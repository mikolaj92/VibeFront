#!/usr/bin/env bash
# Fail if VibeFront skill pins or platform contracts drift.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
manifest_url="${APP_FACTORY_MANIFEST_URL:-https://raw.githubusercontent.com/mikolaj92/app-factory/main/app_factory/assets/MANIFEST.json}"
bom_url="${APP_FACTORY_BOM_URL:-https://raw.githubusercontent.com/mikolaj92/app-factory/main/bom/multi_user.toml}"
skill_file="$repo_root/skills/vibe-front/SKILL.md"
prompt_file="$repo_root/skills/vibe-front/references/agent-paste-prompt.md"

tmp="$(mktemp)"
bom_tmp="$(mktemp)"
trap 'rm -f "$tmp" "$bom_tmp"' EXIT

if ! curl -fsSL "$manifest_url" -o "$tmp"; then
  printf 'Failed to fetch live MANIFEST from %s\n' "$manifest_url" >&2
  exit 1
fi
if ! curl -fsSL "$bom_url" -o "$bom_tmp"; then
  printf 'Failed to fetch live host BOM from %s\n' "$bom_url" >&2
  exit 1
fi

read -r basecoat_version htmx_version alpine_version css_filename js_filename htmx_filename alpine_filename < <(
  python3 - "$tmp" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as manifest_file:
    manifest = json.load(manifest_file)
print(
    manifest["basecoat-css"]["version"],
    manifest["htmx"]["version"],
    manifest["alpine"]["version"],
    manifest["basecoat-css"]["filename"],
    manifest["basecoat-js-all"]["filename"],
    manifest["htmx"]["filename"],
    manifest["alpine"]["filename"],
)
if manifest["basecoat-css"]["version"] != manifest["basecoat-js-all"]["version"]:
    raise SystemExit("basecoat-css and basecoat-js-all versions diverged")
PY
)

printf 'Live app-factory MANIFEST: basecoat %s, htmx %s, alpine %s\n' \
  "$basecoat_version" "$htmx_version" "$alpine_version"

read -r app_factory_version my_auth_version my_usermanager_version < <(
  python3 - "$bom_tmp" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as bom_file:
    pins = tomllib.load(bom_file)["pins"]
print(pins["app-factory"], pins["my-auth"], pins["my-usermanager"])
PY
)
printf 'Live host BOM: app-factory %s, my-auth %s, my-usermanager %s\n' \
  "$app_factory_version" "$my_auth_version" "$my_usermanager_version"

fail=0
require_text() {
  local file="$1" needle="$2"
  if ! grep -Fq "$needle" "$file"; then
    printf 'Missing %s in %s\n' "$needle" "${file#"$repo_root"/}" >&2
    fail=1
  fi
}
forbid_text() {
  local file="$1" needle="$2"
  if grep -Fq "$needle" "$file"; then
    printf 'Forbidden text %s in %s\n' "$needle" "${file#"$repo_root"/}" >&2
    fail=1
  fi
}

for needle in \
  "$basecoat_version" "$htmx_version" "$alpine_version" \
  "$css_filename" "$js_filename" "$htmx_filename" "$alpine_filename" \
  platform_asset_url app_factory/head_assets.html app_factory/product_shell.html \
  'hx-target="#main-content"' install_identity_adapters "$app_factory_version" "$my_auth_version" "$my_usermanager_version" same-origin; do
  require_text "$skill_file" "$needle"
done
for needle in app-sidebar '#page-content' basecoat:sidebar 'cdn.jsdelivr.net/npm/basecoat-css@0.3.11' 'unpkg.com/htmx.org@2.0.4' 'dist/js/sidebar.min.js'; do
  forbid_text "$skill_file" "$needle"
done
# CDN exception must quote the live MANIFEST versions, not stale pins.
for needle in \
  "cdn.jsdelivr.net/npm/basecoat-css@$basecoat_version" \
  "cdn.jsdelivr.net/npm/htmx.org@$htmx_version" \
  "cdn.jsdelivr.net/npm/alpinejs@$alpine_version"; do
  require_text "$skill_file" "$needle"
done

for needle in same-origin MANIFEST.json install_identity_adapters COMPAT.md '#main-content' \
  "$app_factory_version" "$my_auth_version" "$my_usermanager_version"; do
  require_text "$prompt_file" "$needle"
done
for needle in 'from CDN only' 'cdn.jsdelivr.net/npm/basecoat-css@0.3.11' 'unpkg.com/htmx.org@2.0.4'; do
  forbid_text "$prompt_file" "$needle"
done

require_text "$repo_root/README.md" '~/.config/opencode/skills/vibe-front'
require_text "$repo_root/scripts/install_opencode_skill.sh" 'source_dir="$repo_root/skills/vibe-front"'
require_text "$repo_root/scripts/install_codex_skill.sh" 'source_dir="$repo_root/skills/vibe-front"'
forbid_text "$repo_root/README.md" '~/.config/opencode/skill/vibe-front/SKILL.md'

if [ "$fail" -ne 0 ]; then
  exit 1
fi
printf 'Canonical skill matches the live kit, shell, identity, and BOM contracts.\n'

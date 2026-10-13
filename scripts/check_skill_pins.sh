#!/usr/bin/env bash
# Fail if VibeFront skill pins or platform contracts drift.
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  printf 'Python >=3.11 is required to check skill pins; python3 was not found in PATH.\n' >&2
  exit 1
fi

python3 - <<'PY'
import sys
if sys.version_info < (3, 11):
    raise SystemExit(
        f"Python >=3.11 is required to check skill pins; found {sys.version.split()[0]}. "
        "Put Python 3.11 or newer on PATH as python3."
    )
PY

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

manifest_values="$(
  python3 - "$tmp" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as manifest_file:
        manifest = json.load(manifest_file)
    for asset in ("basecoat-css", "basecoat-js-all", "htmx", "alpine"):
        for field in ("version", "filename"):
            value = manifest[asset][field]
            if not isinstance(value, str) or not value or any(c.isspace() for c in value):
                raise ValueError(f"{asset}.{field} must be a nonempty string without whitespace")
    if manifest["basecoat-css"]["version"] != manifest["basecoat-js-all"]["version"]:
        raise ValueError("basecoat-css and basecoat-js-all versions diverged")
except (OSError, ValueError, KeyError, TypeError) as error:
    raise SystemExit(f"Invalid MANIFEST: {error}")
print(
    manifest["basecoat-css"]["version"],
    manifest["htmx"]["version"],
    manifest["alpine"]["version"],
    manifest["basecoat-css"]["filename"],
    manifest["basecoat-js-all"]["filename"],
    manifest["htmx"]["filename"],
    manifest["alpine"]["filename"],
)
PY
)"
read -r basecoat_version htmx_version alpine_version css_filename js_filename htmx_filename alpine_filename <<< "$manifest_values"

printf 'Live app-factory MANIFEST: basecoat %s, htmx %s, alpine %s\n' \
  "$basecoat_version" "$htmx_version" "$alpine_version"

bom_values="$(
  python3 - "$bom_tmp" <<'PY'
import sys, tomllib
try:
    with open(sys.argv[1], "rb") as bom_file:
        pins = tomllib.load(bom_file)["pins"]
    for package in ("app-factory", "my-auth", "my-usermanager"):
        value = pins[package]
        if not isinstance(value, str) or not value or any(c.isspace() for c in value):
            raise ValueError(f"{package} pin must be a nonempty string without whitespace")
except (OSError, ValueError, KeyError, TypeError) as error:
    raise SystemExit(f"Invalid host BOM: {error}")
print(pins["app-factory"], pins["my-auth"], pins["my-usermanager"])
PY
)"
read -r app_factory_version my_auth_version my_usermanager_version <<< "$bom_values"
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
  install_identity_adapters same-origin; do
  require_text "$skill_file" "$needle"
done
for needle in app-sidebar '#page-content' basecoat:sidebar 'cdn.jsdelivr.net/npm/basecoat-css@0.3.11' 'unpkg.com/htmx.org@2.0.4' 'dist/js/sidebar.min.js'; do
  forbid_text "$skill_file" "$needle"
done
# #main-content must be documented as the outer-chrome nav target, not as an
# inner-section load target: an element inside #main-content swapping the whole
# region destroys its own card. See issue #22.
require_text "$skill_file" 'hx-target="#main-content"'
require_text "$skill_file" 'hx-target="this"'
# An inner element must never load-trigger a swap of #main-content: that
# element renders inside #main-content and would erase its own card. See issue #22.
# grep -F is line-based, so check the combined pattern on whitespace-normalized text.
flat_skill="$(tr '\n' ' ' < "$skill_file" | tr -s ' ')"
if printf '%s' "$flat_skill" | grep -Fq 'hx-trigger="load" hx-target="#main-content"' || \
  printf '%s' "$flat_skill" | grep -Fq 'hx-target="#main-content" hx-trigger="load"'; then
  printf 'Forbidden pattern hx-trigger=load combined with hx-target="#main-content" in %s\n' "${skill_file#"$repo_root"/}" >&2
  fail=1
fi
# Match complete CDN asset URLs so longer versions cannot satisfy a live pin.
for needle in \
  "https://cdn.jsdelivr.net/npm/basecoat-css@$basecoat_version/dist/basecoat.cdn.min.css\"" \
  "https://cdn.jsdelivr.net/npm/basecoat-css@$basecoat_version/dist/js/all.min.js\"" \
  "https://cdn.jsdelivr.net/npm/htmx.org@$htmx_version\"" \
  "https://cdn.jsdelivr.net/npm/alpinejs@$alpine_version/dist/cdn.min.js\""; do
  require_text "$skill_file" "$needle"
done

# Match complete Markdown code spans, not prefixes such as v0.7.90 for v0.7.9.
for file in "$skill_file" "$prompt_file"; do
  for version in "$app_factory_version" "$my_auth_version" "$my_usermanager_version"; do
    require_text "$file" "\`$version\`"
  done
  for source in \
    "app-factory = { git = \"https://github.com/mikolaj92/app-factory\", tag = \"$app_factory_version\" }" \
    "my-auth = { git = \"https://github.com/mikolaj92/my-auth\", tag = \"$my_auth_version\" }" \
    "my-usermanager = { git = \"https://github.com/mikolaj92/my-usermanager\", tag = \"$my_usermanager_version\" }"; do
    require_text "$file" "$source"
    package="${source%% =*}"
    while IFS= read -r example; do
      if [ "$example" != "$source" ]; then
        printf 'Host BOM installation source mismatch for %s in %s\n' "$package" "${file#"$repo_root"/}" >&2
        fail=1
      fi
    done < <(grep -E "^${package} = " "$file")
  done
done

for needle in same-origin MANIFEST.json install_identity_adapters COMPAT.md '#main-content'; do
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

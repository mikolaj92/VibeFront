#!/usr/bin/env bash
# Fail if VibeFront skill pins drift from the live app-factory MANIFEST.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
manifest_url="${APP_FACTORY_MANIFEST_URL:-https://raw.githubusercontent.com/mikolaj92/app-factory/main/app_factory/assets/MANIFEST.json}"

skill_files=(
  "$repo_root/.opencode/skills/vibe-front/SKILL.md"
  "$repo_root/codex/skill/vibe-front/SKILL.md"
)
prompt_files=(
  "$repo_root/.opencode/skills/vibe-front/references/agent-paste-prompt.md"
  "$repo_root/codex/skill/vibe-front/references/agent-paste-prompt.md"
)

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if ! curl -fsSL "$manifest_url" -o "$tmp"; then
  printf 'Failed to fetch live MANIFEST from %s\n' "$manifest_url" >&2
  exit 1
fi

read -r basecoat_version htmx_version alpine_version css_filename js_filename htmx_filename alpine_filename < <(
  python3 - "$tmp" <<'PY'
import json, sys
manifest = json.load(open(sys.argv[1], encoding="utf-8"))
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

fail=0

require_text() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$file"; then
    printf 'Missing %s in %s\n' "$needle" "${file#"$repo_root"/}" >&2
    fail=1
  fi
}

forbid_text() {
  local file="$1"
  local needle="$2"
  if grep -Fq "$needle" "$file"; then
    printf 'Forbidden leftover pin %s in %s\n' "$needle" "${file#"$repo_root"/}" >&2
    fail=1
  fi
}

if ! diff -q "${skill_files[0]}" "${skill_files[1]}" >/dev/null; then
  printf 'OpenCode and Codex SKILL.md copies drifted apart\n' >&2
  fail=1
fi

if ! diff -q "${prompt_files[0]}" "${prompt_files[1]}" >/dev/null; then
  printf 'OpenCode and Codex agent-paste-prompt.md copies drifted apart\n' >&2
  fail=1
fi

for file in "${skill_files[@]}"; do
  require_text "$file" "$basecoat_version"
  require_text "$file" "$htmx_version"
  require_text "$file" "$alpine_version"
  require_text "$file" "$css_filename"
  require_text "$file" "$js_filename"
  require_text "$file" "$htmx_filename"
  require_text "$file" "$alpine_filename"
  require_text "$file" "platform_asset_url"
  require_text "$file" "app_factory/head_assets.html"
  require_text "$file" "app_factory/product_shell.html"
  require_text "$file" "same-origin"
  forbid_text "$file" "cdn.jsdelivr.net/npm/basecoat-css@0.3.11"
  forbid_text "$file" "unpkg.com/htmx.org@2.0.4"
  forbid_text "$file" "dist/js/sidebar.min.js"
done

for file in "${prompt_files[@]}"; do
  require_text "$file" "same-origin"
  require_text "$file" "MANIFEST.json"
  forbid_text "$file" "from CDN only"
  forbid_text "$file" "cdn.jsdelivr.net/npm/basecoat-css@0.3.11"
  forbid_text "$file" "unpkg.com/htmx.org@2.0.4"
done

require_text "$repo_root/README.md" "~/.config/opencode/skills/vibe-front"
require_text "$repo_root/scripts/install_opencode_skill.sh" '$HOME/.config/opencode/skills'
forbid_text "$repo_root/README.md" "~/.config/opencode/skill/vibe-front/SKILL.md"
if grep -q 'OPENCODE_SKILL_DIR:-$HOME/.config/opencode/skill}' "$repo_root/scripts/install_opencode_skill.sh"; then
  printf 'install_opencode_skill.sh still defaults to singular OpenCode skill path\n' >&2
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

printf 'Skill pins match live app-factory MANIFEST and same-origin kit contract.\n'

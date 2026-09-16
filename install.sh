#!/usr/bin/env bash
set -euo pipefail

repo_url="${VIBEFRONT_REPO_URL:-https://github.com/mikolaj92/VibeFront.git}"
install_dir="${VIBEFRONT_HOME:-$HOME/.local/share/vibefront}"
repo_ref="${VIBEFRONT_REF:-main}"

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command_name" >&2
    exit 1
  fi
}

require_command git

mkdir -p "$(dirname "$install_dir")"

if [ -d "$install_dir/.git" ]; then
  git -C "$install_dir" fetch origin "$repo_ref"
  git -C "$install_dir" checkout "$repo_ref"
  if git -C "$install_dir" symbolic-ref --quiet --short HEAD >/dev/null; then
    git -C "$install_dir" pull --ff-only origin "$repo_ref"
  fi
else
  rm -rf "$install_dir"
  git clone "$repo_url" "$install_dir"
  git -C "$install_dir" fetch origin "$repo_ref"
  git -C "$install_dir" checkout "$repo_ref"
fi

"$install_dir/scripts/install_opencode_skill.sh"
"$install_dir/scripts/install_codex_skill.sh"

printf 'VibeFront installed in %s\n' "$install_dir"
printf 'Raw installer usage: curl -fsSL https://raw.githubusercontent.com/mikolaj92/VibeFront/main/install.sh | bash\n'

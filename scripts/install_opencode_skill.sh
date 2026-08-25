#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_dir="$repo_root/.opencode/skills/vibe-front"
default_root="$HOME/.config/opencode/skills"
target_root="${OPENCODE_SKILL_DIR:-$default_root}"
target_dir="$target_root/vibe-front"
legacy_dir="$HOME/.config/opencode/skill/vibe-front"

mkdir -p "$target_root"
rm -rf "$target_dir"
ln -s "$source_dir" "$target_dir"

# OpenCode loads ~/.config/opencode/skills/*/SKILL.md (plural).
# Drop the leftover singular path when using the default root.
if [ -z "${OPENCODE_SKILL_DIR:-}" ] && [ -e "$legacy_dir" ]; then
  rm -rf "$legacy_dir"
  printf 'Removed leftover OpenCode path %s\n' "$legacy_dir"
fi

printf 'Installed OpenCode skill at %s\n' "$target_dir"

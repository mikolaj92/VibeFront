#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_dir="$repo_root/.opencode/skills/vibe-front"
target_dir="${OPENCODE_SKILL_DIR:-$HOME/.config/opencode/skill}/vibe-front"

mkdir -p "$(dirname "$target_dir")"
rm -rf "$target_dir"
ln -s "$source_dir" "$target_dir"

printf 'Installed OpenCode skill at %s\n' "$target_dir"

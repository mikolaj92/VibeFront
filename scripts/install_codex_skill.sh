#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_dir="$repo_root/skills/vibe-front"
base_dir="${CODEX_SKILL_DIR:-$HOME/.codex/skills}"
target_dir="$base_dir/vibe-front"

mkdir -p "$base_dir"
rm -rf "$target_dir"
ln -s "$source_dir" "$target_dir"

printf 'Installed Codex skill at %s\n' "$target_dir"

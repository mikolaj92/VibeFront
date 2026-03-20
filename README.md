# VibeFront

Portable Basecoat-first frontend skill package for OpenCode and Codex.

VibeFront is a reusable skill for FastAPI, Jinja2, HTMX, and plain HTML UI work where the result should stay close to the calm, minimal Basecoat feel instead of drifting into custom utility-heavy markup.

## What it installs

- `.opencode/skills/vibe-front/` for OpenCode
- `codex/skill/vibe-front/` for Codex
- shared install scripts for a stable per-user checkout

## Install

Use the one-liner installer on any machine:

```bash
curl -fsSL https://raw.githubusercontent.com/mikolaj92/VibeFront/main/install.sh | bash
```

This installer:

- clones or updates VibeFront in `~/.local/share/vibefront`
- installs the OpenCode skill link
- installs the Codex skill link

If you already have the repo locally, you can run the platform installers directly:

```bash
./scripts/install_opencode_skill.sh
./scripts/install_codex_skill.sh
```

## Installed paths

By default the scripts install symlinks in:

- `~/.config/opencode/skill/vibe-front`
- `~/.codex/skills/vibe-front`

You can override those roots with:

- `OPENCODE_SKILL_DIR`
- `CODEX_SKILL_DIR`

You can also override the stable checkout used by the one-liner installer with:

- `VIBEFRONT_HOME`
- `VIBEFRONT_REPO_URL`
- `VIBEFRONT_REF`

## Repo layout

- `.opencode/skills/vibe-front/` - OpenCode skill payload
- `codex/skill/vibe-front/` - Codex skill payload
- `scripts/` - user-level install scripts
- `install.sh` - clone/update installer for GitHub installs

## What the skill enforces

- Basecoat primitives first
- HTMX fragments instead of duplicated page shells
- one canonical sidebar by default
- no React, Node, npm, or bundler creep
- no utility-heavy rewrites when Basecoat already covers the UI

## Verify install

After installation, confirm both targets exist:

```bash
test -e "$HOME/.config/opencode/skill/vibe-front/SKILL.md"
test -e "$HOME/.codex/skills/vibe-front/SKILL.md"
```

If a tool does not refresh the skill list automatically, restart it once after installation.

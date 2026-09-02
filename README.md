# VibeFront

Portable Basecoat-first frontend skill package for OpenCode and Codex.

VibeFront is a reusable skill for FastAPI, Jinja2, HTMX, and plain HTML UI work where the result should stay close to the calm, minimal Basecoat feel instead of drifting into custom utility-heavy markup.

Chrome pins come from the live [app-factory MANIFEST](https://github.com/mikolaj92/app-factory/blob/main/app_factory/assets/MANIFEST.json). The skill prefers the same-origin kit (`install_app_factory_ui`, `head_assets`, `product_shell`) over leftover jsDelivr/unpkg tags. Re-read that manifest before changing versions.

## What it installs

- one canonical payload in `skills/vibe-front/`
- an OpenCode symlink to that payload
- a Codex symlink to the same payload
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

- `~/.config/opencode/skills/vibe-front`
- `~/.codex/skills/vibe-front`

OpenCode loads `~/.config/opencode/skills/*/SKILL.md` (plural). The installer also removes a leftover `~/.config/opencode/skill/vibe-front` symlink from older installs.

You can override those roots with:

- `OPENCODE_SKILL_DIR`
- `CODEX_SKILL_DIR`

You can also override the stable checkout used by the one-liner installer with:

- `VIBEFRONT_HOME`
- `VIBEFRONT_REPO_URL`
- `VIBEFRONT_REF`

## Repo layout

- `skills/vibe-front/` - the only skill payload
- `scripts/` - user-level installers linking that payload into each harness
- `install.sh` - clone/update installer for GitHub installs

## What the skill enforces

- Basecoat primitives first
- same-origin app-factory chrome (MANIFEST-pinned Basecoat / HTMX / Alpine)
- HTMX fragments instead of duplicated page shells
- one canonical sidebar by default
- no leftover CDN pins for core chrome
- no React, Node, npm, or bundler creep
- no utility-heavy rewrites when Basecoat already covers the UI

## Verify install

After installation, confirm both targets exist:

```bash
test -e "$HOME/.config/opencode/skills/vibe-front/SKILL.md"
test -e "$HOME/.codex/skills/vibe-front/SKILL.md"
./scripts/check_skill_pins.sh
```

If a tool does not refresh the skill list automatically, restart it once after installation.

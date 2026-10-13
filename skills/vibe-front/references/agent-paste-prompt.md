Use FastAPI + Jinja2 + HTMX + plain HTML + the app-factory same-origin kit.

Hard rules:
- Basecoat first, always.
- Do not invent custom components if Basecoat already has an equivalent.
- Do not use utility-heavy Tailwind markup for cards, forms, tables, tabs, dialogs, badges, buttons, or sidebars.
- Keep exactly one sidebar unless explicitly asked otherwise.
- Prefer `app_factory/product_shell.html`. `hx-target="#main-content"` is an outer-chrome pattern: the kit sidebar nav sits outside `#main-content` and targets it. Content inside `#main-content` targets itself (`hx-target="this"`) or a nested fragment id. Do not paste leftover CDN chrome or a private sidebar.
- Chrome-only FastAPI: call `install_app_factory_ui` or `install_platform`. Passkey/user-management host: call `install_identity_adapters` with `PasskeyBinding` and `UserManagerBinding`.
- Do not copy `install_passkey_ui`, `install_usermanager_ui`, session parsing, or identity route glue into the host.
- Pin one immutable host BOM row from app-factory `COMPAT.md` (currently app-factory `v0.7.3`, my-auth `v0.5.6`, my-usermanager `v0.6.7`); never use a local path or floating branch.
- Read Basecoat/HTMX/Alpine versions from app-factory `MANIFEST.json`. Do not reuse `basecoat-css@0.3.11` or `htmx.org@2.0.4`.
- HTMX responses return fragments only, never a second shell or sidebar.
- Match the calm, minimal feel of basecoatui.com.
- No React, no Node, no npm, no bundler.

Before writing code:
1. identify the Basecoat primitive
2. decide full page vs fragment
3. write the smallest valid Jinja/HTML structure
4. add HTMX attributes to that structure
5. remove custom wrappers and utility clutter

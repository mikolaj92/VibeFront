Use FastAPI + Jinja2 + HTMX + plain HTML + the app-factory same-origin kit.

Hard rules:
- Basecoat first, always.
- Do not invent custom components if Basecoat already has an equivalent.
- Do not use utility-heavy Tailwind markup for cards, forms, tables, tabs, dialogs, badges, buttons, or sidebars.
- Keep exactly one sidebar unless explicitly asked otherwise.
- Prefer `app_factory/product_shell.html` (or include `app_factory/head_assets.html`). Do not paste leftover CDN chrome.
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

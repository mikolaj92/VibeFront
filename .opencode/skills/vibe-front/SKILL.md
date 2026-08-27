---
name: vibe-front
description: Enforce Basecoat-first UI generation for FastAPI, Jinja2, HTMX, Alpine.js, and plain HTML apps that use the app-factory same-origin kit. Use this when creating or editing templates, layouts, cards, forms, tables, dialogs, tabs, sidebars, or HTMX fragments that should stay close to the calm, minimal Basecoat feel and avoid custom utility-heavy rebuilds.
---

# VibeFront

Treat this file as the source of truth. The hard rules belong here. Reference files are only supporting material.

## Stack assumptions

Default to this stack unless the user explicitly says otherwise:
- FastAPI
- Jinja2 templates
- HTMX
- plain HTML
- app-factory same-origin chrome (`install_app_factory_ui` + `head_assets` / `product_shell`)
- Basecoat, HTMX, and Alpine versions from the live app-factory `MANIFEST.json` (not leftover CDN pins)
- Alpine.js only when HTMX is not enough for light local UI state
- no Node, no npm, no bundler, no React
- no jsDelivr/unpkg tags for core chrome unless the user explicitly asks for a kit-free standalone HTML file

Use server-rendered templates first.

Interaction preference order:
1. HTMX for server-driven interaction and partial updates
2. Alpine.js for small local UI state when HTMX would be awkward or incomplete
3. small amounts of plain JavaScript only when HTMX and Alpine.js are not a good fit

Do not jump straight to custom JavaScript if HTMX or Alpine.js would solve the problem cleanly.

## Core rule: Basecoat first, always

Before writing markup, check whether Basecoat already has a matching primitive. If it does, use the Basecoat structure directly.

Priority order:
1. exact Basecoat component structure
2. minimal HTMX attributes on that structure
3. minimal utility classes only for page-level layout glue

Never invent a custom component when Basecoat already covers it.
Never rebuild a Basecoat component out of raw Tailwind utilities.
Never keep existing custom markup just because it already exists, if a clear Basecoat equivalent is available.
If unsure, choose the simpler Basecoat structure.

## Non-negotiable rules

### 1. Copy the documented Basecoat anatomy

Use the same element structure and feel as the docs.

Example for cards:

```html
<div class="card">
  <header>
    <h2>Card Title</h2>
    <p>Card Description</p>
  </header>
  <section>
    <p>Card Content</p>
  </section>
  <footer>
    <p>Card Footer</p>
  </footer>
</div>
```

Do not rewrite this as a custom `div` soup with `rounded-*`, `border`, `shadow`, `p-*`, `text-*` unless the user explicitly asks for a different style.

### 2. Match the Basecoat feel 1:1

Aim for the same overall feel as basecoatui.com:
- restrained and neutral
- readable at a glance
- short labels and short helper text
- generous but not flashy spacing
- low visual noise
- simple hierarchy
- no decorative gradients, glassmorphism, oversized shadows, or animated gimmicks

When writing copy inside UI examples, keep it short and boring in a good way.
Prefer titles like `Projects`, `Settings`, `Team`, `Billing`.
Prefer short descriptions like `Recent work and status.`

### 3. HTMX enhances the shell; it does not replace it

HTMX should swap the inner content region, not rebuild the whole page.

Use HTMX first for server-dependent interaction such as:
- request/response updates
- partial swaps
- forms
- loading states tied to server responses
- pagination
- filtering
- CRUD flows

Rules:
- `base.html` is the only full document shell.
- Full pages extend `base.html`.
- HTMX endpoints return fragments only.
- HTMX fragments must not return `<html>`, `<body>`, a second layout wrapper, a second sidebar, or a second main app shell.
- Put `hx-*` attributes on the Basecoat-compatible markup instead of wrapping the whole thing in custom containers.

### 4. Interaction escalation order

Prefer the lightest interaction layer that fits the job.

Order:
1. HTMX
2. Alpine.js
3. plain JavaScript

Use HTMX for:
- request/response interaction
- partial swaps
- forms
- loading
- pagination
- filtering
- CRUD flows
- any interaction that depends on server-rendered HTML

Use Alpine.js for small local UI state when no server round trip is needed, such as:
- toggle state
- dropdown open/close state
- temporary disclosure
- tabs when they are local, not server-driven
- local modal open/close state

Use plain JavaScript only when:
- a browser API is required
- the behavior is custom enough that HTMX or Alpine.js would be unnatural
- HTMX and Alpine.js would make the solution more complex than the problem

Rules:
- prefer HTMX for interactions that depend on the server
- prefer Alpine.js for small local state inside one component
- prefer plain JavaScript only as the last layer
- keep the implementation minimal, readable, and close to the markup
- do not add Alpine.js if HTMX alone already solves the interaction
- do not add plain JavaScript if HTMX or Alpine.js already solve the interaction
- do not skip from HTMX straight to custom JavaScript when Alpine.js would cover the gap cleanly

Decision examples:
- submit a form and update a list -> HTMX
- open or close a dropdown or modal without a server request -> Alpine.js
- integrate with a browser API or handle unusual client-side behavior -> plain JavaScript
- if HTMX already solves the interaction, stop there

### 5. Exactly one canonical sidebar by default

Unless the user explicitly asks for multiple sidebars, there is exactly one app sidebar.

Rules:
- Keep one stable sidebar id, such as `app-sidebar`.
- Define sidebar markup once, usually in `base.html` or one included partial.
- Do not duplicate sidebar markup in page templates.
- Do not return sidebar markup from HTMX fragments.
- HTMX swaps should normally target `#page-content`, not the sidebar.
- Do not create multiple toggle mechanisms with different ids.

Canonical pattern:

```html
<aside class="sidebar" id="app-sidebar" aria-hidden="true">
  <nav>
    <header>
      <a href="/" class="font-medium">Workspace</a>
    </header>
    <section>
      <ul>
        <li><a href="/dashboard" aria-current="page">Dashboard</a></li>
        <li><a href="/projects">Projects</a></li>
        <li><a href="/settings">Settings</a></li>
      </ul>
    </section>
  </nav>
</aside>

<main id="page-content">
  {% block page %}{% endblock %}
</main>

<button
  type="button"
  aria-label="Toggle navigation"
  onclick="document.dispatchEvent(new CustomEvent('basecoat:sidebar', { detail: { id: 'app-sidebar' } }))"
>
  Menu
</button>
```

### 6. Basecoat over utility soup

Bad:

```html
<div class="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm">
  <div class="mb-4">
    <h2 class="text-lg font-semibold">Projects</h2>
    <p class="text-sm text-zinc-500">Recent work and status.</p>
  </div>
</div>
```

Good:

```html
<div class="card">
  <header>
    <h2>Projects</h2>
    <p>Recent work and status.</p>
  </header>
</div>
```

Allowed utility classes are limited to simple layout glue such as:
- `grid`
- `gap-*`
- `flex`
- `items-center`
- `justify-between`
- `w-full`
- `ml-auto`
- `mt-*` or `mb-*` only when necessary for page composition

Do not use utilities to restyle the inside of an existing Basecoat component unless truly necessary.

## Asset pin contract (app-factory MANIFEST)

Do not invent chrome pins. Read the live kit manifest before writing `<link>` or `<script>` tags:

https://raw.githubusercontent.com/mikolaj92/app-factory/main/app_factory/assets/MANIFEST.json

Re-read that file. Do not reuse versions from this skill if the manifest has moved.

Aligned pins at last check:
- `basecoat-css` / `basecoat-js-all` **1.0.2** → `basecoat-factory.min.css`, `basecoat-js.min.js`
- `htmx` **2.0.10** → `htmx.min.js`
- `alpine` **3.15.12** → `alpine.min.js`

Default delivery is **same-origin via the app-factory kit**, not jsDelivr/unpkg:

1. Call `install_app_factory_ui(app, environments=[templates.env])` so `/static/platform` is mounted once.
2. Full product pages extend `app_factory/product_shell.html` (or `app_factory/shell.html`).
3. If the host already has a document shell, `{% include "app_factory/head_assets.html" %}`. Do not hand-roll core chrome tags.
4. Same-origin URLs look like `/static/platform/htmx.min.js` via `platform_asset_url('htmx')`.

This skill is **not** CDN-only. Leftover CDN pins (`basecoat-css@0.3.11`, `htmx.org@2.0.4`, jsDelivr/unpkg for core chrome) are forbidden.

CDN exception: only when the user explicitly asks for a standalone HTML file with no Python/app-factory kit. Then still match the live MANIFEST versions:

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/basecoat-css@1.0.2/dist/basecoat.cdn.min.css" />
<script src="https://cdn.jsdelivr.net/npm/htmx.org@2.0.10"></script>
<script src="https://cdn.jsdelivr.net/npm/alpinejs@3.15.12/dist/cdn.min.js" defer></script>
<script src="https://cdn.jsdelivr.net/npm/basecoat-css@1.0.2/dist/js/all.min.js" defer></script>
```

Do not keep the 0.3.x split (`basecoat.min.js` + `sidebar.min.js`). Basecoat 1.x ships one combined JS bundle (`basecoat-js-all` / `all.min.js`).

## Default project structure

Prefer this structure unless the repo already has a clear equivalent:

```text
templates/
  base.html
  dashboard.html
  partials/
    sidebar.html
    flash.html
    dashboard_table.html
```

## Base template guidance

Prefer the kit shell. Do not fork a private document chrome or paste CDN tags.

```html
{% extends "app_factory/product_shell.html" %}

{% block title %}Projects{% endblock %}

{% block content %}
<div class="grid gap-6">
  <div class="card">
    <header>
      <h1>Projects</h1>
      <p>Recent work and status.</p>
    </header>
    <section
      hx-get="/projects/list"
      hx-trigger="load"
      hx-target="this"
      hx-swap="innerHTML"
    >
      <p>Loading...</p>
    </section>
  </div>
</div>
{% endblock %}
```

If the host already has a document shell, include kit head assets instead of writing tags:

```html
{% include "app_factory/head_assets.html" %}
```

That emits same-origin Basecoat 1.0.2, HTMX 2.0.10, and Alpine 3.15.12 from `/static/platform`.

Only if the host cannot mount app-factory yet, keep one outer shell and point at the same-origin kit files (still MANIFEST versions, still not CDN):

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{% block title %}App{% endblock %}</title>
    <link rel="stylesheet" href="{{ platform_asset_url('basecoat-css') }}" />
    <script src="{{ platform_asset_url('htmx') }}"></script>
    <script src="{{ platform_asset_url('alpine') }}" defer></script>
    <script src="{{ platform_asset_url('basecoat-js-all') }}" defer></script>
    {% block head %}{% endblock %}
  </head>
  <body>
    {% include "partials/sidebar.html" %}
    <main id="page-content">
      {% block page %}{% endblock %}
    </main>
    {% block scripts %}{% endblock %}
  </body>
</html>
```

## Rendering rules for FastAPI + Jinja2

### Full page
- prefer `app_factory/product_shell.html` (or a host `base.html` that includes `app_factory/head_assets.html`)
- fill the `content` / `page` block
- keep one page-level heading area
- use Basecoat cards, forms, tables, and nav primitives directly

### HTMX fragment
- return only the fragment needed by the target
- keep markup valid and minimal
- do not return a second shell
- do not return sidebar markup

Example full page:

```html
{% extends "app_factory/product_shell.html" %}

{% block title %}Projects{% endblock %}

{% block content %}
<div class="grid gap-6">
  <div class="card">
    <header>
      <h1>Projects</h1>
      <p>Recent work and status.</p>
    </header>
    <section
      hx-get="/projects/list"
      hx-trigger="load"
      hx-target="this"
      hx-swap="innerHTML"
    >
      <p>Loading...</p>
    </section>
  </div>
</div>
{% endblock %}
```

Example fragment:

```html
{% for project in projects %}
<div class="card">
  <header>
    <h2>{{ project.name }}</h2>
    <p>{{ project.summary }}</p>
  </header>
</div>
{% endfor %}
```

## Required workflow for the agent

For every UI task, follow this order:
1. identify the Basecoat primitive first
2. choose whether the output is a full page or an HTMX fragment
3. choose the lightest interaction layer that fits:
   - HTMX first
   - Alpine.js second
   - plain JavaScript last
4. write the simplest valid Jinja/HTML structure
5. add HTMX attributes where server interaction is needed
6. add Alpine.js only for small local state that HTMX should not own
7. add plain JavaScript only when HTMX and Alpine.js are not a good fit
8. remove any custom wrappers or utility clutter that duplicate Basecoat
9. verify there is still only one shell and one sidebar

## Forbidden patterns

Alpine.js is allowed as a small local interaction layer. It is not the default, and it is not the architecture.

Never do any of the following:
- pin leftover CDN chrome (`basecoat-css@0.3.11`, `htmx.org@2.0.4`, jsDelivr/unpkg) instead of the app-factory same-origin kit
- invent Basecoat/HTMX/Alpine versions instead of reading `app_factory/assets/MANIFEST.json`
- add React, Vue, or Svelte as a replacement for HTMX, Alpine.js, or server-rendered templates
- add npm, Node, Vite, webpack, Tailwind config, or build tooling
- use Alpine.js as a page-level framework or as a replacement for HTMX server flows
- jump straight to plain JavaScript when HTMX or Alpine.js would solve the interaction cleanly
- recreate cards, dialogs, sidebars, tabs, badges, or buttons from scratch when Basecoat already has them
- return full HTML documents from HTMX endpoints
- place a second sidebar inside swapped content
- create multiple sidebars because different pages were generated independently
- use giant Tailwind class piles for ordinary Basecoat components
- create fancy visual redesigns that drift away from Basecoat's neutral look

## Output expectations

When generating code, prefer delivering concrete template files or patches such as:
- `templates/base.html`
- `templates/dashboard.html`
- `templates/partials/sidebar.html`
- `templates/partials/flash.html`
- `templates/partials/dashboard_table.html`

Do not spend space defending the design. Just implement the Basecoat-aligned version.

## Supplemental reference

If a user wants a pasteable instruction block for another coding agent, consult `references/agent-paste-prompt.md` and adapt it as needed. That file is supplementary. The real enforcement lives in this `SKILL.md`.

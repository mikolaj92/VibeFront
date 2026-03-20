---
name: vibe-front
description: Enforce Basecoat-first UI generation for FastAPI, Jinja2, HTMX, and plain HTML apps that use CDN-hosted assets. Use this when creating or editing templates, layouts, cards, forms, tables, dialogs, tabs, sidebars, or HTMX fragments that should stay close to the calm, minimal Basecoat feel and avoid custom utility-heavy rebuilds.
---

# VibeFront

Treat this file as the source of truth. The hard rules belong here. Reference files are only supporting material.

## Stack assumptions

Default to this stack unless the user explicitly says otherwise:
- FastAPI
- Jinja2 templates
- HTMX
- plain HTML
- Basecoat UI from CDN
- no Node, no npm, no bundler, no React

Use server-rendered templates first. Add JavaScript only when the interaction truly needs it, and prefer HTMX plus Basecoat's own scripts.

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

Rules:
- `base.html` is the only full document shell.
- Full pages extend `base.html`.
- HTMX endpoints return fragments only.
- HTMX fragments must not return `<html>`, `<body>`, a second layout wrapper, a second sidebar, or a second main app shell.
- Put `hx-*` attributes on the Basecoat-compatible markup instead of wrapping the whole thing in custom containers.

### 4. Exactly one canonical sidebar by default

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

### 5. Basecoat over utility soup

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

Use one outer shell in `base.html`.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>{% block title %}App{% endblock %}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/basecoat-css@0.3.11/dist/basecoat.cdn.min.css" />
    <script src="https://unpkg.com/htmx.org@2.0.4"></script>
    <script src="https://cdn.jsdelivr.net/npm/basecoat-css@0.3.11/dist/js/basecoat.min.js" defer></script>
    <script src="https://cdn.jsdelivr.net/npm/basecoat-css@0.3.11/dist/js/sidebar.min.js" defer></script>
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
- extend `base.html`
- fill the `page` block
- keep one page-level heading area
- use Basecoat cards, forms, tables, and nav primitives directly

### HTMX fragment
- return only the fragment needed by the target
- keep markup valid and minimal
- do not return a second shell
- do not return sidebar markup

Example full page:

```html
{% extends "base.html" %}

{% block title %}Projects{% endblock %}

{% block page %}
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
3. write the simplest valid Jinja/HTML structure
4. add HTMX attributes to that structure
5. remove any custom wrappers or utility clutter that duplicate Basecoat
6. verify there is still only one shell and one sidebar

## Forbidden patterns

Never do any of the following unless the user explicitly asks for it:
- add React, Vue, Svelte, Alpine as a replacement for HTMX
- add npm, Node, Vite, webpack, Tailwind config, or build tooling
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

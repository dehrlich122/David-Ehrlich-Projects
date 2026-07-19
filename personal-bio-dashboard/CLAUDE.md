# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-page personal bio/portfolio site for David Ehrlich (Business & Revenue Operations Leader). It is plain static HTML/CSS/JS with **no build step, no package manager, no framework, and no dependencies** — three files do all the work:

- `index.html` — page structure and content
- `style.css` — all styling
- `script.js` — the only JS on the page: auto-updates the footer copyright year via `new Date().getFullYear()`

`profile.jpg` is the hero avatar photo, hosted locally (deliberately not hotlinked from LinkedIn's CDN, since those URLs are signed and expire). `David Ehrlich - Resume 2026.docx` is the source-of-truth content the page copy was drawn from — check it before inventing new bio/experience/skills content.

## Running / previewing

There is nothing to install or build. Open `index.html` directly in a browser to preview:

```
start index.html
```

To verify a change, open the file and visually check the affected section, then resize the window (or use browser dev tools' device toolbar) to confirm responsive behavior at the ~600px mobile breakpoint defined in `style.css`.

## Guiding constraints (established through prior iteration — don't casually violate)

- **Self-contained by design.** No CDNs, no external font imports, no icon libraries — social icons are inline SVGs directly in `index.html`. Keep it working fully offline.
- **CSS-only interactivity/animation.** JS is intentionally limited to the single copyright-year use case. Hover states, card lift effects, the hero fade-in-on-load, sticky/blurred header, etc. are all pure CSS — don't reach for JS to solve something CSS can already do here.
- **System font stack only** (`body` in `style.css`) — no Google Fonts or other web font imports.
- **Heavily commented for a learning audience.** The person maintaining this site is a beginner explicitly learning HTML/CSS from this codebase. Every non-obvious tag/property in both files carries a comment explaining *why*, not just what. Preserve this teaching-comment style when editing — don't strip comments, and add one when introducing a new CSS/HTML technique.

## Structure/theming conventions to follow

- All colors, spacing radius, and max content width are CSS custom properties in `style.css`'s `:root` block (`--accent`, `--bg`, `--bg-soft`, `--text-muted`, `--radius`, `--max-width`, etc.). Reuse these variables rather than hardcoding new colors.
- Each content `<section>` doubles as its own `.container` (i.e. `class="container section"` on the same element — there's no separate outer/inner wrapper). This means full-bleed backgrounds aren't possible without restructuring; the established workaround for "alternating section" tinting is styling specific section `#id`s (see `#achievements, #skills` in `style.css`) as centered, rounded, tinted "panel" cards instead of full-width bands.
- Section headings use a small uppercase `.eyebrow` label above the `<h2>` (e.g. "Track Record", "Career Path") for visual rhythm — add one when adding a new section.
- Two distinct chip/pill visual languages exist and are intentionally different: `.skills-list` (accent-colored, checkmark `::before`, for core competencies) vs `.tool-chips` (neutral/muted, no checkmark, grouped under `.tool-group-label` sub-headings, for the larger supporting tool inventory). Don't merge these styles — the visual hierarchy (skills > tools) is deliberate.
- Achievement stat cards (`.stat-card` in the Key Achievements section) follow a "headline includes the quality" pattern — e.g. `30%+ Churn Reduction`, not a bare number with the meaning relegated to the smaller `.stat-label` line below. Keep new stat cards consistent with this.
- Buttons: `.btn` is the base filled/pill button; add `.btn-outline` alongside it (`class="btn btn-outline"`) for a secondary/lower-emphasis action — it inherits `.btn`'s shape and only overrides color.

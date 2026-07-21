# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A morning news digest, driven entirely by the `/digest` slash command (`.claude/commands/digest.md`). There is no Node.js/Python app and no web service — this machine has neither runtime on PATH. The pipeline is: PowerShell scripts do deterministic fetching/state-tracking, and Claude itself (running the command) does the relevance filtering, clustering, summarizing, and HTML rendering. There is no `ANTHROPIC_API_KEY` or external LLM call involved.

## Running the digest

Just invoke the slash command: `/digest`. It runs start-to-finish unattended — do not stop partway to ask for confirmation, per the command's own instructions.

Manually running the underlying scripts (for debugging), from the project root:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\fetch-new-items.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\mark-seen.ps1"
```

There is no build, lint, or test suite in this repo.

## Architecture

**`feeds.json`** — the 9 source feeds (BBC, Times of Israel, Haaretz as native RSS; AP, Reuters, AFP, NYT, FT, Washington Post as Google News site-restricted proxy feeds using `when:1d` queries).

**`scripts/fetch-new-items.ps1`** — deterministic, no AI. Fetches every feed, parses RSS XML, and writes items not already in `data/seen.json` to `data/pending.json`. Two things to know if touching this file:
- RSS `<title>`/`<description>` nodes sometimes come back as CDATA (BBC does this) and sometimes as plain text, and PowerShell's `[xml]` cast represents these differently (`XmlElement` vs `String`). The `Get-NodeText` helper handles both — don't replace it with a plain `[string]` cast, that silently produces `"System.Xml.XmlElement"` as the value instead of the actual text.
- PowerShell 5.1's `ConvertTo-Json` unwraps single-element arrays into a bare object. Output is forced with `@($pending)` — keep that guard if you touch the output step.
- Google News proxy titles carry a trailing `" - <Source Name>"` suffix; that's stripped for display in the command's Step 2, not here.

**`scripts/mark-seen.ps1`** — deterministic, no AI. Commits every item from `data/pending.json` (not just the ones that made the final page — see below) into `data/seen.json` as `guid -> date-first-seen`, prunes entries older than 14 days, and deletes `data/pending.json`.

**`.claude/commands/digest.md`** — the actual orchestration logic and the source of truth for behavior. Key design decisions baked into it:
- Relevance filtering (US politics/economy/major events, Israel & Middle East) and story clustering (merging near-duplicate coverage of the same story across outlets into one entry with multiple source names) are AI judgment calls made by Claude while running the command, not scripted.
- Discarded (irrelevant) items still get marked seen in Step 6, so they aren't re-evaluated on the next run.
- The HTML template (embedded CSS, two fixed sections: **United States** and **Israel & Middle East**) is written verbatim in the command file so the look stays consistent day to day — if the visual design changes, edit it there, since that's the only place it's defined.

**`data/`** and **`output/`** are gitignored — `data/seen.json` is runtime dedup state, `output/*.html` are generated pages (`latest.html` is overwritten each run; `digest-<date>.html` is kept per day).

## Gotchas specific to this environment

- No Node.js or Python on PATH (only a Windows Store stub for `python`) — everything here is intentionally PowerShell + Claude's own reasoning, not a script that shells out to an LLM API.
- Google News proxy feeds return redirect links (`news.google.com/rss/articles/...`), not direct article URLs — this is expected and fine, clicking still lands on the real article.
- A `when:1d` Google News query across 6 proxy feeds plus 3 native feeds can return 500-700+ raw items in one run. When reading `data/pending.json` directly (as opposed to running it through the command), avoid `Read`-ing the whole file — the base64-ish Google News `link`/`guid` fields tokenize very expensively. Pull just `source`/`title` lines (e.g. via Grep) for a first relevance pass, and look up full `link`/`guid` only for the items actually kept.

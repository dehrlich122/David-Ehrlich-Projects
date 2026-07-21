---
description: Fetch news from feeds.json, summarize/categorize new US and Israel stories with AI, and open a clean morning digest page
---

You are generating today's morning news digest. Follow these steps in order, in this single run. Do not stop partway to ask for confirmation — this command is meant to run start-to-finish unattended.

## Step 1 — Fetch new items

Run this via the PowerShell tool from the project root:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\fetch-new-items.ps1"
```

This deterministically fetches all 9 feeds from `feeds.json`, parses the RSS XML, filters out anything already recorded in `data/seen.json`, and writes the unseen items to `data/pending.json`. It prints a count when done. Per-feed failures are logged as warnings but don't stop the run — if a source fails, just proceed with what succeeded.

## Step 2 — Read the pending items

Read `data/pending.json`. It's a flat array of `{ source, title, link, guid, pubDate, description }`.

- Titles from the Google News proxy sources (AP, Reuters, AFP, NYT, FT, Washington Post) end with a trailing `" - <Source Name>"` — strip that suffix when you display the headline, since the source is already shown separately.
- If the array is empty, skip straight to Step 5 and render a short page that just says there's nothing new since yesterday (still with the same header/styling), then continue to Step 6 onward.

## Step 3 — Filter for relevance (your judgment, not a script)

Keep only stories that are meaningfully about:
- **The United States** — national politics/government, major policy, the economy, notable national events.
- **Israel & the Middle East** — Israeli politics/security, the region's conflicts and diplomacy, US–Israel relations.

Drop everything else: sports, celebrity/entertainment, unrelated local or regional stories, lifestyle pieces, listicles, etc. Be reasonably generous with borderline major-world-impact stories (e.g., a big US-relevant economic or security story), but the bar is "would this matter to someone catching up over coffee," not "every article mentioning the US in passing."

## Step 4 — Cluster and summarize (your judgment, not a script)

- Multiple outlets often cover the same story. Merge near-duplicate coverage of one underlying story into a single digest entry, and list all contributing source names on that entry (e.g. "Reuters, AP, BBC").
- For each surviving entry, write an original 2–3 sentence summary based on the title + description text — don't just copy the description verbatim.
- Assign each entry to exactly one section: **United States** or **Israel & Middle East**. For stories that cross both (e.g. US policy toward Israel), pick whichever is the more specific/primary focus — usually Israel & Middle East.
- Order entries within each section by recency (`pubDate`, newest first).

## Step 5 — Render the page

Write two files: `output/digest-<yyyy-MM-dd>.html` (today's date) and `output/latest.html` (same content, overwritten each run). Use exactly this structure and CSS so the look stays consistent day to day — fill in the header date and the two sections with the entries from Step 4:

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Morning Digest — {{Weekday, Month D, YYYY}}</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #faf8f4;
    --card: #ffffff;
    --ink: #1c1a17;
    --muted: #6b6459;
    --rule: #e6e1d8;
    --accent: #8a3324;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #17140f;
      --card: #201c16;
      --ink: #ece7dc;
      --muted: #a39a8a;
      --rule: #35301f;
      --accent: #e0a17c;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--ink);
    font-family: Georgia, 'Iowan Old Style', 'Palatino Linotype', serif;
    line-height: 1.5;
  }
  .wrap { max-width: 680px; margin: 0 auto; padding: 48px 24px 80px; }
  header { text-align: center; margin-bottom: 40px; }
  header .kicker {
    font-family: -apple-system, Segoe UI, sans-serif;
    font-size: 12px; letter-spacing: 0.14em; text-transform: uppercase;
    color: var(--accent); font-weight: 600; margin-bottom: 8px;
  }
  header h1 { font-size: 28px; margin: 0 0 6px; }
  header .date { color: var(--muted); font-size: 15px; }
  section.topic { margin-bottom: 44px; }
  section.topic h2 {
    font-family: -apple-system, Segoe UI, sans-serif;
    font-size: 13px; letter-spacing: 0.1em; text-transform: uppercase;
    color: var(--accent); border-bottom: 1px solid var(--rule);
    padding-bottom: 10px; margin-bottom: 4px; font-weight: 700;
  }
  article.item { padding: 20px 0; border-bottom: 1px solid var(--rule); }
  article.item:last-child { border-bottom: none; }
  article.item h3 { font-size: 19px; margin: 0 0 6px; line-height: 1.3; }
  article.item h3 a { color: var(--ink); text-decoration: none; }
  article.item h3 a:hover { text-decoration: underline; }
  article.item .src {
    font-family: -apple-system, Segoe UI, sans-serif;
    font-size: 12px; color: var(--muted); margin-bottom: 8px;
  }
  article.item p { margin: 0; color: var(--ink); font-size: 15.5px; }
  .empty { color: var(--muted); text-align: center; padding: 40px 0; font-style: italic; }
  footer {
    text-align: center; margin-top: 40px; color: var(--muted);
    font-family: -apple-system, Segoe UI, sans-serif; font-size: 12px;
  }
</style>
</head>
<body>
  <div class="wrap">
    <header>
      <div class="kicker">Morning Digest</div>
      <h1>United States &amp; Israel</h1>
      <div class="date">{{Weekday, Month D, YYYY}}</div>
    </header>

    <section class="topic">
      <h2>United States</h2>
      <!-- one <article class="item"> per entry, or <p class="empty">Nothing new since yesterday.</p> if none -->
      <article class="item">
        <h3><a href="{{link}}">{{headline}}</a></h3>
        <div class="src">{{Source A, Source B}}</div>
        <p>{{2-3 sentence summary}}</p>
      </article>
    </section>

    <section class="topic">
      <h2>Israel &amp; Middle East</h2>
      <!-- same pattern -->
    </section>

    <footer>Generated {{time}} · {{N}} stories from {{M}} sources</footer>
  </div>
</body>
</html>
```

## Step 6 — Commit seen state

Run this via the PowerShell tool:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\mark-seen.ps1"
```

This marks **every** item from `data/pending.json` as seen (including ones you discarded in Step 3), so they won't be re-fetched or re-evaluated tomorrow, and prunes seen-store entries older than 14 days. Do this even on a "nothing new" run — if `data/pending.json` didn't exist (Step 2 was empty from the start), this script will just no-op.

## Step 7 — Open it

Run via the PowerShell tool:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process (Resolve-Path 'output/latest.html')"
```

Then tell the user in one short sentence how many stories made the digest and that it's open in their browser.

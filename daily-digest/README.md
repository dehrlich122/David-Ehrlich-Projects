# Daily Digest

Automated daily news digest, run by a scheduled Claude Code cloud routine ("Daily News Digest") every morning at 6:00 AM Asia/Jerusalem.

- `feeds.json` — the 9 RSS/news sources the digest pulls from. Edit this file (add/remove/change a `url`) to change sources; no need to touch the routine itself.
- `artifact_url.txt` — holds the published digest's Artifact URL. The routine reads this at the start of each run and, if present, redeploys to the same URL (via the `url` param) instead of minting a new one each day. It commits the URL here after the first successful publish.

To manage the schedule (pause, change time, delete): https://claude.ai/code/routines

// This file holds the page's behavior (JavaScript) — as opposed to
// index.html (structure) and style.css (appearance). It's intentionally
// tiny: the only thing this page needs JS for is reading today's date,
// which HTML/CSS have no way to do on their own.

// `new Date()` creates an object representing the exact moment the page is
// loaded. `.getFullYear()` pulls just the 4-digit year out of it (e.g. 2026,
// then 2027 once the calendar turns over on January 1st, forever, with no
// further edits needed here).
const currentYear = new Date().getFullYear();

// `document.getElementById(...)` finds the one element in index.html with
// id="current-year" (the <span> around "2026" in the footer). Setting its
// `.textContent` replaces whatever text was inside it — the static "2026"
// fallback — with the real current year.
document.getElementById("current-year").textContent = currentYear;

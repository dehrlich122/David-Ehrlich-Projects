<#
Fetches every feed in feeds.json, parses the RSS XML, and writes any items
not already present in data/seen.json to data/pending.json.

Deterministic only - no AI judgment happens here. Relevance filtering,
clustering, and summarization are done by Claude in the /digest command
after this script runs.
#>

$ErrorActionPreference = 'Continue'

# RSS <title>/<description> nodes come back as XmlElement when the feed uses
# CDATA (e.g. BBC) and as plain String otherwise. A bare [string] cast on an
# XmlElement yields the literal text "System.Xml.XmlElement", not the content
# - so every node read goes through this helper instead.
function Get-NodeText {
    param($Node)
    if ($null -eq $Node) { return "" }
    if ($Node -is [string]) { return $Node }
    if ($Node.PSObject.Properties['InnerText']) { return $Node.InnerText }
    return [string]$Node
}

# --- Load config & dedup state ---

New-Item -ItemType Directory -Force -Path "data" | Out-Null

$feeds = (Get-Content "feeds.json" -Raw | ConvertFrom-Json).sources

# seen.json is a flat { guid: date-first-seen } map, written by mark-seen.ps1.
# Load it into a hashtable up front so the per-item lookup below is O(1).
$seenPath = "data/seen.json"
if (Test-Path $seenPath) {
    $seenRaw = Get-Content $seenPath -Raw | ConvertFrom-Json
} else {
    $seenRaw = [PSCustomObject]@{}
}
$seenHash = @{}
foreach ($p in $seenRaw.PSObject.Properties) { $seenHash[$p.Name] = $p.Value }

# --- Fetch every feed and collect items not already marked seen ---

$pending = @()

foreach ($feed in $feeds) {
    try {
        $resp = Invoke-WebRequest -Uri $feed.url -UseBasicParsing -TimeoutSec 25
        [xml]$xml = $resp.Content
        $items = $xml.rss.channel.item
        if (-not $items) { continue }

        foreach ($item in $items) {
            $link = Get-NodeText $item.link
            $guid = Get-NodeText $item.guid
            if (-not $guid) { $guid = $link }
            if (-not $guid) { continue }
            if ($seenHash.ContainsKey($guid)) { continue }

            # Strip HTML tags/entities out of the description so downstream
            # (Claude reading pending.json) gets plain summary text.
            $descRaw = Get-NodeText $item.description
            $desc = $descRaw -replace '<[^>]+>', '' -replace '&nbsp;', ' '
            $desc = $desc.Trim()

            $pending += [PSCustomObject]@{
                source      = $feed.name
                title       = Get-NodeText $item.title
                link        = $link
                guid        = $guid
                pubDate     = Get-NodeText $item.pubDate
                description = $desc
            }
        }
    } catch {
        # A single feed failing (timeout, bad XML, etc.) shouldn't abort the
        # whole run - log it and keep going with whatever else succeeded.
        Write-Warning "Failed to fetch $($feed.name): $($_.Exception.Message)"
    }
}

# --- Write pending.json for the /digest command to read next ---

# PS5.1 unwraps single-element arrays when converting to JSON unless forced.
$json = ConvertTo-Json -InputObject @($pending) -Depth 5
Set-Content -Path "data/pending.json" -Value $json -Encoding utf8

Write-Output "Fetched $($pending.Count) new item(s) across $($feeds.Count) source(s)."

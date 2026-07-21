<#
Fetches every feed in feeds.json, parses the RSS XML, and writes any items
not already present in data/seen.json to data/pending.json.

Deterministic only - no AI judgment happens here. Relevance filtering,
clustering, and summarization are done by Claude in the /digest command
after this script runs.
#>

$ErrorActionPreference = 'Continue'

function Get-NodeText {
    param($Node)
    if ($null -eq $Node) { return "" }
    if ($Node -is [string]) { return $Node }
    if ($Node.PSObject.Properties['InnerText']) { return $Node.InnerText }
    return [string]$Node
}

New-Item -ItemType Directory -Force -Path "data" | Out-Null

$feeds = (Get-Content "feeds.json" -Raw | ConvertFrom-Json).sources

$seenPath = "data/seen.json"
if (Test-Path $seenPath) {
    $seenRaw = Get-Content $seenPath -Raw | ConvertFrom-Json
} else {
    $seenRaw = [PSCustomObject]@{}
}
$seenHash = @{}
foreach ($p in $seenRaw.PSObject.Properties) { $seenHash[$p.Name] = $p.Value }

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
        Write-Warning "Failed to fetch $($feed.name): $($_.Exception.Message)"
    }
}

# PS5.1 unwraps single-element arrays when converting to JSON unless forced.
$json = ConvertTo-Json -InputObject @($pending) -Depth 5
Set-Content -Path "data/pending.json" -Value $json -Encoding utf8

Write-Output "Fetched $($pending.Count) new item(s) across $($feeds.Count) source(s)."

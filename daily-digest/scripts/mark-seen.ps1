<#
Commits every item from data/pending.json into data/seen.json (keyed by
guid -> date first seen), prunes entries older than 14 days, and deletes
data/pending.json. Run this AFTER the digest page has been generated, so
that even discarded (irrelevant) items don't get re-evaluated tomorrow.
#>

$ErrorActionPreference = 'Continue'

$pendingPath = "data/pending.json"
$seenPath = "data/seen.json"

# No pending file means fetch-new-items.ps1 either wasn't run or found
# nothing new - either way there's nothing to commit, so no-op cleanly.
if (-not (Test-Path $pendingPath)) {
    Write-Output "No pending file found - nothing to mark as seen."
    exit
}

$pending = Get-Content $pendingPath -Raw | ConvertFrom-Json

# --- Load existing seen state into a hashtable for merging ---

if (Test-Path $seenPath) {
    $seenRaw = Get-Content $seenPath -Raw | ConvertFrom-Json
} else {
    $seenRaw = [PSCustomObject]@{}
}
$seenHash = @{}
foreach ($p in $seenRaw.PSObject.Properties) { $seenHash[$p.Name] = $p.Value }

# --- Mark every pending item as seen today ---

# Every item from this run is recorded here - including ones Claude
# discarded as irrelevant in the /digest command - so they aren't
# re-fetched or re-evaluated on tomorrow's run.
$today = (Get-Date).ToString('yyyy-MM-dd')
foreach ($item in @($pending)) {
    if ($item.guid) { $seenHash[$item.guid] = $today }
}

# --- Prune anything older than 14 days so seen.json doesn't grow forever ---

$cutoff = (Get-Date).AddDays(-14)
$pruned = [ordered]@{}
foreach ($k in $seenHash.Keys) {
    $d = Get-Date -Date '0001-01-01'
    if ([datetime]::TryParse($seenHash[$k], [ref]$d) -and $d -ge $cutoff) {
        $pruned[$k] = $seenHash[$k]
    }
}

# --- Write back and clear pending.json so it doesn't get re-processed ---

$json = ConvertTo-Json -InputObject $pruned -Depth 5
Set-Content -Path $seenPath -Value $json -Encoding utf8
Remove-Item $pendingPath -Force

Write-Output "Marked $(@($pending).Count) item(s) as seen. Seen store now has $($pruned.Count) entrie(s)."

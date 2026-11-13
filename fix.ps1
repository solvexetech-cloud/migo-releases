$file = "admin\src\pages\BusinessesPage.jsx"
$content = Get-Content $file -Raw
$content = $content -replace 'Ã¢â‚¬â€', '—'
$content = $content -replace 'Ã¢Å“â€œ', '✓'
$content = $content -replace 'Ã¢â‚¬Â¦', '...'
$content = $content -replace 'Ã‚Â·', '·'
[System.IO.File]::WriteAllText("$pwd\$file", $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "✅ Fixed!" -ForegroundColor Green
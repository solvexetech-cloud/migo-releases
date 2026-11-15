$file = "admin\src\pages\CreatorsPage.jsx"
$content = Get-Content $file -Raw
$content = $content -replace 'â€”', '—'
[System.IO.File]::WriteAllText("$pwd\$file", $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "✅ Admin Creators Page fixed!" -ForegroundColor Green
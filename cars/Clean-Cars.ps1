<#
    Clean-Cars.ps1  -  run this ONLY when you want to put the cars on a GitHub
    release so Install.bat can download them anywhere. Not needed for a normal
    local install (Install.bat just takes whatever is in this folder).

    For every .zip/.rar/.7z in this folder it keeps only the data files
    (.dff .txd .txt .cfg .dat .ini .nfo), drops auto-installer .exe/.bat files
    and screenshots, writes a clean <name>.zip into .\publish\ and lists them
    with their SHA256 in ..\cars.json pointing at the release URL.

    Usage:  Clean-Cars.bat https://github.com/USER/REPO/releases/download/cars
    Then:   upload publish\*.zip to that release, commit cars.json.
#>
param([Parameter(Mandatory = $true)][string]$ReleaseUrl)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$pub = Join-Path $here 'publish'
$keep = '.dff', '.txd', '.txt', '.cfg', '.dat', '.ini', '.nfo'

$sz = $null
foreach ($c in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) { if ($c -and (Test-Path -LiteralPath $c)) { $sz = $c; break } }
if (-not $sz) { foreach ($n in '7z', '7za', '7zz') { $cmd = Get-Command $n -ErrorAction SilentlyContinue; if ($cmd) { $sz = $cmd.Source; break } } }

function Expand-Any([string]$archive, [string]$dest) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    if ([IO.Path]::GetExtension($archive) -ieq '.zip') { try { Expand-Archive -LiteralPath $archive -DestinationPath $dest -Force; return } catch {} }
    if (-not $sz) { throw "7-Zip is needed for .rar/.7z (winget install 7zip.7zip)" }
    & $sz x "-o$dest" -y -bso0 -bsp0 -- $archive | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip could not open it (exit $LASTEXITCODE)" }
}

New-Item -ItemType Directory -Path $pub -Force | Out-Null
$items = @()
foreach ($a in (Get-ChildItem -LiteralPath $here -File | Where-Object { $_.Extension -in '.zip', '.rar', '.7z' } | Sort-Object Name)) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("carclean_" + [guid]::NewGuid().ToString('N'))
    try { Expand-Any $a.FullName $tmp } catch { Write-Host "[!!] $($a.Name): $($_.Exception.Message) - skipped" -ForegroundColor Yellow; continue }
    $all = Get-ChildItem -LiteralPath $tmp -Recurse -File
    $removed = @($all | Where-Object { $_.Extension.ToLowerInvariant() -notin $keep })
    $removed | Remove-Item -Force
    $kept = @(Get-ChildItem -LiteralPath $tmp -Recurse -File)
    if (-not ($kept | Where-Object { $_.Extension -in '.dff', '.txd' })) {
        Write-Host "[!!] $($a.Name): no .dff/.txd inside - not a car mod, skipped" -ForegroundColor Yellow
        Remove-Item -LiteralPath $tmp -Recurse -Force; continue
    }
    $dest = Join-Path $pub ($a.BaseName + '.zip')
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
    Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $dest -CompressionLevel Optimal
    Remove-Item -LiteralPath $tmp -Recurse -Force
    $d = Get-Item -LiteralPath $dest
    $items += [ordered]@{ name = $d.Name; url = ($ReleaseUrl.TrimEnd('/') + '/' + [Uri]::EscapeDataString($d.Name)); sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $dest).Hash.ToUpperInvariant() }
    Write-Host ("[ok] {0,-20} {1,7:N2} MB -> {2,7:N2} MB   kept {3}, dropped {4}" -f $a.Name, ($a.Length / 1MB), ($d.Length / 1MB), $kept.Count, $removed.Count) -ForegroundColor Green
    foreach ($r in ($removed | Where-Object { $_.Extension -in '.exe', '.bat', '.cmd', '.msi', '.scr', '.vbs', '.dll', '.com' })) { Write-Host "      dropped executable: $($r.Name)" -ForegroundColor DarkYellow }
}
if ($items.Count -eq 0) { throw "no usable car archives in $here" }
$manifest = Join-Path (Split-Path -Parent $here) 'cars.json'
ConvertTo-Json @($items) -Depth 3 | Set-Content -LiteralPath $manifest -Encoding UTF8
Write-Host ""
Write-Host "[ok] wrote $manifest with $($items.Count) car(s)." -ForegroundColor Green
Write-Host "Next: upload everything in  $pub  to the release at  $ReleaseUrl  and commit cars.json." -ForegroundColor Yellow

<#
    Clean-Cars.ps1  -  makes clean copies of the car archives in this folder.

    For every .zip/.rar/.7z here it keeps only the data files
    (.dff .txd .txt .cfg .dat .ini .nfo), drops auto-installer .exe/.bat files,
    screenshots and anything else, writes the result as clean\<name>.zip and
    lists the clean files with their SHA256 in ..\cars.json.
    The originals here are not touched.

    Usage: double-click Clean-Cars.bat, then upload clean\*.zip to the GitHub
    release named in install.ps1 ($CarsRelease) and commit cars.json.
    To pin an archive to a vehicle, add  "slot": "infernus"  to its entry in
    cars.json (kept on re-runs).

    Not needed for a normal install: Install.bat only ever copies .dff/.txd
    and text files out of an archive and ignores everything else anyway.
#>
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$clean = Join-Path $here 'clean'
New-Item -ItemType Directory -Path $clean -Force | Out-Null
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

$manifest = Join-Path (Split-Path -Parent $here) 'cars.json'
$oldSlots = @{}
if (Test-Path -LiteralPath $manifest) {
    try { foreach ($e in @(Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json)) { if ($e.name -and $e.slot) { $oldSlots[$e.name] = $e.slot } } } catch {}
}
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
    $dest = Join-Path $clean ($a.BaseName + '.zip')
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($tmp, $dest, [IO.Compression.CompressionLevel]::Optimal, $false)
    Remove-Item -LiteralPath $tmp -Recurse -Force
    $origLen = $a.Length
    $d = Get-Item -LiteralPath $dest
    $entry = [ordered]@{ name = $d.Name; sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $dest).Hash.ToUpperInvariant() }
    if ($oldSlots.ContainsKey($d.Name)) { $entry.slot = $oldSlots[$d.Name] }
    $items += $entry
    Write-Host ("[ok] {0,-20} {1,7:N2} MB -> {2,7:N2} MB  {3,-14} kept {4}, dropped {5}" -f $a.Name, ($origLen / 1MB), ($d.Length / 1MB), ("-> clean\" + $d.Name), $kept.Count, $removed.Count) -ForegroundColor Green
    foreach ($r in ($removed | Where-Object { $_.Extension -in '.exe', '.bat', '.cmd', '.msi', '.scr', '.vbs', '.dll', '.com' })) { Write-Host "      dropped executable: $($r.Name)" -ForegroundColor DarkYellow }
}
if ($items.Count -eq 0) { Write-Host "no car archives found in $here"; exit }
ConvertTo-Json @($items) -Depth 3 | Set-Content -LiteralPath $manifest -Encoding UTF8
Write-Host ""
Write-Host "[ok] $($items.Count) clean data-only .zip file(s) in $clean (originals untouched); cars.json updated." -ForegroundColor Green
Write-Host "Next: upload the files in clean\ to the GitHub release named in install.ps1 and commit cars.json." -ForegroundColor Yellow

<#
    Clean-Cars.ps1  -  cleans the car archives in this folder IN PLACE.

    For every .zip/.rar/.7z here it keeps only the data files
    (.dff .txd .txt .cfg .dat .ini .nfo), drops auto-installer .exe/.bat files,
    screenshots and anything else, and replaces the archive with a clean
    <name>.zip (a .rar/.7z becomes a .zip; the original is deleted).

    Usage:  Clean-Cars.bat
            Clean-Cars.bat https://github.com/USER/REPO/releases/download/cars
              -> additionally writes ..\cars.json (name, URL, SHA256) so that
                 Install.bat can download the same files from that release.

    Not needed for a normal install: Install.bat only ever copies .dff/.txd
    and text files out of an archive and ignores everything else anyway.
#>
param([string]$ReleaseUrl)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
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
    $dest = Join-Path $here ($a.BaseName + '.zip')
    $stage = Join-Path $here ($a.BaseName + '.clean.zip')   # Compress-Archive only accepts a .zip name
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Force }
    Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $stage -CompressionLevel Optimal
    Remove-Item -LiteralPath $tmp -Recurse -Force
    $origLen = $a.Length
    Remove-Item -LiteralPath $a.FullName -Force            # the original (.zip/.rar/.7z) is replaced by the clean .zip
    Move-Item -LiteralPath $stage -Destination $dest -Force
    $d = Get-Item -LiteralPath $dest
    $items += [ordered]@{ name = $d.Name; url = (("$ReleaseUrl").TrimEnd('/') + '/' + [Uri]::EscapeDataString($d.Name)); sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $dest).Hash.ToUpperInvariant() }
    Write-Host ("[ok] {0,-20} {1,7:N2} MB -> {2,7:N2} MB  {3,-14} kept {4}, dropped {5}" -f $a.Name, ($origLen / 1MB), ($d.Length / 1MB), ("-> " + $d.Name), $kept.Count, $removed.Count) -ForegroundColor Green
    foreach ($r in ($removed | Where-Object { $_.Extension -in '.exe', '.bat', '.cmd', '.msi', '.scr', '.vbs', '.dll', '.com' })) { Write-Host "      dropped executable: $($r.Name)" -ForegroundColor DarkYellow }
}
if ($items.Count -eq 0) { Write-Host "no car archives found in $here"; exit }
Write-Host ""
Write-Host "[ok] $($items.Count) archive(s) in $here are now data-only .zip files." -ForegroundColor Green
if ($ReleaseUrl) {
    $manifest = Join-Path (Split-Path -Parent $here) 'cars.json'
    ConvertTo-Json @($items) -Depth 3 | Set-Content -LiteralPath $manifest -Encoding UTF8
    Write-Host "[ok] wrote $manifest" -ForegroundColor Green
    Write-Host "Next: upload the .zip files from this folder to the release at  $ReleaseUrl  and commit cars.json." -ForegroundColor Yellow
} else {
    Write-Host "To also write cars.json for a GitHub release, run again with the release URL as argument." -ForegroundColor Yellow
}

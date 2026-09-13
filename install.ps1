<#
.SYNOPSIS
    "Ultimate mod" installer for the classic PC GTA: Vice City
    (infinite health, infinite money, custom cars, Win11 mouse fix, controller notes).

.DESCRIPTION
    Everything this script downloads comes from the projects' own GitHub release
    pages and is checked against a SHA256 hash baked into this file before it is
    used. Nothing is executed from a download; only files are copied.
    Every game file it changes is copied to  <game>\_ultimate_mod_backup\<time>\
    first, so  -Restore  (or Restore-Backup.bat) puts everything back.

.PARAMETER GamePath
    Folder that contains gta-vc.exe. Auto-detected (Steam / common paths) or asked for.
.PARAMETER SkipSilentPatch
    Do not install SilentPatch (bug/mouse/Win8+ compatibility fixes).
.PARAMETER SkipMouseFix
    Do not write the Windows compatibility flags for gta-vc.exe.
.PARAMETER SkipCars
    Do not touch gta3.img / handling / carcols (ignore the cars\ folder).
.PARAMETER InstallMouseFixAsi
    Also install sfwidde's mousefix.asi (only works with the 1.0 exe; skipped otherwise).
.PARAMETER NoDownload
    Never touch the network; use the zips already in .\downloads\ (still hash-checked).
.PARAMETER Restore
    Undo: copy the newest backup back and delete the files that were added.
.PARAMETER BackupDir
    With -Restore: a specific backup folder instead of the newest one.
.PARAMETER Yes
    Do not pause for confirmation.
#>
[CmdletBinding()]
param(
    [string]$GamePath,
    [switch]$SkipSilentPatch,
    [switch]$SkipMouseFix,
    [switch]$SkipCars,
    [switch]$InstallMouseFixAsi,
    [switch]$NoDownload,
    [switch]$Restore,
    [string]$BackupDir,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Windows PowerShell 5.1 downloads are 10x slower with the progress bar
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$IsWin = ($env:OS -eq 'Windows_NT')

# ---------------------------------------------------------------------------
# Pinned downloads (version-locked URL + SHA256 of the zip).  If a hash does not
# match, the file is thrown away and the step is skipped with a loud warning.
# ---------------------------------------------------------------------------
$Packages = @{
    AsiLoader = @{
        Name = 'Ultimate ASI Loader v9.7.4 (ThirteenAG)'
        File = 'Ultimate-ASI-Loader-v9.7.4.zip'
        Url  = 'https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/download/v9.7.4/Ultimate-ASI-Loader.zip'
        Sha  = '952CEBFC30D525AFC2BDBACA954329D405DED3AA688A83027354DAE14DFD5C5F'
    }
    Cleo = @{
        Name = 'CLEO 2.2.0 for Vice City (cleolibrary)'
        File = 'VC.CLEO-v2.2.0.zip'
        Url  = 'https://github.com/cleolibrary/III.VC.CLEO/releases/download/v2.2.0/VC.CLEO-v2.2.0.zip'
        Sha  = '18479D1E3D72C24B2282E66100ABADEEE881676C744216565D9B493DD153A243'
    }
    SilentPatch = @{
        Name = 'SilentPatch VC build 12.1 (Silent)'
        File = 'SilentPatchVC-1.1-BUILD34.1-SA.zip'
        Url  = 'https://github.com/CookiePLMonster/SilentPatch/releases/download/1.1-BUILD34.1-SA/SilentPatchVC.zip'
        Sha  = '37189B72835316AC1D20D13E686D5FE986FFDE51755DE5D730BA5795378840AB'
    }
    MouseFix = @{
        Name = 'gta-vc-mouse-fix v3.0.2 (sfwidde) - 1.0 exe only'
        File = 'mousefix-v3.0.2.zip'
        Url  = 'https://github.com/sfwidde/gta-vc-mouse-fix/releases/download/v3.0.2/mousefix.zip'
        Sha  = 'C0F11F63E25DB247B69E76248F3DBDD947F3FFDE69C2444224741C7B39B1B4E2'
    }
}

# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------
function Write-Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "    [ok] $msg" -ForegroundColor Green }
function Write-Warn2([string]$msg){ Write-Host "    [!!] $msg" -ForegroundColor Yellow }
function Write-Info([string]$msg) { Write-Host "    $msg" }

function Get-Sha256([string]$path) {
    (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToUpperInvariant()
}

function Get-Package([hashtable]$pkg) {
    # Returns the local path of a verified zip, or $null if it could not be obtained.
    $dlDir = Join-Path $ScriptRoot 'downloads'
    if (-not (Test-Path -LiteralPath $dlDir)) { New-Item -ItemType Directory -Path $dlDir | Out-Null }
    $local = Join-Path $dlDir $pkg.File

    if (Test-Path -LiteralPath $local) {
        if ((Get-Sha256 $local) -eq $pkg.Sha) { Write-Ok "$($pkg.Name): already downloaded, hash OK"; return $local }
        Write-Warn2 "$($pkg.File) exists but its hash is wrong - deleting it"
        Remove-Item -LiteralPath $local -Force
    }
    if ($NoDownload) { Write-Warn2 "$($pkg.Name): missing and -NoDownload given"; return $null }

    Write-Info "downloading $($pkg.Url)"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $tmp = "$local.part"
        Invoke-WebRequest -Uri $pkg.Url -OutFile $tmp -UseBasicParsing
        $got = Get-Sha256 $tmp
        if ($got -ne $pkg.Sha) {
            Remove-Item -LiteralPath $tmp -Force
            Write-Warn2 "$($pkg.Name): SHA256 mismatch (got $got). The upstream file changed - NOT installing it."
            return $null
        }
        Move-Item -LiteralPath $tmp -Destination $local -Force
        Write-Ok "$($pkg.Name): downloaded, hash OK"
        return $local
    } catch {
        Write-Warn2 "$($pkg.Name): download failed - $($_.Exception.Message)"
        return $null
    }
}

function Find-7Zip {
    # 7-Zip is needed for .rar / .7z car archives (libertycity ships .rar). Returns the exe path or $null.
    $cands = @()
    if ($env:ProgramFiles) { $cands += (Join-Path $env:ProgramFiles '7-Zip\7z.exe') }
    if (${env:ProgramFiles(x86)}) { $cands += (Join-Path ${env:ProgramFiles(x86)} '7-Zip\7z.exe') }
    if ($env:LOCALAPPDATA) { $cands += (Join-Path $env:LOCALAPPDATA 'Programs\7-Zip\7z.exe') }
    foreach ($c in $cands) { if (Test-Path -LiteralPath $c) { return $c } }
    foreach ($n in '7z', '7za', '7zz', '7zr') {
        $cmd = Get-Command $n -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Install-7Zip {
    # Try to get 7-Zip via winget (built into Windows 10/11). Returns the exe path or $null.
    if (-not $IsWin) { return $null }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $null }
    Write-Info "7-Zip not found - installing it with winget (needed to open .rar car archives)..."
    try {
        & winget install --id 7zip.7zip -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
    } catch {}
    return (Find-7Zip)
}

function Expand-ToTemp([string]$archive) {
    $dest = Join-Path ([System.IO.Path]::GetTempPath()) ("vcmod_" + [System.IO.Path]::GetFileNameWithoutExtension($archive) + "_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $ext = [System.IO.Path]::GetExtension($archive).ToLowerInvariant()
    if ($ext -eq '.zip') {
        try { Expand-Archive -LiteralPath $archive -DestinationPath $dest -Force; return $dest } catch { }
    }
    $sz = $script:SevenZip
    if (-not $sz) { throw "cannot open '$([System.IO.Path]::GetFileName($archive))' - 7-Zip is not installed (get it from https://www.7-zip.org or run: winget install 7zip.7zip)" }
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    & $sz x "-o$dest" -y -bso0 -bsp0 -- "$archive" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip failed to extract '$([System.IO.Path]::GetFileName($archive))' (exit code $LASTEXITCODE)" }
    return $dest
}

# ---------------------------------------------------------------------------
# Game folder / exe version
# ---------------------------------------------------------------------------
function Find-GamePath {
    if ($GamePath) { return $GamePath }
    $candidates = @()
    if ($IsWin) {
        foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
            try {
                $p = (Get-ItemProperty -Path $key -ErrorAction Stop).InstallPath
                if ($p) { $candidates += (Join-Path $p 'steamapps\common\Grand Theft Auto Vice City') }
            } catch {}
        }
        try {
            $p = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto Vice City' -ErrorAction Stop).InstallFolder
            if ($p) { $candidates += $p }
        } catch {}
        $candidates += @(
            'C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto Vice City',
            'C:\Program Files (x86)\Rockstar Games\Grand Theft Auto Vice City',
            'C:\Program Files\Rockstar Games\Grand Theft Auto Vice City',
            'C:\Games\Grand Theft Auto Vice City',
            'D:\Games\Grand Theft Auto Vice City'
        )
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c 'gta-vc.exe'))) { return $c }
    }
    if ($Yes) { throw "Game folder not found. Run again with -GamePath 'C:\path\to\Grand Theft Auto Vice City'." }
    Write-Host ""
    $p = Read-Host "Could not auto-detect the game. Paste the full path of the folder that contains gta-vc.exe"
    return $p.Trim('"').Trim()
}

function Get-ExeVersion([string]$exe) {
    # Same check CLEO does at runtime: the DWORD at virtual address 0x61C11C.
    # Ids come from cleolibrary/III.VC.CLEO source (Game.cpp).
    try {
        $b = [System.IO.File]::ReadAllBytes($exe)
        if ($b.Length -lt 0x40 -or $b[0] -ne 0x4D -or $b[1] -ne 0x5A) { return 'not a Windows exe' }
        $pe = [BitConverter]::ToInt32($b, 0x3C)
        if ([BitConverter]::ToUInt32($b, $pe) -ne 0x00004550) { return 'not a PE file' }
        $nSections = [BitConverter]::ToUInt16($b, $pe + 6)
        $optSize   = [BitConverter]::ToUInt16($b, $pe + 20)
        $imageBase = [BitConverter]::ToUInt32($b, $pe + 24 + 28)
        $rva = [uint32]0x61C11C - $imageBase
        $secTable = $pe + 24 + $optSize
        for ($i = 0; $i -lt $nSections; $i++) {
            $s = $secTable + $i * 40
            $va   = [BitConverter]::ToUInt32($b, $s + 12)
            $vsz  = [BitConverter]::ToUInt32($b, $s + 8)
            $raw  = [BitConverter]::ToUInt32($b, $s + 20)
            $rsz  = [BitConverter]::ToUInt32($b, $s + 16)
            $span = [Math]::Max($vsz, $rsz)
            if ($rva -ge $va -and $rva -lt ($va + $span)) {
                $off = $rva - $va + $raw
                if ($off + 4 -gt $b.Length) { return 'unknown' }
                $id = [BitConverter]::ToUInt32($b, [int]$off)
                switch ($id) {
                    0x74FF5064 { return '1.0' }
                    0x00408DC0 { return '1.1' }
                    0x00004824 { return 'Steam' }
                    0x24E58287 { return 'Steam' }
                    default    { return ('unknown (id 0x{0:X8})' -f $id) }
                }
            }
        }
        return 'unknown'
    } catch { return "unknown ($($_.Exception.Message))" }
}

# ---------------------------------------------------------------------------
# Backup / manifest
# ---------------------------------------------------------------------------
$script:Manifest = @{ Backed = @(); Added = @(); Registry = @{} }
$script:BackupRoot = $null

function Get-Rel([string]$full) {
    return $full.Substring($Game.Length).TrimStart('\', '/')
}

function Backup-File([string]$full) {
    # Copies <game>\rel to backup once; records it. Returns $true if the file existed.
    $rel = Get-Rel $full
    if (-not (Test-Path -LiteralPath $full)) { return $false }
    if ($script:Manifest.Backed -contains $rel) { return $true }
    $dest = Join-Path $script:BackupRoot $rel
    $dd = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $dd)) { New-Item -ItemType Directory -Path $dd -Force | Out-Null }
    Copy-Item -LiteralPath $full -Destination $dest -Force
    $script:Manifest.Backed += $rel
    return $true
}

function Install-File([string]$src, [string]$destFull) {
    # Copy one file into the game folder with backup + manifest bookkeeping.
    $existed = Backup-File $destFull
    $dd = Split-Path -Parent $destFull
    if (-not (Test-Path -LiteralPath $dd)) { New-Item -ItemType Directory -Path $dd -Force | Out-Null }
    Copy-Item -LiteralPath $src -Destination $destFull -Force
    if (-not $existed) {
        $rel = Get-Rel $destFull
        if ($script:Manifest.Added -notcontains $rel) { $script:Manifest.Added += $rel }
    }
}

function Install-Tree([string]$srcDir, [string[]]$exclude) {
    # Copy a whole extracted folder into the game folder.
    Get-ChildItem -LiteralPath $srcDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($srcDir.Length).TrimStart('\', '/')
        $skip = $false
        foreach ($x in $exclude) { if ($rel -like $x) { $skip = $true } }
        if (-not $skip) { Install-File $_.FullName (Join-Path $Game $rel) }
    }
}

function Save-Manifest {
    $script:Manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $script:BackupRoot 'manifest.json') -Encoding UTF8
}

# ---------------------------------------------------------------------------
# IMG v1 archive (gta3.img + gta3.dir): 32-byte entries, 2048-byte sectors
# ---------------------------------------------------------------------------
function Read-ImgDir([string]$dirPath) {
    $b = [System.IO.File]::ReadAllBytes($dirPath)
    $entries = New-Object System.Collections.ArrayList
    for ($i = 0; $i + 32 -le $b.Length; $i += 32) {
        $name = [System.Text.Encoding]::ASCII.GetString($b, $i + 8, 24)
        $nul = $name.IndexOf([char]0); if ($nul -ge 0) { $name = $name.Substring(0, $nul) }
        [void]$entries.Add([pscustomobject]@{
            Offset = [BitConverter]::ToUInt32($b, $i)
            Size   = [BitConverter]::ToUInt32($b, $i + 4)
            Name   = $name
        })
    }
    return $entries
}

function Write-ImgDir([string]$dirPath, $entries) {
    $out = New-Object byte[] ($entries.Count * 32)
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $e = $entries[$i]
        [Array]::Copy([BitConverter]::GetBytes([uint32]$e.Offset), 0, $out, $i * 32, 4)
        [Array]::Copy([BitConverter]::GetBytes([uint32]$e.Size),   0, $out, $i * 32 + 4, 4)
        $nb = [System.Text.Encoding]::ASCII.GetBytes($e.Name)
        [Array]::Copy($nb, 0, $out, $i * 32 + 8, [Math]::Min($nb.Length, 23))
    }
    [System.IO.File]::WriteAllBytes($dirPath, $out)
}

function Set-ImgFile([string]$imgPath, [string]$dirPath, $entries, [string]$srcFile, [string]$name) {
    # Replace the existing entry called $name with the contents of $srcFile.
    if (-not $name) { $name = [System.IO.Path]::GetFileName($srcFile) }
    $entry = $entries | Where-Object { $_.Name -ieq $name } | Select-Object -First 1
    if (-not $entry) { return $false }
    $data = [System.IO.File]::ReadAllBytes($srcFile)
    $sectors = [uint32][Math]::Ceiling($data.Length / 2048.0)
    if ($sectors -eq 0) { $sectors = 1 }
    $fs = [System.IO.File]::Open($imgPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
    try {
        if ($sectors -le $entry.Size) {
            $pos = [int64]$entry.Offset * 2048
        } else {
            # does not fit in place -> append at the end (sector aligned), old bytes become dead space
            $end = $fs.Length
            $newOffset = [uint32][Math]::Ceiling($end / 2048.0)
            $pos = [int64]$newOffset * 2048
            $entry.Offset = $newOffset
        }
        $fs.Position = $pos
        $fs.Write($data, 0, $data.Length)
        $pad = [int]($sectors * 2048 - $data.Length)
        if ($pad -gt 0) { $fs.Write((New-Object byte[] $pad), 0, $pad) }
        $entry.Size = $sectors
    } finally { $fs.Close() }
    Write-ImgDir $dirPath $entries
    return $true
}

function Read-VehicleSlots([string]$idePath) {
    # data\default.ide 'cars' section:  id, model, txd, type, handlingId, gxtName, class, ...
    $slots = @{}
    if (-not (Test-Path -LiteralPath $idePath)) { return $slots }
    $in = $false
    foreach ($raw in [System.IO.File]::ReadAllLines($idePath)) {
        $l = $raw.Trim()
        if (-not $l -or $l.StartsWith('#')) { continue }
        if ($l -ieq 'cars') { $in = $true; continue }
        if ($l -ieq 'end') { $in = $false; continue }
        if (-not $in) { continue }
        $t = $l.Split(',') | ForEach-Object { $_.Trim() }
        if ($t.Count -ge 5) { $slots[$t[1].ToLowerInvariant()] = @{ Model = $t[1]; Txd = $t[2]; Type = $t[3]; Handling = $t[4] } }
    }
    return $slots
}

function Set-FirstToken([string]$line, [string]$token, [string]$kind) {
    # Rewrites the vehicle-name token of a handling.cfg / carcols.dat line.
    $line = $line.Trim()
    if ($kind -eq 'carcols') {
        $i = $line.IndexOf(','); if ($i -lt 0) { return $line }
        return $token + $line.Substring($i)
    }
    $m = [regex]::Match($line, '^([%!$]\s+)?(\S+)(.*)$')
    if (-not $m.Success) { return $line }
    return $m.Groups[1].Value + $token + $m.Groups[3].Value
}

function Compact-Img([string]$imgPath, [string]$dirPath, $entries) {
    # Rewrites gta3.img so it contains exactly the current entries, back to back.
    # Replaced files that did not fit in place were appended, leaving the old
    # bytes as dead space; this removes them for good.
    $used = 0; foreach ($e in $entries) { $used += [int64]$e.Size * 2048 }
    $len = (Get-Item -LiteralPath $imgPath).Length
    if ($len -le $used) { return }
    $tmp = "$imgPath.compact"
    $in  = [System.IO.File]::Open($imgPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    $out = [System.IO.File]::Open($tmp, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    try {
        $buf = New-Object byte[] (1024 * 1024)
        $pos = [uint32]0
        foreach ($e in $entries) {
            $in.Position = [int64]$e.Offset * 2048
            $left = [int64]$e.Size * 2048
            while ($left -gt 0) {
                $n = $in.Read($buf, 0, [int][Math]::Min($buf.Length, $left))
                if ($n -le 0) { break }
                $out.Write($buf, 0, $n); $left -= $n
            }
            if ($left -gt 0) { $out.Write((New-Object byte[] $left), 0, [int]$left) }   # truncated source: pad
            $e.Offset = $pos
            $pos += $e.Size
        }
    } finally { $in.Close(); $out.Close() }
    Move-Item -LiteralPath $tmp -Destination $imgPath -Force
    Write-ImgDir $dirPath $entries
    Write-Ok ("gta3.img compacted: {0:N2} MB of old car data removed" -f (($len - $used) / 1MB))
}

function Update-DataLine([string]$dataFile, [string]$newLine, [string]$kind) {
    # Replace the line in handling.cfg / carcols.dat whose vehicle name matches $newLine's.
    $newLine = $newLine.Trim()
    if (-not $newLine -or $newLine.StartsWith(';') -or $newLine.StartsWith('#')) { return $false }
    function KeyOf([string]$l, [string]$k) {
        $l = $l.Trim()
        if ($k -eq 'carcols') { return ($l.Split(',')[0]).Trim().ToLowerInvariant() }
        $t = $l -split '\s+'
        if ($t.Count -gt 1 -and $t[0] -in '%', '!', '$') { return $t[1].ToLowerInvariant() }
        return $t[0].ToLowerInvariant()
    }
    $key = KeyOf $newLine $kind
    if (-not $key) { return $false }
    $lines = [System.IO.File]::ReadAllLines($dataFile)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i].Trim()
        if (-not $l -or $l.StartsWith(';') -or $l.StartsWith('#')) { continue }
        if ((KeyOf $l $kind) -eq $key) {
            Backup-File $dataFile | Out-Null
            $lines[$i] = $newLine
            [System.IO.File]::WriteAllLines($dataFile, $lines)
            return $true
        }
    }
    return $false
}

# ---------------------------------------------------------------------------
# RESTORE
# ---------------------------------------------------------------------------
function Invoke-Restore {
    $Game = Find-GamePath
    $Game = (Resolve-Path -LiteralPath $Game).Path.TrimEnd('\', '/')
    $root = Join-Path $Game '_ultimate_mod_backup'
    if ($BackupDir) { $dir = $BackupDir }
    else {
        if (-not (Test-Path -LiteralPath $root)) { throw "No backups found in $root" }
        $dir = (Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name | Select-Object -Last 1).FullName
    }
    $mf = Join-Path $dir 'manifest.json'
    if (-not (Test-Path -LiteralPath $mf)) { throw "manifest.json not found in $dir" }
    $m = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
    Write-Step "Restoring from $dir"
    foreach ($rel in @($m.Added)) {
        if (-not $rel) { continue }
        $f = Join-Path $Game $rel
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force; Write-Info "removed $rel" }
    }
    # tidy up folders that only existed for the added files
    foreach ($rel in @($m.Added)) {
        if (-not $rel) { continue }
        $d = Split-Path -Parent (Join-Path $Game $rel)
        while ($d -and $d.Length -gt $Game.Length -and (Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force | Select-Object -First 1)) {
            Remove-Item -LiteralPath $d -Force; $d = Split-Path -Parent $d
        }
    }
    foreach ($rel in @($m.Backed)) {
        if (-not $rel) { continue }
        $src = Join-Path $dir $rel
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $Game $rel) -Force; Write-Info "restored $rel" }
    }
    if ($IsWin -and $m.Registry) {
        $layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
        foreach ($p in $m.Registry.PSObject.Properties) {
            if ($p.Value) { Set-ItemProperty -Path $layers -Name $p.Name -Value $p.Value }
            else { Remove-ItemProperty -Path $layers -Name $p.Name -ErrorAction SilentlyContinue }
            Write-Info "registry compat flags for $($p.Name) restored"
        }
    }
    # empty CLEO folders are harmless; leave them.
    Write-Ok "Restore complete."
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
if ($Restore) { Invoke-Restore; exit 0 }

Write-Host "GTA Vice City - Ultimate mod installer" -ForegroundColor Magenta
Write-Host "--------------------------------------"

$Game = Find-GamePath
if (-not (Test-Path -LiteralPath (Join-Path $Game 'gta-vc.exe'))) { throw "gta-vc.exe not found in '$Game'" }
$Game = (Resolve-Path -LiteralPath $Game).Path.TrimEnd('\', '/')
$Exe  = Join-Path $Game 'gta-vc.exe'
$ExeVersion = Get-ExeVersion $Exe

Write-Info "Game folder : $Game"
Write-Info "Exe version : $ExeVersion"
if ($ExeVersion -like 'unknown*') {
    Write-Warn2 "This exe is not a known 1.0 / 1.1 / Steam build (a repack may have patched it)."
    Write-Warn2 "CLEO may refuse to load. SilentPatch still works on most builds. Continuing."
}

# write access / elevation
$probe = Join-Path $Game ('.writetest_' + [guid]::NewGuid().ToString('N'))
try { [System.IO.File]::WriteAllText($probe, 'x'); Remove-Item -LiteralPath $probe -Force }
catch {
    if ($IsWin) {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Warn2 "No write access to the game folder - re-launching as administrator..."
            $relaunch = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $MyInvocation.MyCommand.Path + '"'), '-GamePath', ('"' + $Game + '"'))
            foreach ($k in $PSBoundParameters.Keys) {
                if ($k -eq 'GamePath') { continue }
                $v = $PSBoundParameters[$k]
                if ($v -is [switch]) { if ($v) { $relaunch += "-$k" } } else { $relaunch += "-$k"; $relaunch += ('"' + $v + '"') }
            }
            Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ($relaunch -join ' ') -Wait
            exit 0
        }
    }
    throw "Cannot write to '$Game': $($_.Exception.Message)"
}

if (-not $Yes) {
    Write-Host ""
    Write-Host "About to install into: $Game" -ForegroundColor Yellow
    Write-Host "A full backup of every changed file goes to $Game\_ultimate_mod_backup\ first."
    $ans = Read-Host "Continue? [Y/n]"
    if ($ans -and $ans.Trim().ToLower().StartsWith('n')) { Write-Host "Aborted."; exit 1 }
}

$script:SevenZip = Find-7Zip
$script:BackupRoot = Join-Path (Join-Path $Game '_ultimate_mod_backup') (Get-Date -Format 'yyyyMMdd_HHmmss')
New-Item -ItemType Directory -Path $script:BackupRoot -Force | Out-Null
$Summary = New-Object System.Collections.ArrayList

# ---- 1. ASI loader ---------------------------------------------------------
Write-Step "1/6  ASI loader (dinput8.dll) - lets the game load .asi plugins"
$dinput = Join-Path $Game 'dinput8.dll'
if (Test-Path -LiteralPath $dinput) {
    Write-Ok "dinput8.dll already present - keeping it (assumed to be an ASI loader)"
    [void]$Summary.Add("ASI loader: kept existing dinput8.dll")
} else {
    $zip = Get-Package $Packages.AsiLoader
    if ($zip) {
        $tmp = Expand-ToTemp $zip
        $dll = Get-ChildItem -LiteralPath $tmp -Recurse -Filter 'dinput8.dll' | Select-Object -First 1
        if (-not $dll) { $dll = Get-ChildItem -LiteralPath $tmp -Recurse -Filter '*.dll' | Select-Object -First 1 }
        Install-File $dll.FullName $dinput
        Remove-Item -LiteralPath $tmp -Recurse -Force
        Write-Ok "installed dinput8.dll"
        [void]$Summary.Add("ASI loader: installed")
    } else { [void]$Summary.Add("ASI loader: FAILED (nothing else will load without it)") }
}

# ---- 2. CLEO ---------------------------------------------------------------
Write-Step "2/6  CLEO 2.2.0 (script engine; supports 1.0, 1.1 and Steam exes)"
$zip = Get-Package $Packages.Cleo
if ($zip) {
    $tmp = Expand-ToTemp $zip
    Install-Tree $tmp @()
    Remove-Item -LiteralPath $tmp -Recurse -Force
    Write-Ok "installed VC.CLEO.asi + CLEO\CLEO_PLUGINS"
    [void]$Summary.Add("CLEO: installed")
} else { [void]$Summary.Add("CLEO: FAILED") }

# ---- 3. cheat scripts ------------------------------------------------------
Write-Step "3/6  Cheat scripts (infinite health + infinite money)"
$cleoDir = Join-Path $Game 'CLEO'
if (-not (Test-Path -LiteralPath $cleoDir)) { New-Item -ItemType Directory -Path $cleoDir | Out-Null }
$scripts = Get-ChildItem -LiteralPath (Join-Path $ScriptRoot 'mods\CLEO') -Filter '*.cs'
foreach ($s in $scripts) {
    Install-File $s.FullName (Join-Path $cleoDir $s.Name)
    Write-Ok "CLEO\$($s.Name)"
}
[void]$Summary.Add("Cheat scripts: " + (($scripts | ForEach-Object { $_.Name }) -join ', '))

# ---- 4. SilentPatch --------------------------------------------------------
Write-Step "4/6  SilentPatch (crash fixes, mouse lock-up fix, Windows 8+ compatibility)"
if ($SkipSilentPatch) { Write-Info "skipped (-SkipSilentPatch)"; [void]$Summary.Add("SilentPatch: skipped") }
else {
    $zip = Get-Package $Packages.SilentPatch
    if ($zip) {
        $tmp = Expand-ToTemp $zip
        Install-Tree $tmp @('ReadMe.txt')
        Remove-Item -LiteralPath $tmp -Recurse -Force
        Write-Ok "installed SilentPatchVC.asi, SilentPatchVC.ini and fixed data\maps\*.ipl"
        [void]$Summary.Add("SilentPatch: installed")
    } else { [void]$Summary.Add("SilentPatch: FAILED") }
}

# ---- 5. mouse --------------------------------------------------------------
Write-Step "5/6  Windows 11 mouse fix"
if ($SkipMouseFix) { Write-Info "skipped (-SkipMouseFix)"; [void]$Summary.Add("Mouse fix: skipped") }
elseif (-not $IsWin) { Write-Info "not on Windows - registry step skipped" }
else {
    # Same as: Properties > Compatibility > "Disable fullscreen optimizations"
    #          + Change high DPI settings > Override scaling: Application
    $layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    if (-not (Test-Path $layers)) { New-Item -Path $layers -Force | Out-Null }
    $old = $null
    try { $old = (Get-ItemProperty -Path $layers -Name $Exe -ErrorAction Stop).$Exe } catch {}
    $script:Manifest.Registry[$Exe] = $old
    $flags = @('~', 'DISABLEDXMAXIMIZEDWINDOWEDMODE', 'HIGHDPIAWARE')
    if ($old) { foreach ($f in ($old -split '\s+')) { if ($f -and $flags -notcontains $f) { $flags += $f } } }
    Set-ItemProperty -Path $layers -Name $Exe -Value ($flags -join ' ')
    Write-Ok "compatibility flags set for gta-vc.exe: $($flags -join ' ')"
    [void]$Summary.Add("Mouse fix: compatibility flags set (+ SilentPatch mouse fixes)")

    if ($InstallMouseFixAsi) {
        if ($ExeVersion -eq '1.0') {
            $zip = Get-Package $Packages.MouseFix
            if ($zip) {
                $tmp = Expand-ToTemp $zip
                Install-Tree $tmp @()
                Remove-Item -LiteralPath $tmp -Recurse -Force
                Write-Ok "installed mousefix.asi + mousefix.txt"
                [void]$Summary.Add("mousefix.asi: installed")
            }
        } else { Write-Warn2 "mousefix.asi only supports the 1.0 exe (yours: $ExeVersion) - skipped" }
    }
}

# ---- 6. cars ---------------------------------------------------------------
Write-Step "6/6  Car mods from .\cars\"
if ($SkipCars) { Write-Info "skipped (-SkipCars)"; [void]$Summary.Add("Cars: skipped") }
else {
    $carsRoot = Join-Path $ScriptRoot 'cars'
    $img = Join-Path $Game 'models\gta3.img'
    $dir = Join-Path $Game 'models\gta3.dir'
    $handling = Join-Path $Game 'data\handling.cfg'
    $carcols  = Join-Path $Game 'data\carcols.dat'
    $sources = @()
    if (Test-Path -LiteralPath $carsRoot) {
        $sources += Get-ChildItem -LiteralPath $carsRoot -Directory
        $sources += Get-ChildItem -LiteralPath $carsRoot -File | Where-Object { $_.Extension -in '.zip', '.rar', '.7z' }
    }
    if (($sources | Where-Object { -not $_.PSIsContainer -and $_.Extension -in '.rar', '.7z' }) -and -not $script:SevenZip) {
        $script:SevenZip = Install-7Zip
        if ($script:SevenZip) { Write-Ok "7-Zip: $script:SevenZip" }
        else { Write-Warn2 ".rar/.7z car archives present but 7-Zip is not installed - install it from https://www.7-zip.org (or 'winget install 7zip.7zip') and run again; those cars are skipped this time" }
    }
    if ($sources.Count -eq 0) {
        Write-Info "no car folders or zips in $carsRoot - nothing to do (see cars\README.md)"
        [void]$Summary.Add("Cars: none provided")
    } elseif (-not (Test-Path -LiteralPath $img) -or -not (Test-Path -LiteralPath $dir)) {
        Write-Warn2 "models\gta3.img / gta3.dir not found - cannot install cars"
        [void]$Summary.Add("Cars: FAILED (gta3.img missing)")
    } else {
        Backup-File $img | Out-Null
        Backup-File $dir | Out-Null
        $entries = Read-ImgDir $dir
        $slots = Read-VehicleSlots (Join-Path $Game 'data\default.ide')
        if ($slots.Count -eq 0) { Write-Warn2 "data\default.ide not readable - slot folders disabled, files must be named after the car they replace" }
        $installed = 0; $skipped = 0
        foreach ($src in $sources) {
            $folder = $src.FullName; $tmp = $null
            if ($src.PSIsContainer -eq $false) {
                try { $tmp = Expand-ToTemp $src.FullName; $folder = $tmp }
                catch { Write-Warn2 "$($src.Name): $($_.Exception.Message) - skipped"; $skipped++; continue }
            }
            # folder/zip named after a game vehicle ("infernus", "cheetah", ...) = slot mode:
            # whatever the files inside are called, they replace that vehicle.
            $slotKey = ($src.BaseName -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
            $slot = $null
            if ($slots.ContainsKey($slotKey)) { $slot = $slots[$slotKey] }
            if ($slot) { Write-Info "-- $($src.Name)  (replaces vehicle '$($slot.Model)')" } else { Write-Info "-- $($src.Name)" }
            $models = Get-ChildItem -LiteralPath $folder -Recurse -File | Where-Object { $_.Extension -in '.dff', '.txd' }
            foreach ($m in $models) {
                $target = $m.Name
                if ($slot) {
                    $sameExt = @($models | Where-Object { $_.Extension -ieq $m.Extension })
                    if ($sameExt.Count -eq 1) { $target = $slot.Model + $m.Extension.ToLowerInvariant() }
                }
                if (Set-ImgFile $img $dir $entries $m.FullName $target) {
                    if ($target -ine $m.Name) { Write-Ok "gta3.img: replaced $target  (from $($m.Name))" } else { Write-Ok "gta3.img: replaced $target" }
                    $installed++
                } else { Write-Warn2 "gta3.img has no entry named '$target' - skipped (put the files in a folder named after the car they replace)"; $skipped++ }
            }
            foreach ($t in (Get-ChildItem -LiteralPath $folder -Recurse -File -Filter '*handling*.txt')) {
                foreach ($line in [System.IO.File]::ReadAllLines($t.FullName)) {
                    $l = $line.Trim(); if (-not $l -or $l.StartsWith(';') -or $l.StartsWith('#')) { continue }
                    if ($slot) {
                        if ($slot.Type -ieq 'car') { $l = $l -replace '^[%!$]\s+', '' }   # car lines carry no boat/bike/plane prefix
                        $l = Set-FirstToken $l $slot.Handling 'handling'
                    }
                    if (Update-DataLine $handling $l 'handling') { Write-Ok "handling.cfg: updated '$(($l -split '\s+')[0])'" }
                    else { Write-Warn2 "handling.cfg: no line for '$(($l -split '\s+')[0])' - ignored" }
                }
            }
            foreach ($t in (Get-ChildItem -LiteralPath $folder -Recurse -File -Filter '*carcol*.txt')) {
                foreach ($line in [System.IO.File]::ReadAllLines($t.FullName)) {
                    $l = $line.Trim(); if (-not $l -or $l.StartsWith(';') -or $l.StartsWith('#')) { continue }
                    if ($slot) { $l = Set-FirstToken $l $slot.Model 'carcols' }
                    if (Update-DataLine $carcols $l 'carcols') { Write-Ok "carcols.dat: updated '$(($l.Split(','))[0])'" }
                    else { Write-Warn2 "carcols.dat: no line for '$(($l.Split(','))[0])' - ignored" }
                }
            }
            $cols = Get-ChildItem -LiteralPath $folder -Recurse -File -Filter '*.col'
            if ($cols) { Write-Warn2 "ignored .col file(s) (VC vehicles carry collision inside the .dff): $(($cols | ForEach-Object { $_.Name }) -join ', ')" }
            $exes = Get-ChildItem -LiteralPath $folder -Recurse -File | Where-Object { $_.Extension -in '.exe', '.bat', '.cmd', '.msi', '.scr', '.vbs', '.ps1' }
            if ($exes) { Write-Warn2 "ignored executable(s) inside the mod: $(($exes | ForEach-Object { $_.Name }) -join ', ')" }
            if ($tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
        }
        if ($installed -gt 0) { Compact-Img $img $dir $entries }
        [void]$Summary.Add("Cars: $installed model file(s) installed, $skipped skipped")
    }
}

# ---- optional drop-in folder (e.g. GInput controller support) --------------
$opt = Join-Path $ScriptRoot 'optional'
if (Test-Path -LiteralPath $opt) {
    $files = Get-ChildItem -LiteralPath $opt -Recurse -File | Where-Object { $_.Name -ne 'README.md' }
    if ($files) {
        Write-Step "Optional drop-ins from .\optional\ (copied 1:1 into the game folder)"
        foreach ($sub in (Get-ChildItem -LiteralPath $opt -Directory)) {
            Install-Tree $sub.FullName @('ReadMe.txt', 'README.md', 'docs\*', 'docs/*')
            Write-Ok "copied $($sub.Name)\"
        }
        [void]$Summary.Add("Optional drop-ins: copied")
    }
}

Save-Manifest

Write-Host ""
Write-Host "================ SUMMARY ================" -ForegroundColor Magenta
$Summary | ForEach-Object { Write-Host "  $_" }
Write-Host "  Backup   : $script:BackupRoot"
Write-Host "  Undo     : Restore-Backup.bat"
Write-Host ""
Write-Host "Now start the game. 'CLEO 2.2.0' in the bottom-left corner of the main menu = success." -ForegroundColor Green
Write-Host "Start a NEW game or load a save: money jumps to 99,999,999 and Tommy cannot be hurt."
Write-Host "Controller / mouse: see README.md sections 5 and 6 for the in-game settings."

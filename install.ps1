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
.PARAMETER SkipWidescreen
    Do not install ThirteenAG's Widescreen Fix (16:9/ultrawide, FOV, HUD scaling, no island loading).
.PARAMETER Skip2DFX
    Do not install Project2DFX (draw distance, night-time city lights) + LimitAdjuster.
.PARAMETER SkipSkyGfx
    Do not install SkyGfx (PS2-style graphics; only installs on a 1.0 exe anyway).
.PARAMETER InstallMouseFixAsi
    Also install sfwidde's mousefix.asi (only works with the 1.0 exe; skipped otherwise).
.PARAMETER NoDownload
    Never touch the network; use the zips already in .\downloads\ (still hash-checked).
.PARAMETER Restore
    Undo: copy the newest backup back and delete the files that were added.
.PARAMETER BackupDir
    With -Restore: a specific backup folder instead of the newest one.
.PARAMETER Diagnose
    The game does not start? Reports Windows' crash record for gta-vc.exe, then
    launches the game with each installed component switched off in turn and
    tells you which one is the problem (Diagnose.bat).
.PARAMETER MakeCarsManifest
    Clean every archive in cars\ (only .dff/.txd/text files survive, no executables
    or screenshots), write the cleaned .zip copies to cars\publish\ and list them
    with SHA256 in cars.json pointing at -ReleaseUrl (a GitHub release:
    https://github.com/USER/REPO/releases/download/TAG). Upload cars\publish\* to
    that release; the installer then downloads them on the fly.
.PARAMETER ReleaseUrl
    Base URL used by -MakeCarsManifest.
.PARAMETER Yes
    Do not pause for confirmation.

    Linux (Bottles / Wine / Proton): run with PowerShell 7 -  ./install.sh  - the
    game folder is the one inside drive_c. Afterwards add the Wine DLL override
    dinput8 = native,builtin (printed at the end) so the ASI loader is used.
#>
[CmdletBinding()]
param(
    [string]$GamePath,
    [switch]$SkipSilentPatch,
    [switch]$SkipMouseFix,
    [switch]$SkipCars,
    [switch]$SkipWidescreen,
    [switch]$Skip2DFX,
    [switch]$SkipSkyGfx,
    [switch]$InstallMouseFixAsi,
    [switch]$NoDownload,
    [switch]$Restore,
    [string]$BackupDir,
    [switch]$Diagnose,
    [switch]$MakeCarsManifest,
    [string]$ReleaseUrl,
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
    Widescreen = @{
        Name = 'Widescreen Fix (ThirteenAG)'
        File = 'GTAVC.WidescreenFix.zip'
        Url  = 'https://github.com/ThirteenAG/WidescreenFixesPack/releases/download/gtavc/GTAVC.WidescreenFix.zip'
        Sha  = '63D7381729C9E12D3F46D534EF99BF38DA7A9912654531AF21FB386F4AFF5D85'
    }
    Project2DFX = @{
        Name = 'Project2DFX + LimitAdjuster (ThirteenAG)'
        File = 'VC.Project2DFX.zip'
        Url  = 'https://github.com/ThirteenAG/III.VC.SA.IV.Project2DFX/releases/download/gtavc/VC.Project2DFX.zip'
        Sha  = 'AD82978D9DFBC02F388A12C192CCB0DE07B76D800361D6566F8FEF2BF03236E9'
    }
    SkyGfx = @{
        Name = 'SkyGfx 2.7 (aap) - 1.0 exe only'
        File = 'SkyGfx_III_VC_2.7.zip'
        Url  = 'https://github.com/aap/skygfx_vc/releases/download/v2.7/SkyGfx_III_VC_2.7.zip'
        Sha  = 'BCDA8034B1257CFCB9E258225A0E6506B3352F7ACD38694B3718B2B1B5C1DA0C'
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

function Get-GitHubToken {
    # Needed only when the cars live in a PRIVATE repo's release. Read from
    # github_token.txt next to the installer (gitignored) or $env:GITHUB_TOKEN.
    $f = Join-Path $ScriptRoot 'github_token.txt'
    if (Test-Path -LiteralPath $f) { $t = (Get-Content -LiteralPath $f -Raw).Trim(); if ($t) { return $t } }
    if ($env:GITHUB_TOKEN) { return $env:GITHUB_TOKEN }
    return $null
}

function Invoke-Download([string]$url, [string]$outFile) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $token = Get-GitHubToken
    $m = [regex]::Match($url, '^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$')
    if ($token -and $m.Success) {
        # private repo: resolve the asset through the API and download it with the token
        $owner = $m.Groups[1].Value; $repo = $m.Groups[2].Value; $tag = $m.Groups[3].Value
        $name = [Uri]::UnescapeDataString($m.Groups[4].Value)
        $h = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json'; 'User-Agent' = 'gta-vc-ultimate-mod' }
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/tags/$tag" -Headers $h -UseBasicParsing
        $asset = $rel.assets | Where-Object { $_.name -eq $name } | Select-Object -First 1
        if (-not $asset) { throw "asset '$name' not found in release '$tag' of $owner/$repo" }
        $h.Accept = 'application/octet-stream'
        Invoke-WebRequest -Uri $asset.url -Headers $h -OutFile $outFile -UseBasicParsing
    } else {
        Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
    }
}

function Get-RemoteCars {
    # cars.json: [ { "name": "infernus.rar", "url": "...", "sha256": "..." }, ... ]
    # Downloads each (hash-checked) into downloads\cars\ and returns the local paths.
    $mf = Join-Path $ScriptRoot 'cars.json'
    $out = @()
    if (-not (Test-Path -LiteralPath $mf)) { return $out }
    $list = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
    $dir = Join-Path (Join-Path $ScriptRoot 'downloads') 'cars'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    foreach ($e in @($list)) {
        if (-not $e.name -or -not $e.url) { continue }
        $local = Join-Path $dir $e.name
        $sha = if ($e.sha256) { ([string]$e.sha256).ToUpperInvariant() } else { $null }
        if (Test-Path -LiteralPath $local) {
            if (-not $sha -or (Get-Sha256 $local) -eq $sha) { $out += $local; continue }
            Remove-Item -LiteralPath $local -Force
        }
        if ($NoDownload) { Write-Warn2 "$($e.name): not downloaded (-NoDownload)"; continue }
        Write-Info "downloading $($e.name)"
        try {
            Invoke-Download $e.url "$local.part"
            if ($sha -and (Get-Sha256 "$local.part") -ne $sha) { Remove-Item -LiteralPath "$local.part" -Force; Write-Warn2 "$($e.name): SHA256 mismatch - skipped"; continue }
            Move-Item -LiteralPath "$local.part" -Destination $local -Force
            $out += $local
        } catch { Write-Warn2 "$($e.name): download failed - $($_.Exception.Message)" }
    }
    return $out
}

function Write-CarsManifest {
    # Cleans every archive in cars\ (keeps only data files), writes the cleaned
    # copies as .zip into cars\publish\ and lists them in cars.json for the
    # installer to download from a GitHub release.
    if (-not $ReleaseUrl) { throw "-MakeCarsManifest needs -ReleaseUrl https://github.com/USER/REPO/releases/download/TAG" }
    $carsRoot = Join-Path $ScriptRoot 'cars'
    $pubDir = Join-Path $carsRoot 'publish'
    if (-not (Test-Path -LiteralPath $pubDir)) { New-Item -ItemType Directory -Path $pubDir -Force | Out-Null }
    $script:SevenZip = Find-7Zip
    $keep = '.dff', '.txd', '.txt', '.cfg', '.dat', '.ini', '.nfo'
    $items = @()
    foreach ($f in (Get-ChildItem -LiteralPath $carsRoot -File | Where-Object { $_.Extension -in '.zip', '.rar', '.7z' } | Sort-Object Name)) {
        $tmp = $null
        try { $tmp = Expand-ToTemp $f.FullName } catch { Write-Warn2 "$($f.Name): $($_.Exception.Message) - skipped"; continue }
        $all = Get-ChildItem -LiteralPath $tmp -Recurse -File
        $removed = @($all | Where-Object { $_.Extension.ToLowerInvariant() -notin $keep })
        $removed | Remove-Item -Force
        $kept = @(Get-ChildItem -LiteralPath $tmp -Recurse -File)
        if (-not ($kept | Where-Object { $_.Extension -in '.dff', '.txd' })) {
            Write-Warn2 "$($f.Name): no .dff/.txd inside - not a car mod, skipped"
            Remove-Item -LiteralPath $tmp -Recurse -Force; continue
        }
        $dest = Join-Path $pubDir ($f.BaseName + '.zip')
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
        Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $dest -CompressionLevel Optimal
        Remove-Item -LiteralPath $tmp -Recurse -Force
        $d = Get-Item -LiteralPath $dest
        $items += [ordered]@{ name = $d.Name; url = ($ReleaseUrl.TrimEnd('/') + '/' + [Uri]::EscapeDataString($d.Name)); sha256 = (Get-Sha256 $d.FullName) }
        Write-Ok ("{0,-20} {1,7:N2} MB -> {2,7:N2} MB   kept {3}, dropped {4}" -f $f.Name, ($f.Length / 1MB), ($d.Length / 1MB), $kept.Count, $removed.Count)
        foreach ($r in ($removed | Where-Object { $_.Extension -in '.exe', '.bat', '.cmd', '.msi', '.scr', '.vbs', '.dll', '.com' })) { Write-Info "      dropped executable: $($r.Name)" }
    }
    if ($items.Count -eq 0) { throw "no usable .zip/.rar/.7z in $carsRoot" }
    ConvertTo-Json @($items) -Depth 3 | Set-Content -LiteralPath (Join-Path $ScriptRoot 'cars.json') -Encoding UTF8
    Write-Ok "wrote cars.json with $($items.Count) car(s)."
    Write-Host ""
    Write-Host "Next: upload every file from  $pubDir  to the release at  $ReleaseUrl  and commit cars.json." -ForegroundColor Yellow
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
    $exeName = 'gta-vc.exe'

    # 0. remembered from a previous run
    $remember = Join-Path $ScriptRoot 'gamepath.txt'
    if (Test-Path -LiteralPath $remember) {
        $p = (Get-Content -LiteralPath $remember -Raw).Trim()
        if ($p -and (Test-Path -LiteralPath (Join-Path $p $exeName))) { return $p }
    }

    # 1. this folder placed inside (or next to) the game folder
    $d = $ScriptRoot
    while ($d) {
        if (Test-Path -LiteralPath (Join-Path $d $exeName)) { return $d }
        $parent = Split-Path -Parent $d
        if (-not $parent -or $parent -eq $d) { break }
        $d = $parent
    }

    $candidates = @()
    $roots = @()
    if ($IsWin) {
        # 2. Steam: main install + every extra library folder
        foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam') {
            try {
                $sp = (Get-ItemProperty -Path $key -ErrorAction Stop).InstallPath
                if ($sp) {
                    $candidates += (Join-Path $sp 'steamapps\common\Grand Theft Auto Vice City')
                    $vdf = Join-Path $sp 'steamapps\libraryfolders.vdf'
                    if (Test-Path -LiteralPath $vdf) {
                        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                            $candidates += (Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common\Grand Theft Auto Vice City')
                        }
                    }
                }
            } catch {}
        }
        try {
            $rp = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Rockstar Games\Grand Theft Auto Vice City' -ErrorAction Stop).InstallFolder
            if ($rp) { $candidates += $rp }
        } catch {}
        # 3. usual fixed spots
        $candidates += @(
            'C:\Program Files (x86)\Steam\steamapps\common\Grand Theft Auto Vice City',
            'C:\Program Files (x86)\Rockstar Games\Grand Theft Auto Vice City',
            'C:\Program Files\Rockstar Games\Grand Theft Auto Vice City'
        )
        # 4. places to search a few levels deep
        $up = $env:USERPROFILE
        if ($up) {
            foreach ($sub in 'Desktop', 'Downloads', 'Documents', 'Games', 'OneDrive\Desktop', 'OneDrive\Documents') {
                $roots += @{ Path = (Join-Path $up $sub); Depth = 3 }
            }
        }
        foreach ($drv in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' })) {
            $roots += @{ Path = $drv.Root; Depth = 2 }
            foreach ($sub in 'Games', 'Program Files (x86)', 'Program Files', 'SteamLibrary\steamapps\common', 'Steam\steamapps\common', 'Rockstar Games') {
                $roots += @{ Path = (Join-Path $drv.Root $sub); Depth = 2 }
            }
        }
    } else {
        if ($HOME) {
            foreach ($r in @(
                @{ Path = (Join-Path $HOME '.var/app/com.usebottles.bottles/data/bottles/bottles'); Depth = 6 },   # Bottles (flatpak)
                @{ Path = (Join-Path $HOME '.local/share/bottles/bottles'); Depth = 6 },                          # Bottles (native)
                @{ Path = (Join-Path $HOME '.wine/drive_c'); Depth = 4 },                                         # plain Wine
                @{ Path = (Join-Path $HOME '.local/share/Steam/steamapps'); Depth = 6 },                          # Proton / Steam
                @{ Path = (Join-Path $HOME '.steam/steam/steamapps'); Depth = 6 },
                @{ Path = (Join-Path $HOME 'Games'); Depth = 4 },
                @{ Path = $HOME; Depth = 4 })) { $roots += $r }
        }
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath (Join-Path $c $exeName))) { return $c }
    }
    Write-Info "searching your drives for $exeName (a few seconds)..."
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r.Path)) { continue }
        $hit = Get-ChildItem -LiteralPath $r.Path -Filter $exeName -File -Recurse -Depth $r.Depth -ErrorAction SilentlyContinue -Force |
               Where-Object { $_.FullName -notmatch '\\_ultimate_mod_backup\\' } | Select-Object -First 1
        if ($hit) { return $hit.DirectoryName }
    }

    if ($Yes) { throw "Game folder not found. Run again with -GamePath 'C:\path\to\Grand Theft Auto Vice City'." }
    Write-Host ""
    Write-Host "Could not find $exeName anywhere. Drag the game folder onto this window (or paste its path) and press Enter:" -ForegroundColor Yellow
    $p = Read-Host "Game folder"
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

function Set-LargeAddressAware([string]$exe) {
    # Sets IMAGE_FILE_LARGE_ADDRESS_AWARE (0x20) in the PE header so the 32-bit
    # game can use 4 GB of address space instead of 2 GB. On 64-bit Windows the
    # game sizes its streaming memory at ~2 GB (half of a capped 'available
    # physical memory' value), which overflows a 2 GB process: models stop
    # loading while their collision stays. Returns 'set', 'already' or an error text.
    $b = [System.IO.File]::ReadAllBytes($exe)
    if ($b.Length -lt 0x40 -or $b[0] -ne 0x4D -or $b[1] -ne 0x5A) { return 'not a Windows exe' }
    $pe = [BitConverter]::ToInt32($b, 0x3C)
    if ($pe -le 0 -or $pe + 24 -gt $b.Length -or [BitConverter]::ToUInt32($b, $pe) -ne 0x00004550) { return 'not a PE file' }
    $off = $pe + 22
    $chars = [BitConverter]::ToUInt16($b, $off)
    if (($chars -band 0x20) -ne 0) { return 'already' }
    $chars = [uint16]($chars -bor 0x20)
    [Array]::Copy([BitConverter]::GetBytes($chars), 0, $b, $off, 2)
    [System.IO.File]::WriteAllBytes($exe, $b)
    return 'set'
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
    $exe = Join-Path $Game 'gta-vc.exe'
    $layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    if ($BackupDir) { $dirs = @($BackupDir) }
    else {
        if (-not (Test-Path -LiteralPath $root)) {
            # the game folder was re-extracted: nothing of ours is in it, but the registry flags survive
            if ($IsWin) {
                Remove-ItemProperty -Path $layers -Name $exe -ErrorAction SilentlyContinue
                Write-Ok "no backup folder in $Game (fresh copy) - removed the compatibility flags for $exe, nothing else to undo"
                return
            }
            throw "No backups found in $root"
        }
        # oldest first: the first backup of a file is the untouched original
        $dirs = @(Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name | ForEach-Object { $_.FullName })
    }
    $added = @{}; $backed = @{}; $reg = @{}
    foreach ($dir in $dirs) {
        $mf = Join-Path $dir 'manifest.json'
        if (-not (Test-Path -LiteralPath $mf)) { continue }
        $m = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
        # first record of a file wins: added by an early run = delete; present before any run = restore
        foreach ($rel in @($m.Backed)) { if ($rel -and -not $backed.ContainsKey($rel) -and -not $added.ContainsKey($rel)) { $backed[$rel] = (Join-Path $dir $rel) } }
        foreach ($rel in @($m.Added))  { if ($rel -and -not $backed.ContainsKey($rel) -and -not $added.ContainsKey($rel)) { $added[$rel] = $true } }
        if ($m.Registry) { foreach ($p in $m.Registry.PSObject.Properties) { if (-not $reg.ContainsKey($p.Name)) { $reg[$p.Name] = $p.Value } } }
    }
    if ($added.Count -eq 0 -and $backed.Count -eq 0) { throw "no usable manifest.json in $root" }
    Write-Step "Restoring from $($dirs.Count) backup(s) in $root"
    foreach ($rel in $added.Keys) {
        $f = Join-Path $Game $rel
        if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force; Write-Info "removed $rel" }
    }
    foreach ($rel in $added.Keys) {
        $d = Split-Path -Parent (Join-Path $Game $rel)
        while ($d -and $d.Length -gt $Game.Length -and (Test-Path -LiteralPath $d) -and -not (Get-ChildItem -LiteralPath $d -Force | Select-Object -First 1)) {
            Remove-Item -LiteralPath $d -Force; $d = Split-Path -Parent $d
        }
    }
    foreach ($rel in $backed.Keys) {
        $src = $backed[$rel]
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $Game $rel) -Force; Write-Info "restored $rel" }
    }
    if ($IsWin) {
        foreach ($name in $reg.Keys) {
            if ($reg[$name]) { Set-ItemProperty -Path $layers -Name $name -Value $reg[$name] }
            else { Remove-ItemProperty -Path $layers -Name $name -ErrorAction SilentlyContinue }
            Write-Info "registry compat flags for $name restored"
        }
        Remove-ItemProperty -Path $layers -Name $exe -ErrorAction SilentlyContinue
    }
    Write-Ok "Restore complete."
}

# ---------------------------------------------------------------------------
# DIAGNOSE (game does not start)
# ---------------------------------------------------------------------------
function Test-GameLaunch([string]$exe, [int]$seconds) {
    # $true if the game is still running after $seconds (i.e. it reached the menu / loading screen)
    $p = Start-Process -FilePath $exe -WorkingDirectory (Split-Path -Parent $exe) -PassThru
    $alive = $true
    for ($i = 0; $i -lt $seconds; $i++) {
        Start-Sleep -Seconds 1
        $p.Refresh()
        if ($p.HasExited) { $alive = $false; break }
    }
    if ($alive) { try { Stop-Process -Id $p.Id -Force } catch {} ; Start-Sleep -Seconds 2 }
    else { Write-Info ("      exited after {0}s with code {1}" -f $i, $p.ExitCode) }
    return $alive
}

function Invoke-Diagnose {
    $Game = Find-GamePath
    $Game = (Resolve-Path -LiteralPath $Game).Path.TrimEnd('\', '/')
    $exe = Join-Path $Game 'gta-vc.exe'
    if (-not (Test-Path -LiteralPath $exe)) { throw "gta-vc.exe not found in $Game" }
    Write-Step "Diagnosing why $exe does not start"
    Write-Info "Exe version : $(Get-ExeVersion $exe)"
    $exeItem = Get-Item -LiteralPath $exe
    Write-Info ("Exe size    : {0:N0} bytes, modified {1}" -f $exeItem.Length, $exeItem.LastWriteTime)

    # components we may have added
    $components = @(
        @{ Name = 'ASI loader (dinput8.dll)';    Files = @('dinput8.dll') },
        @{ Name = 'CLEO (VC.CLEO.asi + scripts)'; Files = @('VC.CLEO.asi') },
        @{ Name = 'SilentPatch (SilentPatchVC.asi)'; Files = @('SilentPatchVC.asi') },
        @{ Name = 'Widescreen Fix';              Files = @('scripts\GTAVC.WidescreenFix.asi') },
        @{ Name = 'Project2DFX + LimitAdjuster'; Files = @('VCLodLights.asi', 'III.VC.SA.LimitAdjuster.asi') },
        @{ Name = 'SkyGfx (+ d3d8to9)';          Files = @('skygfx.asi', 'd3d8.dll') },
        @{ Name = 'mousefix.asi';                Files = @('mousefix.asi') }
    )
    $present = @()
    foreach ($c in $components) {
        $paths = @($c.Files | ForEach-Object { Join-Path $Game $_ } | Where-Object { Test-Path -LiteralPath $_ })
        if ($paths.Count -gt 0) { $c.Paths = $paths; $present += $c; Write-Info "installed   : $($c.Name)" }
    }
    $others = Get-ChildItem -LiteralPath $Game -File | Where-Object { $_.Extension -in '.asi', '.dll' -and $_.Name -notin 'dinput8.dll','VC.CLEO.asi','SilentPatchVC.asi','mousefix.asi','Mss32.dll','binkw32.dll','eax.dll','vorbis.dll','vorbisFile.dll','ogg.dll' }
    if ($others) { Write-Info "other plugins/dlls in the folder (not ours): $(($others | ForEach-Object { $_.Name }) -join ', ')" }
    $cleoLog = Join-Path $Game 'cleo.log'
    if (Test-Path -LiteralPath $cleoLog) { Write-Info "cleo.log (last lines):"; Get-Content -LiteralPath $cleoLog -Tail 8 | ForEach-Object { Write-Info "      $_" } }

    if (-not $IsWin) { Write-Warn2 "not on Windows - cannot read the event log or launch the game"; return }

    # things that survive deleting and re-extracting the game folder
    Write-Step "Leftovers outside the game folder"
    $userFiles = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'GTA Vice City User Files'
    $set = Join-Path $userFiles 'gta_vc.set'
    if (Test-Path -LiteralPath $set) {
        $si = Get-Item -LiteralPath $set
        Write-Info ("settings file: {0} ({1:N0} bytes, {2}) - a bad one makes the game exit silently; delete it to test (saves are separate files)" -f $set, $si.Length, $si.LastWriteTime)
    } else { Write-Info "no gta_vc.set in $userFiles (the game has not managed a first run yet, or it was deleted)" }
    $layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    try {
        $cf = (Get-ItemProperty -Path $layers -Name $exe -ErrorAction Stop).$exe
        if ($cf) { Write-Info "compatibility flags on this exe path: $cf  (set by Install.bat or by you; Restore-Backup.bat removes them)" }
    } catch { Write-Info "no compatibility flags on this exe path" }

    Write-Step "Windows Defender detections touching the game folder"
    try {
        $det = Get-MpThreatDetection -ErrorAction Stop | Where-Object { ($_.Resources -join ' ') -match [regex]::Escape($Game) -or ($_.Resources -join ' ') -match 'gta' } | Sort-Object InitialDetectionTime -Descending | Select-Object -First 5
        if ($det) {
            foreach ($d in $det) {
                $t = try { (Get-MpThreat -ThreatID $d.ThreatID -ErrorAction Stop).ThreatName } catch { "threat id $($d.ThreatID)" }
                Write-Warn2 ("{0}  {1}  action={2}" -f $d.InitialDetectionTime, $t, $d.CurrentThreatExecutionStatusID)
                foreach ($r in $d.Resources) { Write-Info "      $r" }
            }
            Write-Warn2 "Defender removed or blocked file(s) from the game folder. A repack's exe or its bundled dll is usually what gets taken; without it the exe exits at once. Windows Security > Protection history shows the same list."
        } else { Write-Info "none recorded" }
    } catch { Write-Info "could not query Defender: $($_.Exception.Message)" }

    # Windows' own crash records for this exe
    Write-Step "Windows crash records for gta-vc.exe (last 3)"
    try {
        $ev = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'Application Error', 'Windows Error Reporting' } -MaxEvents 400 -ErrorAction Stop |
              Where-Object { $_.Message -match 'gta-vc\.exe' } | Select-Object -First 3
        if (-not $ev) { Write-Info "none found (the exe exits without crashing - typical for DRM / launcher / a plugin calling exit)" }
        foreach ($e in $ev) {
            $mod = [regex]::Match($e.Message, 'Faulting module name:\s*([^,\r\n]+)').Groups[1].Value
            $code = [regex]::Match($e.Message, 'Exception code:\s*(0x[0-9a-fA-F]+)').Groups[1].Value
            Write-Info ("{0}  faulting module: {1}  exception: {2}" -f $e.TimeCreated, $(if ($mod) { $mod.Trim() } else { '?' }), $(if ($code) { $code } else { '?' }))
        }
    } catch { Write-Info "could not read the event log: $($_.Exception.Message)" }

    # launch tests
    Write-Step "Launch tests (each one starts the game for up to 25 s and closes it again)"
    Write-Host "    Do not touch the game window while this runs." -ForegroundColor Yellow
    $layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    $compat = $null
    try { $compat = (Get-ItemProperty -Path $layers -Name $exe -ErrorAction Stop).$exe } catch {}

    Write-Info "1. everything as installed..."
    if (Test-GameLaunch $exe 25) {
        Write-Ok "the game starts and stays up. If it still does nothing when YOU double-click it, the difference is how it is launched: launch gta-vc.exe directly from the game folder, not from Steam or a repack launcher, and not as a different user."
        return
    }
    $culprit = $null
    foreach ($c in $present) {
        Write-Info "-- without $($c.Name)..."
        foreach ($f in $c.Paths) { Rename-Item -LiteralPath $f -NewName ([System.IO.Path]::GetFileName($f) + '.off') -Force }
        $ok = Test-GameLaunch $exe 25
        foreach ($f in $c.Paths) { Rename-Item -LiteralPath "$f.off" -NewName ([System.IO.Path]::GetFileName($f)) -Force }
        if ($ok) { $culprit = $c; break }
    }
    if (-not $culprit -and $compat) {
        Write-Info "-- without the compatibility flags..."
        Remove-ItemProperty -Path $layers -Name $exe -ErrorAction SilentlyContinue
        $ok = Test-GameLaunch $exe 25
        Set-ItemProperty -Path $layers -Name $exe -Value $compat
        if ($ok) { $culprit = @{ Name = 'compatibility flags'; Paths = @() } }
    }
    if (-not $culprit -and $present.Count -gt 0) {
        Write-Info "-- without ALL of our components..."
        foreach ($c in $present) { foreach ($f in $c.Paths) { Rename-Item -LiteralPath $f -NewName ([System.IO.Path]::GetFileName($f) + '.off') -Force } }
        if ($compat) { Remove-ItemProperty -Path $layers -Name $exe -ErrorAction SilentlyContinue }
        $ok = Test-GameLaunch $exe 25
        foreach ($c in $present) { foreach ($f in $c.Paths) { Rename-Item -LiteralPath "$f.off" -NewName ([System.IO.Path]::GetFileName($f)) -Force } }
        if ($compat) { Set-ItemProperty -Path $layers -Name $exe -Value $compat }
        if (-not $ok) {
            Write-Warn2 "The game does not start even with everything of ours removed - the problem is the game copy itself (Steam DRM exe started outside Steam, a repack launcher, a missing gta_vc.set, or Defender). Run Restore-Backup.bat, then get that copy starting on its own first."
            return
        }
        $culprit = @{ Name = 'a combination of components'; Paths = @() }
    }

    Write-Step "Result"
    if ($culprit.Paths.Count -gt 0) {
        foreach ($f in $culprit.Paths) { Rename-Item -LiteralPath $f -NewName ([System.IO.Path]::GetFileName($f) + '.off') -Force }
        Write-Warn2 "$($culprit.Name) stops the game from starting. It has been switched OFF (renamed to .off) so the game runs; the rest stays on."
        if ($culprit.Name -like 'ASI loader*') { Write-Info "Without the ASI loader no plugin loads. Try the other loader name: rename dinput8.dll.off to ddraw.dll and start the game." }
        if ($culprit.Name -like 'CLEO*') { Write-Info "CLEO refused this exe (version '$(Get-ExeVersion $exe)'). The cheats need a clean 1.0 / 1.1 / Steam gta-vc.exe." }
        if ($culprit.Name -like 'SilentPatch*') { Write-Info "SilentPatch does not accept this exe build. Cheats and cars work without it; the mouse fix then relies on the compatibility flags only." }
    } elseif ($culprit.Name -eq 'compatibility flags') {
        Remove-ItemProperty -Path $layers -Name $exe -ErrorAction SilentlyContinue
        Write-Warn2 "The compatibility flags stop the game from starting; they have been removed."
    } else {
        Write-Warn2 "No single component is at fault but all together they are. Run Restore-Backup.bat and re-run Install.bat with -SkipSilentPatch, then again without it, to narrow it down."
    }
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
if ($MakeCarsManifest) { Write-CarsManifest; exit 0 }
if ($Diagnose) { Invoke-Diagnose; exit 0 }
if ($Restore) { Invoke-Restore; exit 0 }

Write-Host "GTA Vice City - Ultimate mod installer" -ForegroundColor Magenta
Write-Host "--------------------------------------"

$Game = Find-GamePath
if (-not (Test-Path -LiteralPath (Join-Path $Game 'gta-vc.exe'))) { throw "gta-vc.exe not found in '$Game'" }
$Game = (Resolve-Path -LiteralPath $Game).Path.TrimEnd('\', '/')
try { Set-Content -LiteralPath (Join-Path $ScriptRoot 'gamepath.txt') -Value $Game -Encoding UTF8 } catch {}
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
Write-Step "1/8  ASI loader (dinput8.dll) - lets the game load .asi plugins"
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
Write-Step "2/8  CLEO 2.2.0 (script engine; supports 1.0, 1.1 and Steam exes)"
$zip = Get-Package $Packages.Cleo
if ($zip) {
    $tmp = Expand-ToTemp $zip
    Install-Tree $tmp @()
    Remove-Item -LiteralPath $tmp -Recurse -Force
    Write-Ok "installed VC.CLEO.asi + CLEO\CLEO_PLUGINS"
    [void]$Summary.Add("CLEO: installed")
} else { [void]$Summary.Add("CLEO: FAILED") }

# ---- 3. cheat scripts ------------------------------------------------------
Write-Step "3/8  Cheat scripts (infinite health + infinite money)"
$cleoDir = Join-Path $Game 'CLEO'
if (-not (Test-Path -LiteralPath $cleoDir)) { New-Item -ItemType Directory -Path $cleoDir | Out-Null }
$scripts = Get-ChildItem -LiteralPath (Join-Path $ScriptRoot 'mods\CLEO') -Filter '*.cs'
foreach ($s in $scripts) {
    Install-File $s.FullName (Join-Path $cleoDir $s.Name)
    Write-Ok "CLEO\$($s.Name)"
}
[void]$Summary.Add("Cheat scripts: " + (($scripts | ForEach-Object { $_.Name }) -join ', '))

# ---- 4. SilentPatch --------------------------------------------------------
Write-Step "4/8  SilentPatch (crash fixes, mouse lock-up fix, Windows 8+ compatibility)"
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

# ---- 5. streaming memory ---------------------------------------------------
Write-Step "5/8  Large Address Aware flag (fixes models/trees not loading, invisible walls)"
try {
    Backup-File $Exe | Out-Null
    $r = Set-LargeAddressAware $Exe
    switch ($r) {
        'set'     { Write-Ok "gta-vc.exe can now use 4 GB of memory (one header bit changed; original exe is in the backup)"; [void]$Summary.Add("Large Address Aware: set") }
        'already' { Write-Ok "gta-vc.exe already has the flag"; [void]$Summary.Add("Large Address Aware: already set") }
        default   { Write-Warn2 "could not set the flag: $r"; [void]$Summary.Add("Large Address Aware: skipped ($r)") }
    }
} catch { Write-Warn2 "could not set the flag: $($_.Exception.Message)"; [void]$Summary.Add("Large Address Aware: FAILED") }

# ---- 6. graphics extras ----------------------------------------------------
Write-Step "6/8  Graphics: Widescreen Fix, Project2DFX, SkyGfx"
$scriptsDir = Join-Path $Game 'scripts'
if ($SkipWidescreen) { Write-Info "Widescreen Fix skipped (-SkipWidescreen)"; [void]$Summary.Add("Widescreen Fix: skipped") }
else {
    $zip = Get-Package $Packages.Widescreen
    if ($zip) {
        $tmp = Expand-ToTemp $zip
        # only the plugin itself: the zip's d3d8.dll is a second ASI loader and its global.ini
        # would stop our dinput8.dll loader from loading CLEO / SilentPatch from the game root
        foreach ($f in 'GTAVC.WidescreenFix.asi', 'GTAVC.WidescreenFix.ini') {
            $src = Get-ChildItem -LiteralPath $tmp -Recurse -File -Filter $f | Select-Object -First 1
            if ($src) { Install-File $src.FullName (Join-Path $scriptsDir $f) }
        }
        Remove-Item -LiteralPath $tmp -Recurse -Force
        Write-Ok "installed scripts\GTAVC.WidescreenFix.asi (+ ini)"
        [void]$Summary.Add("Widescreen Fix: installed")
    } else { [void]$Summary.Add("Widescreen Fix: FAILED") }
}
if ($Skip2DFX) { Write-Info "Project2DFX skipped (-Skip2DFX)"; [void]$Summary.Add("Project2DFX: skipped") }
else {
    $zip = Get-Package $Packages.Project2DFX
    if ($zip) {
        $tmp = Expand-ToTemp $zip
        $ini = Get-ChildItem -LiteralPath $tmp -Recurse -File -Filter 'VCLodLights.ini' | Select-Object -First 1
        if ($ini) {
            # the dynamic draw distance aims at this fps; with the frame limiter on (30 fps) a 60 target would keep it minimal
            $t = [System.IO.File]::ReadAllText($ini.FullName) -replace '(?m)^TargetFPS\s*=\s*\d+', 'TargetFPS = 25'
            [System.IO.File]::WriteAllText($ini.FullName, $t)
        }
        Install-Tree $tmp @()
        Remove-Item -LiteralPath $tmp -Recurse -Force
        Write-Ok "installed VCLodLights.asi/.dat/.ini + III.VC.SA.LimitAdjuster.asi/.ini"
        [void]$Summary.Add("Project2DFX: installed")
    } else { [void]$Summary.Add("Project2DFX: FAILED") }
}
if ($SkipSkyGfx) { Write-Info "SkyGfx skipped (-SkipSkyGfx)"; [void]$Summary.Add("SkyGfx: skipped") }
elseif ($ExeVersion -ne '1.0') { Write-Warn2 "SkyGfx 2.7 only works with the 1.0 exe (yours: $ExeVersion) - skipped"; [void]$Summary.Add("SkyGfx: skipped (needs 1.0 exe)") }
else {
    $zip = Get-Package $Packages.SkyGfx
    if ($zip) {
        $tmp = Expand-ToTemp $zip
        $root = Get-ChildItem -LiteralPath $tmp -Recurse -File -Filter 'skygfx.asi' | Select-Object -First 1
        if ($root) {
            $base = $root.DirectoryName
            Install-File $root.FullName (Join-Path $Game 'skygfx.asi')
            Install-File (Join-Path $base 'rwd3d9.dll') (Join-Path $Game 'rwd3d9.dll')
            Install-File (Join-Path $base 'VC\skygfx.ini') (Join-Path $Game 'skygfx.ini')
            foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $base 'VC\neo') -File)) {
                Install-File $f.FullName (Join-Path (Join-Path $Game 'neo') $f.Name)
            }
            # d3d8to9 wrapper (crosire), needed by SkyGfx for its d3d9 features; never overwrite an existing d3d8.dll
            if ($IsWin -and -not (Test-Path -LiteralPath (Join-Path $Game 'd3d8.dll'))) { Install-File (Join-Path $base 'd3d8.dll') (Join-Path $Game 'd3d8.dll') }
            Write-Ok "installed skygfx.asi, skygfx.ini, rwd3d9.dll, neo\, d3d8.dll (d3d8to9)"
            [void]$Summary.Add("SkyGfx: installed")
        } else { Write-Warn2 "skygfx.asi not found in the archive"; [void]$Summary.Add("SkyGfx: FAILED") }
        Remove-Item -LiteralPath $tmp -Recurse -Force
    } else { [void]$Summary.Add("SkyGfx: FAILED") }
}

# ---- 7. mouse --------------------------------------------------------------
Write-Step "7/8  Windows 11 mouse fix"
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

# ---- 8. cars ---------------------------------------------------------------
Write-Step "8/8  Car mods from .\cars\"
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
    $localNames = @($sources | ForEach-Object { $_.Name })
    foreach ($p in (Get-RemoteCars)) {
        $fi = Get-Item -LiteralPath $p
        if ($localNames -notcontains $fi.Name) { $sources += $fi }     # a local copy in cars\ wins over the release
    }
    if (($sources | Where-Object { -not $_.PSIsContainer -and $_.Extension -in '.rar', '.7z' }) -and -not $script:SevenZip) {
        $script:SevenZip = Install-7Zip
        if ($script:SevenZip) { Write-Ok "7-Zip: $script:SevenZip" }
        elseif ($IsWin) { Write-Warn2 ".rar/.7z car archives present but 7-Zip is not installed - install it from https://www.7-zip.org (or 'winget install 7zip.7zip') and run again; those cars are skipped this time" }
        else { Write-Warn2 ".rar/.7z car archives present but 7z is not installed - run: sudo apt install p7zip-full p7zip-rar   then run again; those cars are skipped this time" }
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
Write-Host "In game: Options > Display Setup > Frame Limiter ON (the engine mis-streams the world above ~60 fps)." -ForegroundColor Yellow
if (-not $IsWin) {
    Write-Host ""
    Write-Host "Wine / Bottles / Proton: the game must load OUR dinput8.dll, not Wine's. Set the DLL override once:" -ForegroundColor Yellow
    Write-Host "  Bottles : bottle > Settings > DLL overrides > add  dinput8  = Native then Builtin"
    Write-Host "  Proton  : launch options  WINEDLLOVERRIDES=\"dinput8=n,b\" %command%"
    Write-Host "  winecfg : Libraries tab > new override  dinput8  > Edit > Native then Builtin"
    Write-Host "(the compatibility-flag mouse fix is Windows-only and was skipped; not needed under Wine)"
}
Write-Host "Controller / mouse: see README.md for the in-game settings."

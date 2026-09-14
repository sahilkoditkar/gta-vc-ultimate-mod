# GTA Vice City – Ultimate mod kit

One installer for the classic PC Vice City (Steam / retail, Windows 10/11):

* **infinite health** (nothing can hurt you, your car can't blow up)
* **infinite money** ($99,999,999, always refilled)
* **never fall off a bike** (crashes, burst tyres and cops pulling you off)
* **all weapons, infinite ammo** (whatever you hold is refilled, also picked-up guns)
* **infinite sprint**, **nobody can pull you out of a car**
* **widescreen / ultrawide fix**, **long draw distance + city lights at night**
  (Project2DFX), **PS2-style graphics** (SkyGfx, 1.0 exe only)
* **modern cars** – every car in `cars\` replaces an old one
* **Windows 11 mouse fix**
* crash fixes (SilentPatch) and EvoFox controller notes

Nothing here is a trainer or an installer `.exe`. Everything the script
downloads comes from the projects' own GitHub release pages and is checked
against a SHA256 hash written in `install.ps1`. Your `gta-vc.exe` is never
replaced (CLEO 2.2.0 works with 1.0, 1.1 and Steam exes); the only change to
it is one header bit, "Large Address Aware", so the game can use 4 GB of
memory. Every game file that gets changed is backed up first;
`Restore-Backup.bat` undoes everything.

## Install

1. Green **Code** button → **Download ZIP** → extract anywhere.
2. Double-click **`Install.bat`**. Windows may warn that the file came from the
   internet: *More info → Run anyway*. It finds the game folder by itself:
   Steam libraries, Program Files, and a search of Desktop / Downloads /
   Documents / every drive a few levels deep (a `Games` folder on the Desktop
   is fine). It remembers the result in `gamepath.txt`. Only if nothing is
   found does it ask you to drag the game folder onto the window. It asks
   once for admin rights if the game is under Program Files, then prints a
   summary.
3. Start the game. **`CLEO 2.2.0`** in the bottom-left of the menu means it
   worked. Load a save: money is $99,999,999 and Tommy can't be hurt.
4. Options → Display Setup → **Frame Limiter ON**. Above ~60 fps the 2002
   engine streams the world late (invisible trees/walls) and breaks physics.

Run `Install.bat` again any time (after adding cars, for example); finished
steps are skipped.

## What it does to the game folder

| Step | What | From |
|---|---|---|
| ASI loader | `dinput8.dll` | Ultimate ASI Loader v9.7.4 |
| CLEO | `VC.CLEO.asi`, `CLEO\` | cleolibrary III.VC.CLEO v2.2.0 |
| Cheats | `CLEO\infinite_health.cs`, `infinite_money.cs`, `no_bike_fall.cs`, `all_weapons.cs`, `infinite_sprint.cs`, `no_dragout.cs` | this repo (source: `tools\cleo_asm.py`) |
| Widescreen | `scripts\GTAVC.WidescreenFix.asi` + ini | ThirteenAG/WidescreenFixesPack |
| Draw distance & lights | `VCLodLights.asi/.dat/.ini`, `III.VC.SA.LimitAdjuster.asi/.ini` | ThirteenAG/III.VC.SA.IV.Project2DFX |
| PS2 look (1.0 exe only) | `skygfx.asi`, `skygfx.ini`, `rwd3d9.dll`, `neo\`, `d3d8.dll` (d3d8to9) | aap/skygfx_vc v2.7 |
| SilentPatch | `SilentPatchVC.asi` + fixed `data\maps\*.ipl` | CookiePLMonster/SilentPatch build 12.1 |
| Memory | Large Address Aware bit set in `gta-vc.exe` (models/trees not loading, invisible walls, crashes after a while) | – |
| Mouse | compatibility flags on `gta-vc.exe` (registry) | – |
| Cars | old model + textures replaced inside `models\gta3.img`, matching `handling.cfg` / `carcols.dat` lines swapped, old data compacted away | `cars\` |
| Backup | `_ultimate_mod_backup\<date>\` with a manifest | – |

To remove a cheat later, delete its `.cs` file from the game's `CLEO\` folder.
Graphics add-ons can be left out with `-SkipWidescreen`, `-Skip2DFX`,
`-SkipSkyGfx` (edit the line in `Install.bat`), and tuned in their `.ini`
files: `VCLodLights.ini` (draw distance, number of lights) is the one that
costs GPU on a weak laptop; `skygfx.ini` switches the PS2/Xbox effects.
Note: the two ThirteenAG downloads live under a rolling release tag, so
when the author rebuilds them the hash check fails and that step is
skipped with a warning until the hash in `install.ps1` is refreshed.

## Cars

`cars\` holds the replacements, one archive or folder per car, **named after
the slot it replaces** (`infernus.rar`, `cheetah.zip`, `banshee\`, ...).
`.zip`, `.rar` and `.7z` all work; for `.rar`/`.7z` the installer uses 7-Zip
and installs it through winget if it isn't there. The installer takes the
`.dff`/`.txd` inside whatever they are called, writes them over the old car in
`gta3.img`, applies any handling / carcols lines the mod ships, then compacts
`gta3.img` so the old car is really gone. Executables inside a mod are ignored.
The full slot list, modern-car suggestions and download links are in
**`cars\README.md`**.

Car archives are too big for git, so to install them on another machine they
go on a **GitHub release** instead (optional, only when you want that):

1. With the archives in `cars\`, run
   `cars\Clean-Cars.bat https://github.com/USER/REPO/releases/download/cars`.
   It re-packs each one with only the data files (installer `.exe`s and
   screenshots dropped and listed) into `cars\publish\` and writes `cars.json`
   (name, URL, SHA256).
2. On GitHub: Releases → *Draft a new release* → tag `cars` → drag
   `cars\publish\*.zip` in → Publish. Commit `cars.json`.
3. Private repo? Create a fine-grained token with read access to the repo's
   *Contents* and save it as `github_token.txt` next to `Install.bat` (never
   committed).

`Install.bat` installs what's in `cars\` **and** what `cars.json` lists
(downloaded and hash-checked; a local copy of the same name wins). Change that
with `-Cars local`, `-Cars release` or `-Cars none` on the line in `Install.bat`.

## Linux (Bottles / Wine / Proton)

The installer runs natively with PowerShell 7 (`sudo snap install powershell
--classic`, plus `sudo apt install p7zip-full p7zip-rar` for `.rar` cars):

```
./install.sh                      # finds the game inside Bottles / .wine / Steam prefixes
./install.sh -GamePath "$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/VC/drive_c/Games/Grand Theft Auto Vice City"
```

Then one setting in the prefix, or CLEO never loads: the game must use the
ASI loader `dinput8.dll` from its folder instead of Wine's own.

* Bottles: the bottle → Settings → *DLL overrides* → add `dinput8` → *Native then Builtin*.
* Proton (game added to Steam): launch options `WINEDLLOVERRIDES="dinput8=n,b" %command%`.
* Plain Wine: `winecfg` → Libraries → add `dinput8` → Edit → *Native then Builtin*.

The Windows-only parts (compatibility flags, winget) are skipped; SkyGfx's
`d3d8to9` wrapper is not installed under Wine because Wine's own d3d8 is
already the better path. Everything else, including the Large Address Aware
flag, works the same.

## Mouse doesn't work on Windows 11

The installer already sets *Disable fullscreen optimizations* + *High DPI
override: Application* on `gta-vc.exe` and installs SilentPatch (which fixes
the menu mouse lock-up). If it still doesn't respond, in order:

1. Alt+Tab out and back in once the game window is up.
2. `gta-vc.exe` → Properties → Compatibility → *Windows XP SP3* + *Run as administrator*.
3. Delete `Documents\GTA Vice City User Files\gta_vc.set` (settings file).
4. In game: Options → Controller Setup → Configuration → **Mouse+Keys**.
5. Windows Settings → Gaming → Game Bar → off.

## EvoFox One S ("1S3") controller

The pad must be in the right mode **and** connected before the game starts;
Vice City only looks for controllers at launch.

| Want | Press (pad on) | LED |
|---|---|---|
| D-Input – works with the game as-is | **Start + Select** | red |
| X-Input – needs GInput (below), Xbox layout + icons | hold **LB + Home** 2 s, then plug in the dongle | purple |

* **D-Input, no extra mod:** Start + Select → red → plug in dongle/cable →
  start game → Options → Controller Setup → Configuration → **Joypad**.
  Remap anything under *Redefine Controls*.
* **X-Input with GInput (proper Xbox layout):** download *GInput VC* from
  https://silentsblog.com/mods/gta-vc/ (plain zip, no exe), extract it into
  `optional\GInput\`, run `Install.bat` again, set the pad to X-Input.
* Still nothing: try a rear USB 2.0 port, charge the pad, check it in
  `joy.cpl` (Win+R), and if you launch through Steam disable *Steam Input*
  for the game.

## More

`OPTIONS.md` lists everything else that can be added (more cheats, widescreen
fix, draw distance, PS2 graphics, HD textures, weapons, skins, saves) with a
one-line verdict on each.

## Undo

`Restore-Backup.bat` puts every changed file back and deletes the added ones.

## Problems

| | |
|---|---|
| Game does not start at all after installing | run **`Diagnose.bat`**: it shows Windows' crash record for `gta-vc.exe`, then starts the game with each component switched off in turn and switches off the one that breaks it |
| "Cannot find 640x480 video mode" | the settings file is missing and modern GPUs have no 16-bit 640×480 mode; run `Install.bat`, SilentPatch makes the game default to your desktop resolution instead |
| No `CLEO 2.2.0` text in the menu | rename `dinput8.dll` to `ddraw.dll` in the game folder |
| Installer says exe version *unknown* | your copy has a patched exe; CLEO may still load, otherwise use a clean 1.0/1.1/Steam copy |
| Trees / walls / buildings invisible but solid, textures missing | streaming memory: run `Install.bat` (sets Large Address Aware) and turn **Frame Limiter ON** in Display Setup |
| Crash on loading after adding a car | that model is broken/too heavy: delete its zip from `cars\`, run `Restore-Backup.bat`, then `Install.bat` |
| Defender flags `dinput8.dll` / `.asi` | expected for code-injecting DLLs; the hashes in `install.ps1` match the official GitHub releases |

Not affiliated with Rockstar Games. CLEO, SilentPatch, Ultimate ASI Loader,
GInput and the car models belong to their authors.

# GTA Vice City – Ultimate mod kit

One installer for the classic PC Vice City (Steam / retail, Windows 10/11):

* **infinite health** (nothing can hurt you, your car can't blow up)
* **infinite money** ($99,999,999, always refilled)
* **modern cars** – every car in `cars\` replaces an old one
* **Windows 11 mouse fix**
* crash fixes (SilentPatch) and EvoFox controller notes

Nothing here is a trainer or an installer `.exe`. Everything the script
downloads comes from the projects' own GitHub release pages and is checked
against a SHA256 hash written in `install.ps1`. Your `gta-vc.exe` is never
replaced (CLEO 2.2.0 works with 1.0, 1.1 and Steam exes). Every game file
that gets changed is backed up first; `Restore-Backup.bat` undoes everything.

## Install

1. Green **Code** button → **Download ZIP** → extract anywhere.
2. Double-click **`Install.bat`**. Windows may warn that the file came from the
   internet: *More info → Run anyway*. It finds the game folder by itself
   (asks you to paste the path if it can't), asks once for admin rights if the
   game is under Program Files, and prints a summary.
3. Start the game. **`CLEO 2.2.0`** in the bottom-left of the menu means it
   worked. Load a save: money is $99,999,999 and Tommy can't be hurt.

Run `Install.bat` again any time (after adding cars, for example); finished
steps are skipped.

## What it does to the game folder

| Step | What | From |
|---|---|---|
| ASI loader | `dinput8.dll` | Ultimate ASI Loader v9.7.4 |
| CLEO | `VC.CLEO.asi`, `CLEO\` | cleolibrary III.VC.CLEO v2.2.0 |
| Cheats | `CLEO\infinite_health.cs`, `CLEO\infinite_money.cs` | this repo (source: `tools\cleo_asm.py`) |
| SilentPatch | `SilentPatchVC.asi` + fixed `data\maps\*.ipl` | CookiePLMonster/SilentPatch build 12.1 |
| Mouse | compatibility flags on `gta-vc.exe` (registry) | – |
| Cars | old model + textures replaced inside `models\gta3.img`, matching `handling.cfg` / `carcols.dat` lines swapped, old data compacted away | `cars\` |
| Backup | `_ultimate_mod_backup\<date>\` with a manifest | – |

To remove a cheat later, delete its `.cs` file from the game's `CLEO\` folder.

## Cars

`cars\` holds the replacements, one zip or folder per car, **named after the
slot it replaces** (`infernus.zip`, `cheetah\`, ...). The installer takes the
`.dff`/`.txd` inside whatever they are called, writes them over the old car in
`gta3.img`, applies any handling / carcols lines the mod ships, then compacts
`gta3.img` so the old car is really gone. The full slot list, modern-car
suggestions and download links are in **`cars\README.md`**.

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

## Undo

`Restore-Backup.bat` puts every changed file back and deletes the added ones.

## Problems

| | |
|---|---|
| No `CLEO 2.2.0` text in the menu | rename `dinput8.dll` to `ddraw.dll` in the game folder |
| Installer says exe version *unknown* | your copy has a patched exe; CLEO may still load, otherwise use a clean 1.0/1.1/Steam copy |
| Crash on loading after adding a car | that model is broken/too heavy: delete its zip from `cars\`, run `Restore-Backup.bat`, then `Install.bat` |
| Defender flags `dinput8.dll` / `.asi` | expected for code-injecting DLLs; the hashes in `install.ps1` match the official GitHub releases |

Not affiliated with Rockstar Games. CLEO, SilentPatch, Ultimate ASI Loader,
GInput and the car models belong to their authors.

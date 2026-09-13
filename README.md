# GTA Vice City "Ultimate" mod kit (PC classic version, Windows 11)

Brings back the "Ultimate Vice City" feeling on the classic Steam / retail PC
game without downloading a single trainer or installer `.exe`:

| Feature | How it is done | Files involved |
|---|---|---|
| Infinite health (bullet, fire, explosion, fall & melee proof, armour always full, your car can't blow up) | CLEO script written for this kit, source in `tools/cleo_asm.py` | `CLEO\infinite_health.cs` |
| Infinite money ($99,999,999, refilled twice a second) | CLEO script written for this kit | `CLEO\infinite_money.cs` |
| Modern sports cars | Your chosen `.dff` + `.txd` car models are written into `models\gta3.img` by the installer (no IMG Tool needed) | `cars\` folder |
| Windows 11 mouse fix | Compatibility flags for `gta-vc.exe` + SilentPatch's mouse fixes | registry, `SilentPatchVC.asi` |
| EvoFox One S ("1S3") controller | In-game settings + controller mode + optional GInput | see section 6 |

Everything is either **written here (readable source)** or **downloaded from the
projects' own GitHub release pages and verified against a SHA256 hash** before
it is used. The installer never runs anything it downloaded; it only copies
files. Every file it changes is backed up first and `Restore-Backup.bat` undoes
the whole thing.

**Your `gta-vc.exe` is never replaced.** CLEO 2.2.0 supports the 1.0, 1.1 and
Steam executables, so the usual "download a 1.0 exe from a random site" step
is not needed.

---

## 1. Quick start (5 minutes)

1. Download this repository as a zip (green **Code** button → *Download ZIP*)
   and extract it anywhere, e.g. `C:\Users\you\Downloads\gta-vc-ultimate-mod`.
2. *(Optional, for cars)* put each car mod in its own sub-folder (or zip) inside
   `cars\` — read `cars\README.md` for the exact layout and where to get cars.
3. Double-click **`Install.bat`**.
   * Windows may show *"Windows protected your PC"* / *"Open File – Security
     Warning"* because the file came from the internet. Click *More info → Run
     anyway* / *Run*. The code it runs is `install.ps1`; open it in Notepad if
     you want to read it first — it is ~500 lines of plain PowerShell.
   * If the game lives in `C:\Program Files (x86)\...` the script re-launches
     itself once with an admin prompt (it needs write access to the game folder).
   * It finds the game folder by itself (Steam registry / common paths). If it
     can't, it asks you to paste the path of the folder containing `gta-vc.exe`.
4. Read the summary it prints, then start the game.
5. In the main menu you should see **`CLEO 2.2.0`** in the bottom-left corner.
   Load a save or start a new game: money jumps to **$99,999,999** and Tommy
   can no longer be hurt.

Command-line variants (run from a PowerShell window in this folder):

```powershell
.\install.ps1 -GamePath "D:\Games\Grand Theft Auto Vice City"   # explicit path
.\install.ps1 -SkipCars                                          # leave gta3.img alone
.\install.ps1 -SkipSilentPatch -SkipMouseFix                     # cheats only
.\install.ps1 -InstallMouseFixAsi                                # extra mouse mod (1.0 exe only)
.\install.ps1 -Restore                                           # undo (same as Restore-Backup.bat)
```

---

## 2. What exactly gets put into the game folder

| File / folder | Purpose | Source (version-pinned, SHA256-checked) |
|---|---|---|
| `dinput8.dll` | ASI loader – makes the game load `.asi` plugins | [ThirteenAG/Ultimate-ASI-Loader v9.7.4](https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/tag/v9.7.4) |
| `VC.CLEO.asi`, `CLEO\CLEO_PLUGINS\*.cleo` | CLEO script engine | [cleolibrary/III.VC.CLEO v2.2.0](https://github.com/cleolibrary/III.VC.CLEO/releases/tag/v2.2.0) |
| `CLEO\infinite_health.cs`, `CLEO\infinite_money.cs` | the cheats | this repo, `mods\CLEO\` (built by `tools\cleo_asm.py`) |
| `SilentPatchVC.asi`, `SilentPatchVC.ini`, `data\maps\*.ipl` | crash / mouse / Windows 8+ fixes | [CookiePLMonster/SilentPatch, build 12.1](https://github.com/CookiePLMonster/SilentPatch/releases/tag/1.1-BUILD34.1-SA) |
| `models\gta3.img`, `models\gta3.dir`, `data\handling.cfg`, `data\carcols.dat` | modified in place for your cars | your `cars\` folder |
| *(optional)* `mousefix.asi`, `mousefix.txt` | extra mouse-lock fix, **1.0 exe only** | [sfwidde/gta-vc-mouse-fix v3.0.2](https://github.com/sfwidde/gta-vc-mouse-fix/releases/tag/v3.0.2) |
| `_ultimate_mod_backup\<date>\` | copies of every original file + `manifest.json` | created by the installer |

Pinned hashes live at the top of `install.ps1`. If an upstream file ever
changes, the hash check fails and that component is **skipped with a warning**
rather than installed blindly.

---

## 3. Manual install (if you'd rather copy-paste yourself)

All paths are relative to the folder that contains `gta-vc.exe`.

1. **ASI loader** – download `Ultimate-ASI-Loader.zip` from the v9.7.4 release
   link above, copy `dinput8.dll` next to `gta-vc.exe`.
   (If nothing loads, rename it to `ddraw.dll` – both names work for VC.)
2. **CLEO** – download `VC.CLEO-v2.2.0.zip`, extract so that `VC.CLEO.asi` sits
   next to `gta-vc.exe` and the `CLEO\` folder is beside it.
3. **Cheats** – copy `mods\CLEO\infinite_health.cs` and
   `mods\CLEO\infinite_money.cs` from this repo into the game's `CLEO\` folder.
4. **SilentPatch** – download `SilentPatchVC.zip`, extract everything except
   `ReadMe.txt` into the game folder (`data\maps\...` files overwrite the
   originals – back them up first).
5. **Cars** – see section 7.
6. Start the game and check for `CLEO 2.2.0` in the menu corner.

Remove a cheat any time by deleting its `.cs` file from `CLEO\`.

---

## 4. Infinite health & money – details

* `infinite_health.cs` runs every frame: heals Tommy whenever health drops
  below 100, tops armour up to the maximum, and sets bullet / fire / explosion /
  collision / melee immunity. While you are in a vehicle the vehicle gets the
  same immunities plus full health, and they are removed again when you get out
  (so the rest of the traffic behaves normally). Drowning still hurts, but the
  per-frame heal outruns it.
* `infinite_money.cs` runs twice a second and adds exactly the difference
  between your wallet and $99,999,999 (the widest amount the HUD shows cleanly).
  Spend freely – it refills.
* Both scripts wait until the player exists, so they are inert in menus and
  during cut-scenes. They are 227 and 68 bytes of standard SCM bytecode; every
  opcode is listed with its meaning in `tools/cleo_asm.py`. To change the
  amount, edit `MONEY_TARGET` in that file and run `python3 tools/cleo_asm.py`
  (needs Python, only if you want to customise).
* Missions that *require* you to be "wasted" or to lose money don't exist in
  VC, so the story is fully playable. Achievements are not a thing in the
  classic Steam build.

---

## 5. Windows 11 – mouse doesn't work (menu or in-game)

The game uses 2002-era DirectInput; on Windows 10/11 the mouse frequently
ignores input in the menu, only works after Alt-Tab, or locks up after leaving
the pause menu. Two independent fixes are applied by the installer; the rest
are fallbacks in order of "try next".

**Applied automatically**

1. **Compatibility flags** on `gta-vc.exe` – equivalent to right-click →
   *Properties → Compatibility*:
   * ☑ *Disable fullscreen optimizations*
   * *Change high DPI settings* → ☑ *Override high DPI scaling behavior* → **Application**

   (stored under `HKCU\...\AppCompatFlags\Layers`; `-Restore` removes it)
2. **SilentPatch** – among 100+ fixes it removes the DirectPlay dependency
   (Windows 8+ compatibility), fixes *"the mouse locks up randomly when exiting
   the menu on newer systems"*, keeps the mouse inside the window on multi-monitor
   setups, and gives the vertical axis the same sensitivity as the horizontal.

**If the mouse still doesn't respond, in this order**

3. Press **Alt+Tab twice** (out and back in) after the game window appears –
   the classic one-second workaround; if this fixes it, step 4 makes it permanent.
4. `gta-vc.exe` → *Properties → Compatibility* → ☑ *Run this program in
   compatibility mode for* **Windows XP (Service Pack 3)** and ☑ *Run this
   program as an administrator*. Apply.
5. Run the game **windowed / borderless**: in the game *Options → Display Setup*
   set your desktop resolution; a borderless fix is included in ThirteenAG's
   Widescreen Fix (not part of this kit, GitHub: `ThirteenAG/WidescreenFixesPack`).
6. Delete `Documents\GTA Vice City User Files\gta_vc.set` (controller/display
   settings file). The game recreates it with defaults; SilentPatch then defaults
   the resolution to your desktop's.
7. In game: *Options → Controller Setup → Configuration* must be **Mouse+Keys**
   (if it says *Joypad*, the mouse is ignored on purpose – see section 6).
8. Windows *Settings → Bluetooth & devices → Mouse → Additional mouse settings →
   Pointer Options*: untick *Enhance pointer precision* while playing.
9. Only with a **1.0 exe**: run `.\install.ps1 -InstallMouseFixAsi` to add
   sfwidde's `mousefix.asi`, a dedicated "mouse not working" hook (the installer
   prints your exe version at the top; it is skipped on 1.1/Steam builds).
10. Windows Game Bar can steal focus: *Settings → Gaming → Game Bar* → off.

---

## 6. EvoFox One S 3-mode ("1S3") controller

The pad has three PC personalities; Vice City only understands the DirectInput
one natively, and the XInput one through GInput. That's why it "sometimes"
works – it depends on which mode it woke up in.

**Modes (Amkette's own combos)**

| Want | Do this (pad on) | LED |
|---|---|---|
| 2.4 GHz dongle, **X-Input** (Xbox-style) | hold **LB + Home** ~2 s, then plug the USB dongle in | purple |
| **D-Input** (generic DirectInput joystick) | press **Start + Select** | red, steady |
| Bluetooth pairing | hold **A + Home** | green blinking |
| Wired | USB-C cable → PC; mode combos still apply | |

**Option A – no extra mod (D-Input mode)**

1. Put the pad in **D-Input** (Start + Select → red LED) and connect it
   **before** launching the game. VC only enumerates controllers at start-up.
2. Check Windows sees it: press Win+R, run `joy.cpl`, select the pad →
   *Properties* – move the sticks, all axes/buttons must react.
3. In game: *Options → Controller Setup → Configuration* → set **Joypad**
   (this also switches the menu prompts). *Redefine Controls* lets you assign
   any button to any action.
4. Triggers on a DirectInput pad are one shared axis; use the shoulder
   buttons for accelerate/brake or remap in *Redefine Controls*.

**Option B – proper Xbox layout (X-Input mode + GInput)**

GInput (by Silent) replaces VC's controller code with XInput: correct trigger
handling, vibration, PS/Xbox button icons, auto-switch between pad and
mouse/keyboard, five layouts including the GTA IV one.

1. Get "GInput VC" from the author: https://silentsblog.com/mods/gta-vc/
   (mirrors: ModDB *[III/VC/SA] GInput v1.11*, libertycity *GInput VC v1.11*).
   It is a zip containing `GInputVC.asi`, `GInputVC.ini`, `models\` and `docs\`
   – no executable. It is not fetched automatically only because it isn't on
   GitHub, so the script can't pin a hash for it.
2. Extract it into `optional\GInput\` (so `optional\GInput\GInputVC.asi` exists)
   and run `Install.bat` again – or copy the same files next to `gta-vc.exe`
   yourself.
3. Put the pad in **X-Input** mode (LB + Home → purple) and connect it before
   starting the game.
4. Everything is automatic; layout and icon style are in `GInputVC.ini`.

**If it still doesn't work**

* Pad connected *after* the game started → quit, connect, relaunch.
* Wrong mode LED → do the combo again; the pad remembers the last mode, so a
  Bluetooth session on your phone leaves it in the wrong mode for PC.
* Dongle in a USB 3 hub / front port → move it to a rear USB 2.0 port; charge
  the pad (Amkette's own first troubleshooting steps).
* If you launch through Steam: right-click the game → *Properties →
  Controller* → **Disable Steam Input**; Steam's own remapper fights both the
  game and GInput.
* Two "controllers" showing in `joy.cpl` (e.g. a wheel or the dongle's second
  device) → VC picks the first one; unplug the other.
* X-Input mode *without* GInput: works but the triggers share one axis and
  the button numbering is odd – use Option A or install GInput.

---

## 7. Cars

Full instructions and safe sources in **`cars/README.md`**. Short version:

```
cars\
  my_lambo\
    infernus.dff       <- must be named after the VC car it replaces
    infernus.txd
    handling.txt       <- optional line(s) for handling.cfg
    carcols.txt        <- optional line(s) for carcols.dat
```

The installer replaces the entries of the same name inside `models\gta3.img`
(rewriting `gta3.dir`; files that don't fit in the old slot are appended at the
end, exactly what IMG Tool does), then swaps the matching lines in the data
files. `.dff`/`.txd` are pure model/texture data and cannot contain code; any
`.exe`/`.bat` inside a mod is ignored and reported.

Spawning them: they replace normal traffic cars, so drive around Ocean Beach /
Starfish Island, or use the vehicle cheats that spawn the replaced model
(e.g. **PANZER** = tank, **THELASTRIDE** = Romero, **GETTHEREFAST** = Sabre
Turbo, **GETTHEREVERYFASTINDEED** = Hotring Racer). Infernus/Cheetah/Banshee
spawn naturally around the rich districts.

---

## 8. Uninstall / undo

Double-click **`Restore-Backup.bat`** (or `.\install.ps1 -Restore`). It reads
`_ultimate_mod_backup\<newest>\manifest.json`, deletes every file that was
added, copies back every file that was replaced (including `gta3.img` and the
registry compatibility value). Older backups stay in that folder; pass
`-BackupDir` to pick one explicitly.

---

## 9. Troubleshooting

| Symptom | Fix |
|---|---|
| No `CLEO 2.2.0` text in the menu | The ASI loader isn't being loaded. Rename `dinput8.dll` → `ddraw.dll`. If a `dinput8.dll` was already there before (dgVoodoo, another loader) keep only one. |
| Installer says *Exe version: unknown* | Your repack patched the exe. CLEO and SilentPatch detect the version at runtime and may still work; if CLEO refuses, the only fix is a clean 1.0/1.1/Steam exe. |
| Game crashes at loading after adding a car | That model is too heavy or broken. Remove its folder from `cars\`, run `Restore-Backup.bat`, install again. |
| Health still drops | `CLEO\infinite_health.cs` missing, or the game paused the scripts (menus). Check the file is there and CLEO text shows. |
| Money shows less than 99,999,999 | It's animating up – the HUD counter counts, the wallet is already full. |
| "Insert CD" error on an old retail exe | SilentPatch removes that check on 1.0/1.1. |
| Windows Defender flags `dinput8.dll` / `.asi` | These are code-injecting DLLs by design, which some heuristics dislike. The hashes in `install.ps1` match the official GitHub releases; re-download from the linked release page if you want to compare yourself (`Get-FileHash file -Algorithm SHA256` in PowerShell). |

---

## 10. Repository layout

```
Install.bat / Restore-Backup.bat   double-click launchers
install.ps1                         the installer (PowerShell 5.1+, Windows 10/11)
mods/CLEO/*.cs                      the two cheat scripts (built bytecode)
tools/cleo_asm.py                   readable source + assembler for those scripts
tools/test/make_fake_game.py        builds a dummy game folder for testing the installer
cars/                               your car mods go here (see cars/README.md)
optional/                           drop-ins copied 1:1 into the game (GInput)
downloads/                          hash-verified upstream zips are cached here
```

Not affiliated with Rockstar Games or Take-Two. CLEO, SilentPatch, Ultimate
ASI Loader, GInput and the car models belong to their respective authors.

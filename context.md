# Handoff / context for the next session

Repo: https://github.com/sahilkoditkar/gta-vc-ultimate-mod — single branch `main`, push
directly to it (user asked for one branch; the old `claude/...` branch was merged; it may
still exist on GitHub because this session could not delete remote refs — user deletes
it in the GitHub UI). Commits use the attribution footer from the system reminder.
Repo is public. Personal weekend project, not commercial.

## What the project is

A safe "Ultimate Vice City"-style mod kit for the classic PC GTA Vice City on
Windows 11 (user's copy is a Steam rip; exe version is detected at runtime).
Everything is delivered as one installer the user double-clicks. Read `README.md`
first — it is the authoritative short description of what gets installed and how.

Key files (all committed, all documented in README.md):

| Path | Role |
|---|---|
| `install.ps1` | The installer (PowerShell 5.1+ / pwsh 7). Steps 1–8: ASI loader, CLEO, cheat scripts, SilentPatch, Large-Address-Aware flag, graphics extras, mouse compat flags, cars. Also `-Restore`, `-Diagnose`, `-Cars both/local/release/none`, `-Skip*` switches. Pinned URLs + SHA256 at the top (`$Packages`), `$CarsRelease` base URL. |
| `Install.bat`, `Restore-Backup.bat`, `Diagnose.bat`, `install.sh` | launchers (Windows / Linux-pwsh) |
| `mods/CLEO/*.cs` | 6 cheat scripts (built bytecode) — infinite_health, infinite_money, no_bike_fall, all_weapons, infinite_sprint, no_dragout |
| `tools/cleo_asm.py` | tiny SCM assembler + readable source of every script; `python3 tools/cleo_asm.py` rebuilds them |
| `tools/test/make_fake_game.py` | fake game folder (minimal PE with version id, IMG v1, default.ide, handling/carcols) used for all installer tests |
| `cars/README.md` | 64-slot table with modern-car suggestions, download sources, priority order |
| `cars/Clean-Cars.ps1` + `.bat` | strips exe/screenshots from car archives → `cars/clean/*.zip`, writes `cars.json` (name+sha256, keeps `slot` fields). No arguments. |
| `cars.json` | manifest of the 31 archives on the `cars_v1` GitHub release (sha256 + 14 `slot` overrides) |
| `optional/README.md` | drop-in folder (GInput controller mod goes here) |
| `OPTIONS.md` | checklist of possible further additions; A2/A3/A7/B1/B2/B3 marked installed |

## Decisions and facts established (don't re-derive)

- No exe replacement/downgrade: CLEO 2.2.0 supports 1.0/1.1/Steam exes (verified in
  cleolibrary source: version id DWORD at VA 0x61C11C; installer reads it from the PE).
  Only exe change is the LAA header bit (fixes invisible models: on 64-bit Windows the
  game budgets ~2 GB streaming memory into a 2 GB process).
- ASI loader = Ultimate ASI Loader as `dinput8.dll`; alternative name `ddraw.dll`.
  Widescreen Fix's bundled `d3d8.dll`/`global.ini` are deliberately NOT installed.
- SkyGfx 2.7 only works on 1.0 exe → installer skips it otherwise; d3d8to9 wrapper only on Windows.
- Framerate Vigilante not added (no official GitHub release). mousefix.asi opt-in (`-InstallMouseFixAsi`, 1.0 only).
- Project2DFX `TargetFPS` is rewritten to 25 at install (user runs frame limiter ON, 30 fps).
- Cars: 64 fixed slots; installer writes `.dff/.txd` into `models/gta3.img` (IMG v1), edits
  handling.cfg/carcols.dat lines (vehicle token rewritten from `data/default.ide`), then
  compacts the IMG. Slot = archive/folder name, or `slot` in cars.json, else inner file names.
  Root-level model wins over sub-folder variants. Executables inside mods are ignored + reported.
- Car archives are NOT in git (gitignored); they live on GitHub release `cars_v1`.
  All 31 uploaded files were verified clean and hashed; end-to-end install from the real
  release was tested against the fake game (68 model files, 0 skipped).
- Restore merges every backup folder, oldest original wins (tested with 3 consecutive installs).
- This sandbox's network policy allows only GitHub; every mod site (libertycity, gtainside,
  moddb, …) is blocked. Cars must be downloaded by the user. GitHub API to other repos is
  blocked, but `github.com` release downloads and raw.githubusercontent work.
- Testing: pwsh 7 for Linux is unpacked at
  `/tmp/claude-0/-home-user-gta-vc-ultimate-mod/f8c182a9-1e4e-5384-8608-518a796e31ac/scratchpad/pwsh/pwsh`
  (scratchpad may be gone in a new session; re-download PowerShell tar.gz from GitHub
  releases). 7z from apt (p7zip-full/p7zip-rar) is available in the sandbox.
  Standard test: `make_fake_game.py <dir>`, copy pinned zips into `downloads/`, run
  `install.ps1 -GamePath <dir> -Yes -NoDownload ...`, then `-Restore` and `diff -r` vs a pristine copy.
- reVC (reverse-engineered VC source) was cloned to the scratchpad to verify game
  mechanics (bike knock-off flags, streaming memory, weapon ids); re-clone
  `https://github.com/AltronMaxX/reVC` if needed.

## User context

- Windows 11 laptop, 8 GB RAM, basic GPU; also wants to run on Ubuntu via Bottles
  (README has the Linux section; `install.sh` runs `install.ps1` natively with pwsh; the
  only extra step is the `dinput8` DLL override in the bottle).
- Controller: EvoFox One S 3-mode ("1S3") — mode combos documented in README.
- Game confirmed working after install (CLEO shows, cheats work); earlier issues solved:
  silent exit (Defender/gta_vc.set), 640x480 error (SilentPatch), invisible models (LAA + frame limiter).
- User wants the installer kept simple; extra tooling lives in separate scripts.

## Possible next work (only if the user asks)

- Items from `OPTIONS.md` not yet built: A1 never wanted, A4 car spawner hotkeys, A5/A6
  time & weather, A8 fast cars (handling.cfg), A9 slow-mo, A10 100% save; C3–C8 content
  (HD textures, weapons, skins, HUD, map add-ons, save game).
- Refresh pinned hashes if ThirteenAG's rolling `gtavc` release tags change (installer
  then warns and skips that step).
- More cars: user downloads → `cars/` → `Clean-Cars.bat` → upload `cars/clean/*.zip` to a
  release → commit `cars.json`; if a new tag is used, change `$CarsRelease` in `install.ps1`.
- Remove `install.sh` if the user decides against it (README Linux section would then say
  `pwsh -File install.ps1`).

## Suggested skills

None required. Use plain Bash/pwsh testing as above. `code-review` on `install.ps1`
would be reasonable before any large change.

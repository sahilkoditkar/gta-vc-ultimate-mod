# Optional extras – tick what you want

Everything below is **not installed** yet. Copy the lines you want into a message
("add A1, A3, B1, B3") and I'll build them into `Install.bat`. Items in A and B
need nothing from you; items in C need a file from a mod site dropped into the
repo, like the cars.

## A. Cheats I write myself (CLEO scripts, no downloads, on/off per file)

| | Cheat | What it does | Downside |
|---|---|---|---|
| A1 | **Never wanted** | wanted level stays at 0 stars, cops ignore you | police-chase missions become trivial |
| A2 | **All weapons + infinite ammo** | every weapon in every slot, ammo never drops | none, you can still switch to fists |
| A3 | **Infinite sprint** | Tommy never gets tired | none |
| A4 | **Car spawner hotkeys** | e.g. F5 Infernus, F6 PCJ-600, F7 Hunter, F8 Rhino; list is yours to pick | none |
| A5 | **Time & weather keys** | e.g. F9 = jump 1 hour, F10 = cycle weather (sunny → rain → fog) | none |
| A6 | **Freeze clock** | keep it always day (or always night) | none |
| A7 | **Nobody can pull you out of a car** | cops/peds can't drag you out (the bike script already does this on bikes) | none |
| A8 | **Fast cars** | +30 % top speed and acceleration on every car via `handling.cfg` | AI drivers get faster too |
| A9 | **Slow motion / fast forward key** | game speed 0.3× or 2× while a key is held | none |
| A10 | **Every property bought, map fully open** | all safehouses/businesses owned and both islands open from a new game | done via a modified save game rather than a script; you'd start from that save |

## B. Fixes & graphics from GitHub (installer downloads them, hash-checked)

| | Add-on | What it does | Cost |
|---|---|---|---|
| B1 | **Widescreen Fix** (ThirteenAG) | proper 16:9 / ultrawide, correct FOV, HUD and radar scaling, borderless window, no loading screen between islands, anti-aliasing option | none, strongly recommended |
| B2 | **Project2DFX** (ThirteenAG) | much longer draw distance, thousands of street/neon lights visible at night, distant cars with headlights | a bit of GPU, looks far more "modern" |
| B3 | **SkyGfx VC** (aap) | the PS2 look: motion-blur trails, PS2 colours and water, or the Xbox look with reflections | taste – some prefer the plain PC look; switchable in its ini |
| B4 | **Framerate Vigilante** (GTAmodding) | fixes physics/animation at high fps so you can run the frame limiter OFF at 144 fps | only useful if you want > 30 fps |
| B5 | **mousefix.asi** (sfwidde) | extra mouse-lock fix + vertical sensitivity | only works on the 1.0 exe; the installer already has `-InstallMouseFixAsi` |

## C. Content you download, installer applies

| | Content | Where | Where it goes |
|---|---|---|---|
| C1 | **64 modern cars** | see `cars/README.md` | `cars\` (already supported) |
| C2 | **GInput** – Xbox-style controller with on-screen button icons | https://silentsblog.com/mods/gta-vc/ | `optional\GInput\` (already supported) |
| C3 | **HD texture pack** (roads, buildings, sky) | libertycity → *Textures* / "Vice City HD" packs | `optional\<name>\` – I'll extend the installer to write `.txd` files into `gta3.img` and the interior IMGs |
| C4 | **Modern weapons pack** | libertycity → *Weapons* | `optional\weapons\` – same `.dff/.txd` mechanism as cars |
| C5 | **Tommy outfits / modern peds** | libertycity → *Skins* | `optional\skins\` |
| C6 | **HD radar map + HUD icons** | libertycity → *HUD* | `optional\hud\` |
| C7 | **Map add-ons** (new bridge, billboards, the Ultimate Vice City extras) | ModDB Ultimate Vice City 2.1 (open with 7-Zip, don't run) | `optional\map\` – needs `.ipl/.ide` lines merged; more work, tell me if you want it |
| C8 | **100 % save game** | https://libertycity.net/files/gta-vice-city/saves/ | `optional\saves\` → copied to Documents\GTA Vice City User Files |
| C9 | **Your own radio station** | no mod needed: drop `.mp3` files into the game's `mp3\` folder, in game pick the *MP3 player* station | – |

## D. Not worth it / avoid

* Trainers and "mod installer" `.exe` files – the thing you wanted to avoid.
* "Vice City Next Gen Edition" – a different game (GTA IV engine), not compatible with anything here.
* Definitive Edition / Android / San Andreas mods – wrong file formats.
* Very heavy car models converted from Forza / Assetto – crash the 2002 engine.
* Modloader – handy for modders, but this installer already does what you'd use it for.

## My suggestion for "the old Ultimate feeling"

A1 A2 A3 A4 A7 A8 + B1 B2 + C1 C2, and C8 if you don't want to replay the story
to unlock the second island.

# optional/ — drop-in extras

Anything you put in a sub-folder here is copied 1:1 into the game folder by
the installer (with backup). `ReadMe.txt`, `README.md` and `docs\` are skipped.

The one thing worth putting here is **GInput** (proper Xbox/XInput controller
support with on-screen button prompts, by Silent — same author as SilentPatch):

1. Download "GInput VC" from the author's page: https://silentsblog.com/mods/gta-vc/
   (mirrors: ModDB "[III/VC/SA] GInput v1.11", libertycity.net "GInput VC v1.11").
   It is a plain zip with `GInputVC.asi`, `GInputVC.ini`, a `models\` folder and docs.
   No installer, no exe — if the archive you found contains an .exe, get it elsewhere.
2. Extract it into `optional\GInput\` so that `optional\GInput\GInputVC.asi` exists.
3. Run `Install.bat` again.

It is not downloaded automatically because it is not hosted on GitHub, so this
script cannot pin a hash for it. See README.md section 6 for how to use it.

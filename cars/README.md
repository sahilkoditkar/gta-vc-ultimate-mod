# cars/ — drop your car mods here

Each car mod goes in its **own sub-folder** (or as a `.zip`), for example:

```
cars/
  lamborghini_aventador/
    infernus.dff      <- 3D model, named after the Vice City car it replaces
    infernus.txd      <- textures, same name
    handling.txt      <- OPTIONAL: one line for data\handling.cfg
    carcols.txt       <- OPTIONAL: one line for data\carcols.dat
  ferrari_f40.zip     <- zips are fine too, same layout inside
```

The installer replaces the matching entries inside `models\gta3.img` and,
if the optional text files exist, swaps the matching line in `handling.cfg`
/ `carcols.dat` (the first word on the line is the vehicle name that gets
matched). Everything it touches is backed up first.

## Which files are safe?

* `.dff` and `.txd` are pure **data** (mesh + textures). The game just reads
  them; they cannot run code. Same for `.txt`, `.cfg`, `.dat`, `.ide` lines.
* **Never** run an `.exe`, `.bat`, `.cmd`, `.msi` or `.scr` that comes inside a
  mod archive ("auto installer", "setup", "trainer"). You do not need it —
  this installer does the same job with readable code.
* Right-click any downloaded archive → *Scan with Microsoft Defender* before
  extracting. It is free and already on Windows 11.

## Where to get cars

Long-running community archives where each file has an author page and
comments (check them, and prefer files with many downloads and a clear
"replaces: infernus" style description):

* https://libertycity.net/files/gta-vice-city/vehicles/cars/
* https://www.gtainside.com/en/vicecity/cars/
* https://www.gtagarage.com/mods/browse.php?C=11 (older, original 2000s mods —
  this is where the "Ultimate Vice City" era cars came from)

Good cars to replace for a "sports car" feel: `infernus`, `cheetah`,
`banshee`, `stinger`, `phoenix`, `comet`, `sabretur`, `deluxo`.

## Keep it stable

Vice City is a 2002 engine. Mods made for it (VC-era, "low poly") run fine.
Very high-detail conversions from newer games can crash the game or tank the
frame rate. If the game crashes after a car, remove that folder and run
`Restore-Backup.bat`, then try a lighter model.

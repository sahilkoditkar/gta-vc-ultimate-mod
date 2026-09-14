# cars/ – one zip per car

Every car in traffic is one of 64 fixed slots; the game can't delete a slot,
only replace what's in it. Fill the slots below and the whole city is modern.

## Adding a car (no extracting, no renaming inside)

1. Download a car mod made for the **classic PC Vice City** (not Definitive
   Edition, not Android, not San Andreas).
2. Rename the archive to the slot name from the table, e.g. `infernus.rar`,
   and put it in this folder. `.rar` (what libertycity ships), `.zip` and
   `.7z` all work; a folder called `infernus\` with the files inside works
   too. Files inside can be called anything, nested folders are fine.
   (`.rar`/`.7z` need 7-Zip; the installer installs it via winget if missing.)
3. Run `Install.bat` – it installs whatever is in this folder: writes the
   model over the old car in `gta3.img`, applies the handling / carcols lines
   the mod ships, removes the old car's data.

Optional: `Clean-Cars.bat` writes a data-only `.zip` copy of every archive
here into `clean\` (drops the `.exe` installers and screenshots; originals
stay) and updates `..\cars.json` with their SHA256. Upload `clean\*.zip` to
the GitHub release named in `install.ps1` and commit `cars.json`;
`Install.bat` then downloads them (hash-checked) wherever it runs. An archive
whose files are not named after a vehicle gets `"slot": "..."` in `cars.json`.

Only `.dff` / `.txd` / `.txt` are used – they are data and can't run code.
Any `.exe` / `.bat` inside a mod is ignored and reported; never run one.
Scan downloads with Defender (right-click → *Scan with Microsoft Defender*).

## Where to download

* By slot (best): `https://libertycity.net/files/gta-vice-city/zamena/<slot>.dff/`
  – e.g. https://libertycity.net/files/gta-vice-city/zamena/infernus.dff/ lists
  70+ cars made for the Infernus slot; sort by rating, take a recent one.
* By brand: https://libertycity.net/files/gta-vice-city/vehicles/cars/
* Also: https://www.gtainside.com/en/vicecity/cars/ and https://www.gtagarage.com/mods/browse.php?C=11
* Whole packs (many slots in one zip, files already named `infernus.dff` etc.
  – put the whole pack in one folder here, any name):
  https://libertycity.net/files/gta-vice-city/vehicles/car-packs/
* *Ultimate Vice City 2.1* (the 2000s mod, 40 real cars) on ModDB / MajorGeeks
  is an `.exe` installer: don't run it, open it with 7-Zip and take the
  `.dff`/`.txd` out.

Pick "lightweight" / "VC style" models over huge Forza conversions; the 2002
engine crashes on very heavy ones. Priority if you don't want all 64 at once:
`infernus cheetah banshee stinger comet deluxo sentinel sentxs admiral washing
landstal rancher patriot bobcat stallion sabretur pheonix blistac taxi police`.

## Full slot list (64 cars) with modern suggestions

Search the "Search for" text on libertycity/gtainside. Any car in the same
size class works; the suggestion is just a good fit for the slot's role.

| Slot (folder name) | Original | Role in traffic | Modern suggestion (search for) |
|---|---|---|---|
| `infernus` | Infernus | supercar, rich areas | Lamborghini Aventador SVJ / Revuelto |
| `cheetah` | Cheetah | supercar | Ferrari F8 Tributo / SF90 |
| `banshee` | Banshee | sports | Dodge Viper / Chevrolet Corvette C8 |
| `stinger` | Stinger | roadster | Porsche 718 Boxster / BMW Z4 |
| `comet` | Comet | sports | Porsche 911 (992) |
| `deluxo` | Deluxo | 80s exotic | Audi R8 / Tesla Roadster |
| `pheonix` | Phoenix (yes, the game misspells it) | muscle | Ford Mustang Shelby GT500 |
| `sabre` | Sabre | muscle | Chevrolet Camaro SS |
| `sabretur` | Sabre Turbo | muscle | Chevrolet Camaro ZL1 |
| `stallion` | Stallion | muscle | Ford Mustang GT |
| `hermes` | Hermes | 50s cruiser | Dodge Challenger Hellcat |
| `esperant` | Esperanto | coupe | Lexus RC / Infiniti Q60 |
| `idaho` | Idaho | coupe | Dodge Charger |
| `manana` | Manana | small coupe | Honda Civic Type R |
| `blistac` | Blista Compact | hatchback | VW Golf GTI / Honda Civic |
| `sentinel` | Sentinel | executive sedan | BMW 5 Series (G30) |
| `sentxs` | Sentinel XS | sports sedan | BMW M5 |
| `admiral` | Admiral | luxury sedan | Mercedes-Benz S-Class (W223) |
| `washing` | Washington | sedan | Mercedes-Benz E-Class |
| `virgo` | Virgo | old sedan | Cadillac CT5 |
| `greenwoo` | Greenwood | old sedan | Chevrolet Impala / Malibu |
| `glendale` | Glendale | old sedan | Chrysler 300 |
| `oceanic` | Oceanic | big cruiser | Rolls-Royce Ghost |
| `stretch` | Stretch | limo | Mercedes-Maybach / Cadillac Escalade limo |
| `lovefist` | Love Fist limo | limo (mission) | Hummer H2 limo |
| `regina` | Regina | station wagon | Volvo V90 / Audi RS6 Avant |
| `peren` | Perennial | station wagon | Subaru Outback |
| `landstal` | Landstalker | SUV | Range Rover Sport / Toyota Land Cruiser |
| `rancher` | Rancher | SUV | Jeep Wrangler |
| `fbiranch` | FBI Rancher | unmarked SUV | Chevrolet Tahoe (black) |
| `mesa` | Mesa Grande | off-road | Jeep Gladiator |
| `patriot` | Patriot | big 4x4 | GMC Hummer EV / Hummer H2 |
| `sandking` | Sandking | off-road truck | Ford F-150 Raptor |
| `bobcat` | Bobcat | pickup | Toyota Tacoma / Ford Ranger |
| `walton` | Walton | old pickup | Ford F-250 |
| `bfinject` | BF Injection | dune buggy | Polaris RZR |
| `cuban` | Cuban Hermes | gang car | Dodge Charger SRT (lowered) |
| `voodoo` | Voodoo | lowrider | Chevrolet Impala lowrider / Cadillac CTS-V |
| `hotring` | Hotring Racer | race car | NASCAR Camaro / Mustang |
| `hotrina` | Hotring Racer A | race car | any GT3 race car |
| `hotrinb` | Hotring Racer B | race car | any GT3 race car |
| `bloodra` | Bloodring Banger A | derby car | any beater |
| `bloodrb` | Bloodring Banger B | derby car | any beater |
| `taxi` | Taxi | taxi | Toyota Camry / Prius taxi |
| `cabbie` | Cabbie | taxi | Toyota Sienna taxi |
| `zebra` | Zebra Cab | taxi | any taxi with a stripe livery |
| `kaufman` | Kaufman Cab | taxi (yours) | Tesla Model 3 taxi |
| `police` | Police | cop car | Ford Explorer Police Interceptor / Charger Pursuit |
| `vicechee` | Vice Squad Cheetah | undercover | Ferrari with lights |
| `fbicar` | FBI Washington | unmarked | Dodge Charger (unmarked) |
| `enforcer` | Enforcer | SWAT | Lenco BearCat |
| `securica` | Securicar | armoured van | Brink's / Loomis truck |
| `ambulan` | Ambulance | ambulance | Ford F-450 ambulance |
| `firetruk` | Fire Truck | fire engine | Rosenbauer / Pierce engine |
| `pony` | Pony | van | Mercedes Sprinter |
| `rumpo` | Rumpo | van | Ford Transit |
| `burrito` | Burrito | van | Chevrolet Express |
| `gangbur` | Gang Burrito | gang van | Ford Transit Custom (black) |
| `spand` | Spand Express | delivery van | Amazon-style Sprinter |
| `topfun` | Top Fun | RC van | any small van |
| `moonbeam` | Moonbeam | minivan | Toyota Sienna / Alphard |
| `mrwhoop` | Mr Whoopee | ice-cream van | modern ice-cream truck |
| `mule` | Mule | box truck | Isuzu N-Series |
| `yankee` | Yankee | box truck | Hino / Isuzu box truck |
| `benson` | Benson | box truck | Freightliner M2 |
| `boxville` | Boxville | box truck | GMC step van |
| `flatbed` | Flatbed | flatbed truck | Kenworth flatbed |
| `linerun` | Linerunner | semi tractor | Volvo VNL / Peterbilt 579 |
| `packer` | Packer | car carrier | modern car hauler |
| `trash` | Trashmaster | garbage truck | Mack LR / modern refuse truck |
| `barracks` | Barracks OL | army truck | Oshkosh FMTV |
| `bus` | Bus | city bus | New Flyer / Volvo city bus |
| `coach` | Coach | coach | Setra / Prevost |
| `caddy` | Caddy | golf cart | modern golf cart |
| `baggage` | Baggage | airport tug | (leave) |
| `rhino` | Rhino | tank | M1 Abrams (leave) |

Bikes (`pcj600`, `freeway`, `angel`, `sanchez`, `faggio`, `pizzaboy`), boats,
helicopters and planes have their own slots and work the same way, they are
just not part of the "cars" count.

## Order of priority

If you don't want to hunt for 64 files at once, do them in this order — the
first two groups are what you actually see in traffic on the rich side of
town and cover the "it looks modern" feeling with ~15 cars:

1. `infernus cheetah banshee stinger comet deluxo sentinel sentxs admiral washing`
2. `landstal rancher patriot bobcat stallion sabretur pheonix blistac taxi police`
3. everything else in the table.

## If the game crashes after a car

That model is too heavy or broken for the 2002 engine. Delete its folder,
run `Restore-Backup.bat`, run `Install.bat` again. Prefer mods marked
"lightweight", "VC-style", "low poly" or converted from GTA SA / GTA IV over
ones converted from Forza / Assetto Corsa.

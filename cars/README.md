# cars/ — the "every car modern" plan

Vice City cannot *delete* a vehicle: every car in traffic is one of 64 fixed
slots. "Removing the old cars" therefore means **replacing all 64 slots**.
This folder is where the replacements go, and the table below is the full
slot list with a modern real-car suggestion for each, so the whole city looks
current, not just a few exotics.

## How to add a car (30 seconds each)

1. Download a car mod for **the classic PC Vice City** (not "Definitive
   Edition", not iOS/Android, not San Andreas — those use different formats).
2. Make a folder here **named after the slot it replaces** (first column of the
   table) and put the mod's files inside — names inside don't matter:

   ```
   cars\
     infernus\                 <- slot name = folder name
       Lamborghini_Aventador.dff
       Lamborghini_Aventador.txd
       readme handling.txt     <- optional; any *.txt with "handling" in the name
       carcols.txt             <- optional; any *.txt with "carcol" in the name
     cheetah.zip               <- a zip named after the slot works the same way
   ```

   The installer renames the `.dff`/`.txd` to the slot's names inside
   `models\gta3.img`, and rewrites the vehicle name on handling / carcols
   lines to the slot's IDs (taken from your own `data\default.ide`), so lines
   that mod authors paste into their readme just work.
3. Run `Install.bat` again. Only the new folders take a moment; everything
   else says "already installed".

Multiple `.dff` files in one folder (e.g. a mod that also ships a wheel or
an LOD) fall back to name-matching, so keep one car per folder.

## What's safe

* `.dff`, `.txd`, `.txt`, `.cfg`, `.dat` = data. The game parses them; they
  cannot execute anything. `.col` files are ignored (VC keeps vehicle
  collision inside the `.dff`).
* **Never run** any `.exe` / `.bat` / `.msi` shipped inside a mod ("auto
  installer", "setup", "trainer"). The installer ignores them and tells you.
  If a mod is *only* offered as an `.exe` installer, skip it — there is always
  a plain-zip alternative for the same car.
* Right-click every downloaded archive → *Scan with Microsoft Defender*.
* Take mods from the big archives where each file has an author, date,
  download count and comments: libertycity.net, gtainside.com, gtagarage.com,
  gtaall.com, modland.net, moddb.com. Prefer files with thousands of
  downloads and recent positive comments.

## Where to look

* Everything by slot: `https://libertycity.net/files/gta-vice-city/zamena/<slot>.dff/`
  (e.g. `.../zamena/infernus.dff/` lists 70+ cars made to replace the Infernus).
* Brand folders: `https://libertycity.net/files/gta-vice-city/vehicles/cars/lamborghini/`
  (also `ferrari`, `bmw`, `audi`, `mercedes`, `porsche`, `toyota`, ...).
* GTAInside: `https://www.gtainside.com/en/vicecity/cars/` (filter/search by name).
* Ready-made full packs (one download replaces most slots — each of these is a
  zip with `.dff`/`.txd` per slot; unpack and sort into slot folders, or if the
  files are already named `infernus.dff` etc. just drop the whole thing in one
  folder):
  * *NextGen Cars Pack* and other packs: `https://libertycity.net/files/gta-vice-city/vehicles/car-packs/`
  * *GTA VC: True Vehicle Pack* (ModDB) — real cars but era-correct 1980s, not modern.
  * *Ultimate Vice City 2.1* (ModDB / MajorGeeks) — the mod you remember (40 real
    cars, 2000s models). It is an `.exe` installer: do **not** run it; open it
    with 7-Zip (*right-click → 7-Zip → Open archive*) and pull the `.dff`/`.txd`
    files out into slot folders instead.

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

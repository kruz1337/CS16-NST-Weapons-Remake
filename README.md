# CS16-NST-Weapons-Remake
This repository is AMX Mod X plugin for add new customizable weapons to Counter-Strike 1.6 game.

![](https://img.shields.io/badge/language-pawn-a68762?style=flat) ![](https://img.shields.io/badge/game-cs16-yellow?style=flat) ![](https://img.shields.io/badge/license-GNU-green?style=flat)

## How to build NST Weapons Remake Script files?
* First of all you should download project files on project page or clone this repository from GitBash or GitHub Desktop on your PC. [NST-Weapons-Remake.zip](https://github.com/Kruziikrel1/CS16-NST-Weapons-Remake)

* If you download project files with manual method you need extract zip file.

* Go Counter-Strike 1.6 directory the go "cstrike/addons/amxmodx/scripting"

* Drag one by one all scripts in "CS16-NST-Weapons-Remake" repository it to "amxxpc.exe"

* Check all ".amxx" files.

## How to add NST Weapons Remake Plugin in game
* Before doing this steps, build NST Weapons Remake Script files.

* Firstly, move all ".amxx" files to "cstrike/addons/amxmodx/plugins" in Counter-Strike 1.6 directory.

* Finally, open "plugins.ini" file in "cstrike/addons/amxmodx/configs" then add these to the bottom line.
```
nst_weapons.amxx
nst_weapons_knifes.amxx
nst_weapons_primary.amxx
nst_weapons_secondary.amxx
```

* That's all, enjoy it :)

## What is NST Weapons Remake commands?
* nst_menu <0|1> : Opens NST Weapons Remake Menu.
* nst_free <0|1> : If you set 1, all NST weapons are will be free.
* nst_use_buyzone <0|1> : If you set 0, players can open NST Weapons Menu anywhere.
* nst_buy_time <second> : You set the NST Weapons buy time.
* nst_give_bot <0|1> : If you set 1, all bots can buy NST Weapons.
* nst_zoom_spk <0|1> : If you set 0, there will be no sound when NST weapon scope is opened.

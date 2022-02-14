# CS16-NST-Weapons-Remake
This repository is AMX Mod X plugin for add new customizable weapons to Counter-Strike 1.6 game.

![](https://img.shields.io/badge/language-pawn-a68762?style=flat) ![](https://img.shields.io/badge/game-cs16-yellow?style=flat) ![](https://img.shields.io/badge/license-GNU-green?style=flat)

![Image of RequestX International Developer Group on Discord](https://raw.githubusercontent.com/Kruziikrel1/CS16-NST-Weapons-Remake/main/thumbnail.png)

## How to build NST Weapons Remake Script files?
* First of all you should download project files on project page or clone this repository from GitBash or GitHub Desktop on your PC. [NST-Weapons-Remake.zip](https://github.com/Kruziikrel1/CS16-NST-Weapons-Remake/releases/)

* If you download project files with manual method you need extract zip file.

* Go Counter-Strike 1.6 directory the go "cstrike/addons/amxmodx/scripting"

* Move "string_stocks.inc" file to "cstrike/addons/amxmodx/scripting/include" directory and move "cstrike_amxx.dll" file to "cstrike/addons/amxmodx/modules" in project files.

* Add this line "modules.ini" file in "cstrike/addons/amxmodx/configs" directory.
```
cstrike
```

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
* nst_menu <0/1> : Opens NST Weapons Remake Menu.
* nst_free <0/1> : If you set 1, all NST weapons are will be free.
* nst_use_buyzone <0/1> : If you set 0, players can open NST Weapons Menu anywhere.
* nst_buy_time <Second> : You set the NST Weapons buy time.
* nst_give_bot <0/1> : If you set 1, all bots can buy NST Weapons.
* nst_zoom_spk <0/1> : If you set 0, there will be no sound when NST weapon scope is opened.

## How to make NST Weapons Remake config?
### Syntax Rules:

* Do not use Float in digit values.
* Do not set digit values more than 6 character.
* Use the value order in the config file. If you change values place you will get error.
* Do not set Digit values in Sound Files, Model Files and Sprite Files.
* Do not add any values other than those in the config file.
* Set "Tracer" value like `"255 255 255"`. Do not delete spaces. Do not insert different operators in spaces.
* Set "wpn_id" value to `"1, 10, 11, 16, 17 or 26"` in Pistol config file. 
* Set "wpn_id" value to `"3, 5,7, 8, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28 or 30"`
  in Rifles config file.
* Always do not add sound more than 2 when setting "fire_sounds".
* When you setting Models, Sounds or Sprite value do not add "models/", "sounds/", or "sprites/" in value begin.

- [x] If you follow these rules, you will not get any error.
  
### Some Infos:
- If you set "reload" value to "1" player will be able to shoot until the ammo runs out.
- If you increase "speed" value, player speed will increase while holding that NST weapon.
- If you increase "knockback" value, enemy will you shoot is knocked back.
- If you set "zoom_type" value to "3" when you click right click open's custom sight model.
 #### Secondary Types:
  ```
"4" = When you hold right click pistol auto shoots
"3" = Custom model scope
"2" = Awp big scope
"1" = Zoom
  ```
 #### Tracer Types:
  ```
"2" = New tracer
"1" = Spawns custom sprites where bullet is thrown
"0" = Classic tracer
  ```
  #### Example Images:
  | Zoom Type 1 | Zoom Type 2 | Tracer Type 1 | Tracer Type 2 |
  |-------------|-------------|---------------|---------------|
  |![](https://raw.githubusercontent.com/Kruziikrel1/CS16-NST-Weapons-Remake/main/zoomtype1.png)|![](https://raw.githubusercontent.com/Kruziikrel1/CS16-NST-Weapons-Remake/main/zoomtype2.png)             |![](https://raw.githubusercontent.com/Kruziikrel1/CS16-NST-Weapons-Remake/main/tracertype1.png)                |![](https://raw.githubusercontent.com/Kruziikrel1/CS16-NST-Weapons-Remake/main/tracertype2.png)              |
  
  | Reload 0 |
  |-------------|
  |![](https://user-images.githubusercontent.com/61029407/145643046-20b341ba-4534-4d9f-b6c6-a67164be107c.gif)|

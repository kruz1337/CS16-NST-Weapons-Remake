# CS16-NST-Weapons-Remake
This repository is AMX Mod X plugin for add new customizable weapons to Counter-Strike 1.6 game. This repository still under development. If you have any issue please write in github or requestx discord server. **Supports Counter-Strike bots.**

![](https://img.shields.io/badge/language-pawn-a68762?style=flat) ![](https://img.shields.io/badge/game-cs16-yellow?style=flat) ![](https://img.shields.io/badge/license-GNU-green?style=flat)

![Image of RequestX International Developer Group on Discord](https://raw.githubusercontent.com/kruz1337/CS16-NST-Weapons-Remake/main/thumbnail.png)

## How to build NST Weapons Remake Script files?
* First of all you should download project files on project page or clone this repository from GitBash or GitHub Desktop on your PC. [NST-Weapons-Remake.zip](https://github.com/kruz1337/CS16-NST-Weapons-Remake/releases/)

* If you download project files with manual method you need extract zip file.

* Go Counter-Strike 1.6 directory the go "cstrike/addons/amxmodx/scripting"

* Move "string_stocks.inc" file to "cstrike/addons/amxmodx/scripting/include" directory and move "cstrike_amxx.dll" file to "cstrike/addons/amxmodx/modules" in project files.

* Add this line "modules.ini" file in "cstrike/addons/amxmodx/configs" directory.
```
cstrike
```

* Drag one by one all NST scripts it to "amxxpc.exe"

* Finally, ".amxx" files will be created in current path.

## How to add NST Weapons Remake Plugin in game
* Firstly, Before doing this steps, build NST Weapons Remake Script files.

* Then, Move all ".amxx" files to "cstrike/addons/amxmodx/plugins" in game directory.

* Finally, open "plugins.ini" file in "cstrike/addons/amxmodx/configs" then add full names of the files you builded line by line.

* That's all, enjoy it :)

## What is NST Weapons Remake commands?
* nst_menu: Opens NST Weapons Remake Menu.
* nst_free <0/1>: If you set 1, all NST weapons are will be free.
* nst_use_buyzone <0/1>: If you set 0, players can open NST Weapons Menu anywhere.
* nst_buy_time <Second>: You set the NST Weapons buy time.
* nst_give_bot <0/1>: If you set 1, all bots can buy NST Weapons.
* nst_zoom_spk <0/1>: If you set 0, there will be no sound when NST weapon scope is opened.

## How to make NST Weapons Remake config?
### Syntax Rules:
  
* Use the value order in the config file.
* Use only secondary weapon IDs in the wpnid field in the secondary weapons configuration and use primary weapon IDs on primary weapons as well. You can see weapon IDs in [this site](https://wiki.alliedmods.net/Cs_weapons_information).
* Create the config file as shown in the Example config files.
* Do not delete comma and don't change coma to different character when setting value to "trace" field.
* Do not set long values.
* Do not add any values other than those in the config file.
* Do not start with `"/models, /sounds, /sprites"` when adding values to Models, Sounds and Sprite fields.
* Do not add sound more than 2 when adding value to "fire_sounds" field.
* Do not add empty line but you can add new line **after end of new added weapon**.

- [x] If you follow these rules, you will not get any error.
  
### Some Infos:
- If you set "reload" value to "0" player will be able to shoot until the all ammo runs out.
- If you increase "speed" value, player attack speed will increase while holding that NST weapon.
- If you increase "knockback" value, enemy will you shoot is knocked back.
- If you set "secondary_type" value to "3" when you click right click open's your custom sight model. You should add "sight_model" but if you dont set this value you can leave at blank "sight_model" value.
 #### Secondary Types:
  ```
"4" = Automatically fires when you hold right mouse button
"3" = Open's iron sight
"2" = Open's awp scope
"1" = Open's aug zoom
"0" = Disabled
  ```
 #### Tracer Types:
  ```
"3" = Tracer type 2
"2" = Tracer type
"1" = Spawns custom sprites where bullet is thrown
"0" = Disabled
  ```

  
  #### Example Images:
  | Secondary type 1 | Secondary type 2 | Secondary Type 3 | Secondary Type 4 |
  |------------------|------------------|------------------|------------------|
  | <img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/sectype1.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage">        | <img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/sectype2.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage">        | <img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/sectype3.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage">        | <img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/sectype4.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage">        | 
  
  | Tracer type 1 | Tracer type 2 | Tracer type 3 | No Relaod |
  |---------------|---------------|---------------|-----------|
 |<img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/tracertype1.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage">     | <img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/tracertype2.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage">     | <img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/tracertype3.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage">     | <img src="https://github.com/kruz1337/CS16-NST-Weapons-Remake/raw/main/noreload.gif" alt="Image of RequestX International Developer Group on Discord" style="max-width: 100%; display: inline-block;" width="200" data-target="animated-image.originalImage"> |
  


#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta_util>
#include <string_stocks>

#define PLUGIN "NST Primary Weapons"
#define VERSION "1.2.1"
#define AUTHOR "github.com/kruz1337"

const m_pPlayer = 41
const m_iId = 43
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47
const m_flTimeWeaponIdle = 48
const m_iPrimaryAmmoType = 49
const m_iClip = 51
const m_fInReload = 54
const m_flNextAttack = 83
const m_iFOV = 363
const m_rgPlayerAmmo_Slot0 = 376
const m_fInSpecialReload = 55
const m_fWeaponState = 74
const m_rgpPlayerItems_Slot1 = 368
const m_iHideHUD = 361

const MAX_WPN = 40
const MAX_PLAYER = 32
const NEXT_SECTION = 25 - 1
const MAX_ARRAYSIZE = 64

new HAS_WEAPON[MAX_PLAYER], CURRENT_WEAPON[MAX_PLAYER]
new SAVED_CLIP[MAX_PLAYER]
new IS_INIRONSIGHT[MAX_PLAYER], IS_INRELOAD[MAX_PLAYER]
new Float: PUSHANGLE[MAX_PLAYER][3]

new Array: Rifle_InfoText
new Array: Rifle_Names

new bool: IsConfigBroken = false
new bool: IsInCommencing = false
new Float: gameTime

new Float: cvar_deploy[MAX_WPN + 1]
new Float: cvar_dmgmultiplier[MAX_WPN + 1]
new Float: cvar_speed[MAX_WPN + 1]
new Float: cvar_recoil[MAX_WPN + 1]
new Float: cvar_knockback[MAX_WPN + 1]
new Float: cvar_fastrun[MAX_WPN + 1]
new Float: cvar_sightrecoil[MAX_WPN + 1]

new class_weapons[MAX_WPN + 1][MAX_ARRAYSIZE]
new cvar_secondary_type[MAX_WPN + 1]
new cvar_clip[MAX_WPN + 1]
new cvar_ammo[MAX_WPN + 1]
new cvar_cost[MAX_WPN + 1]
new cvar_administrator[MAX_WPN + 1]
new cvar_reload[MAX_WPN + 1]
new cvar_tracer[MAX_WPN + 1][MAX_ARRAYSIZE]
new cvar_tracer_type[MAX_WPN + 1]
new cvar_tracer_sprite[MAX_WPN + 1]
new cvar_buycvar[MAX_WPN + 1][MAX_ARRAYSIZE]

new const primaryWeaponsId[] = { 3, 5, 7, 8, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 24, 27, 28, 30 }
new const primaryWeaponsWorld[] = { "models/w_scout.mdl", "models/w_xm1014.mdl", "models/w_aug.mdl", "models/w_mac10.mdl", "models/w_ump45.mdl", "models/w_sg550.mdl", "models/w_galil.mdl", "models/w_famas.mdl", "models/w_awp.mdl", "models/w_mp5.mdl", "models/w_m249.mdl", "models/w_m3.mdl", "models/w_m4a1.mdl", "models/w_tmp.mdl", "models/w_g3sg1.mdl", "models/w_sg552.mdl", "models/w_ak47.mdl", "models/w_p90.mdl" }
new const weaponsAmmoId[] = {-1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }
new const weaponsMaxAmmo[] = {-1, 13, -1, 10, 1, 7, 1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }
new const weaponsMaxBpAmmo[] = {-1, 52, -1, 90, -1, 32, -1, 100, 90, -1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, -1, 35, 90, 90, -1, 100 }
new const weaponsAmmo[] = {-1, 13, -1, 30, -1, 8, -1, 12, 30, -1, 30, 50, 12, 30, 30, 30, 12, 30, 10, 30, 30, 8, 30, 30, 30, -1, 30, 30, 30, -1, 50 }
new const weaponsAmmoCost[] = {-1, 50, -1, 80, -1, 65, -1, 25, 60, -1, 20, 50, 25, 60, 60, 60, 25, 20, 125, 20, 60, 65, 60, 20, 80, -1, 80, 60, 80, -1, 50 }
new const Float: weaponsReloadDelay[] = { 0.00, 2.70, 0.00, 2.00, 0.00, 0.55, 0.00, 3.15, 3.30, 0.00, 4.50, 2.70, 3.50, 3.35, 2.45, 3.30, 2.70, 2.20, 2.50, 2.63, 4.70, 0.55, 3.05, 2.12, 3.50, 0.00, 2.20, 3.00, 2.45, 0.00, 3.40 }

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("nst_weapons.txt")

    register_concmd("nst_primary_rebuy", "ReBuy_Weapon")
    register_clcmd("nst_menu_type2", "NST_Shotguns")
    register_clcmd("nst_menu_type3", "NST_Submachine")
    register_clcmd("nst_menu_type4", "NST_Snipers")
    register_clcmd("nst_menu_type5", "NST_Rifles")
    register_clcmd("nst_menu_type6", "NST_Machine")
    register_clcmd("nst_primary_buy", "NST_Buy_Convar")
    register_clcmd("buyammo1", "Cmd_BuyAmmo1")
    register_clcmd("primammo", "Cmd_BuyAmmo1")

    register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
    register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")
    register_event("Damage", "Event_Damage", "b", "2>0")
    register_event("DeathMsg", "Event_Death", "a")
    register_event("TextMsg", "Event_Commencing", "a", "2=#Game_Commencing", "2=#Game_End", "2=#Game_will_restart_in")

    register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
    register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
    register_forward(FM_SetModel, "fw_WorldModel")
    register_forward(FM_CmdStart, "fw_CmdStart")

    RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Pre")
    RegisterHam(Ham_Touch, "weaponbox", "Ham_PlayerTouchWeaponBox")
    RegisterHam(Ham_TraceAttack, "worldspawn", "Ham_TraceAttack_Post", 1)
    RegisterHam(Ham_TraceAttack, "func_breakable", "Ham_TraceAttack_Post", 1)
    RegisterHam(Ham_TraceAttack, "func_wall", "Ham_TraceAttack_Post", 1)
    RegisterHam(Ham_TraceAttack, "func_door", "Ham_TraceAttack_Post", 1)
    RegisterHam(Ham_TraceAttack, "func_door_rotating", "Ham_TraceAttack_Post", 1)
    RegisterHam(Ham_TraceAttack, "func_plat", "Ham_TraceAttack_Post", 1)
    RegisterHam(Ham_TraceAttack, "func_rotating", "Ham_TraceAttack_Post", 1)

    new weapon_name[64]
    for (new wpnId = 1; wpnId <= CSW_P90; wpnId++) {
        if (wpnId < CSW_P90 &&
            wpnId != 2 &&
            wpnId != CSW_KNIFE &&
            wpnId != CSW_ELITE &&
            wpnId != CSW_FIVESEVEN &&
            wpnId != CSW_USP &&
            wpnId != CSW_GLOCK18 &&
            wpnId != CSW_DEAGLE &&
            wpnId != CSW_HEGRENADE &&
            wpnId != CSW_SMOKEGRENADE &&
            wpnId != CSW_FLASHBANG && get_weaponname(wpnId, weapon_name, charsmax(weapon_name))) {

            if (wpnId == CSW_M3 || wpnId == CSW_XM1014) {
                RegisterHam(Ham_Item_PostFrame, weapon_name, "Shotguns_PostFrame_Pre")
            } else {
                RegisterHam(Ham_Item_PostFrame, weapon_name, "Rifles_PostFrame_Pre")
                RegisterHam(Ham_Weapon_Reload, weapon_name, "Rifles_Reload_Post", 1)
            }

            RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "Primary_Attack")
            RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "Primary_Attack_Post", 1)
            RegisterHam(Ham_Item_Deploy, weapon_name, "Weapon_Deploy_Post", 1)
        }
    }
}

public plugin_precache() {
    plugin_startup()

    if (IsConfigBroken) {
        return
    }

    for (new wpnId = 1; wpnId < ArraySize(Rifle_Names); wpnId++) {
        new v_model[64], p_model[64], w_model[64], sight_model[64]
        formatex(v_model, charsmax(v_model), "models/%s", ParseConfig(wpnId, "v_model"))
        formatex(p_model, charsmax(p_model), "models/%s", ParseConfig(wpnId, "p_model"))
        formatex(w_model, charsmax(w_model), "models/%s", ParseConfig(wpnId, "w_model"))

        precache_model(v_model)
        precache_model(p_model)
        precache_model(w_model)

        if (equali(ParseConfig(wpnId, "secondary_type"), "3")) {
            formatex(sight_model, charsmax(sight_model), "models/%s", ParseConfig(wpnId, "sight_model"))
            precache_model(sight_model)
        }

        new sound[256]
        new sound1[64], sound2[64]

        formatex(sound, charsmax(sound), "%s", ParseConfig(wpnId, "fire_sounds"))
        strtok(sound, sound1, charsmax(sound1), sound2, charsmax(sound2), '*')
        trim(sound1)
        trim(sound2)

        if (contain(sound2, ".wav") == -1) {
            format(sound, charsmax(sound), "weapons/%s", sound)
            precache_sound(sound)
        } else {
            format(sound1, charsmax(sound1), "weapons/%s", sound1)
            format(sound2, charsmax(sound2), "weapons/%s", sound2)
            precache_sound(sound1)
            precache_sound(sound2)
        }

        new name[64]
        ArrayGetString(Rifle_Names, wpnId, name, charsmax(name))

        replace_all(name, charsmax(name), "-", "")
        replace_all(name, charsmax(name), "(", "")
        replace_all(name, charsmax(name), ")", "")
        replace_all(name, charsmax(name), " ", "")
        trim(name)
        strtolower(name)

        format(class_weapons[wpnId], charsmax(name), "nst_%s", name)

        if (strlen(ParseConfig(wpnId, "tracer"))) {
            format(cvar_tracer[wpnId], MAX_ARRAYSIZE, "%s", ParseConfig(wpnId, "tracer"))
        }

        format(cvar_buycvar[wpnId], MAX_ARRAYSIZE, "%s", ParseConfig(wpnId, "buycvar"))

        cvar_clip[wpnId] = str_to_num(ParseConfig(wpnId, "clip"))
        cvar_ammo[wpnId] = str_to_num(ParseConfig(wpnId, "ammo"))
        cvar_cost[wpnId] = str_to_num(ParseConfig(wpnId, "cost"))
        cvar_administrator[wpnId] = str_to_num(ParseConfig(wpnId, "administrator"))
        cvar_secondary_type[wpnId] = str_to_num(ParseConfig(wpnId, "secondary_type"))
        cvar_reload[wpnId] = str_to_num(ParseConfig(wpnId, "reload"))
        cvar_tracer_type[wpnId] = str_to_num(ParseConfig(wpnId, "tracer_type"))
        cvar_tracer_sprite[wpnId] = cvar_tracer_type[wpnId] == 0 ? 0 : precache_model(ParseConfig(wpnId, "tracer_sprite"))
        cvar_deploy[wpnId] = str_to_float(ParseConfig(wpnId, "deploy"))
        cvar_knockback[wpnId] = str_to_float(ParseConfig(wpnId, "knockback"))
        cvar_recoil[wpnId] = str_to_float(ParseConfig(wpnId, "recoil"))
        cvar_dmgmultiplier[wpnId] = str_to_float(ParseConfig(wpnId, "damage"))
        cvar_speed[wpnId] = str_to_float(ParseConfig(wpnId, "speed"))
        cvar_fastrun[wpnId] = str_to_float(ParseConfig(wpnId, "fastrun"))
        cvar_sightrecoil[wpnId] = str_to_float(ParseConfig(wpnId, "sight_recoil"))
    }
}

public plugin_startup() {
    new primaryFile[128] = { "addons/amxmodx/configs/nst_weapons/nst_primary.ini" }
    IsConfigBroken = !file_exists(primaryFile)

    if (IsConfigBroken) {
        new log[256]
        formatex(log[0], charsmax(log) - 0, "%L", LANG_PLAYER, "FILE_NOT_LOADED", "../nst_weapons/nst_primary.ini")
        server_print("[NST Weapons] %s", log)
        return
    }

    Rifle_InfoText = ArrayCreate(128)
    Rifle_Names = ArrayCreate(64)

    ReadConfig()
    ReadConfigSections()

    new exceptionLine = 0
    IsConfigBroken = !CheckConfigSyntax(exceptionLine)

    if (IsConfigBroken) {
        new log[256]
        formatex(log[0], charsmax(log) - 0, "%L", LANG_PLAYER, "BROKEN_CONFIG", "../nst_weapons/nst_primary.ini", exceptionLine)
        server_print("[NST Weapons] %s", log)
        return
    }
}

ReadConfigSections() {
    new sectionNumber = 0
    new buffer[64]

    ArrayPushString(Rifle_Names, "")

    for (new i = 0; i < ArraySize(Rifle_InfoText) / NEXT_SECTION && i < MAX_WPN; i++) {
        ArrayGetString(Rifle_InfoText, sectionNumber, buffer, charsmax(buffer))
        replace(buffer, charsmax(buffer), "[", "")
        replace(buffer, charsmax(buffer), "]", "")
        replace(buffer, charsmax(buffer), "^n", "")
        ArrayPushString(Rifle_Names, buffer)
        sectionNumber = ArraySize(Rifle_InfoText) > sectionNumber + NEXT_SECTION ? sectionNumber + NEXT_SECTION : ArraySize(Rifle_InfoText)
    }

    sectionNumber = 0
}

ReadConfig() {
    new buffer[256]
    new left_comment[256], right_comment[256], left_s_comment[256], right_s_comment[256]

    new primaryFile = fopen("addons/amxmodx/configs/nst_weapons/nst_primary.ini", "r")
    while (!feof(primaryFile)) {
        fgets(primaryFile, buffer, charsmax(buffer))

        //Comment Line Remover
        strtok(buffer, left_comment, charsmax(left_comment), right_comment, charsmax(right_comment), ';')
        format(right_comment, charsmax(right_comment), ";%s", right_comment)
        str_replace(buffer, charsmax(buffer), right_comment, strlen(left_comment) ? " " : "COMMENT_LINE")

        //Comment Line Remover 2
        strtok(buffer, left_s_comment, charsmax(left_s_comment), right_s_comment, charsmax(right_s_comment), ']')
        if (!equali(right_s_comment, "")) {
            str_replace(buffer, charsmax(buffer), right_s_comment, "")
        }

        if (!equali(buffer, "^n")) {
            ArrayPushString(Rifle_InfoText, buffer)
        }
    }

    for (new i = 0; i < ArraySize(Rifle_InfoText); i++) {
        new commentBuffer[256]
        ArrayGetString(Rifle_InfoText, i, commentBuffer, charsmax(commentBuffer))

        if (equali(commentBuffer, "COMMENT_LINE")) {
            ArrayDeleteItem(Rifle_InfoText, i)
        }
    }

    fclose(primaryFile)
}

ParseConfig(const wpnId, const Property[], & syntaxLine = 0) {
    const administrator = 1
    const cost = 2
    const wpn_id = 3
    const clip = 4
    const ammo = 5
    const damage = 6
    const recoil = 7
    const deploy = 8
    const reload = 9
    const speed = 10
    const knockback = 11
    const fastrun = 12
    const secondary_type = 13
    const tracer = 14
    const tracer_type = 15
    const tracer_sprite = 16
    const sight_recoil = 17
    const sight_model = 18
    const v_model = 19
    const p_model = 20
    const w_model = 21
    const fire_sounds = 22
    const buycvar = 23

    new propertyLine

    if (equali(Property, "administrator")) {
        propertyLine = administrator
    } else if (equali(Property, "cost")) {
        propertyLine = cost
    } else if (equali(Property, "wpn_id")) {
        propertyLine = wpn_id
    } else if (equali(Property, "clip")) {
        propertyLine = clip
    } else if (equali(Property, "ammo")) {
        propertyLine = ammo
    } else if (equali(Property, "damage")) {
        propertyLine = damage
    } else if (equali(Property, "recoil")) {
        propertyLine = recoil
    } else if (equali(Property, "deploy")) {
        propertyLine = deploy
    } else if (equali(Property, "reload")) {
        propertyLine = reload
    } else if (equali(Property, "speed")) {
        propertyLine = speed
    } else if (equali(Property, "knockback")) {
        propertyLine = knockback
    } else if (equali(Property, "fastrun")) {
        propertyLine = fastrun
    } else if (equali(Property, "secondary_type")) {
        propertyLine = secondary_type
    } else if (equali(Property, "tracer")) {
        propertyLine = tracer
    } else if (equali(Property, "tracer_type")) {
        propertyLine = tracer_type
    } else if (equali(Property, "tracer_sprite")) {
        propertyLine = tracer_sprite
    } else if (equali(Property, "sight_recoil")) {
        propertyLine = sight_recoil
    } else if (equali(Property, "sight_model")) {
        propertyLine = sight_model
    } else if (equali(Property, "v_model")) {
        propertyLine = v_model
    } else if (equali(Property, "p_model")) {
        propertyLine = p_model
    } else if (equali(Property, "w_model")) {
        propertyLine = w_model
    } else if (equali(Property, "fire_sounds")) {
        propertyLine = fire_sounds
    } else if (equali(Property, "buycvar")) {
        propertyLine = buycvar
    }

    new parseLine[128]
    new field[128], value[128]
    new fieldLineNumber = max((wpnId * NEXT_SECTION) - NEXT_SECTION + propertyLine, 0)

    ArrayGetString(Rifle_InfoText, fieldLineNumber, parseLine, charsmax(parseLine))
    strtok(parseLine, field, charsmax(field), value, charsmax(value), '=')
    trim(value)

    syntaxLine = fieldLineNumber + 1

    return value
}

bool:CheckConfigSyntax( & exceptionLine) {
    new buffer[128]

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "administrator", exceptionLine))
        if (!equali(buffer, "0") && !equali(buffer, "1")) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "cost", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "wpn_id", exceptionLine))
        new wpnId = str_to_num(buffer[0])

        if (wpnId < CSW_SCOUT ||
            wpnId > CSW_P90 ||
            wpnId == CSW_KNIFE ||
            wpnId == CSW_ELITE ||
            wpnId == CSW_FIVESEVEN ||
            wpnId == CSW_USP ||
            wpnId == CSW_GLOCK18 ||
            wpnId == CSW_DEAGLE ||
            wpnId == CSW_HEGRENADE ||
            wpnId == CSW_SMOKEGRENADE ||
            wpnId == CSW_FLASHBANG) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "clip", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "ammo", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "damage", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "recoil", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "deploy", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "reload", exceptionLine))
        if (!equali(buffer, "0") && !equali(buffer, "1")) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "speed", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "knockback", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "fastrun", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "secondary_type", exceptionLine))
        if (!equali(buffer, "0") &&
            !equali(buffer, "1") &&
            !equali(buffer, "2") &&
            !equali(buffer, "3")) {
            return false
        } else if (equali(buffer, "3")) {
            formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sight_recoil", exceptionLine))
            if (!isdigit(buffer[0])) {
                return false
            }

            formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sight_model", exceptionLine))
            if (contain(buffer, ".mdl") == -1) {
                return false
            }
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "tracer_type", exceptionLine))
        if (!equali(buffer, "0") &&
            !equali(buffer, "1") &&
            !equali(buffer, "2") &&
            !equali(buffer, "3")) {
            return false
        } else if (!equali(buffer, "0")) {
            formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "tracer", exceptionLine))

            new r_color[64], g_color[64], b_color[64], width[64], right[64]
            strtok(buffer, r_color, 64, right, 64, ',')
            strtok(right, g_color, 64, right, 64, ',')
            strtok(right, b_color, 64, width, 64, ',')

            if (!equali(buffer[0], "0") &&
                (!strlen(r_color) || !strlen(g_color) || !strlen(width)) &&
                (!isdigit(r_color[0]) || !isdigit(g_color[0]) || !isdigit(b_color[0]) || !isdigit(width[0]))) {
                return false
            }

            formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "tracer_sprite", exceptionLine))
            if (contain(buffer, ".spr") == -1) {
                return false
            }
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "v_model", exceptionLine))
        if (contain(buffer, ".mdl") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "p_model", exceptionLine))
        if (contain(buffer, ".mdl") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "w_model", exceptionLine))
        if (contain(buffer, ".mdl") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "fire_sounds", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "buycvar", exceptionLine))
        if (!strlen(buffer) && (!equali(buffer, " ") || !equali(buffer, ""))) {
            return false
        }
    }

    exceptionLine = 0
    return true
}

DropPrimary(client) {
    new dropweapon[64]
    for (new i = 0; i < sizeof(primaryWeaponsId); i++) {
        get_weaponname(primaryWeaponsId[i], dropweapon, sizeof dropweapon - 1)
        engclient_cmd(client, "drop", dropweapon)
    }
}

GetWeaponEnt(client, wpnId = 0) {
    new className[64]
    get_weaponname(wpnId, className, charsmax(className))

    return fm_find_ent_by_owner(get_maxplayers(), className, client)
}

bool:HasUserPrimary(client) {
    return (get_pdata_cbase(client, m_rgpPlayerItems_Slot1, 5) > 0)
}

SetWeaponTime(client, Float: TimeIdle) {
    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))

    if (!is_user_alive(client)) {
        return
    }

    static entity
    entity = fm_get_user_weapon_entity(client, CHANGE_WEAPON)

    if (!pev_valid(entity)) {
        return
    }

    set_pdata_float(entity, m_flNextPrimaryAttack, TimeIdle, 4)
    set_pdata_float(entity, m_flNextSecondaryAttack, TimeIdle, 4)
    set_pdata_float(entity, m_flTimeWeaponIdle, TimeIdle + 1.0, 4)
}

SetWeaponNextAttack(client, Float: nexttime) {
    set_pdata_float(client, m_flNextAttack, nexttime, 5)
}

SetWeaponAnim(const player, const sequence) {
    set_pev(player, pev_weaponanim, sequence)
    message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = player)
    write_byte(sequence)
    write_byte(pev(player, pev_body))
    message_end()
}

GetCustomPrimarySound(weapon) {
    new sound[256]
    new sound1[64], sound2[64]

    formatex(sound, charsmax(sound), "%s", ParseConfig(weapon, "fire_sounds"))
    strtok(sound, sound1, charsmax(sound1), sound2, charsmax(sound2), '*')
    trim(sound1)
    trim(sound2)

    if (contain(sound2, ".wav") == -1) {
        format(sound, charsmax(sound), "weapons/%s", sound)
    } else {
        format(sound1, charsmax(sound1), "weapons/%s", sound1)
        format(sound2, charsmax(sound2), "weapons/%s", sound2)
        sound = random_num(0, 1) == 0 ? sound1 : sound2
    }

    return sound
}

CreateVelocityVector(victim, attacker, Float: velocity[3], Float: knockback) {
    new Float: victim_origin[3], Float: attacker_origin[3], Float: new_origin[3]

    entity_get_vector(victim, EV_VEC_origin, victim_origin)
    entity_get_vector(attacker, EV_VEC_origin, attacker_origin)

    new_origin[0] = victim_origin[0] - attacker_origin[0]
    new_origin[1] = victim_origin[1] - attacker_origin[1]

    velocity[0] = (new_origin[0] * (knockback * 900)) / get_entity_distance(victim, attacker)
    velocity[1] = (new_origin[1] * (knockback * 900)) / get_entity_distance(victim, attacker)
}

GetFireAnimation(wpnId, mode) {
    switch (wpnId) {
        case CSW_P228:
            return random_num(1, 3)
        case CSW_SCOUT:
            return random_num(1, 2)
        case CSW_XM1014:
            return random_num(1, 2)
        case CSW_MAC10:
            return random_num(3, 5)
        case CSW_AUG:
            return random_num(3, 5)
        case CSW_ELITE:
            return random_num(2, 6) || random_num(8, 12)
        case CSW_FIVESEVEN:
            return random_num(1, 2)
        case CSW_UMP45:
            return random_num(3, 5)
        case CSW_SG550:
            return random_num(1, 2)
        case CSW_GALIL:
            return random_num(3, 5)
        case CSW_FAMAS:
            return random_num(3, 5)
        case CSW_USP:
            return mode ? random_num(1, 3) : random_num(9, 11) //CHECK THIS OUT
        case CSW_GLOCK18:
            return random_num(3, 5)
        case CSW_AWP:
            return random_num(1, 3)
        case CSW_MP5NAVY:
            return random_num(3, 5)
        case CSW_M249:
            return random_num(1, 2)
        case CSW_M4A1:
            return mode ? random_num(1, 3) : random_num(8, 10) //CHECK THIS OUT
        case CSW_TMP:
            return random_num(3, 5)
        case CSW_G3SG1:
            return random_num(1, 2)
        case CSW_DEAGLE:
            return random_num(1, 2)
        case CSW_SG552:
            return random_num(3, 5)
        case CSW_AK47:
            return random_num(3, 5)
        case CSW_P90:
            return random_num(3, 5)
    }

    return 0
}

ShowHud_Ammo(client, ammo) {
    new wpnId = get_user_weapon(client)
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoPickup"), _, client)
    write_byte(weaponsAmmoId[wpnId])
    write_byte(ammo)
    message_end()
}

Remove_WeaponsBox() {
    new entity
    for (new i = 1; i < sizeof(class_weapons); i++) {
        while ((entity = find_ent_by_class(entity, class_weapons[i]))) {
            set_pev(entity, pev_nextthink, get_gametime())
        }
    }
}

Buy_Weapon(client, wpnId) {
    if (IsConfigBroken) {
        return
    }

    new buyzone = cs_get_user_buyzone(client)

    if ((get_cvar_num("nst_use_buyzone") ? buyzone : 1) == 0) {
        client_print(client, print_chat, "[NST Wpn] %L", LANG_PLAYER, "CANT_BUY_WEAPON")
    } else {
        new user_money = cs_get_user_money(client)
        new wp_cost = cvar_cost[wpnId]
        new clipMax = cvar_clip[wpnId]
        new ammoMax = cvar_ammo[wpnId]
        new administrator = cvar_administrator[wpnId]

        if (!(get_user_flags(client) & ADMIN_KICK) && administrator == 1) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ACCESS_DENIED_BUY")
        } else if (!is_user_alive(client)) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "NOT_LIVE")
        } else if (get_gametime() - gameTime > get_cvar_num("nst_buy_time")) {
            engclient_print(client, engprint_center, "%L", LANG_PLAYER, "BUY_TIME_END", get_cvar_num("nst_buy_time"))
        } else if (HAS_WEAPON[client] == wpnId) {
            new buffer[256]
            ArrayGetString(Rifle_Names, HAS_WEAPON[client], buffer, charsmax(buffer))

            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ALREADY_HAVE", buffer)
        } else if (get_cvar_num("nst_free") ? true : (wp_cost <= cs_get_user_money(client))) {
            DropPrimary(client)
            CURRENT_WEAPON[client] = wpnId
            HAS_WEAPON[client] = wpnId
            Give_Weapon(client, clipMax, ammoMax)
            ShowHud_Ammo(client, ammoMax)

            if (get_cvar_num("nst_free") == 0) {
                cs_set_user_money(client, user_money + -wp_cost)
            }
        } else {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "INSUFFICIENT_MONEY")
        }
    }
}

public NST_Shotguns(client) {
    if (IsConfigBroken || IsInCommencing) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(client)) {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
        return PLUGIN_HANDLED
    }

    new menu[512], menuxx
    new text[256], len = 0

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        new administrator = str_to_num(ParseConfig(i, "administrator"))
        new wpnId = str_to_num(ParseConfig(i, "wpn_id"))

        new title[64]
        ArrayGetString(Rifle_Names, i, title, charsmax(title))

        if (wpnId == 5 || wpnId == 21) {
            new menuKey[64]
            formatex(menu, charsmax(menu), administrator == 0 ? "%s 	\r$%s" : "\y%s 	\r$%s", title, ParseConfig(i, "cost"))
            num_to_str(i + 1, menuKey, 999)
            menu_additem(menuxx, menu, menuKey)
        }
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT")
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK")
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    menu_display(client, menuxx, 0)

    return PLUGIN_HANDLED
}

public NST_Submachine(client) {
    if (IsConfigBroken || IsInCommencing) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(client)) {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
        return PLUGIN_HANDLED
    }

    new menu[512], menuxx
    new text[256], len = 0

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        new administrator = str_to_num(ParseConfig(i, "administrator"))
        new wpnId = str_to_num(ParseConfig(i, "wpn_id"))

        new title[64]
        ArrayGetString(Rifle_Names, i, title, charsmax(title))

        if (wpnId == 7 || wpnId == 12 || wpnId == 19 || wpnId == 23 || wpnId == 30) {
            new menuKey[64]
            formatex(menu, charsmax(menu), administrator == 0 ? "%s 	\r$%s" : "\y%s 	\r$%s", title, ParseConfig(i, "cost"))
            num_to_str(i + 1, menuKey, 999)
            menu_additem(menuxx, menu, menuKey)
        }
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT")
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK")
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    menu_display(client, menuxx, 0)

    return PLUGIN_HANDLED
}

public NST_Rifles(client) {
    if (IsConfigBroken || IsInCommencing) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(client)) {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
        return PLUGIN_HANDLED
    }

    new menu[512], menuxx
    new text[256], len = 0

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        new administrator = str_to_num(ParseConfig(i, "administrator"))
        new wpnId = str_to_num(ParseConfig(i, "wpn_id"))

        new title[64]
        ArrayGetString(Rifle_Names, i, title, charsmax(title))

        if (wpnId == 8 || wpnId == 14 || wpnId == 15 || wpnId == 22 || wpnId == 27 || wpnId == 28) {
            new menuKey[64]
            formatex(menu, charsmax(menu), administrator == 0 ? "%s 	\r$%s" : "\y%s 	\r$%s", title, ParseConfig(i, "cost"))
            num_to_str(i + 1, menuKey, 999)
            menu_additem(menuxx, menu, menuKey)
        }
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT")
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK")
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    menu_display(client, menuxx, 0)

    return PLUGIN_HANDLED
}

public NST_Snipers(client) {
    if (IsConfigBroken || IsInCommencing) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(client)) {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
        return PLUGIN_HANDLED
    }

    new menu[512], menuxx
    new text[256], len = 0

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        new administrator = str_to_num(ParseConfig(i, "administrator"))
        new wpnId = str_to_num(ParseConfig(i, "wpn_id"))

        new title[64]
        ArrayGetString(Rifle_Names, i, title, charsmax(title))

        if (wpnId == 3 || wpnId == 13 || wpnId == 18 || wpnId == 24) {
            new menuKey[64]
            formatex(menu, charsmax(menu), administrator == 0 ? "%s 	\r$%s" : "\y%s 	\r$%s", title, ParseConfig(i, "cost"))
            num_to_str(i + 1, menuKey, 999)
            menu_additem(menuxx, menu, menuKey)
        }
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT")
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK")
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    menu_display(client, menuxx, 0)

    return PLUGIN_HANDLED
}

public NST_Machine(client) {
    if (IsConfigBroken || IsInCommencing) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(client)) {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
        return PLUGIN_HANDLED
    }

    new menu[512], menuxx
    new text[256], len = 0

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        new administrator = str_to_num(ParseConfig(i, "administrator"))
        new wpnId = str_to_num(ParseConfig(i, "wpn_id"))

        new title[64]
        ArrayGetString(Rifle_Names, i, title, charsmax(title))

        if (wpnId == 20) {
            new menuKey[64]
            formatex(menu, charsmax(menu), administrator == 0 ? "%s 	\r$%s" : "\y%s 	\r$%s", title, ParseConfig(i, "cost"))
            num_to_str(i + 1, menuKey, 999)
            menu_additem(menuxx, menu, menuKey)
        }
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT")
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK")
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    menu_display(client, menuxx, 0)

    return PLUGIN_HANDLED
}

public Get_NSTWeapon(client, menu, item) {
    new access, callback, data[6], name[64]
    menu_item_getinfo(menu, item, access, data, 5, name, 63, callback)
    new key = str_to_num(data)

    if (key != 0) {
        Buy_Weapon(client, key - 1)
    }
}

public NST_Buy_Convar(client) {
    new msg[64]
    if (read_argc() != 2) {
        formatex(msg, charsmax(msg), "[NST Wpn] %L", LANG_PLAYER, "BUY_COMMAND_USAGE", "nst_rifle_buy")
        client_print(client, print_console, msg)
        return PLUGIN_HANDLED
    }

    new arg[64]
    read_argv(1, arg, 63)
    strtolower(arg)

    for (new i = 1; i < sizeof cvar_buycvar; i++) {
        new buffer[128]
        formatex(buffer, charsmax(buffer), "%s", cvar_buycvar[i])
        if (equali(buffer, arg) && (!equali(buffer, "NULL") && !equali(buffer, " "))) {
            Buy_Weapon(client, i)
            break
        }
    }

    return PLUGIN_HANDLED
}

public ReBuy_Weapon(client) {
    if (IsConfigBroken) {
        return PLUGIN_HANDLED
    }

    new wpnId = CURRENT_WEAPON[client]
    if (wpnId > 0) {
        Buy_Weapon(client, wpnId)
    }

    return PLUGIN_HANDLED
}

public Cmd_BuyAmmo1(client) {
    new wpnId, ammoCurr, defaultMaxAmmo

    wpnId = get_user_weapon(client, _, ammoCurr)
    defaultMaxAmmo = weaponsMaxBpAmmo[wpnId]

    if (!wpnId || !HasUserPrimary(client)) {
        return PLUGIN_CONTINUE
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new buyzone = cs_get_user_buyzone(client)

    if ((IsConfigBroken || !CURRENT_WEAPON) &&
        weaponsAmmoCost[wpnId] < cs_get_user_money(client) &&
        ammoCurr < defaultMaxAmmo &&
        buyzone) {

        cs_set_user_money(client, cs_get_user_money(client) + -weaponsAmmoCost[wpnId])
        cs_set_user_bpammo(client, wpnId, ammoCurr + weaponsAmmo[wpnId])

        if (cs_get_user_bpammo(client, wpnId) > defaultMaxAmmo) {
            cs_set_user_bpammo(client, wpnId, defaultMaxAmmo)
            ShowHud_Ammo(client, defaultMaxAmmo - ammoCurr)
        } else {
            ShowHud_Ammo(client, weaponsAmmo[wpnId])
        }

        client_cmd(0, "spk sound/items/9mmclip1.wav")
        return PLUGIN_HANDLED
    }

    if (get_cvar_num("nst_use_buyzone") ? buyzone : 1) {
        new custom_ammo_max = cvar_ammo[CURRENT_WEAPON]

        if (weaponsAmmoCost[wpnId] < cs_get_user_money(client) && ammoCurr < custom_ammo_max) {
            cs_set_user_money(client, cs_get_user_money(client) + -weaponsAmmoCost[wpnId])
            cs_set_user_bpammo(client, wpnId, ammoCurr + weaponsAmmo[wpnId])

            if (cs_get_user_bpammo(client, wpnId) > custom_ammo_max) {
                cs_set_user_bpammo(client, wpnId, custom_ammo_max)
                ShowHud_Ammo(client, custom_ammo_max - ammoCurr)
            } else {
                ShowHud_Ammo(client, weaponsAmmo[wpnId])
            }

            client_cmd(0, "spk sound/items/9mmclip1.wav")
        }
    }

    return PLUGIN_HANDLED
}

public Give_Weapon(client, clip, ammo) {
    if (IsConfigBroken) {
        return PLUGIN_CONTINUE
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))

    static weapon_name[32]
    get_weaponname(CHANGE_WEAPON, weapon_name, charsmax(weapon_name))

    give_item(client, weapon_name)
    cs_set_user_bpammo(client, CHANGE_WEAPON, ammo)

    new entity = GetWeaponEnt(client, CHANGE_WEAPON)
    if (!is_valid_ent(entity)) {
        return PLUGIN_CONTINUE
    }

    cs_set_weapon_ammo(entity, clip)
    return PLUGIN_HANDLED
}

public Primary_Attack(entity) {
    new client = pev(entity, pev_owner)
    pev(client, pev_punchangle, PUSHANGLE[client])

    return HAM_HANDLED
}

public Primary_Attack_Post(entity) {
    if (IsConfigBroken || !is_valid_ent(entity)) {
        return HAM_IGNORED
    }

    static client
    client = pev(entity, pev_owner)

    new clipCurr, ammoCurr

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(client, clipCurr, ammoCurr)

    if (wpnId != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    set_pdata_float(entity, m_flNextPrimaryAttack, get_pdata_float(entity, 46, 4) * cvar_speed[CURRENT_WEAPON], 4)

    new Float: push[3]
    pev(client, pev_punchangle, push)
    xs_vec_sub(push, PUSHANGLE[client], push)

    xs_vec_mul_scalar(push, IS_INIRONSIGHT[client] ? cvar_sightrecoil[CURRENT_WEAPON] : cvar_recoil[CURRENT_WEAPON], push)
    xs_vec_add(push, PUSHANGLE[client], push)
    set_pev(client, pev_punchangle, push)

    if (cvar_reload[CURRENT_WEAPON] == 0 &&
        !IS_INRELOAD[client] &&
        ammoCurr != 0 &&
        clipCurr != 0) {
        cs_set_user_bpammo(client, wpnId, ammoCurr - 1)
        cs_set_weapon_ammo(entity, SAVED_CLIP[client])
    }

    return HAM_HANDLED
}

public Rifles_PostFrame_Pre(entity) {
    if (IsConfigBroken) {
        return HAM_IGNORED
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new user_wpnid = get_user_weapon(client)

    if (user_wpnid != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    static btnInfo, inReload, clipCurr, clipMax, ammoCurr, ammoType, Float:nextAttack
    btnInfo = pev(client, pev_button)
    inReload = get_pdata_int(entity, m_fInReload, 4)
    clipCurr = get_pdata_int(entity, m_iClip, 4)
    clipMax = cvar_clip[CURRENT_WEAPON]

    ammoType = m_rgPlayerAmmo_Slot0 + get_pdata_int(entity, m_iPrimaryAmmoType, 4)
    ammoCurr = get_pdata_int(client, ammoType, 5)
    nextAttack = get_pdata_float(client, m_flNextAttack, 5)

    if (inReload && nextAttack <= 0.0) {
        new j = min(clipMax - clipCurr, ammoCurr)
        set_pdata_int(entity, m_iClip, clipCurr + j, 4)
        set_pdata_int(client, ammoType, ammoCurr - j, 5)
        set_pdata_int(entity, m_fInReload, 0, 4)
    }

    //SECONDARY ATTACK
    IS_INRELOAD[client] = (btnInfo & IN_RELOAD && !inReload)
    if (cvar_secondary_type[CURRENT_WEAPON] != 0) {
        set_pev(client, pev_button, btnInfo & ~IN_ATTACK2)
    }

    return HAM_HANDLED
}

public Shotguns_PostFrame_Pre(entity) {
    if (IsConfigBroken) {
        return HAM_IGNORED
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new user_wpnid = get_user_weapon(client)

    if (user_wpnid != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    static btnInfo, inSpecialReload, clipCurr, clipMax, ammoCurr, ammoType
    btnInfo = pev(client, pev_button)
    inSpecialReload = get_pdata_int(entity, m_fInSpecialReload, 4)
    clipCurr = get_pdata_int(entity, m_iClip, 4)
    clipMax = cvar_clip[CURRENT_WEAPON]
    ammoType = m_rgPlayerAmmo_Slot0 + get_pdata_int(entity, m_iPrimaryAmmoType, 4)
    ammoCurr = get_pdata_int(client, ammoType, 5)

    if (inSpecialReload && clipCurr >= clipMax) //FULL CLIP DON'T STOP FIX
    {
        set_pev(client, pev_button, btnInfo & ~IN_RELOAD)
        set_pev(entity, m_fInSpecialReload, 0, 4)
        set_pdata_float(entity, m_flTimeWeaponIdle, get_pdata_float(entity, m_flTimeWeaponIdle, 4) + 1.0, 4)
        set_pev(client, pev_weaponanim, 4)
    }

    if (clipCurr == weaponsMaxAmmo[user_wpnid] && ((btnInfo & IN_RELOAD) || inSpecialReload)) //DEFAULT MAX CLIP RELOAD STOP FIX 
    {
        set_pev(client, pev_button, btnInfo & IN_RELOAD)
        set_pev(client, pev_weaponanim, 3)

        set_pdata_int(entity, m_iClip, clipCurr + 1, 4)
        set_pdata_int(client, ammoType, ammoCurr - 1, 5)
        set_pdata_int(entity, m_fInSpecialReload, 1, 4)
    }

    return HAM_HANDLED
}

public Rifles_Reload_Post(entity) {
    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new user_wpnid = get_user_weapon(client)

    if (user_wpnid != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    static clipCurr, clipMax, btnInfo, ammoCurr, ammoType, inReload
    clipCurr = get_pdata_int(entity, m_iClip, 4)
    clipMax = cvar_clip[CURRENT_WEAPON]
    inReload = get_pdata_int(entity, m_fInReload, 4)
    btnInfo = pev(client, pev_button)
    ammoType = m_rgPlayerAmmo_Slot0 + get_pdata_int(entity, m_iPrimaryAmmoType, 4)
    ammoCurr = get_pdata_int(client, ammoType, 5)

    if (inReload) {
        if (clipCurr >= clipMax) {
            set_pdata_float(client, m_flNextAttack, 0.0, 5)
            set_pev(client, pev_button, btnInfo & ~IN_RELOAD)

            //STOP RELOAD ANIMATION
            switch (user_wpnid) {
                case CSW_MP5NAVY, CSW_MAC10, CSW_TMP, CSW_P90, CSW_UMP45, CSW_GALIL, CSW_FAMAS, CSW_AK47, CSW_SG552, CSW_AUG:  {
                    SetWeaponAnim(client, 0)
                }
                case CSW_M4A1:  {
                    SetWeaponAnim(client, cs_get_weapon_silen(entity) ? 0 : 7)
                }
                case CSW_G3SG1, CSW_SG550, CSW_SCOUT, CSW_M249:  {
                    SetWeaponAnim(client, 0)
                }
            }
        } else if (clipCurr == weaponsMaxAmmo[user_wpnid] && ammoCurr) {
            set_pdata_float(client, m_flNextAttack, weaponsReloadDelay[user_wpnid], 5)
            set_pdata_int(entity, m_fInReload, 1, 4)

            //START RELOAD ANIMATION
            switch (user_wpnid) {
                case CSW_MP5NAVY, CSW_MAC10, CSW_TMP, CSW_P90, CSW_UMP45, CSW_GALIL, CSW_FAMAS, CSW_AK47, CSW_SG552, CSW_AUG:  {
                    SetWeaponAnim(client, 1)
                }
                case CSW_M4A1:  {
                    SetWeaponAnim(client, (get_pdata_int(entity, m_fWeaponState, 4) & (1 << 2)) ? 4 : 11)
                }
                case CSW_G3SG1, CSW_SG550, CSW_SCOUT, CSW_M249:  {
                    SetWeaponAnim(client, 3)
                }
            }
        }
    }

    return HAM_HANDLED
}

public Weapon_Deploy_Post(entity) {
    if (IsConfigBroken) {
        return HAM_IGNORED
    }

    if (!pev_valid(entity)) {
        return HAM_IGNORED
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    if (!is_user_alive(client)) {
        return HAM_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(client)

    if (wpnId != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    SetWeaponTime(client, cvar_deploy[CURRENT_WEAPON])
    SetWeaponNextAttack(client, cvar_deploy[CURRENT_WEAPON])

    return HAM_HANDLED
}

public Event_CurrentWeapon(client) {
    if (IsConfigBroken) {
        return PLUGIN_CONTINUE
    }

    new clipCurr, ammoCurr

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new user_wpnid = get_user_weapon(client, clipCurr, ammoCurr)

    if (user_wpnid != CHANGE_WEAPON || !CURRENT_WEAPON) {
        IS_INIRONSIGHT[client] = 0
        SAVED_CLIP[client] = 0
        return PLUGIN_CONTINUE
    }

    entity_set_float(client, EV_FL_maxspeed, 240.0 + cvar_fastrun[CURRENT_WEAPON])

    new v_model[64], p_model[64], sight_model[64]
    formatex(v_model, charsmax(v_model), "models/%s", ParseConfig(CURRENT_WEAPON, "v_model"))
    formatex(p_model, charsmax(p_model), "models/%s", ParseConfig(CURRENT_WEAPON, "p_model"))
    formatex(sight_model, charsmax(sight_model), "models/%s", ParseConfig(CURRENT_WEAPON, "sight_model"))

    set_pev(client, pev_viewmodel2, IS_INIRONSIGHT[client] ? sight_model : v_model)
    set_pev(client, pev_weaponmodel2, p_model)

    new weaponEntity = GetWeaponEnt(client, CHANGE_WEAPON)

    if (!is_valid_ent(weaponEntity)) {
        return PLUGIN_HANDLED
    }

    if (cvar_secondary_type[CURRENT_WEAPON]) {
        message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Crosshair"), _, client)
        write_byte(0)
        message_end()
    }

    if (!SAVED_CLIP[client] || ammoCurr == 0) {
        SAVED_CLIP[client] = clipCurr
    }

    return PLUGIN_HANDLED
}

public Ham_PlayerTouchWeaponBox(entity, client) {
    if (IsConfigBroken ||
        !is_valid_ent(entity) ||
        get_entity_flags(entity) != FL_ONGROUND ||
        !is_user_alive(client) ||
        HasUserPrimary(client)) {
        return HAM_IGNORED
    }

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        if (str_to_num(ParseConfig(i, "wpn_id")) <= 0) {
            break
        }

        new class_name[64]
        entity_get_string(entity, EV_SZ_classname, class_name, charsmax(class_name))

        if (equal(class_name, class_weapons[i]) && (client > 0 && client < MAX_PLAYER)) {
            HAS_WEAPON[client] = i
            break
        }
    }

    return HAM_HANDLED
}

public Ham_TraceAttack_Post(entity, attacker, Float: flDamage, Float: fDir[3], ptr, iDamageType) {
    if (IsConfigBroken || !is_user_alive(attacker)) {
        return HAM_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(attacker)

    if (wpnId != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    //For create default bullet trace
    static Float: flEnd[3], Float: vecPlane[3]
    get_tr2(ptr, TR_vecEndPos, flEnd)
    get_tr2(ptr, TR_vecPlaneNormal, vecPlane)

    static LoopTime, Decal
    Decal = random_num(41, 45)
    LoopTime = flDamage > 100.0 ? 2 : 1

    for (new i = 0; i < LoopTime; i++) {
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_WORLDDECAL)
        engfunc(EngFunc_WriteCoord, flEnd[0])
        engfunc(EngFunc_WriteCoord, flEnd[1])
        engfunc(EngFunc_WriteCoord, flEnd[2])
        write_byte(Decal)
        message_end()

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_GUNSHOTDECAL)
        engfunc(EngFunc_WriteCoord, flEnd[0])
        engfunc(EngFunc_WriteCoord, flEnd[1])
        engfunc(EngFunc_WriteCoord, flEnd[2])
        write_short(attacker)
        write_byte(Decal)
        message_end()
    }

    if (cvar_tracer_type[CURRENT_WEAPON] == 0) {
        return HAM_HANDLED
    }

    new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

    new field[64], field2[64], field3[64], field4[64], buffer[64]
    strtok(cvar_tracer[CURRENT_WEAPON], field, charsmax(field), buffer, charsmax(buffer), ',')
    strtok(buffer, field2, charsmax(field2), buffer, charsmax(buffer), ',')
    strtok(buffer, field3, charsmax(field3), field4, charsmax(field4), ',')

    new r_color = str_to_num(field)
    new g_color = str_to_num(field2)
    new b_color = str_to_num(field3)
    new thickness = str_to_num(field4)

    if (cvar_tracer_type[CURRENT_WEAPON] == 1) {
        static vec1[3], vec2[3]

        get_user_origin(attacker, vec1, 4)
        get_user_origin(attacker, vec2, 1)

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(0)
        write_coord(vec1[0])
        write_coord(vec1[1])
        write_coord(vec1[2])
        write_coord(vec2[0])
        write_coord(vec2[1])
        write_coord(vec2[2])
        write_short(cvar_tracer_sprite[CURRENT_WEAPON])
        write_byte(1)
        write_byte(5)
        write_byte(2)
        write_byte(thickness)
        write_byte(0)
        write_byte(r_color)
        write_byte(g_color)
        write_byte(b_color)
        write_byte(200)
        write_byte(0)
        message_end()
    } else if (cvar_tracer_type[CURRENT_WEAPON] == 2) {
        if (entity) {
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(entity ? TE_DECAL : TE_WORLDDECAL)
            engfunc(EngFunc_WriteCoord, flEnd[0])
            engfunc(EngFunc_WriteCoord, flEnd[1])
            engfunc(EngFunc_WriteCoord, flEnd[2])
            write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS - 1)])
            write_short(entity)
            message_end()
        } else {
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_WORLDDECAL)
            engfunc(EngFunc_WriteCoord, flEnd[0])
            engfunc(EngFunc_WriteCoord, flEnd[1])
            engfunc(EngFunc_WriteCoord, flEnd[2])
            write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS - 1)])
            message_end()
        }

        message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
        write_byte(TE_BEAMENTPOINT)
        write_short(attacker | 0x1000)
        engfunc(EngFunc_WriteCoord, flEnd[0])
        engfunc(EngFunc_WriteCoord, flEnd[1])
        engfunc(EngFunc_WriteCoord, flEnd[2])
        write_short(cvar_tracer_sprite[CURRENT_WEAPON])
        write_byte(1)
        write_byte(5)
        write_byte(2)
        write_byte(thickness)
        write_byte(0)
        write_byte(r_color)
        write_byte(g_color)
        write_byte(b_color)
        write_byte(255)
        write_byte(0)
        message_end()
    } else if (cvar_tracer_type[CURRENT_WEAPON] == 3) {
        if (entity) {
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_DECAL)
            engfunc(EngFunc_WriteCoord, flEnd[0])
            engfunc(EngFunc_WriteCoord, flEnd[1])
            engfunc(EngFunc_WriteCoord, flEnd[2])
            write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS - 1)])
            write_short(entity)
            message_end()
        } else {
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_SPRITE)
            engfunc(EngFunc_WriteCoord, flEnd[0] + 10)
            engfunc(EngFunc_WriteCoord, flEnd[1] + 10)
            engfunc(EngFunc_WriteCoord, flEnd[2] + 10)
            write_short(cvar_tracer_sprite[CURRENT_WEAPON])
            write_byte(thickness)
            write_byte(200)
            message_end()
        }
    }

    return HAM_HANDLED
}

public Ham_TakeDamage_Pre(victim, inflictor, attacker, Float: damage) {
    if (IsConfigBroken || !is_user_alive(attacker)) {
        return HAM_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(attacker)

    if (wpnId != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    SetHamParamFloat(4, damage * cvar_dmgmultiplier[CURRENT_WEAPON])
    return HAM_HANDLED
}

public Ham_BotSpawn_Post(client) {
    if (IsConfigBroken ||
        !get_cvar_num("nst_give_bot") ||
        !is_user_alive(client)) {
        return HAM_IGNORED
    }

    set_task(random_float(1.0, 4.0), "Task_BotWeapons", client)
    return HAM_HANDLED
}

public fw_WorldModel(entity, model[]) {
    if (IsConfigBroken || !is_valid_ent(entity)) {
        return FMRES_IGNORED
    }

    static client
    client = pev(entity, pev_owner)

    new CURRENT_WEAPON = HAS_WEAPON[client]

    if (!CURRENT_WEAPON) {
        return FMRES_IGNORED
    }

    new class_name[64], w_model[64]
    pev(entity, pev_classname, class_name, sizeof(class_name))

    if (!equal(class_name, "weaponbox")) {
        return FMRES_IGNORED
    }

    for (new i = 0; i < sizeof(primaryWeaponsWorld); i++) {
        if (equal(model, primaryWeaponsWorld[i]) && CURRENT_WEAPON) {
            entity_set_string(entity, EV_SZ_classname, class_weapons[CURRENT_WEAPON])

            formatex(w_model, charsmax(w_model), "models/%s", ParseConfig(CURRENT_WEAPON, "w_model"))
            engfunc(EngFunc_SetModel, entity, w_model)
            HAS_WEAPON[client] = 0

            return FMRES_SUPERCEDE
        }
    }

    return FMRES_HANDLED
}

public fw_CmdStart(client, uc_handle, seed) {
    if (IsConfigBroken || !is_user_alive(client)) {
        return FMRES_IGNORED
    }

    new clipCurr

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(client, clipCurr)

    if (wpnId != CHANGE_WEAPON || !CURRENT_WEAPON) {
        IS_INIRONSIGHT[client] = 0
        return FMRES_IGNORED
    }

    if (!cvar_secondary_type[CURRENT_WEAPON]) {
        IS_INIRONSIGHT[client] = 0
        return FMRES_IGNORED
    }

    static currentBtn, oldButton
    currentBtn = get_uc(uc_handle, UC_Buttons)
    oldButton = pev(client, pev_oldbuttons)

    if ((currentBtn & IN_RELOAD) || clipCurr == 0) {
        cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
        IS_INIRONSIGHT[client] = 0
    } else if ((currentBtn & IN_ATTACK2) && !(oldButton & IN_ATTACK2) && !IS_INRELOAD[client]) {
        client_cmd(0, "spk weapons/zoom.wav")

        switch (cvar_secondary_type[CURRENT_WEAPON]) {
            case 1 :  {
                SetWeaponTime(client, 0.3)
                set_pdata_float(client, m_flNextAttack, 0.3, 5)
                SetWeaponNextAttack(client, 0.66)
                cs_set_user_zoom(client, cs_get_user_zoom(client) == 1 ? CS_SET_AUGSG552_ZOOM : CS_SET_NO_ZOOM, 1)
            }
            case 2 :  {
                SetWeaponTime(client, 0.3)
                set_pdata_float(client, m_flNextAttack, 0.3, 5)
                SetWeaponNextAttack(client, 0.66)
                cs_set_user_zoom(client, cs_get_user_zoom(client) == 1 ? CS_SET_FIRST_ZOOM : CS_SET_NO_ZOOM, 1)
            }
            case 3 :  {
                SetWeaponTime(client, 0.3)
                set_pdata_float(client, m_flNextAttack, 0.3, 5)
                SetWeaponNextAttack(client, 0.66)
                cs_set_user_zoom(client, cs_get_user_zoom(client) == 1 ? CS_SET_AUGSG552_ZOOM : CS_SET_NO_ZOOM, 1)
                IS_INIRONSIGHT[client] = IS_INIRONSIGHT[client] ? 0 : 1
            }
        }
    }

    return FMRES_HANDLED
}

public fw_UpdateClientData_Post(client, sendweapons, cd_handle) {
    if (IsConfigBroken || !is_user_connected(client)) {
        return FMRES_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(client)

    if (wpnId != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return FMRES_IGNORED
    }

    set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001)
    return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float: delay, Float: origin[3], Float: angles[3], Float: fparam1, Float: fparam2, iParam1, iParam2, bParam1, bParam2) {
    if (IsConfigBroken || !is_user_connected(invoker)) {
        return FMRES_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[invoker]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(invoker)

    if (wpnId != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return FMRES_IGNORED
    }

    static m4entity
    m4entity = fm_find_ent_by_owner(-1, "weapon_m4a1", invoker)

    engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
    emit_sound(invoker, CHAN_WEAPON, GetCustomPrimarySound(HAS_WEAPON[invoker]), VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    SetWeaponAnim(invoker, GetFireAnimation(wpnId, is_valid_ent(m4entity) ? cs_get_weapon_silen(m4entity) : 0))

    return FMRES_SUPERCEDE
}

public client_connect(client) {
    HAS_WEAPON[client] = 0
}

public client_disconnect(client) {
    HAS_WEAPON[client] = 0
}

public Event_Commencing() {
    IsInCommencing = true

    return PLUGIN_CONTINUE
}

public Event_NewRound() {
    if (IsConfigBroken) {
        return PLUGIN_CONTINUE
    }

    gameTime = get_gametime()

    if (IsInCommencing) {
        new players[MAX_PLAYER], playersCount
        get_players(players, playersCount)

        for (new i = 0; i < playersCount; i++) {
            CURRENT_WEAPON[i] = 0
            HAS_WEAPON[i] = 0
        }
        IsInCommencing = false
    }

    Remove_WeaponsBox()
    return PLUGIN_HANDLED
}

public Event_Damage(client) {
    if (IsConfigBroken || !is_valid_ent(client)) {
        return PLUGIN_CONTINUE
    }

    new weapon
    new attacker = get_user_attacker(client, weapon)

    if (!is_user_alive(attacker)) {
        return PLUGIN_CONTINUE
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))

    if (weapon != CHANGE_WEAPON || !CURRENT_WEAPON) {
        return PLUGIN_CONTINUE
    }

    new Float: vector[3]
    new Float: old_velocity[3]
    get_user_velocity(client, old_velocity)
    CreateVelocityVector(client, attacker, vector, cvar_knockback[CURRENT_WEAPON])
    vector[0] += old_velocity[0]
    vector[1] += old_velocity[1]
    set_user_velocity(client, vector)

    return PLUGIN_HANDLED
}

public Event_Death() {
    new client = read_data(2)

    if (CURRENT_WEAPON[client]) {
        CURRENT_WEAPON[client] = 0
    }

    return PLUGIN_HANDLED
}

public Task_BotWeapons(client) {
    if (IsConfigBroken || !is_valid_ent(client)) {
        return
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(ParseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpnId = get_user_weapon(client)

    if (HasUserPrimary(client)) {
        return
    }

    new random_weapon_id = random_num(0, ArraySize(Rifle_Names) - 1)

    if (wpnId == CHANGE_WEAPON && CURRENT_WEAPON) {
        Cmd_BuyAmmo1(client)
    } else if (random_weapon_id != 0) {
        Buy_Weapon(client, random_weapon_id)
    }
}

public client_putinserver(client) {
    if (IsConfigBroken || 
        !is_user_bot(client)) {
        return PLUGIN_CONTINUE
    }

    set_task(0.1, "Do_RegisterHam_Bot", client)
    return PLUGIN_HANDLED
}

public Do_RegisterHam_Bot(client) {
    RegisterHamFromEntity(Ham_Spawn, client, "Ham_BotSpawn_Post")
    RegisterHamFromEntity(Ham_TakeDamage, client, "Ham_TakeDamage_Pre")
}
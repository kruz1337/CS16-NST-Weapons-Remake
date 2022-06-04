#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta_util>
#include <string_stocks>

#define PLUGIN "NST Primary Weapons"
#define VERSION "1.3"
#define AUTHOR "github.com/kruz1337"

#if defined UL_COMPAT
   #define get_user_money(%1) cs_get_user_money_ul(%1)
   #define set_user_money(%1,%2) cs_set_user_money_ul(%1,%2)
#else
   #define set_user_money(%1,%2) cs_set_user_money(%1,%2)
   #define get_user_money(%1) cs_get_user_money(%1)
#endif

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

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
const m_rgAmmo_player_Slot0 = 376
const m_fInSpecialReload = 55
const m_fWeaponState = 74

new brokenConfig = 0
new commencing = 0

const MAX_WPN = 5000
const NEXT_SECTION = 24

new HAS_WEAPON[33], CURRENT_WEAPON[33]
new inZoom[33], inZoom2[33], disableZoom[33]

enum( += 100) {
    TASK_GIVEWPNBOT
}

new Array: Rifle_InfoText;
new Array: Rifle_Names;
new Array: Rifles_Number;

new Float:cvar_deploy[MAX_WPN]
new Float:cvar_dmgmultiplier[MAX_WPN]
new Float:cvar_speed[MAX_WPN]
new Float:cvar_recoil[MAX_WPN]
new Float:cvar_knockback[MAX_WPN]
new Float:cvar_fastrun[MAX_WPN]
new Float:cvar_sightrecoil[MAX_WPN]

new Float:pushangle[33][3]
new Float:roundTime

new class_weapons[MAX_WPN][32]
new cvar_zoom_type[MAX_WPN]
new cvar_clip[MAX_WPN]
new cvar_ammo[MAX_WPN]
new cvar_cost[MAX_WPN]
new cvar_administrator[MAX_WPN]
new cvar_reload[MAX_WPN]
new cvar_tracer[MAX_WPN][64]
new cvar_tracer_type[MAX_WPN]
new cvar_tracer_sprite[MAX_WPN]

new SAVE_CLIP[33], SAVED_CLIP[33]
new IN_EMIT_ATTACK

new const rifles[] = { 3, 5, 7, 8, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 24, 27, 28, 30 }
new const weapons_ammo_id[] = {-1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }
new const weapons_max_bp_ammo[] = {-1, 52, -1, 90, -1, 32, -1, 100, 90, -1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, -1, 35, 90, 90, -1, 100 }
new const weapons_def_world[][] = { "w_scout", "w_xm1014", "w_aug", "w_mac10", "w_ump45", "w_sg550", "w_galil", "w_famas", "w_awp", "w_mp5navy", "w_m249", "w_m3", "w_m4a1", "w_tmp", "w_g3sg1", "w_sg552", "w_ak47", "w_p90" }
new const buy_AmmoCount[] = {-1, 13, -1, 30, -1, 8, -1, 12, 30, -1, 30, 50, 12, 30, 30, 30, 12, 30, 10, 30, 30, 8, 30, 30, 30, -1, 30, 30, 30, -1, 50 }
new const buy_AmmoCost[] = {-1, 50, -1, 80, -1, 65, -1, 25, 60, -1, 20, 50, 25, 60, 60, 60, 25, 20, 125, 20, 60, 65, 60, 20, 80, -1, 80, 60, 80, -1, 50 }

stock const weapons_max_clip[] = {-1, 13, -1, 10, 1, 7, 1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }
stock const Float:weapons_clip_delay[CSW_P90 + 1] = { 0.00, 2.70, 0.00, 2.00, 0.00, 0.55, 0.00, 3.15, 3.30, 0.00, 4.50, 2.70, 3.50, 3.35, 2.45, 3.30, 2.70, 2.20, 2.50, 2.63, 4.70, 0.55, 3.05, 2.12, 3.50, 0.00, 2.20, 3.00, 2.45, 0.00, 3.40 }

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("nst_weapons.txt")
    register_concmd("nst_rifle_rebuy", "ReBuy_Weapon")
    register_clcmd("nst_menu_type2", "NST_Shotguns")
    register_clcmd("nst_menu_type3", "NST_Submachine")
    register_clcmd("nst_menu_type4", "NST_Snipers")
    register_clcmd("nst_menu_type5", "NST_Rifles")
    register_clcmd("nst_menu_type6", "NST_Machine")

    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    register_event("HLTV", "event_start_freezetime", "a", "1=0", "2=0")
    register_event("CurWeapon", "Current_Weapon", "be", "1=1")
    register_event("Damage", "event_damage", "b", "2>0")

    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
    RegisterHam(Ham_Touch, "weaponbox", "OnPlayerTouchWeaponBox")

    RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
    RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
    RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
    RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
    RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
    RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
    RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

    register_forward(FM_SetModel, "fw_WorldModel")
    register_forward(FM_CmdStart, "fw_CmdStart")

    register_clcmd("buyammo1", "ClientCommand_buyammo1")
    register_clcmd("primammo", "ClientCommand_buyammo1")

    register_event("TextMsg", "event_commencing", "a", "2=#event_commencing", "2=#Game_will_restart_in")

    new weapon_name[17]
    for (new i = 1; i <= CSW_P90; i++) {
        if (!(((1 << 2) | (1 << CSW_HEGRENADE) | (1 << CSW_DEAGLE) | (1 << CSW_GLOCK18) | (1 << CSW_FIVESEVEN) | (1 << CSW_P228) | (1 << CSW_USP) | (1 << CSW_ELITE) | (1 << CSW_SMOKEGRENADE) | (1 << CSW_FLASHBANG) | (1 << CSW_KNIFE) | (1 << CSW_C4)) & (1 << i)) && get_weaponname(i, weapon_name, charsmax(weapon_name))) {
            if (i != CSW_M3 && i != CSW_XM1014) {
                RegisterHam(Ham_Item_PostFrame, weapon_name, "Item_PostFrame_Pre")
            }
            RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "Primary_Attack")
            RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "Primary_Attack_Post", 1)
            RegisterHam(Ham_Item_Deploy, weapon_name, "Weapon_Deploy_Post", 1)
        }
    }

    RegisterHam(Ham_Item_PostFrame, "weapon_m3", "Shotguns_PostFrame_Pre")
    RegisterHam(Ham_Item_PostFrame, "weapon_xm1014", "Shotguns_PostFrame_Pre")
}

public plugin_precache() {
    plugin_startup()

    if (brokenConfig != 0) {
        return
    }

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        new v_model[252], p_model[252], w_model[252], sight_model[252]
        formatex(v_model, charsmax(v_model), "models/%s", parseConfig(i, "v_model"))
        formatex(p_model, charsmax(p_model), "models/%s", parseConfig(i, "p_model"))
        formatex(w_model, charsmax(w_model), "models/%s", parseConfig(i, "w_model"))

        precache_model(v_model)
        precache_model(p_model)
        precache_model(w_model)

        if (equali(parseConfig(i, "zoom_type"), "3")) {
            formatex(sight_model, charsmax(sight_model), "models/%s", parseConfig(i, "sight_model"))
            precache_model(sight_model)
        }
    }

    for (new i = 1; i < ArraySize(Rifle_Names); i++) {
        new total_sound[252]
        new fs_left[252], fs_right[252]

        formatex(total_sound, charsmax(total_sound), "%s", parseConfig(i, "fire_sounds"))
        strtok(total_sound, fs_left, 252, fs_right, 252, '*')
        trim(fs_left)
        trim(fs_right)

        if (equali(fs_left, "") || equali(fs_right, "")) {
            format(total_sound, 252, "weapons/%s", total_sound)

            precache_sound(total_sound)
        } else {
            format(fs_left, 252, "weapons/%s", fs_left)
            format(fs_right, 252, "weapons/%s", fs_right)

            precache_sound(fs_left)
            precache_sound(fs_right)
        }
    }

    new model[64]
    for (new wpnid = 0; wpnid < ArraySize(Rifles_Number); wpnid++) {
        if (wpnid != 0) {
            ArrayGetString(Rifle_Names, wpnid, model, charsmax(model))

            trim(model)
            replace(model, 64, " ", "_")
            strtolower(model)

            format(class_weapons[wpnid], 31, "nst_%s", model)

            cvar_clip[wpnid] = str_to_num(parseConfig(wpnid, "clip"))
            cvar_ammo[wpnid] = str_to_num(parseConfig(wpnid, "ammo"))
            cvar_cost[wpnid] = str_to_num(parseConfig(wpnid, "cost"))
            cvar_administrator[wpnid] = str_to_num(parseConfig(wpnid, "administrator"))
            cvar_zoom_type[wpnid] = str_to_num(parseConfig(wpnid, "zoom_type"))
            cvar_reload[wpnid] = str_to_num(parseConfig(wpnid, "reload"))
            cvar_tracer_type[wpnid] = str_to_num(parseConfig(wpnid, "tracer_type"))
            cvar_tracer_sprite[wpnid] = precache_model(parseConfig(wpnid, "tracer_sprite"))

            format(cvar_tracer[wpnid], 63, "%s", parseConfig(wpnid, "tracer"))

            cvar_deploy[wpnid] = str_to_float(parseConfig(wpnid, "deploy"))
            cvar_knockback[wpnid] = str_to_float(parseConfig(wpnid, "knockback"))
            cvar_recoil[wpnid] = str_to_float(parseConfig(wpnid, "recoil"))
            cvar_dmgmultiplier[wpnid] = str_to_float(parseConfig(wpnid, "damage"))
            cvar_speed[wpnid] = str_to_float(parseConfig(wpnid, "speed"))
            cvar_fastrun[wpnid] = str_to_float(parseConfig(wpnid, "fastrun"))
            cvar_sightrecoil[wpnid] = str_to_float(parseConfig(wpnid, "sight_recoil"))
        }
    }
}

public plugin_startup() {
    new _rifles_File[100] = { "addons/amxmodx/configs/nst_weapons/nst_rifles.ini" }

    if (!file_exists(_rifles_File)) {
        new log_file[999]
        formatex(log_file[0], charsmax(log_file) - 0, "%L", LANG_PLAYER, "FILE_NOT_LOADED")
        replace(log_file, 999, "$", "./.../nst_rifles.ini")

        server_print("[NST Weapons] %s", log_file)
        brokenConfig = 1

        return
    }

    Rifles_Number = ArrayCreate(1)
    Rifle_Names = ArrayCreate(64)
    Rifle_InfoText = ArrayCreate(128)

    readConfig()
    readConfigSections()

    if (configSyntax() == -1) {
        new log_file[999]
        formatex(log_file[0], charsmax(log_file) - 0, "%L", LANG_PLAYER, "BROKEN_CONFIG")
        replace(log_file, 999, "$", "./.../nst_rifles.ini")

        server_print("[NST Weapons] %s", log_file)
        brokenConfig = 1

        return;
    }
}

/* Config Functions */
public config_error_log() {
    new _rifles_File[100] = { "addons/amxmodx/configs/nst_weapons/nst_rifles.ini" }
    new log_msg[999]
    formatex(log_msg[0], charsmax(log_msg) - 0, "%L", LANG_PLAYER, (!file_exists(_rifles_File)) ? "FILE_NOT_LOADED" : "BROKEN_CONFIG")
    replace(log_msg, 999, "$", "./.../nst_rifles.ini")

    server_print("[NST Weapons] %s", log_msg)
    brokenConfig = 1
    return;
}

public readConfigSections() {
    new sectionNumber = 0
    new temp[64]

    /* Rifle */
    for (new i = 0; i < ArraySize(Rifle_InfoText); i++) {
        if (i == 0) {
            ArrayPushString(Rifle_Names, temp)
            ArrayPushCell(Rifles_Number, sectionNumber)
            i++;
        }
        ArrayGetString(Rifle_InfoText, sectionNumber, temp, charsmax(temp))
        replace(temp, 999, "[", "")
        replace(temp, 999, "]", "")
        replace(temp, 999, "^n", "")
        ArrayPushString(Rifle_Names, temp)
        ArrayPushCell(Rifles_Number, sectionNumber)

        if (ArraySize(Rifle_InfoText) > sectionNumber + NEXT_SECTION) {
            sectionNumber = sectionNumber + NEXT_SECTION
        } else {
            i = ArraySize(Rifle_InfoText)
        }
    }
    sectionNumber = 0
}

public readConfig() {
    new buffer[128]
    new left_comment[128], right_comment[128], left_s_comment[128], right_s_comment[128]

    new fp_rifles = fopen("addons/amxmodx/configs/nst_weapons/nst_rifles.ini", "r")
    while (!feof(fp_rifles)) {
        fgets(fp_rifles, buffer, charsmax(buffer))

        //Comment Line Remover
        strtok(buffer, left_comment, 128, right_comment, 128, ';')
        format(right_comment, 128, ";%s", right_comment)
        str_replace(buffer, 128, right_comment, "_THIS_IS_COMMENT_LINE_")

        //Comment Line Remover 2
        strtok(buffer, left_s_comment, 128, right_s_comment, 128, ']')
        if (!equali(right_s_comment, "")) {
            str_replace(buffer, 128, right_s_comment, "")
        }

        ArrayPushString(Rifle_InfoText, buffer)

        for (new i = 0; i < ArraySize(Rifle_InfoText); i++) {
            new temp[128]
            ArrayGetString(Rifle_InfoText, i, temp, charsmax(temp))
            if (equali(temp, "_THIS_IS_COMMENT_LINE_")) {
                ArrayDeleteItem(Rifle_InfoText, i)
            }
        }
    }
    fclose(fp_rifles)
}

stock parseConfig(const strKey, const Property[]) {
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
    const zoom_type = 13
    const tracer = 14
    const tracer_type = 15
    const tracer_sprite = 16
    const sight_recoil = 17
    const sight_model = 18
    const v_model = 19
    const p_model = 20
    const w_model = 21
    const fire_sounds = 22

    new parserLine[128]
    new rightValue[128], leftValue[32]

    new PropertyNumber

    if (equali(Property, "administrator")) {
        PropertyNumber = administrator
    }
    if (equali(Property, "cost")) {
        PropertyNumber = cost
    }
    if (equali(Property, "wpn_id")) {
        PropertyNumber = wpn_id
    }
    if (equali(Property, "clip")) {
        PropertyNumber = clip
    }
    if (equali(Property, "ammo")) {
        PropertyNumber = ammo
    }
    if (equali(Property, "damage")) {
        PropertyNumber = damage
    }
    if (equali(Property, "recoil")) {
        PropertyNumber = recoil
    }
    if (equali(Property, "deploy")) {
        PropertyNumber = deploy
    }
    if (equali(Property, "reload")) {
        PropertyNumber = reload
    }
    if (equali(Property, "speed")) {
        PropertyNumber = speed
    }
    if (equali(Property, "knockback")) {
        PropertyNumber = knockback
    }
    if (equali(Property, "fastrun")) {
        PropertyNumber = fastrun
    }
    if (equali(Property, "zoom_type")) {
        PropertyNumber = zoom_type
    }
    if (equali(Property, "tracer")) {
        PropertyNumber = tracer
    }
    if (equali(Property, "tracer_type")) {
        PropertyNumber = tracer_type
    }
    if (equali(Property, "tracer_sprite")) {
        PropertyNumber = tracer_sprite
    }
    if (equali(Property, "sight_recoil")) {
        PropertyNumber = sight_recoil
    }
    if (equali(Property, "sight_model")) {
        PropertyNumber = sight_model
    }
    if (equali(Property, "v_model")) {
        PropertyNumber = v_model
    }
    if (equali(Property, "p_model")) {
        PropertyNumber = p_model
    }
    if (equali(Property, "w_model")) {
        PropertyNumber = w_model
    }
    if (equali(Property, "fire_sounds")) {
        PropertyNumber = fire_sounds
    }

    ArrayGetString(Rifle_InfoText, ArrayGetCell(Rifles_Number, strKey) + PropertyNumber, parserLine, charsmax(parserLine))
    strtok(parserLine, leftValue, 64, rightValue, 127, '=')
    trim(leftValue);
    trim(rightValue);

    return rightValue
}

stock configSyntax() {
    new temp[128]

    for (new i = 0; i < ArraySize(Rifle_Names); i++) {
        if (!equali(parseConfig(i, "administrator"), "0")) {
            if (!equali(parseConfig(i, "administrator"), "1")) {
                return -1;
            }
        }
        formatex(temp, charsmax(temp), "%s", parseConfig(i, "cost"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "wpn_id"))

        if (str_to_num(temp[0]) == 0 || str_to_num(temp[0]) == 2 || str_to_num(temp[0]) == 29 || str_to_num(temp[0]) > 30 || str_to_num(temp[0]) == 1 || str_to_num(temp[0]) == 10 || str_to_num(temp[0]) == 11 || str_to_num(temp[0]) == 16 || str_to_num(temp[0]) == 17 || str_to_num(temp[0]) == 26 || str_to_num(temp[0]) == 4 || str_to_num(temp[0]) == 9 || str_to_num(temp[0]) == 25) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "clip"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "ammo"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "damage"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "recoil"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "deploy"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        if (!equali(parseConfig(i, "reload"), "0")) {
            if (!equali(parseConfig(i, "reload"), "1")) {
                return -1;
            }
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "speed"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "knockback"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "fastrun"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        if (!equali(parseConfig(i, "zoom_type"), "0")) {
            if (!equali(parseConfig(i, "zoom_type"), "1")) {
                if (!equali(parseConfig(i, "zoom_type"), "2")) {
                    if (!equali(parseConfig(i, "zoom_type"), "3")) {
                        return -1;
                    }
                }
            }
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "tracer"))

        new r_color[64], g_color[64], b_color[64], width[64], right[64]
        strtok(temp, r_color, 64, right, 64, ',')
        strtok(right, g_color, 64, right, 64, ',')
        strtok(right, b_color, 64, width, 64, ',')

        if (!equali(temp[0], "0")) {
            if (!strlen(r_color) || !strlen(g_color) || !strlen(width)) {
                if (!isdigit(r_color[0]) || !isdigit(g_color[0]) || !isdigit(b_color[0]) || !isdigit(width[0])) {
                    return -1;
                }
            }
        }

        if (!equali(parseConfig(i, "tracer_type"), "0")) {
            if (!equali(parseConfig(i, "tracer_type"), "1")) {
                if (!equali(parseConfig(i, "tracer_type"), "2")) {
                    return -1;
                }
            }
        }

        if (!contain(parseConfig(i, "tracer_sprite"), ".spr")) {
            return -1
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "sight_recoil"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        if (!contain(parseConfig(i, "sight_model"), ".mdl")) {
            return -1
        }

        if (!contain(parseConfig(i, "v_model"), ".mdl")) {
            return -1
        }

        if (!contain(parseConfig(i, "p_model"), ".mdl")) {
            return -1
        }

        if (!contain(parseConfig(i, "w_model"), ".mdl")) {
            return -1
        }

        if (!contain(parseConfig(i, "fire_sounds"), ".wav")) {
            return -1
        }
    }

    return 0;
}

/* All Stock Functions */
stock drop_all_primary(client) {
    for (new i = 0; i < sizeof(rifles); i++) {
        static dropweapon[32]
        get_weaponname(rifles[i], dropweapon, sizeof dropweapon - 1)
        engclient_cmd(client, "drop", dropweapon)
    }
}

stock get_weapon_ent(client, wpnid = 0, wpnName[] = "") {
    static newName[24];

    if (wpnid) {
        get_weaponname(wpnid, newName, 23);
    } else {
        formatex(newName, 23, "%s", wpnName);
    }

    if (!equal(newName, "weapon_", 7)) {
        format(newName, 23, "weapon_%s", newName);
    }

    return fm_find_ent_by_owner(get_maxplayers(), newName, client);
}

stock user_has_primary(client) {
    new return_ = 0
    for (new i = 0; i < sizeof(rifles); i++) {
        if (user_has_weapon(client, rifles[i])) {
            return_ = 1
        }
    }
    return return_
}

stock set_weapon_timeidle(client, Float:TimeIdle) {
    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))

    if (!is_user_alive(client)) {
        return
    }

    static entity;
    entity = fm_get_user_weapon_entity(client, CHANGE_WEAPON)

    if (!pev_valid(entity)) {
        return
    }

    set_pdata_float(entity, m_flNextPrimaryAttack, TimeIdle, 4)
    set_pdata_float(entity, m_flNextSecondaryAttack, TimeIdle, 4)
    set_pdata_float(entity, m_flTimeWeaponIdle, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(client, Float:nexttime) {
    if (!is_user_alive(client))
        return

    set_pdata_float(client, 83, nexttime, 5)
}

stock set_weapon_anim(const player, const sequence) {
    set_pev(player, pev_weaponanim, sequence)

    message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = player)
    write_byte(sequence)
    write_byte(pev(player, pev_body))
    message_end()
}

stock get_rifle_sound(weapon) {
    new total_sound[252], BLANK[252]
    new fs_left[252], fs_right[252]

    formatex(total_sound, charsmax(total_sound), "%s", parseConfig(weapon, "fire_sounds"))
    strtok(total_sound, fs_left, 252, fs_right, 252, '*')
    trim(fs_left)
    trim(fs_right)

    if (equali(fs_left, "") || equali(fs_right, "")) {
        format(total_sound, 252, "weapons/%s", total_sound)

        return total_sound
    } else {
        format(fs_left, 252, "weapons/%s", fs_left)
        format(fs_right, 252, "weapons/%s", fs_right)

        new selected_variable[252]
        switch (random_num(0, 1)) {
            case 0:
                selected_variable = fs_left
            case 1:
                selected_variable = fs_right
        }

        return selected_variable
    }

    return BLANK
}

stock create_velocity_vector(victim, attacker, Float:velocity[3], Float:knockback) {
    if (!is_user_alive(attacker)) {
        return 0;
    }
    if (!is_valid_ent(attacker)) {
        return 0;
    }

    new Float:victim_origin[3], Float:attacker_origin[3], Float:new_origin[3];

    entity_get_vector(victim, EV_VEC_origin, victim_origin);
    entity_get_vector(attacker, EV_VEC_origin, attacker_origin);

    new_origin[0] = victim_origin[0] - attacker_origin[0];
    new_origin[1] = victim_origin[1] - attacker_origin[1];

    velocity[0] = (new_origin[0] * (knockback * 900)) / get_entity_distance(victim, attacker);
    velocity[1] = (new_origin[1] * (knockback * 900)) / get_entity_distance(victim, attacker);

    return 1;
}

PlayEmitSound(client, const sound[], type) {
    emit_sound(client, type, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

ShowHud_Ammo(client, ammo) {
    new wpn_id = get_user_weapon(client, _, _)
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoPickup"), _, client)
    write_byte(weapons_ammo_id[wpn_id])
    write_byte(ammo)
    message_end()
}

SetFov(client, iFov) {
    set_pev(client, pev_fov, iFov)
    set_pdata_int(client, m_iFOV, iFov, 5)
}

ResetFov(client) {
    if (0 <= get_pdata_int(client, m_iFOV, 5) <= 90) {
        set_pev(client, pev_fov, 90)
        set_pdata_int(client, m_iFOV, 90, 5)
    }
}

//Main
public NST_Shotguns(client) {
    new temp[64]
    new menu[512], menuxx
    new text[256], len = 0
    new administrator, wpn_id
    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    if (brokenConfig == 0 && commencing == 0) {
        for (new i = 1; i < ArraySize(Rifle_Names); i++) {
            administrator = str_to_num(parseConfig(i, "administrator"))
            wpn_id = str_to_num(parseConfig(i, "wpn_id"))
            new menuKey[64]
            ArrayGetString(Rifle_Names, i, temp, charsmax(temp))

            if (wpn_id == 5 || wpn_id == 21) {
                if (administrator == 0) {
                    formatex(menu, charsmax(menu), "%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                } else {
                    formatex(menu, charsmax(menu), "\y%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                }
            }
        }
    } else {
        config_error_log()
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT");
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK");
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")


    if (is_user_alive(client)) {
        menu_display(client, menuxx, 0)
    } else {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
    }

    return PLUGIN_HANDLED
}

public NST_Submachine(client) {
    new temp[64]
    new menu[512], menuxx
    new text[256], len = 0
    new administrator, wpn_id
    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    if (brokenConfig == 0 && commencing == 0) {
        for (new i = 1; i < ArraySize(Rifle_Names); i++) {
            administrator = str_to_num(parseConfig(i, "administrator"))
            wpn_id = str_to_num(parseConfig(i, "wpn_id"))
            new menuKey[64]
            ArrayGetString(Rifle_Names, i, temp, charsmax(temp))

            if (wpn_id == 7 || wpn_id == 12 || wpn_id == 19 || wpn_id == 23 || wpn_id == 30) {
                if (administrator == 0) {
                    formatex(menu, charsmax(menu), "%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                } else {
                    formatex(menu, charsmax(menu), "\y%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                }
            }
        }
    } else {
        config_error_log()
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT");
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK");
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    if (is_user_alive(client)) {
        menu_display(client, menuxx, 0)
    } else {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
    }

    return PLUGIN_HANDLED
}

public NST_Rifles(client) {
    new temp[64]
    new menu[512], menuxx
    new text[256], len = 0
    new administrator, wpn_id
    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    if (brokenConfig == 0 && commencing == 0) {
        for (new i = 1; i < ArraySize(Rifle_Names); i++) {
            administrator = str_to_num(parseConfig(i, "administrator"))
            wpn_id = str_to_num(parseConfig(i, "wpn_id"))
            new menuKey[64]
            ArrayGetString(Rifle_Names, i, temp, charsmax(temp))

            if (wpn_id == 8 || wpn_id == 14 || wpn_id == 15 || wpn_id == 22 || wpn_id == 27 || wpn_id == 28) {
                if (administrator == 0) {
                    formatex(menu, charsmax(menu), "%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                } else {
                    formatex(menu, charsmax(menu), "\y%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                }
            }
        }
    } else {
        config_error_log()
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT");
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK");
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    if (is_user_alive(client)) {
        menu_display(client, menuxx, 0)
    } else {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
    }

    return PLUGIN_HANDLED
}

public NST_Snipers(client) {
    new temp[64]
    new menu[512], menuxx
    new text[256], len = 0
    new administrator, wpn_id
    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    if (brokenConfig == 0 && commencing == 0) {
        for (new i = 1; i < ArraySize(Rifle_Names); i++) {
            administrator = str_to_num(parseConfig(i, "administrator"))
            wpn_id = str_to_num(parseConfig(i, "wpn_id"))
            new menuKey[64]
            ArrayGetString(Rifle_Names, i, temp, charsmax(temp))

            if (wpn_id == 3 || wpn_id == 13 || wpn_id == 18 || wpn_id == 24) {
                if (administrator == 0) {
                    formatex(menu, charsmax(menu), "%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                } else {
                    formatex(menu, charsmax(menu), "\y%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                }
            }
        }
    } else {
        config_error_log()
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT");
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK");
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    if (is_user_alive(client)) {
        menu_display(client, menuxx, 0)
    } else {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
    }

    return PLUGIN_HANDLED
}

public NST_Machine(client) {
    new temp[64]
    new menu[512], menuxx
    new text[256], len = 0
    new administrator, wpn_id
    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTWeapon")

    if (brokenConfig == 0 && commencing == 0) {
        for (new i = 1; i < ArraySize(Rifle_Names); i++) {
            administrator = str_to_num(parseConfig(i, "administrator"))
            wpn_id = str_to_num(parseConfig(i, "wpn_id"))
            new menuKey[64]
            ArrayGetString(Rifle_Names, i, temp, charsmax(temp))

            if (wpn_id == 20) {
                if (administrator == 0) {
                    formatex(menu, charsmax(menu), "%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                } else {
                    formatex(menu, charsmax(menu), "\y%s 	\r$%s", temp, parseConfig(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                }
            }
        }
    } else {
        config_error_log()
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT");
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK");
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    if (is_user_alive(client)) {
        menu_display(client, menuxx, 0)
    } else {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
    }

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

public Buy_Weapon(client, wpnid) {
    if (brokenConfig != 0) {
        return
    }

    new buyzone = cs_get_user_buyzone(client)

    if ((get_cvar_num("nst_use_buyzone") ? buyzone : 1) == 0) {
        client_print(client, print_chat, "[NST Wpn] %L", LANG_PLAYER, "CANT_BUY_WEAPON")
    } else {
        new plrClip, plrAmmo
        get_user_weapon(client, plrClip, plrAmmo)

        new user_money = get_user_money(client)
        new wp_cost = cvar_cost[wpnid]
        new clip_max = cvar_clip[wpnid]
        new ammo_max = cvar_ammo[wpnid]
        new administrator = cvar_administrator[wpnid]

        if (!(get_user_flags(client) & ADMIN_KICK) && administrator == 1) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ACCESS_DENIED_BUY")
        } else if (!is_user_alive(client)) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "NOT_LIVE")
        } else if (get_gametime() - roundTime > get_cvar_num("nst_buy_time")) {
            engclient_print(client, engprint_center, "%L", LANG_PLAYER, "BUY_TIME_END", get_cvar_num("nst_buy_time"));
        } else if (HAS_WEAPON[client] == wpnid) {
            new temp[256]
            ArrayGetString(Rifle_Names, HAS_WEAPON[client], temp, charsmax(temp))

            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ALREADY_HAVE", temp)
        } else if (get_cvar_num("nst_free") ? true : (wp_cost <= get_user_money(client))) {
            drop_all_primary(client)

            CURRENT_WEAPON[client] = wpnid
            HAS_WEAPON[client] = wpnid
            Give_Weapon(client, clip_max, ammo_max)
            ShowHud_Ammo(client, ammo_max)

            if (get_cvar_num("nst_free") == 0) {
                set_user_money(client, user_money + -wp_cost)
            }
        } else {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "INSUFFICIENT_MONEY")
        }
    }
}

public ReBuy_Weapon(client) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    new wpnid = CURRENT_WEAPON[client]
    if (wpnid > 0) {
        Buy_Weapon(client, wpnid)
    }

    return PLUGIN_HANDLED
}

public Give_Weapon(client, clip, ammo) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))

    static weapon_name[32]
    get_weaponname(CHANGE_WEAPON, weapon_name, charsmax(weapon_name))

    give_item(client, weapon_name)
    cs_set_user_bpammo(client, CHANGE_WEAPON, ammo)
    new entity = get_weapon_ent(client, CHANGE_WEAPON)
    cs_set_weapon_ammo(entity, clip)

    return PLUGIN_HANDLED
}

public Primary_Attack(entity) {
    new client = pev(entity, pev_owner)
    pev(client, pev_punchangle, pushangle[client])

    return HAM_IGNORED
}

public Primary_Attack_Post(entity) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    if (!is_valid_ent(entity)) {
        return HAM_IGNORED
    }

    static client
    client = pev(entity, pev_owner)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpn_id = get_user_weapon(client, _, _)

    if (wpn_id != CHANGE_WEAPON || !HAS_WEAPON[client]) {
        return HAM_IGNORED
    }

    new old_ammo, blank
    get_user_ammo(client, CHANGE_WEAPON, old_ammo, blank)

    if (old_ammo != 0) {
        if (cvar_speed[CURRENT_WEAPON] > 0.9) {
            set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON] - 0.9, 4)
        } else if (cvar_speed[CURRENT_WEAPON] > 0.2) {
            set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON] - 0.38, 4)
        } else {
            set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON], 4)
        }
    }

    new Float:push[3]
    pev(client, pev_punchangle, push)
    xs_vec_sub(push, pushangle[client], push)

    if (inZoom2[client]) {
        xs_vec_mul_scalar(push, cvar_sightrecoil[CURRENT_WEAPON], push)
    } else {
        xs_vec_mul_scalar(push, cvar_recoil[CURRENT_WEAPON], push)
    }

    xs_vec_add(push, pushangle[client], push)
    set_pev(client, pev_punchangle, push)
    Set_BitVar(IN_EMIT_ATTACK, client)

    return FMRES_SUPERCEDE
}

public Weapon_Deploy_Post(entity) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpn_id = get_user_weapon(client, _, _)

    if (!pev_valid(entity)) {
        return HAM_IGNORED
    }

    if (!is_user_alive(client)) {
        return HAM_IGNORED
    }

    if (wpn_id != CHANGE_WEAPON || !HAS_WEAPON[client]) {
        return HAM_IGNORED
    }

    set_weapon_timeidle(client, cvar_deploy[CURRENT_WEAPON])
    set_player_nextattack(client, cvar_deploy[CURRENT_WEAPON])

    return HAM_IGNORED
}

public Shotguns_PostFrame_Pre(entity) {
    if (brokenConfig != 0) {
        return
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new user_wpnid = get_user_weapon(client, _, _)

    if (user_wpnid != CHANGE_WEAPON || !HAS_WEAPON[client]) {
        return
    }

    static btnInfo, inSpecialReload, clip_old, clip_max, ammo_old, AmmoType
    btnInfo = pev(client, pev_button)
    inSpecialReload = get_pdata_int(entity, m_fInSpecialReload, 4)
    clip_old = get_pdata_int(entity, m_iClip, 4)
    clip_max = cvar_clip[CURRENT_WEAPON]
    ammo_old = get_pdata_int(client, AmmoType, 5)
    AmmoType = m_rgAmmo_player_Slot0 + get_pdata_int(entity, m_iPrimaryAmmoType, 4)

    if (inSpecialReload && clip_old >= clip_max) //FULL CLIP DON'T STOP FIX
    {
        set_pev(client, pev_button, btnInfo & ~IN_RELOAD)
        set_pev(entity, m_fInSpecialReload, 0, 4)
        set_pdata_float(entity, m_flTimeWeaponIdle, get_pdata_float(entity, m_flTimeWeaponIdle, 4) + 1.0, 4)
        set_pev(client, pev_weaponanim, 4);
    }

    if (clip_old == weapons_max_clip[user_wpnid] && ((btnInfo & IN_RELOAD) || inSpecialReload)) //DEFAULT MAX CLIP RELOAD STOP FIX 
    {
        set_pev(client, pev_button, btnInfo & IN_RELOAD)
        set_pev(client, pev_weaponanim, 3);

        set_pdata_int(entity, m_iClip, clip_old + 1, 4)
        set_pdata_int(client, AmmoType, ammo_old - 1, 5)
        set_pdata_int(entity, m_fInSpecialReload, 1, 4)
    }

    return
}

public Item_PostFrame_Pre(entity) {
    if (brokenConfig != 0) {
        return
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new user_wpnid = get_user_weapon(client, _, _)

    if (user_wpnid != CHANGE_WEAPON || !HAS_WEAPON[client]) {
        return
    }

    static btnInfo, inReload, clip_old, clip_max, ammo_old, AmmoType, Float:nextAttack
    btnInfo = pev(client, pev_button)
    inReload = get_pdata_int(entity, m_fInReload, 4)
    clip_old = get_pdata_int(entity, m_iClip, 4)
    clip_max = cvar_clip[CURRENT_WEAPON]
    ammo_old = get_pdata_int(client, AmmoType, 5)
    AmmoType = m_rgAmmo_player_Slot0 + get_pdata_int(entity, m_iPrimaryAmmoType, 4)
    nextAttack = get_pdata_float(client, m_flNextAttack, 5)

    if (inReload && nextAttack <= 0.0) {
        new j = min(clip_max - clip_old, ammo_old)
        set_pdata_int(entity, m_iClip, clip_old + j, 4)
        set_pdata_int(client, AmmoType, ammo_old - j, 5)
        set_pdata_int(entity, m_fInReload, 0, 4)
    }

    if (btnInfo & IN_RELOAD && !inReload) {
        disableZoom[client] = 1

        if (clip_old >= clip_max) {
            set_pdata_float(client, m_flNextAttack, 0.0, 5)
            set_pev(client, pev_button, btnInfo & ~IN_RELOAD)

            //STOP RELOAD ANIMATION
            switch (user_wpnid) {
                case CSW_MP5NAVY, CSW_MAC10, CSW_TMP, CSW_P90, CSW_UMP45, CSW_GALIL, CSW_FAMAS, CSW_AK47, CSW_SG552, CSW_AUG:  {
                    set_weapon_anim(client, 0);
                }
                case CSW_M4A1:  {
                    set_weapon_anim(client, (get_pdata_int(entity, m_fWeaponState, 4) & (1 << 2)) ? 0 : 7);
                }
                case CSW_G3SG1, CSW_SG550, CSW_SCOUT, CSW_M249:  {
                    set_weapon_anim(client, 0)
                }
            }
        } else if (clip_old == weapons_max_clip[user_wpnid] && ammo_old) {
            set_pdata_float(client, m_flNextAttack, weapons_clip_delay[user_wpnid], 5)
            set_pdata_int(entity, m_fInReload, 1, 4)
            //set_pdata_float(entity, m_flTimeWeaponIdle, weapons_clip_delay[user_wpnid] + 0.5, 4)

            //START RELOAD ANIMATION
            switch (user_wpnid) {
                case CSW_MP5NAVY, CSW_MAC10, CSW_TMP, CSW_P90, CSW_UMP45, CSW_GALIL, CSW_FAMAS, CSW_AK47, CSW_SG552, CSW_AUG:  {
                    set_weapon_anim(client, 1);
                }
                case CSW_M4A1:  {
                    set_weapon_anim(client, (get_pdata_int(entity, m_fWeaponState, 4) & (1 << 2)) ? 4 : 11)
                }
                case CSW_G3SG1, CSW_SG550, CSW_SCOUT, CSW_M249:  {
                    set_weapon_anim(client, 3)
                }
            }
        }
    } else {
        disableZoom[client] = 0
    }

    //SECONDARY ATTACK
    if (cvar_zoom_type[CURRENT_WEAPON] != 0) {
        set_pev(client, pev_button, btnInfo & ~IN_ATTACK2)
    }
}

public Current_Weapon(client) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    static clip, ammo

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new user_wpnid = get_user_weapon(client, clip, ammo)

    if (user_wpnid == CHANGE_WEAPON && HAS_WEAPON[client]) {
        entity_set_float(client, EV_FL_maxspeed, 240.0 + cvar_fastrun[CURRENT_WEAPON])

        new v_model[999], p_model[999], sight_model[999]
        formatex(v_model, charsmax(v_model), "models/%s", parseConfig(CURRENT_WEAPON, "v_model"))
        formatex(p_model, charsmax(p_model), "models/%s", parseConfig(CURRENT_WEAPON, "p_model"))
        formatex(sight_model, charsmax(sight_model), "models/%s", parseConfig(CURRENT_WEAPON, "sight_model"))

        if (!inZoom2[client]) {
            set_pev(client, pev_viewmodel2, v_model)
        } else {
            set_pev(client, pev_viewmodel2, sight_model)
        }

        set_pev(client, pev_weaponmodel2, p_model)
    }

    if (SAVE_CLIP[client] == 0) {
        if (is_valid_ent(get_weapon_ent(client, CHANGE_WEAPON))) {
            SAVED_CLIP[client] = cs_get_weapon_ammo(get_weapon_ent(client, CHANGE_WEAPON))
            SAVE_CLIP[client] = 1
        }
    }

    if (user_wpnid == CHANGE_WEAPON && HAS_WEAPON[client] && pev(client, pev_oldbuttons) & IN_ATTACK) {
        if (Get_BitVar(IN_EMIT_ATTACK, client)) {
            PlayEmitSound(client, get_rifle_sound(HAS_WEAPON[client]), 1)
        }

        if (cvar_reload[CURRENT_WEAPON] == 0) {
            if (cs_get_user_bpammo(client, user_wpnid) == 0) {

            } else {
                cs_set_user_bpammo(client, user_wpnid, cs_get_user_bpammo(client, user_wpnid) - 1)
                cs_set_weapon_ammo(get_weapon_ent(client, CHANGE_WEAPON), SAVED_CLIP[client])
            }
        }
    } else {
        SAVE_CLIP[client] = 0
    }

    UnSet_BitVar(IN_EMIT_ATTACK, client)

    return PLUGIN_HANDLED
}

public OnPlayerTouchWeaponBox(entity, client) {
    if (brokenConfig != 0) {
        return
    }

    new loop_enabled = 1
    for (new i = 1; i < ArraySize(Rifles_Number) && loop_enabled == 1; i++) {
        if (str_to_num(parseConfig(i, "wpn_id")) <= 0) {
            break;
        }
        if (is_valid_ent(entity)) {
            new classname[32]
            entity_get_string(entity, EV_SZ_classname, classname, 31)
            if (equal(classname, class_weapons[i])) {
                if (is_valid_ent(entity)) {
                    if (client > 0 && client < 34) {
                        if (get_entity_flags(entity) == FL_ONGROUND && !user_has_primary(client) && is_user_alive(client)) {
                            HAS_WEAPON[client] = i
                            loop_enabled = 0
                        }
                    }
                }
            }
        }
    }
}

public ClientCommand_buyammo1(client) {
    new old_ammo, iWeapon, ammo_max, ammo_def

    if (brokenConfig != 0) {
        for (new i = 0; i < sizeof(rifles); i++) {
            if (user_has_weapon(client, rifles[i])) {
                iWeapon = rifles[i]
            }
        }

        if (buy_AmmoCost[iWeapon] < cs_get_user_money(client)) {
            if (old_ammo < ammo_def) {
                set_user_money(client, get_user_money(client) + -buy_AmmoCost[iWeapon])
                cs_set_user_bpammo(client, iWeapon, old_ammo + buy_AmmoCount[iWeapon])

                if (cs_get_user_bpammo(client, iWeapon) > ammo_def) {
                    cs_set_user_bpammo(client, iWeapon, ammo_def)
                    ShowHud_Ammo(client, ammo_def - old_ammo)
                } else {
                    ShowHud_Ammo(client, buy_AmmoCount[iWeapon])
                }

                client_cmd(0, "spk sound/items/9mmclip1.wav")
            }
        }
    } else {
        new buyzone = cs_get_user_buyzone(client)
        new CURRENT_WEAPON = HAS_WEAPON[client]

        if ((get_cvar_num("nst_use_buyzone") ? buyzone : 1) && user_has_primary(client)) {
            for (new i = 0; i < sizeof(rifles); i++) {
                if (user_has_weapon(client, rifles[i])) {
                    iWeapon = rifles[i]
                }
            }

            if (iWeapon != 0) {
                ammo_def = weapons_max_bp_ammo[iWeapon]
                ammo_max = cvar_ammo[CURRENT_WEAPON]
                old_ammo = cs_get_user_bpammo(client, iWeapon);

                if (HAS_WEAPON[client]) {
                    if (buy_AmmoCost[iWeapon] < cs_get_user_money(client)) {
                        if (old_ammo < ammo_max) {
                            set_user_money(client, get_user_money(client) + -buy_AmmoCost[iWeapon])
                            cs_set_user_bpammo(client, iWeapon, old_ammo + buy_AmmoCount[iWeapon])

                            if (cs_get_user_bpammo(client, iWeapon) > ammo_max) {
                                cs_set_user_bpammo(client, iWeapon, ammo_max)
                                ShowHud_Ammo(client, ammo_max - old_ammo)
                            } else {
                                ShowHud_Ammo(client, buy_AmmoCount[iWeapon])
                            }

                            client_cmd(0, "spk sound/items/9mmclip1.wav")
                        }
                    }
                } else {
                    if (buy_AmmoCost[iWeapon] < cs_get_user_money(client)) {
                        if (old_ammo < ammo_def) {
                            set_user_money(client, get_user_money(client) + -buy_AmmoCost[iWeapon])
                            cs_set_user_bpammo(client, iWeapon, old_ammo + buy_AmmoCount[iWeapon])

                            if (cs_get_user_bpammo(client, iWeapon) > ammo_def) {
                                cs_set_user_bpammo(client, iWeapon, ammo_def)
                                ShowHud_Ammo(client, ammo_def - old_ammo)
                            } else {
                                ShowHud_Ammo(client, buy_AmmoCount[iWeapon])
                            }

                            client_cmd(0, "spk sound/items/9mmclip1.wav")
                        }
                    }
                }
            }
        }
    }

    return PLUGIN_HANDLED_MAIN
}

public fw_TraceAttack(entity, attacker, Float:flDamage, Float:fDir[3], ptr, iDamageType) {
    if (brokenConfig != 0) {
        return
    }

    if (!is_user_alive(attacker)) {
        return
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpn_id = get_user_weapon(attacker, _, _)

    if (wpn_id != CHANGE_WEAPON || !HAS_WEAPON[attacker]) {
        return
    }

    if (!equali(cvar_tracer[CURRENT_WEAPON], "0")) {
        new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

        new clip, ammo
        wpn_id = get_user_weapon(attacker, clip, ammo)

        new r_color[64], g_color[64], b_color[64], width[64], right[64]
        strtok(cvar_tracer[CURRENT_WEAPON], r_color, 64, right, 64, ',')
        strtok(right, g_color, 64, right, 64, ',')
        strtok(right, b_color, 64, width, 64, ',')

        if (cvar_tracer_type[CURRENT_WEAPON] == 0) {
            new vec1[3], vec2[3]
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
            write_byte(1) //Framestart
            write_byte(5) //Framerate
            write_byte(2) //Life
            write_byte(str_to_num(width)) //Width
            write_byte(0) //Noise
            write_byte(str_to_num(r_color))
            write_byte(str_to_num(g_color))
            write_byte(str_to_num(b_color))
            write_byte(200) //Brightness
            write_byte(0) //Speed
            message_end()
        } else if (cvar_tracer_type[CURRENT_WEAPON] == 1) {
            static Float:flEnd[3]
            get_tr2(ptr, TR_vecEndPos, flEnd)

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
                write_byte(str_to_num(width)) //Height
                write_byte(200) //Bright
                message_end()
            }
        } else if (cvar_tracer_type[CURRENT_WEAPON] == 2) {
            static Float:end[3]
            get_tr2(ptr, TR_vecEndPos, end)

            if (entity) {
                message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
                write_byte(TE_DECAL)
                engfunc(EngFunc_WriteCoord, end[0])
                engfunc(EngFunc_WriteCoord, end[1])
                engfunc(EngFunc_WriteCoord, end[2])
                write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS - 1)])
                write_short(entity)
                message_end()
            } else {
                message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
                write_byte(TE_WORLDDECAL)
                engfunc(EngFunc_WriteCoord, end[0])
                engfunc(EngFunc_WriteCoord, end[1])
                engfunc(EngFunc_WriteCoord, end[2])
                write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS - 1)])
                message_end()
            }
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
            write_byte(TE_BEAMENTPOINT)
            write_short(attacker | 0x1000)
            engfunc(EngFunc_WriteCoord, end[0])
            engfunc(EngFunc_WriteCoord, end[1])
            engfunc(EngFunc_WriteCoord, end[2])
            write_short(cvar_tracer_sprite[CURRENT_WEAPON])
            write_byte(1) //Framerate
            write_byte(5) //Framerate
            write_byte(2) //Life
            write_byte(str_to_num(width)) //Width
            write_byte(0) //Noise
            write_byte(str_to_num(r_color))
            write_byte(str_to_num(g_color))
            write_byte(str_to_num(b_color))
            write_byte(255)
            write_byte(0)
            message_end()
        }
    }
}

public fw_WorldModel(entity, model[]) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    static client
    client = pev(entity, pev_owner)

    new Classname[32], w_model[252]
    new CURRENT_WEAPON = HAS_WEAPON[client]

    pev(entity, pev_classname, Classname, sizeof(Classname))

    if (!pev_valid(entity)) {
        return FMRES_IGNORED
    }

    if (!equal(Classname, "weaponbox")) {
        return FMRES_IGNORED
    }

    for (new i = 0; i < sizeof(weapons_def_world); i++) {
        new old_W[252]
        formatex(old_W, charsmax(old_W), "models/%s.mdl", weapons_def_world[i])

        if (equal(model, old_W)) {
            if (HAS_WEAPON[client]) {
                entity_set_string(entity, EV_SZ_classname, class_weapons[CURRENT_WEAPON])

                formatex(w_model, charsmax(w_model), "models/%s", parseConfig(CURRENT_WEAPON, "w_model"))
                engfunc(EngFunc_SetModel, entity, w_model)
                HAS_WEAPON[client] = 0

                return FMRES_SUPERCEDE
            }
        }
    }

    return PLUGIN_CONTINUE
}

public fw_CmdStart(client, uc_handle, seed) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(client)) {
        return PLUGIN_HANDLED
    }

    new clip_old

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpn_id = get_user_weapon(client, clip_old, _)

    if (wpn_id != CHANGE_WEAPON || !HAS_WEAPON[client]) {
        return PLUGIN_HANDLED
    }

    static currentBtn;
    currentBtn = get_uc(uc_handle, UC_Buttons)
    static oldButton;
    oldButton = pev(client, pev_oldbuttons)

    if (((currentBtn & IN_RELOAD) || clip_old == 0) && cvar_zoom_type[CURRENT_WEAPON]) {
        //Reset weapon zoom after reload
        set_pdata_int(client, m_iFOV, 90, 5);
        cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
        ResetFov(client)

        new v_model[999]
        formatex(v_model, charsmax(v_model), "models/%s", parseConfig(CURRENT_WEAPON, "v_model"))
        set_pev(client, pev_viewmodel2, v_model)

        inZoom[client] = 0
        inZoom2[client] = 0
    } else if ((currentBtn & IN_ATTACK2) && !(oldButton & IN_ATTACK2) && !disableZoom[client]) {
        if (cvar_zoom_type[CURRENT_WEAPON] == 1) {
            set_weapon_timeidle(client, 0.3)
            set_pdata_float(client, m_flNextAttack, 0.3, 5)
            set_player_nextattack(client, 0.66)

            if (cs_get_user_zoom(client) == 1) {
                cs_set_user_zoom(client, CS_SET_AUGSG552_ZOOM, 1)
                if (get_cvar_num("nst_zoom_spk")) {
                    client_cmd(0, "spk weapons/zoom.wav")
                }
            } else {
                cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
                if (get_cvar_num("nst_zoom_spk")) {
                    client_cmd(0, "spk weapons/zoom.wav")
                }
            }
        } else if (cvar_zoom_type[CURRENT_WEAPON] == 2) {
            set_weapon_timeidle(client, 0.3)
            set_pdata_float(client, m_flNextAttack, 0.3, 5)
            set_player_nextattack(client, 0.66)

            if (!inZoom[client]) {
                inZoom[client] = 1

                set_pdata_int(client, m_iFOV, 35, 5);
                if (get_cvar_num("nst_zoom_spk")) {
                    client_cmd(0, "spk weapons/zoom.wav")
                }
            } else {
                inZoom[client] = 0

                set_pdata_int(client, m_iFOV, 90, 5);
                if (get_cvar_num("nst_zoom_spk")) {
                    client_cmd(0, "spk weapons/zoom.wav")
                }
            }
        } else if (cvar_zoom_type[CURRENT_WEAPON] == 3) {
            set_weapon_timeidle(client, 0.3)
            set_pdata_float(client, m_flNextAttack, 0.3, 5)
            set_player_nextattack(client, 0.66)

            if (!inZoom2[client]) {
                inZoom2[client] = 1

                new sight_model[999]
                formatex(sight_model, charsmax(sight_model), "models/%s", parseConfig(CURRENT_WEAPON, "sight_model"))
                set_pev(client, pev_viewmodel2, sight_model)
                SetFov(client, 70)

                if (get_cvar_num("nst_zoom_spk")) {
                    client_cmd(0, "spk weapons/zoom.wav")
                }
            }
        } else if (cvar_zoom_type[CURRENT_WEAPON] == 4) {
            inZoom2[client] = 0

            new v_model[999]
            formatex(v_model, charsmax(v_model), "models/%s", parseConfig(CURRENT_WEAPON, "v_model"))
            set_pev(client, pev_viewmodel2, v_model)
            ResetFov(client)

            if (get_cvar_num("nst_zoom_spk")) {
                client_cmd(0, "spk weapons/zoom.wav")
            }
        }
    }

    return PLUGIN_HANDLED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage) {
    if (brokenConfig != 0) {
        return
    }

    if (!is_valid_ent(attacker)) {
        return
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpn_id = get_user_weapon(attacker, _, _)

    if (wpn_id != CHANGE_WEAPON || !HAS_WEAPON[attacker]) {
        return
    }

    SetHamParamFloat(4, damage * cvar_dmgmultiplier[CURRENT_WEAPON])
}

public fw_PlayerSpawn_Post(id) {
    if (brokenConfig != 0) {
        return
    }

    if (!is_valid_ent(id)) {
        return
    }

    if (!is_user_alive(id)) {
        return
    }

    if (is_user_bot(id)) {
        new Float: time_give = random_float(1.0, 4.0)
        if (task_exists(id + TASK_GIVEWPNBOT)) {
            remove_task(id + TASK_GIVEWPNBOT)
        }
        set_task(time_give, "nst_bot_weapons", id + TASK_GIVEWPNBOT)
    }
}

public client_connect(id) {
    HAS_WEAPON[id] = 0
}

public client_disconnect(id) {
    HAS_WEAPON[id] = 0
}

public event_damage(client) {
    if (brokenConfig != 0) {
        return PLUGIN_CONTINUE
    }

    if (!is_valid_ent(client)) {
        return PLUGIN_CONTINUE
    }

    new weapon, attacker = get_user_attacker(client, weapon)

    if (!is_user_alive(attacker)) {
        return PLUGIN_CONTINUE
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))

    if (weapon == CHANGE_WEAPON && HAS_WEAPON[attacker]) {
        new Float:vector[3]
        new Float:old_velocity[3]
        get_user_velocity(client, old_velocity)
        create_velocity_vector(client, attacker, vector, cvar_knockback[CURRENT_WEAPON])
        vector[0] += old_velocity[0]
        vector[1] += old_velocity[1]
        set_user_velocity(client, vector)
    }

    return PLUGIN_CONTINUE;
}

public event_commencing() {
    commencing = 1
}

public event_start_freezetime() {
    remove_modded()
    commencing = 0
}

public event_new_round() {
    roundTime = get_gametime()
}

public client_putinserver(client) {
    if (brokenConfig != 0) {
        return
    }

    if (is_user_bot(client)) {
        set_task(0.1, "Do_RegisterHam_Bot", client)
    }
}

public Do_RegisterHam_Bot(client) {
    if (brokenConfig != 0) {
        return
    }

    if (!is_valid_ent(client)) {
        return
    }

    if (is_user_alive(client)) {
        fw_PlayerSpawn_Post(client)
    }

    RegisterHamFromEntity(Ham_Item_PostFrame, client, "Item_PostFrame_Pre")
    RegisterHamFromEntity(Ham_Item_Deploy, client, "Weapon_Deploy_Post", 1)
    RegisterHamFromEntity(Ham_TakeDamage, client, "fw_TakeDamage")
    RegisterHamFromEntity(Ham_Spawn, client, "fw_PlayerSpawn_Post", 1)
    RegisterHamFromEntity(Ham_Touch, client, "OnPlayerTouchWeaponBox")
}

public nst_bot_weapons(taskid) {
    if (brokenConfig != 0) {
        return
    }

    new id = (taskid - TASK_GIVEWPNBOT)

    new CURRENT_WEAPON = HAS_WEAPON[id]
    new CHANGE_WEAPON = str_to_num(parseConfig(CURRENT_WEAPON, "wpn_id"))
    new wpn_id = get_user_weapon(id, _, _)

    if (!is_valid_ent(id)) {
        return
    }

    if (!is_user_alive(id)) {
        return
    }

    if (get_cvar_num("nst_give_bot")) {
        if (wpn_id == CHANGE_WEAPON && HAS_WEAPON[id]) {
            ClientCommand_buyammo1(id)
        } else {
            if (!user_has_primary(id)) {
                new random_weapon_id = random_num(0, ArraySize(Rifle_Names) - 1)
                if (random_weapon_id != 0) {
                    Buy_Weapon(id, random_weapon_id)
                }
            }
        }
    }
}

public remove_modded() { //Who say this is bad?
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    new entity = -1
    for (new i = 0; i < ArraySize(Rifles_Number); i++) {
        while ((entity = find_ent_by_class(entity, class_weapons[i]))) {
            set_pev(entity, pev_nextthink, get_gametime());
        }
    }

    return PLUGIN_CONTINUE
}
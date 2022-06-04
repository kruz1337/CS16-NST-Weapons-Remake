#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta_util>
#include <string_stocks>

#define PLUGIN "NST Knifes"
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
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47
const m_flTimeWeaponIdle = 48

new brokenConfig = 0
new commencing = 0

const NEXT_SECTION = 24
const MAX_WPN = 5000

new HAS_WEAPON[33], CURRENT_WEAPON[33]

new Array: Knife_InfoText;
new Array: Knife_Names;
new Array: Knifes_Number;

new Float:cvar_deploy[MAX_WPN]
new Float:cvar_knockback[MAX_WPN]
new Float:cvar_dmgmultiplier[MAX_WPN]
new Float:cvar_speed[MAX_WPN]
new Float:cvar_speed2[MAX_WPN]
new Float:cvar_jumppower[MAX_WPN]
new Float:cvar_jumpgravity[MAX_WPN]
new Float:cvar_fastrun[MAX_WPN]

new Float:round_time

new class_knifes[MAX_WPN][32]
new cvar_cost[MAX_WPN]
new cvar_administrator[MAX_WPN]

new IN_BITVAR_JUMP

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("nst_weapons.txt")
    register_concmd("nst_knife_rebuy", "ReBuy_Knife")
    register_clcmd("nst_menu_type7", "NST_Knife")

    register_event("HLTV", "event_new_round", "a", "1=0", "2=0");
    register_event("HLTV", "event_start_freezetime", "a", "1=0", "2=0")
    register_event("CurWeapon", "Current_Weapon", "be", "1=1")
    register_event("Damage", "event_damage", "b", "2>0")
    register_event("DeathMsg", "event_death", "a", "1>0")
    register_event("TextMsg", "event_commencing", "a", "2=#event_commencing", "2=#Game_will_restart_in")

    register_forward(FM_EmitSound, "fw_EmitSound")
    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
    RegisterHam(Ham_Item_Deploy, "weapon_knife", "Weapon_Deploy_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Primary_Attack_Post", 1)
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Secondary_Attack_Post", 1)
}

public plugin_precache() {
    plugin_startup()

    if (brokenConfig != 0) {
        return
    }

    for (new i = 1; i < ArraySize(Knife_Names); i++) {
        new v_model[252], p_model[252], w_model[252]
        formatex(v_model, charsmax(v_model), "models/%s", parseConfig(i, "v_model"))
        formatex(p_model, charsmax(p_model), "models/%s", parseConfig(i, "p_model"))
        formatex(w_model, charsmax(w_model), "models/%s", parseConfig(i, "w_model"))

        precache_model(v_model)
        precache_model(p_model)
        precache_model(w_model)
    }

    for (new i = 1; i < ArraySize(Knife_Names); i++) {
        new hitwall[252], deploy[252], stab[252]
        new hit1[252], hit2[252], hit3[252], hit4[252]
        new slash1[252], slash2[252]

        formatex(hitwall, charsmax(hitwall), "weapons/%s", parseConfig(i, "sound_hitwall"))
        formatex(deploy, charsmax(deploy), "weapons/%s", parseConfig(i, "sound_deploy"))
        formatex(stab, charsmax(stab), "weapons/%s", parseConfig(i, "sound_stab"))
        formatex(slash1, charsmax(slash1), "weapons/%s", parseConfig(i, "sound_slash1"))
        formatex(slash2, charsmax(slash2), "weapons/%s", parseConfig(i, "sound_slash2"))
        formatex(hit1, charsmax(hit1), "weapons/%s", parseConfig(i, "sound_hit1"))
        formatex(hit2, charsmax(hit2), "weapons/%s", parseConfig(i, "sound_hit2"))
        formatex(hit3, charsmax(hit3), "weapons/%s", parseConfig(i, "sound_hit3"))
        formatex(hit4, charsmax(hit4), "weapons/%s", parseConfig(i, "sound_hit4"))

        precache_sound(hitwall)
        precache_sound(deploy)
        precache_sound(stab)
        precache_sound(hit1)
        precache_sound(hit2)
        precache_sound(hit3)
        precache_sound(hit4)
        precache_sound(slash1)
        precache_sound(slash2)
    }

    new model[64]
    for (new wpnid = 0; wpnid < ArraySize(Knifes_Number); wpnid++) {
        if (wpnid != 0) {
            ArrayGetString(Knife_Names, wpnid, model, charsmax(model))

            trim(model)
            replace(model, 64, " ", "_")
            strtolower(model)

            format(class_knifes[wpnid], 31, "nst_%s", model)

            cvar_cost[wpnid] = str_to_num(parseConfig(wpnid, "cost"))
            cvar_administrator[wpnid] = str_to_num(parseConfig(wpnid, "administrator"))

            cvar_deploy[wpnid] = str_to_float(parseConfig(wpnid, "deploy"))
            cvar_knockback[wpnid] = str_to_float(parseConfig(wpnid, "knockback"))
            cvar_dmgmultiplier[wpnid] = str_to_float(parseConfig(wpnid, "damage"))
            cvar_speed[wpnid] = str_to_float(parseConfig(wpnid, "speed"))
            cvar_speed2[wpnid] = str_to_float(parseConfig(wpnid, "speed2"))
            cvar_jumppower[wpnid] = str_to_float(parseConfig(wpnid, "jump_power"))
            cvar_jumpgravity[wpnid] = str_to_float(parseConfig(wpnid, "jump_gravity"))
            cvar_fastrun[wpnid] = str_to_float(parseConfig(wpnid, "fastrun"))
        }
    }
}

public plugin_startup() {
    new _knifes_File[100] = { "addons/amxmodx/configs/nst_weapons/nst_knifes.ini" }

    if (!file_exists(_knifes_File)) {
        new log_file[999]
        formatex(log_file[0], charsmax(log_file) - 0, "%L", LANG_PLAYER, "FILE_NOT_LOADED")
        replace(log_file, 999, "$", "./.../nst_knifes.ini")

        server_print("[NST Weapons] %s", log_file)
        brokenConfig = 1

        return
    }

    Knifes_Number = ArrayCreate(1)
    Knife_Names = ArrayCreate(64)
    Knife_InfoText = ArrayCreate(128)

    readConfig()
    readConfigSections()

    if (configSyntax() == -1) {
        new log_file[999]
        formatex(log_file[0], charsmax(log_file) - 0, "%L", LANG_PLAYER, "BROKEN_CONFIG")
        replace(log_file, 999, "$", "./.../nst_knifes.ini")

        server_print("[NST Weapons] %s", log_file)
        brokenConfig = 1

        return;
    }
}

public readConfigSections() {
    new sectionNumber = 0
    new temp[64]

    for (new i = 0; i < ArraySize(Knife_InfoText); i++) {
        if (i == 0) {
            ArrayPushString(Knife_Names, temp)
            ArrayPushCell(Knifes_Number, sectionNumber)
            i++;
        }

        ArrayGetString(Knife_InfoText, sectionNumber, temp, charsmax(temp))
        replace(temp, 999, "[", "")
        replace(temp, 999, "]", "")
        replace(temp, 999, "^n", "")
        ArrayPushString(Knife_Names, temp)
        ArrayPushCell(Knifes_Number, sectionNumber)

        if (ArraySize(Knife_InfoText) > sectionNumber + NEXT_SECTION) {
            sectionNumber = sectionNumber + NEXT_SECTION
        } else {
            i = ArraySize(Knife_InfoText)
        }
    }

    sectionNumber = 0
}

public config_error_log() {
    new _knifes_File[100] = { "addons/amxmodx/configs/nst_weapons/nst_knifes.ini" }
    new log_msg[999]
    formatex(log_msg[0], charsmax(log_msg) - 0, "%L", LANG_PLAYER, (!file_exists(_knifes_File)) ? "FILE_NOT_LOADED" : "BROKEN_CONFIG")
    replace(log_msg, 999, "$", "./.../nst_knifes.ini")

    server_print("[NST Weapons] %s", log_msg)
    brokenConfig = 1
    return;
}

public readConfig() {
    new buffer[128]
    new left_comment[128], right_comment[128], left_s_comment[128], right_s_comment[128]

    new fKnifes = fopen("addons/amxmodx/configs/nst_weapons/nst_knifes.ini", "r")
    while (!feof(fKnifes)) {
        fgets(fKnifes, buffer, charsmax(buffer))

        //Comment Line Remover
        strtok(buffer, left_comment, 128, right_comment, 128, ';')
        format(right_comment, 128, ";%s", right_comment)
        str_replace(buffer, 128, right_comment, "_THIS_IS_COMMENT_LINE_")

        //Comment Line Remover 2
        strtok(buffer, left_s_comment, 128, right_s_comment, 128, ']')
        if (!equali(right_s_comment, "")) {
            str_replace(buffer, 128, right_s_comment, "")
        }

        ArrayPushString(Knife_InfoText, buffer)

        for (new i = 0; i < ArraySize(Knife_InfoText); i++) {
            new temp[128]
            ArrayGetString(Knife_InfoText, i, temp, charsmax(temp))
            if (equali(temp, "_THIS_IS_COMMENT_LINE_")) {
                ArrayDeleteItem(Knife_InfoText, i)
            }
        }
    }

    fclose(fKnifes)
}

stock parseConfig(const strKey, const Property[]) {
    const administrator = 1
    const cost = 2
    const damage = 3
    const deploy = 4
    const speed = 5
    const speed2 = 6
    const knockback = 7
    const fastrun = 8
    const jump_power = 9
    const jump_gravity = 10
    const sound_deploy = 11
    const sound_hit1 = 12
    const sound_hit2 = 13
    const sound_hit3 = 14
    const sound_hit4 = 15
    const sound_hitwall = 16
    const sound_slash1 = 17
    const sound_slash2 = 18
    const sound_stab = 19
    const v_model = 20
    const p_model = 21
    const w_model = 22

    new parserLine[128]
    new rightValue[128], leftValue[32]

    new PropertyNumber

    if (equali(Property, "administrator")) {
        PropertyNumber = administrator
    }

    if (equali(Property, "cost")) {
        PropertyNumber = cost
    }

    if (equali(Property, "damage")) {
        PropertyNumber = damage
    }

    if (equali(Property, "deploy")) {
        PropertyNumber = deploy
    }

    if (equali(Property, "speed")) {
        PropertyNumber = speed
    }

    if (equali(Property, "speed2")) {
        PropertyNumber = speed2
    }

    if (equali(Property, "knockback")) {
        PropertyNumber = knockback
    }

    if (equali(Property, "jump_power")) {
        PropertyNumber = jump_power
    }

    if (equali(Property, "jump_gravity")) {
        PropertyNumber = jump_gravity
    }

    if (equali(Property, "fastrun")) {
        PropertyNumber = fastrun
    }

    if (equali(Property, "sound_deploy")) {
        PropertyNumber = sound_deploy
    }

    if (equali(Property, "sound_hit1")) {
        PropertyNumber = sound_hit1
    }

    if (equali(Property, "sound_hit2")) {
        PropertyNumber = sound_hit2
    }

    if (equali(Property, "sound_hit3")) {
        PropertyNumber = sound_hit3
    }

    if (equali(Property, "sound_hit4")) {
        PropertyNumber = sound_hit4
    }

    if (equali(Property, "sound_hitwall")) {
        PropertyNumber = sound_hitwall
    }

    if (equali(Property, "sound_slash1")) {
        PropertyNumber = sound_slash1
    }

    if (equali(Property, "sound_slash2")) {
        PropertyNumber = sound_slash2
    }

    if (equali(Property, "sound_stab")) {
        PropertyNumber = sound_stab
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

    ArrayGetString(Knife_InfoText, ArrayGetCell(Knifes_Number, strKey) + PropertyNumber, parserLine, charsmax(parserLine))
    strtok(parserLine, leftValue, 64, rightValue, 127, '=')
    trim(leftValue);
    trim(rightValue);

    return rightValue
}

stock configSyntax() {
    new temp[128]

    for (new i = 0; i < ArraySize(Knife_Names); i++) {
        if (!equali(parseConfig(i, "administrator"), "0")) {
            if (!equali(parseConfig(i, "administrator"), "1")) {
                return -1;
            }
        }
        formatex(temp, charsmax(temp), "%s", parseConfig(i, "cost"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "damage"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "deploy"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "speed"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "speed2"))

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

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "jump_power"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        formatex(temp, charsmax(temp), "%s", parseConfig(i, "jump_gravity"))

        if (!isdigit(temp[0])) {
            return -1;
        }

        if (!contain(parseConfig(i, "sound_deploy"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_hit1"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_hit2"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_hit3"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_hit4"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_hitwall"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_slash1"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_slash2"), ".wav")) {
            return -1
        }

        if (!contain(parseConfig(i, "sound_stab"), ".wav")) {
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
    }

    return 0;
}

stock create_velocity_vector(victim, attacker, Float: velocity[3], Float: knockback) {
    if (!is_user_alive(attacker)) {
        return 0;
    }

    if (!is_valid_ent(attacker)) {
        return 0;
    }

    new Float: victim_origin[3], Float: attacker_origin[3], Float: new_origin[3];

    entity_get_vector(victim, EV_VEC_origin, victim_origin);
    entity_get_vector(attacker, EV_VEC_origin, attacker_origin);

    new_origin[0] = victim_origin[0] - attacker_origin[0];
    new_origin[1] = victim_origin[1] - attacker_origin[1];

    velocity[0] = (new_origin[0] * (knockback * 900)) / get_entity_distance(victim, attacker);
    velocity[1] = (new_origin[1] * (knockback * 900)) / get_entity_distance(victim, attacker);

    return 1;
}

stock set_weapon_timeidle(client, Float: TimeIdle) {
    if (!is_user_alive(client)) {
        return
    }

    static entity;
    entity = fm_get_user_weapon_entity(client, CSW_KNIFE)

    if (!pev_valid(entity)) {
        return
    }

    set_pdata_float(entity, m_flNextPrimaryAttack, TimeIdle, 4)
    set_pdata_float(entity, m_flNextSecondaryAttack, TimeIdle, 4)
    set_pdata_float(entity, m_flTimeWeaponIdle, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(client, Float: nexttime) {
    if (!is_user_alive(client)) {
        return
    }

    set_pdata_float(client, 83, nexttime, 5)
}

stock format_knife_sound(wpn_id, const config_sound[]) {
    new formatted_sound[512]
    formatex(formatted_sound, charsmax(formatted_sound), "weapons/%s", parseConfig(wpn_id, config_sound))

    return formatted_sound
}

public NST_Knife(client) {
    new temp[64]
    new menu[512], menuxx
    new text[256], len = 0
    new administrator
    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "Get_NSTMelee")

    if (brokenConfig == 0 && commencing == 0) {
        for (new i = 1; i < ArraySize(Knife_Names); i++) {
            administrator = str_to_num(parseConfig(i, "administrator"))
            new menuKey[64]
            ArrayGetString(Knife_Names, i, temp, charsmax(temp))

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

public Get_NSTMelee(client, menu, item) {
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
        new user_money = get_user_money(client)
        new wp_cost = cvar_cost[wpnid]
        new administrator = cvar_administrator[wpnid]

        if (!(get_user_flags(client) & ADMIN_KICK) && administrator == 1) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ACCESS_DENIED_BUY")
        } else if (!is_user_alive(client)) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "NOT_LIVE")
        } else if (get_gametime() - round_time > get_cvar_num("nst_buy_time")) {
            engclient_print(client, engprint_center, "%L", LANG_PLAYER, "BUY_TIME_END", get_cvar_num("nst_buy_time"));
        } else if (HAS_WEAPON[client] == wpnid) {
            new temp[256]
            ArrayGetString(Knife_Names, HAS_WEAPON[client], temp, charsmax(temp))

            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ALREADY_HAVE", temp)
        } else if (get_cvar_num("nst_free") ? true : (wp_cost <= get_user_money(client))) {
            CURRENT_WEAPON[client] = wpnid
            HAS_WEAPON[client] = wpnid
            Current_Weapon(client)

            client_cmd(0, "spk sound/items/gunpickup2.wav")

            if (get_cvar_num("nst_free") == 0) {
                set_user_money(client, user_money + -wp_cost)
            }
        } else {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "INSUFFICIENT_MONEY")
        }
    }
}

public ReBuy_Knife(client) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    new wpnid = CURRENT_WEAPON[client]
    if (wpnid > 0) {
        Buy_Weapon(client, wpnid)
    }

    return PLUGIN_HANDLED
}

public Current_Weapon(client) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]

    new clip, ammo
    new wpn_id = get_user_weapon(client, clip, ammo)

    if (wpn_id == CSW_KNIFE && HAS_WEAPON[client]) {
        new v_model[999], p_model[999]
        formatex(v_model, charsmax(v_model), "models/%s", parseConfig(CURRENT_WEAPON, "v_model"))
        formatex(p_model, charsmax(p_model), "models/%s", parseConfig(CURRENT_WEAPON, "p_model"))

        set_pev(client, pev_viewmodel2, v_model)
        set_pev(client, pev_weaponmodel2, p_model)
    }

    return PLUGIN_HANDLED
}

public Primary_Attack_Post(entity) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    if (!is_valid_ent(entity)) {
        return HAM_IGNORED
    }

    new client = pev(entity, pev_owner)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new wpn_id = get_user_weapon(client, _, _)

    if (wpn_id == CSW_KNIFE && HAS_WEAPON[client]) {
        set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON], 4)
    }

    return FMRES_SUPERCEDE
}

public Secondary_Attack_Post(entity) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    if (!is_valid_ent(entity)) {
        return HAM_IGNORED
    }

    new client = pev(entity, pev_owner)
    new CURRENT_WEAPON = HAS_WEAPON[client]

    if (HAS_WEAPON[client]) {
        set_pdata_float(entity, m_flNextSecondaryAttack, cvar_speed2[CURRENT_WEAPON], 4)
    }

    return FMRES_SUPERCEDE
}

public Weapon_Deploy_Post(entity) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4);

    new CURRENT_WEAPON = HAS_WEAPON[client]

    if (!pev_valid(entity)) {
        return HAM_IGNORED;
    }

    if (!is_user_alive(client)) {
        return HAM_IGNORED;
    }

    if (HAS_WEAPON[client]) {
        emit_sound(client, CHAN_WEAPON, format_knife_sound(CURRENT_WEAPON, "sound_deploy"), VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
        set_weapon_timeidle(client, cvar_deploy[CURRENT_WEAPON])
        set_player_nextattack(client, cvar_deploy[CURRENT_WEAPON])
    }

    return HAM_IGNORED
}

public fw_EmitSound(entity, channel, sound[], Float: volume, Float: attenuation, fFlags, pitch) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(entity)) {
        return FMRES_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[entity]
    new wpn_id = get_user_weapon(entity, _, _)

    if (wpn_id != CSW_KNIFE || !HAS_WEAPON[entity]) {
        return PLUGIN_HANDLED
    }

    if (equali(sound, "weapons/knife_hit1.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit1"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    if (equali(sound, "weapons/knife_hit2.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit2"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    if (equali(sound, "weapons/knife_hit3.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit3"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    if (equali(sound, "weapons/knife_hit4.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit4"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    if (equali(sound, "weapons/knife_hitwall1.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hitwall"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    if (equali(sound, "weapons/knife_slash1.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_slash1"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    if (equali(sound, "weapons/knife_slash2.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_slash2"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    if (equali(sound, "weapons/knife_stab.wav")) {
        emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_stab"), volume, attenuation, fFlags, pitch)
        return FMRES_SUPERCEDE
    }

    return FMRES_IGNORED
}

public fw_PlayerPreThink(client) {
    if (brokenConfig != 0) {
        return PLUGIN_HANDLED
    }

    if (!is_user_alive(client)) {
        return FMRES_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new wpn_id = get_user_weapon(client, _, _)

    if (wpn_id == CSW_KNIFE && HAS_WEAPON[client]) {
        entity_set_float(client, EV_FL_maxspeed, 240.0 + cvar_fastrun[CURRENT_WEAPON])

        if ((pev(client, pev_button) & IN_JUMP) && !(pev(client, pev_oldbuttons) & IN_JUMP)) {
            new flags = pev(client, pev_flags)
            new waterlvl = pev(client, pev_waterlevel)

            if (!(flags & FL_ONGROUND)) {
                return FMRES_IGNORED
            }

            if (flags & FL_WATERJUMP) {
                return FMRES_IGNORED
            }

            if (waterlvl > 1) {
                return FMRES_IGNORED
            }

            new Float:fVelocity[3]
            pev(client, pev_velocity, fVelocity)

            fVelocity[2] += cvar_jumppower[CURRENT_WEAPON]

            set_pev(client, pev_velocity, fVelocity)
            set_pev(client, pev_gaitsequence, 6)
            set_user_gravity(client, cvar_jumpgravity[CURRENT_WEAPON])
            Set_BitVar(IN_BITVAR_JUMP, client)
        }
    }

    if ((pev(client, pev_button) & IN_JUMP) && !(pev(client, pev_oldbuttons) & IN_JUMP)) {

    } else {
        if (Get_BitVar(IN_BITVAR_JUMP, client)) {
            if ((pev(client, pev_flags) & FL_ONGROUND)) {
                set_user_gravity(client, 1.0)
                UnSet_BitVar(IN_BITVAR_JUMP, client)
            }
        }
    }

    return FMRES_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float: damage) {
    if (brokenConfig != 0) {
        return
    }

    if (!is_valid_ent(attacker)) {
        return
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new wpn_id = get_user_weapon(attacker)

    if (wpn_id != CSW_KNIFE || !HAS_WEAPON[attacker]) {
        return
    }

    SetHamParamFloat(4, damage * cvar_dmgmultiplier[CURRENT_WEAPON])
}

public client_putinserver(client) {
    if (brokenConfig != 0) {
        return
    }

    if (is_user_bot(client)) {
        set_task(0.1, "Do_RegisterHam_Bot", client)
    }
}

public event_commencing() {
    commencing = 1

    new id = read_data(2)

    if (HAS_WEAPON[id]) {
        HAS_WEAPON[id] = 0
        return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
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

    if (weapon == CSW_KNIFE && HAS_WEAPON[attacker]) {
        new Float: vector[3]
        new Float: old_velocity[3]
        get_user_velocity(client, old_velocity)
        create_velocity_vector(client, attacker, vector, cvar_knockback[CURRENT_WEAPON])
        vector[0] += old_velocity[0]
        vector[1] += old_velocity[1]
        set_user_velocity(client, vector)
    }

    return PLUGIN_CONTINUE;
}

public event_death() {
    new id = read_data(2)

    if (HAS_WEAPON[id]) {
        HAS_WEAPON[id] = 0
        return PLUGIN_HANDLED
    }

    return PLUGIN_CONTINUE
}

public event_start_freezetime() {
    commencing = 0
}

public event_new_round() {
    round_time = get_gametime()
}

public Do_RegisterHam_Bot(client) {
    if (brokenConfig != 0) {
        return
    }

    if (!is_valid_ent(client)) {
        return
    }

    RegisterHamFromEntity(Ham_TakeDamage, client, "fw_TakeDamage")
}
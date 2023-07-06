#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta_util>
#include <string_stocks>

#define PLUGIN "NST Melee Weapons"
#define VERSION "1.2.1"
#define AUTHOR "github.com/kruz1337"

const m_pPlayer = 41
const m_flNextAttack = 83
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47
const m_flTimeWeaponIdle = 48

const MAX_WPN = 40
const MAX_PLAYER = 32
const NEXT_SECTION = 25 - 1
const MAX_ARRAYSIZE = 64

new HAS_WEAPON[MAX_PLAYER], CURRENT_WEAPON[MAX_PLAYER]
new Float: PLAYER_GRAVITY[MAX_PLAYER]

new Array:Knife_InfoText
new Array:Knife_Names

new bool:IsConfigBroken = false
new bool:IsInCommencing = false
new Float: gameTime

new Float: cvar_deploy[MAX_WPN + 1]
new Float: cvar_knockback[MAX_WPN + 1]
new Float: cvar_dmgmultiplier[MAX_WPN + 1]
new Float: cvar_speed[MAX_WPN + 1]
new Float: cvar_speed2[MAX_WPN + 1]
new Float: cvar_jumppower[MAX_WPN + 1]
new Float: cvar_gravity[MAX_WPN + 1]
new Float: cvar_fastrun[MAX_WPN + 1]

new cvar_cost[MAX_WPN + 1]
new cvar_administrator[MAX_WPN + 1]
new cvar_buycvar[MAX_WPN + 1][MAX_ARRAYSIZE]

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("nst_weapons.txt")

    register_concmd("nst_melee_rebuy", "ReBuy_Weapon")
    register_clcmd("nst_menu_type7", "NST_Melee")
    register_clcmd("nst_melee_rebuy", "NST_Buy_Convar")

    register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
    register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")
    register_event("Damage", "Event_Damage", "b", "2>0")
    register_event("DeathMsg", "Event_Death", "a")
    register_event("TextMsg", "Event_Commencing", "a", "2=#Game_Commencing", "2=#Game_End", "2=#Game_will_restart_in")

    register_forward(FM_EmitSound, "fw_EmitSound")
    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

    RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Pre")
    RegisterHam(Ham_Item_Deploy, "weapon_knife", "Weapon_Deploy_Post", 1)
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Primary_Attack_Post", 1)
    RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "Secondary_Attack_Post", 1)
}

public plugin_precache() {
    plugin_startup()

    if (IsConfigBroken) {
        return
    }

    for (new wpnId = 1; wpnId < ArraySize(Knife_Names); wpnId++) {
        new v_model[128], p_model[128], w_model[128]
        formatex(v_model, charsmax(v_model), "models/%s", ParseConfig(wpnId, "v_model"))
        formatex(p_model, charsmax(p_model), "models/%s", ParseConfig(wpnId, "p_model"))
        formatex(w_model, charsmax(w_model), "models/%s", ParseConfig(wpnId, "w_model"))

        precache_model(v_model)
        precache_model(p_model)
        precache_model(w_model)

        new hitwall[128], deploy[128], stab[128]
        new hit1[128], hit2[128], hit3[128], hit4[128]
        new slash1[128], slash2[128]

        formatex(hitwall, charsmax(hitwall), "weapons/%s", ParseConfig(wpnId, "sound_hitwall"))
        formatex(deploy, charsmax(deploy), "weapons/%s", ParseConfig(wpnId, "sound_deploy"))
        formatex(stab, charsmax(stab), "weapons/%s", ParseConfig(wpnId, "sound_stab"))
        formatex(slash1, charsmax(slash1), "weapons/%s", ParseConfig(wpnId, "sound_slash1"))
        formatex(slash2, charsmax(slash2), "weapons/%s", ParseConfig(wpnId, "sound_slash2"))
        formatex(hit1, charsmax(hit1), "weapons/%s", ParseConfig(wpnId, "sound_hit1"))
        formatex(hit2, charsmax(hit2), "weapons/%s", ParseConfig(wpnId, "sound_hit2"))
        formatex(hit3, charsmax(hit3), "weapons/%s", ParseConfig(wpnId, "sound_hit3"))
        formatex(hit4, charsmax(hit4), "weapons/%s", ParseConfig(wpnId, "sound_hit4"))

        if (strlen(ParseConfig(wpnId, "sound_hitwall"))) {
            precache_sound(hitwall)
        }
        if (strlen(ParseConfig(wpnId, "sound_deploy"))) {
            precache_sound(deploy)
        }
        if (strlen(ParseConfig(wpnId, "sound_stab"))) {
            precache_sound(stab)
        }
        if (strlen(ParseConfig(wpnId, "sound_slash1"))) {
            precache_sound(slash1)
        }
        if (strlen(ParseConfig(wpnId, "sound_slash2"))) {
            precache_sound(slash2)
        }
        if (strlen(ParseConfig(wpnId, "sound_hit1"))) {
            precache_sound(hit1)
        }
        if (strlen(ParseConfig(wpnId, "sound_hit2"))) {
            precache_sound(hit2)
        }
        if (strlen(ParseConfig(wpnId, "sound_hit3"))) {
            precache_sound(hit3)
        }
        if (strlen(ParseConfig(wpnId, "sound_hit4"))) {
            precache_sound(hit4)
        }

        new name[64]
        ArrayGetString(Knife_Names, wpnId, name, charsmax(name))

        replace_all(name, charsmax(name), "-", "")
        replace_all(name, charsmax(name), "(", "")
        replace_all(name, charsmax(name), ")", "")
        replace_all(name, charsmax(name), " ", "")
        trim(name)
        strtolower(name)

        format(cvar_buycvar[wpnId], MAX_ARRAYSIZE, "%s", ParseConfig(wpnId, "buycvar"))

        cvar_cost[wpnId] = str_to_num(ParseConfig(wpnId, "cost"))
        cvar_administrator[wpnId] = str_to_num(ParseConfig(wpnId, "administrator"))
        cvar_deploy[wpnId] = str_to_float(ParseConfig(wpnId, "deploy"))
        cvar_knockback[wpnId] = str_to_float(ParseConfig(wpnId, "knockback"))
        cvar_dmgmultiplier[wpnId] = str_to_float(ParseConfig(wpnId, "damage"))
        cvar_speed[wpnId] = str_to_float(ParseConfig(wpnId, "speed"))
        cvar_speed2[wpnId] = str_to_float(ParseConfig(wpnId, "speed2"))
        cvar_jumppower[wpnId] = str_to_float(ParseConfig(wpnId, "jump_power"))
        cvar_gravity[wpnId] = str_to_float(ParseConfig(wpnId, "gravity"))
        cvar_fastrun[wpnId] = str_to_float(ParseConfig(wpnId, "fastrun"))
    }
}

public plugin_startup() {
    new knifesFile[128] = { "addons/amxmodx/configs/nst_weapons/nst_melee.ini" }
    IsConfigBroken = !file_exists(knifesFile)

    if (IsConfigBroken) {
        new log[256]
        formatex(log[0], charsmax(log) - 0, "%L", LANG_PLAYER, "FILE_NOT_LOADED", "../nst_weapons/nst_melee.ini")
        server_print("[NST Weapons] %s", log)
        return
    }

    Knife_InfoText = ArrayCreate(128)
    Knife_Names = ArrayCreate(64)

    ReadConfig()
    ReadConfigSections()

    new exceptionLine = 0
    IsConfigBroken = !CheckConfigSyntax(exceptionLine)

    if (IsConfigBroken) {
        new log[256]
        formatex(log[0], charsmax(log) - 0, "%L", LANG_PLAYER, "BROKEN_CONFIG", "../nst_weapons/nst_melee.ini", exceptionLine)
        server_print("[NST Weapons] %s", log)
        return
    }
}

ReadConfigSections() {
    new sectionNumber = 0
    new buffer[64]

    ArrayPushString(Knife_Names, "")

    for (new i = 0; i < ArraySize(Knife_InfoText) / NEXT_SECTION && i < MAX_WPN; i++) {
        ArrayGetString(Knife_InfoText, sectionNumber, buffer, charsmax(buffer))
        replace(buffer, charsmax(buffer), "[", "")
        replace(buffer, charsmax(buffer), "]", "")
        replace(buffer, charsmax(buffer), "^n", "")
        ArrayPushString(Knife_Names, buffer)
        sectionNumber = ArraySize(Knife_InfoText) > sectionNumber + NEXT_SECTION ? sectionNumber + NEXT_SECTION : ArraySize(Knife_InfoText)
    }

    sectionNumber = 0
}

ReadConfig() {
    new buffer[256]
    new left_comment[256], right_comment[256], left_s_comment[256], right_s_comment[256]

    new knifesFile = fopen("addons/amxmodx/configs/nst_weapons/nst_melee.ini", "r")
    while (!feof(knifesFile)) {
        fgets(knifesFile, buffer, charsmax(buffer))

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
            ArrayPushString(Knife_InfoText, buffer)
        }
    }

    for (new i = 0; i < ArraySize(Knife_InfoText); i++) {
        new commentBuffer[256]
        ArrayGetString(Knife_InfoText, i, commentBuffer, charsmax(commentBuffer))

        if (equali(commentBuffer, "COMMENT_LINE")) {
            ArrayDeleteItem(Knife_InfoText, i)
        }
    }

    fclose(knifesFile)
}

ParseConfig(const wpnId, const Property[], & syntaxLine = 0) {
    const administrator = 1
    const cost = 2
    const damage = 3
    const deploy = 4
    const speed = 5
    const speed2 = 6
    const knockback = 7
    const fastrun = 8
    const jump_power = 9
    const gravity = 10
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
    const buycvar = 23

    new propertyLine

    if (equali(Property, "administrator")) {
        propertyLine = administrator
    } else if (equali(Property, "cost")) {
        propertyLine = cost
    } else if (equali(Property, "damage")) {
        propertyLine = damage
    } else if (equali(Property, "deploy")) {
        propertyLine = deploy
    } else if (equali(Property, "speed")) {
        propertyLine = speed
    } else if (equali(Property, "speed2")) {
        propertyLine = speed2
    } else if (equali(Property, "knockback")) {
        propertyLine = knockback
    } else if (equali(Property, "jump_power")) {
        propertyLine = jump_power
    } else if (equali(Property, "gravity")) {
        propertyLine = gravity
    } else if (equali(Property, "fastrun")) {
        propertyLine = fastrun
    } else if (equali(Property, "sound_deploy")) {
        propertyLine = sound_deploy
    } else if (equali(Property, "sound_hit1")) {
        propertyLine = sound_hit1
    } else if (equali(Property, "sound_hit2")) {
        propertyLine = sound_hit2
    } else if (equali(Property, "sound_hit3")) {
        propertyLine = sound_hit3
    } else if (equali(Property, "sound_hit4")) {
        propertyLine = sound_hit4
    } else if (equali(Property, "sound_hitwall")) {
        propertyLine = sound_hitwall
    } else if (equali(Property, "sound_slash1")) {
        propertyLine = sound_slash1
    } else if (equali(Property, "sound_slash2")) {
        propertyLine = sound_slash2
    } else if (equali(Property, "sound_stab")) {
        propertyLine = sound_stab
    } else if (equali(Property, "v_model")) {
        propertyLine = v_model
    } else if (equali(Property, "p_model")) {
        propertyLine = p_model
    } else if (equali(Property, "w_model")) {
        propertyLine = w_model
    } else if (equali(Property, "buycvar")) {
        propertyLine = buycvar
    }

    new parseLine[128]
    new field[128], value[128]
    new fieldLineNumber = max((wpnId * NEXT_SECTION) - NEXT_SECTION + propertyLine, 0)

    ArrayGetString(Knife_InfoText, fieldLineNumber, parseLine, charsmax(parseLine))
    strtok(parseLine, field, charsmax(field), value, charsmax(value), '=')
    trim(value)

    syntaxLine = fieldLineNumber + 1

    return value
}

bool:CheckConfigSyntax( & exceptionLine) {
    new buffer[128]

    for (new i = 1; i < ArraySize(Knife_Names); i++) {
        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "administrator", exceptionLine))
        if (!equali(buffer, "0") && !equali(buffer, "1")) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "cost", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "damage", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "deploy", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "speed", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "speed2", exceptionLine))
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

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "jump_power", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "gravity", exceptionLine))
        if (!isdigit(buffer[0])) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_deploy", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_hit1", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_hit2", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_hit3", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_hit4", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_hitwall", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_slash1", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_slash2", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
        }

        formatex(buffer, charsmax(buffer), "%s", ParseConfig(i, "sound_stab", exceptionLine))
        if (contain(buffer, ".wav") == -1) {
            return false
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
    }

    exceptionLine = 0
    return true
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

SetWeaponTime(client, Float: TimeIdle) {
    if (!is_user_alive(client)) {
        return
    }

    static entity
    entity = fm_get_user_weapon_entity(client, CSW_KNIFE)

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

GetCustomKnifeSound(wpnId, const soundName[]) {
    new sound[64]
    if (strlen(ParseConfig(wpnId, soundName))) {
        formatex(sound, charsmax(sound), "weapons/%s", ParseConfig(wpnId, soundName))
    }

    return sound
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
        new administrator = cvar_administrator[wpnId]

        if (!(get_user_flags(client) & ADMIN_KICK) && administrator == 1) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ACCESS_DENIED_BUY")
        } else if (!is_user_alive(client)) {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "NOT_LIVE")
        } else if (get_gametime() - gameTime > get_cvar_num("nst_buy_time")) {
            engclient_print(client, engprint_center, "%L", LANG_PLAYER, "BUY_TIME_END", get_cvar_num("nst_buy_time"))
        } else if (HAS_WEAPON[client] == wpnId) {
            new buffer[256]
            ArrayGetString(Knife_Names, HAS_WEAPON[client], buffer, charsmax(buffer))

            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ALREADY_HAVE", buffer)
        } else if (get_cvar_num("nst_free") ? true : (wp_cost <= cs_get_user_money(client))) {
            CURRENT_WEAPON[client] = wpnId
            HAS_WEAPON[client] = wpnId
            Event_CurrentWeapon(client)

            client_cmd(0, "spk sound/items/gunpickup2.wav")

            if (get_cvar_num("nst_free") == 0) {
                cs_set_user_money(client, user_money + -wp_cost)
            }
        } else {
            client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "INSUFFICIENT_MONEY")
        }
    }
}

public NST_Melee(client) {
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

    for (new i = 1; i < ArraySize(Knife_Names); i++) {
        new administrator = str_to_num(ParseConfig(i, "administrator"))

        new title[64]
        ArrayGetString(Knife_Names, i, title, charsmax(title))

        new menuKey[64]
        formatex(menu, charsmax(menu), administrator == 0 ? "%s 	\r$%s" : "\y%s 	\r$%s", title, ParseConfig(i, "cost"))
        num_to_str(i + 1, menuKey, 999)
        menu_additem(menuxx, menu, menuKey)
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
        formatex(msg, charsmax(msg), "[NST Wpn] %L", LANG_PLAYER, "BUY_COMMAND_USAGE", "nst_melee_buy")
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

public Primary_Attack_Post(entity) {
    if (IsConfigBroken || !is_valid_ent(entity)) {
        return HAM_IGNORED
    }

    static client
    client = pev(entity, pev_owner)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new wpnId = get_user_weapon(client)

    if (wpnId != CSW_KNIFE || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    if (cvar_speed[CURRENT_WEAPON] != 0) {
        set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON], 4)
    }

    return HAM_HANDLED
}

public Secondary_Attack_Post(entity) {
    if (IsConfigBroken || !is_valid_ent(entity)) {
        return HAM_IGNORED
    }

    static client
    client = pev(entity, pev_owner)

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new wpnId = get_user_weapon(client)

    if (wpnId != CSW_KNIFE || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    if (cvar_speed2[CURRENT_WEAPON] != 0) {
        set_pdata_float(entity, m_flNextSecondaryAttack, cvar_speed2[CURRENT_WEAPON], 4)
    }

    return HAM_HANDLED
}

public Weapon_Deploy_Post(entity) {
    if (IsConfigBroken || !pev_valid(entity)) {
        return HAM_IGNORED
    }

    static client
    client = get_pdata_cbase(entity, m_pPlayer, 4)

    if (!is_user_alive(client)) {
        return HAM_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new wpnId = get_user_weapon(client)

    if (wpnId != CSW_KNIFE || !CURRENT_WEAPON) {
        return HAM_IGNORED
    }

    if (strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_deploy"))) {
        emit_sound(client, CHAN_WEAPON, GetCustomKnifeSound(CURRENT_WEAPON, "sound_deploy"), VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    }

    SetWeaponTime(client, cvar_deploy[CURRENT_WEAPON])
    SetWeaponNextAttack(client, cvar_deploy[CURRENT_WEAPON])

    return HAM_HANDLED
}

public Event_CurrentWeapon(client) {
    if (IsConfigBroken) {
        return PLUGIN_CONTINUE
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new wpnId = get_user_weapon(client)
    new Float: playerGravity = PLAYER_GRAVITY[client]

    if (wpnId != CSW_KNIFE || !CURRENT_WEAPON) {
        if (playerGravity) {
            set_user_gravity(client, playerGravity)
            PLAYER_GRAVITY[client] = 0.0
        }
        return PLUGIN_CONTINUE
    }

    if (!playerGravity) {
        PLAYER_GRAVITY[client] = get_user_gravity(client)
    }

    entity_set_float(client, EV_FL_maxspeed, 240.0 + cvar_fastrun[CURRENT_WEAPON])

    new Float: customGravity = cvar_gravity[CURRENT_WEAPON]
    if (customGravity) {
        set_user_gravity(client, customGravity)
    }

    new v_model[64], p_model[64]
    formatex(v_model, charsmax(v_model), "models/%s", ParseConfig(CURRENT_WEAPON, "v_model"))
    formatex(p_model, charsmax(p_model), "models/%s", ParseConfig(CURRENT_WEAPON, "p_model"))

    set_pev(client, pev_viewmodel2, v_model)
    set_pev(client, pev_weaponmodel2, p_model)

    return PLUGIN_HANDLED
}

public Ham_TakeDamage_Pre(victim, inflictor, attacker, Float: damage) {
    if (IsConfigBroken || !is_user_alive(attacker)) {
        return HAM_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]
    new wpnId = get_user_weapon(attacker)

    if (wpnId != CSW_KNIFE || !CURRENT_WEAPON) {
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

public fw_EmitSound(entity, channel, sound[], Float: volume, Float: attenuation, fFlags, pitch) {
    if (IsConfigBroken || !is_user_alive(entity)) {
        return FMRES_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[entity]
    new wpnId = get_user_weapon(entity)

    if (wpnId != CSW_KNIFE || !CURRENT_WEAPON) {
        return FMRES_IGNORED
    }

    if (equali(sound, "weapons/knife_hit1.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit1"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit1"), volume, attenuation, fFlags, pitch)
    } else if (equali(sound, "weapons/knife_hit2.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit2"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit2"), volume, attenuation, fFlags, pitch)
    } else if (equali(sound, "weapons/knife_hit3.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit3"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit3"), volume, attenuation, fFlags, pitch)
    } else if (equali(sound, "weapons/knife_hit4.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit4"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_hit4"), volume, attenuation, fFlags, pitch)
    } else if (equali(sound, "weapons/knife_hitwall1.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_hitwall"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_hitwall"), volume, attenuation, fFlags, pitch)
    } else if (equali(sound, "weapons/knife_slash1.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_slash1"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_slash1"), volume, attenuation, fFlags, pitch)
    } else if (equali(sound, "weapons/knife_slash2.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_slash2"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_slash2"), volume, attenuation, fFlags, pitch)
    } else if (equali(sound, "weapons/knife_stab.wav") && strlen(GetCustomKnifeSound(CURRENT_WEAPON, "sound_stab"))) {
        emit_sound(entity, channel, GetCustomKnifeSound(CURRENT_WEAPON, "sound_stab"), volume, attenuation, fFlags, pitch)
    } else {
        return FMRES_IGNORED
    }

    return FMRES_SUPERCEDE
}

public fw_PlayerPreThink(client) {
    if (IsConfigBroken || !is_user_alive(client)) {
        return FMRES_IGNORED
    }

    new CURRENT_WEAPON = HAS_WEAPON[client]
    new wpnId = get_user_weapon(client)

    if (wpnId != CSW_KNIFE || !CURRENT_WEAPON) {
        return FMRES_IGNORED
    }

    if (!cvar_jumppower[CURRENT_WEAPON]) {
        return FMRES_IGNORED
    }

    new flags = pev(client, pev_flags)
    new waterLevel = pev(client, pev_waterlevel)
    new currBtn = pev(client, pev_button)
    new oldBtn = pev(client, pev_oldbuttons)

    if (!(currBtn & IN_JUMP) ||
        (oldBtn & IN_JUMP)) {
        return FMRES_IGNORED
    }

    if (!(flags & FL_ONGROUND) ||
        flags & FL_WATERJUMP ||
        waterLevel > 1) {
        return FMRES_IGNORED
    }

    new Float: velocity[3]
    pev(client, pev_velocity, velocity)

    velocity[2] = cvar_jumppower[CURRENT_WEAPON]

    set_pev(client, pev_velocity, velocity)
    set_pev(client, pev_gaitsequence, 6)

    return FMRES_HANDLED
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

    return PLUGIN_HANDLED
}

public Event_Damage(client) {
    if (IsConfigBroken) {
        return PLUGIN_CONTINUE
    }

    new weapon, attacker = get_user_attacker(client, weapon)
    if (!is_user_alive(attacker)) {
        return PLUGIN_CONTINUE
    }

    new CURRENT_WEAPON = HAS_WEAPON[attacker]

    if (weapon != CSW_KNIFE || !CURRENT_WEAPON) {
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

    new random_weapon_id = random_num(0, ArraySize(Knife_Names) - 1)
    if (random_weapon_id != 0) {
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
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <hlsdk_const>
#include <fakemeta>
#include <fun>
#include <engine>
#include <fakemeta_util>
#include <regex>

#define PLUGIN "NST Weapons"
#define VERSION "1.3"
#define AUTHOR "github.com/kruz1337"

new auto_buy_enabled[33]

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    register_dictionary("nst_weapons.txt")

    register_concmd("nst_menu", "nstmenu")
    register_cvar("nst_free", "0")
    register_cvar("nst_use_buyzone", "1")
    register_cvar("nst_buy_time", "60")
    register_cvar("nst_give_bot", "1")
    register_cvar("nst_zoom_spk", "1")

    RegisterHam(Ham_Spawn, "player", "player_spawn", 1)

    BrokenConfig()
}

/* Default Menu */
public nstmenu(client) {
    new menu[512], menuxx
    new text[256], len = 0

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "nstmenu_next")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_ITEM1")
    menu_additem(menuxx, menu, "1")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_ITEM2")
    menu_additem(menuxx, menu, "2")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_ITEM3")
    menu_additem(menuxx, menu, "3")

    formatex(menu, charsmax(menu), "%L^n", LANG_PLAYER, "MENU_ITEM4")
    menu_additem(menuxx, menu, "4")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_ITEM5")
    menu_additem(menuxx, menu, "5")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_ITEM6")
    menu_additem(menuxx, menu, "6")

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT");
    menu_setprop(menuxx, MPROP_NEXTNAME, text)

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK");
    menu_setprop(menuxx, MPROP_BACKNAME, text)

    menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")

    //Show Menu
    if (is_user_alive(client)) {
        menu_display(client, menuxx, 0)
    } else {
        client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
    }

    return PLUGIN_HANDLED
}

public nstmenu_next(client, menu, item) {
    switch (item) {
        case 0 :  {
            nstwpn_primary(client)
        }
        case 1 :  {
            client_cmd(client, "nst_menu_type1")
        }
        case 2 :  {
            client_cmd(client, "nst_menu_type7")
        }
        case 3 :  {

        }
        case 4 :  {
            client_cmd(client, "nst_rifle_rebuy")
            client_cmd(client, "nst_pistol_rebuy")
            client_cmd(client, "nst_knife_rebuy")
        }
        case 5 :  {
            auto_buy_enabled[client] = !auto_buy_enabled[client]

            if (!auto_buy_enabled[client]) {
                client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "AUTO_BUY_DISABLED")
            } else {
                client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "AUTO_BUY_ENABLED")
            }
        }
    }

    if (item == MPROP_EXIT) {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    return PLUGIN_HANDLED
}

/* Primary Menu */
public nstwpn_primary(client) {
    new menu[512], menuxx
    new text[256], len = 0

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
    menuxx = menu_create(menu, "nstmenu_primary_next")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU2_ITEM1")
    menu_additem(menuxx, menu, "1")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU2_ITEM2")
    menu_additem(menuxx, menu, "2")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU2_ITEM3")
    menu_additem(menuxx, menu, "3")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU2_ITEM4")
    menu_additem(menuxx, menu, "4")

    formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU2_ITEM5")
    menu_additem(menuxx, menu, "5")

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
}

public nstmenu_primary_next(client, menu, item) {
    switch (item) {
        case 0 :  {
            client_cmd(client, "nst_menu_type2")
        }
        case 1 :  {
            client_cmd(client, "nst_menu_type3")
        }
        case 2 :  {
            client_cmd(client, "nst_menu_type4")
        }
        case 3 :  {
            client_cmd(client, "nst_menu_type5")
        }
        case 4 :  {
            client_cmd(client, "nst_menu_type6")
        }
        case 5 :  {
            client_cmd(client, "nst_menu_type7")
        }
    }

    if (item == MPROP_EXIT) {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    return PLUGIN_HANDLED
}

public autobuy_previous_task(client) {
    client_cmd(client, "nst_rifle_rebuy")
    client_cmd(client, "nst_pistol_rebuy")
    client_cmd(client, "nst_knife_rebuy")
}

public player_spawn(client) {
    if (!is_user_alive(client)) {
        return
    }

    if (!auto_buy_enabled[client]) {
        return
    }

    set_task(1.2, "autobuy_previous_task", client)
}

public BrokenConfig() {
    new messageTex[100], messageTex2[100]
    new const files[][] = { "addons/amxmodx/configs/nst_weapons/nst_rifles.ini", "addons/amxmodx/configs/nst_weapons/nst_pistols.ini", "addons/amxmodx/configs/nst_weapons/nst_knifes.ini" }

    formatex(messageTex[0], charsmax(messageTex) - 0, "%L", LANG_PLAYER, "FILE_NOT_LOADED")
    formatex(messageTex2[0], charsmax(messageTex2) - 0, "%L", LANG_PLAYER, "BROKEN_CONFIG")

    new hasErr = 0
    if (file_exists(files[0]) == 0) {
        replace(messageTex, 999, "$", "./.../nst_rifles.ini")
        hasErr = 1
    } else if (file_exists(files[1]) == 0) {
        replace(messageTex, 999, "$", "./.../nst_pistols.ini")
        hasErr = 1
    } else if (file_exists(files[2]) == 0) {
        replace(messageTex, 999, "$", "./.../nst_knifes.ini")
        hasErr = 1
    }

    if (hasErr == 1) {
        server_print("[NST Weapons] %s", messageTex)
    }
}
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
#include <string_stocks>
#include <fakemeta>
#include <fakemeta_stocks>

#pragma tabsize 0

#define PLUGIN "NST Secondary Weapons"
#define VERSION "1.0"
#define AUTHOR "Ҡruziikrel#6822"

/* Other Variables */
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

enum
{
	GLOCK_ANIM_IDLE1 = 0,
	GLOCK_ANIM_IDLE2,
	GLOCK_ANIM_IDLE3,
	GLOCK_ANIM_SHOOT_BURST1,
	GLOCK_ANIM_SHOOT_BURST2,
	GLOCK_ANIM_SHOOT,
	GLOCK_ANIM_SHOOT_EMPTY,
	GLOCK_ANIM_RELOAD,
	GLOCK_ANIM_DRAW,
	GLOCK_ANIM_HOLSTER,
	GLOCK_ANIM_ADD_SILENCER,
	GLOCK_ANIM_DRAW2,
	GLOCK_ANIM_RELOAD2
}

enum (+= 100)
{
    TASK_GIVEWPNBOT
}

/* Offsets */
const XTRA_OFS_PLAYER			= 5
const m_pPlayer			        = 41
const m_iId				        = 43
const m_fKnown				    = 44
const m_flNextPrimaryAttack	    = 46
const m_flNextSecondaryAttack	= 47
const m_flTimeWeaponIdle		= 48
const m_iPrimaryAmmoType		= 49
const m_iClip				    = 51
const m_fInReload			    = 54
const m_fInSpecialReload	    = 55
const m_flAccuracy              = 62
const m_fSilent			        = 74
const m_flDecreaseShotsFired    = 76
const m_flNextAttack		    = 83
const m_iFOV                    = 363
const m_rgAmmo_player_Slot0	    = 376
const m_pActiveItem             = 373

/* Arrays */
new Array: Pistol_InfoText;
new Array: Pistol_Names;
new Array: Pistol_Numbers;

/* Config Variables */
const NEXT_SECTION = 24
const END_SECTION = 22
const s_administrator = 1
const s_administrator_next = 25
const s_cost = 2
const s_cost_next = 26
const s_wpn_id = 3
const s_wpn_id_next = 27
const s_clip = 4
const s_clip_next = 28
const s_ammo = 5
const s_ammo_next = 29
const s_damage = 6
const s_damage_next = 30
const s_recoil = 7
const s_recoil_next = 31
const s_deploy = 8
const s_deploy_next = 32
const s_reload = 9
const s_reload_next = 33
const s_speed = 10
const s_speed_next = 34
const s_knockback = 11
const s_knockback_next = 35
const s_fastrun = 12
const s_fastrun_next = 36
const s_secondary_type = 13
const s_secondary_type_next = 37
const s_tracer = 14
const s_tracer_next = 38
const s_tracer_type = 15
const s_tracer_type_next = 39
const s_tracer_sprite = 16
const s_tracer_sprite_next = 40
const s_sight_recoil = 17
const s_sight_recoil_next = 41
const s_sight_model = 18
const s_sight_model_next = 42
const s_v_model = 19
const s_v_model_next = 43
const s_p_model = 20
const s_p_model_next = 44
const s_w_model = 21
const s_w_model_next = 45
const s_fire_sounds = 22
const s_fire_sounds_next = 46

/* Integers */
const MAX_WPN = 5000

new commencing = 0
new typecontrol = 0
new brokenConfig = 0
new backup_client
new HAS_WEAPON[33]
new CURRENT_WEAPON[33]
new inTwoZoom[33], inThreeZoom[33], Disable_Type_Zoom[33]

/* Weapon Variables */
new class_weapons[MAX_WPN][32]

new Float:cvar_deploy[MAX_WPN]
new Float:cvar_dmgmultiplier[MAX_WPN]
new Float:cvar_speed[MAX_WPN]
new Float:cvar_recoil[MAX_WPN]
new Float:cvar_knockback[MAX_WPN]
new Float:cvar_fastrun[MAX_WPN]
new Float:cvar_sightrecoil[MAX_WPN]

new cvar_uclip[MAX_WPN]
new cvar_secondary_type[MAX_WPN]
new cvar_clip[MAX_WPN]
new cvar_ammo[MAX_WPN]
new cvar_cost[MAX_WPN]
new cvar_administrator[MAX_WPN]
new cvar_reload[MAX_WPN]
new cvar_tracer[MAX_WPN][64]
new cvar_tracer_type[MAX_WPN]
new cvar_tracer_sprite[MAX_WPN]

new Float:Pushangle[33][3]
new Float:round_time

new SAVE_CLIP[33]
new SAVED_CLIP[33]
new IN_EMIT_ATTACK

/* Weapons Consts */
new const pistols[] = { 1, 10, 11, 16, 17, 26 }
new const weapons_ammo_id[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7}
new const weapons_max_bp_ammo[] = { -1, 52, -1, 90, -1, 32, -1, 100, 90, -1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, -1, 35, 90, 90, -1, 100 }
new const buy_AmmoCount[] = { -1 , 13, -1, 30, -1, 8, -1, 12, 30, -1, 30, 50, 12, 30, 30, 30, 12, 30, 10, 30, 30, 8, 30, 30, 30, -1, 30, 30, 30, -1, 50 }
new const buy_AmmoCost[] = { -1 , 50, -1, 80, -1, 65, -1, 25, 60, -1, 20, 50, 25, 60, 60, 60, 25, 20, 125, 20, 60, 65, 60, 20, 80, -1, 80, 60, 80, -1, 50 }

/* Old Weapon Variables */
new const weapons_old_w[][] = { "w_fiveseven", "w_elite", "w_usp", "w_p228", "w_deagle", "w_glock18" }
new const weapons_old_sounds[][] = 
{ 
    "weapons/deagle-1.wav", 
    "weapons/deagle-2.wav", 
    "weapons/elite_fire.wav", 
    "weapons/fiveseven-1.wav", 
    "weapons/glock18-1.wav", 
    "weapons/glock18-2.wav", 
    "weapons/p228-1.wav", 
    "weapons/usp1.wav",
    "weapons/usp2.wav",
}

stock const weapons_max_clip[] = {-1, 13, -1, 10, 1, 7, 1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50}
stock const Float:weapons_clip_delay[CSW_P90+1] = {0.00, 2.70, 0.00, 2.00, 0.00, 0.55, 0.00, 3.15, 3.30, 0.00, 4.50, 2.70, 3.50, 3.35, 2.45, 3.30, 2.70, 2.20, 2.50, 2.63, 4.70, 0.55, 3.05, 2.12, 3.50, 0.00, 2.20, 3.00, 2.45, 0.00, 3.40}

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("nst_weapons.txt")
	register_concmd("nst_pistol_rebuy", "ReBuy_Weapon")
	register_clcmd("nst_menu_type1", "NST_Pistols")

    register_event("HLTV", "event_new_round", "a", "1=0", "2=0" );
	register_event("HLTV", "event_start_freezetime", "a", "1=0", "2=0")
    register_event("CurWeapon", "Current_Weapon", "be", "1=1")
    register_event("Damage" , "event_damage" , "b" , "2>0")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox" ,"OnPlayerTouchWeaponBox")

    RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
    RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

    register_forward(FM_SetModel, "fw_WorldModel")
	register_forward(FM_CmdStart, "fw_CmdStart")		

    register_clcmd("buyammo2", "ClientCommand_buyammo2")
    register_clcmd("secammo", "ClientCommand_buyammo2")
    register_clcmd("+attack2", "Secondary_Attack")

    register_event("TextMsg", "event_commencing", "a", "2=#event_commencing", "2=#Game_will_restart_in") 

    new weapon_name[17]
	for(new i = 1; i < sizeof(pistols); i++)
	{
        get_weaponname(pistols[i], weapon_name, charsmax(weapon_name))

        RegisterHam(Ham_Item_PostFrame, weapon_name, "Item_PostFrame")
        RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "Primary_Attack")
		RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "Primary_Attack_Post",1)
        RegisterHam(Ham_Item_Deploy, weapon_name, "Weapon_Deploy_Post", 1)
        RegisterHam(Ham_Weapon_SecondaryAttack, weapon_name, "Secondary_Attack")
	}
}

public plugin_startup()
{
    Pistol_Numbers = ArrayCreate(1)
	Pistol_Names = ArrayCreate(64)
	Pistol_InfoText = ArrayCreate(128)

	C_read_pistol_config()
	C_read_pistol_sections()
	C_check_pistol_config()
}

public plugin_precache()
{
    plugin_startup()

    if (brokenConfig == 0)
    {
        for(new i = 1; i < ArraySize(Pistol_Names); i++)
        {
            new v_model[252], p_model[252], w_model[252], sight_model[252]
            formatex(v_model,charsmax(v_model), "models/%s", C_parse_pistol_config(i, "v_model"))
            formatex(p_model,charsmax(p_model), "models/%s", C_parse_pistol_config(i, "p_model"))
            formatex(w_model,charsmax(w_model), "models/%s", C_parse_pistol_config(i, "w_model"))
            formatex(sight_model,charsmax(sight_model), "models/%s", C_parse_pistol_config(i, "sight_model"))

            precache_model(v_model)
            precache_model(p_model)
            precache_model(w_model)
            precache_model(sight_model)
        }
        
        for (new i = 1; i < ArraySize(Pistol_Names); i++)
        {
            new total_sound[252]
            new fs_left[252], fs_right[252]

            formatex(total_sound, charsmax(total_sound), "%s", C_parse_pistol_config(i, "fire_sounds"))
            strtok(total_sound, fs_left, 252, fs_right, 252, '*')
            trim(fs_left)
            trim(fs_right)

            if (equali(fs_left, "") || equali(fs_right, ""))
            {
                format(total_sound, 252, "weapons/%s", total_sound)

                precache_sound(total_sound)
            }
            else
            {
                format(fs_left, 252, "weapons/%s", fs_left)
                format(fs_right, 252, "weapons/%s", fs_right)

                precache_sound(fs_left)
                precache_sound(fs_right)
            }
        }

        
        new model[64]
        for (new wpnid = 0; wpnid < ArraySize(Pistol_Numbers); wpnid++)
        {
            if (wpnid != 0)
            {
                ArrayGetString(Pistol_Names, wpnid, model, charsmax(model))

                trim(model)
                replace(model, 64, " ", "_")
                strtolower(model)

                format(class_weapons[wpnid], 31, "nst_%s", model)

                cvar_clip[wpnid] = str_to_num(C_parse_pistol_config(wpnid, "clip"))
                cvar_ammo[wpnid] = str_to_num(C_parse_pistol_config(wpnid, "ammo"))
                cvar_cost[wpnid] = str_to_num(C_parse_pistol_config(wpnid, "cost"))
                cvar_administrator[wpnid] = str_to_num(C_parse_pistol_config(wpnid, "administrator"))
                cvar_secondary_type[wpnid] = str_to_num(C_parse_pistol_config(wpnid, "secondary_type"))
                cvar_reload[wpnid] = str_to_num(C_parse_pistol_config(wpnid, "reload"))
                cvar_tracer_type[wpnid] = str_to_num(C_parse_pistol_config(wpnid, "tracer_type"))
                cvar_tracer_sprite[wpnid] = precache_model(C_parse_pistol_config(wpnid, "tracer_sprite"))

                format(cvar_tracer[wpnid], 63, "%s", C_parse_pistol_config(wpnid, "tracer"))
                
                cvar_deploy[wpnid] = str_to_float(C_parse_pistol_config(wpnid, "deploy"))
                cvar_knockback[wpnid] = str_to_float(C_parse_pistol_config(wpnid, "knockback"))
                cvar_recoil[wpnid] = str_to_float(C_parse_pistol_config(wpnid, "recoil"))
                cvar_dmgmultiplier[wpnid] = str_to_float(C_parse_pistol_config(wpnid, "damage"))
                cvar_speed[wpnid] = str_to_float(C_parse_pistol_config(wpnid, "speed"))
                cvar_fastrun[wpnid] = str_to_float(C_parse_pistol_config(wpnid, "fastrun"))
                cvar_sightrecoil[wpnid] = str_to_float(C_parse_pistol_config(wpnid, "sight_recoil"))
            }
        }
    }
}

/* Config Functions */
public C_read_pistol_sections()
{
	new sectionNumber = 0
    new szTemp[64]

	for (new i = 0; i < ArraySize(Pistol_InfoText); i++)
	{
        if (i == 0)
        {
            ArrayPushString(Pistol_Names, szTemp)
            ArrayPushCell(Pistol_Numbers, sectionNumber)
            i++;
        }
		ArrayGetString(Pistol_InfoText, sectionNumber, szTemp, charsmax( szTemp ) )
		replace(szTemp, 999, "[", "")
		replace(szTemp, 999, "]", "")
		replace(szTemp, 999, "^n", "")
  		ArrayPushString(Pistol_Names, szTemp)
		ArrayPushCell(Pistol_Numbers, sectionNumber)

		if (ArraySize(Pistol_InfoText) > sectionNumber + NEXT_SECTION)
		{
			sectionNumber = sectionNumber + NEXT_SECTION
		}
		else
		{
			i = ArraySize(Pistol_InfoText)
		}
	}
	sectionNumber = 0
}

public C_check_pistol_config()
{
    new messageTex[999]
    new _pistols_File[100] = {"addons/amxmodx/configs/nst_weapons/nst_pistols.ini" }

    formatex(messageTex[0], charsmax(messageTex) - 0, "%L", LANG_PLAYER, "BROKEN_CONFIG")
    if (file_exists(_pistols_File) == 1)
    {
        if (C_pistol_syntaxRules() == -1)
        {
            replace(messageTex, 999, "$", "new Array: Pistol_InfoText;")
            server_print("[NST Weapons] %s", messageTex)
            brokenConfig = 1
        }
        else
        {
            brokenConfig = 0
        }
    }
}

public C_read_pistol_config()
{
	new buffer[128]
	new right[128], left[128]
    new left_comment[128], right_comment[128], left_s_comment[128], right_s_comment[128]

	new fp_pistols = fopen("addons/amxmodx/configs/nst_weapons/nst_pistols.ini", "r")
    while (!feof(fp_pistols))
    {
	    fgets(fp_pistols, buffer, charsmax(buffer))
            
        //Comment Line Remover
        strtok(buffer, left_comment, 128, right_comment, 128, ';')
        format(right_comment, 128, ";%s", right_comment)
        str_replace(buffer, 128, right_comment, "_THIS_IS_COMMENT_LINE_")

        //Comment Line Remover 2
        strtok(buffer, left_s_comment, 128, right_s_comment, 128, ']')
        if (!equali(right_s_comment, ""))
        {
            str_replace(buffer, 128, right_s_comment, "")
        }

        ArrayPushString(Pistol_InfoText, buffer)

        for (new i = 0; i < ArraySize(Pistol_InfoText); i++)
        {
            new szTemp[128]
            ArrayGetString(Pistol_InfoText, i, szTemp, charsmax(szTemp))
            if (equali(szTemp, "_THIS_IS_COMMENT_LINE_"))
            {
                ArrayDeleteItem(Pistol_InfoText, i)
            }
        }
    }
    fclose(fp_pistols)
}

stock C_parse_pistol_config(const strKey, const Property[])
{
	new parserLine[128]
	new rightValue[128], leftValue[32], right_C[128], left_C[32]

	new PropertyNumber

	if (equali(Property, "administrator"))
	{
		PropertyNumber = s_administrator
	}
	if (equali(Property, "cost"))
	{
		PropertyNumber = s_cost
	}
	if (equali(Property, "wpn_id"))
	{
		PropertyNumber = s_wpn_id
	}
	if (equali(Property, "clip"))
	{
		PropertyNumber = s_clip
	}
	if (equali(Property, "ammo"))
	{
		PropertyNumber = s_ammo
	}
	if (equali(Property, "damage"))
	{
		PropertyNumber = s_damage
	}
	if (equali(Property, "recoil"))
	{
		PropertyNumber = s_recoil
	}
	if (equali(Property, "deploy"))
	{
		PropertyNumber = s_deploy
	}
	if (equali(Property, "reload"))
	{
		PropertyNumber = s_reload
	}
	if (equali(Property, "speed"))
	{
		PropertyNumber = s_speed
	}
	if (equali(Property, "knockback"))
	{
		PropertyNumber = s_knockback
	}
	if (equali(Property, "fastrun"))
	{
		PropertyNumber = s_fastrun
	}
	if (equali(Property, "secondary_type"))
	{
		PropertyNumber = s_secondary_type
	}
    if (equali(Property, "tracer"))
	{
		PropertyNumber = s_tracer
	}
    if (equali(Property, "tracer_type"))
    {
        PropertyNumber = s_tracer_type
    }
    if (equali(Property, "tracer_sprite"))
    {
        PropertyNumber = s_tracer_sprite
    }
    if (equali(Property, "sight_recoil"))
	{
		PropertyNumber = s_sight_recoil
	}
    if (equali(Property, "sight_model"))
	{
		PropertyNumber = s_sight_model
	}
	if (equali(Property, "v_model"))
	{
		PropertyNumber = s_v_model
	}
	if (equali(Property, "p_model"))
	{
		PropertyNumber = s_p_model
	}
	if (equali(Property, "w_model"))
	{
		PropertyNumber = s_w_model
	}
	if (equali(Property, "fire_sounds"))
	{
		PropertyNumber = s_fire_sounds
	}

    ArrayGetString(Pistol_InfoText, ArrayGetCell(Pistol_Numbers, strKey) + PropertyNumber, parserLine, charsmax(parserLine))
	strtok(parserLine, leftValue, 64, rightValue, 127, '=')
	trim(leftValue); trim(rightValue);

	return rightValue
}

stock C_pistol_syntaxRules()
{
	new buffer[128], leftValue[128], rightValue[128]
    new lineFixer[24]
	new firstChar[15], endChar[15]

	for (new i = 0; i < ArraySize(Pistol_InfoText); i++)
	{
		ArrayGetString(Pistol_InfoText, i, buffer, charsmax(buffer))
		replace(buffer, 128, "^n", "")
		strtok(buffer, leftValue, 128, rightValue, 128, '=')
		trim(leftValue); trim(rightValue);

        new commentLine[128], le[1]
        strtok(rightValue, le, 1, commentLine, 128, ';')
        replace(commentLine, 128, "^n", "")
        trim(commentLine);

        if (!equali(commentLine, ""))
        {
            str_replace(rightValue, 999, commentLine, "")
            str_replace(rightValue, 999, ";", "")
        }

		formatex(firstChar, charsmax(firstChar), "%c", buffer[0])
		formatex(endChar, charsmax(endChar), "%c", buffer[strlen(buffer) - 1])

		//1-
		if (i == 0)
		{
			if (!equali(firstChar, "[") || !equali(endChar, "]"))
			{
				return -1;
			}
		}
		else if (i == lineFixer[1] + NEXT_SECTION)
		{
			lineFixer[1] = lineFixer[1] + NEXT_SECTION
			if (!equali(firstChar, "[") || !equali(endChar, "]"))
			{
				return -1;
			}
		}

		if (i >= lineFixer[0] + 1 && i < lineFixer[0] + 14)
		{
			if (strlen(rightValue) > 8)
			{
				return -1;
			}
		}

        if (i == s_administrator)
        {
            if (equal(leftValue, "administator"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        return -1;
                    }
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[2] + s_administrator_next)
        {
            lineFixer[2] = lineFixer[2] + NEXT_SECTION;

            if (equal(leftValue, "administator"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        return -1;
                    }
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_cost)
        {
            if (equal(leftValue, "cost"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[3] + s_cost_next)
        {
            lineFixer[3] = lineFixer[3] + NEXT_SECTION;

            if (equal(leftValue, "cost"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_wpn_id)
        {
            if (equal(leftValue, "wpn_id"))
            {
                if(str_to_num(rightValue[0]) == 0 || str_to_num(rightValue[0]) == 2 || str_to_num(rightValue[0]) == 29 || str_to_num(rightValue[0]) > 30 && (str_to_num(rightValue[0]) != 1 && str_to_num(rightValue[0]) != 10 && str_to_num(rightValue[0]) != 11 && str_to_num(rightValue[0]) != 16 && str_to_num(rightValue[0]) != 17 && str_to_num(rightValue[0]) != 26) || str_to_num(rightValue[0]) == 4 || str_to_num(rightValue[0]) == 9 || str_to_num(rightValue[0]) == 25)
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[4] + s_wpn_id_next)
        {
            lineFixer[4] = lineFixer[4] + NEXT_SECTION;

            if (equal(leftValue, "wpn_id"))
            {
                if(str_to_num(rightValue[0]) == 0 || str_to_num(rightValue[0]) == 2 || str_to_num(rightValue[0]) == 29 || str_to_num(rightValue[0]) > 30 && (str_to_num(rightValue[0]) != 1 && str_to_num(rightValue[0]) != 10 && str_to_num(rightValue[0]) != 11 && str_to_num(rightValue[0]) != 16 && str_to_num(rightValue[0]) != 17 && str_to_num(rightValue[0]) != 26) || str_to_num(rightValue[0]) == 4 || str_to_num(rightValue[0]) == 9 || str_to_num(rightValue[0]) == 25)
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_clip)
        {
            if (equal(leftValue, "clip"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[5] + s_clip_next)
        {
            lineFixer[5] = lineFixer[5] + NEXT_SECTION;

            if (equal(leftValue, "clip"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_ammo)
        {
            if (equal(leftValue, "ammo"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[6] + s_ammo_next)
        {
            lineFixer[6] = lineFixer[6] + NEXT_SECTION;

            if (equal(leftValue, "ammo"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_damage)
        {
            if (equal(leftValue, "damage"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[7] + s_damage_next)
        {
            lineFixer[7] = lineFixer[7] + NEXT_SECTION;

            if (equal(leftValue, "damage"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_recoil)
        {
            if (equal(leftValue, "recoil"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[8] + s_recoil_next)
        {
            lineFixer[8] = lineFixer[8] + NEXT_SECTION;

            if (equal(leftValue, "recoil"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_deploy)
        {
            if (equal(leftValue, "deploy"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[9] + s_deploy_next)
        {
            lineFixer[9] = lineFixer[9] + NEXT_SECTION;

            if (equal(leftValue, "deploy"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_reload)
        {
            if (equal(leftValue, "reload"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        return -1;
                    }
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[10] + s_reload_next)
        {
            lineFixer[10] = lineFixer[10] + NEXT_SECTION;

            if (equal(leftValue, "reload"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        return -1;
                    }
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_speed)
        {
            if (equal(leftValue, "speed"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[11] + s_speed_next)
        {
            lineFixer[11] = lineFixer[11] + NEXT_SECTION;

            if (equal(leftValue, "speed"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_knockback)
        {
            if (equal(leftValue, "knockback"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[12] + s_knockback_next)
        {
            lineFixer[12] = lineFixer[12] + NEXT_SECTION;

            if (equal(leftValue, "knockback"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_fastrun)
        {
            if (equal(leftValue, "fastrun"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[13] + s_fastrun_next)
        {
            lineFixer[13] = lineFixer[13] + NEXT_SECTION;

            if (equal(leftValue, "fastrun"))
            {
                if(!isdigit(rightValue[0]))
                {
                    return -1;
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_secondary_type)
        {
            if (equal(leftValue, "secondary_type"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        if (!equali(rightValue, "2"))
                        {
                            if (!equali(rightValue, "3"))
                            {
                                if (!equali(rightValue, "4"))
                                {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[14] + s_secondary_type_next)
        {
            lineFixer[14] = lineFixer[14] + NEXT_SECTION;

            if (equal(leftValue, "secondary_type"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        if (!equali(rightValue, "2"))
                        {
                            if (!equali(rightValue, "3"))
                            {
                                if (!equali(rightValue, "4"))
                                {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                return -1
            }
        }
        
        if (i == s_tracer)
        {
            if (equal(leftValue, "tracer"))
            {
                new r_color[64], g_color[64], b_color[64], width[64], right[64], left[64]
                strtok(rightValue, r_color, 64, right, 64, ',')
                strtok(right, g_color, 64, right, 64, ',')
                strtok(right, b_color, 64, width, 64, ',')
                
                if (!equali(rightValue[0], "0"))
                {
                    if (!strlen(r_color) || !strlen(g_color) || !strlen(width))
                    {
                        if (!isdigit(r_color[0]) || !isdigit(g_color[0]) || !isdigit(b_color[0]) || !isdigit(width[0]))
                        {
                            return -1;
                        }
                    }
                }
            }
            else
            {
                return -1
            }
        }
 
        if(i == lineFixer[15] + s_tracer_next)
        {
            lineFixer[15] = lineFixer[15] + NEXT_SECTION;

            if (equal(leftValue, "tracer"))
            {
                new r_color[64], g_color[64], b_color[64], width[64], right[64], left[64]
                strtok(rightValue, r_color, 64, right, 64, ',')
                strtok(right, g_color, 64, right, 64, ',')
                strtok(right, b_color, 64, width, 64, ',')
                
                if (!equali(rightValue[0], "0"))
                {
                    if (!strlen(r_color) || !strlen(g_color) || !strlen(width))
                    {
                        if (!isdigit(r_color[0]) || !isdigit(g_color[0]) || !isdigit(b_color[0]) || !isdigit(width[0]))
                        {
                            return -1;
                        }
                    }
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_tracer_type)
        {
            if (equal(leftValue, "tracer_type"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        if (!equali(rightValue, "2"))
                        {
                            return -1;
                        }
                    }
                }
            }
            else
            {
                return -1
            }
        }
 
        if(i == lineFixer[16] + s_tracer_type_next)
        {
            lineFixer[16] = lineFixer[16] + NEXT_SECTION;

            if (equal(leftValue, "tracer_type"))
            {
                if (!equali(rightValue, "0"))
                {
                    if (!equali(rightValue, "1"))
                    {
                        if (!equali(rightValue, "2"))
                        {
                            return -1;
                        }
                    }
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_tracer_sprite)
        {
            if (equal(leftValue, "tracer_sprite"))
            {
                if (!contain(rightValue, ".spr"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[17] + s_tracer_sprite_next)
        {
            lineFixer[17] = lineFixer[17] + NEXT_SECTION;

            if (equal(leftValue, "tracer_sprite"))
            {
                if (!contain(rightValue, ".spr"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_sight_recoil)
        {
            if (equal(leftValue, "sight_recoil"))
            {
                if (!isdigit(rightValue[0]))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }
 
        if(i == lineFixer[18] + s_sight_recoil_next)
        {
            lineFixer[18] = lineFixer[18] + NEXT_SECTION;

            if (equal(leftValue, "sight_recoil"))
            {
                if (!isdigit(rightValue[0]))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_sight_model)
        {
            if (equal(leftValue, "sight_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }
 
        if(i == lineFixer[19] + s_sight_model_next)
        {
            lineFixer[19] = lineFixer[19] + NEXT_SECTION;

            if (equal(leftValue, "sight_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_v_model)
        {
            if (equal(leftValue, "v_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[20] + s_v_model_next)
        {
            lineFixer[20] = lineFixer[20] + NEXT_SECTION;

            if (equal(leftValue, "v_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_p_model)
        {
            if (equal(leftValue, "p_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[21] + s_p_model_next)
        {
            lineFixer[21] = lineFixer[21] + NEXT_SECTION;

            if (equal(leftValue, "p_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_w_model)
        {
            if (equal(leftValue, "w_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[22] + s_w_model_next)
        {
            lineFixer[22] = lineFixer[22] + NEXT_SECTION;

            if (equal(leftValue, "w_model"))
            {
                if (!contain(rightValue, ".mdl"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if (i == s_fire_sounds)
        {
            if (equal(leftValue, "fire_sounds"))
            {
                if (!contain(rightValue, ".wav"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

        if(i == lineFixer[23] + s_fire_sounds_next)
        {
            lineFixer[23] = lineFixer[23] + NEXT_SECTION;

            if (equal(leftValue, "fire_sounds"))
            {
                if (!contain(rightValue, ".wav"))
                {
                    return -1
                }
            }
            else
            {
                return -1
            }
        }

		if (i == lineFixer[0] + END_SECTION)
		{
			lineFixer[0] = lineFixer[0] + NEXT_SECTION
			i++;
		}
	}

	return 0;
}

/* All Stock Functions */
stock IDtoName(const id)
{
    new weaponName[64]

    switch (id) 
    {
        case 1:
            weaponName = "weapon_p228"
        case 3:
            weaponName = "weapon_scout"
        case 4:
            weaponName = "weapon_hegrenade"
        case 5:
            weaponName = "weapon_xm1014"
        case 6:
            weaponName = "weapon_c4"
        case 7:
            weaponName = "weapon_mac10"
        case 8:
            weaponName = "weapon_aug"
        case 10:
            weaponName = "weapon_elite"
        case 11:
            weaponName = "weapon_fiveseven"
        case 12:
            weaponName = "weapon_ump45"
        case 13:
            weaponName = "weapon_sg550"
        case 14:
            weaponName = "weapon_galil"
        case 15:
            weaponName = "weapon_famas"
        case 16:
            weaponName = "weapon_usp"
        case 17:
            weaponName = "weapon_glock18"
        case 18:
            weaponName = "weapon_awp"
        case 19:
            weaponName = "weapon_mp5navy"
        case 20:
            weaponName = "weapon_m249"
        case 21:
            weaponName = "weapon_m3"
        case 22:
            weaponName = "weapon_m4a1"
        case 23:
            weaponName = "weapon_tmp"
        case 24:
            weaponName = "weapon_g3sg1"
        case 25:
            weaponName = "weapon_flashbang"
        case 26:
            weaponName = "weapon_deagle"
        case 27:
            weaponName = "weapon_sg552"
        case 28:
            weaponName = "weapon_ak47"
        case 29:
            weaponName = "weapon_knife"
        case 30:
            weaponName = "weapon_p90"
    }
    return weaponName
}

stock drop_all_secondary(id)
{
    for (new i = 0; i < sizeof(pistols); i++)
    {
        static dropweapon[32]
		get_weaponname(pistols[i], dropweapon, sizeof dropweapon - 1)
		engclient_cmd(id, "drop", dropweapon)
    }
}

stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
	// who knows what wpnName will be
	static newName[24];

	// need to find the name
	if(wpnid) get_weaponname(wpnid,newName,23);

	// go with what we were told
	else formatex(newName,23,"%s",wpnName);

	// prefix it if we need to
	if(!equal(newName,"weapon_",7))
		format(newName,23,"weapon_%s",newName);

	return fm_find_ent_by_owner(get_maxplayers(),newName,id);
}

stock user_has_secondary(client)
{
    new return_ = 0
    for (new i = 0; i < sizeof(pistols); i++)
    {
        if (user_has_weapon(client, pistols[i]))
        {
            return_ = 1
        }
    }
    return return_
}

stock user_hand_secondary(client)
{
    new return_ = 1
    new wpnid 
    wpnid = get_user_weapon(client, _, _)
    for (new i = 0; i < sizeof(pistols); i++)
    {
        if (!equali(pistols[i], IDtoName(wpnid)))
        {
            return_ = 0
        }
    }
    return return_
}

stock set_weapon_timeidle(id, Float:TimeIdle)
{
    new CURRENT_WEAPON = HAS_WEAPON[id]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))

	if(!is_user_alive(id))
    {
		return
    }
		
	static entwpn;
    entwpn = fm_get_user_weapon_entity(id, CHANGE_WEAPON)

	if(!pev_valid(entwpn))
    {
		return
    }
	
	set_pdata_float(entwpn, m_flNextPrimaryAttack, TimeIdle, 4)
	set_pdata_float(entwpn, m_flNextSecondaryAttack, TimeIdle, 4)
	set_pdata_float(entwpn, m_flTimeWeaponIdle, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

stock set_weapon_anim(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

stock get_pistol_sound(cur_wpn)
{
	new total_sound[252], BLANK[252]
	new fs_left[252], fs_right[252]

	formatex(total_sound, charsmax(total_sound), "%s", C_parse_pistol_config(cur_wpn, "fire_sounds"))
	strtok(total_sound, fs_left, 252, fs_right, 252, '*')
	trim(fs_left)
	trim(fs_right)

	if (equali(fs_left, "") || equali(fs_right, ""))
	{
		format(total_sound, 252, "weapons/%s", total_sound)

        return total_sound
	}
	else
	{
		format(fs_left, 252, "weapons/%s", fs_left)
		format(fs_right, 252, "weapons/%s", fs_right)

		new selected_variable[252]
		switch (random_num(0, 1))
		{
			case 0:
				selected_variable = fs_left
			case 1:
				selected_variable = fs_right
		}

        return selected_variable
	}
    
    return BLANK
}

stock create_velocity_vector(victim, attacker, Float:velocity[3], Float:knockback)
{
	if(!is_user_alive(attacker))
    {
		return 0;
    }
    if (!is_valid_ent(attacker))
    {
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

stock get_weapon_attachment(client, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(client, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(client, pev_origin, fOrigin) 
	pev(client, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock Make_BulletHole(client, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(client)
		write_byte(Decal)
		message_end()
	}
}

stock Make_BulletSmoke(client, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(client, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr"))
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

PlayEmitSound(id, const sound[], type)
{
    emit_sound(id, type, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

ShowHud_Ammo(client, ammo)
{    
    new wpn_id = get_user_weapon(client, _, _)
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoPickup"), _, client)
    write_byte(weapons_ammo_id[wpn_id])
    write_byte(ammo)
    message_end()
}

SetFov(id, iFov)
{
	set_pev(id, pev_fov, iFov)
	set_pdata_int(id, m_iFOV, iFov, XTRA_OFS_PLAYER)
}

ResetFov(id)
{
	if( 0 <= get_pdata_int(id, m_iFOV, XTRA_OFS_PLAYER) <= 90 )
	{
		set_pev(id, pev_fov, 90)
		set_pdata_int(id, m_iFOV, 90, XTRA_OFS_PLAYER)
	}
}

/* Menu Function */
public NST_Pistols(client)
{
	new szTemp[64]
	new menu[512] , menuxx
	new text[256], len = 0
    new administrator, wpn_id
    backup_client = client
	formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
	menuxx = menu_create(menu, "Get_NSTWeapon")

    if (brokenConfig == 0 && commencing == 0)
    {
    	for(new i = 1; i < ArraySize(Pistol_Names); i++)
    	{
            administrator = str_to_num(C_parse_pistol_config(i, "administrator"))
            wpn_id = str_to_num(C_parse_pistol_config(i, "wpn_id"))
            new menuKey[64]
        	ArrayGetString(Pistol_Names, i, szTemp, charsmax(szTemp))

            if (wpn_id == 1 || wpn_id == 10 || wpn_id == 11 || wpn_id == 16 || wpn_id == 17 || wpn_id == 26)
            {
                if (administrator == 0)
                {
                    formatex(menu,charsmax(menu), "%s 	\r$%s", szTemp, C_parse_pistol_config(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                }
                else
                {
                    formatex(menu,charsmax(menu), "\y%s 	\r$%s", szTemp, C_parse_pistol_config(i, "cost"))
                    num_to_str(i + 1, menuKey, 999)
                    menu_additem(menuxx, menu, menuKey)
                }
            }
    	}
    }
    else
    {
        C_check_pistol_config()
    }

    formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_NEXT");
	menu_setprop(menuxx, MPROP_NEXTNAME, text)
	
	formatex(text[len], charsmax(text) - len, "%L", LANG_PLAYER, "MENU_BACK");
	menu_setprop(menuxx, MPROP_BACKNAME, text)
	
	menu_setprop(menuxx, MPROP_EXIT, "\r%L", LANG_PLAYER, "MENU_EXIT")
	

	//Show Menu
	if (is_user_alive(client))
	{
		menu_display(client, menuxx, 0)
	}
	else
	{
		client_print(client, print_chat, "[NST Weapons] %L", LANG_PLAYER, "USER_IS_DEAD")
	}

    return PLUGIN_HANDLED
}

/* Weapon Registration */
public ClientCommand_buyammo2(client)
{
    if (brokenConfig != 0)
    {
		new iClip, iAmmo, iWeapon, clip_max, ammo_max, clip_def, ammo_def

		for (new i = 0; i < sizeof(pistols); i++)
		{
			if (user_has_weapon(client, pistols[i]))
			{
				iWeapon = pistols[i]
			}
		}

		if (buy_AmmoCost[iWeapon] < cs_get_user_money(client))
		{
			if (iAmmo < ammo_def)
			{
				set_user_money(client, get_user_money(client) + -buy_AmmoCost[iWeapon])
				cs_set_user_bpammo(client, iWeapon, iAmmo + buy_AmmoCount[iWeapon])

				if (cs_get_user_bpammo(client, iWeapon) > ammo_def)
				{
					cs_set_user_bpammo(client, iWeapon, ammo_def)
					ShowHud_Ammo(client, ammo_def - iAmmo)
				}
				else
				{
					ShowHud_Ammo(client, buy_AmmoCount[iWeapon])
				}

				client_cmd(0, "spk sound/items/9mmclip1.wav")
			}
		}
    }
    else
    {
        new buyzone = cs_get_user_buyzone(client)
        new CURRENT_WEAPON = HAS_WEAPON[client]
        new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))

        if ((get_cvar_num("nst_use_buyzone") ? buyzone : 1) && user_has_secondary(client))
        {
            new iClip, iAmmo, iWeapon, clip_max, ammo_max, clip_def, ammo_def

            for (new i = 0; i < sizeof(pistols); i++)
            {
                if (user_has_weapon(client, pistols[i]))
                {
                    iWeapon = pistols[i]
                }
            }

            if (iWeapon != 0)
            {
                clip_def = weapons_max_clip[iWeapon]
                ammo_def = weapons_max_bp_ammo[iWeapon]
                clip_max = cvar_clip[CURRENT_WEAPON]
                ammo_max = cvar_ammo[CURRENT_WEAPON]
                iAmmo = cs_get_user_bpammo(client, iWeapon);
                
                if (HAS_WEAPON[client])
                {
                    if (buy_AmmoCost[iWeapon] < cs_get_user_money(client))
                    {
                        if (iAmmo < ammo_max)
                        {
                            set_user_money(client, get_user_money(client) + -buy_AmmoCost[iWeapon])
                            cs_set_user_bpammo(client, iWeapon, iAmmo + buy_AmmoCount[iWeapon])

                            if (cs_get_user_bpammo(client, iWeapon) > ammo_max)
                            {
                                cs_set_user_bpammo(client, iWeapon, ammo_max)
                                ShowHud_Ammo(client, ammo_max - iAmmo)
                            }
                            else
                            {
                                ShowHud_Ammo(client, buy_AmmoCount[iWeapon])
                            }

                            client_cmd(0, "spk sound/items/9mmclip1.wav")
                        }
                    }
                }
                else
                {
                    if (buy_AmmoCost[iWeapon] < cs_get_user_money(client))
                    {
                        if (iAmmo < ammo_def)
                        {
                            set_user_money(client, get_user_money(client) + -buy_AmmoCost[iWeapon])
                            cs_set_user_bpammo(client, iWeapon, iAmmo + buy_AmmoCount[iWeapon])

                            if (cs_get_user_bpammo(client, iWeapon) > ammo_def)
                            {
                                cs_set_user_bpammo(client, iWeapon, ammo_def)
                                ShowHud_Ammo(client, ammo_def - iAmmo)
                            }
                            else
                            {
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

public Get_NSTWeapon(client, menu, item)
{
    new access,callback,data[6],name[64]
    menu_item_getinfo(menu,item,access,data,5,name,63,callback)
    new key = str_to_num(data)

    if (key != 0)
    {
        Buy_Weapon(client, key - 1)
    }
}

public Buy_Weapon(id, wpnid)
{
    if (brokenConfig != 0)
    {
        return
    }

	new buyzone = cs_get_user_buyzone(id)

	if ((get_cvar_num("nst_use_buyzone") ? buyzone : 1) == 0) 
    {
        client_print(id, print_chat, "[NST Wpn] %L", LANG_PLAYER, "CANT_BUY_WEAPON")
    }
    else
	{
		new plrClip, plrAmmo, user
		get_user_weapon(id, plrClip , plrAmmo)

		new user_money = get_user_money(id)
		new wp_cost = cvar_cost[wpnid]
		new clip_max = cvar_clip[wpnid]
		new ammo_max = cvar_ammo[wpnid]
        new administrator = cvar_administrator[wpnid]

        if (!(get_user_flags(id) & ADMIN_KICK) && administrator == 1)
        {
            client_print(id, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ACCESS_DENIED_BUY")
        }
		else if(!is_user_alive(id))
		{
            client_print(id, print_chat, "[NST Weapons] %L", LANG_PLAYER, "NOT_LIVE")
        }
        else if (get_gametime() - round_time > get_cvar_num("nst_buy_time"))
        {
            engclient_print(id, engprint_center, "%L", LANG_PLAYER, "BUY_TIME_END", get_cvar_num("nst_buy_time"));
        }
        else if(HAS_WEAPON[id] == wpnid)
		{
            new szTemp[256]
            ArrayGetString(Pistol_Names, HAS_WEAPON[id], szTemp, charsmax(szTemp))

            client_print(id, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ALREADY_HAVE", szTemp)
		}
        else if (get_cvar_num("nst_free") ? wp_cost <= get_user_money(id) : 1)
        {
            drop_all_secondary(id)
        
			CURRENT_WEAPON[id] = wpnid
			HAS_WEAPON[id] = wpnid
            Give_Weapon(id, clip_max, ammo_max)
			ShowHud_Ammo(id, ammo_max)

            if (!get_cvar_num("nst_free"))
            {
                set_user_money(id, user_money + -wp_cost)
            }
        }
        else
		{	
            client_print(id, print_chat, "[NST Weapons] %L", LANG_PLAYER, "INSUFFICIENT_MONEY")
		}
	}
}

public ReBuy_Weapon(id)
{
    if (brokenConfig != 0)
    {
        return PLUGIN_HANDLED
    }

	new wpnid = CURRENT_WEAPON[id]
	if (wpnid > 0) 
    {
        Buy_Weapon(id, wpnid)
    }
	
	return PLUGIN_HANDLED
}

public Weapon_Deploy_Post(entity)
{
    if (brokenConfig != 0)
    {
        return PLUGIN_HANDLED
    }

	new id = get_pdata_cbase(entity, m_pPlayer, 4);
    new CURRENT_WEAPON = HAS_WEAPON[id]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	new wpn_id = get_user_weapon(id, _, _)

    if(!pev_valid(entity))
    {
		return HAM_IGNORED;
    }
    
	if(!is_user_alive(id))
    {
        return HAM_IGNORED;
    }

	if(wpn_id == CHANGE_WEAPON && HAS_WEAPON[id])
	{
		set_weapon_timeidle(id, cvar_deploy[CURRENT_WEAPON])
		set_player_nextattack(id, cvar_deploy[CURRENT_WEAPON])
    }

    return HAM_IGNORED
}

public Item_PostFrame(entity)
{
    if (brokenConfig != 0)
    {
        return
    }

	static client
    static inReload, wpnid, clip_max, AmmoType, ammo_old, clip_old, Float:flNextAttack, btnInfo
    client = get_pdata_cbase(entity, m_pPlayer, 4)

	new CURRENT_WEAPON = HAS_WEAPON[client]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	new user_wpnid = get_user_weapon(client, _, _)

	if (user_wpnid == CHANGE_WEAPON && HAS_WEAPON[client])
	{
        btnInfo = pev(client, pev_button)
        wpnid = get_pdata_int(entity, m_iId, 4)
        clip_max = cvar_clip[CURRENT_WEAPON]
		inReload = get_pdata_int(entity, m_fInReload, 4)
        flNextAttack = get_pdata_float(client, m_flNextAttack, 5)
        AmmoType = m_rgAmmo_player_Slot0 + get_pdata_int(entity, m_iPrimaryAmmoType, 4)
        ammo_old = get_pdata_int(client, AmmoType, 5)
        clip_old = get_pdata_int(entity, m_iClip, 4)

		if(inReload && flNextAttack <= 0.0)
		{
			new j = min(clip_max - clip_old, ammo_old)
			set_pdata_int(entity, m_iClip, clip_old + j, 4)
			set_pdata_int(client, AmmoType, ammo_old-j, 5)		
			set_pdata_int(entity, m_fInReload, 0, 4)

			inReload = 0
		}
		
		if((btnInfo & IN_ATTACK2 && get_pdata_float(entity, m_flNextSecondaryAttack, 4) <= 0.0) || (btnInfo & IN_ATTACK && get_pdata_float(entity, m_flNextPrimaryAttack, 4) <= 0.0))
		{
			return;
		}
		
		if(btnInfo & IN_RELOAD && !inReload)
		{
			if(clip_old >= clip_max)
			{
				set_pev(client, pev_button, btnInfo & ~IN_RELOAD)
			}
			else if(clip_old == weapons_max_clip[wpnid])
			{
				if(ammo_old)
				{
					set_pdata_float(client, m_flNextAttack, weapons_clip_delay[wpnid], 5)
					set_pdata_int(entity, m_fInReload, 1, 4)
					set_pdata_float(entity, m_flTimeWeaponIdle, weapons_clip_delay[wpnid] + 0.5, 4)
				}
			}

            Disable_Type_Zoom[client] = 1
		}
        else
        {
            Disable_Type_Zoom[client] = 0
        }
	}
}

public Give_Weapon(id, clip, ammo)
{
    if (brokenConfig != 0)
    {
        return PLUGIN_HANDLED
    }

	new CURRENT_WEAPON = HAS_WEAPON[id]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))

	give_item(id, IDtoName(CHANGE_WEAPON))
	cs_set_user_bpammo(id, CHANGE_WEAPON, ammo)
    new ent = get_weapon_ent(id, CHANGE_WEAPON)
	cs_set_weapon_ammo(ent, clip)
	
	return PLUGIN_HANDLED
}

public Primary_Attack(entity)
{
	new client = pev(entity, pev_owner)
	pev(client, pev_punchangle, Pushangle[client])

	return HAM_IGNORED
}

public Primary_Attack_Post(entity)
{
    if (brokenConfig != 0)
    {
        return PLUGIN_HANDLED
    }

    if (!is_valid_ent(entity))
    {
        return HAM_IGNORED
    }
    
	new client = pev(entity, pev_owner)
	new id = get_pdata_cbase(entity, 41, 4);

	new CURRENT_WEAPON = HAS_WEAPON[client]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	new wpn_id = get_user_weapon(client, _, _)

	if(wpn_id == CHANGE_WEAPON && HAS_WEAPON[client])
	{
        new old_ammo, blank
        get_user_ammo(client, CHANGE_WEAPON, old_ammo, blank)

        if (old_ammo != 0)
        {
            if (cvar_speed[CURRENT_WEAPON] > 0.9)
            {
                set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON] - 0.9, 4)
            }
            else if (cvar_speed[CURRENT_WEAPON] > 0.2)
            {
                set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON] - 0.38, 4)
            }
            else
            {
                set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON], 4)
            }
        }
        
		new Float:push[3]
		pev(client,pev_punchangle,push)
		xs_vec_sub(push, Pushangle[client], push)

        if (inThreeZoom[client])
        {
            xs_vec_mul_scalar(push, cvar_sightrecoil[CURRENT_WEAPON], push)
        }
        else
        {
            xs_vec_mul_scalar(push, cvar_recoil[CURRENT_WEAPON], push)
        }
		xs_vec_add(push, Pushangle[client], push)
		set_pev(client, pev_punchangle, push)
        Set_BitVar(IN_EMIT_ATTACK, client)
    }

    return FMRES_SUPERCEDE
}

public Secondary_Attack(entity)
{
    if (brokenConfig != 0)
    {
        return PLUGIN_HANDLED
    }

    if(pev_valid(entity) != 2)
    {
		return HAM_IGNORED
    }
    
	new client = pev(entity, pev_owner)
    static Id;
    Id = get_pdata_cbase(entity, 41, 4)

	new CURRENT_WEAPON = HAS_WEAPON[client]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	new wpn_id = get_user_weapon(client, _, _)

	if(wpn_id == CHANGE_WEAPON && HAS_WEAPON[client])
    {
        if (wpn_id == CSW_USP || wpn_id == CSW_GLOCK18)
        {
            if (cvar_secondary_type[CURRENT_WEAPON] == 4)
            {
                if (get_pdata_float(Id, 83, 5) > 0.0)
                {
                    return HAM_SUPERCEDE
                }
                if (cs_get_weapon_ammo(entity) <= 0)
                {
                    return HAM_SUPERCEDE
                }

                if (wpn_id == CSW_GLOCK18)
                {
                    set_weapon_anim(client, 5)
                }
                else if (wpn_id == CSW_USP)
                {
                    set_weapon_anim(client, 3)
                }
                ExecuteHamB(Ham_Weapon_PrimaryAttack, entity)
                PlayEmitSound(client, get_pistol_sound(HAS_WEAPON[client]), CHAN_WEAPON)
                
                if (cvar_speed[CURRENT_WEAPON] > 0.9)
                {
                    set_pdata_float(Id, m_flNextAttack, cvar_speed[CURRENT_WEAPON] - 0.9, 4)
                }
                else if (cvar_speed[CURRENT_WEAPON] > 0.2)
                {
                    set_pdata_float(Id, m_flNextAttack, cvar_speed[CURRENT_WEAPON] - 0.38, 4)
                }
                else
                {
                    set_pdata_float(Id, m_flNextAttack, cvar_speed[CURRENT_WEAPON], 4)
                }
                set_pdata_int(entity, 64, 0, 4)
            }

            if (cvar_secondary_type[CURRENT_WEAPON])
            {
                return FMRES_SUPERCEDE
            }
        }
        else
        {
            if (get_pdata_float(Id, 83, 5) > 0.0)
            {
                return HAM_SUPERCEDE
            }

            set_pdata_float(Id, 83, get_pdata_float(Id, 83, 5) + 0.2, 5)	
            set_pdata_int(entity, 64, 0, 4)

            return FMRES_SUPERCEDE
        }
    }
    else
    {
        return PLUGIN_CONTINUE
    }

    return FMRES_SUPERCEDE
}

public Current_Weapon(client)
{
    if (brokenConfig != 0)
    {
        return PLUGIN_HANDLED
    }

	new CURRENT_WEAPON = HAS_WEAPON[client]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	
    new clip, ammo
	new wpn_id = get_user_weapon(client, clip, ammo)

	if (wpn_id == CHANGE_WEAPON && HAS_WEAPON[client])
	{
        entity_set_float(client, EV_FL_maxspeed, 240.0 + cvar_fastrun[CURRENT_WEAPON])
         
        new v_model[999], p_model[999], sight_model[999]
        formatex(v_model,charsmax(v_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "v_model"))
        formatex(p_model,charsmax(p_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "p_model"))
        formatex(sight_model,charsmax(sight_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "sight_model"))

        if (!inThreeZoom[client])
        {
		    set_pev(client, pev_viewmodel2, v_model)
        }
        else
        {
            set_pev(client, pev_viewmodel2, sight_model)
        }

		set_pev(client, pev_weaponmodel2, p_model)
	}

    if (SAVE_CLIP[client] == 0)
    {
        if (is_valid_ent(get_weapon_ent(client, CHANGE_WEAPON)))
        {
            SAVED_CLIP[client] = cs_get_weapon_ammo(get_weapon_ent(client, CHANGE_WEAPON))
            SAVE_CLIP[client] = 1
        }
    }

    if (wpn_id == CHANGE_WEAPON && HAS_WEAPON[client] && pev(client, pev_oldbuttons) & IN_ATTACK)
    {
        if (Get_BitVar(IN_EMIT_ATTACK, client))
        {
            PlayEmitSound(client, get_pistol_sound(HAS_WEAPON[client]), 1)
        }
        
        if (cvar_reload[CURRENT_WEAPON] == 0)
        {
            if (cs_get_user_bpammo(client, wpn_id) == 0)
            {
                
            }
            else
            {
                cs_set_user_bpammo(client, wpn_id, cs_get_user_bpammo(client, wpn_id) - 1)
                cs_set_weapon_ammo(get_weapon_ent(client, CHANGE_WEAPON), SAVED_CLIP[client])
            }
        }
    }
    else
    {
        SAVE_CLIP[client] = 0
    }
    UnSet_BitVar(IN_EMIT_ATTACK, client)

	return PLUGIN_HANDLED
}

public OnPlayerTouchWeaponBox(ent, id)
{
    if (brokenConfig != 0)
    {
        return
    }

	new loop_enabled = 1
    for (new i = 1; i < ArraySize(Pistol_Numbers) && loop_enabled == 1; i++)
    {
        if (str_to_num(C_parse_pistol_config(i, "wpn_id")) <= 0)
        {
            break;
        }
        if(is_valid_ent(ent)) 
        {
			new classname[32]
			entity_get_string(ent,EV_SZ_classname,classname,31)
			if(equal(classname, class_weapons[i])) 
            {
				if(is_valid_ent(ent))
                {
					if(id > 0 && id < 34) 
                    {
						if (get_entity_flags(ent) == FL_ONGROUND && !user_has_secondary(id) && is_user_alive(id)) 
                        {
                            HAS_WEAPON[id] = i
                            loop_enabled = 0
						}
					}
				}
			}
        }
    }
}

/* Forwards */
public fw_TraceAttack(entity, attacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
    if(!is_user_alive(attacker))
    {
		return
    }
    
    new CURRENT_WEAPON = HAS_WEAPON[attacker]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	new wpn_id = get_user_weapon(attacker, _, _)
    
	if (!equali(cvar_tracer[CURRENT_WEAPON], "0"))
	{
        new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

		new clip,ammo
		new wpn_id = get_user_weapon(attacker, clip, ammo)

		if (wpn_id == CHANGE_WEAPON && HAS_WEAPON[attacker]) 
		{           
            if(cvar_secondary_type[CURRENT_WEAPON] == 4)
            {
                static Float:flEnd[3], Float:vecPlane[3]
                
                get_tr2(ptr, TR_vecEndPos, flEnd)
                get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
                    
                Make_BulletHole(attacker, flEnd, flDamage)
                Make_BulletSmoke(attacker, ptr)
            }

            new r_color[64], g_color[64], b_color[64], width[64], right[64], left[64]
            strtok(cvar_tracer[CURRENT_WEAPON], r_color, 64, right, 64, ',')
            strtok(right, g_color, 64, right, 64, ',')
            strtok(right, b_color, 64, width, 64, ',')

            if (cvar_tracer_type[CURRENT_WEAPON] == 0)
            {
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
                write_byte(1) //framestart
                write_byte(5) //framerate
                write_byte(2) //life
                write_byte(str_to_num(width)) //width
                write_byte(0) //noise
                write_byte(str_to_num(r_color))
                write_byte(str_to_num(g_color))
                write_byte(str_to_num(b_color))
                write_byte(200) //brightness
                write_byte(0) //speed
                message_end()
            }
            else if (cvar_tracer_type[CURRENT_WEAPON] == 1)
            {
                static Float:flEnd[3]
                get_tr2(ptr, TR_vecEndPos, flEnd)
                
                if(entity)
                {
                    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
                    write_byte(TE_DECAL)
                    engfunc(EngFunc_WriteCoord, flEnd[0])
                    engfunc(EngFunc_WriteCoord, flEnd[1])
                    engfunc(EngFunc_WriteCoord, flEnd[2])
		            write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS-1)])
                    write_short(entity)
                    message_end()
                }
                else
                {
                    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
                    write_byte(TE_SPRITE)
                    engfunc(EngFunc_WriteCoord, flEnd[0]+10)
                    engfunc(EngFunc_WriteCoord, flEnd[1]+10)
                    engfunc(EngFunc_WriteCoord, flEnd[2]+10)
                    write_short(cvar_tracer_sprite[CURRENT_WEAPON])
                    write_byte(str_to_num(width))  //Height
                    write_byte(200) //Bright
                    message_end()
                }
            }
            else if (cvar_tracer_type[CURRENT_WEAPON] == 2)
            {
                static Float:end[3]
                get_tr2(ptr, TR_vecEndPos, end)
                
                if(entity)
                {
                    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
                    write_byte(TE_DECAL)
                    engfunc(EngFunc_WriteCoord, end[0])
                    engfunc(EngFunc_WriteCoord, end[1])
                    engfunc(EngFunc_WriteCoord, end[2])
		            write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS-1)])
                    write_short(entity)
                    message_end()
                }
                else
                {
                    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
                    write_byte(TE_WORLDDECAL)
                    engfunc(EngFunc_WriteCoord, end[0])
                    engfunc(EngFunc_WriteCoord, end[1])
                    engfunc(EngFunc_WriteCoord, end[2])
		            write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS-1)])
                    message_end()
                }
                message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
                write_byte(TE_BEAMENTPOINT)
                write_short(attacker | 0x1000)
                engfunc(EngFunc_WriteCoord, end[0])
                engfunc(EngFunc_WriteCoord, end[1])
                engfunc(EngFunc_WriteCoord, end[2])
                write_short(cvar_tracer_sprite[CURRENT_WEAPON])
                write_byte(1) // framerate
                write_byte(5) // framerate
                write_byte(2) // life
                write_byte(str_to_num(width))  // width
                write_byte(0)// noise
                write_byte(str_to_num(r_color))
                write_byte(str_to_num(g_color))
                write_byte(str_to_num(b_color))
                write_byte(255)
                write_byte(0)
                message_end()
            }
		}
	}
}

public fw_WorldModel(entity, model[])
{
    if (brokenConfig != 0)
    {
        return PLUGIN_HANDLED
    }

	static iOwner
    iOwner = pev(entity, pev_owner)

	new Classname[32], w_model[252]
    new CURRENT_WEAPON = HAS_WEAPON[iOwner]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))

	pev(entity, pev_classname, Classname, sizeof(Classname))

	if(!pev_valid(entity))
    {
        return FMRES_IGNORED
    }
	
	if(!equal(Classname, "weaponbox"))
    {
        return FMRES_IGNORED
    }

	for (new i = 0; i < sizeof(weapons_old_w); i++)
    {
        new old_W[252]
        formatex(old_W, charsmax(old_W), "models/%s.mdl", weapons_old_w[i])

	    if(equal(model, old_W))
	    {
		    if(HAS_WEAPON[iOwner])
		    {
                entity_set_string(entity, EV_SZ_classname, class_weapons[CURRENT_WEAPON])

                formatex(w_model,charsmax(w_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "w_model"))
			    engfunc(EngFunc_SetModel, entity, w_model)
                HAS_WEAPON[iOwner] = 0

			    return FMRES_SUPERCEDE
		    }
	    }
    }
    
    return PLUGIN_CONTINUE
}

public fw_CmdStart(client, uc_handle, seed)
{
    if (brokenConfig != 0)
    {
        return
    }

	new CURRENT_WEAPON = HAS_WEAPON[client]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	new wpn_id = get_user_weapon(client, _, _)

	if(!is_user_alive(client))
    {
		return
    }

	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	static OldButton; OldButton = pev(client, pev_oldbuttons)

	if (wpn_id == CHANGE_WEAPON && HAS_WEAPON[client] && cvar_secondary_type[CURRENT_WEAPON])
	{
		if ((NewButton & IN_RELOAD) && !(OldButton & IN_RELOAD))
		{
			set_pdata_int(client, m_iFOV, 90, 5);
			cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
			ResetFov(client)

			new v_model[999]
			formatex(v_model, charsmax(v_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "v_model"))
			set_pev(client, pev_viewmodel2, v_model)

			inTwoZoom[client] = 0
			inThreeZoom[client] = 0
		}
		else
		{
			if ((NewButton & IN_ATTACK2) && !(OldButton & IN_ATTACK2))
			{
				if (cvar_secondary_type[CURRENT_WEAPON] == 1 && !Disable_Type_Zoom[client])
				{
					set_weapon_timeidle(client, 0.3)
					set_pdata_float(client, m_flNextAttack, 0.3, 5)
					set_player_nextattack(client, 0.66)

					if (cs_get_user_zoom(client) == 1)
					{
						cs_set_user_zoom(client, CS_SET_AUGSG552_ZOOM, 1)
						if (get_cvar_num("nst_zoom_spk"))
						{
							client_cmd(0, "spk weapons/zoom.wav")
						}
					}
					else
					{
						cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
						if (get_cvar_num("nst_zoom_spk"))
						{
							client_cmd(0, "spk weapons/zoom.wav")
						}
					}
				}
				else if (cvar_secondary_type[CURRENT_WEAPON] == 2 && !Disable_Type_Zoom[client])
				{
					set_weapon_timeidle(client, 0.3)
					set_pdata_float(client, m_flNextAttack, 0.3, 5)
					set_player_nextattack(client, 0.66)

					if (!inTwoZoom[client])
					{
						inTwoZoom[client] = 1
						set_pdata_int(client, m_iFOV, 35, 5);
						if (get_cvar_num("nst_zoom_spk"))
						{
							client_cmd(0, "spk weapons/zoom.wav")
						}
					}
					else
					{
						inTwoZoom[client] = 0
						set_pdata_int(client, m_iFOV, 90, 5);
						if (get_cvar_num("nst_zoom_spk"))
						{
							client_cmd(0, "spk weapons/zoom.wav")
						}
					}
				}
				else if (cvar_secondary_type[CURRENT_WEAPON] == 3 && !Disable_Type_Zoom[client])
				{
					set_weapon_timeidle(client, 0.3)
					set_pdata_float(client, m_flNextAttack, 0.3, 5)
					set_player_nextattack(client, 0.66)
					if (!inThreeZoom[client])
					{
						inThreeZoom[client] = 1
						new sight_model[999]
						formatex(sight_model, charsmax(sight_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "sight_model"))
						set_pev(client, pev_viewmodel2, sight_model)
						SetFov(client, 70)

						if (get_cvar_num("nst_zoom_spk"))
						{
							client_cmd(0, "spk weapons/zoom.wav")
						}
					}
					else
					{
						inThreeZoom[client] = 0
						new v_model[999]
						formatex(v_model, charsmax(v_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "v_model"))
						set_pev(client, pev_viewmodel2, v_model)
						ResetFov(client)
						if (get_cvar_num("nst_zoom_spk"))
						{
							client_cmd(0, "spk weapons/zoom.wav")
						}
					}
				}
			}

		}

        new clip
        get_user_weapon(client, clip, _)

        //Sniper Zoom Fix
		if (cvar_secondary_type[CURRENT_WEAPON] == 3 && (wpn_id == CSW_SG550 || wpn_id == CSW_AWP || wpn_id == CSW_G3SG1 || wpn_id == CSW_SG552))
		{
			set_pdata_int(client, m_iFOV, 90, 5);
			cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
			ResetFov(client)

            if (clip == 0 || (NewButton & IN_RELOAD))
            {
                set_pdata_int(client, m_iFOV, 90, 5);
                cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
                ResetFov(client)

                new v_model[999]
			    formatex(v_model, charsmax(v_model), "models/%s", C_parse_pistol_config(CURRENT_WEAPON, "v_model"))
			    set_pev(client, pev_viewmodel2, v_model)

                inTwoZoom[client] = 0
			    inThreeZoom[client] = 0
            }
		}
        if (cvar_secondary_type[CURRENT_WEAPON] == 2 && (wpn_id == CSW_SG550 || wpn_id == CSW_AWP || wpn_id == CSW_G3SG1 || wpn_id == CSW_SG552))
        {
            if (clip == 0 || (NewButton & IN_RELOAD))
            {
                set_pdata_int(client, m_iFOV, 90, 5);
                cs_set_user_zoom(client, CS_SET_NO_ZOOM, 1)
                ResetFov(client)
            }
        }
    }
    else
    {
        inTwoZoom[client] = 0
        inThreeZoom[client] = 0
    }
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
    if (brokenConfig != 0)
    {
        return
    }

    if (!is_valid_ent(attacker))
    {
        return
    }

	new CURRENT_WEAPON = HAS_WEAPON[attacker]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
    new wpn_id = get_user_weapon(attacker, _, _)

	if (wpn_id == CHANGE_WEAPON && HAS_WEAPON[attacker])
	{
		SetHamParamFloat(4, damage * cvar_dmgmultiplier[CURRENT_WEAPON])
	}
}

public fw_PlayerSpawn_Post(id)
{
    if (brokenConfig != 0)
    {
        return
    }

    if (!is_valid_ent(id))
    {
        return
    }

	if (!is_user_alive(id))
    {
		return
    }

	if (is_user_bot(id))
	{
		new Float: time_give = random_float(1.0, 4.0)
		if (task_exists(id + TASK_GIVEWPNBOT)) 
        {
            remove_task(id + TASK_GIVEWPNBOT)
        }
		set_task(time_give, "nst_bot_weapons", id + TASK_GIVEWPNBOT)
	}
}

/* Game Events */
public event_commencing()
{
    commencing = 1
}

public event_damage(client)
{    
    if (brokenConfig != 0)
    {
        return PLUGIN_CONTINUE
    }

    if (!is_valid_ent(client))
    {
        return PLUGIN_CONTINUE
    }
    
	new weapon, attacker = get_user_attacker(client , weapon)

	new CURRENT_WEAPON = HAS_WEAPON[attacker]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
    
	if(!is_user_alive(attacker))
    {
		return PLUGIN_CONTINUE
    }

	if(weapon == CHANGE_WEAPON && HAS_WEAPON[attacker])
	{
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

public event_start_freezetime()
{
	remove_modded()
    commencing = 0
}

public event_new_round()
{
    round_time = get_gametime()
}

/* Client Events */
public client_connect(id)
{
	HAS_WEAPON[id] = 0
}

public client_disconnect(id)
{
	HAS_WEAPON[id] = 0
}

public client_putinserver(id)
{
    if (brokenConfig != 0)
    {
        return
    }

	if(is_user_bot(id))
	{
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

/* Bot Registration */
public Do_RegisterHam_Bot(id)
{
    if (brokenConfig != 0)
    {
        return
    }

    if (!is_valid_ent(id))
    {
        return
    }

    if (is_user_alive(id)) 
    {
        fw_PlayerSpawn_Post(id)
    }

    RegisterHamFromEntity(Ham_Item_PostFrame, id , "Item_PostFrame")
    RegisterHamFromEntity(Ham_Item_Deploy, id, "Weapon_Deploy_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
    RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Touch, id, "OnPlayerTouchWeaponBox")
}

public nst_bot_weapons(taskid)
{
    if (brokenConfig != 0)
    {
        return
    }

	new id = (taskid - TASK_GIVEWPNBOT)

	new CURRENT_WEAPON = HAS_WEAPON[id]
	new CHANGE_WEAPON = str_to_num(C_parse_pistol_config(CURRENT_WEAPON, "wpn_id"))
	new wpn_id = get_user_weapon(id, _, _)

    if (!is_valid_ent(id))
    {
        return
    }

    if (!is_user_alive(id))
    {
        return
    }

	if (get_cvar_num("nst_give_bot"))
	{
	    if(wpn_id == CHANGE_WEAPON && HAS_WEAPON[id])
		{
			ClientCommand_buyammo2(id)
		}
		else 
        {
            if (!user_has_secondary(id))
            {
                new random_weapon_id = random_num(0, ArraySize(Pistol_Names)-1)
                if (random_weapon_id != 0)
                {
                    Buy_Weapon(id, random_weapon_id)
                }
            }
        }
	}
}

/* Other Functions */
public remove_modded()
{
    for (new entity = 1; entity < 100000; entity++)
    {
        if (is_valid_ent(entity))
        {
            static Class[10]
            pev(entity, pev_classname, Class, sizeof Class - 1)
                
            if (equal(Class, "weaponbox"))
            {
                set_pev(entity, pev_nextthink, get_gametime() + 1)
            }

            server_print("Removed All WeaponBox")
        }
    }
	return PLUGIN_CONTINUE
}
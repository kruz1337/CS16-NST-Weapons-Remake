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

#define PLUGIN "NST Knifes"
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
new Array: Knife_InfoText;
new Array: Knife_Names;
new Array: Knifes_Number;

/* Config Variables */
const NEXT_SECTION = 24
const END_SECTION = 22
const s_administrator = 1
const s_administrator_next = 25
const s_cost = 2
const s_cost_next = 26
const s_damage = 3
const s_damage_next = 27
const s_deploy = 4
const s_deploy_next = 28
const s_speed = 5
const s_speed_next = 29
const s_speed2 = 6
const s_speed2_next = 30
const s_knockback = 7
const s_knockback_next = 31
const s_fastrun = 8
const s_fastrun_next = 32
const s_jump_power = 9
const s_jump_power_next = 33
const s_jump_gravity = 10
const s_jump_gravity_next = 34
const s_sound_deploy = 11
const s_sound_deploy_next = 35
const s_sound_hit1 = 12
const s_sound_hit1_next = 36
const s_sound_hit2 = 13
const s_sound_hit2_next = 37
const s_sound_hit3 = 14
const s_sound_hit3_next = 38
const s_sound_hit4 = 15
const s_sound_hit4_next = 39
const s_sound_hitwall = 16
const s_sound_hitwall_next = 40
const s_sound_slash1 = 17
const s_sound_slash1_next = 41
const s_sound_slash2 = 18
const s_sound_slash2_next = 42
const s_sound_stab = 19
const s_sound_stab_next = 43
const s_v_model = 20
const s_v_model_next = 44
const s_p_model = 21
const s_p_model_next = 45
const s_w_model = 22
const s_w_model_next = 46

/* Integers */
const MAX_WPN = 5000
new brokenConfig = 0
new commencing = 0
new HAS_WEAPON[33]
new CURRENT_WEAPON[33]
new IN_BITVAR_JUMP

/* Weapon Variables */
new class_knifes[MAX_WPN][32]

new Float:cvar_deploy[MAX_WPN]
new Float:cvar_knockback[MAX_WPN]
new Float:cvar_dmgmultiplier[MAX_WPN]
new Float:cvar_speed[MAX_WPN]
new Float:cvar_speed2[MAX_WPN]
new Float:cvar_jumppower[MAX_WPN]
new Float:cvar_jumpgravity[MAX_WPN]
new Float:cvar_fastrun[MAX_WPN]

new Float:round_time

new cvar_cost[MAX_WPN]
new cvar_administrator[MAX_WPN]

public plugin_init()
{
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

public plugin_startup()
{
	Knifes_Number = ArrayCreate(1)
	Knife_Names = ArrayCreate(64)
	Knife_InfoText = ArrayCreate(128)

	C_read_knife_config()
	C_read_knife_sections()
	C_check_knife_config()
}

public plugin_precache()
{
	plugin_startup()

	if (brokenConfig == 0)
	{
		for (new i = 1; i < ArraySize(Knife_Names); i++)
		{
			new v_model[252], p_model[252], w_model[252], sight_model[252]
			formatex(v_model, charsmax(v_model), "models/%s", C_parse_knife_config(i, "v_model"))
			formatex(p_model, charsmax(p_model), "models/%s", C_parse_knife_config(i, "p_model"))
			formatex(w_model, charsmax(w_model), "models/%s", C_parse_knife_config(i, "w_model"))

			precache_model(v_model)
			precache_model(p_model)
			precache_model(w_model)
		}

		for (new i = 1; i < ArraySize(Knife_Names); i++)
		{
			new hitwall[252], deploy[252], stab[252]
			new hit1[252], hit2[252], hit3[252], hit4[252]
			new slash1[252], slash2[252]

			formatex(hitwall, charsmax(hitwall), "weapons/%s", C_parse_knife_config(i, "sound_hitwall"))
			formatex(deploy, charsmax(deploy), "weapons/%s", C_parse_knife_config(i, "sound_deploy"))
			formatex(stab, charsmax(stab), "weapons/%s", C_parse_knife_config(i, "sound_stab"))
			formatex(slash1, charsmax(slash1), "weapons/%s", C_parse_knife_config(i, "sound_slash1"))
			formatex(slash2, charsmax(slash2), "weapons/%s", C_parse_knife_config(i, "sound_slash2"))
			formatex(hit1, charsmax(hit1), "weapons/%s", C_parse_knife_config(i, "sound_hit1"))
			formatex(hit2, charsmax(hit2), "weapons/%s", C_parse_knife_config(i, "sound_hit2"))
			formatex(hit3, charsmax(hit3), "weapons/%s", C_parse_knife_config(i, "sound_hit3"))
			formatex(hit4, charsmax(hit4), "weapons/%s", C_parse_knife_config(i, "sound_hit4"))

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
		for (new wpnid = 0; wpnid < ArraySize(Knifes_Number); wpnid++)
		{
			if (wpnid != 0)
			{
				ArrayGetString(Knife_Names, wpnid, model, charsmax(model))

				trim(model)
				replace(model, 64, " ", "_")
				strtolower(model)

				format(class_knifes[wpnid], 31, "nst_%s", model)

				cvar_cost[wpnid] = str_to_num(C_parse_knife_config(wpnid, "cost"))
				cvar_administrator[wpnid] = str_to_num(C_parse_knife_config(wpnid, "administrator"))

				cvar_deploy[wpnid] = str_to_float(C_parse_knife_config(wpnid, "deploy"))
				cvar_knockback[wpnid] = str_to_float(C_parse_knife_config(wpnid, "knockback"))
				cvar_dmgmultiplier[wpnid] = str_to_float(C_parse_knife_config(wpnid, "damage"))
				cvar_speed[wpnid] = str_to_float(C_parse_knife_config(wpnid, "speed"))
				cvar_speed2[wpnid] = str_to_float(C_parse_knife_config(wpnid, "speed2"))
				cvar_jumppower[wpnid] = str_to_float(C_parse_knife_config(wpnid, "jump_power"))
				cvar_jumpgravity[wpnid] = str_to_float(C_parse_knife_config(wpnid, "jump_gravity"))
				cvar_fastrun[wpnid] = str_to_float(C_parse_knife_config(wpnid, "fastrun"))
			}
		}
	}
}

/*Config Functions */
public C_read_knife_sections()
{
	new sectionNumber = 0
	new szTemp[64]

	for (new i = 0; i < ArraySize(Knife_InfoText); i++)
	{
		if (i == 0)
		{
			ArrayPushString(Knife_Names, szTemp)
			ArrayPushCell(Knifes_Number, sectionNumber)
			i++;
		}

		ArrayGetString(Knife_InfoText, sectionNumber, szTemp, charsmax(szTemp))
		replace(szTemp, 999, "[", "")
		replace(szTemp, 999, "]", "")
		replace(szTemp, 999, "^n", "")
		ArrayPushString(Knife_Names, szTemp)
		ArrayPushCell(Knifes_Number, sectionNumber)

		if (ArraySize(Knife_InfoText) > sectionNumber + NEXT_SECTION)
		{
			sectionNumber = sectionNumber + NEXT_SECTION
		}
		else
		{
			i = ArraySize(Knife_InfoText)
		}
	}

	sectionNumber = 0
}

public C_check_knife_config()
{
	new messageTex[999]
	new _knifes_File[100] = { "addons/amxmodx/configs/nst_weapons/nst_knifes.ini" }

	formatex(messageTex[0], charsmax(messageTex) - 0, "%L", LANG_PLAYER, "BROKEN_CONFIG")
	if (file_exists(_knifes_File) == 1)
	{
		if (C_knife_syntaxRules() == -1)
		{
			replace(messageTex, 999, "$", "new Array: Knife_InfoText;")
			server_print("[NST Weapons] %s", messageTex)
			brokenConfig = 1
		}
		else
		{
			brokenConfig = 0
		}
	}
}

public C_read_knife_config()
{
	new buffer[128]
	new right[128], left[128]
	new left_comment[128], right_comment[128], left_s_comment[128], right_s_comment[128]

	new fp_knifes = fopen("addons/amxmodx/configs/nst_weapons/nst_knifes.ini", "r")
	while (!feof(fp_knifes))
	{
		fgets(fp_knifes, buffer, charsmax(buffer))

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

		ArrayPushString(Knife_InfoText, buffer)

		for (new i = 0; i < ArraySize(Knife_InfoText); i++)
		{
			new szTemp[128]
			ArrayGetString(Knife_InfoText, i, szTemp, charsmax(szTemp))
			if (equali(szTemp, "_THIS_IS_COMMENT_LINE_"))
			{
				ArrayDeleteItem(Knife_InfoText, i)
			}
		}
	}

	fclose(fp_knifes)
}

stock C_parse_knife_config(const strKey, const Property[])
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

	if (equali(Property, "damage"))
	{
		PropertyNumber = s_damage
	}

	if (equali(Property, "deploy"))
	{
		PropertyNumber = s_deploy
	}

	if (equali(Property, "speed"))
	{
		PropertyNumber = s_speed
	}

	if (equali(Property, "speed2"))
	{
		PropertyNumber = s_speed2
	}

	if (equali(Property, "knockback"))
	{
		PropertyNumber = s_knockback
	}

	if (equali(Property, "jump_power"))
	{
		PropertyNumber = s_jump_power
	}

	if (equali(Property, "jump_gravity"))
	{
		PropertyNumber = s_jump_gravity
	}

	if (equali(Property, "fastrun"))
	{
		PropertyNumber = s_fastrun
	}

	if (equali(Property, "sound_deploy"))
	{
		PropertyNumber = s_sound_deploy
	}

	if (equali(Property, "sound_hit1"))
	{
		PropertyNumber = s_sound_hit1
	}

	if (equali(Property, "sound_hit2"))
	{
		PropertyNumber = s_sound_hit2
	}

	if (equali(Property, "sound_hit3"))
	{
		PropertyNumber = s_sound_hit3
	}

	if (equali(Property, "sound_hit4"))
	{
		PropertyNumber = s_sound_hit4
	}

	if (equali(Property, "sound_hitwall"))
	{
		PropertyNumber = s_sound_hitwall
	}

	if (equali(Property, "sound_slash1"))
	{
		PropertyNumber = s_sound_slash1
	}

	if (equali(Property, "sound_slash2"))
	{
		PropertyNumber = s_sound_slash2
	}

	if (equali(Property, "sound_stab"))
	{
		PropertyNumber = s_sound_stab
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

	ArrayGetString(Knife_InfoText, ArrayGetCell(Knifes_Number, strKey) + PropertyNumber, parserLine, charsmax(parserLine))
	strtok(parserLine, leftValue, 64, rightValue, 127, '=')
	trim(leftValue);
	trim(rightValue);

	return rightValue
}

stock C_knife_syntaxRules()
{
	new buffer[128], leftValue[128], rightValue[128]
	new lineFixer[24]
	new firstChar[15], endChar[15]

	for (new i = 0; i < ArraySize(Knife_InfoText); i++)
	{
		ArrayGetString(Knife_InfoText, i, buffer, charsmax(buffer))
		replace(buffer, 128, "^n", "")
		strtok(buffer, leftValue, 128, rightValue, 128, '=')
		trim(leftValue);
		trim(rightValue);

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

		if (i == lineFixer[2] + s_administrator_next)
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
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[3] + s_cost_next)
		{
			lineFixer[3] = lineFixer[3] + NEXT_SECTION;

			if (equal(leftValue, "cost"))
			{
				if (!isdigit(rightValue[0]))
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
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[4] + s_damage_next)
		{
			lineFixer[4] = lineFixer[4] + NEXT_SECTION;

			if (equal(leftValue, "damage"))
			{
				if (!isdigit(rightValue[0]))
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
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[5] + s_deploy_next)
		{
			lineFixer[5] = lineFixer[5] + NEXT_SECTION;

			if (equal(leftValue, "deploy"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
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
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[6] + s_speed_next)
		{
			lineFixer[6] = lineFixer[6] + NEXT_SECTION;

			if (equal(leftValue, "speed"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == s_speed2)
		{
			if (equal(leftValue, "speed2"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[7] + s_speed2_next)
		{
			lineFixer[7] = lineFixer[7] + NEXT_SECTION;

			if (equal(leftValue, "speed2"))
			{
				if (!isdigit(rightValue[0]))
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
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[8] + s_knockback_next)
		{
			lineFixer[8] = lineFixer[8] + NEXT_SECTION;

			if (equal(leftValue, "knockback"))
			{
				if (!isdigit(rightValue[0]))
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
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[9] + s_fastrun_next)
		{
			lineFixer[9] = lineFixer[9] + NEXT_SECTION;

			if (equal(leftValue, "fastrun"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == s_jump_power)
		{
			if (equal(leftValue, "jump_power"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[10] + s_jump_power_next)
		{
			lineFixer[11] = lineFixer[11] + NEXT_SECTION;

			if (equal(leftValue, "jump_power"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == s_jump_gravity)
		{
			if (equal(leftValue, "jump_gravity"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == lineFixer[11] + s_jump_gravity_next)
		{
			lineFixer[11] = lineFixer[11] + NEXT_SECTION;

			if (equal(leftValue, "jump_gravity"))
			{
				if (!isdigit(rightValue[0]))
				{
					return -1;
				}
			}
			else
			{
				return -1
			}
		}

		if (i == s_sound_deploy)
		{
			if (equal(leftValue, "sound_deploy"))
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

		if (i == lineFixer[12] + s_sound_deploy_next)
		{
			lineFixer[12] = lineFixer[12] + NEXT_SECTION;

			if (equal(leftValue, "sound_deploy"))
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

		if (i == s_sound_hit1)
		{
			if (equal(leftValue, "sound_hit1"))
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

		if (i == lineFixer[13] + s_sound_hit1_next)
		{
			lineFixer[13] = lineFixer[13] + NEXT_SECTION;

			if (equal(leftValue, "sound_hit1"))
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

		if (i == s_sound_hit2)
		{
			if (equal(leftValue, "sound_hit2"))
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

		if (i == lineFixer[14] + s_sound_hit2_next)
		{
			lineFixer[14] = lineFixer[14] + NEXT_SECTION;

			if (equal(leftValue, "sound_hit2"))
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

		if (i == s_sound_hit3)
		{
			if (equal(leftValue, "sound_hit3"))
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

		if (i == lineFixer[15] + s_sound_hit3_next)
		{
			lineFixer[15] = lineFixer[15] + NEXT_SECTION;

			if (equal(leftValue, "sound_hit3"))
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

		if (i == s_sound_hit4)
		{
			if (equal(leftValue, "sound_hit4"))
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

		if (i == lineFixer[16] + s_sound_hit4_next)
		{
			lineFixer[16] = lineFixer[16] + NEXT_SECTION;

			if (equal(leftValue, "sound_hit4"))
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

		if (i == s_sound_hitwall)
		{
			if (equal(leftValue, "sound_hitwall"))
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

		if (i == lineFixer[17] + s_sound_hitwall_next)
		{
			lineFixer[17] = lineFixer[17] + NEXT_SECTION;

			if (equal(leftValue, "sound_hitwall"))
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

		if (i == s_sound_slash1)
		{
			if (equal(leftValue, "sound_slash1"))
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

		if (i == lineFixer[18] + s_sound_slash1_next)
		{
			lineFixer[18] = lineFixer[18] + NEXT_SECTION;

			if (equal(leftValue, "sound_slash1"))
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

		if (i == s_sound_slash2)
		{
			if (equal(leftValue, "sound_slash2"))
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

		if (i == lineFixer[19] + s_sound_slash2_next)
		{
			lineFixer[19] = lineFixer[19] + NEXT_SECTION;

			if (equal(leftValue, "sound_slash2"))
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

		if (i == s_sound_stab)
		{
			if (equal(leftValue, "sound_stab"))
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

		if (i == lineFixer[20] + s_sound_stab_next)
		{
			lineFixer[20] = lineFixer[20] + NEXT_SECTION;

			if (equal(leftValue, "sound_stab"))
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

		if (i == lineFixer[21] + s_v_model_next)
		{
			lineFixer[21] = lineFixer[21] + NEXT_SECTION;

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

		if (i == lineFixer[22] + s_p_model_next)
		{
			lineFixer[22] = lineFixer[22] + NEXT_SECTION;

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

		if (i == lineFixer[23] + s_w_model_next)
		{
			lineFixer[23] = lineFixer[23] + NEXT_SECTION;

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

		if (i == lineFixer[0] + END_SECTION)
		{
			lineFixer[0] = lineFixer[0] + NEXT_SECTION
			i++;
		}
	}

	return 0;
}

/*All Stocks */
stock create_velocity_vector(victim, attacker, Float: velocity[3], Float: knockback)
{
	if (!is_user_alive(attacker))
	{
		return 0;
	}

	if (!is_valid_ent(attacker))
	{
		return 0;
	}

	new Float: victim_origin[3], Float: attacker_origin[3], Float: new_origin[3];

	entity_get_vector(victim, EV_VEC_origin, victim_origin);
	entity_get_vector(attacker, EV_VEC_origin, attacker_origin);

	new_origin[0] = victim_origin[0] - attacker_origin[0];
	new_origin[1] = victim_origin[1] - attacker_origin[1];

	velocity[0] = (new_origin[0] *(knockback *900)) / get_entity_distance(victim, attacker);
	velocity[1] = (new_origin[1] *(knockback *900)) / get_entity_distance(victim, attacker);

	return 1;
}

stock set_weapon_timeidle(id, Float: TimeIdle)
{
	new CURRENT_WEAPON = HAS_WEAPON[id]

	if (!is_user_alive(id))
	{
		return
	}

	static entwpn;
	entwpn = fm_get_user_weapon_entity(id, CSW_KNIFE)

	if (!pev_valid(entwpn))
	{
		return
	}

	set_pdata_float(entwpn, m_flNextPrimaryAttack, TimeIdle, 4)
	set_pdata_float(entwpn, m_flNextSecondaryAttack, TimeIdle, 4)
	set_pdata_float(entwpn, m_flTimeWeaponIdle, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(id, Float: nexttime)
{
	if (!is_user_alive(id))
		return

	set_pdata_float(id, 83, nexttime, 5)
}

stock format_knife_sound(wpn_id, const config_sound[])
{
	new formatted_sound[512]
	formatex(formatted_sound, charsmax(formatted_sound), "weapons/%s", C_parse_knife_config(wpn_id, config_sound))
	return formatted_sound
}

/* Menu Function */
public NST_Knife(client)
{
	new szTemp[64]
	new menu[512], menuxx
	new text[256], len = 0
	new administrator, wpn_id
	formatex(menu, charsmax(menu), "%L", LANG_PLAYER, "MENU_TITLE")
	menuxx = menu_create(menu, "Get_NSTMelee")

	if (brokenConfig == 0 && commencing == 0)
	{
		for (new i = 1; i < ArraySize(Knife_Names); i++)
		{
			administrator = str_to_num(C_parse_knife_config(i, "administrator"))
			new menuKey[64]
			ArrayGetString(Knife_Names, i, szTemp, charsmax(szTemp))

			if (administrator == 0)
			{
				formatex(menu, charsmax(menu), "%s 	\r$%s", szTemp, C_parse_knife_config(i, "cost"))
				num_to_str(i + 1, menuKey, 999)
				menu_additem(menuxx, menu, menuKey)
			}
			else
			{
				formatex(menu, charsmax(menu), "\y%s 	\r$%s", szTemp, C_parse_knife_config(i, "cost"))
				num_to_str(i + 1, menuKey, 999)
				menu_additem(menuxx, menu, menuKey)
			}
		}
	}
	else
	{
		C_check_knife_config()
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

/* All Knife Properties */
public Get_NSTMelee(client, menu, item)
{
	new access, callback, data[6], name[64]
	menu_item_getinfo(menu, item, access, data, 5, name, 63, callback)
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
		new user_money = get_user_money(id)
		new wp_cost = cvar_cost[wpnid]
		new administrator = cvar_administrator[wpnid]

		if (!(get_user_flags(id) &ADMIN_KICK) && administrator == 1)
		{
			client_print(id, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ACCESS_DENIED_BUY")
		}
		else if (!is_user_alive(id))
		{
			client_print(id, print_chat, "[NST Weapons] %L", LANG_PLAYER, "NOT_LIVE")
		}
		else if (get_gametime() - round_time > get_cvar_num("nst_buy_time"))
		{
			engclient_print(id, engprint_center, "%L", LANG_PLAYER, "BUY_TIME_END", get_cvar_num("nst_buy_time"));
		}
		else if (HAS_WEAPON[id] == wpnid)
		{
			new szTemp[256]
			ArrayGetString(Knife_Names, HAS_WEAPON[id], szTemp, charsmax(szTemp))

			client_print(id, print_chat, "[NST Weapons] %L", LANG_PLAYER, "ALREADY_HAVE", szTemp)
		}
		else if (get_cvar_num("nst_free") ? wp_cost <= get_user_money(id) : 1)
		{
			CURRENT_WEAPON[id] = wpnid
			HAS_WEAPON[id] = wpnid
			Current_Weapon(id)

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

public ReBuy_Knife(id)
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

public Current_Weapon(client)
{
	if (brokenConfig != 0)
	{
		return PLUGIN_HANDLED
	}

	new CURRENT_WEAPON = HAS_WEAPON[client]

	new clip, ammo
	new wpn_id = get_user_weapon(client, clip, ammo)

	if (wpn_id == CSW_KNIFE && HAS_WEAPON[client])
	{		
		new v_model[999], p_model[999], sight_model[999]
		formatex(v_model, charsmax(v_model), "models/%s", C_parse_knife_config(CURRENT_WEAPON, "v_model"))
		formatex(p_model, charsmax(p_model), "models/%s", C_parse_knife_config(CURRENT_WEAPON, "p_model"))

		set_pev(client, pev_viewmodel2, v_model)
		set_pev(client, pev_weaponmodel2, p_model)
	}

	return PLUGIN_HANDLED
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
	new wpn_id = get_user_weapon(client, _, _)

	if (wpn_id == CSW_KNIFE && HAS_WEAPON[client])
	{
		set_pdata_float(entity, m_flNextPrimaryAttack, cvar_speed[CURRENT_WEAPON], 4)
	}

	return FMRES_SUPERCEDE
}

public Secondary_Attack_Post(entity)
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
	new wpn_id = get_user_weapon(client, _, _)

	if (HAS_WEAPON[client])
	{
		set_pdata_float(entity, m_flNextSecondaryAttack, cvar_speed2[CURRENT_WEAPON], 4)
	}

	return FMRES_SUPERCEDE
}

public Weapon_Deploy_Post(entity)
{
	if (brokenConfig != 0)
	{
		return PLUGIN_HANDLED
	}

	new id = get_pdata_cbase(entity, m_pPlayer, 4);
	new CURRENT_WEAPON = HAS_WEAPON[id]
	new wpn_id = get_user_weapon(id, _, _)

	if (!pev_valid(entity))
	{
		return HAM_IGNORED;
	}

	if (!is_user_alive(id))
	{
		return HAM_IGNORED;
	}

	if (HAS_WEAPON[id])
	{
		emit_sound(id, CHAN_WEAPON, format_knife_sound(CURRENT_WEAPON, "sound_deploy"), VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_weapon_timeidle(id, cvar_deploy[CURRENT_WEAPON])
		set_player_nextattack(id, cvar_deploy[CURRENT_WEAPON])
	}

	return HAM_IGNORED
}

/* Forwards */
public fw_EmitSound(entity, channel, sound[], Float: volume, Float: attenuation, fFlags, pitch)
{
	if (!is_user_alive(entity))
	{
		return FMRES_IGNORED
	}

	new CURRENT_WEAPON = HAS_WEAPON[entity]
	new wpn_id = get_user_weapon(entity, _, _)

	if (wpn_id == CSW_KNIFE && HAS_WEAPON[entity])
	{
		if (equali(sound, "weapons/knife_hit1.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit1"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}

		if (equali(sound, "weapons/knife_hit2.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit2"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}

		if (equali(sound, "weapons/knife_hit3.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit3"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}

		if (equali(sound, "weapons/knife_hit4.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hit4"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}

		if (equali(sound, "weapons/knife_hitwall1.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_hitwall"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}

		if (equali(sound, "weapons/knife_slash1.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_slash1"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}

		if (equali(sound, "weapons/knife_slash2.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_slash2"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}

		if (equali(sound, "weapons/knife_stab.wav"))
		{
			emit_sound(entity, channel, format_knife_sound(CURRENT_WEAPON, "sound_stab"), volume, attenuation, fFlags, pitch)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public fw_PlayerPreThink(client)
{
	if(!is_user_alive(client))
	{
		return FMRES_IGNORED
	}

	new CURRENT_WEAPON = HAS_WEAPON[client]
	new wpn_id = get_user_weapon(client, _, _)

	if (wpn_id == CSW_KNIFE && HAS_WEAPON[client])
	{
		entity_set_float(client, EV_FL_maxspeed, 240.0 + cvar_fastrun[CURRENT_WEAPON])

		if ((pev(client, pev_button) & IN_JUMP) && !(pev(client, pev_oldbuttons) & IN_JUMP))
		{
			new flags = pev(client, pev_flags)
			new waterlvl = pev(client, pev_waterlevel)
				
			if (!(flags & FL_ONGROUND))
			{
				return FMRES_IGNORED
			}

			if (flags & FL_WATERJUMP)
			{
				return FMRES_IGNORED
			}

			if (waterlvl > 1)
			{
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

	if ((pev(client, pev_button) & IN_JUMP) && !(pev(client, pev_oldbuttons) & IN_JUMP))
	{

	}
	else
	{
		if (Get_BitVar(IN_BITVAR_JUMP, client))
		{
			if ((pev(client, pev_flags) & FL_ONGROUND))
			{
				set_user_gravity(client, 1.0)
				UnSet_BitVar(IN_BITVAR_JUMP, client)
			}
		}
	}

	return FMRES_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float: damage)
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
	new weapon = get_user_weapon(attacker)

	if (weapon == CSW_KNIFE && HAS_WEAPON[attacker])
	{
		SetHamParamFloat(4, damage *cvar_dmgmultiplier[CURRENT_WEAPON])
	}
}

/* Client Events */
public client_putinserver(id)
{
	if (brokenConfig != 0)
	{
		return
	}

	if (is_user_bot(id))
	{
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

/* Game Events */
public event_commencing()
{
	commencing = 1

	new id = read_data(2)
	new CURRENT_WEAPON = HAS_WEAPON[id]

	if (HAS_WEAPON[id])
	{
		HAS_WEAPON[id] = 0
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
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
	new weapon, attacker = get_user_attacker(client, weapon)

	new CURRENT_WEAPON = HAS_WEAPON[attacker]

	if (!is_user_alive(attacker))
	{
		return PLUGIN_CONTINUE
	}

	if (weapon == CSW_KNIFE && HAS_WEAPON[attacker])
	{
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

public event_death()
{
	new id = read_data(2)
	new CURRENT_WEAPON = HAS_WEAPON[id]

	if (HAS_WEAPON[id])
	{
		HAS_WEAPON[id] = 0
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public event_start_freezetime()
{
	commencing = 0
}

public event_new_round()
{
	round_time = get_gametime()
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

	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}
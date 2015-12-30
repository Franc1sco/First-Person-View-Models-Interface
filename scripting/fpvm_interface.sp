#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#undef REQUIRE_EXTENSIONS
#include <dhooks>

#define DATA "1.4"

Handle array_weapons[MAXPLAYERS+1];

bool eco_items = false;

int g_PVMid[MAXPLAYERS+1];

Handle hGiveNamedItem, hGiveNamedItem2;
bool nosir[MAXPLAYERS+1];

new OldSequence[MAXPLAYERS+1];
new Float:OldCycle[MAXPLAYERS+1];

bool hook[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "SM First Person View Models Interface",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(GetEngineVersion() == Engine_CSGO || GetEngineVersion() == Engine_TF2) eco_items = true;
	
	CreateNative("FPVMI_AddViewModelToClient", Native_AddWeapon);
	CreateNative("FPVMI_RemoveViewModelToClient", Native_RemoveWeapon);
    
	MarkNativeAsOptional("DHookCreate");
	MarkNativeAsOptional("DHookAddParam");
	MarkNativeAsOptional("DHookEntity");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_fpvmi_version", DATA, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//HookEvent("weapon_fire", EventWeaponFire);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	
	Handle hGameConf;
	
	hGameConf = LoadGameConfigFile("sdktools.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Gamedata file sdktools.games.txt is missing.");
	int iOffset = GameConfGetOffset(hGameConf, "GiveNamedItem");
	CloseHandle(hGameConf);
	if(iOffset == -1)
		SetFailState("Gamedata is missing the \"GiveNamedItem\" offset.");
	
	hGiveNamedItem = DHookCreate(iOffset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, OnGiveNamedItem);
	DHookAddParam(hGiveNamedItem, HookParamType_CharPtr);
	DHookAddParam(hGiveNamedItem, HookParamType_Int);
	DHookAddParam(hGiveNamedItem, HookParamType_Unknown);
	DHookAddParam(hGiveNamedItem, HookParamType_Bool);
	
	hGiveNamedItem2 = DHookCreate(iOffset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, OnGiveNamedItemPre);
}

/* public Action:EventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    // Get all required event info.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new model_index;
	char classname[64];
	if(!GetEdictClassname(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), classname, 64)) return;
	
	if(!GetTrieValue(array_weapons[client], classname, model_index) || model_index == -1) return;
	
	new Sequence = GetEntProp(g_PVMid[client], Prop_Send, "m_nSequence");
	
	PrintToConsole(client, "secuencia POST fire %i",Sequence);
} */

public OnPostThinkPostKnifeFix(client)
{
	new clientview = EntRefToEntIndex(g_PVMid[client]);
	if(clientview == INVALID_ENT_REFERENCE)
	{
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPostKnifeFix);
		//PrintToChat(client, "quitado");
		hook[client] = false;
		return;
	}
	
	new Sequence = GetEntProp(clientview, Prop_Send, "m_nSequence");
	new Float:Cycle = GetEntPropFloat(clientview, Prop_Data, "m_flCycle");
	if ((Cycle < OldCycle[client]) && (Sequence == OldSequence[client]))
	{
		//PrintToConsole(client, "FIX = secuencia %i",Sequence);
		switch (Sequence)
		{
			case 3:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 4);
			case 4:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 3);
			case 5:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 6);
			case 6:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 5);
			case 7:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 8);
			case 8:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 7);
			case 9:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 10);
			case 10:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 11); 
			case 11:
				SetEntProp(clientview, Prop_Send, "m_nSequence", 10);
		}
		
		//SetEntProp(clientview, Prop_Send, "m_nSequence", Sequence);
	}
	
	OldSequence[client] = Sequence;
	OldCycle[client] = Cycle;
}

public MRESReturn OnGiveNamedItem(int client, Handle hReturn, Handle hParams)
{
	new model_index;
	char classname[64];
	
	DHookGetParamString(hParams, 1, classname, 64);
	
	if(!GetTrieValue(array_weapons[client], classname, model_index) || model_index == -1) return MRES_Ignored;
	
	new weapon = DHookGetReturn(hReturn);
	
	if(eco_items)
	{
		SetEntProp(weapon, Prop_Send, "m_iItemIDLow", 0);
		SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", 0);
	}
	
	nosir[client] = false;
	return MRES_Ignored;
}

public MRESReturn OnGiveNamedItemPre(int client, Handle hReturn, Handle hParams)
{
	nosir[client] = true;
	
	return MRES_Ignored;
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client)) return;
	
	g_PVMid[client] = INVALID_ENT_REFERENCE;
	hook[client] = false;
	
	array_weapons[client] = CreateTrie();
	
	SDKHook(client, SDKHook_WeaponSwitchPost, OnClientWeaponSwitchPost); 
	SDKHook(client, SDKHook_WeaponSwitch, OnClientWeaponSwitch); 
	
	if(eco_items)
	{
		DHookEntity(hGiveNamedItem, true, client);
		DHookEntity(hGiveNamedItem2, false, client);
		//SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPostKnifeFix);
	}
}

public Action PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(hook[client])
	{
		//PrintToChat(client, "quitado");
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPostKnifeFix);
		hook[client] = false;
	}
}

public void OnClientWeaponSwitch(int client, int wpnid) 
{ 
	if(hook[client])
	{
		//PrintToChat(client, "quitado");
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPostKnifeFix);
		hook[client] = false;
	}
}

public void OnClientWeaponSwitchPost(int client, int wpnid) 
{ 
	if(wpnid < 1)
	{
		return;
	}
	char classname[64], classname_default[64];
	
	if(!GetEdictClassname(wpnid, classname, sizeof(classname)))
	{
		return;
	}
	
	new model_index;
	
	if(!GetTrieValue(array_weapons[client], classname, model_index))
	{
		return;
	}
	
	Format(classname_default, sizeof(classname_default), "%s_default", classname);
	
	
	new clientview = EntRefToEntIndex(g_PVMid[client]);
	if(clientview == INVALID_ENT_REFERENCE)
	{
		g_PVMid[client] = newWeapon_GetViewModelIndex(client, -1); 
		clientview = EntRefToEntIndex(g_PVMid[client]);
		if(clientview == INVALID_ENT_REFERENCE) 
		{
			return;
		}
	}
	
	if(model_index == -1)
	{
		if(!GetTrieValue(array_weapons[client], classname_default, model_index) || model_index == -1) return;
		
		SetEntProp(clientview, Prop_Send, "m_nModelIndex", model_index); 
		SetTrieValue(array_weapons[client], classname_default, -1);
		return;
	}
	
 	if(eco_items && !nosir[client])
	{
		if(GetEntProp(wpnid, Prop_Send, "m_iItemIDLow") != 0 || GetEntProp(wpnid, Prop_Send, "m_iItemIDHigh") != 0) 
		{
			if(!GetTrieValue(array_weapons[client], classname_default, model_index) || model_index == -1) return;
			
			SetEntProp(clientview, Prop_Send, "m_nModelIndex", model_index); 
			return;
			
		}
	}
	
	SetEntProp(wpnid, Prop_Send, "m_nModelIndex", 0); 
		
/*  	int iWorldModel = GetEntPropEnt(wpnid, Prop_Send, "m_hWeaponWorldModel"); 
	if(IsValidEdict(iWorldModel)) SetEntProp(iWorldModel, Prop_Send, "m_nModelIndex", 0);  */ 
	
	int model_index_custom = model_index;
	
	if(!GetTrieValue(array_weapons[client], classname_default, model_index) || model_index == -1) SetTrieValue(array_weapons[client], classname_default, GetEntProp(clientview, Prop_Send, "m_nModelIndex"));
	
	SetEntProp(clientview, Prop_Send, "m_nModelIndex", model_index_custom); 
	
	if(StrEqual(classname, "weapon_knife"))
	{
		hook[client] = true;
		//PrintToChat(client, "puesto");
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPostKnifeFix);
	}
}

public void OnClientDisconnect(int client)
{
	if(array_weapons[client] != INVALID_HANDLE) CloseHandle(array_weapons[client]);
	
	array_weapons[client] = INVALID_HANDLE;
}

public Native_AddWeapon(Handle:plugin, argc)
{  
	char name[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	int model_index = GetNativeCell(3);
	
	SetTrieValue(array_weapons[client], name, model_index);
	
	RefreshWeapon(client, name);
}

public Native_RemoveWeapon(Handle:plugin, argc)
{  
	char name[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	
	SetTrieValue(array_weapons[client], name, -1);
	
	RefreshWeapon(client, name);
}

RefreshWeapon(client, char[] name, int weaponindex=-1)
{
	if(!IsPlayerAlive(client)) return;
	
	
	new weapon;
	
	if(weaponindex == -1) weapon = Client_GetWeapon(client, name);
	else weapon = weaponindex;
	
	if(weapon != INVALID_ENT_REFERENCE)
	{
		new ammo1 = Weapon_GetPrimaryAmmoCount(weapon);
		new ammo2 = Weapon_GetSecondaryAmmoCount(weapon);
		new clip1 = Weapon_GetPrimaryClip(weapon);
		new clip2 = Weapon_GetSecondaryClip(weapon);
		
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
		//PrintToChat(client, "verdadero custom");
		weapon = GivePlayerItem(client, name);
		EquipPlayerWeapon(client, weapon);
		//PrintToChat(client, "falso custom");

 		if(ammo1 > -1) Weapon_SetPrimaryAmmoCount(weapon, ammo1);
		if(ammo2 > -1) Weapon_SetSecondaryAmmoCount(weapon, ammo2);
		if(clip1 > -1) Weapon_SetPrimaryClip(weapon, clip1);
		if(clip2 > -1) Weapon_SetSecondaryClip(weapon, clip2);
		
		//PrintToChat(client, "ammo1 %i ammo2 %i clip1 %i clip2 %i", ammo1, ammo2, clip1, clip2);
	}
}

// Thanks to gubka for these 2 functions below. 

// Get model index and prevent server from crash 
int newWeapon_GetViewModelIndex(int client, int sIndex) 
{ 
	int Owner;
	//int ClientWeapon;
	//int Weapon;
	
	while ((sIndex = FindEntityByClassname2(sIndex, "predicted_viewmodel")) != -1) 
	{ 
		Owner = GetEntPropEnt(sIndex, Prop_Send, "m_hOwner"); 
		//ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); 
		//Weapon = GetEntPropEnt(sIndex, Prop_Send, "m_hWeapon");
         
		if (Owner != client) 
			continue; 
         
		//if (ClientWeapon != Weapon) 
			//continue;
         
		return EntIndexToEntRef(sIndex); 
	} 
	return INVALID_ENT_REFERENCE; 
} 
// Get entity name 
int FindEntityByClassname2(int sStartEnt, char[] szClassname) 
{ 
    while (sStartEnt > -1 && !IsValidEntity(sStartEnt)) sStartEnt--; 
    return FindEntityByClassname(sStartEnt, szClassname); 
}  
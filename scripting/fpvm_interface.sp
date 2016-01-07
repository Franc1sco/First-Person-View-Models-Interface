#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
//#undef REQUIRE_EXTENSIONS
#include <dhooks>

#define DATA "2.2.1"

Handle trie_weapons[MAXPLAYERS+1];

bool eco_items = false;

int g_PVMid[MAXPLAYERS+1];

Handle hGiveNamedItem, hGiveNamedItem2, OnClientView, OnClientWorld;
bool nosir[MAXPLAYERS+1];

new OldSequence[MAXPLAYERS+1];
new Float:OldCycle[MAXPLAYERS+1];

char g_classname[MAXPLAYERS+1][64];

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
	
	CreateNative("FPVMI_AddViewModelToClient", Native_AddViewWeapon);
	CreateNative("FPVMI_RemoveViewModelToClient", Native_RemoveViewWeapon);
	CreateNative("FPVMI_SetClientModel", Native_SetWeapon);
	CreateNative("FPVMI_GetClientViewModel", Native_GetWeaponView);
	CreateNative("FPVMI_GetClientWorldModel", Native_GetWeaponWorld);
	CreateNative("FPVMI_AddWorldModelToClient", Native_AddWorldWeapon);
	CreateNative("FPVMI_RemoveWorldModelToClient", Native_RemoveWorldWeapon);
	
	OnClientView = CreateGlobalForward("FPVMI_OnClientViewModel", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	OnClientWorld = CreateGlobalForward("FPVMI_OnClientWorldModel", ET_Ignore, Param_Cell, Param_String, Param_Cell);
    
/* 	MarkNativeAsOptional("DHookCreate");
	MarkNativeAsOptional("DHookAddParam");
	MarkNativeAsOptional("DHookEntity"); */
	
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
	
	if(!GetTrieValue(trie_weapons[client], classname, model_index) || model_index == -1) return;
	
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
		if(StrEqual(g_classname[client], "weapon_knife"))
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
		}
		else if(StrEqual(g_classname[client], "weapon_ak47"))
		{
			switch (Sequence)
			{
				case 3:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 2);
				case 2:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 1);
				case 1:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 3);			
			}
		}
		else if(StrEqual(g_classname[client], "weapon_mp7"))
		{
			switch (Sequence)
			{
				case 3:
				{
					SetEntProp(clientview, Prop_Send, "m_nSequence", -1);
				}
			}
		}
		else if(StrEqual(g_classname[client], "weapon_awp"))
		{
			switch (Sequence)
			{
				case 1:
				{
					SetEntProp(clientview, Prop_Send, "m_nSequence", -1);	
				}	
			}
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
	if(StrContains(classname, "item", false) == 0) return MRES_Ignored;
	
	new weapon = DHookGetReturn(hReturn);
	
	new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	switch (weaponindex)
	{
		case 60: strcopy(classname, 64, "weapon_m4a1_silencer");
		case 61: strcopy(classname, 64, "weapon_usp_silencer");
		case 63: strcopy(classname, 64, "weapon_cz75a");
		case 64: strcopy(classname, 64, "weapon_revolver");
	}
	
	if(!GetTrieValue(trie_weapons[client], classname, model_index) || model_index == -1) return MRES_Ignored;
	
	
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
	//if(IsFakeClient(client)) return;
	
	g_PVMid[client] = INVALID_ENT_REFERENCE;
	hook[client] = false;
	
	trie_weapons[client] = CreateTrie();
	
	SDKHook(client, SDKHook_WeaponSwitchPost, OnClientWeaponSwitchPost); 
	SDKHook(client, SDKHook_WeaponSwitch, OnClientWeaponSwitch); 
	
	if(eco_items)
	{
		DHookEntity(hGiveNamedItem, true, client);
		DHookEntity(hGiveNamedItem2, false, client);
		//SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPostKnifeFix);
		//SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	}
}

/* public OnPostThinkPost(client)
{
	if (!IsPlayerAlive(client))
	{
        return;
	}
	
	new model_index;
    
	if(g_PVMid[client] == -1)
	{
		g_PVMid[client] = newWeapon_GetViewModelIndex(client, -1); 
		if(!IsValidEdict(g_PVMid[client])) return;
	}
	
	new Sequence = GetEntProp(g_PVMid[client], Prop_Send, "m_nSequence");
	new Float:Cycle = GetEntPropFloat(g_PVMid[client], Prop_Data, "m_flCycle");
    
	PrintHintText(client, "secuencia %i", Sequence);
	
	if ((Cycle < OldCycle[client]) && (Sequence == OldSequence[client]))
	{
		PrintToConsole(client, "FIX = secuencia %i",Sequence);
		
		//SetEntProp(g_PVMid[client], Prop_Send, "m_nSequence", Sequence);
	}
	
	OldSequence[client] = Sequence;
	OldCycle[client] = Cycle;
} */

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
	char classname[64];
	
	if(!GetEdictClassname(wpnid, classname, sizeof(classname)))
	{
		return;
	}
	
	if(StrContains(classname, "item", false) == 0) return;
	
	new weaponindex = GetEntProp(wpnid, Prop_Send, "m_iItemDefinitionIndex");
	switch (weaponindex)
	{
		case 60: strcopy(classname, 64, "weapon_m4a1_silencer");
		case 61: strcopy(classname, 64, "weapon_usp_silencer");
		case 63: strcopy(classname, 64, "weapon_cz75a");
		case 64: strcopy(classname, 64, "weapon_revolver");
	}
	
	new model_index;
	
	if(!GetTrieValue(trie_weapons[client], classname, model_index))
	{
		return;
	}
	
	char classname_default[64], classname_world[64];
	Format(classname_default, sizeof(classname_default), "%s_default", classname);
	Format(classname_world, sizeof(classname_world), "%s_world", classname);
	
	
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
		if(!GetTrieValue(trie_weapons[client], classname_default, model_index) || model_index == -1) return;
		
		SetEntProp(clientview, Prop_Send, "m_nModelIndex", model_index); 
		SetTrieValue(trie_weapons[client], classname_default, -1);
		return;
	}
	
 	if(eco_items && !nosir[client])
	{
		if(GetEntProp(wpnid, Prop_Send, "m_iItemIDLow") != 0 || GetEntProp(wpnid, Prop_Send, "m_iItemIDHigh") != 0) 
		{
			if(!GetTrieValue(trie_weapons[client], classname_default, model_index) || model_index == -1) return;
			
			SetEntProp(clientview, Prop_Send, "m_nModelIndex", model_index); 
			return;
			
		}
	}
	
	SetEntProp(wpnid, Prop_Send, "m_nModelIndex", 0); 
		
	new model_world;
	if(GetTrieValue(trie_weapons[client], classname_world, model_world) && model_world != -1)
	{
		int iWorldModel = GetEntPropEnt(wpnid, Prop_Send, "m_hWeaponWorldModel"); 
		if(IsValidEdict(iWorldModel)) SetEntProp(iWorldModel, Prop_Send, "m_nModelIndex", model_world);
		
		//PrintToChat(client, "dado");
	}
	
	int model_index_custom = model_index;
	
	if(!GetTrieValue(trie_weapons[client], classname_default, model_index) || model_index == -1) SetTrieValue(trie_weapons[client], classname_default, GetEntProp(clientview, Prop_Send, "m_nModelIndex"));
	
	SetEntProp(clientview, Prop_Send, "m_nModelIndex", model_index_custom); 
	
	hook[client] = true;
	Format(g_classname[client], 64, classname);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPostKnifeFix);
}

public void OnClientDisconnect(int client)
{
	if(trie_weapons[client] != INVALID_HANDLE) CloseHandle(trie_weapons[client]);
	
	trie_weapons[client] = INVALID_HANDLE;
}

public Native_AddViewWeapon(Handle:plugin, argc)
{  
	char name[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	int model_index = GetNativeCell(3);
	SetTrieValue(trie_weapons[client], name, model_index);

	RefreshWeapon(client, name);
	
	Call_StartForward(OnClientView);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(model_index);
	Call_Finish();
}

public Native_AddWorldWeapon(Handle:plugin, argc)
{  
	char name[64], world[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	int model_world = GetNativeCell(3);
	
	
	Format(world, 64, "%s_world", name);
	SetTrieValue(trie_weapons[client], world, model_world);
	
	RefreshWeapon(client, name);
	
	Call_StartForward(OnClientWorld);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(model_world);
	Call_Finish();
}

public int Native_GetWeaponView(Handle:plugin, argc)
{  
	char name[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	
	int arrayindex;
	if(!GetTrieValue(trie_weapons[client], name, arrayindex) || arrayindex == -1)
	{
		return -1;
	}

	return arrayindex;
}

public int Native_GetWeaponWorld(Handle:plugin, argc)
{  
	char name[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	Format(name, 64, "%s_world", name);
	int arrayindex;
	if(!GetTrieValue(trie_weapons[client], name, arrayindex) || arrayindex == -1)
	{
		return -1;
	}

	return arrayindex;
}

public Native_SetWeapon(Handle:plugin, argc)
{  
	char name[64], world[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	int model_index = GetNativeCell(3);
	int model_world = GetNativeCell(4);
	Format(world, 64, "%s_world", name);
	
	SetTrieValue(trie_weapons[client], name, model_index);
	SetTrieValue(trie_weapons[client], world, model_world);
	
	RefreshWeapon(client, name);
	
	Call_StartForward(OnClientView);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(model_index);
	Call_Finish();
	
	Call_StartForward(OnClientWorld);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(model_world);
	Call_Finish();
}


public Native_RemoveViewWeapon(Handle:plugin, argc)
{  
	char name[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	SetTrieValue(trie_weapons[client], name, -1);
	
	RefreshWeapon(client, name);
	
	Call_StartForward(OnClientView);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(-1);
	Call_Finish();
}

public Native_RemoveWorldWeapon(Handle:plugin, argc)
{  
	char name[64], world[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	
	Format(world, 64, "%s_world", name);
	SetTrieValue(trie_weapons[client], world, -1);
	
	RefreshWeapon(client, name);
	
	Call_StartForward(OnClientWorld);
	Call_PushCell(client);
	Call_PushString(name);
	Call_PushCell(-1);
	Call_Finish();
}

RefreshWeapon(client, char[] name)
{
	if(!IsPlayerAlive(client)) return;
	
	
	new weapon = Client_GetWeapon(client, name);
	
	if(weapon != INVALID_ENT_REFERENCE)
	{
		new ammo1 = Weapon_GetPrimaryAmmoCount(weapon);
		new ammo2 = Weapon_GetSecondaryAmmoCount(weapon);
		new clip1 = Weapon_GetPrimaryClip(weapon);
		new clip2 = Weapon_GetSecondaryClip(weapon);
		
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
		//PrintToChat(client, "verdadero custom %s", name);
		if(StrEqual(name, "weapon_knife"))
		{
			int zeus = GetPlayerWeaponSlot(client, 2);
			if(zeus != -1)
			{
				RemovePlayerItem(client, zeus);
				AcceptEntityInput(zeus, "Kill");
				weapon = GivePlayerItem(client, name);
				GivePlayerItem(client, "weapon_taser");
			}
			else weapon = GivePlayerItem(client, name);
			
		} else weapon = GivePlayerItem(client, name);
		//if(StrEqual(name, "weapon_knife")) EquipPlayerWeapon(client, weapon);
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
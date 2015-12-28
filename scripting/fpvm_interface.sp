#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#undef REQUIRE_EXTENSIONS
#include <dhooks>

#define DATA "1.2"

Handle array_weapons[MAXPLAYERS+1];

bool eco_items = false;

int g_PVMid[MAXPLAYERS+1];

Handle hGiveNamedItem, hGiveNamedItem2;
bool nosir[MAXPLAYERS+1];

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
	
	HookEvent("player_spawn", OnSpawn);
	
	if(!eco_items) return;
	
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

public MRESReturn OnGiveNamedItem(int client, Handle hReturn, Handle hParams)
{
	new model_index;
	char classname[64];
	
	DHookGetParamString(hParams, 1, classname, 64);
	
	if(!GetTrieValue(array_weapons[client], classname, model_index) || model_index == -1) return MRES_Ignored;
	
	new weapon = DHookGetReturn(hReturn);
	SetEntProp(weapon, Prop_Send, "m_iItemIDLow", 0);
	SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", 0);
	
	nosir[client] = false;
	return MRES_Ignored;
}

public MRESReturn OnGiveNamedItemPre(int client, Handle hReturn, Handle hParams)
{
	nosir[client] = true;
	
	return MRES_Ignored;
}

public Action OnSpawn(Handle event, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_PVMid[client] = newWeapon_GetViewModelIndex(client, -1); 
}

public void OnClientPutInServer(int client)
{
	array_weapons[client] = CreateTrie();
	
	SDKHook(client, SDKHook_WeaponSwitchPost, OnClientWeaponSwitchPost); 
	
	if(eco_items && !IsFakeClient(client))
	{
		DHookEntity(hGiveNamedItem, true, client);
		DHookEntity(hGiveNamedItem2, false, client);
	}
}

public void OnClientWeaponSwitchPost(int client, int wpnid) 
{ 
	if(wpnid < 1) return;
	
	char classname[64];
	
	if(!GetEdictClassname(wpnid, classname, sizeof(classname))) return;
	
	new model_index;
	
	if(!GetTrieValue(array_weapons[client], classname, model_index)) return;
	
	Format(classname, sizeof(classname), "%s_default", classname);
	
	if(model_index == -1)
	{
		if(!GetTrieValue(array_weapons[client], classname, model_index) || model_index == -1) return;
		
		SetEntProp(g_PVMid[client], Prop_Send, "m_nModelIndex", model_index); 
		SetTrieValue(array_weapons[client], classname, -1);
		return;
	}
	
 	if(eco_items && !nosir[client])
	{
		if(GetEntProp(wpnid, Prop_Send, "m_iItemIDLow") != 0 || GetEntProp(wpnid, Prop_Send, "m_iItemIDHigh") != 0) 
		{
			if(!GetTrieValue(array_weapons[client], classname, model_index) || model_index == -1) return;
			
			SetEntProp(g_PVMid[client], Prop_Send, "m_nModelIndex", model_index); 
			return;
			
		}
	}
	
	SetEntProp(wpnid, Prop_Send, "m_nModelIndex", 0); 
		
/*  	int iWorldModel = GetEntPropEnt(wpnid, Prop_Send, "m_hWeaponWorldModel"); 
	if(IsValidEdict(iWorldModel)) SetEntProp(iWorldModel, Prop_Send, "m_nModelIndex", 0);  */ 
	
	int model_index_custom = model_index;
	
	if(!GetTrieValue(array_weapons[client], classname, model_index) || model_index == -1) SetTrieValue(array_weapons[client], classname, GetEntProp(g_PVMid[client], Prop_Send, "m_nModelIndex"));
	
	SetEntProp(g_PVMid[client], Prop_Send, "m_nModelIndex", model_index_custom); 
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
	
	if(weaponindex != -1) weapon = weaponindex;
	else weapon = Client_GetWeapon(client, name);
	
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
    while ((sIndex = FindEntityByClassname2(sIndex, "predicted_viewmodel")) != -1) 
    { 
        int Owner = GetEntPropEnt(sIndex, Prop_Send, "m_hOwner"); 
        int ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); 
        int Weapon = GetEntPropEnt(sIndex, Prop_Send, "m_hWeapon"); 
         
        if (Owner != client) 
            continue; 
         
        if (ClientWeapon != Weapon) 
            continue; 
         
        return sIndex; 
    } 
    return -1; 
} 
// Get entity name 
int FindEntityByClassname2(int sStartEnt, char[] szClassname) 
{ 
    while (sStartEnt > -1 && !IsValidEntity(sStartEnt)) sStartEnt--; 
    return FindEntityByClassname(sStartEnt, szClassname); 
}  
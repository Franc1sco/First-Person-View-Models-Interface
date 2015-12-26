#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DATA "1.0"

Handle array_weapons[MAXPLAYERS+1];

bool eco_items = false;

int g_PVMid[MAXPLAYERS+1];

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
    
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_fpvmi_version", DATA, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("player_spawn", OnSpawn);
}

public Action OnSpawn(Handle event, char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_PVMid[client] = Weapon_GetViewModelIndex(client, -1); 
} 


public void OnClientPutInServer(int client)
{
	array_weapons[client] = CreateTrie();
	
	SDKHook(client, SDKHook_WeaponSwitchPost, OnClientWeaponSwitchPost); 
}

public void OnClientWeaponSwitchPost(int client, int wpnid) 
{ 
	if(wpnid < 1) return;
	
	char classname[64];
	
	if(!GetEdictClassname(wpnid, classname, sizeof(classname))) return;
	
	new model_index;
	
	if(!GetTrieValue(array_weapons[client], classname, model_index)) return;
	
	if(model_index == -1) return;
	
	if(eco_items)
	{
		SetEntProp(wpnid, Prop_Send, "m_iItemIDLow", 0);
		SetEntProp(wpnid, Prop_Send, "m_iItemIDHigh", 0);
	}
	
	SetEntProp(wpnid, Prop_Send, "m_nModelIndex", 0); 
		
	int iWorldModel = GetEntPropEnt(wpnid, Prop_Send, "m_hWeaponWorldModel"); 
	if(IsValidEdict(iWorldModel)) SetEntProp(iWorldModel, Prop_Send, "m_nModelIndex", 0); 
	
	SetEntProp(g_PVMid[client], Prop_Send, "m_nModelIndex", model_index); 
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
}

public Native_RemoveWeapon(Handle:plugin, argc)
{  
	char name[64];
	
	int client = GetNativeCell(1);
	GetNativeString(2, name, 64);
	
	SetTrieValue(array_weapons[client], name, -1);
}


// Thanks to gubka for these 2 functions below. 

// Get model index and prevent server from crash 
int Weapon_GetViewModelIndex(int client, int sIndex) 
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
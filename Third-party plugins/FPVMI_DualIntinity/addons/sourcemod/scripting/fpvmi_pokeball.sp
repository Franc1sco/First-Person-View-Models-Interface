#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <fpvm_interface>

#define WEAPON "weapon_hegrenade" // weapon to replace
#define MODEL "models/weapons/pokeball/pokeball.mdl" // custom view model


int g_Model;

public Plugin myinfo = 
{
	name = "SM FPVMI - Pokeball",
	author = "Franc1sco franug",
	description = "Add dual intinity view model to all",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnClientPostAdminCheck(client)
{
	FPVMI_AddViewModelToClient(client, WEAPON, g_Model); // add custom view model to the player
}

public OnMapStart() 
{ 
	g_Model = PrecacheModel(MODEL); // Custom model 
	
} 
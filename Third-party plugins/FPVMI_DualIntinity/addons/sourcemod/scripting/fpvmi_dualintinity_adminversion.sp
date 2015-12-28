#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <fpvm_interface>

#define WEAPON "weapon_elite" // weapon to replace
#define MODEL "models/weapons/v_pist_dualinfinity.mdl" // custom view model
#define ADMFLAG_NEEDED ADMFLAG_RESERVATION // admin flag needed for have the custom view model


int g_Model;

public Plugin myinfo = 
{
	name = "SM FPVMI - Dual Intinity (admin version)",
	author = "Franc1sco franug",
	description = "Add dual intinity view model to all",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnClientPostAdminCheck(client)
{
	if(GetUserFlagBits(client) & ADMFLAG_NEEDED) // if the client have the admin flag needed
		FPVMI_AddViewModelToClient(client, WEAPON, g_Model); // add custom view model to the player
}

public OnMapStart() 
{ 
	g_Model = PrecacheModel(MODEL); // Custom model 
	
	// model downloads
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/01.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/01.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/02.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/02.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/exponent");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/hong02.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/hong02.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/jin01.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/jin01.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/m9a1.vmt");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/m9a1.vtf");
	AddFileToDownloadsTable("materials/models/weapons/w_models/w_pist_elite/m9a1_exponent.vtf");
	AddFileToDownloadsTable("models/weapons/v_pist_dualinfinity.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/v_pist_dualinfinity.vvd");
	AddFileToDownloadsTable("models/weapons/v_pist_dualinfinity.mdl");
} 
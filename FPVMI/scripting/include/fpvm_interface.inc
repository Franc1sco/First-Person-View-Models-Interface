/** Double-include prevention */
#if defined _fpvm_interface_included_
  #endinput
#endif
#define _fpvm_interface_included_


/**
 * Add a custom view model to a weapon
 *
 * @param client     Player for check
 * @String weapon     Weapon to replace
 * @param weapon_index     The weapon precached index with the view model
 * @return no return
 */
native FPVMI_AddViewModelToClient(int client, char[] weapon, int weapon_index);

/**
 * Remove a custom view model to a weapon
 *
 * @param client     Player for check
 * @String weapon     Weapon to replace
 * @return no return
 */
native FPVMI_RemoveViewModelToClient(int client, char[] weapon);
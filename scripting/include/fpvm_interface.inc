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
 * @param weaponview_index     The weapon precached index with the view model.
 * @return no return
 */
native FPVMI_AddViewModelToClient(int client, char[] weapon, int weaponview_index=-1);

/**
 * Add a custom world model to a weapon
 *
 * @param client     Player for check
 * @String weapon     Weapon to replace
 * @param weaponwold_index    The weapon precached index with the view model. -1 = default model
 * @return no return
 */
native FPVMI_AddWorldModelToClient(int client, char[] weapon, int weaponworld_index=-1);

/**
 * Set a custom view/world model to a weapon
 *
 * @param client     Player for check
 * @String weapon     Weapon to replace
 * @param weapon_index     The weapon precached index with the view model. -1 = default model
 * @param weaponwold_index    The weapon precached index with the view model. -1 = default model
 * @return no return
 */
native FPVMI_SetClientModel(int client, char[] weapon, int weaponview_index=-1, int weaponworld_index=-1);

/**
 * Remove a custom view model to a weapon
 *
 * @param client     Player for check
 * @String weapon     Weapon to replace
 * @return no return
 */
native FPVMI_RemoveViewModelToClient(int client, char[] weapon);

/**
 * Remove a custom world model to a weapon
 *
 * @param client     Player for check
 * @String weapon     Weapon to replace
 * @return no return
 */
native FPVMI_RemoveWorldModelToClient(int client, char[] weapon);
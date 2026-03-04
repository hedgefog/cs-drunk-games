#if defined _drunkgames_const_included
  #endinput
#endif

#define _drunkgames_const_included

stock const DRUNKGAMES_LIBRARY[] = "drunkgames";
stock const DRUNKGAMES_TITLE[] = "Drunk Games";
stock const DRUNKGAMES_VERSION[] = "1.0.0";

/*--------------------------------[ Entities ]--------------------------------*/

stock const DrunkGames_Entity_Bottle[] = "drunkgames-bottle";
stock const DrunkGames_Entity_TriggerEndRound[] = "trigger_endround";
stock const DrunkGames_Entity_AmbientGeneric[] = "ambient_generic";
stock const DrunkGames_Entity_Button[] = "func_button";
stock const DrunkGames_Entity_Train[] = "func_train";
stock const DrunkGames_Entity_WallToggle[] = "func_wall_toggle";
stock const DrunkGames_Entity_MultiManager[] = "multi_manager";
stock const DrunkGames_Entity_MultiSource[] = "multisource";
stock const DrunkGames_Entity_Door[] = "func_door";

/*--------------------------------[ Entity Members ]--------------------------------*/

stock const DrunkGames_Entity_Bottle_Member_flDamage[] = "flDamage";
stock const DrunkGames_Entity_Bottle_Member_flLastTouch[] = "flLastTouch";

stock const DrunkGames_Entity_Train_Member_szFirstTarget[] = "szFirstTarget";
stock const DrunkGames_Entity_Train_Member_flSpeed[] = "flSpeed";

stock const DrunkGames_Entity_AmbientGeneric_Member_bStartSilent[] = "bStartSilent";

/*--------------------------------[ Weapons ]--------------------------------*/

stock const DrunkGames_Weapon_Bottle[] = "drunkgames/v100/weapon_bottle";

/*--------------------------------[ Asset Library ]--------------------------------*/

stock const DrunkGames_AssetLibrary[] = "drunkgames";

stock const DrunkGames_Asset_Weapon_Bottle_ModelView[] = "weapons.bottle.model.view";
stock const DrunkGames_Asset_Weapon_Bottle_ModelPlayer[] = "weapons.bottle.model.player";
stock const DrunkGames_Asset_Weapon_Bottle_ModelWorld[] = "weapons.bottle.model.world";
stock const DrunkGames_Asset_Entity_Bottle_GibsModel[] = "entities.bottle.gibs";
stock const DrunkGames_Asset_Entity_Bottle_Sound_Break[] = "entities.bottle.sounds.break";
stock const DrunkGames_Asset_Notifications_Sound_Finished[] = "notifications.sounds.finished";
stock const DrunkGames_Asset_Notifications_Sound_Win[] = "notifications.sounds.win";
stock const DrunkGames_Asset_Notifications_Sound_RoundEnd[] = "notifications.sounds.roundend";

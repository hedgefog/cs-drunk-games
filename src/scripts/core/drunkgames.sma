#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <drunkgames>

#define PLUGIN "Drunk Games"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

new g_pFwConfigLoaded;

new g_pCvarVersion;

public plugin_precache() {
    for (new i = 0; i < sizeof(DRUNKGAME_SPRITE_HUD); ++i) {
        precache_model(DRUNKGAME_SPRITE_HUD[i]);
    }
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_forward(FM_GetGameDescription, "FMForward_GetGameDescription");

    g_pCvarVersion = register_cvar("drunkgames_version", VERSION, FCVAR_SERVER);
    hook_cvar_change(g_pCvarVersion, "CvarHook_Version");

    g_pFwConfigLoaded = CreateMultiForward("DrunkGames_Fw_ConfigLoaded", ET_IGNORE);
}

public plugin_natives() {
    register_library("drunkgames");
}

public plugin_cfg() {
    new szConfigDir[32];
    get_configsdir(szConfigDir, charsmax(szConfigDir));

    server_cmd("exec %s/drunkgames.cfg", szConfigDir);
    server_exec();
    
    ExecuteForward(g_pFwConfigLoaded);
}

public CvarHook_Version() {
    set_pcvar_string(g_pCvarVersion, DRUNKGAME_VERSION);
}

public FMForward_GetGameDescription() {
    static szGameName[32];
    format(szGameName, charsmax(szGameName), "%s %s", DRUNKGAME_VERSION, DRUNKGAME_VERSION);
    forward_return(FMV_STRING, szGameName);

    return FMRES_SUPERCEDE;
}

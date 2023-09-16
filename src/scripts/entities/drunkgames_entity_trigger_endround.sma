
#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_custom_entities>

#include <drunkgames>

#define PLUGIN "[Entity] trigger_endround"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

#define ENTITY_NAME "trigger_endround"

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public plugin_precache() {
    CE_Register(ENTITY_NAME, .preset = CEPreset_Trigger);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
    CE_RegisterHook(CEFunction_Activate, ENTITY_NAME, "@Entity_Activate");
}

public @Entity_Spawn(this) {
    log_amx("Spawn");
}

public @Entity_Activate(this, pToucher) {
    log_amx("Activate %d", pToucher);
    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    DrunkGames_AddWinner(pToucher);

    return HAM_HANDLED;
}

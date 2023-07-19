
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
#define SF_FORALL BIT(0)

new g_ceHandler;

new g_rgbPlayerTouched[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    RegisterHam(Ham_Touch, CE_BASE_CLASSNAME, "HamHook_Base_Touch_Post", .Post = 1);
}

public plugin_precache() {
    g_ceHandler = CE_Register(ENTITY_NAME);
    CE_RegisterHook(CEFunction_Spawn, ENTITY_NAME, "@Entity_Spawn");
    CE_RegisterHook(CEFunction_KVD, ENTITY_NAME, "@Entity_KVD");
}

public @Entity_Spawn(pEntity) {
    set_pev(pEntity, pev_solid, SOLID_TRIGGER);
    set_pev(pEntity, pev_movetype, MOVETYPE_NONE);
    set_pev(pEntity, pev_effects, EF_NODRAW);
}

public @Entity_KVD(pEntity, const szKey[], const szValue[]) {
    // if (equal(szKey, "master")) {
    //     set_pev(pEntity, pev_message, szValue);
    // }
}

public HamHook_Base_Touch_Post(pEntity, pToucher) {
    if (g_ceHandler != CE_GetHandlerByEntity(pEntity)) {
        return HAM_IGNORED;
    }

    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    // static szMaster[32];
    // pev(pEntity, pev_message, szMaster, charsmax(szMaster));

    // if (!UTIL_IsMasterTriggered(szMaster, pToucher)) {
    //     return HAM_IGNORED;
    // }

    g_rgbPlayerTouched[pToucher] = true;

    DrunkGames_AddWinner(pToucher);

    return HAM_HANDLED;
}

public Round_Fw_NewRound() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        g_rgbPlayerTouched[pPlayer] = false;
    }
}

#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <api_rounds>
#include <api_custom_weapons>
#include <api_player_dizziness>

#include <drunkgames>

#define PLUGIN "[Drunk Games] Game Rules"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

new g_rgiPlayerTeam[MAX_PLAYERS + 1];
new bool:g_rgbIsPlayerDrunk[MAX_PLAYERS + 1];
new bool:g_rgbIsPlayerFinished[MAX_PLAYERS + 1];
new g_rgpPlayerPusher[MAX_PLAYERS + 1];
new Float:g_rgflPlayerPushTime[MAX_PLAYERS + 1];

new Array:g_iszWinners = Invalid_Array;
new bool:g_bRoundExpired = false;

new g_pCvarMaxWinners;
new g_pCvarFreeForAll;
new g_pCvarPlayerDizzinessStrength;

new g_iFwPlayerWon;
new g_iFwPlayerFinished;
new g_iFwRoundEnd;

public plugin_precache() {
    g_iszWinners = ArrayCreate();
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_OnSpawnEquip");

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
    RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
    RegisterHamPlayer(Ham_Touch, "HamHook_Player_Touch_Post", .Post = 1);
    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);
    RegisterHamPlayer(Ham_Player_PostThink, "HamHook_Player_PostThink_Post", .Post = 1);

    g_iFwPlayerWon = CreateMultiForward("DrunkGames_Fw_PlayerWon", ET_IGNORE, FP_CELL, FP_CELL);
    g_iFwPlayerFinished = CreateMultiForward("DrunkGames_Fw_PlayerFinished", ET_IGNORE, FP_CELL, FP_CELL);
    g_iFwRoundEnd = CreateMultiForward("DrunkGames_Fw_RoundEnd", ET_IGNORE, FP_CELL, FP_CELL);

    g_pCvarFreeForAll = get_cvar_pointer("mp_freeforall");
    g_pCvarMaxWinners = create_cvar("drunkgames_max_winners", "3", _, "Max winners (FFA Only)");
    g_pCvarPlayerDizzinessStrength = create_cvar("drunkgames_player_dizziness_strength", "1.0", _, "Player drunk effect strength", true, 0.0);
}

public plugin_natives() {
    register_library("drunkgames");

    register_native("DrunkGames_GetWinnerNum", "Native_GetWinnersNum");
    register_native("DrunkGames_GetMaxWinners", "Native_GetMaxWinners");
    register_native("DrunkGames_GetWinner", "Native_GetWinner");
    register_native("DrunkGames_AddWinner", "Native_AddWinner");
    register_native("DrunkGames_RemoveWinner", "Native_RemoveWinner");
    register_native("DrunkGames_Player_IsFinished", "Native_IsPlayerFinished");
    register_native("DrunkGames_IsFreeForAll", "Native_IsFreeForAll");
}

public plugin_end() {
    ArrayDestroy(g_iszWinners);
}

public Native_GetWinnersNum(iPluginId, iArgc) {
    return GetWinnersNum();
}

public Native_GetMaxWinners(iPluginId, iArgc) {
    return GetMaxWinners();
}

public Native_GetWinner(iPluginId, iArgc) {
    new iPlace = get_param(1);

    return GetWinner(iPlace);
}

public Native_AddWinner(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    AddWinner(pPlayer);
}

public Native_RemoveWinner(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    RemoveWinner(pPlayer);
}

public bool:Native_IsPlayerFinished(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return g_rgbIsPlayerFinished[pPlayer];
}

public bool:Native_IsFreeForAll(iPluginId, iArgc) {
    return IsFreeForAll();
}

public client_connect(pPlayer) {
    g_rgiPlayerTeam[pPlayer] = 0;
    CheckWinConditions();
}

public client_disconnected(pPlayer) {
    RemoveWinner(pPlayer);
}

public Round_Fw_CheckWinCondition() {
    return PLUGIN_HANDLED;
}

public Round_Fw_NewRound() {
    ArrayClear(g_iszWinners);
    g_bRoundExpired = false;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        g_rgbIsPlayerFinished[pPlayer] = false;
    }
}

public Round_Fw_RoundExpired() {
    if (Round_IsRoundEnd()) {
        return;
    }

    g_bRoundExpired = true;
    CheckWinConditions();
}

public Round_Fw_RoundEnd() {
    new iWinnersNum = GetWinnersNum();

    for (new iPlace = 0; iPlace < iWinnersNum; ++iPlace) {
        new pWinner = GetWinner(iPlace);
        ExecuteHamB(Ham_AddPoints, pWinner, 1, false);
        ExecuteForward(g_iFwPlayerWon, _, pWinner, iPlace);
    }
}

public HC_Player_OnSpawnEquip(pPlayer) {
    rg_remove_all_items(pPlayer);
    CW_GiveWeapon(pPlayer, DRUNKGAME_WEAPON_BOTTLE);

    return HC_SUPERCEDE;
}

public HamHook_Player_Spawn_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(pPlayer) {
    CheckWinConditions();
}

public HamHook_Player_TakeDamage(pPlayer, pInflictor, pAttacker) {
    if (!IS_PLAYER(pAttacker)) {
        if (g_rgpPlayerPusher[pPlayer] && get_gametime() - g_rgflPlayerPushTime[pPlayer] < 5.0) {
            SetHamParamEntity2(2, 0);
            SetHamParamEntity2(3, g_rgpPlayerPusher[pPlayer]);
            pAttacker = g_rgpPlayerPusher[pPlayer];
        }
    }
}
public HamHook_Player_TakeDamage_Post(pPlayer, pInflictor, pAttacker) {
    if (IS_PLAYER(pAttacker) && rg_is_player_can_takedamage(pPlayer, pAttacker)) {
        g_rgpPlayerPusher[pPlayer] = pAttacker;
        g_rgflPlayerPushTime[pPlayer] = get_gametime();
    }
}

public HamHook_Player_Touch_Post(pPlayer, pToucher) {
    if (IS_PLAYER(pToucher) && rg_is_player_can_takedamage(pPlayer, pToucher)) {
        g_rgpPlayerPusher[pPlayer] = pToucher;
        g_rgflPlayerPushTime[pPlayer] = get_gametime();
    }
}

public HamHook_Player_PostThink_Post(pPlayer) {
    if (is_user_alive(pPlayer)) {
        new bool:bDrunkValue = Round_IsRoundStarted() && !g_rgbIsPlayerFinished[pPlayer];
        @Player_SetDrunk(pPlayer, bDrunkValue);
    }
}

@Player_SetDrunk(this, bool:bValue) {
    if (g_rgbIsPlayerDrunk[this] == bValue) {
        return;
    }

    PlayerDizziness_Set(this, bValue ? get_pcvar_float(g_pCvarPlayerDizzinessStrength) : 0.0);

    g_rgbIsPlayerDrunk[this] = bValue;
}

CheckWinConditions() {
    if (Round_IsRoundEnd()) {
        return;
    }

    if (IsFreeForAll()) {
        new iMaxWinners = GetMaxWinners();
        new iWinnersNum = min(GetWinnersNum(), iMaxWinners);
        new iNotFinishedPlayersNum = CountNotFinishedPlayers();

        new bool:bEndRound = false;

        if (!bEndRound && g_bRoundExpired) {
            bEndRound = true;
        }

        if (!bEndRound && iWinnersNum >= iMaxWinners) {
            bEndRound = true;
        }

        if (!bEndRound && !iNotFinishedPlayersNum) {
            bEndRound = true;
        }

        if (!bEndRound && !iWinnersNum && iNotFinishedPlayersNum == 1) {
            new pWinner = find_player("f");
            AddWinner(pWinner, false, true);
            bEndRound = true;
        }

        if (bEndRound) {
            EndRound(3, iWinnersNum > 0);
        }
    } else {
        new iWinners = GetWinnersNum();
        new iWinnerTeam = GetWinnerTeam();

        if (iWinnerTeam) {
            for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
                if (!is_user_connected(pPlayer)) {
                    continue;
                }

                new iTeam = get_member(pPlayer, m_iTeam);
                if (iTeam == iWinnerTeam) {
                    AddWinner(pPlayer, false, true);
                }
            }

            EndRound(iWinnerTeam, iWinners > 0);
        }
    }
}

GetWinnerTeam() {
    new iWinnerTeam = 0;

    new iWinnersNum = GetWinnersNum();

    // get winner team by alive players
    if (!iWinnersNum) {
        new iAliveT = 0;
        new iAliveCT = 0;

        for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
            if (!is_user_alive(pPlayer)) {
                continue;
            }

            new iTeam = get_member(pPlayer, m_iTeam);

            switch (iTeam) {
                case 1: iAliveT++;
                case 2: iAliveCT++;
            }
        }

        if (iAliveT && !iAliveCT) {
            iWinnerTeam = 1;
        } else if (!iAliveT && iAliveCT) {
            iWinnerTeam = 2;
        } else if (!iAliveT && !iAliveCT) {
            iWinnerTeam = 3;
        }
    } else {
        new pWinner = GetWinner(0);
        iWinnerTeam = get_member(pWinner, m_iTeam);
    }

    return iWinnerTeam;
}

GetWinnersNum() {
    new iWinnersNum = ArraySize(g_iszWinners);
    return iWinnersNum;
}

GetWinner(iPlace) {
    if (GetWinnersNum() <= iPlace) {
        return 0;
    }

    return ArrayGetCell(g_iszWinners, iPlace);
}

GetMaxWinners() {
    if (!IsFreeForAll()) {
        return 0;
    }

    return get_pcvar_num(g_pCvarMaxWinners);
}

bool:IsFreeForAll() {
    return !!get_pcvar_num(g_pCvarFreeForAll);
}

AddWinner(pPlayer, bool:bFinished = true, bool:bSilent = false) {
    if (!Round_IsRoundStarted()) {
        return;
    }

    new iMaxWinners = GetMaxWinners();

    if (IsFreeForAll() && GetWinnersNum() >= iMaxWinners) {
        return;
    }

    if (ArrayFindValue(g_iszWinners, pPlayer) != -1) {
        return;
    }

    new iPlace = ArrayPushCell(g_iszWinners, pPlayer);

    if (bFinished) {
        g_rgbIsPlayerFinished[pPlayer] = true;
        ExecuteForward(g_iFwPlayerFinished, _, pPlayer, iPlace);
    }

    if (!bSilent) {
        CheckWinConditions();
    }
}

RemoveWinner(pPlayer, bool:bSilent = false) {
    new iIndex = ArrayFindValue(g_iszWinners, pPlayer);
    if (iIndex != -1) {
        ArrayDeleteItem(g_iszWinners, iIndex);
    }

    g_rgbIsPlayerFinished[pPlayer] = false;

    if (!bSilent) {
        CheckWinConditions();
    }
}

CountNotFinishedPlayers() {
    new iCount = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_alive(pPlayer)) {
            continue;
        }

        if (g_rgbIsPlayerFinished[pPlayer]) {
            continue;
        }

        iCount++;
    }

    return iCount;
}

EndRound(iTeam, bool:bFinished) {
    Round_DispatchWin(3, 5.0);

    ExecuteForward(g_iFwRoundEnd, _, iTeam, bFinished);
}

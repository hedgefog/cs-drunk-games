#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_rounds>
#include <api_custom_weapons>
#include <api_player_dizziness>
#include <api_entity_force>

#include <drunkgames>
#include <drunkgames_internal>

new g_rgiPlayerTeam[MAX_PLAYERS + 1];
new bool:g_rgbIsPlayerDrunk[MAX_PLAYERS + 1];
new bool:g_rgbIsPlayerFinished[MAX_PLAYERS + 1];
new g_rgpPlayerPusher[MAX_PLAYERS + 1];
new Float:g_rgflPlayerPushTime[MAX_PLAYERS + 1];

new g_rgpWinners[MAX_PLAYERS + 1];
new g_iWinnersNum = 0;

new bool:g_bRoundExpired = false;
new bool:g_bFreeForAll = false;
new bool:g_bGameInProgress = false;

new g_iMaxWinners = 0;
new Float:g_flPlayerDizzinessStrength = 0.0;

new g_pfwPlayerWon;
new g_pfwPlayerFinished;
new g_pfwRoundEnd;

new Float:g_flGameTime = 0.0;

public plugin_init() {
  register_plugin(PLUGIN_NAME("Game Rules"), DRUNKGAMES_VERSION, "Hedgehog Fog");

  RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "HC_Player_SpawnEquip");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
  RegisterHamPlayer(Ham_Touch, "HamHook_Player_Touch_Post", .Post = 1);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);
  RegisterHamPlayer(Ham_Player_PostThink, "HamHook_Player_PostThink_Post", .Post = 1);
  RegisterHamPlayer(Ham_Item_PreFrame, "HamHook_Player_ItemPreFrame_Post", .Post = 1);

  RegisterHam(Ham_Touch, "func_train", "HamHook_Train_Touch_Post", .Post = 1);
  RegisterHam(Ham_Touch, "func_tracktrain", "HamHook_Train_Touch_Post", .Post = 1);

  register_message(get_user_msgid("TextMsg"), "Message_TextMsg");
  register_message(get_user_msgid("SendAudio"), "Message_SendAudio");

  g_pfwPlayerWon = CreateMultiForward("DrunkGames_OnPlayerWon", ET_IGNORE, FP_CELL, FP_CELL);
  g_pfwPlayerFinished = CreateMultiForward("DrunkGames_OnPlayerFinished", ET_IGNORE, FP_CELL, FP_CELL);
  g_pfwRoundEnd = CreateMultiForward("DrunkGames_OnRoundEnd", ET_IGNORE, FP_CELL, FP_CELL);

  if (!cvar_exists("mp_freeforall")) {
    create_cvar("mp_freeforall", "0", FCVAR_SERVER);
  }

  bind_pcvar_num(get_cvar_pointer("mp_freeforall"), g_bFreeForAll);
  bind_pcvar_num(create_cvar(CVAR("max_winners"), "3", _, "Max winners (FFA Only)"), g_iMaxWinners);
  bind_pcvar_float(create_cvar(CVAR("player_dizziness_strength"), "1.0", _, "Player drunk effect strength", true, 0.0), g_flPlayerDizzinessStrength);

  #if defined _reapi_included
    set_member_game(m_bCTCantBuy, 1);
    set_member_game(m_bTCantBuy, 1);
  #else
    set_gamerules_int("CHalfLifeMultiplay", "m_bCTCantBuy", 1);
    set_gamerules_int("CHalfLifeMultiplay", "m_bTCantBuy", 1);
  #endif
}

public plugin_natives() {
  register_native("DrunkGames_GetWinnerNum", "Native_GetWinnersNum");
  register_native("DrunkGames_GetMaxWinners", "Native_GetMaxWinners");
  register_native("DrunkGames_GetWinner", "Native_GetWinner");
  register_native("DrunkGames_AddWinner", "Native_AddWinner");
  register_native("DrunkGames_RemoveWinner", "Native_RemoveWinner");
  register_native("DrunkGames_Player_IsFinished", "Native_IsPlayerFinished");
  register_native("DrunkGames_IsFreeForAll", "Native_IsFreeForAll");
  register_native("DrunkGames_CanPlayerTakeDamage", "Native_CanPlayerTakeDamage");
}

public server_frame() {
  g_flGameTime = get_gametime();
}

/*--------------------------------[ Natives ]--------------------------------*/

public Native_GetWinnersNum(const iPluginId, const iArgc) {
  return g_iWinnersNum;
}

public Native_GetMaxWinners(const iPluginId, const iArgc) {
  return GetMaxWinners();
}

public Native_GetWinner(const iPluginId, const iArgc) {
  new iPlace = get_param(1);

  return GetWinner(iPlace);
}

public Native_AddWinner(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  AddWinner(pPlayer);
}

public Native_RemoveWinner(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  RemoveWinner(pPlayer);
}

public bool:Native_IsPlayerFinished(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  return g_rgbIsPlayerFinished[pPlayer];
}

public bool:Native_IsFreeForAll(const iPluginId, const iArgc) {
  return g_bFreeForAll;
}

public bool:Native_CanPlayerTakeDamage(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);
  new pAttacker = get_param(2);

  return rg_is_player_can_takedamage(pPlayer, pAttacker);
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_rgiPlayerTeam[pPlayer] = 0;
  g_rgbIsPlayerDrunk[pPlayer] = false;
  CheckWinConditions();
}

public client_disconnected(pPlayer) {
  RemoveWinner(pPlayer);
}

/*--------------------------------[ Round Forwards ]--------------------------------*/

public Round_OnInit() {
  ClearWinners();
  g_bRoundExpired = false;
  g_bGameInProgress = false;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    g_rgbIsPlayerFinished[pPlayer] = false;
  }
}

public Round_OnStart() {
  g_bGameInProgress = true;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (is_user_alive(pPlayer)) {
      @Player_UpdateMaxSpeed(pPlayer);
    }
  }
}

public Round_OnExpired() {
  if (!g_bGameInProgress) return;

  g_bRoundExpired = true;
  CheckWinConditions();
}

public Round_OnEnd() {
  g_bGameInProgress = false;

  for (new iPlace = 0; iPlace < g_iWinnersNum; ++iPlace) {
    new pWinner = GetWinner(iPlace);
    if (pWinner == FM_NULLENT) continue;
    ExecuteHamB(Ham_AddPoints, pWinner, 1, false);
    ExecuteForward(g_pfwPlayerWon, _, pWinner, iPlace);
  }
}

public Round_CheckResult:Round_OnCheckWinConditions() {
  return Round_CheckResult_Supercede;
}

public Round_CheckResult:Round_OnCanStartCheck() {
  new iPlayersNum = 0;
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;
    new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
    if (iTeam < 1 || iTeam > 2) continue;

    iPlayersNum++;
  }

  if (iPlayersNum < 1) return Round_CheckResult_Supercede;

  return Round_CheckResult_Continue;
}

/*--------------------------------[ Message Hooks ]--------------------------------*/

public Message_TextMsg(const iMsgId, const iDest, const pPlayer) {
  if (!g_bFreeForAll) return PLUGIN_CONTINUE;

  static szMessage[32]; get_msg_arg_string(2, szMessage, charsmax(szMessage));

  if (equal(szMessage, "#Terrorists_Win")) return PLUGIN_HANDLED;
  if (equal(szMessage, "#CTs_Win")) return PLUGIN_HANDLED;

  if (equal(szMessage, "#Round_Draw")) {
    if (DrunkGames_GetWinnerNum()) return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

public Message_SendAudio(const iMsgId, const iDest, const pPlayer) {
  if (!g_bFreeForAll) return PLUGIN_CONTINUE;

  static szMessage[32]; get_msg_arg_string(2, szMessage, charsmax(szMessage));

  if (equal(szMessage[7], "terwin")) return PLUGIN_HANDLED;
  if (equal(szMessage[7], "ctwin")) return PLUGIN_HANDLED;

  if (equal(szMessage[7], "rounddraw")) {
    if (DrunkGames_GetWinnerNum()) return PLUGIN_HANDLED;
  }

  return PLUGIN_CONTINUE;
}

/*--------------------------------[ Hooks ]--------------------------------*/

public HC_Player_SpawnEquip(const pPlayer) {
  rg_remove_all_items(pPlayer);
  CW_Give(pPlayer, WEAPON(Bottle));

  return HC_SUPERCEDE;
}

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  @Player_UpdateMaxSpeed(pPlayer);

  return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(const pPlayer) {
  CheckWinConditions();
}

public HamHook_Player_TakeDamage(const pPlayer, const pInflictor, const pAttacker) {
  if (!IS_PLAYER(pAttacker)) {
    if (g_rgpPlayerPusher[pPlayer] && g_flGameTime - g_rgflPlayerPushTime[pPlayer] < 5.0) {
      SetHamParamEntity2(2, 0);
      SetHamParamEntity2(3, g_rgpPlayerPusher[pPlayer]);
    }
  }
}

public HamHook_Player_TakeDamage_Post(const pPlayer, const pInflictor, const pAttacker) {
  if (IS_PLAYER(pAttacker) && rg_is_player_can_takedamage(pPlayer, pAttacker)) {
    g_rgpPlayerPusher[pPlayer] = pAttacker;
    g_rgflPlayerPushTime[pPlayer] = g_flGameTime;
  }
}

public HamHook_Player_Touch_Post(const pPlayer, const pToucher) {
  if (IS_PLAYER(pToucher) && rg_is_player_can_takedamage(pPlayer, pToucher)) {
    EntityForce_TransferMomentum(pPlayer, pToucher, 0.85);
    g_rgpPlayerPusher[pPlayer] = pToucher;
    g_rgflPlayerPushTime[pPlayer] = g_flGameTime;
  }
}

public HamHook_Player_PostThink_Post(const pPlayer) {
  if (is_user_alive(pPlayer)) {
    new bool:bDrunkValue = Round_IsStarted() && !g_rgbIsPlayerFinished[pPlayer];
    @Player_SetDrunk(pPlayer, bDrunkValue);
  }
}

public HamHook_Player_ItemPreFrame_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;
  if (!Round_IsStarted()) return HAM_IGNORED;

  @Player_UpdateMaxSpeed(pPlayer);

  return HAM_HANDLED;
}

public HamHook_Train_Touch_Post(const pTrain, const pTarget) {
  if (IS_PLAYER(pTarget)) {
    ExecuteHamB(Ham_Blocked, pTrain, pTarget);
  }
}

/*--------------------------------[ Methods ]--------------------------------*/

@Player_UpdateMaxSpeed(const &this) {
  static Float:flMaxSpeed; pev(this, pev_maxspeed, flMaxSpeed);
  set_pev(this, pev_maxspeed, floatmin(flMaxSpeed, 180.0));
}

@Player_SetDrunk(const &this, const bool:bValue) {
  if (g_rgbIsPlayerDrunk[this] == bValue) return;

  PlayerDizziness_Set(this, bValue ? g_flPlayerDizzinessStrength : 0.0);

  g_rgbIsPlayerDrunk[this] = bValue;
}

/*--------------------------------[ Functions ]--------------------------------*/

CheckWinConditions() {
  if (!g_bGameInProgress) return;

  if (g_bFreeForAll) {
    new iMaxWinners = GetMaxWinners();
    new iWinnersNum = min(g_iWinnersNum, iMaxWinners);
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
    new iWinnerTeam = GetWinnerTeam();

    if (iWinnerTeam) {
      for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        if (!is_user_connected(pPlayer)) continue;

        new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");
        if (iTeam == iWinnerTeam) {
          AddWinner(pPlayer, false, true);
        }
      }

      EndRound(iWinnerTeam, g_iWinnersNum > 0);
    }
  }
}

GetWinnerTeam() {
  new iWinnerTeam = 0;

  if (!g_iWinnersNum) {
    new iAliveT = 0;
    new iAliveCT = 0;

    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
      if (!is_user_alive(pPlayer)) continue;

      new iTeam = get_ent_data(pPlayer, "CBasePlayer", "m_iTeam");

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

    if (pWinner != FM_NULLENT) {
      iWinnerTeam = get_ent_data(pWinner, "CBasePlayer", "m_iTeam");
    }
  }

  return iWinnerTeam;
}

GetWinner(iPlace) {
  if (g_iWinnersNum <= iPlace) return FM_NULLENT;

  return g_rgpWinners[iPlace];
}

GetMaxWinners() {
  return g_bFreeForAll ? g_iMaxWinners : 0;
}

AddWinner(pPlayer, bool:bFinished = true, bool:bSilent = false) {
  if (!Round_IsStarted()) return;

  new iMaxWinners = GetMaxWinners();

  if (g_bFreeForAll && g_iWinnersNum >= iMaxWinners) return;
  if (g_rgbIsPlayerFinished[pPlayer]) return;

  new iPlace = g_iWinnersNum;
  g_rgpWinners[iPlace] = pPlayer;
  g_iWinnersNum++;

  if (bFinished) {
    g_rgbIsPlayerFinished[pPlayer] = true;
    ExecuteForward(g_pfwPlayerFinished, _, pPlayer, iPlace);
  }

  if (!bSilent) {
    CheckWinConditions();
  }
}

ClearWinners() {
  g_iWinnersNum = 0;
}

RemoveWinner(pPlayer, bool:bSilent = false) {
  for (new iPlace = 0; iPlace < g_iWinnersNum; ++iPlace) {
    if (g_rgpWinners[iPlace] == pPlayer) {
      g_rgpWinners[iPlace] = FM_NULLENT;
      break;
    }
  }

  g_rgbIsPlayerFinished[pPlayer] = false;

  if (!bSilent) {
    CheckWinConditions();
  }
}

CountNotFinishedPlayers() {
  new iCount = 0;

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_alive(pPlayer)) continue;
    if (g_rgbIsPlayerFinished[pPlayer]) continue;

    iCount++;
  }

  return iCount;
}

EndRound(iTeam, bool:bFinished) {
  Round_DispatchWin(iTeam);
  ExecuteForward(g_pfwRoundEnd, _, iTeam, bFinished);
}

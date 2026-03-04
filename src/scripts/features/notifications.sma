#pragma semicolon 1

#include <amxmodx>

#include <api_assets>

#include <drunkgames>
#include <drunkgames_internal>

#define CHAT_PREFIX "^4[Drunk Games]^1 "

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Notifications_Sound_Finished));
  Asset_Precache(ASSET_LIBRARY, ASSET(Notifications_Sound_Win));
  Asset_Precache(ASSET_LIBRARY, ASSET(Notifications_Sound_RoundEnd));
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Notifications"), DRUNKGAMES_VERSION, "Hedgehog Fog");

  register_dictionary("drunkgames.txt");
}

/*--------------------------------[ Forwards ]--------------------------------*/

public DrunkGames_OnRoundEnd(iTeam, bool:bFinished) {
  new iWinnersNum = DrunkGames_GetWinnerNum();

  static szWinners[1024];

  new iCursor = 0;
  for (new iPlace = 0; iPlace < iWinnersNum; ++iPlace) {
    new pWinner = DrunkGames_GetWinner(iPlace);

    if (iPlace > 0) {
      iCursor += copy(szWinners[iCursor], charsmax(szWinners) - iCursor, ", ");
    }

    iCursor += format(szWinners[iCursor], charsmax(szWinners) - iCursor, "^3%n^1", pWinner);
  }

  if (DrunkGames_IsFreeForAll()) {
    if (iWinnersNum == 1) {
      if (bFinished) {
        client_print_color(0, print_team_grey, "%s%L", CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_FINISHED_AND_WIN", DrunkGames_GetWinner(0));
      } else {
        client_print_color(0, print_team_grey, "%s%L", CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_SURVIVED_AND_WIN", DrunkGames_GetWinner(0));
      }
    } else if (bFinished) {
      new iMaxWinners = DrunkGames_GetMaxWinners();

      if (iWinnersNum >= iMaxWinners) {
        client_print_color(0, print_team_grey, "%s%L", CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_ALL_PLACES_TAKEN", szWinners);
      } else {
        client_print_color(0, print_team_grey, "%s%L", CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_ONLY_FEW_PLAYERS_FINISHED", iWinnersNum, szWinners);
      }
    } else {
      client_print_color(0, print_team_grey, "%s%L", CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_NO_ONE_FINISHED");
    }
  }

  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    Asset_PlayClientSound(pPlayer, ASSET_LIBRARY, ASSET(Notifications_Sound_RoundEnd));
  }
}

public DrunkGames_OnPlayerFinished(const pPlayer, const iPlace) {
  Asset_PlayClientSound(pPlayer, ASSET_LIBRARY, ASSET(Notifications_Sound_Win));

  for (new pTarget = 1; pTarget <= MaxClients; ++pTarget) {
    if (!is_user_connected(pTarget)) continue;
    if (pPlayer == pTarget) continue;

    Asset_PlayClientSound(pTarget, ASSET_LIBRARY, ASSET(Notifications_Sound_Finished));
  }

  if (DrunkGames_IsFreeForAll()) {
    client_print_color(0, print_team_grey, "%s%L", CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_TOOK_PLACE", pPlayer, iPlace + 1);
  } else {
    client_print_color(0, pPlayer, "%s%L", CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_BROUGHT_TEAM_VICTORY", pPlayer);
  }
}

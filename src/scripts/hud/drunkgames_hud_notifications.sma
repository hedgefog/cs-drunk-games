#pragma semicolon 1

#include <amxmodx>

#include <drunkgames>

#define PLUGIN "[Drunk Games] Notifications HUD"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

static g_szFinishedNotificationSound[] = "events/enemy_died.wav";
static g_szWinSound[] = "events/task_complete.wav";
static g_szRoundEndSound[] = "ambience/goal_1.wav";

public plugin_precache() {
    precache_sound(g_szFinishedNotificationSound);
    precache_sound(g_szWinSound);
    precache_sound(g_szRoundEndSound);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_dictionary("drunkgames.txt");
}

public DrunkGames_Fw_RoundEnd(iTeam, bool:bFinished) {
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
        new iWinnersNum = DrunkGames_GetWinnerNum();

        if (iWinnersNum == 1) {
            if (bFinished) {
                client_print_color(0, print_team_grey, "%s %L", DRUNKGAME_CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_FINISHED_AND_WIN", DrunkGames_GetWinner(0));
            } else {
                client_print_color(0, print_team_grey, "%s %L", DRUNKGAME_CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_SURVIVED_AND_WIN", DrunkGames_GetWinner(0));
            }
        } else if (bFinished) {
            new iMaxWinners = DrunkGames_GetMaxWinners();

            if (iWinnersNum >= iMaxWinners) {
                client_print_color(0, print_team_grey, "%s %L", DRUNKGAME_CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_ALL_PLACES_TAKEN", szWinners);
            } else {
                client_print_color(0, print_team_grey, "%s %L", DRUNKGAME_CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_ONLY_FEW_PLAYERS_FINISHED", iWinnersNum, szWinners);
            }
        } else {
            client_print_color(0, print_team_grey, "%s %L", DRUNKGAME_CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_NO_ONE_FINISHED");
        }
    }

    client_cmd(0, "spk ^"%s^"", g_szRoundEndSound);
}

public DrunkGames_Fw_PlayerFinished(pPlayer, iPlace) {
    // client_print(pPlayer, print_center, "You finished and took %dnd place.", iPlace);
    client_cmd(pPlayer, "spk ^"%s^"", g_szWinSound);

    for (new pTarget = 1; pTarget <= MaxClients; ++pTarget) {
        if (!is_user_connected(pTarget)) {
            continue;
        }

        if (pPlayer == pTarget) {
            continue;
        }
    
        client_cmd(pTarget, "spk ^"%s^"", g_szFinishedNotificationSound);
    }

    if (DrunkGames_IsFreeForAll()) {
        client_print_color(0, print_team_grey, "%s %L", DRUNKGAME_CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_TOOK_PLACE", pPlayer, iPlace + 1);
    } else {
        client_print_color(0, pPlayer, "%s %L", DRUNKGAME_CHAT_PREFIX, LANG_PLAYER, "DRUNKGAMES_PLAYER_BROUGHT_TEAM_VICTORY", pPlayer);
    }
}

#if defined _drunkgames_included
  #endinput
#endif
#define _drunkgames_included

#pragma reqlib drunkgames

#include <drunkgames_const>

native DrunkGames_GetWinnerNum();
native DrunkGames_GetMaxWinners();
native DrunkGames_GetWinner(iPlace);
native DrunkGames_AddWinner(pPlayer);
native DrunkGames_RemoveWinner(pPlayer);
native DrunkGames_Player_IsFinished(pPlayer);
native bool:DrunkGames_IsFreeForAll();

forward DrunkGames_Fw_ConfigLoaded();
forward DrunkGames_Fw_PlayerFinished(pPlayer, iPlace);
forward DrunkGames_Fw_PlayerWon(pPlayer, iPlace);
forward DrunkGames_Fw_RoundEnd(iTeam, bool:bFinished);

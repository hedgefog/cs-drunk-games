#if defined _drunkgames_included
  #endinput
#endif
#define _drunkgames_included

#pragma reqlib drunkgames

#include <drunkgames_const>

native DrunkGames_GetWinnerNum();
native DrunkGames_GetMaxWinners();
native DrunkGames_GetWinner(iPlace);
native DrunkGames_AddWinner(const pPlayer);
native DrunkGames_RemoveWinner(const pPlayer);
native DrunkGames_Player_IsFinished(const pPlayer);
native bool:DrunkGames_IsFreeForAll();
native bool:DrunkGames_CanPlayerTakeDamage(const pPlayer, const pAttacker);

forward DrunkGames_OnConfigLoaded();
forward DrunkGames_OnPlayerFinished(const pPlayer, const iPlace);
forward DrunkGames_OnPlayerWon(const pPlayer, iPlace);
forward DrunkGames_OnRoundEnd(iTeam, bool:bFinished);

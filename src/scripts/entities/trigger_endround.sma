#pragma semicolon 1

#include <amxmodx>

#include <api_custom_entities>

#include <drunkgames>
#include <drunkgames_internal>

#define ENTITY_NAME ENTITY(TriggerEndRound)

public plugin_precache() {
  CE_RegisterClass(ENTITY_NAME, CE_Class_BaseTrigger);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Trigger, "@Entity_Trigger");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(TriggerEndRound), DRUNKGAMES_VERSION, "Hedgehog Fog");
}

@Entity_Trigger(const this, const pToucher) {
  CE_CallBaseMethod(pToucher);

  if (!IS_PLAYER(pToucher)) return;

  DrunkGames_AddWinner(pToucher);
}

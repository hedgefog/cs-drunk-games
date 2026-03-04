#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <api_custom_entities>

#include <drunkgames_internal>

#define ENTITY_NAME ENTITY(WallToggle)

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(WallToggle), DRUNKGAMES_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Restart(const this) {
  ExecuteHam(Ham_Spawn, this);
}

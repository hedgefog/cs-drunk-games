#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_custom_entities>

#include <drunkgames_internal>

#define ENTITY_NAME ENTITY(MultiSource)

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_MS_TARGETS 32 

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(MultiSource), DRUNKGAMES_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Restart(const this) {
  for (new i = 0; i < MAX_MS_TARGETS; i++) {
    set_ent_data(this, "CMultiSource", "m_rgTriggered", 0, i);
  }

  ExecuteHam(Ham_Spawn, this);
}

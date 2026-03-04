#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_entities>

#include <drunkgames_internal>

#define ENTITY_NAME ENTITY(Button)

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(Button), DRUNKGAMES_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Restart(const this) {
  static Float:vecStartPosition[3]; get_ent_data_vector(this, "CBaseToggle", "m_vecPosition1", vecStartPosition);
  static Float:vecAngles[3]; CE_GetMemberVec(this, CE_Member_vecAngles, vecAngles);

  set_ent_data_entity(this, "CBaseToggle", "m_hActivator", FM_NULLENT);
  set_ent_data(this, "CBaseToggle", "m_toggle_state", TS_AT_BOTTOM);
  set_ent_data_vector(this, "CBaseToggle", "m_vecFinalDest", vecStartPosition);
  
  engfunc(EngFunc_SetOrigin, this, vecStartPosition);

  set_pev(this, pev_angles, vecAngles);
  set_pev(this, pev_frame, 0.0);
  set_pev(this, pev_nextthink, -1.0);
  set_pev(this, pev_velocity, NULL_VECTOR);

  ExecuteHam(Ham_Spawn, this);
}

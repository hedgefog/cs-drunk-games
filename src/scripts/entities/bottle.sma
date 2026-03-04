#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_custom_entities>
#include <api_assets>

#include <drunkgames_internal>

#define ENTITY_NAME ENTITY(Bottle)
#define MEMBER ENTITY_MEMBER<Bottle>

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

new Float:g_flGameTime = 0.0;

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Entity_Bottle_GibsModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Entity_Bottle_Sound_Break));

  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_Bottle_ModelWorld), g_szModel, charsmax(g_szModel));

  CE_RegisterClass(ENTITY_NAME);
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Think, "@Entity_Think");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Touch, "@Entity_Touch");
  CE_ImplementClassMethod(ENTITY_NAME, CE_Method_Killed, "@Entity_Killed");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(Bottle), DRUNKGAMES_VERSION, "Hedgehog Fog");
}

public server_frame() {
  g_flGameTime = get_gametime();
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, CE_Member_flLifeTime, 10.0);
  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-4.0, -4.0, -4.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{4.0, 4.0, 4.0});
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);

  CE_SetMember(this, MEMBER(flDamage), 30.0);
  CE_SetMember(this, MEMBER(flLastTouch), 0.0);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  set_pev(this, pev_solid, SOLID_BBOX);
  set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
  set_pev(this, pev_gravity, 0.5);
  set_pev(this, pev_sequence, 1);
  set_pev(this, pev_framerate, 1.0);
  set_pev(this, pev_takedamage, DAMAGE_YES);
  set_pev(this, pev_health, 1.0);
  set_pev(this, pev_nextthink, g_flGameTime + 0.1);
}

@Entity_Think(const this) {
  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);
  static Float:flSpeed; flSpeed = xs_vec_len(vecVelocity);

  static Float:vecAVelocity[3];
  xs_vec_copy(Float:{0.0, 0.0, 0.0}, vecAVelocity);
  vecAVelocity[2] = flSpeed;
  set_pev(this, pev_avelocity, vecAVelocity);

  CE_CallBaseMethod();
  set_pev(this, pev_nextthink, g_flGameTime + 0.1);
}

@Entity_Touch(const this, const pTarget) {
  CE_CallBaseMethod(pTarget);

  if (pev(pTarget, pev_solid) < SOLID_BBOX) return;

  static pOwner; pOwner = pev(this, pev_owner);
  if (pOwner == pTarget) return;

  static Float:flLastTouch; flLastTouch = CE_GetMember(this, MEMBER(flLastTouch));
  if (g_flGameTime - flLastTouch < 0.25) return;

  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);

  static Float:flDamage;
  flDamage = IS_PLAYER(pTarget) ? 1.0 : Float:CE_GetMember(this, MEMBER(flDamage));

  if (IS_PLAYER(pTarget)) {
    vecVelocity[0] = vecVelocity[1] = 0.0;
  } else {
    xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
  }

  set_pev(this, pev_velocity, vecVelocity);
  CE_SetMember(this, MEMBER(flLastTouch), g_flGameTime);

  if (IS_PLAYER(pTarget)) {
    static Float:flForce; flForce = xs_vec_len(vecVelocity) * 0.5;
    static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
    static Float:vecTargetOrigin[3]; pev(pTarget, pev_origin, vecTargetOrigin);
    static Float:vecTargetVelocity[3]; pev(pTarget, pev_velocity, vecTargetVelocity);

    static Float:vecDir[3];
    xs_vec_sub(vecTargetOrigin, vecOrigin, vecDir);
    xs_vec_normalize(vecDir, vecDir);

    static Float:flTargetSpeed; flTargetSpeed = xs_vec_len(vecTargetVelocity);

    xs_vec_add_scaled(vecTargetVelocity, vecDir, flForce, vecTargetVelocity);
    xs_vec_normalize(vecTargetVelocity, vecTargetVelocity);
    xs_vec_mul_scalar(vecTargetVelocity, floatmax(flTargetSpeed, flForce), vecTargetVelocity);

    set_pev(pTarget, pev_velocity, vecTargetVelocity);
  }

  static Float:flTargetTakeDamage; pev(pTarget, pev_takedamage, flTargetTakeDamage);

  if (flTargetTakeDamage != DAMAGE_NO) {
    ExecuteHamB(Ham_TakeDamage, pTarget, this, pOwner, flDamage, DMG_GENERIC);
  }

  ExecuteHamB(Ham_TakeDamage, this, pTarget, pTarget, 1.0, DMG_GENERIC);
}

@Entity_Killed(const this, const pKiller, iShouldGib) {
  CE_CallBaseMethod(pKiller, iShouldGib);

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);
  xs_vec_mul_scalar(vecVelocity, -0.25, vecVelocity);

  static const iRandomVelocity = 10;
  static const iGibsNum = 20;
  static const iLifeTime = 30;

  static Float:vecSize[3]; xs_vec_set(vecSize, 4.0, 4.0, 4.0);

  static iGibsModelIndex;
  if (!iGibsModelIndex) {
    iGibsModelIndex = Asset_GetModelIndex(ASSET_LIBRARY, ASSET(Entity_Bottle_GibsModel));
  }

  engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
  write_byte(TE_BREAKMODEL);
  engfunc(EngFunc_WriteCoord, vecOrigin[0]);
  engfunc(EngFunc_WriteCoord, vecOrigin[1]);
  engfunc(EngFunc_WriteCoord, vecOrigin[2]);
  engfunc(EngFunc_WriteCoord, vecSize[0]);
  engfunc(EngFunc_WriteCoord, vecSize[1]);
  engfunc(EngFunc_WriteCoord, vecSize[2]);
  engfunc(EngFunc_WriteCoord, vecVelocity[0]);
  engfunc(EngFunc_WriteCoord, vecVelocity[1]);
  engfunc(EngFunc_WriteCoord, vecVelocity[2]);
  write_byte(iRandomVelocity);
  write_short(iGibsModelIndex);
  write_byte(iGibsNum);
  write_byte(iLifeTime);
  write_byte(0);
  message_end();

  Asset_EmitSound(this, CHAN_BODY, ASSET_LIBRARY, ASSET(Entity_Bottle_Sound_Break), .flVolume = 0.5);
}

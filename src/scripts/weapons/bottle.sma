#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>
#include <weapon_base_throwable_const>

#include <drunkgames_internal>

#define WEAPON_NAME WEAPON(Bottle)
#define ENTITY_NAME ENTITY(Bottle)

new g_szVModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_Bottle_ModelView), g_szVModel, charsmax(g_szVModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_Bottle_ModelPlayer), g_szPModel, charsmax(g_szPModel));
  Asset_Precache(ASSET_LIBRARY, ASSET(Weapon_Bottle_ModelWorld), g_szWModel, charsmax(g_szWModel));

  CW_RegisterClass(WEAPON_NAME, Weapon_BaseThrowable);

  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");

  CW_RegisterClassMethod(WEAPON_NAME, Weapon_BaseThrowable_Method_Throw, "@Weapon_Throw");
  CW_RegisterClassMethod(WEAPON_NAME, Weapon_BaseThrowable_Method_SpawnProjectile, "@Weapon_SpawnProjectile");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Bottle), DRUNKGAMES_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWModel);
  CW_SetMember(this, CW_Member_iId, CSW_DEAGLE);
  CW_SetMember(this, CW_Member_iSlot, 0);
  CW_SetMember(this, CW_Member_iPosition, 1);
  CW_SetMemberString(this, CW_Member_szIcon, "bottle");

  CW_SetMember(this, Weapon_BaseThrowable_Member_flThrowForce, 750.0);
}

@Weapon_Deploy(const this) {
  static Float:flGameTime; flGameTime = get_gametime();

  if (!CW_CallBaseMethod()) return;

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szVModel, g_szPModel, 3, "grenade");

  CW_SetMember(this, CW_Member_flTimeIdle, flGameTime + 0.5);
  CW_SetMember(this, CW_Member_iClip, 1);
}

@Weapon_Idle(const this) {
  static bool:bRedeploy; bRedeploy = CW_GetMember(this, Weapon_BaseThrowable_Member_bRedeploy);
  static Float:flStartThrow; flStartThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flStartThrow);
  static Float:flReleaseThrow; flReleaseThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flReleaseThrow);

  CW_CallBaseMethod();

  if (!flStartThrow && flReleaseThrow == -1.0 && !bRedeploy) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 61.0 / 30.0);
  }
}

@Weapon_PrimaryAttack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static Float:flStartThrow; flStartThrow = CW_GetMember(this, Weapon_BaseThrowable_Member_flStartThrow);

  if (flStartThrow > 0.0 && is_user_bot(pPlayer)) {
    CW_CallNativeMethod(this, CW_Method_Idle);
    return;
  }

  if (!CW_CallBaseMethod()) return;

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 19.0 / 30.0);

  // Force throw for bots 
  if (is_user_bot(pPlayer)) {
    CW_CallNativeMethod(this, CW_Method_Idle);
  }
}

@Weapon_Throw(const this) {
  CW_CallBaseMethod();
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 16.0 / 30.0);
}

@Weapon_SpawnProjectile(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

  xs_vec_add_scaled(vecSrc, vecForward, 16.0, vecSrc);

  new pBottle = CE_Create(ENTITY_NAME, vecSrc);
  if (pBottle == FM_NULLENT) return FM_NULLENT;

  set_pev(pBottle, pev_owner, pPlayer);
  dllfunc(DLLFunc_Spawn, pBottle);

  return pBottle;
}

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  CW_CallBaseMethod(pWeaponBox);

  engfunc(EngFunc_SetModel, pWeaponBox, g_szWModel);
}

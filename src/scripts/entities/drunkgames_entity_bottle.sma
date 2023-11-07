#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_custom_entities>

#include <drunkgames>

#define PLUGIN "[Entity] drunkgames_bottle"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

#define IS_PLAYER(%1) (%1 > 0 && %1 <= MaxClients)

#define ENTITY_NAME "drunkgames_bottle"

new g_iCeHandler;
new g_iGibsModelIndex;

public plugin_precache() {
    precache_model(DRUNKGAME_MODEL_WEAPON_BOTTLE_W);

    g_iCeHandler = CE_Register(ENTITY_NAME);
    CE_RegisterHook(CEFunction_Init, ENTITY_NAME, "@Entity_Init");
    CE_RegisterHook(CEFunction_Spawned, ENTITY_NAME, "@Entity_Spawned");
    CE_RegisterHook(CEFunction_Kill, ENTITY_NAME, "@Entity_Kill");

    g_iGibsModelIndex = precache_model(DRUNKGAME_MODEL_BOTTLE_GIBS);
    precache_sound(DRUNKGAME_SOUND_BOTTLE_HIT);
}

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHam(Ham_Touch, CE_BASE_CLASSNAME, "Ham_Base_Touch_Post", .Post = 1);
    RegisterHam(Ham_Think, CE_BASE_CLASSNAME, "Ham_Base_Think", .Post = 0);
}

@Entity_Init(this) {
    CE_SetMember(this, CE_MEMBER_LIFETIME, 10.0);
    CE_SetMemberVec(this, CE_MEMBER_MINS, Float:{-4.0, -4.0, -4.0});
    CE_SetMemberVec(this, CE_MEMBER_MAXS, Float:{4.0, 4.0, 4.0});
    CE_SetMemberString(this, CE_MEMBER_MODEL, DRUNKGAME_MODEL_WEAPON_BOTTLE_W);
}

@Entity_Spawned(this) {
    set_pev(this, pev_solid, SOLID_BBOX);
    set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
    set_pev(this, pev_gravity, 0.5);
    set_pev(this, pev_sequence, 1);
    set_pev(this, pev_framerate, 1.0);
    set_pev(this, pev_takedamage, DAMAGE_YES);
    set_pev(this, pev_health, 1.0);
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Kill(this) {
    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    static Float:vecVelocity[3];
    pev(this, pev_velocity, vecVelocity);
    xs_vec_mul_scalar(vecVelocity, -0.25, vecVelocity);

    static const iRandomVelocity = 10;
    static const iGibsNum = 20;
    static const iLifeTime = 30;

    static Float:vecSize[3];
    vecSize[0] = 4.0;
    vecSize[1] = 4.0;
    vecSize[2] = 4.0;

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
    write_short(g_iGibsModelIndex);
    write_byte(iGibsNum);
    write_byte(iLifeTime);
    write_byte(0);
    message_end();

    emit_sound(this, CHAN_BODY, DRUNKGAME_SOUND_BOTTLE_HIT, 0.5, ATTN_NORM, 0, PITCH_NORM);
}

@Entity_Think(this) {
    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);

    static Float:vecVelocity[3];
    pev(this, pev_velocity, vecVelocity);

    new Float:flSpeed = xs_vec_len(vecVelocity);

    static Float:vecAVelocity[3];
    xs_vec_copy(Float:{0.0, 0.0, 0.0}, vecAVelocity);
    vecAVelocity[2] = flSpeed;
    set_pev(this, pev_avelocity, vecAVelocity);

    // fix collision for hight velocity
    // set_pev(this, pev_solid, flSpeed > 1024.0 ? SOLID_BBOX : SOLID_TRIGGER);

    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

public Ham_Base_Touch_Post(pEntity, pTarget) {
    if (CE_GetHandlerByEntity(pEntity) != g_iCeHandler) {
        return HAM_IGNORED;
    }

    if (pev(pTarget, pev_solid) < SOLID_BBOX) {
        return HAM_IGNORED;
    }

    new pOwner = pev(pEntity, pev_owner);
    if (pOwner == pTarget) {
        return HAM_IGNORED;
    }

    new Float:flLastTouch = Float:pev(pEntity, pev_fuser1);
    if (get_gametime() - flLastTouch < 0.25) {
        return HAM_IGNORED;
    }

    static Float:vecVelocity[3];
    pev(pEntity, pev_velocity, vecVelocity);

    new Float:flDamage = IS_PLAYER(pTarget) ? 1.0 : 30.0;

    if (IS_PLAYER(pTarget)) {
        vecVelocity[0] = vecVelocity[1] = 0.0;
    } else {
        xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
    }

    set_pev(pEntity, pev_velocity, vecVelocity);
    set_pev(pEntity, pev_fuser1, get_gametime());


    if (IS_PLAYER(pTarget)) {
        static Float:flForce; flForce = xs_vec_len(vecVelocity) * 0.5;

        static Float:vecOrigin[3];
        pev(pEntity, pev_origin, vecOrigin);

        static Float:vecTargetOrigin[3];
        pev(pTarget, pev_origin, vecTargetOrigin);

        static Float:vecDir[3];
        xs_vec_sub(vecTargetOrigin, vecOrigin, vecDir);
        xs_vec_normalize(vecDir, vecDir);

        static Float:vecTargetVelocity[3];
        pev(pTarget, pev_velocity, vecTargetVelocity);

        static Float:flTargetSpeed; flTargetSpeed = xs_vec_len(vecTargetVelocity);

        xs_vec_add_scaled(vecTargetVelocity, vecDir, flForce, vecTargetVelocity);
        xs_vec_normalize(vecTargetVelocity, vecTargetVelocity);
        xs_vec_mul_scalar(vecTargetVelocity, floatmax(flTargetSpeed, flForce), vecTargetVelocity);

        set_pev(pTarget, pev_velocity, vecTargetVelocity);
    }

    static Float:flTargetTakeDamage;
    pev(pTarget, pev_takedamage, flTargetTakeDamage);

    if (flTargetTakeDamage != DAMAGE_NO) {
        ExecuteHamB(Ham_TakeDamage, pTarget, pEntity, pOwner, flDamage, DMG_GENERIC);
    }

    ExecuteHamB(Ham_TakeDamage, pEntity, pTarget, pTarget, 1.0, DMG_GENERIC);

    return HAM_HANDLED;
}

public Ham_Base_Think(pEntity) {
    if (CE_GetHandlerByEntity(pEntity) != g_iCeHandler) {
        return HAM_IGNORED;
    }

    @Entity_Think(pEntity);

    return HAM_HANDLED;
}

#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <drunkgames>

#define PLUGIN "[Drunk Games] Player"
#define VERSION DRUNKGAME_VERSION
#define AUTHOR "Hedgehog Fog"

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    RegisterHamPlayer(Ham_Touch, "HamHook_Player_Touch_Post", .Post = 1);
}

public HamHook_Player_Touch_Post(pPlayer, pToucher) {
    if (IS_PLAYER(pToucher) && rg_is_player_can_takedamage(pPlayer, pToucher)) {
        static Float:vecOrigin[3];
        pev(pToucher, pev_origin, vecOrigin);

        static Float:vecToucherOrigin[3];
        pev(pPlayer, pev_origin, vecToucherOrigin);

        static Float:vecDir[3];
        xs_vec_sub(vecToucherOrigin, vecOrigin, vecDir);
        vecDir[2] = 0.0;
        xs_vec_normalize(vecDir, vecDir);

        static Float:vecToucherVelocity[3];
        pev(pToucher, pev_velocity, vecToucherVelocity);

        static Float:flPushForce;
        flPushForce = floatmax(xs_vec_dot(vecToucherVelocity, vecDir) * 0.5, 32.0);

        static Float:vecVelocity[3];
        pev(pPlayer, pev_velocity, vecVelocity);
        xs_vec_add_scaled(vecVelocity, vecDir, flPushForce, vecVelocity);

        set_pev(pPlayer, pev_velocity, vecVelocity);
    }
}

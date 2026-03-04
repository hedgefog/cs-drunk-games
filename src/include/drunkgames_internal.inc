#if defined _drunkgames_internal_included
  #endinput
#endif
#define _drunkgames_internal_included

#include <drunkgames_const>

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

#define NAMESPACE(%1) DrunkGames_%1
#define NAMESPACE_FIELD<%1>(%2) NAMESPACE(%1)_%2

// Entity shortcuts
#define ENTITY(%1) NAMESPACE_FIELD<Entity>(%1)
#define ENTITY_DATA<%1>(%2,%3) ENTITY(%2)_%1_%3
#define ENTITY_MEMBER<%1>(%2) ENTITY_DATA<Member>(%1,%2)

// Weapon shortcuts
#define WEAPON(%1) NAMESPACE_FIELD<Weapon>(%1)
#define WEAPON_DATA<%1>(%2,%3) WEAPON(%2)_%1_%3
#define WEAPON_MEMBER<%1>(%2) WEAPON_DATA<Member>(%1,%2)

// Asset shortcuts
#define ASSET(%1) NAMESPACE_FIELD<Asset>(%1)
#define ASSET_LIBRARY NAMESPACE(AssetLibrary)

// Plugin registration
#define PLUGIN_NAME(%1) "[Drunk Games] " + %1
#define ENTITY_PLUGIN(%1) "[Entity] Drunk Games " + #%1
#define WEAPON_PLUGIN(%1) "[Weapon] Drunk Games " + #%1
#define ENTITY_EXTENSION_PLUGIN(%1) "[Entity Extension] Drunk Games " + #%1

// CVar
#define CVAR(%1) "drunkgames_" + %1

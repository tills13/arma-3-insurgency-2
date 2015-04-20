if (!isServer && isNull player) then { isJIP = true; } else { isJIP = false; };
if (!isDedicated) then { waitUntil {!isNull player && isPlayer player}; };
enableSaving [false, false]; 

#include "insurgency\core\functions.sqf";

if (isServer) then {
	[] execVM "insurgency\modules\vehicles\INS_vehicles_respawn.sqf";
};

if (!isDedicated) then { // players
	[] execVM "insurgency\modules\players\groups.sqf";
};

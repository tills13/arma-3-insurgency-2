/* INS_fnc_fillVehicleSeats 
 * args: [vehicle object, crew size, side] 
 * crew size -1 for random */
INS_fnc_fillVehicleSeats = {
	_vehicle = _this select 0;
	_size = if (typeName  (_this select 1) == "Array") then { (random 9) max 5 } else { // gonna leave this in just to make sure
		if ((_this select 1) == -1) then { (random 10) max 5 } else { _this select 1 } // should always be this
	};

	//_size = if ((_this select 1) == -1) then { (random 10) max 5 } else { _this select 1 };
	_side = _this select 2;

	_vehPositions = [typeOf _vehicle] call BIS_fnc_vehicleRoles;
	_veh_group = createGroup _side;
	_veh_crew = createGroup _side;

	{
		if (count units _veh_group > _size) exitWith {};

		_currentPosition = _x;
		_pool = call compile format["%1_crews", toLower (str _side)];
		_type = _pool call BIS_fnc_selectRandom;
		_unit = [_type, if (_currentPosition select 0 in ["driver", "turret"]) then { _veh_crew } else { _veh_group }, position _vehicle, [], 5, "CAN_COLLIDE"] call INS_fnc_spawnUnit;	

		if (_currentPosition select 0 == "driver") then {				
			_unit assignAsDriver _vehicle;
			_unit moveInDriver _vehicle;
		} else {
			if (_currentPosition select 0 == "turret") then {
				_unit assignAsGunner _vehicle;
				_unit moveInTurret [_vehicle, _currentPosition select 1];
			} else {
				_unit moveInCargo _vehicle;
			};
		};
	} forEach _vehPositions;

	_vehicle setVariable ["group", _veh_group];
};

// ---------------------------------------
//	helper functions
// ---------------------------------------

dl_fnc_getAIGroup = {
	_group = group ((player call dl_fnc_getAIForPlayer) call BIS_fnc_selectRandom);
	if (isNil "_group") then { _group = createGroup east; };

	_group
};

/* dl_fnc_getAIArray
 * args: array of units
 * returns: an array of AI units */
dl_fnc_getAIArray = {
	_array = _this;
	_aiPlayerList = [];

	{ if (!(isPlayer _x)) then { _aiPlayerList = _aiPlayerList + [_x]; }; } forEach _array;

	_aiPlayerList;
};

/* dl_fnc_getAIArray
 * args: group
 * returns: an array of AI units */
dl_fnc_getAIinGroup = {
	_group = _this;
	_aiPlayerList = [];

	{ if (!(isPlayer _x)) then { _aiPlayerList = _aiPlayerList + [_x]; }; } forEach units _group;

	_aiPlayerList;
};

/* dl_fnc_dismissAIFromGroup
 * args: group
 * dismisses all AI from a group */
dl_fnc_dismissAIFromGroup = {
	_group = _this;

	{ deleteVehicle _x; } forEach (_group call dl_fnc_getAIinGroup);
};

/* INS_fnc_onDeathListener
 * args: [unit]
 * spawns an intel item at the unit's position INS_prodOfDrop% of the time */
INS_fnc_onDeathListener = {
	_tempRandom = random 100;

	if (_tempRandom > (100 - INS_probOfDrop) || debugMode == 1) then {
		_unit = _this select 0;
		_pos = position _unit;
		_intel = createVehicle ["Land_Suitcase_F", _pos, [], 0, "CAN_COLLIDE"];
		_intel setVariable ["INTEL_STRENGTH", (rank _unit) call INS_fnc_getRankModifier];

		[_intel] spawn {
			_listen = true;
			_intel = _this select 0;
			_pos = getPos _intel;

			timeSlept = 0;
			while { _listen } do {
				sleep 0.5;
				timeSlept = timeSlept + 0.5;

				if (timeSlept > INS_intelTimeout) then { deleteVehicle _intel; _listen = false; };

				_nearUnits = _pos nearEntities [["CAManBase", "Car"], 2];

				{ 
					if (side _x == west) then {
						["New Intel", "New intel received on the location of an ammo cache. A marker has been added to the map.", true, true] call dl_fnc_hintMP;
						[_intel, "INS_fnc_createIntel", false, false] spawn BIS_fnc_MP;
						deleteVehicle _intel;
						_listen = false;
					}; 
				} forEach _nearUnits;	
			};
		};	
	};
};

/* INS_fnc_initAIUnit
 * args: unit
 * sets up an AI unit */
INS_fnc_initAIUnit = {
	private ["_unit"];
	_unit = _this;
	
	_unit setSkill ['aimingAccuracy', 0.2];
	_unit setSkill ['aimingShake', 0.5];
	_unit setSkill ['aimingSpeed', 0.2];
	_unit setSkill ['spotDistance', 0.4];
	_unit setSkill ['spotTime', 0.4];
	_unit setSkill ['courage', 0.5];
	_unit setSkill ['reloadSpeed', 0.5];
	_unit setSkill ['commanding', 0.5];
	_unit setSkill ['general', 0.5];

	//diag_log format["spawning %1 %2", player call dl_fnc_getNextAINameForPlayer, _unit];
	call compile format ["%1 = _unit;", player call dl_fnc_getNextAINameForPlayer];
	if (side _unit == east) then { _unit addEventHandler ["Killed", INS_fnc_onDeathListener]; };
};
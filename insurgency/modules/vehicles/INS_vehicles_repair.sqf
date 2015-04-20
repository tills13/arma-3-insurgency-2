#define DEF_FIELDREPAIR_EACH_PART_TIME 30
#define DEF_FIELDREPAIR_EACH_HARDPART_TIME 60
#define DEF_FULLREPAIR_LENGTH 120
#define DEF_REPAIR_TRUCK_USES 5
#define DEF_FREE_REPAIRS 1

#define STR_ACT_FIELD_REPAIR "Quick Repair"
#define STR_ACT_CANCEL_ACTION "Cancel Action"
#define STR_ACT_SERIOUS_REPAIR "Full Repair"
#define STR_ACT_PUSH_APC "Push Vehicle"
#define STR_REPAIR_CONDITIONS "Bad Conditions for Repair"
#define STR_ANOTHER_ACTION "<t size='0.75' color='#ff6347'>Another Action in Progress</t>"
#define STR_NEED_TOOLKIT "Need ToolKit in Inventory (player or vehicle)"
#define STR_REPAIR_INTERRUPTED "<t size='0.75' color='#ff6347'>Repair Interrupted</t>"
#define STR_REPAIR_FINISHED "<t size='0.75' color='#7ba151'>Repair Finished</t>"
#define STR_REPAIR_MSG_STRING "<t size='0.75'><t color='#ff6347'>%2</t> will be repaired in <t color='#ff6347'>%1</t> second(s)</t>"

INS_veh_repair_loop = [_this, 0, false] call BIS_fnc_param;

if (isServer) then {
	[] spawn {
		_first = true;
		while { _first or INS_veh_repair_loop } do {
			{ 
				if (getRepairCargo _x > 0) then {
					_x setRepairCargo 0;
					_x setVariable ["INS_veh_repair_cargo", 1, true]; 
				};
			} foreach vehicles;

			_first = false;
			sleep 26.1;
		};
	};
};

INS_veh_fnc_partRepair = {
	private "_veh";
	_veh = [_this, 0] call BIS_fnc_param;

	if (!isNil "_veh") then {
		{
			_dmg = (_veh getHitPointDamage _x);
			if (!isNil "_dmg") then {
				if (_dmg > 0.64) then {
					if (_x in INS_veh_hardRepairParts) then {
						_veh setHitPointDamage [_x, 0.64];
					} else {
						_veh setHitPointDamage [_x, 0];
					};
				};
			};
		} foreach INS_veh_repair_hps;
	};
};

INS_veh_fnc_fullRepair = {
	private "_veh";
	_veh = [_this, 0] call BIS_fnc_param;
	_veh setDamage 0;
};

INS_veh_repair_hps = ["HitLFWheel", "HitLBWheel", "HitLMWheel", "HitLF2Wheel", "HitRFWheel", "HitRBWheel", "HitRMWheel", "HitRF2Wheel", "HitEngine", "HitLTrack", "HitRTrack"] + ["HitFuel", "HitAvionics", "HitVRotor", "HitHRotor"];
INS_veh_hardRepairParts = ["HitEngine", "HitLTrack", "HitRTrack"] + ["HitFuel", "HitAvionics", "HitHRotor"];

if (isDedicated) exitWith {};
waitUntil {player == player};
INS_veh_mutexAction = false;

INS_veh_fnc_vehicleDamaged = {
	private ["_veh", "_flag"];
	_veh =  [_this, 0] call BIS_fnc_param;
	if (isNil "_veh") exitWith {false};
	_flag = false;

	{
		_cdmg = _veh getHitPointDamage (_x);
		if (!isNil "_cdmg") then { if (_cdmg > 0.64) exitWith { _flag = true }; };
	} forEach INS_veh_repair_hps;

	_flag
};

INS_veh_frpr_getPartsRepairTime = {
	private ["_veh", "_vehtype", "_flag"];
	_veh =  [_this, 0] call BIS_fnc_param;
	if (isNil "_veh") exitWith {1};
	_rprTime = 0;

	{
		_cdmg = _veh getHitPointDamage (_x);
		if (!isNil "_cdmg") then {
			if (_cdmg > 0.64) exitWith { _rprTime = _rprTime + (if (_x in INS_veh_hardRepairParts) then {DEF_FIELDREPAIR_EACH_HARDPART_TIME} else {DEF_FIELDREPAIR_EACH_PART_TIME}); };
		};
	} forEach INS_veh_repair_hps;
	_rprTime;
};

INS_veh_fnc_notify_normal = {
	[_this, 0, 1, 5, 0, 0, 301] spawn bis_fnc_dynamicText;
};

INS_veh_fnc_notify_hint = {
	hint parseText _this;
};

INS_veh_fnc_notify_hint_wrapper = {
	[_this, "INS_veh_fnc_notify_hint", true] spawn BIS_fnc_MP;
};

INS_veh_fnc_hastk = {
	private ["_ret"];
	_ret = 0;

	if ("ToolKit" in (items player)) then { _ret = 1; };
	if ("ToolKit" in (itemCargo _veh)) then { _ret = 2; };
	if ((_veh getVariable ["INS_veh_longrepair_times", 0]) < DEF_FREE_REPAIRS) then { _ret = 3; };

	_ret;
};


INS_veh_fnc_removeItemFromCargo = {
	private ["_veh"];
	_item = [_this, 0, ""] call BIS_fnc_param;
	_veh = [_this, 1] call BIS_fnc_param;

	_allitems = itemcargo _veh;
	clearItemCargoGlobal _veh;
	_allitems = _allitems call BIS_fnc_consolidateArray;
	_n = [_allitems, _item] call BIS_fnc_findInPairs;
	_allitems set [_n, [(_allitems select _n) select 0, ((_allitems select _n) select 1) - 1]];

	{ _veh addItemCargoGlobal [_x select 0, _x select 1]; } foreach _allitems;
};

INS_veh_fnc_quickRepair = {
	private ["_veh"];
	_veh = (nearestObjects [player, ["LandVehicle", "Air", "Ship"], 7]) select 0;
	if (!isNil "_veh") then {
		if (INS_veh_mutexAction) exitWith { STR_ANOTHER_ACTION call INS_veh_fnc_notify_normal; };
		if (not alive player or (player distance _veh) > 7 or (vehicle player != player) or speed _veh > 3) exitWith {STR_REPAIR_CONDITIONS call INS_veh_fnc_notify_normal; };
		_hastk = [] call INS_veh_fnc_hastk;
		if (_hastk == 0) exitWith { STR_NEED_TOOLKIT call INS_veh_fnc_notify_normal; };

		_repairFinished = false;
		INS_veh_mutexAction = true;

		_lastPlayerState = animationState player;
		player playActionNow "medicStartRightSide";
		sleep 0.5;

		_maxlength = _veh getVariable["INS_veh_longrepair", [_veh] call INS_veh_frpr_getPartsRepairTime];
		_vehname = "";
		if (vehicleVarName _veh != "") then { _vehname = vehicleVarName _veh; } 
		else { _vehname = getText (configFile >> "CfgVehicles" >> typeOf(_veh) >> "displayName"); };
		_length = _maxlength;
		_cycle = 0;

		while {alive player and (player distance _veh) < 7 and (vehicle player == player) and speed _veh < 3 and !(_repairFinished) and INS_veh_mutexAction and (_cycle < 3 or (["medic", animationState player] call BIS_fnc_inString))} do {
			(format[STR_REPAIR_MSG_STRING, _length, _vehname]) call INS_veh_fnc_notify_normal;
			if (_length <= 0) then { _repairFinished = true; };
			_length = _length - 1;
			sleep 1;

			_cycle = _cycle + 1;
		};

		if (_repairFinished) then {
			STR_REPAIR_FINISHED call INS_veh_fnc_notify_normal;
			[_veh, "INS_veh_fnc_partRepair", _veh] call bis_fnc_MP;
			_veh setVariable["INS_veh_longrepair",nil, true];
			_veh setVariable["INS_veh_longrepair_times", (_veh getVariable ["INS_veh_longrepair_times",0]) + 1, true];
		} else {
			STR_REPAIR_INTERRUPTED call INS_veh_fnc_notify_normal;
			_veh setVariable["INS_veh_longrepair",_length, true];
		};

		INS_veh_mutexAction = false;  
		player playActionNow "medicstop";
	};
};


INS_veh_fnc_repair_cond = {
	private ["_veh", "_ret"];
	_ret = false;
	_veh = (nearestObjects [player, ["LandVehicle", "Air", "Ship"], 7]) select 0;
	if (isNil "_veh") exitWith { _ret };

	_dmged = _veh call INS_veh_fnc_vehicleDamaged;
	_ret = (alive player and {(player distance _veh) <= 7} and {(vehicle player == player)} and {speed _veh < 3} and {not INS_veh_mutexAction} and { _dmged} and {alive _veh});
	_ret
};

INS_veh_fnc_heavyRepair = {
	_caller = player;
	_truck = vehicle _caller;
	_veh = cursorTarget;

	if (!isNil "_veh" or {!isNull _truck} or {!isNull _veh}) then {
		if (INS_veh_mutexAction) exitWith { STR_ANOTHER_ACTION call INS_veh_fnc_notify_normal; };
		if (not alive player or vehicle player == player or speed _veh > 3 or _veh distance _truck > 15) exitWith { STR_REPAIR_CONDITIONS call INS_veh_fnc_notify_normal; };
		
		_repairFinished = false;
		INS_veh_mutexAction = true;

		_maxlength = _veh getVariable["INS_veh_longRepairTruck", DEF_FULLREPAIR_LENGTH];
		_vehname = "";
		if (vehicleVarName _veh != "") then { _vehname = vehicleVarName _veh; } 
		else { _vehname = getText (configFile >> "CfgVehicles" >> typeOf(_veh) >> "displayName"); };
		_length = _maxlength;

		while { alive player and alive _truck and alive _veh and vehicle _caller != _caller and speed _veh <= 3 and not _repairFinished and INS_veh_mutexAction and _veh distance _truck <= 15 } do {			
			(format[STR_REPAIR_MSG_STRING, _length, _vehname]) call INS_veh_fnc_notify_normal;
			if (_length <= 0) then { _repairFinished = true; };
			_length = _length - 1;
			sleep 1;
		};
		
		if (_repairFinished) then {
			STR_REPAIR_FINISHED call INS_veh_fnc_notify_normal;
			[_veh, "INS_veh_fnc_fullRepair", _veh] call bis_fnc_MP;
			_truck setVariable ["INS_veh_repair_cargo", ((_truck getVariable ["INS_veh_repair_cargo", 0]) - (1 / DEF_REPAIR_TRUCK_USES)), true];
			
			_veh setVariable["INS_veh_longRepairTruck", nil, true];
			_veh setVariable["INS_veh_fullrepair_times", (_veh getVariable ["INS_veh_fullrepair_times", 0]) + 1, true];
		} else {
			STR_REPAIR_INTERRUPTED call INS_veh_fnc_notify_normal;
			_veh setVariable["INS_veh_longRepairTruck", _length, true];
		};

		INS_veh_mutexAction = false;
	};	
};

INS_veh_pushAPC = {
	private ["_veh", "_unit"];
	_veh = vehicle player;

	if (!INS_veh_mutexAction) then {
		INS_veh_mutexAction = true;
		sleep 1.0;

		_spd = 3;
		_dir = direction _veh;
		_veh setVelocity [(sin _dir) * _spd, (cos _dir) * _spd, 0];  

		INS_veh_mutexAction = false;
	};
};

if (isNil "INS_veh_cancelActionId") then {
	INS_veh_cancelActionId = player addAction["<t color='#ff6347'>" + STR_ACT_CANCEL_ACTION + "</t>", {INS_veh_mutexAction = false}, [], 10, false, true, '',' INS_veh_mutexAction  '];
	
	player addAction["<t color='#5dc183'>" + STR_ACT_FIELD_REPAIR + "</t>", INS_veh_fnc_quickRepair, [], -1, false, true, '','[] call INS_veh_fnc_repair_cond'];
	player addAction["<t color='#cd380e'>" + STR_ACT_SERIOUS_REPAIR + "</t>", INS_veh_fnc_heavyRepair, [], -1, false, true, '','_truck=(vehicle player);_truck getVariable ["INS_veh_repair_cargo", -1] != -1 and {alive cursorTarget} and { _truck distance cursorTarget <= 15} and {(cursorTarget isKindOf "LandVehicle" or cursorTarget isKindOf "Ship" or cursorTarget isKindOf "Air")} and {not INS_veh_mutexAction} and {speed cursorTarget <= 3} and {(damage cursorTarget != 0)}'];
	player addAction["<t color='#ffffff'>" + STR_ACT_PUSH_APC + "</t>", INS_veh_pushAPC, [], 5, false, true, "", "canMove (vehicle player) and ((vehicle player) isKindOf 'Wheeled_APC_F') and player == driver (vehicle player) and surfaceIsWater getpos (vehicle player)  and abs(speed (vehicle player)) < 3 and not INS_veh_mutexAction"];   
};

player addEventHandler ["Respawn", {
	INS_veh_cancelActionId = player addAction["<t color='#ff6347'>" + STR_ACT_CANCEL_ACTION + "</t>", {INS_veh_mutexAction = false}, [], 10, false, true, '',' INS_veh_mutexAction  '];
	
	player addAction["<t color='#5dc183'>" + STR_ACT_FIELD_REPAIR + "</t>", INS_veh_fnc_quickRepair, [], -1, false, true, '','[] call INS_veh_fnc_repair_cond'];
	player addAction["<t color='#cd380e'>" + STR_ACT_SERIOUS_REPAIR+ "</t>", INS_veh_fnc_heavyRepair, [], -1, false, true, '','_truck = (vehicle player);_truck getVariable ["INS_veh_repair_cargo", -1] != -1 and {alive cursorTarget} and { _truck distance cursorTarget <= 15 } and {(cursorTarget isKindOf "LandVehicle" or cursorTarget isKindOf "Ship" or cursorTarget isKindOf "Air")} and {not INS_veh_mutexAction} and {speed cursorTarget <= 3} and {(damage cursorTarget != 0)}'];
	player addAction["<t color='#ffffff'>" + STR_ACT_PUSH_APC + "</t>", INS_veh_pushAPC, [], 5, false,true, "", "canMove (vehicle player) and ((vehicle player) isKindOf 'Wheeled_APC_F') and player == driver (vehicle player) and surfaceIsWater getpos (vehicle player)  and abs(speed (vehicle player)) < 3 and not INS_veh_mutexAction"];   
}];
debugMode = 1; 
INS_veh_updateLocation = {
	private ["_vehicle"];

	_vehicle = (_this select 0);
	_newPos = (_this select 1);
	_newDir = (_this select 2);

	_vehicle setVariable ["RES_ORIG_LOC", _newPos];
	_vehicle setVariable ["RES_ORIG_DIR", _newDir];
	if (debugMode == 1) then { diag_log format ["updated %1's location to %2 (%3)", vehicleVarName _vehicle, _newPos, _newDir]; };
};

INS_veh_initParams = {
	private ["_vehicle"];

	_vehicle = (_this select 0);
	_name = (_this select 1);
	_init = (_this select 2);

	if (debugMode == 1) then { diag_log format["initializing %1: %2", _name, _init]; };
	_vehicle call compile format ["%1 = _this; publicVariable ""%1""; " + _init, _name];
	_vehicle setVehicleVarName _name;
};

INS_veh_addVehtoArray = {
	_vehicle = (_this select 0);
	_name = (_this select 1);
	_destroyedRespawnDelay = (_this select 2);
	_abandonedRespawnDelay = (_this select 3);
	_abandon = if (_abandonedRespawnDelay == 0) then { false } else { true };
	_init = if (count _this > 4) then { (_this select 4) } else { "" };

	_vehicle setVariable ["RES_NAME", _name];
	_vehicle setVariable ["RES_DESTROY_RESPAWN_DELAY", _destroyedRespawnDelay];
	_vehicle setVariable ["RES_ABANDON_RESPAWN_DELAY", _abandonedRespawnDelay];
	_vehicle setVariable ["RES_ABANDON", _abandon];
	_vehicle setVariable ["RES_ABANDON_LISTEN", false];
	_vehicle setVariable ["RES_ABANDON_WARN", true];
	_vehicle setVariable ["RES_ABANDON_TIME", 0];
	_vehicle setVariable ["RES_INIT", _init];
	_vehicle setVariable ["RES_ORIG_TYPE", typeOf _vehicle];
	_vehicle setVariable ["RES_ORIG_LOC", getPos _vehicle];
	_vehicle setVariable ["RES_ORIG_DIR", getDir _vehicle];

	[[_vehicle, _name, _init], "INS_veh_initParams", true, true] spawn BIS_fnc_MP; // init parameters
	if (debugMode == 1) then { diag_log format["INS_VEH_RESPAWN: adding %1 to respawn array [%2, %3]", _name, _destroyedRespawnDelay, _abandonedRespawnDelay]; };

	vehicleArray = vehicleArray + [_vehicle];
};

if (isNil "vehicleArray") then { vehicleArray = []; /*publicVariable "vehicleArray";*/ };
if (isServer) then { // server loop
	if (count _this == 0) then { // called script to loop
		if (debugMode == 1) then { diag_log format["INS_VEH_RESPAWN: starting respawn loop"]; };
		while { true } do {
			{
				_veh = _x;

				_name = _veh getVariable "RES_NAME";
				_destroyedRespawnDelay = _veh getVariable "RES_DESTROY_RESPAWN_DELAY";
				_abandonedRespawnDelay = _veh getVariable "RES_ABANDON_RESPAWN_DELAY";
				_abandon = _veh getVariable "RES_ABANDON";
				_abandonedTime = _veh getVariable "RES_ABANDON_TIME";
				_respawn = false;
				_abandoned = false;
				_delay = 0;

				_abandonedListen = _veh getVariable ["RES_ABANDON_LISTEN", false];
				_abandonWarn = _veh getVariable ["RES_ABANDON_WARN", true];

				if (_abandon and !_abandonedListen and (count crew _veh != 0)) then { _abandonedListen = true; };
				if (_abandon and _abandonedListen and (count crew _veh == 0)) then { _abandonedTime = _abandonedTime + 1; };
				if (_abandon and _abandonedListen and (count crew _veh != 0)) then { _abandonedTime = 0; };

				_veh setVariable ["RES_ABANDON_TIME", _abandonedTime];
				_veh setVariable ["RES_ABANDON_LISTEN", _abandonedListen];

				if (_abandon and _abandonedTime > _abandonedRespawnDelay) then { _abandoned = true; _respawn = true; };
				if (_abandonedListen and _abandonedTime > (_abandonedRespawnDelay - 60) and _abandonWarn and (count crew _veh == 0)) then { [nil, format["<t color='#ff6347'>%1</t> will respawn in %2 seconds", _name, _abandonedRespawnDelay - _abandonedTime], true, true] call dl_fnc_hintMP; _abandonWarn = false; };
				_veh setVariable ["RES_ABANDON_WARN", _abandonWarn];

				if (!alive _veh) then { _respawn = true; _delay = _destroyedRespawnDelay; };
				if (_respawn) then {
					[_veh, _abandoned, _delay] spawn {
						_veh = _this select 0; 
						_abandoned = _this select 1; 
						_delay = _this select 2;

						if (_delay != 0) then { sleep _delay; };

						_name = _veh getVariable "RES_NAME";
						_init = _veh getVariable "RES_INIT";
						_type = _veh getVariable "RES_ORIG_TYPE";
						_origLoc = _veh getVariable "RES_ORIG_LOC";
						_origDir = _veh getVariable "RES_ORIG_DIR";
						_destroyedRespawnDelay = _veh getVariable "RES_DESTROY_RESPAWN_DELAY";
						_abandonedRespawnDelay = _veh getVariable "RES_ABANDON_RESPAWN_DELAY";

						_reason = if (_abandoned) then {"abandoned"} else {"destroyed"};
						[nil, format["respawning %1 vehicle: <t color = '#ff6347'>%2</t>", _reason, _name], true, true] call dl_fnc_hintMP;

						vehicleArray = vehicleArray - [_veh];
						deleteVehicle _veh;
						sleep 3;

						_veh = _type createVehicle _origLoc;
						_veh setDir _origDir;
						[_veh, _name, _destroyedRespawnDelay, _abandonedRespawnDelay, _init] call INS_veh_addVehtoArray;
					};
				};
			} forEach vehicleArray;

			sleep 1;
		};
	} else { // called script to add vehicle to loop
		_attrs = _this;
		_attrs call INS_veh_addVehtoArray;
	};
};
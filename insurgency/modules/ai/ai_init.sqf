/* INS_fnc_initAIUnit
 * args: unit
 * sets up an AI unit */
INS_fnc_initAIUnit = {
	private ["_unit"];
	_unit = _this;
	
	_unit setSkill ["aimingAccuracy", 0.2];
	_unit setSkill ["aimingShake", 0.5];
	_unit setSkill ["aimingSpeed", 0.2];
	_unit setSkill ["spotDistance", 0.4];
	_unit setSkill ["spotTime", 0.4];
	_unit setSkill ["courage", 0.5];
	_unit setSkill ["reloadSpeed", 0.5];
	_unit setSkill ["commanding", 0.5];
	_unit setSkill ["general", 0.5];

	if (side _unit == east) then { _unit addEventHandler ["Killed", INS_fnc_onDeathListener]; }
};

/* INS_fnc_onDeathListener
 * args: [unit]
 * spawns an intel item at the unit's position INS_prodOfDrop% of the time */
INS_fnc_onDeathListener = {
	_tempRandom = random 100;

	if (_tempRandom > (100 - 100) || true) then {
		_unit = _this select 0;
		_pos = position _unit;
		_intel = createVehicle ["Land_Suitcase_F", _pos, [], 0, "CAN_COLLIDE"];
		_intel setVariable ["INTEL_STRENGTH", (rank _unit) call INS_fnc_getRankModifier];

		[_intel] spawn {
			_listen = true;
			_intel = _this select 0;
			_pos = getPos _intel;

			_timeSlept = 0;
			while { _listen } do {
				sleep 0.5;
				_timeSlept = _timeSlept + 0.5;

				//if (_timeSlept > INS_intelTimeout) then { deleteVehicle _intel; _listen = false; };

				_nearUnits = _pos nearEntities [["Man", "Car"], 2];

				{
					if (side _x == west) then {
						["New Intel", "New intel received on the location of an ammo cache. A marker has been added to the map.", true, true] call dl_fnc_hintMP;
						//[_intel, "INS_fnc_createIntel", false, false] spawn BIS_fnc_MP;
						deleteVehicle _intel;
						_listen = false;
					}; 
				} forEach _nearUnits;	
			};
		};	
	};
};


_unit = _this select 0;

if (!isPlayer _unit) then { _unit call INS_fnc_initAIUnit; }
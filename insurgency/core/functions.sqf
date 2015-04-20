// ---------------------------------------
//	helper functions
// ---------------------------------------

dl_fnc_addEventHandlerMPHelper = {
	_object = _this select 0;
	_type = _this select 1;
	_action = _this select 2;

	_object addEventHandler [_type, _action];
};

dl_fnc_addEventHandlerMP = {
	_object = _this select 0;
	_type = _this select 1;
	_action = _this select 2;

	[[_object, _type, _action], "dl_fnc_addEventHandlerMPHelper", true, true] spawn BIS_fnc_MP;
};

dl_fnc_addActionMPHelper = {
	private ["_object", "_title", "_script", "_args", "_showInWindow", "_hideOnUse", "_condition"];

	_object = _this select 0;
	_title = _this select 1;
	_script = _this select 2;
	_args = _this select 3;
	_showInWindow = _this select 4;
	_hideOnUse = _this select 5;
	_condition = _this select 6;

	_object addAction [_title, _script, _args, 1, _showInWindow, _hideOnUse, "", _condition];
};

dl_fnc_addActionMP = {
	private ["_object", "_title", "_script", "_args", "_showInWindow", "_hideOnUse", "_condition"];

	_object = _this select 0;
	_title = _this select 1;
	_script = _this select 2;
	_args = _this select 3;
	_showInWindow = _this select 4;
	_hideOnUse = _this select 5;
	_condition = _this select 6;

	[[_object, _title, _script, _args, _showInWindow, _hideOnUse, _condition], "dl_fnc_addActionMPHelper", true, true] spawn BIS_fnc_MP;
};

dl_fnc_hintMP = {
	_title = _this select 0; 
	_body = _this select 1;
	_obj = _this select 2;
	_jip = _this select 3;

	_message = if (!isNil "_title") then { format["<t align='center' color='#ff6347' shadow='2' size='1.75'>%1</t><br/><t align='center' color='#ff6347'>------------------------------</t><br/><t size='1.0'>%2</t>", _title, _body] } else { _body };
	[_message, "dl_fnc_hintMPHelper", _obj, _jip] spawn BIS_fnc_MP;
};

dl_fnc_hintMPHelper = {
	hint parseText _this;
};

dl_fnc_titleTextMP = {
	_message = _this select 0;
	_obj = _this select 1;
	_jip = _this select 2;

	[_message, "dl_fnc_titleTextMPHelper", _obj, _jip] spawn BIS_fnc_MP;
};

dl_fnc_titleTextMPHelper = {
	[parseText _this, 0, 1, 5, 0, 0, 301] spawn bis_fnc_dynamicText;
};

dl_fnc_getCityNameFromPath = {
	_path = _this;
    _array = toArray _path;

    _cityName = [];
    _break = false;
    for "_i" from (count _array - 1) to 0 step -1 do {
        if ((_array select _i) != 47) then { _cityName = [(_array select _i)] + _cityName; }
        else { _break = true; };

        if (_break) exitWith {};
    };

    toString _cityName;
};

dl_fnc_velocityToSpeed = {
	_vel = _this;
	_dx = _vel select 0;
	_dy = _vel select 1;
	_dz = _vel select 2;

	_speed = sqrt (_dx * _dx + _dy * _dy + _dz * _dz);
	_speed
};

dl_fnc_canSee = {
	private ["_unit","_obj","_dirTo","_uDir","_vcl","_arc"];
	_unit  = _this select 0;
	_obj   = _this select 1;
	_arc   = _this select 2;
	
	_dirTo = [_unit, _obj] call dl_fnc_dirTo; // vector from _unit to _obj
	_uDir  = direction (vehicle _unit); // heading of _unit
	if (vehicle _unit != _unit) then {
		_vcl = vehicle _unit;
		if (_vcl turretUnit [0] == _unit) then {
			_uDir = _vcl weaponDirection (_vcl weaponsTurret [0] select 0);
			_uDir = (_uDir select 0) atan2 (_uDir select 1);
		};
	};

	if (abs(_dirTo - _uDir) > 180) then { _uDir = -1 * (360 - _uDir); };
	abs(_dirTo - _uDir) <= _arc
};

dl_fnc_canBeSeen = {
	private ["_arc","_pos","_arr","_rng","_unit","_canSee"];
	_unit = _this select 0;
	_arc = _this select 1;
    
	_canSee = false;
	{ if (alive _x and {[_x, _unit, _arc] call dl_fnc_canSee}) exitWith { _canSee = true; }; } forEach playableUnits;

	_canSee
};

dl_fnc_dirTo = {
	_to = _this select 0;
	_from = _this select 1;

	_dirTo = ((getPosATL _from select 0) - (getPosATL _to select 0)) atan2 ((getPosATL _from select 1) - (getPosATL _to select 1));
	_dirTo
};

dl_fnc_countNearestPlayers = {
	_pos = _this select 0; 
	_range = _this select 1; 

	_count = { _x distance _pos < _range; } count playableUnits;
	_count
};

SL_fnc_urbanAreas = {
	private ["_locations", "_cityTypes", "_randomLoc", "_x", "_i", "_cities"];
	_i = 0;
	_cities = [];

	_locations = configfile >> "CfgWorlds" >> worldName >> "Names";
	_cityTypes = ["NameVillage", "NameCity", "NameCityCapital", "NameLocal"];

	for "_x" from 0 to (count _locations - 1) do {
		private["_cityName", "_cityPos", "_cityRadA", "_cityRadB", "_cityType", "_cityAngle"];
		_cityClassName = _locations select _x;
		_cityName = getText(_cityClassName >> "name");
		_cityPos = getArray(_cityClassName >> "position");
		_cityRadA = getNumber(_cityClassName >> "radiusA");
		_cityRadB = getNumber(_cityClassName >> "radiusB");
		_cityType = getText(_cityClassName >> "type");
		_cityAngle = getNumber(_cityClassName >> "angle");
		if (_cityType in _cityTypes) then {
			_cities set [_i, [((str _cityClassName) call dl_fnc_getCityNameFromPath), ((str _cityClassName) call dl_fnc_getCityNameFromPath), _cityPos, _cityRadA, _cityRadB, _cityType, _cityAngle]];
			_i = _i + 1;
		};
	};
	
	_cities
};

dl_houses_illegal = ["Land_HighVoltageColumn_F", 
					 "Land_HighVoltageColumnWire_F", 
					 "Land_LampDecor_F", 
					 "Land_spp_Transformer_F", 
					 "Land_LampShabby_F", 
					 "Land_LampHarbour_F",
					 "Land_LampHalogen_F", 
					 "Land_Kiosk_blueking_F", 
					 "Land_Carousel_01_F", 
					 "Land_TBox_F", 
					 "Land_Crane_F", 
					 "Land_Kiosk_redburger_F", 
					 "Land_Pier_addon", 
					 "Land_nav_pier_m_F", 
					 "Land_Pier_Box_F"];

// todo: make faster
dl_fnc_createMarkers = {
	private ["_center", "_radius", "_buildings"];
	_timeStart = time;
	_buildings = nearestObjects [[15000, 15000, 0] , ["house"], 15000];

	{
		if (!(typeOf _x in dl_houses_illegal)) then { (position _x) call dl_fnc_addGridMarkerIfNotAlready;  }; 
	} forEach _buildings;

	diag_log format["done creating markers in %1 seconds", time - _timeStart];
};

// todo: figure out a better way to do "reclaims"
dl_fnc_createTriggers = {
	private ["_markers", "_pos", "_trigger"];

	{
		_pos = getMarkerPos _x;
		_trigger = createTrigger ["EmptyDetector", _pos];
		_trigger setTriggerActivation ["ANY", "PRESENT", true];
		_trigger setTriggerArea [50, 50, 0, true];
		_trigger setTriggerStatements ["{(side _x) == east} count thisList == 0 AND {(((side _x) == west) and (isPlayer _x)) } count thisList >= 1", format["""%1"" setMarkerColor ""ColorGreen"";", _x], ""];
	} foreach _this;
};

// ---------------------------------------
//	position functions
// ---------------------------------------

dl_fnc_gridPos = {
	_pos = _this;

	_x = _pos select 0;
 	_y = _pos select 1;
 	_x = _x - (_x % 100);
 	_y = _y - (_y % 100);
 	_mpos = [_x + 50, _y + 50, 0];

 	_mpos
};

dl_fnc_findBuildings = {
	_center = _this select 0; 
	_radius = _this select 1; 

	_buildings = nearestObjects [_center , ["house"], _radius];
	_buildings
};

getCountBuildingPositions = {		
	private ["_building", "_count"];
	
	_building = _this select 0;
	_count = 0;
	
	while {str(_building buildingPos _count) != "[0,0,0]"} do {
		_count = _count + 1;
	};
	
	_count
};

getRandomBuildingPosition = {		
	private ["_building", "_count", "_position"];
	
	_building = _this select 0;
	_count = [_building] call getCountBuildingPositions;
	
	if(_count == 0) then {
		_position = getPos _building;
	} else {
		_position = random _count;
		_position = _building buildingPos _position;
	};
	
	if((_position select 0) == 0) then {
		_position = getPos _building;
	};
	
	_position
};

getSideOfRoadPosition = {		
	private ["_target", "_radius", "_roads", "_road", "_position"];
	
	_target = _this select 0;
	_radius = if(count _this > 1) then { _this select 1 } else { 100 };
	_roads = _target nearRoads _radius;
		
	if(count _roads > 1) then {
		_road = getPos (_roads select (random((count _roads)-1)));
		_position = [(_road select 0) + 6, _road select 1, _road select 2];
	} else {
		_position = _target;
	};
	
	_position
};

// ---------------------------------------
//	intel functions
// ---------------------------------------

INS_fnc_intelPickup = {
    private ["_intelItems", "_intel", "_used", "_aid", "_cases", "_case", "_cache"];
	
	_intel = _this select 0;
	_used = _this select 1;
	_aid = _this select 2;

	_intel removeAction _aid;
	deleteVehicle _intel;
	
	_cache = cache;
	if (isNil "_cache") exitWith {};

	["New intel received on the location of an ammo cache. A marker has been added to the map.", true, true] call dl_fnc_hintMP;
	[_cache, "INS_fnc_createIntel", false, false] spawn BIS_fnc_MP; // server only
};

INS_fnc_createIntel = { 
    private ["_i", "_sign", "_sign2", "_radius", "_cache", "_pos", "_mkr", "_range", "_intelRadius"];
    
    _cache = cache;
    _intel = _this;
    _strength = _intel getVariable "INTEL_STRENGTH";
	if (!isNil "_strength") then { _intelRadius = 500 - ((_strength + 1) * 25); }
	else { _intelRadius = 500; };
    _i = 0; 
	
	while { (getMarkerPos format["%1intel%2", _cache, _i] select 0) != 0} do { _i = _i + 1; }; 	
	_sign = 1; 
	
	if (random 100 > 50) then { _sign = -1; };
	_sign2 = 1;
	
	if (random 100 > 50) then { _sign2 = -1; };
	_radius = _intelRadius - _i * 50;
	if (_radius < 50) then { _radius = 50; };
	
	_pos = [(getPosATL _cache select 0) + _sign * (random _radius), (getPosATL _cache select 1) + _sign2 * (random _radius)];
	_mkr = createMarker[format["%1intel%2", _cache, _i], _pos]; 
	_mkr setMarkerType "hd_unknown";
	_range = round sqrt(_radius ^ 2 * 2);
	_range = _range - (_range % 25);
	_mkr setMarkerText format["%1m", _range];
	_mkr setMarkerColor "ColorRed"; 	
	_mkr setMarkerSize [0.5, 0.5];

	INS_marker_array = INS_marker_array + [_mkr];
};

INS_fnc_getRankModifier = {
	_rank = _this;
	_unitRanks = ["PRIVATE", "CORPORAL", "SERGEANT", "LIEUTENANT", "CAPTAIN", "MAJOR", "COLONEL"];

	for "_i" from 0 to count _unitRanks - 1 do { if (_rank == (_unitRanks select _i)) exitWith { _rank = _i }; };

	_rank
};

// ---------------------------------------
//	marker functions
// ---------------------------------------

dl_fnc_addGridMarkerForPosition = {
	private ["_mkr", "_pos"];
	_pos = _this;

	_mkr = str _pos;
	_mkr = createMarkerLocal[_mkr, _pos];
	_mkr setMarkerShapeLocal "RECTANGLE";
	_mkr setMarkerTypeLocal "SOLID";
	_mkr setMarkerSizeLocal [50, 50];
	_mkr setMarkerColor "ColorRed";
	_mkr setMarkerAlphaLocal 0.5;
	[_mkr] call dl_fnc_createTriggers;

	_mkr
};

dl_fnc_addGridMarkerIfNotAlready = {
	private ["_mkr", "_pos"];
	_pos = _this call dl_fnc_gridPos;

	_mkr = str _pos;
	if (getMarkerPos _mkr select 0 == 0) then { _mkr = _pos call dl_fnc_addGridMarkerForPosition } else { _mkr = "" };

	_mkr
};
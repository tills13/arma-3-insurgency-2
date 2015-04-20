doSetLeaderMP = {
	_group = _this select 0;
	_player = _this select 1;

	_group selectLeader _player;
};

INS_groups_fnc_joinGroup = {
	[player] join cursorTarget;
	hint parseText format ["Joined group <t color='#6775cf'>%1</t>", group player];
	[nil, player] call INS_groups_fnc_removeActions;
};

INS_groups_fnc_dismissAI = {
	(group player) call dl_fnc_dismissAIFromGroup;
	hint parseText format ["Dismissed AI in group <t color='#6775cf'>%1</t>", group player];
	[nil, player] call INS_groups_fnc_removeActions;
};

INS_groups_fnc_leaveGroup = {
	_cGroup = group player;
	if (leader group player == player) then {
		_curGroup = [];
		_curGroup = units group player;
		_newLead = player;

		while {_newLead == player} do { _newLead = _curGroup select (floor(random(count _curGroup))); sleep 1.0; };
		(group player) selectLeader _newLead;
	};

	[player] join grpNull;
	hint parseText format ["Left group <t color='#6775cf'>%1</t>", _cGroup];
	[nil, player] call INS_groups_fnc_removeActions;
};

INS_groups_fnc_leadGroup = {
	[[group player, player], "doSetLeaderMP", group player] spawn BIS_fnc_MP;
	hint parseText format ["Leading group <t color='#6775cf'>%1</t>", group player];
	[nil, player] call INS_groups_fnc_removeActions;	
};

INS_groups_fnc_quitLead = {
	_curGroup = [];
	_curGroup = units group player;
	_newLead = player;

	while {_newLead == player} do { _newLead = _curGroup select (floor(random(count _curGroup))); sleep 1.0; };

	(group player) selectLeader _newLead;
	hint parseText format ["No longer leading <t color='#6775cf'>%1</t>", group player];
	[nil, player] call INS_groups_fnc_removeActions;	
};

INS_groups_fnc_removeActions = {
	player removeAction INS_groups_title;
	player removeAction INS_groups_joinGroup;
	player removeAction INS_groups_dismissAI;
	player removeAction INS_groups_leaveGroup;
	player removeAction INS_groups_leadGroup;
	player removeAction INS_groups_quitLead;
	
	player removeAction INS_groups_requestLead;
	player removeAction INS_groups_leadAccept;
	player removeAction INS_groups_leadDecline;
	player removeAction INS_groups_exitMenu;

	INS_groups_groupActions = player addAction["<t color='#6775cf'>Groups Menu</t>", INS_groups_fnc_addActions, nil, 1.05, false, false, "", "_target == vehicle _this || _target == _this"];
};

INS_groups_fnc_addActions = {
	player removeAction INS_groups_groupActions;

	INS_groups_title = player addAction["<t color='#6775cf'>Group Options:</t>", "", nil, 1.05, false, false];
	INS_groups_joinGroup = player addAction["  Join Group", INS_groups_fnc_joinGroup, nil, 1.05, false, false, "", "(cursorTarget distance _this) < 20 && side cursorTarget == side _this && !(group player == group cursorTarget)"];
	INS_groups_dismissAI = player addAction["  Dismiss AI", INS_groups_fnc_dismissAI, nil, 1.05, false, false, "", "count ((group _this) call dl_fnc_getAIinGroup) != 0 && (leader group _this == _this)"];
	INS_groups_leaveGroup = player addAction["  Leave Group", INS_groups_fnc_leaveGroup, nil, 1.05, false, false, "", "(count units group _this) > 1"];
	INS_groups_leadGroup = player addAction["  Become Group Lead", INS_groups_fnc_leadGroup, nil, 1.05, false, false, "", "(count units group _this) > 1 && leader group _this != _this && !(isPlayer leader group _this)"];
	INS_groups_requestLead = player addAction["  Request Group Lead", {
		call compile format ["INS_GROUP_REQUEST_%1 = [true, '%2']", name leader group player, name player];
		publicVariable format["INS_GROUP_REQUEST_%1", name leader group player];

		format["INS_GROUP_REQUEST_RESPONSE_%1", name leader group player] addPublicVariableEventHandler {
			_response = _this select 1;	
			hint str _response;
			if (_response) then { 
				[[group player, player], "doSetLeaderMP", group player] spawn BIS_fnc_MP;
				hint parseText format ["Leading group <t color='#6775cf'>%1</t>", group player];
			};
		};

		call INS_groups_fnc_removeActions;
	}, nil, 1.05, false, false, "", "(count units group _this) > 1 && leader group _this != _this && isPlayer leader group _this"];
	INS_groups_leadAccept = player addAction["  Accept Leadership Request", {
		call compile format ["INS_GROUP_REQUEST_%1 = [false, '%1']", name player];
		call compile format ["INS_GROUP_REQUEST_RESPONSE_%1 = true", name player];
		publicVariable format["INS_GROUP_REQUEST_%1", name player];
		publicVariable format["INS_GROUP_REQUEST_RESPONSE_%1", name player];
		call INS_groups_fnc_removeActions;
	}, nil, 1.05, false, false, "", format["if (isNil 'INS_GROUP_REQUEST_%1') then {false} else {(INS_GROUP_REQUEST_%1 select 0)};", name player]];
	INS_groups_leadDecline = player addAction["  Deny Leadership Request", {
		call compile format ["INS_GROUP_REQUEST_%1 = [false, '%1']", name player];
		call compile format ["INS_GROUP_REQUEST_RESPONSE_%1 = false", name player];
		publicVariable format["INS_GROUP_REQUEST_%1", name player];
		publicVariable format["INS_GROUP_REQUEST_RESPONSE_%1", name player];
		call INS_groups_fnc_removeActions;
	}, nil, 1.05, false, false, "", format["if (isNil 'INS_GROUP_REQUEST_%1') then {false} else {(INS_GROUP_REQUEST_%1 select 0)};", name player]];
	INS_groups_quitLead = player addAction["  Step Down as Group Lead", INS_groups_fnc_quitLead, nil, 1.05, false, false, "", "(count units group _this) > 1 && leader group _this == _this"];
	INS_groups_exitMenu = player addAction["  <t color='#ff6347'>Exit Groups Menu</t>", INS_groups_fnc_removeActions, nil, -1.04, false, true];	
};

if (!isNull player) then {
    INS_groups_groupActions = player addAction["<t color='#6775cf'>Groups Menu</t>", INS_groups_fnc_addActions, nil, 1.05, false, false, "", "_target == vehicle _this || _target == _this"];
    
    player addEventHandler ["Respawn", {
        INS_groups_groupActions = player addAction["<t color='#6775cf'>Groups Menu</t>", INS_groups_fnc_addActions, nil, 1.05, false, false, "", "_target == vehicle _this || _target == _this"];
    }];

    format["INS_GROUP_REQUEST_%1", name player] addPublicVariableEventHandler {
    	if ((_this select 1) select 0) then { hint parseText format ["Group lead request from <t color='#6775cf'>%1</t>", (_this select 1) select 1]; };
	};
};
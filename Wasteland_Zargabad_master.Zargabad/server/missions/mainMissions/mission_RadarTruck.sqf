//	@file Version: 1.0
//	@file Name: mission_RadarTruck.sqf
//	@file Author: [404] Deadbeat, [404] Costlyy
//	@file Created: 08/12/2012 15:19
//	@file Args:

#include "mainMissionDefines.sqf";

if(!isServer) exitwith {};
diag_log format["WASTELAND SERVER - Mission Started"];
private ["_result","_missionType","_GotLoc","_randomIndex","_selectedMarker","_randomPos","_hint","_startTime","_currTime","_playerPresent","_unitsAlive","_veh","_tank","_picture","_vehicleName"];

//Mission Initialization.
_result = 0;
_missionType = "Mobile Radar Station";
_GotLoc = false;

while {!_GotLoc} do 
{
	_randomIndex = random (count MissionSpawnMarkers - 1);

	//If the index of the mission markers array is false then break the loop and finish up doing the mission
	if (!((MissionSpawnMarkers select _randomIndex) select 1)) then 
	{
		_selectedMarker = MissionSpawnMarkers select _randomIndex select 0;
		_randomPos = getMarkerPos _selectedMarker;
		MissionSpawnMarkers select _randomIndex set[1, true];
		_GotLoc = true;
	};
};
waitUntil {_GotLoc};

_hint = parseText format ["<t align='center' color='%2' shadow='2' size='1.75'>Main Objective</t><br/><t align='center' color='%2'>------------------------------</t><br/><t color='%3' size='1.0'>Starting in %1 Minutes</t>", mainMissionDelayTime / 60, mainMissionColor, subTextColor];
[nil,nil,rHINT,_hint] call RE;

diag_log format["WASTELAND SERVER - Mission Waiting to run"];
_startTime = floor(time);
waitUntil
{ 
    _currTime = floor(time);
    if(_currTime - _startTime >= mainMissionDelayTime) then {_result = 1;};
    (_result == 1)
};
diag_log format["WASTELAND SERVER - Mission Resumed"];
_result = 0;

clientMissionMarkers set [count clientMissionMarkers,["Radar_Marker",_randomPos,"Mobile Radar Station"]];
publicVariable "clientMissionMarkers";

_veh = "M1133_MEV_EP1";

_tank = createVehicle [_veh,[(_randomPos select 0), _randomPos select 1,0],[], 0, "NONE"];
_tank setFuel 0.5;
_tank setVehicleAmmo 1;
_tank setDamage 0.75;

_tank setVehicleLock "LOCKED";
_tank setVariable["original",1,true];
_tank setVariable ["R3F_LOG_disabled", true, true];

_picture = getText (configFile >> "cfgVehicles" >> typeOf _tank >> "picture");
_vehicleName = getText (configFile >> "cfgVehicles" >> typeOf _tank >> "displayName");
_hint = parseText format ["<t align='center' color='%4' shadow='2' size='1.75'>Main Objective</t><br/><t align='center' color='%4'>------------------------------</t><br/><t align='center' color='%5' size='1.25'>%1</t><br/><t align='center'><img size='5' image='%2'/></t><br/><t align='center' color='%5'>A<t color='%4'> %3</t> Mobile Radar Vehicle has been immobilized. Sieze it before your enemies do!</t>", _missionType, _picture, _vehicleName, mainMissionColor, subTextColor];
[nil,nil,rHINT,_hint] call RE;

CivGrpM = createGroup civilian;
[CivGrpM,_randomPos]execVM "server\missions\createUnits\largeGroup.sqf";

diag_log format["WASTELAND SERVER - Mission Waiting to be Finished"];
_startTime = floor(time);
waitUntil
{
    sleep 1; 
	_playerPresent = false;
    _currTime = floor(time);
    if(_currTime - _startTime >= mainMissionTimeout) then {_result = 1;};
    {if((isPlayer _x) AND (_x distance _tank <= missionRadiusTrigger)) then {_playerPresent = true};}forEach playableUnits;
    _unitsAlive = ({alive _x} count units CivGrpM);
    (_result == 1) OR ((_playerPresent) AND (_unitsAlive < 1)) OR ((damage _tank) == 1)
};

_tank setVehicleLock "UNLOCKED";
_tank setVariable ["R3F_LOG_disabled", false, true];

if(_result == 1) then
{
	//Mission Failed.
    deleteVehicle _tank;
    {deleteVehicle _x;}forEach units CivGrpM;
    deleteGroup CivGrpM;
    _hint = parseText format ["<t align='center' color='%4' shadow='2' size='1.75'>Objective Failed</t><br/><t align='center' color='%4'>------------------------------</t><br/><t align='center' color='%5' size='1.25'>%1</t><br/><t align='center'><img size='5' image='%2'/></t><br/><t align='center' color='%5'>Objective failed, better luck next time</t>", _missionType, _picture, _vehicleName, failMissionColor, subTextColor];
	[nil,nil,rHINT,_hint] call RE;
    diag_log format["WASTELAND SERVER - Mission Failed"];
} else {
	//Mission Complete.
    deleteGroup CivGrpM;
    _hint = parseText format ["<t align='center' color='%4' shadow='2' size='1.75'>Objective Complete</t><br/><t align='center' color='%4'>------------------------------</t><br/><t align='center' color='%5' size='1.25'>%1</t><br/><t align='center'><img size='5' image='%2'/></t><br/><t align='center' color='%5'>The Radar Truck has been captured, now go hunt the enemy!</t>", _missionType, _picture, _vehicleName, successMissionColor, subTextColor];
	[nil,nil,rHINT,_hint] call RE;
    diag_log format["WASTELAND SERVER - Mission Finished"];
    _tank setVariable ["deployed", 0, true];    
};

//Reset Mission Spot.
MissionSpawnMarkers select _randomIndex set[1, false]; 

//Remove marker from client marker array.
{
    if(_x select 0 == "Radar_Marker") then
    {
    	clientMissionMarkers set [_forEachIndex, "REMOVETHISCRAP"];
		clientMissionMarkers = clientMissionMarkers - ["REMOVETHISCRAP"];
        publicVariable "clientMissionMarkers";    
    };
}forEach clientMissionMarkers;
mainMissionRunning = false;
extends RefCounted
## Immutable content consumed by the existing walkthrough, not another manager.
const VERSION := 1
const CREW := ["Maya Chen (CDR)", "Elias Ward (PLT)", "Amara Okoye (MED)", "Leila Haddad (ENG)", "Mateo Ruiz (MIN)"]
const OBJECTIVES := [
	["crew", "Verify the duty roster", "CREW QUARTERS", "Check-in"],
	["cargo", "Inspect and secure the cargo", "CARGO BAY", "Inspection"],
	["power", "Diagnose and restore distribution", "POWER", "Distribution"],
	["life", "Service and verify life support", "LIFE SUPPORT", "Air service"],
	["hydro", "Restore nutrient delivery", "HYDROPONICS", "Nutrients"],
	["engine", "Diagnose and verify cooling", "ENGINES", "Cooling"],
	["navigation", "Compare and correct flight readings", "BRIDGE", "Flight check"],
	["communications", "Transmit the verified duty report", "BRIDGE", "Duty report"],
]
const OBJECTIVE_STATIONS := {
	"crew":"quarters.desk", "cargo":"cargo.scale", "power":"power.breaker",
	"life":"life.filter", "hydro":"hydro.console", "engine":"engine.pump.1",
	"navigation":"bridge.helm", "communications":"bridge.comms.upper",
}
const AREAS := {
	"bridge": Rect2(60,195,310,300), "quarters": Rect2(275,445,390,225),
	"cargo": Rect2(690,400,535,270), "engine": Rect2(1338,205,290,355),
	"power": Rect2(1050,255,162,140), "life": Rect2(1215,190,160,215),
	"hydro": Rect2(15,605,600,245), "shuttle": Rect2(1190,495,190,215),
}
# path, stable instance ID, room, function, preferred access side (never a sprite rotation).
const PROPS := [
	["BridgeRoomProps/MissionPlanningTable", "bridge.planning", "bridge", "planning", Vector2.DOWN],
	["BridgeRoomProps/MainHelmConsole", "bridge.helm", "bridge", "navigation", Vector2.RIGHT],
	["BridgeRoomProps/UpperFlightControlStation", "bridge.comms.upper", "bridge", "communications", Vector2.DOWN],
	["BridgeRoomProps/LowerFlightControlStation", "bridge.comms.lower", "bridge", "communications", Vector2.UP],
	["BridgeRoomProps/UpperBowFlightConsole", "bridge.flight.upper", "bridge", "navigation", Vector2.DOWN],
	["BridgeRoomProps/LowerBowFlightConsole", "bridge.flight.lower", "bridge", "navigation", Vector2.UP],
	["BridgeRoomProps/UpperStationChair", "bridge.chair.upper", "bridge", "chair", Vector2.RIGHT],
	["BridgeRoomProps/MainHelmChair", "bridge.chair.helm", "bridge", "chair", Vector2.RIGHT],
	["BridgeRoomProps/LowerStationChair", "bridge.chair.lower", "bridge", "chair", Vector2.RIGHT],
	["CrewLivingQuarterProps/PersonalComputerDesk", "quarters.desk", "quarters", "crew", Vector2.DOWN],
	["CrewLivingQuarterProps/CommunalTable", "quarters.table", "quarters", "crew", Vector2.LEFT],
	["CrewLivingQuarterProps/StorageCabinet02", "quarters.wardrobe", "quarters", "storage", Vector2.DOWN],
	["CrewLivingQuarterProps/ThreeDrawerChest", "quarters.drawer.1", "quarters", "storage", Vector2.DOWN],
	["CrewLivingQuarterProps/ThreeDrawerChest02", "quarters.drawer.2", "quarters", "storage", Vector2.DOWN],
	["CrewLivingQuarterProps/StackedCapsuleUnit", "quarters.bed.1", "quarters", "rest", Vector2.DOWN],
	["CrewLivingQuarterProps/StackedCapsuleUnit02", "quarters.bed.2", "quarters", "rest", Vector2.DOWN],
	["CrewLivingQuarterProps/StackedCapsuleUnit03", "quarters.bed.3", "quarters", "rest", Vector2.DOWN],
	["CrewLivingQuarterProps/DeskChair", "quarters.chair.desk", "quarters", "chair", Vector2.DOWN],
	["CrewLivingQuarterProps/TableChairNorth", "quarters.chair.north", "quarters", "chair", Vector2.RIGHT],
	["CrewLivingQuarterProps/TableChairSouth", "quarters.chair.south", "quarters", "chair", Vector2.RIGHT],
	["CrewLivingQuarterProps/TableChairWest", "quarters.chair.west", "quarters", "chair", Vector2.LEFT],
	["CrewLivingQuarterProps/TableChairEast", "quarters.chair.east", "quarters", "chair", Vector2.RIGHT],
	["CargoBayProps/ElectricPalletMover", "cargo.mover", "cargo", "transfer", Vector2.RIGHT],
	["CargoBayProps/CargoInspectionScale", "cargo.scale", "cargo", "cargo", Vector2.DOWN],
	["CargoBayProps/SecuredCylinderRack", "cargo.cylinders", "cargo", "cylinders", Vector2.DOWN],
	["CargoBayProps/MaintenanceTrolley", "cargo.trolley", "cargo", "transfer", Vector2.UP],
	["CargoBayProps/CargoLocker", "cargo.locker", "cargo", "storage_hide", Vector2.LEFT],
	["CargoBayProps/TiedBoxBundle", "cargo.bundle", "cargo", "cargo_hide", Vector2.DOWN],
	["EngineRoomProps/TurbineUpper", "engine.turbine.1", "engine", "turbine", Vector2.RIGHT],
	["EngineRoomProps/TurbineLower", "engine.turbine.2", "engine", "turbine", Vector2.RIGHT],
	["EngineRoomProps/TurbineMiddleWest", "engine.turbine.3", "engine", "turbine", Vector2.RIGHT],
	["EngineRoomProps/TurbineMiddleEast", "engine.turbine.4", "engine", "turbine", Vector2.RIGHT],
	["EngineRoomProps/CoolantPumpUpper", "engine.pump.1", "engine", "engine", Vector2.DOWN],
	["EngineRoomProps/CoolantPumpLower", "engine.pump.2", "engine", "engine", Vector2.DOWN],
	["EngineRoomProps/ValveManifoldUpper", "engine.valve.1", "engine", "engine_valve", Vector2.DOWN],
	["EngineRoomProps/ValveManifoldLower", "engine.valve.2", "engine", "engine_valve", Vector2.DOWN],
	["EngineRoomProps/LockerUpper", "engine.locker.1", "engine", "storage_hide", Vector2.LEFT],
	["EngineRoomProps/LockerLower", "engine.locker.2", "engine", "storage_hide", Vector2.LEFT],
	["PowerMaintenanceRoomProps/BreakerCabinet", "power.breaker", "power", "power", Vector2.DOWN],
	["PowerMaintenanceRoomProps/PowerConverterAssembly", "power.converter", "power", "power", Vector2.DOWN],
	["PowerMaintenanceRoomProps/PowerCellModule", "power.cell", "power", "power", Vector2.DOWN],
	["LifeSupportRoomProps/OxygenTankRack", "life.oxygen", "life", "life", Vector2.LEFT],
	["LifeSupportRoomProps/AirDuctAssembly", "life.duct", "life", "life", Vector2.RIGHT],
	["LifeSupportRoomProps/AirScrubber", "life.scrubber", "life", "life", Vector2.LEFT],
	["LifeSupportRoomProps/FilterCartridge", "life.filter", "life", "life", Vector2.LEFT],
	["HydroponicsRoomProps/ControlConsole", "hydro.console", "hydro", "hydro", Vector2.RIGHT],
	["HydroponicsRoomProps/NutrientPump", "hydro.pump", "hydro", "hydro", Vector2.RIGHT],
	["HydroponicsRoomProps/GrowTrayNorth", "hydro.tray.north", "hydro", "hydro", Vector2.DOWN],
	["HydroponicsRoomProps/GrowTraySouth", "hydro.tray.south", "hydro", "hydro", Vector2.DOWN],
	["HydroponicsRoomProps/SeedlingRack", "hydro.seedlings", "hydro", "hydro", Vector2.RIGHT],
	["HydroponicsRoomProps/WallHerbShelf", "hydro.herbs", "hydro", "observation", Vector2.DOWN],
	["ShuttleBayCargo", "shuttle.bundle", "shuttle", "storage", Vector2.UP],
]

static func definition(id: String) -> Dictionary:
	for row in PROPS:
		if row[1] == id:
			return {"path":row[0],"id":row[1],"room":row[2],"kind":row[3],"side":row[4]}
	return {}

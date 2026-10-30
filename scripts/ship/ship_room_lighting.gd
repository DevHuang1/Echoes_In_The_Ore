@tool
class_name ShipRoomLighting
extends Node2D

# Unoccupied rooms turn a tiny bit gray with their lights off; occupied rooms return to natural
# indoor brightness with visible wall-mounted bulkhead light fixtures that cast warm directional
# illumination from the walls into each room.
const UNLIT_ROOM_GRAY_TINT := Color(0.18, 0.21, 0.26, 0.28)
const UNLIT_PROP_MODULATE := Color(0.85, 0.87, 0.90, 1.0)
const LIT_PROP_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const EXISTING_LIGHT_ENERGY_SCALE := 0.16
const FADE_SPEED := 5.5

const ROOM_DEFINITIONS: Array[Dictionary] = [
	{
		"id": &"r01_bridge",
		"label": "R01 Bridge",
		"origin": Vector2(110.0, 246.0),
		"size": Vector2(178.0, 205.0),
		"teleport_pos": Vector2(198.0, 346.0),
		"mask_path": "res://art/lighting/room_masks/r01_bridge_mask.png",
		"entry_rects": [
			Rect2(276.0, 310.0, 18.0, 76.0),
		],
		"prop_container_path": NodePath("../BridgeRoomProps"),
		"existing_light_paths": [],
		"wall_lights": [
			{"pos": Vector2(202.0, 258.0), "side": &"top", "length": 22.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(202.0, 444.0), "side": &"bottom", "length": 22.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(114.0, 348.0), "side": &"left", "length": 20.0, "energy": 0.12, "scale": 0.42, "color": Color(0.76, 0.92, 1.0, 1.0)},
			{"pos": Vector2(285.0, 282.0), "side": &"right", "length": 18.0, "energy": 0.11, "scale": 0.38, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(284.0, 410.0), "side": &"right", "length": 18.0, "energy": 0.11, "scale": 0.38, "color": Color(1.0, 0.88, 0.70, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r02_upper_main",
		"label": "R02 Upper Main",
		"origin": Vector2(602.0, 92.0),
		"size": Vector2(516.0, 157.0),
		"teleport_pos": Vector2(860.0, 170.0),
		"mask_path": "res://art/lighting/room_masks/r02_upper_main_mask.png",
		"entry_rects": [
			Rect2(648.0, 240.0, 40.0, 22.0),
			Rect2(1030.0, 240.0, 38.0, 22.0),
		],
		"prop_container_path": NodePath("../MedBayRoomProps"),
		"existing_light_paths": [
			NodePath("../MedBayRoomProps/ExamLighting/PodAreaLight"),
			NodePath("../MedBayRoomProps/ExamLighting/ExamBenchLight"),
			NodePath("../MedBayRoomProps/ExamLighting/SterileStationLight"),
		],
		"wall_lights": [
			{"pos": Vector2(725.0, 103.0), "side": &"top", "length": 26.0, "energy": 0.13, "scale": 0.50, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(860.0, 95.0), "side": &"top", "length": 28.0, "energy": 0.14, "scale": 0.52, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(995.0, 103.0), "side": &"top", "length": 26.0, "energy": 0.13, "scale": 0.50, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(775.0, 244.0), "side": &"bottom", "length": 24.0, "energy": 0.12, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(945.0, 244.0), "side": &"bottom", "length": 24.0, "energy": 0.12, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(606.0, 170.0), "side": &"left", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1113.0, 170.0), "side": &"right", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.86, 0.66, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r03_center_recess",
		"label": "R03 Center Recess",
		"origin": Vector2(752.0, 294.0),
		"size": Vector2(218.0, 67.0),
		"teleport_pos": Vector2(862.0, 330.0),
		"mask_path": "res://art/lighting/room_masks/r03_center_recess_mask.png",
		"entry_rects": [
			Rect2(836.0, 352.0, 52.0, 20.0),
		],
		"prop_container_path": NodePath(""),
		"existing_light_paths": [
			NodePath("../CenterRecessRoom/NorthwestWallSconce"),
			NodePath("../CenterRecessRoom/NortheastWallSconce"),
			NodePath("../CenterRecessRoom/WestWallSconce"),
			NodePath("../CenterRecessRoom/EastWallSconce"),
			NodePath("../CenterRecessRoom/SouthwestWallSconce"),
			NodePath("../CenterRecessRoom/SoutheastWallSconce"),
		],
		"wall_lights": [
			{"pos": Vector2(802.0, 297.0), "side": &"top", "length": 20.0, "energy": 0.10, "scale": 0.36, "color": Color(0.86, 0.82, 1.0, 1.0)},
			{"pos": Vector2(919.0, 297.0), "side": &"top", "length": 20.0, "energy": 0.10, "scale": 0.36, "color": Color(0.86, 0.82, 1.0, 1.0)},
			{"pos": Vector2(755.0, 328.0), "side": &"left", "length": 18.0, "energy": 0.09, "scale": 0.32, "color": Color(1.0, 0.86, 0.68, 1.0)},
			{"pos": Vector2(966.0, 328.0), "side": &"right", "length": 18.0, "energy": 0.09, "scale": 0.32, "color": Color(1.0, 0.86, 0.68, 1.0)},
			{"pos": Vector2(796.0, 356.0), "side": &"bottom", "length": 18.0, "energy": 0.08, "scale": 0.30, "color": Color(1.0, 0.86, 0.68, 1.0)},
			{"pos": Vector2(926.0, 356.0), "side": &"bottom", "length": 18.0, "energy": 0.08, "scale": 0.30, "color": Color(1.0, 0.86, 0.68, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r04_power_maint",
		"label": "R04 Power Maint",
		"origin": Vector2(1095.0, 281.0),
		"size": Vector2(64.0, 78.0),
		"teleport_pos": Vector2(1118.0, 340.0),
		"mask_path": "res://art/lighting/room_masks/r04_power_maint_mask.png",
		"entry_rects": [
			Rect2(1088.0, 276.0, 114.0, 104.0),
		],
		"prop_container_path": NodePath("../PowerMaintenanceRoomProps"),
		"existing_light_paths": [
			NodePath("../PowerMaintenanceRoomProps/BreakerWorklight"),
			NodePath("../PowerMaintenanceRoomProps/ConverterWorklight"),
			NodePath("../PowerMaintenanceRoomProps/PortWallSconce"),
			NodePath("../PowerMaintenanceRoomProps/StarboardWallSconce"),
			NodePath("../PowerMaintenanceRoomProps/LowerWallSconce"),
		],
		"wall_lights": [
			{"pos": Vector2(1127.0, 283.0), "side": &"top", "length": 18.0, "energy": 0.11, "scale": 0.34, "color": Color(1.0, 0.78, 0.48, 1.0)},
			{"pos": Vector2(1097.0, 322.0), "side": &"left", "length": 18.0, "energy": 0.10, "scale": 0.32, "color": Color(1.0, 0.78, 0.48, 1.0)},
			{"pos": Vector2(1155.0, 322.0), "side": &"right", "length": 18.0, "energy": 0.10, "scale": 0.32, "color": Color(1.0, 0.78, 0.48, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r05_life_support",
		"label": "R05 Life Support",
		"origin": Vector2(1252.0, 232.0),
		"size": Vector2(45.0, 127.0),
		"teleport_pos": Vector2(1275.0, 336.0),
		"mask_path": "res://art/lighting/room_masks/r05_life_support_mask.png",
		"entry_rects": [
			Rect2(1194.0, 228.0, 148.0, 150.0),
		],
		"prop_container_path": NodePath("../LifeSupportRoomProps"),
		"existing_light_paths": [
			NodePath("../LifeSupportRoomProps/UpperServiceLight"),
			NodePath("../LifeSupportRoomProps/LowerServiceLight"),
			NodePath("../LifeSupportRoomProps/PortUpperWallSconce"),
			NodePath("../LifeSupportRoomProps/StarboardUpperWallSconce"),
			NodePath("../LifeSupportRoomProps/PortLowerWallSconce"),
			NodePath("../LifeSupportRoomProps/StarboardLowerWallSconce"),
			NodePath("../LifeSupportRoomProps/VentAirflow/VentGlow"),
			NodePath("../LifeSupportRoomProps/VentAirflow/AirflowSpillGlow"),
		],
		"wall_lights": [
			{"pos": Vector2(1274.0, 235.0), "side": &"top", "length": 16.0, "energy": 0.10, "scale": 0.32, "color": Color(0.68, 0.94, 1.0, 1.0)},
			{"pos": Vector2(1255.0, 272.0), "side": &"left", "length": 18.0, "energy": 0.10, "scale": 0.32, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1294.0, 272.0), "side": &"right", "length": 18.0, "energy": 0.10, "scale": 0.32, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1255.0, 326.0), "side": &"left", "length": 18.0, "energy": 0.10, "scale": 0.32, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1294.0, 326.0), "side": &"right", "length": 18.0, "energy": 0.10, "scale": 0.32, "color": Color(1.0, 0.86, 0.66, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r06_engine_room",
		"label": "R06 Engine Room",
		"origin": Vector2(1343.0, 238.0),
		"size": Vector2(259.0, 309.0),
		"teleport_pos": Vector2(1472.0, 390.0),
		"mask_path": "res://art/lighting/room_masks/r06_engine_room_mask.png",
		"entry_rects": [
			Rect2(1336.0, 366.0, 20.0, 50.0),
		],
		"prop_container_path": NodePath(""),
		"existing_light_paths": [],
		"wall_lights": [
			{"pos": Vector2(1425.0, 241.0), "side": &"top", "length": 24.0, "energy": 0.13, "scale": 0.48, "color": Color(1.0, 0.84, 0.60, 1.0)},
			{"pos": Vector2(1505.0, 248.0), "side": &"top", "length": 24.0, "energy": 0.13, "scale": 0.48, "color": Color(1.0, 0.84, 0.60, 1.0)},
			{"pos": Vector2(1425.0, 542.0), "side": &"bottom", "length": 24.0, "energy": 0.13, "scale": 0.48, "color": Color(1.0, 0.84, 0.60, 1.0)},
			{"pos": Vector2(1505.0, 538.0), "side": &"bottom", "length": 24.0, "energy": 0.13, "scale": 0.48, "color": Color(1.0, 0.84, 0.60, 1.0)},
			{"pos": Vector2(1347.0, 312.0), "side": &"left", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.84, 0.60, 1.0)},
			{"pos": Vector2(1347.0, 468.0), "side": &"left", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.84, 0.60, 1.0)},
			{"pos": Vector2(1596.0, 340.0), "side": &"right", "length": 24.0, "energy": 0.14, "scale": 0.48, "color": Color(1.0, 0.78, 0.50, 1.0)},
			{"pos": Vector2(1595.0, 442.0), "side": &"right", "length": 24.0, "energy": 0.14, "scale": 0.48, "color": Color(1.0, 0.78, 0.50, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r07_crew_quarters",
		"label": "R07 Crew Quarters",
		"origin": Vector2(304.0, 438.0),
		"size": Vector2(366.0, 196.0),
		"teleport_pos": Vector2(485.0, 550.0),
		"mask_path": "res://art/lighting/room_masks/r07_crew_quarters_mask.png",
		"entry_rects": [
			Rect2(506.0, 426.0, 34.0, 22.0),
			Rect2(318.0, 626.0, 28.0, 18.0),
			Rect2(506.0, 626.0, 30.0, 18.0),
		],
		"prop_container_path": NodePath("../CrewLivingQuarterProps"),
		"existing_light_paths": [],
		"wall_lights": [
			{"pos": Vector2(395.0, 441.0), "side": &"top", "length": 22.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(582.0, 443.0), "side": &"top", "length": 22.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(420.0, 624.0), "side": &"bottom", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(592.0, 624.0), "side": &"bottom", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(307.0, 502.0), "side": &"left", "length": 20.0, "energy": 0.11, "scale": 0.40, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(307.0, 578.0), "side": &"left", "length": 20.0, "energy": 0.11, "scale": 0.40, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(642.0, 536.0), "side": &"right", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.88, 0.70, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r08_central_bay",
		"label": "R08 Central Bay",
		"origin": Vector2(670.0, 445.0),
		"size": Vector2(494.0, 189.0),
		"teleport_pos": Vector2(960.0, 540.0),
		"mask_path": "res://art/lighting/room_masks/r08_central_bay_mask.png",
		"entry_rects": [
			Rect2(668.0, 434.0, 34.0, 20.0),
			Rect2(852.0, 434.0, 32.0, 20.0),
			Rect2(1098.0, 434.0, 30.0, 20.0),
			Rect2(852.0, 626.0, 32.0, 20.0),
		],
		"prop_container_path": NodePath("../LabRoom"),
		"existing_light_paths": [
			NodePath("../LabRoom/StationLighting/AnalysisGlow"),
			NodePath("../LabRoom/StationLighting/ConsoleGlow"),
			NodePath("../LabRoom/StationLighting/ContainmentGlow"),
			NodePath("../LabRoom/StationLighting/CartWorklight"),
			NodePath("../LabRoom/StationLighting/ArchiveGlowLeft"),
			NodePath("../LabRoom/StationLighting/ArchiveGlowCenter"),
			NodePath("../LabRoom/StationLighting/ArchiveGlowRight"),
		],
		"wall_lights": [
			{"pos": Vector2(802.0, 623.0), "side": &"bottom", "length": 24.0, "energy": 0.12, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(965.0, 624.0), "side": &"bottom", "length": 24.0, "energy": 0.13, "scale": 0.48, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1088.0, 624.0), "side": &"bottom", "length": 24.0, "energy": 0.12, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(763.0, 518.0), "side": &"left", "length": 20.0, "energy": 0.12, "scale": 0.42, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1158.0, 504.0), "side": &"right", "length": 20.0, "energy": 0.12, "scale": 0.42, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1158.0, 586.0), "side": &"right", "length": 20.0, "energy": 0.12, "scale": 0.42, "color": Color(1.0, 0.86, 0.66, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r09_shuttle_bay",
		"label": "R09 Shuttle Bay",
		"origin": Vector2(1213.0, 541.0),
		"size": Vector2(142.0, 133.0),
		"teleport_pos": Vector2(1252.0, 610.0),
		"mask_path": "res://art/lighting/room_masks/r09_shuttle_bay_mask.png",
		"entry_rects": [
			Rect2(1240.0, 526.0, 28.0, 22.0),
		],
		"prop_container_path": NodePath("../ShuttleBayCargo"),
		"existing_light_paths": [],
		"wall_lights": [
			{"pos": Vector2(1305.0, 548.0), "side": &"top", "length": 22.0, "energy": 0.13, "scale": 0.44, "color": Color(1.0, 0.87, 0.68, 1.0)},
			{"pos": Vector2(1284.0, 670.0), "side": &"bottom", "length": 24.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.87, 0.68, 1.0)},
			{"pos": Vector2(1216.0, 607.0), "side": &"left", "length": 22.0, "energy": 0.13, "scale": 0.44, "color": Color(1.0, 0.87, 0.68, 1.0)},
			{"pos": Vector2(1351.0, 607.0), "side": &"right", "length": 22.0, "energy": 0.12, "scale": 0.42, "color": Color(1.0, 0.87, 0.68, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r10_hydroponics_west",
		"label": "R10 Hydroponics Bay",
		"origin": Vector2(99.0, 643.0),
		"size": Vector2(389.0, 178.0),
		"teleport_pos": Vector2(320.0, 746.0),
		"mask_path": "res://art/lighting/room_masks/r10_hydroponics_west_mask.png",
		"entry_rects": [
			Rect2(318.0, 636.0, 28.0, 20.0),
			Rect2(476.0, 720.0, 22.0, 34.0),
		],
		"prop_container_path": NodePath("../HydroponicsRoomProps"),
		"existing_light_paths": [
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/TopLeftWallSconce"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/TopCenterWallSconce"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/NorthGrowTrayLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/SeedlingRackUpperLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/SeedlingRackMiddleLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/SeedlingRackLowerLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/SouthGrowTrayLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/NutrientStationLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/UpperHerbShelfLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/LowerHerbShelfLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/CenterAisleLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/EastEntryLight"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/LowerWallSconce"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/PortWallSconce"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/PortLowerWallSconce"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/StarboardUpperWallSconce"),
			NodePath("../HydroponicsRoomProps/HydroponicsLighting/StarboardLowerWallSconce"),
		],
		"wall_lights": [
			{"pos": Vector2(196.0, 648.0), "side": &"top", "length": 22.0, "energy": 0.11, "scale": 0.38, "color": Color(0.84, 1.0, 0.78, 1.0)},
			{"pos": Vector2(285.0, 648.0), "side": &"top", "length": 22.0, "energy": 0.11, "scale": 0.38, "color": Color(0.84, 1.0, 0.78, 1.0)},
			{"pos": Vector2(410.0, 678.0), "side": &"top", "length": 22.0, "energy": 0.11, "scale": 0.38, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(204.0, 810.0), "side": &"bottom", "length": 22.0, "energy": 0.11, "scale": 0.38, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(340.0, 809.0), "side": &"bottom", "length": 22.0, "energy": 0.11, "scale": 0.38, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(440.0, 808.0), "side": &"bottom", "length": 20.0, "energy": 0.10, "scale": 0.36, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(102.0, 742.0), "side": &"left", "length": 20.0, "energy": 0.10, "scale": 0.36, "color": Color(0.84, 1.0, 0.78, 1.0)},
			{"pos": Vector2(478.0, 696.0), "side": &"right", "length": 18.0, "energy": 0.10, "scale": 0.34, "color": Color(1.0, 0.88, 0.70, 1.0)},
			{"pos": Vector2(478.0, 775.0), "side": &"right", "length": 18.0, "energy": 0.10, "scale": 0.34, "color": Color(1.0, 0.88, 0.70, 1.0)},
		],
		"ceiling_lights": [],
	},
	{
		"id": &"r11_lower_deck_east",
		"label": "R11 Lower Deck East",
		"origin": Vector2(557.0, 662.0),
		"size": Vector2(448.0, 161.0),
		"teleport_pos": Vector2(780.0, 742.0),
		"mask_path": "res://art/lighting/room_masks/r11_lower_deck_east_mask.png",
		"entry_rects": [
			Rect2(546.0, 720.0, 22.0, 34.0),
			Rect2(712.0, 650.0, 36.0, 20.0),
			Rect2(854.0, 650.0, 30.0, 20.0),
		],
		"prop_container_path": NodePath(""),
		"existing_light_paths": [],
		"wall_lights": [
			{"pos": Vector2(635.0, 678.0), "side": &"top", "length": 24.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(790.0, 678.0), "side": &"top", "length": 24.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(935.0, 678.0), "side": &"top", "length": 24.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(660.0, 814.0), "side": &"bottom", "length": 24.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(785.0, 814.0), "side": &"bottom", "length": 24.0, "energy": 0.13, "scale": 0.46, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(910.0, 814.0), "side": &"bottom", "length": 24.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(565.0, 700.0), "side": &"left", "length": 18.0, "energy": 0.11, "scale": 0.38, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(565.0, 782.0), "side": &"left", "length": 18.0, "energy": 0.11, "scale": 0.38, "color": Color(1.0, 0.86, 0.66, 1.0)},
			{"pos": Vector2(1000.0, 742.0), "side": &"right", "length": 22.0, "energy": 0.12, "scale": 0.44, "color": Color(1.0, 0.86, 0.66, 1.0)},
		],
		"ceiling_lights": [],
	},
]

const WARM_LIGHT_SCENE := preload("res://scenes/ship/props/warm_ship_light.tscn")


class WallLightFixture extends Node2D:
	var wall_side: StringName = &"top"
	var bar_length: float = 22.0
	var light_color: Color = Color(1.0, 0.86, 0.66, 1.0)
	var lit_amount: float = 0.0

	func set_lit_amount(value: float) -> void:
		if is_equal_approx(lit_amount, value):
			return
		lit_amount = value
		queue_redraw()

	func _inward_normal() -> Vector2:
		match wall_side:
			&"bottom":
				return Vector2.UP
			&"left":
				return Vector2.RIGHT
			&"right":
				return Vector2.LEFT
			_:
				return Vector2.DOWN

	func _tangent() -> Vector2:
		match wall_side:
			&"left", &"right":
				return Vector2.DOWN
			_:
				return Vector2.RIGHT

	func _draw() -> void:
		# Floor/wall light strip overlays removed per user request; illumination is handled by PointLight2D.
		pass


var _room_states: Array[Dictionary] = []
var flicker_current_room: bool = false
var flicker_all_rooms: bool = false
var force_all_lights_on: bool = false
var emergency_breaker_mode: bool = false
var max_power_units: int = 4
var breaker_powered_rooms: Dictionary = {}
var flicker_rooms: Dictionary = {}
var flicker_style: StringName = &"erratic"
var flicker_speed: float = 1.0
var _flicker_time: float = 0.0
var _current_player_room_id: StringName = &""


func _ready() -> void:
	add_to_group("ship_room_lighting")
	_build_rooms()
	if Engine.is_editor_hint():
		set_process(false)
		return
	set_process(true)
	# Snap initial lighting states on the first frame once Player position is finalized
	_update_all_rooms.call_deferred(1.0, true)


func _build_rooms() -> void:
	for child in get_children():
		child.queue_free()
	_room_states.clear()

	for def in ROOM_DEFINITIONS:
		var origin: Vector2 = def["origin"]
		var size: Vector2 = def["size"]
		var mask_path: String = def["mask_path"]

		var img := Image.load_from_file(ProjectSettings.globalize_path(mask_path))
		var tex: Texture2D = null
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
		elif ResourceLoader.exists(mask_path):
			tex = load(mask_path) as Texture2D
			if tex != null:
				img = tex.get_image()

		# Gray unlit overlay sprite (turns the room a tiny bit gray when unoccupied,
		# and fades completely to 0 when occupied so the room looks naturally lit without white glare)
		var dim_sprite := Sprite2D.new()
		dim_sprite.name = "%s_DimOverlay" % String(def["id"])
		dim_sprite.centered = false
		dim_sprite.position = origin
		dim_sprite.z_index = 1
		dim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dim_sprite.texture = tex
		dim_sprite.modulate = Color(UNLIT_ROOM_GRAY_TINT.r, UNLIT_ROOM_GRAY_TINT.g, UNLIT_ROOM_GRAY_TINT.b, 0.12 if Engine.is_editor_hint() else UNLIT_ROOM_GRAY_TINT.a)
		add_child(dim_sprite)

		# Collect existing PointLight2D nodes in the room (scaled down for the white floor)
		var light_entries: Array[Dictionary] = []
		var existing_paths: Array = def.get("existing_light_paths", [])
		for np in existing_paths:
			var light_node := get_node_or_null(np) as PointLight2D
			if light_node != null:
				var natural_energy := light_node.energy * EXISTING_LIGHT_ENERGY_SCALE
				light_entries.append({
					"node": light_node,
					"base_energy": natural_energy,
				})

		# Build visible wall-mounted light source fixtures along the room's walls
		var wall_fixtures: Array = []
		var wall_defs: Array = def.get("wall_lights", [])
		var editor_lit := 1.0 if Engine.is_editor_hint() else 0.0
		for wdef in wall_defs:
			var wpos: Vector2 = wdef["pos"]
			var wside: StringName = wdef.get("side", &"top")
			var wlen: float = float(wdef.get("length", 22.0))
			var wcol: Color = wdef.get("color", Color(1.0, 0.86, 0.66, 1.0))
			var fixture := WallLightFixture.new()
			fixture.position = wpos
			fixture.z_index = 2
			fixture.wall_side = wside
			fixture.bar_length = wlen
			fixture.light_color = wcol
			fixture.lit_amount = editor_lit
			add_child(fixture)
			wall_fixtures.append(fixture)

			# Pair each wall light fixture with a PointLight2D projecting inward from that wall
			var wlight := WARM_LIGHT_SCENE.instantiate() as PointLight2D
			var inward_offset := fixture._inward_normal() * 14.0
			wlight.position = wpos + inward_offset
			wlight.energy = float(wdef.get("energy", 0.12))
			wlight.texture_scale = float(wdef.get("scale", 0.44))
			wlight.color = wcol
			add_child(wlight)
			light_entries.append({
				"node": wlight,
				"base_energy": wlight.energy,
			})

		var ceiling_defs: Array = def.get("ceiling_lights", [])
		for cdef in ceiling_defs:
			var clight := WARM_LIGHT_SCENE.instantiate() as PointLight2D
			clight.position = cdef["pos"]
			clight.energy = float(cdef.get("energy", 0.14))
			clight.texture_scale = float(cdef.get("scale", 0.6))
			clight.color = cdef.get("color", Color(1.0, 0.86, 0.66, 1.0))
			add_child(clight)
			light_entries.append({
				"node": clight,
				"base_energy": clight.energy,
			})

		var prop_container: CanvasItem = null
		var prop_path: NodePath = def.get("prop_container_path", NodePath(""))
		if not prop_path.is_empty():
			prop_container = get_node_or_null(prop_path) as CanvasItem

		_room_states.append({
			"id": def["id"],
			"label": def.get("label", String(def["id"])),
			"teleport_pos": def.get("teleport_pos", origin + size * 0.5),
			"bbox": Rect2(origin, size),
			"origin": origin,
			"image": img,
			"entry_rects": def.get("entry_rects", []),
			"dim_sprite": dim_sprite,
			"lights": light_entries,
			"wall_fixtures": wall_fixtures,
			"prop_container": prop_container,
			"lit_factor": 0.0,
		})


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_flicker_time = fposmod(_flicker_time + delta * maxf(flicker_speed, 0.1), 1000.0)
	_update_all_rooms(delta, false)


func _update_all_rooms(delta: float, snap_immediately: bool) -> void:
	var parent_node := get_parent() as Node2D
	if parent_node == null:
		return
	var player := parent_node.get_node_or_null("Player") as Node2D
	var floor_layer := parent_node.get_node_or_null("FloorLayer") as Node2D
	if player == null or floor_layer == null:
		return

	var base_pos := floor_layer.to_local(player.global_position)
	var sample_points: Array[Vector2] = [
		base_pos,
		base_pos + Vector2(0.0, -6.0),
		base_pos + Vector2(-6.0, 0.0),
		base_pos + Vector2(6.0, 0.0),
	]

	var extra_illum_points: Array[Vector2] = []
	if player.has_method("get_active_illumination_points"):
		var world_illum_pts: Array = player.call("get_active_illumination_points")
		for wp in world_illum_pts:
			var world_vec: Vector2 = wp
			extra_illum_points.append(floor_layer.to_local(world_vec))

	var detected_player_room: StringName = &""
	for idx in range(_room_states.size()):
		var room: Dictionary = _room_states[idx]
		var room_id: StringName = room["id"]
		var occupied := _is_player_in_room(room, sample_points)
		if occupied and detected_player_room == &"":
			detected_player_room = room_id

		var flare_or_tool_lit: bool = false
		if not extra_illum_points.is_empty():
			flare_or_tool_lit = _is_player_in_room(room, extra_illum_points)

		var room_flicker_forced := flicker_all_rooms or bool(flicker_rooms.get(room_id, false))
		var is_flickering := room_flicker_forced or (flicker_current_room and occupied)
		var should_be_lit := occupied or flare_or_tool_lit or force_all_lights_on or room_flicker_forced
		if emergency_breaker_mode and not bool(breaker_powered_rooms.get(room_id, false)):
			should_be_lit = flare_or_tool_lit

		var target := 1.0 if should_be_lit else 0.0
		var current: float = float(room["lit_factor"])
		if snap_immediately:
			current = target
		else:
			current = move_toward(current, target, delta * FADE_SPEED)
		room["lit_factor"] = current

		var effective_lit := current
		if is_flickering and current > 0.01:
			effective_lit = current * _compute_flicker_multiplier(_flicker_time, float(idx) * 1.93)
		_apply_room_lighting(room, effective_lit, is_flickering, idx)

	_current_player_room_id = detected_player_room


func _compute_flicker_multiplier(t: float, phase: float) -> float:
	var p := t + phase
	match flicker_style:
		&"strobe":
			var pulse := sin(p * 26.0) + 0.45 * sin(p * 41.0)
			return 1.25 if pulse > 0.0 else 0.04
		&"brownout":
			var wave := 0.5 + 0.5 * sin(p * 3.8 + sin(p * 1.7))
			var sputter := 0.5 + 0.5 * sin(p * 31.0)
			if wave < 0.35:
				return 0.06 + 0.14 * sputter
			elif wave < 0.55:
				return 0.25 + 0.55 * sputter
			return 0.88 + 0.18 * sin(p * 9.0)
		&"pulse":
			return 0.12 + 0.98 * (0.5 + 0.5 * sin(p * 6.5))
		_:
			# "erratic": fluorescent voltage surge + sudden ballast dropouts
			var cell := floorf(p * 13.5)
			var noise := fposmod(sin(cell * 127.1 + phase * 311.7) * 43758.5453, 1.0)
			var sub_noise := fposmod(sin(floorf(p * 29.0) * 269.5 + phase * 183.3) * 19453.21, 1.0)
			if noise < 0.24:
				return 0.03 if sub_noise < 0.65 else 0.18
			elif noise < 0.48:
				return 0.22 + 0.58 * sub_noise
			elif noise > 0.86:
				return 1.22
			return 0.86 + 0.14 * sin(p * 19.0)


func _is_player_in_room(room: Dictionary, sample_points: Array[Vector2]) -> bool:
	var bbox: Rect2 = room["bbox"]
	var origin: Vector2 = room["origin"]
	var img: Image = room["image"]
	var entry_rects: Array = room["entry_rects"]

	for pt in sample_points:
		for rect in entry_rects:
			var r_box: Rect2 = rect
			if r_box.has_point(pt):
				return true
		if bbox.has_point(pt):
			if img == null:
				return true
			var lx := clampi(floori(pt.x - origin.x), 0, img.get_width() - 1)
			var ly := clampi(floori(pt.y - origin.y), 0, img.get_height() - 1)
			if img.get_pixel(lx, ly).a > 0.12:
				return true
	return false


func _apply_room_lighting(room: Dictionary, lit_factor: float, is_flickering: bool = false, room_idx: int = 0) -> void:
	var clamped_lit := clampf(lit_factor, 0.0, 1.0)
	var unlit_factor := 1.0 - clamped_lit

	var dim_sprite := room["dim_sprite"] as Sprite2D
	if is_instance_valid(dim_sprite):
		var tint_alpha := UNLIT_ROOM_GRAY_TINT.a * unlit_factor
		if is_flickering and clamped_lit < 0.45:
			# Deepen the unlit shadow slightly during flicker dropouts so the flicker is unmistakable
			tint_alpha = lerpf(UNLIT_ROOM_GRAY_TINT.a, 0.48, 1.0 - (clamped_lit / 0.45))
		dim_sprite.modulate = Color(
			UNLIT_ROOM_GRAY_TINT.r,
			UNLIT_ROOM_GRAY_TINT.g,
			UNLIT_ROOM_GRAY_TINT.b,
			tint_alpha
		)
		dim_sprite.visible = tint_alpha > 0.005

	var prop_container := room["prop_container"] as CanvasItem
	if is_instance_valid(prop_container):
		prop_container.modulate = UNLIT_PROP_MODULATE.lerp(LIT_PROP_MODULATE, clamped_lit)

	var lights: Array = room["lights"]
	for i in range(lights.size()):
		var entry: Dictionary = lights[i]
		var light_node := entry["node"] as PointLight2D
		if is_instance_valid(light_node):
			var base_e: float = float(entry["base_energy"])
			var local_lit := lit_factor
			if is_flickering:
				var micro_jitter := 0.88 + 0.24 * sin(_flicker_time * 34.0 + float(i) * 1.7 + float(room_idx))
				local_lit *= micro_jitter
			light_node.energy = base_e * maxf(local_lit, 0.0)
			light_node.enabled = local_lit > 0.01

	var wall_fixtures: Array = room.get("wall_fixtures", [])
	for i in range(wall_fixtures.size()):
		var fixture := wall_fixtures[i] as Node2D
		if is_instance_valid(fixture):
			var fixture_lit := lit_factor
			if is_flickering and lit_factor > 0.02:
				var jitter := 0.85 + 0.30 * sin(_flicker_time * 38.0 + float(i) * 2.1 + float(room_idx))
				fixture_lit = maxf(lit_factor * jitter, 0.0)
			fixture.call("set_lit_amount", fixture_lit)


# --- Dev Menu / Testing API ---

func get_room_definitions() -> Array[Dictionary]:
	return ROOM_DEFINITIONS


func get_current_player_room_id() -> StringName:
	return _current_player_room_id


func set_flicker_current_room(enabled: bool) -> void:
	flicker_current_room = enabled


func is_flicker_current_room() -> bool:
	return flicker_current_room


func set_flicker_all_rooms(enabled: bool) -> void:
	flicker_all_rooms = enabled


func is_flicker_all_rooms() -> bool:
	return flicker_all_rooms


func set_room_flicker(room_id: StringName, enabled: bool) -> void:
	if enabled:
		flicker_rooms[room_id] = true
	else:
		flicker_rooms.erase(room_id)


func toggle_room_flicker(room_id: StringName) -> bool:
	var next_state := not is_room_flickering(room_id)
	set_room_flicker(room_id, next_state)
	return next_state


func is_room_flickering(room_id: StringName) -> bool:
	return bool(flicker_rooms.get(room_id, false))


func set_flicker_style(style: StringName) -> void:
	flicker_style = style


func get_flicker_style() -> StringName:
	return flicker_style


func set_flicker_speed(speed: float) -> void:
	flicker_speed = clampf(speed, 0.25, 3.0)


func get_flicker_speed() -> float:
	return flicker_speed


func set_force_all_lights_on(enabled: bool) -> void:
	force_all_lights_on = enabled


func is_force_all_lights_on() -> bool:
	return force_all_lights_on


func clear_all_flicker() -> void:
	flicker_current_room = false
	flicker_all_rooms = false
	flicker_rooms.clear()


func set_emergency_breaker_mode(enabled: bool) -> void:
	emergency_breaker_mode = enabled


func is_emergency_breaker_mode() -> bool:
	return emergency_breaker_mode


func set_breaker_power(room_id: StringName, powered: bool) -> bool:
	if powered:
		var current_used := get_used_power_units()
		if not is_breaker_powered(room_id) and current_used >= max_power_units:
			return false
		breaker_powered_rooms[room_id] = true
	else:
		breaker_powered_rooms.erase(room_id)
	return true


func is_breaker_powered(room_id: StringName) -> bool:
	return bool(breaker_powered_rooms.get(room_id, false))


func get_used_power_units() -> int:
	return breaker_powered_rooms.size()


func get_max_power_units() -> int:
	return max_power_units


func set_max_power_units(val: int) -> void:
	max_power_units = max(1, val)

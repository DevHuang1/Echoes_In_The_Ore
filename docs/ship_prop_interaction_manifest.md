# Ship prop interaction manifest

All paths are under the existing `BareShipWalkthrough` root in
`res://scenes/ship/bare_ship_walkthrough.tscn`. Runtime access markers are children
of the named host; saved furniture is not duplicated. Each stable ID remains
independent even where equipment shares a cooling loop/system.

All 52 rows passed E selection/cancellation, connected real-player routes and
host-move marker attachment in the physical runtime validator. Full mission
procedures are separately exercised in both state and rendered validators.
The four hiding rows also passed concealment entry/exit. See the validation report
for exact test scope and current counts.

| Scene-tree path below root | Stable ID | Function / task connection |
|---|---|---|
| `BridgeRoomProps/MissionPlanningTable` | `bridge.planning` | Assignments, objective prerequisites, phase evidence/journal, final report, save/load |
| `BridgeRoomProps/MainHelmConsole` | `bridge.helm` | Compare planned/instrument headings; signed correction and verification |
| `BridgeRoomProps/UpperFlightControlStation` | `bridge.comms.upper` | Prepare verified report; choose signal-compatible protocol; transmit/acknowledge |
| `BridgeRoomProps/LowerFlightControlStation` | `bridge.comms.lower` | Prepare verified report; choose signal-compatible protocol; transmit/acknowledge |
| `BridgeRoomProps/UpperBowFlightConsole` | `bridge.flight.upper` | Compare planned/instrument headings; signed correction and verification |
| `BridgeRoomProps/LowerBowFlightConsole` | `bridge.flight.lower` | Compare planned/instrument headings; signed correction and verification |
| `BridgeRoomProps/UpperStationChair` | `bridge.chair.upper` | Operator-access examination; seated animation unavailable |
| `BridgeRoomProps/MainHelmChair` | `bridge.chair.helm` | Operator-access examination; seated animation unavailable |
| `BridgeRoomProps/LowerStationChair` | `bridge.chair.lower` | Operator-access examination; seated animation unavailable |
| `CrewLivingQuarterProps/PersonalComputerDesk` | `quarters.desk` | Duty roster, authorised watch records and supported check-in conclusion |
| `CrewLivingQuarterProps/CommunalTable` | `quarters.table` | Duty roster, authorised watch records and supported check-in conclusion |
| `CrewLivingQuarterProps/StorageCabinet02` | `quarters.wardrobe` | Retrieve/store shared inventory supplies |
| `CrewLivingQuarterProps/ThreeDrawerChest` | `quarters.drawer.1` | Retrieve/store shared inventory supplies |
| `CrewLivingQuarterProps/ThreeDrawerChest02` | `quarters.drawer.2` | Retrieve/store shared inventory supplies |
| `CrewLivingQuarterProps/StackedCapsuleUnit` | `quarters.bed.1` | Conditional fatigue recovery without chapter/event advancement |
| `CrewLivingQuarterProps/StackedCapsuleUnit02` | `quarters.bed.2` | Conditional fatigue recovery without chapter/event advancement |
| `CrewLivingQuarterProps/StackedCapsuleUnit03` | `quarters.bed.3` | Conditional fatigue recovery without chapter/event advancement |
| `CrewLivingQuarterProps/DeskChair` | `quarters.chair.desk` | Operator-access examination; seated animation unavailable |
| `CrewLivingQuarterProps/TableChairNorth` | `quarters.chair.north` | Operator-access examination; seated animation unavailable |
| `CrewLivingQuarterProps/TableChairSouth` | `quarters.chair.south` | Operator-access examination; seated animation unavailable |
| `CrewLivingQuarterProps/TableChairWest` | `quarters.chair.west` | Operator-access examination; seated animation unavailable |
| `CrewLivingQuarterProps/TableChairEast` | `quarters.chair.east` | Operator-access examination; seated animation unavailable |
| `CargoBayProps/ElectricPalletMover` | `cargo.mover` | Bounded identified-load transfer and cargo-to-engine coolant-kit ledger transfer |
| `CargoBayProps/CargoInspectionScale` | `cargo.scale` | Manifest/ID/seal comparison, scale tare/mass and disposition |
| `CargoBayProps/SecuredCylinderRack` | `cargo.cylinders` | Labelled COOL-02/O2-01/N2-03 issues; different inventory contents |
| `CargoBayProps/MaintenanceTrolley` | `cargo.trolley` | Bounded identified-load transfer and cargo-to-engine coolant-kit ledger transfer |
| `CargoBayProps/CargoLocker` | `cargo.locker` | Shared supply storage and safe concealment |
| `CargoBayProps/TiedBoxBundle` | `cargo.bundle` | Manifest/seal inspection and safe concealment |
| `EngineRoomProps/TurbineUpper` | `engine.turbine.1` | Individually identified output/cooling-loop monitoring and maintenance output control |
| `EngineRoomProps/TurbineLower` | `engine.turbine.2` | Individually identified output/cooling-loop monitoring and maintenance output control |
| `EngineRoomProps/TurbineMiddleWest` | `engine.turbine.3` | Individually identified output/cooling-loop monitoring and maintenance output control |
| `EngineRoomProps/TurbineMiddleEast` | `engine.turbine.4` | Individually identified output/cooling-loop monitoring and maintenance output control |
| `EngineRoomProps/CoolantPumpUpper` | `engine.pump.1` | Pump/cooling-loop readings and diagnosis; pump1 service outbound |
| `EngineRoomProps/CoolantPumpLower` | `engine.pump.2` | Pump/cooling-loop readings and diagnosis; pump1 service outbound |
| `EngineRoomProps/ValveManifoldUpper` | `engine.valve.1` | Valve pressure/flow comparison; valve2 service return |
| `EngineRoomProps/ValveManifoldLower` | `engine.valve.2` | Valve pressure/flow comparison; valve2 service return |
| `EngineRoomProps/LockerUpper` | `engine.locker.1` | Shared supply storage and safe concealment |
| `EngineRoomProps/LockerLower` | `engine.locker.2` | Shared supply storage and safe concealment |
| `PowerMaintenanceRoomProps/BreakerCabinet` | `power.breaker` | Load diagnosis, science-service isolation, allocation/restoration/verification; original bank controls at cell |
| `PowerMaintenanceRoomProps/PowerConverterAssembly` | `power.converter` | Load diagnosis, science-service isolation, allocation/restoration/verification; original bank controls at cell |
| `PowerMaintenanceRoomProps/PowerCellModule` | `power.cell` | Load diagnosis, science-service isolation, allocation/restoration/verification; original bank controls at cell |
| `LifeSupportRoomProps/OxygenTankRack` | `life.oxygen` | Gas/airflow diagnosis, isolation/restoration/verification; filter outbound, scrubber return, optional labelled O2 reserve |
| `LifeSupportRoomProps/AirDuctAssembly` | `life.duct` | Gas/airflow diagnosis, isolation/restoration/verification; filter outbound, scrubber return, optional labelled O2 reserve |
| `LifeSupportRoomProps/AirScrubber` | `life.scrubber` | Gas/airflow diagnosis, isolation/restoration/verification; filter outbound, scrubber return, optional labelled O2 reserve |
| `LifeSupportRoomProps/FilterCartridge` | `life.filter` | Gas/airflow diagnosis, isolation/restoration/verification; filter outbound, scrubber return, optional labelled O2 reserve |
| `HydroponicsRoomProps/ControlConsole` | `hydro.console` | EC/flow/pump/environment comparison, manifold outbound or measured buffer dosing return, recovery verification |
| `HydroponicsRoomProps/NutrientPump` | `hydro.pump` | EC/flow/pump/environment comparison, manifold outbound or measured buffer dosing return, recovery verification |
| `HydroponicsRoomProps/GrowTrayNorth` | `hydro.tray.north` | EC/flow/pump/environment comparison, manifold outbound or measured buffer dosing return, recovery verification |
| `HydroponicsRoomProps/GrowTraySouth` | `hydro.tray.south` | EC/flow/pump/environment comparison, manifold outbound or measured buffer dosing return, recovery verification |
| `HydroponicsRoomProps/SeedlingRack` | `hydro.seedlings` | EC/flow/pump/environment comparison, manifold outbound or measured buffer dosing return, recovery verification |
| `HydroponicsRoomProps/WallHerbShelf` | `hydro.herbs` | Phase-sensitive herb/reservoir crew observation |
| `ShuttleBayCargo` | `shuttle.bundle` | Retrieve/store shared inventory supplies |

Every major prop also offers its room’s phase-sensitive record action, stored
under `outbound.<room>` / `return.<room>`. Outbound notes do not reveal return
records. Only authorised/shared supplies and records are exposed.

## Decorative and deferred scope

Pipes, lamps, mist, floor decals and repeated decorative herb clusters do not
each get an Examine panel. Their system observation/operation belongs to the
nearby major host. Sprite, collision, handle and foot children are part of that
same prop; they are not separate targets.

Chairs offer operator-access examination because the supplied player has only
walking animation rows. Capsule beds restore fatigue under safe duty conditions.
No seated, tool-use or new character frames have been invented.

The shuttle bundle is optional shared storage. The central recess/med-bay stays
environmental. The separate science lab is inactive and its six unresolved
room_additions images are not dependencies of this walkthrough. Ops/mess/other
areas retain their layouts for later briefing, crew-report and social duties.

`ship_missions_playguide.md` describes both playable sequences and editing. The
JSON version of this manifest includes room/type IDs and per-prop validation flags.

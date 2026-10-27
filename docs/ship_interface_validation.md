# Ship equipment interface validation

This report covers the mission interface redesign, separate from the original
mission implementation report. Baseline is `kaung` at `747a1dc`. No commit/push,
merge, furniture transform, collision, floor, wall, character or map edit is part
of this task.

## Implementation and screen checklist

All screens use the original mission owner, inventory and action handlers.
`equipment_ui.gd` constructs a reusable local Theme and native components:
metal/inset panels, physical command buttons, tabs, status lamps, segmented meters,
readouts, confirmation review cards and chassis details. It uses the existing
bitmap font and slider artwork with nearest filtering. No reference image is
embedded. The established HUD and inventory theme are unchanged.

| Group | Implemented composition | Review/validation |
|---|---|---|
| Power | Essential/science/reserve bus, voltage, bank synchronization, load meters, isolation handle, stable-observation strip | Both sizes; blocked, isolated, restored, verified; original bank game |
| Cargo | Identified container, scale/tare/reference, mass/tolerance, seal and custody, disposition review, cylinder labels and supply routing | Both sizes; weighing and accepted/quarantined decisions in both sequences |
| Engines | Two actual pump/valve circuits, four turbine IDs/loop assignments, pressure, load, flow and temperature | Both sizes; pump service outbound and valve service return, isolation and recovery |
| Life support | Intake/filter/scrubber/air circuit, O2, CO2, airflow, reserve, isolation and recovery | Both sizes; original filter sequence and return scrubber service |
| Hydroponics | Reservoir/pump/manifold/grow-bed circuit, EC, delivery, pump capacity, humidity and recovery | Both sizes; original manifold and actual return buffer dosing |
| Bridge | Eight-duty grid, evidence/history, heading comparison/correction, retained report, protocol/link/acknowledgement | Both sizes; locked, available, transmitted, acknowledged and filed |
| Quarters | Named roster/watch review and supported comparison, separate storage transfers, capsule rest and access feedback | Both sizes; outbound matched records and return whereabouts unconfirmed |

Stage tabs replace the long scrolling action column. Only records/report text
scrolls. Shared prerequisites appear once; each disabled control retains its own
interlock tooltip and focus/hover explanation. Stock entries paginate four at a
time. Existing actions offered at shared engine locker hosts remain accessible.
No supported model action or option is discarded to simplify the presentation.

## Checks

The unchanged state/save validator passed **271 checks**, exit 0, normal OpenGL.
The unchanged physical validator passed **663 checks**, exit 0, normal OpenGL.
The extended rendered rollout passed **1,473 checks**, including all original
rendered assertions, both complete mission sequences and 146 two-size captures.
The final focused interface run passed **1,361 checks**. All four suites have
zero assertion failures; final counts, source hashes and preservation proof are
recorded in `ship_interface_validation.json`.

The focused interface validator covers every offered action at all 52 hosts in
both contexts, all option counts and numeric ranges, actual mouse operation of
the breaker and bank controls, stable observation, keyboard navigation/menus,
focus and pending input retention through refresh, close/reopen and loaded
readouts. It found and helped fix a rebuilt numeric widget losing keyboard focus.

The rollout validator inherits the original rendered test unchanged, retains its
behavioral assertions and adds actual pointer activation, stage access, native
control bounds, and two-size captures of blocked/active/verified states. Original
service tasks retain their callbacks, sliders/rotation ranges, resumption and
consumption. HUD inventory drag/drop, compatibility, hotbar keys/wheel, Settings,
volume, blank map, closing and original ship/planet transit are still tested.

Godot 4.7.2 Compatibility/OpenGL is used throughout. Headless editor import/compile
passes. Repeated runtime reloads retain an intermittent native engine limitation:
one normal-renderer run completed all 271 assertions, then crashed on shutdown.
The next run completed 271 assertions and exited 0. An isolated copy of the
pre-redesign scripts from `747a1dc`, using the same saved ship scene/artwork,
also crashed on reload. Both Windows records report `0xc0000005` at native offset
`0x321fccb`, matching the previously documented headless failure. This is a
reproduced pre-existing reload issue, not counted as a passing test run or a UI
regression. Its engine-level cause remains unresolved. Normal gameplay flows,
both complete sequences, original planet transit and the successful save/reload
run are validated. No engine upgrade or geometry change was used to mask it.

## Evidence and review

Local screenshots/logs/JSON live under `.godot/ui_restyle_validation/`.
`rollout_report.json` maps each capture to the actual station, stage and watch.
The original rendered report and scene-transition screenshots remain in
`.godot/mission_validation/`. Screenshots are generated from working Controls.

Actual visual inspections are tracked in `ship_interface_redesign.md`, including
compact-layout fixes. Final screenshot selections and review notes are recorded
in the JSON evidence snapshot. File existence alone is not a visual-review claim.

## Representative screenshots

These working interfaces were actually opened and inspected in both sizes.
The `final_` images load the completed return save produced by the walkthrough
validator; measurements are not invented for a mockup. Blocked and isolated
captures come from the real mission sequence. The full local capture manifest is
in `rollout_report.json` and `interface_report.json`.

| View | 1280×720 | 1024×576 |
|---|---|---|
| Power | [Image](../.godot/ui_restyle_validation/screenshots/final_power_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_power_1024x576.png) |
| Cargo disposition | [Image](../.godot/ui_restyle_validation/screenshots/final_cargo_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_cargo_1024x576.png) |
| Engine cooling | [Image](../.godot/ui_restyle_validation/screenshots/final_engine_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_engine_1024x576.png) |
| Life support | [Image](../.godot/ui_restyle_validation/screenshots/final_life_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_life_1024x576.png) |
| Hydroponics | [Image](../.godot/ui_restyle_validation/screenshots/final_hydro_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_hydro_1024x576.png) |
| Crew roster | [Image](../.godot/ui_restyle_validation/screenshots/final_crew_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_crew_1024x576.png) |
| Bridge duty log | [Image](../.godot/ui_restyle_validation/screenshots/final_planning_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_planning_1024x576.png) |
| Navigation | [Image](../.godot/ui_restyle_validation/screenshots/final_navigation_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_navigation_1024x576.png) |
| Transmission | [Image](../.godot/ui_restyle_validation/screenshots/final_communications_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_communications_1024x576.png) |
| Storage | [Image](../.godot/ui_restyle_validation/screenshots/final_storage_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_storage_1024x576.png) |
| Evidence | [Image](../.godot/ui_restyle_validation/screenshots/final_records_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_records_1024x576.png) |
| Retained report | [Image](../.godot/ui_restyle_validation/screenshots/final_report_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/final_report_1024x576.png) |
| Original filter controls | [Image](../.godot/ui_restyle_validation/screenshots/reviewed_filter_regulation_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/reviewed_filter_regulation_1024x576.png) |
| Original manifold controls | [Image](../.godot/ui_restyle_validation/screenshots/reviewed_nutrient_flow_complete_1280x720.png) | [Image](../.godot/ui_restyle_validation/screenshots/reviewed_nutrient_flow_complete_1024x576.png) |

## Changed files

Runtime:

- `scripts/ui/ship_procedure_panel.gd`: equipment layout and live view/controller.
- `scripts/ui/service_task_console.gd`: local skin, adaptive frame, original games.
- `scripts/ship/ship_mission_state.gd`: read-only accessor for the existing fixed
  hydro environmental observations, shared by prose and widgets. No rules,
  state fields, save schema, action ranges or progression are changed.
- New `scripts/ui/equipment_ui.gd`, `ship_station_presentation.gd`, and
  `ship_equipment_diagram.gd`, with Godot UID sidecars.

Validation:

- New `tools/validate_ship_interfaces.gd`, `ship_interface_validation.tscn`.
- New `tools/validate_ship_interface_rollout.gd`,
  `ship_interface_rollout_validation.tscn`, and script UID sidecars.
- The three original validators are unchanged.

Documentation: this report, its JSON evidence snapshot,
`ship_interface_redesign.md`, and the updated `ship_missions_playguide.md`.
The byte-level preservation report covers all nine pre-existing edits, including
the saved walkthrough and eight import metadata files. They are not task changes.

## Re-run

Use the configured Godot executable with the project directory as working folder:

```powershell
godot --headless --editor --import --path . --quit
godot --path . res://tools/ship_missions_validation.tscn --audio-driver Dummy
godot --path . res://tools/ship_interactions_validation.tscn --audio-driver Dummy
godot --path . res://tools/ship_interface_validation.tscn --audio-driver Dummy
godot --path . res://tools/ship_interface_rollout_validation.tscn --audio-driver Dummy
```

The last two scenes can also be run through Godot MCP. All test save writes use
the existing isolated validation namespace. Runtime UI state remains in the
existing model; opening a station always rebinds to its saved equipment state.

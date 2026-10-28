# Ship-side mission verification

Baseline: `kaung`, `a3f823924fdb98a8b2b13f9f65aacdef28d0ff2c`, Godot
4.7.2 Compatibility renderer. No commit, push or branch merge is part of this work.
See `ship_missions_implementation.md` for checkpoints and resolved test findings,
`ship_missions_playguide.md` for the complete routes/controls, and the JSON/Markdown
prop manifest for all 52 hosts.

## Checks and evidence

The tests instantiate the real walkthrough/HUD and original service controls.
They do not replace the inventory or run a separate mock mission implementation.
Test writes stay in `.godot/mission_validation/`; no normal user save is loaded or
overwritten. Both contexts exercise all eight duties across the seven rooms.

Final results: **271 state/save checks**, **663 physical/interaction checks** and
**267 rendered checks**, all with zero assertion failures. The state and physical
validators exited0 in normal OpenGL. The rendered run completed through Godot MCP.
The headless editor import exited0; the separate headless runtime reload limitation
is described below and is not counted as a passing run.

| Requirement | Evidence / coverage |
|---|---|
| Import/parse and normal entry | Headless editor `--import --quit` completed with exit0, no import/parse errors. Rendered MCP runner follows actual landing Start → existing prologue Skip Intro → arrival/walkthrough. |
| Seven room procedures and phase notes | State and rendered validators finish roster, cargo, power, life, hydro, cooling, navigation and communications in both contexts. Seven distinct room evidence keys are recorded per context. |
| Real diagnosis/state | Wrong crew/cargo/diagnosis/dose/correction/protocol decisions fail. Tests check inventory/stock consumption, allocations, both cooling-loop flows, temperature, gas recovery, EC/delivery and acknowledgement state. The prepared report retains the actual measured values and phase evidence through transmission/acknowledgement. |
| Coherent sequences | Prerequisite attempts fail before assignment/prior duty. Report requires all eight verifications. Return has a changed diagnosis and measurements; it does not repeat outbound filter/manifold/bank failures. |
| Reach, one target, walls/doors | All52 actual markers select/open with E; all52 have connected paths traversed using the real player movement method. Actual closed pressure-door barriers reject interaction; cross-room/remote access fails. Objective data points to station access markers, and retired world markers are hidden. |
| Cancel/retry/idempotence | E/Esc opens/closes each target, restores movement. Partial filter housing stage/rotation survives cancellation and a fresh scene load. Wrong doses and full-inventory transfers lose no items. Repeated service/report submissions cannot consume/reward again. |
| Persistence | Fresh-scene full return reload, partial outbound filter reload, immutable inventory snapshots, malformed data rejection, and existing planet-transit preservation including the separate test save namespace. |
| Concealment | Cargo locker/bundle and both engine lockers enter and exit with collision/visibility/control restored. Signal/group/metadata publish concealment. Obstructed exits allow retry; an obstructed saved exit falls back to clear floor. Enemy detection is explicitly unverified: no compatible AI exists. |
| Existing gameplay | Original power/filter/manifold Controls finish. Amara dialogue, acceptance and both original E jobs work. Walking routes, solid footprints, doors, blank map, inventory/equipment compatibility, quick slots/wheel, Settings volume and modal closing are checked. |
| Sorting and presentation | Original Z/ysort/scene properties are byte-preserved. Rendered probe captures player on each side of the bridge table. World screenshots cover all seven furnished rooms. Procedures and existing HUD overlays are captured at1280×720 and1024×576. |
| Furniture editability | Every interaction marker is a child of its existing host; moving/restoring each host by3px in memory moves/restores its marker. Saved collection instances, Editable Children and all transforms/footprints remain unchanged. |
| Unfinished areas | Runtime asserts no LabRoom. Active scene/scripts do not load its missing room_additions images. Shuttle bundle is optional storage; med/recess environmental, ops/mess future integration points. |

Final machine-readable counts, source hashes and preservation proof are in
`ship_missions_validation.json`. Detailed logs/JSON and PNGs remain under
`.godot/mission_validation/`. They are local validation artifacts, not game assets.

## Re-run

Use the project's configured Godot4.7.2 executable. From the project directory:

```powershell
godot --headless --editor --import --path . --quit
godot --path . res://tools/ship_missions_validation.tscn --audio-driver Dummy
godot --path . res://tools/ship_interactions_validation.tscn --audio-driver Dummy
```

Through Godot MCP, run `res://tools/ship_missions_rendered_validation.tscn` and
inspect debug output plus `rendered_report.json`. It uses the normal renderer,
actual E/key events, original/dynamic Control signals and live verification time.
The physical test separately traverses routes with the real player movement and
collision code; rendered sequence travel places the test player at each proven
access point. This is not a claim that the rendered runner manually walked every
cross-room route.

The headless editor initially encountered sandbox access errors for Godot's
normal per-user editor settings. The authorised import was repeated with access
to that directory and completed cleanly. It normalised eight unrelated lab import
files' line endings; those exact baseline bytes were restored afterward.

The headless runtime path reproducibly hit a native access violation while
recreating hydroponics visuals on a second ship load, without a GDScript error.
That path is not claimed as passing. The same full automated state/save test
passed in the project's normal OpenGL renderer, including three fresh ship loads,
and exited0. The MCP rendered runner also exercises the original ship → planet →
ship transition. The headless cause remains unresolved; use the normal-renderer
commands above for these runtime validators. No Godot upgrade, visual/collision
change or skipped save test was used to mask it. The headless editor import itself
completed cleanly. Assertion counts and process exit results are recorded
separately in the JSON report.

## Preserved work and limitations

The baseline records913 tracked file hashes and23 pre-existing local edits.
All23 remain byte-identical, including the47MB walkthrough and existing import
metadata. Four existing scripts are intentionally extended: player controller,
walkthrough owner, HUD and service console. Four new scripts provide the owner's
catalogue/state/base methods and procedure renderer. No new autoload, competing
inventory/objective owner, scene furniture, map, floor, wall or collision geometry
has been added/replaced.

No supplied seated/tool-use animations were found beyond the four walking rows.
Chairs therefore offer access/examination and beds a conditional short rest. The
return scenario is development-only because canonical incident/crew-fate/ending
transitions are not implemented in this checkout. Hiding exposes state for future
AI but makes no enemy-detection claim. Concealed saves intentionally resume outside
on clear floor. Required missions do not activate the overlapping lab or require
unfinished rooms. These are the scope boundaries in the user's brief.

## Files changed by this task

Existing scripts extended:

- `scripts/player/player_controller.gd`: concealment API; optional door-free
  connectivity planning while normal movement keeps existing door barriers.
- `scripts/ship/bare_ship_walkthrough.gd`: inherited mission methods, original
  service/Amara integration and existing planet-transit handoff.
- `scripts/ui/walk_hud.gd`: existing inventory transfer/snapshot APIs, objective
  data/markers and development scenario entries; independent snapshot arrays.
- `scripts/ui/service_task_console.gd`: original service-control partial snapshots
  and resumption, preserving the three existing games and inactive lab interfaces.

New runtime scripts (and generated `.gd.uid` sidecars):

- `scripts/ship/ship_mission_catalog.gd`
- `scripts/ship/ship_mission_state.gd`
- `scripts/ship/ship_mission_walkthrough.gd`
- `scripts/ui/ship_procedure_panel.gd`

New validation scripts/scenes:

- `tools/validate_ship_missions.gd` and `tools/ship_missions_validation.tscn`
- `tools/validate_ship_interactions.gd` and `tools/ship_interactions_validation.tscn`
- `tools/validate_ship_missions_rendered.gd` and
  `tools/ship_missions_rendered_validation.tscn`
- Generated `.gd.uid` sidecars for the three validator scripts.

Documentation: the implementation checklist, play guide, this verification report,
its JSON evidence snapshot, and the JSON/Markdown prop interaction manifest under
`docs/`. Logs, baseline backups, scratch diagnostics and captured PNGs are ignored
local artifacts under `.godot/mission_baseline/` and `.godot/mission_validation/`.
The already-modified walkthrough and22 import files visible in Git status belong
to the preserved baseline; they were not changed by this task.

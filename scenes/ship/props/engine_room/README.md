# Engine-room props

The reference map's **04 engines** is the walkthrough's **R06 / Starboard aft room**,
identified from the current floor, hull and corridor entrance. The collection is at
floor coordinates (1347, 224); the walkthrough root's saved (-30, -23) offset is
preserved. The floor module's used bounds are (1347, 224)–(1625, 554), but the actual
floor alpha and the current wall's angled corners determine safe placements.

## Reusable scenes

- `res://scenes/ship/props/engine_room/turbine_module.tscn`
- `res://scenes/ship/props/engine_room/coolant_circulation_pump.tscn`
- `res://scenes/ship/props/engine_room/fuel_valve_manifold.tscn`
- Reused locker: `res://scenes/ship/props/cargo_bay/cargo_locker.tscn`
- Collection: `res://scenes/ship/props/engine_room_props.tscn`

The engine and cargo locker PNGs are byte-for-byte identical (SHA-256
`9F122D2E930C59E1555D9A33D2BB2338B69173C6246D1F74B5087280D13977D9`).
The existing locker scene therefore supplies the same approved artwork, all
directions/states, clipping outlines and future access/hide markers without a
duplicate scene or script. Both original PNGs stay in their original locations.

All machinery inherits the existing cargo prop scene and shared quarters/cargo
tool scripts: atlas preview, stable floor anchor, Artwork Scale, collision toggle,
editable chamfered floor footprint, layer 1/mask 0. Props share Z=3 with the player
and use the walkthrough/collection's existing Y-sorting. No shared scripts,
lighting, navigation, door, room, floor or wall geometry changed.

## Full Scene-tree paths and initial views

Open `res://scenes/ship/bare_ship_walkthrough.tscn`.

| Exact Scene-tree path | View | Collection-local Position |
|---|---|---|
| BareShipWalkthrough/EngineRoomProps/TurbineUpper | East: coupling RIGHT | (69, 126) |
| BareShipWalkthrough/EngineRoomProps/TurbineLower | East: coupling RIGHT | (69, 269) |
| BareShipWalkthrough/EngineRoomProps/CoolantPumpUpper | South: controls, motor LEFT, reservoir RIGHT | (154, 109) |
| BareShipWalkthrough/EngineRoomProps/CoolantPumpLower | South: controls, motor LEFT, reservoir RIGHT | (154, 283) |
| BareShipWalkthrough/EngineRoomProps/ValveManifoldUpper | South: three amber handwheels and gauges | (73, 62) |
| BareShipWalkthrough/EngineRoomProps/ValveManifoldLower | South: three amber handwheels and gauges | (73, 228) |
| BareShipWalkthrough/EngineRoomProps/LockerUpper | West: access LEFT, Intact–Closed | (233, 128) |
| BareShipWalkthrough/EngineRoomProps/LockerLower | West: access LEFT, Intact–Closed | (201, 244) |
| BareShipWalkthrough/EngineRoomProps/TurbineMiddleWest | East: coupling RIGHT | (69, 173) |
| BareShipWalkthrough/EngineRoomProps/TurbineMiddleEast | East: coupling RIGHT | (188, 186) |

The lower locker follows the eastern wall's inward corner rather than aligning
with the upper locker. Both have walkable floor immediately west of AccessPoint.
The centre corridor, maintenance approach and continuous upper/lower routes stay
open. There is no diagnostics cabinet.

## Select, move, resize and change facing in Godot

1. Open the walkthrough and select the **2D** workspace. Expand
   **BareShipWalkthrough > EngineRoomProps** in the Scene tree. Editable Children
   is already enabled on this collection instance; if it is disabled later,
   right-click EngineRoomProps and enable **Editable Children**.
2. Select the named prop root in the Scene tree (for example **LockerLower**).
   With the full ship visible, use **W** / Move Mode and drag its gizmo, or edit
   **Inspector > Node2D > Transform > Position**. Sprite, solid body and markers
   move together. Save the walkthrough to retain its instance overrides.
3. Change the script's **Artwork Scale** to resize its image proportionally.
   Keep **Transform > Scale = (1,1)** and **Rotation = 0**.
4. Resize collision separately under **Floor Footprint**. **Footprint Size** is
   used for the first two broad/end views; **Footprint Side Size** is used for
   the two side views. **Footprint Offset** moves the footprint relative to the
   floor anchor; **Footprint Corner Cut** adjusts its cut corners. Toggle
   **Collision Enabled** if needed. These dimensions are unscaled world units.
5. Choose **Direction** in the script properties; the editor preview changes
   immediately to the genuine separately drawn view. All four turbines use
   **East (coupling right)**, both pumps **South (controls, motor left)**, both
   manifolds **South (three handwheels)**, and both lockers **West (door left)**.
   The locker also exposes **Appearance**; leave **Intact - Closed** for the
   requested starter arrangement. Machinery has only the supplied intact views.
6. To add a future copy, drag the reusable scene into the room collection. Do not
   scale the collection or prop root. To inspect collision visually, run with
   **Debug > Visible Collision Shapes**.

## Source artwork measurements

All three machinery sheets are **1536 × 1024 RGBA** with real alpha, transparent
pipe openings and no red annotation. Approximately 39–52% of each source canvas is
fully transparent. The dark hardware is retained: no colour key or background
removal is applied. The source sheets are unchanged. Explicit measured rectangles
exclude faint remote padding/halos and neighbouring views, preserving machine
feet, lifting handles, couplings, controls and pipes. The pump's top-row bottom
edge ends before the next row's lifting handle begins.

Each row below gives **(x, y, width, height)** in original image pixels and a
**crop-local floor anchor (x, y)** measured at the supporting base. Different
views deliberately have different bounds and floor-anchor offsets.

### TurbineModule

Source: `res://art/concepts/engine_room_props/Chunky 16-bit turbine sprite sheet-1.png`

| Direction / visible landmark | Atlas rectangle | Floor anchor |
|---|---|---|
| North (rear end) | (215, 22, 524, 545) | (261, 514) |
| South (coupling forward) | (797, 22, 524, 545) | (262, 514) |
| East (coupling right) | (26, 615, 728, 376) | (350, 348) |
| West (coupling left) | (782, 615, 728, 376) | (372, 348) |

### CoolantCirculationPump

Source: `res://art/concepts/engine_room_props/16-Bit Coolant Unit Sprite Sheet-2.png`

| Direction / visible landmark | Atlas rectangle | Floor anchor |
|---|---|---|
| North (rear, motor right) | (132, 17, 605, 464) | (301, 434) |
| South (controls, motor left) | (799, 17, 605, 464) | (302, 434) |
| West (fan left) | (141, 482, 506, 513) | (245, 479) |
| East (fan right) | (885, 482, 510, 513) | (257, 479) |

### FuelValveManifold

Source: `res://art/concepts/engine_room_props/Retro 16-bit fuel manifold sprite sheet-3.png`

| Direction / visible landmark | Atlas rectangle | Floor anchor |
|---|---|---|
| North (rear) | (46, 14, 721, 472) | (363, 453) |
| South (three handwheels) | (801, 14, 729, 472) | (366, 453) |
| East (wheel right) | (295, 499, 290, 477) | (121, 460) |
| West (wheel left) | (949, 499, 294, 477) | (173, 460) |

### Locker

The reused locker keeps its established 1448 × 1086 atlas data. Its intact/closed
WEST crop is **(1077, 13, 187, 351)**, with crop-local floor anchor **(93, 327)**.
Its four columns are North/rear, South/front, East/door-right, West/door-left;
three rows are intact-closed, intact-open, damaged-closed. Existing per-view
outlines isolate overlapping open-door states. The original atlas measurements
and clipping are preserved.

## Hiding and gameplay

There is no reusable hiding gameplay implementation in the current project.
Both lockers retain **AccessPoint** and **HidePoint** Marker2D children from the
cargo scene. AccessPoint is 30 world units WEST of the base by default; the
**Future Hiding Markers** Inspector group adjusts access distance/offset and hide
offset. The markers prepare a later mechanic only. All ten props are
decorative and solid, with no chores, interaction, inventory, hiding or machinery
gameplay added.

## Validation

Run `res://tools/engine_room_validation.tscn` to validate the actual walkthrough.
It produces screenshots, per-view galleries and a JSON report in the ignored
`.godot/engine_validation/` directory, without saving gameplay or scene changes.
It checks all ten instances, requested views, transform and collision settings,
all supplied crops and anchors, artwork-only resizing, collision toggles, floor
bounds, real player blocking, door-trigger clearance, front/behind rendering and
continuous player traversal to 14 maintenance/access targets.

The rendered run uses the real walkthrough/player and the normal 1.75 camera zoom,
plus a closer 2.0 view. During route tests only, doors are opened in memory; no
door data is saved. Screenshots:
- `.godot/engine_validation/engine_room_gameplay.png`
- `.godot/engine_validation/engine_room_close.png`

Godot 4.7.2 validation completed through Godot MCP: **720 checks, 0 failures**.
The actual editor-hint preview run also passed **81 checks, 0 failures**, including
every supplied direction/state, floor anchors, editable footprints and separate
Artwork Scale. Pixel comparisons confirmed all ten props occlude the player
behind them and leave the player fully visible in front. All 14 access routes
were traversed using the existing player movement/collision implementation.

During the initial eight-prop integration, only the walkthrough changed among
files present at the start of that task.
Removing its new collection reference, instance and Editable Children flag
reproduces the previous walkthrough content exactly. Source PNGs, existing import
settings and all other files matched their starting hashes. Added files are the
three machine scenes, collection, this guide, validation script/scene/UID, and four
Godot-generated texture import descriptors (lossless, no size limit).

The subsequent two-turbine addition changes only the collection, this guide and
the existing validator. TurbineMiddleWest and TurbineMiddleEast reuse the original
scene, scale, RIGHT-pointing view and collision settings. Existing prop blocks and
walkthrough overrides are preserved; the collection now has ten props, including
four turbines.

The rendered walkthrough had no new runtime errors. Existing UI/input script
warnings remain. Headless editor runs also report the environment's certificate
store and global editor-settings write errors; these did not prevent import or
the successful editor-preview checks.

Existing local furniture placements and overrides are preserved. Remaining
pre-existing wall/floor visual mismatches are documented in
`res://tools/ship_wall_visual_report.md`; gameplay geometry was not altered to
match the newer wall art.

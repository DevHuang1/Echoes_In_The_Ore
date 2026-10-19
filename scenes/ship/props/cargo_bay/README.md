# Cargo bay props

## Placement and existing workflow

The reference cargo bay corresponds to the playable central-lower compartment,
internally **R08 / Center lower room**, between the center recess above, lower
deck below and shuttle bay to the right. Its original floor module bounds are
(697,405)–(1220,665), in FloorLayer coordinates. The current Valkyrie inner wall
edges put the main open area roughly at x=774–1161, y=465–625; the west entrance
uses a dogleg. Placement was checked against the current floor mask, rendered
walls and saved door transforms, rather than coordinates from the reference.

`res://scenes/ship/props/cargo_bay_props.tscn` is instanced once at (697,405)
in the walkthrough. The ship's saved root offset (-30,-23) is retained.
Existing furniture, wall/floor assets, doors, lighting, player and gameplay
scripts are unchanged.

The shared cargo script **extends the existing crew_quarters_prop.gd** and its
base scene. It reuses the original editor preview, atlas textures, floor
anchors, chamfered footprint and independent artwork scaling. Existing quarters
and bridge code is not modified. Cargo props retain Z=3, matching the player,
under the existing Y-sorted ship and a Y-sorted CargoBayProps collection.

## Reusable scenes and exact node paths

All paths below start at the root of `bare_ship_walkthrough.tscn`.

| Reusable scene under res://scenes/ship/props/cargo_bay/ | Exact Scene-tree path | Position within CargoBayProps | Initial facing |
| --- | --- | --- | --- |
| electric_pallet_mover.tscn | BareShipWalkthrough/CargoBayProps/ElectricPalletMover | (263,173) | East (forks right) |
| cargo_inspection_scale.tscn | BareShipWalkthrough/CargoBayProps/CargoInspectionScale | (363,147) | South (display front) |
| secured_cylinder_rack.tscn | BareShipWalkthrough/CargoBayProps/SecuredCylinderRack | (288,91) | South (restraint straps) |
| maintenance_trolley.tscn | BareShipWalkthrough/CargoBayProps/MaintenanceTrolley | (383,91) | South (drawers) |
| cargo_locker.tscn | BareShipWalkthrough/CargoBayProps/CargoLocker | (446,174) | West (door left) |
| tied_box_bundle.tscn | BareShipWalkthrough/CargoBayProps/TiedBoxBundle | (118,173) | As drawn |

These are starter placements: cylinders and trolley at the north wall, locker
by the east wall with its door toward the room, boxes in the southwest storage
area, and scale/pallet mover on the east side of the handling floor. The
central aisle and all four entrance approaches remain clear.

## Select, move, resize and change facing

1. Open `res://scenes/ship/bare_ship_walkthrough.tscn` in the 2D editor.
2. Expand **BareShipWalkthrough > CargoBayProps** in the Scene tree.
   Editable Children is already enabled for this collection instance. If it
   is ever disabled, right-click CargoBayProps and enable **Editable Children**.
3. Select one of the six named prop roots in the table. Zoom the 2D viewport out
   until the surrounding ship is visible. Use the Move tool and drag the prop,
   or edit **Node2D > Transform > Position**. Sprite, collision and markers move
   together. Save the walkthrough to keep a per-instance override.
4. Change **Artwork Scale** to resize only the artwork. Keep the root's
   Transform Scale at (1,1) and Rotation at zero. Adjust **Floor Footprint > Size,
   Side Size and Offset** separately if the physical base needs resizing.
   Side Size applies to the two side views. Collision Enabled toggles every
   footprint part.
5. Use **Direction** for supplied views. The bundle has one fixed perspective,
   so it has no direction dropdown. The locker also has an **Appearance**
   selector for the supplied intact/closed, intact/open and damaged/closed rows.
   These are artwork previews, not an opening or hiding mechanic.
6. The pallet mover's **Pallet Forks** group controls north/south/side fork
   lengths, widths, spacing and forward offsets. Side Offset X is the
   east-view distance; Y is the west-view distance.
7. For locker/box markers, use **Future Hiding Markers > Access Distance,
   Access Offset and Hide Offset**. Their Marker2D positions are generated from
   these properties; editing the marker node directly is overwritten by preview
   refresh.

Changing artwork scale never changes the footprint. Changing footprint settings
never scales the image or the root. Every view uses separately drawn artwork;
sprite/root rotation and flip remain zero/off.

## Collision and hiding preparation

- All solid bodies use collision layer 1, mask 0, matching existing furniture.
- Rack, trolley, locker and scale have editable chamfered floor bases, not
  collisions over their full visible height.
- The pallet mover has a separate body and two narrow fork shapes. Empty
  surrounding space is not filled by one large bounding rectangle.
- The bundle has three small projected crate footprints, retaining the notch
  between its front crates. It is still one movable prop.
- No reusable gameplay hiding system exists in this project. No new hiding,
  interaction or inventory mechanic was introduced.
- `BareShipWalkthrough/CargoBayProps/CargoLocker/AccessPoint` is on accessible
  floor to the left of the current locker. Its HidePoint is the future interior
  target; the cabinet remains solid.
- `BareShipWalkthrough/CargoBayProps/TiedBoxBundle/AccessPoint` is south of the
  bundle. Its HidePoint is behind the stack on clear floor. Both are reachable
  around the bundle. Markers are preparation only; there is no new E action.
- Existing wall-art/geometry mismatches from the Valkyrie swap are unchanged.

## Asset inspection and explicit crops

The six original PNGs retain their filenames and locations under
`res://art/concepts/cargo_bay_props/`. Every PNG is 8-bit RGBA. The gray halos
visible against black in the source preview have zero or very low alpha, rather
than being opaque baked backgrounds. Crop bounds include the hardware and a
small edge allowance. Nearest filtering is set on each Sprite2D. The generated
2D import files use lossless compression with no size limit.

Each sheet was inspected separately; the scale and rack side views use
West/East ordering, while the mover, trolley and locker use East/West ordering.
No equal-cell grid was used. Bounds below are explicit x,y,width,height on the
original sheet; floor anchors are local pixel coordinates within that crop.

The locker's open doors extend into neighboring rectangular crop bounds. Its
scene stores measured per-view outlines from connected hardware alpha, and a
small canvas shader clips neighboring sprite fragments while preserving a
1.25-pixel soft-edge allowance. This mask changes neither the PNG nor collision.
All handles, wheels, guards and open door panels were checked in rendered views.

### ElectricPalletMover

Source: `Pixel-art four-view electric pallet mover-2.png`, 1452×1083; 1,144,874 fully transparent pixels. Initial Artwork Scale: 0.1.

| Supplied view / appearance | Crop rectangle | Floor anchor in crop |
| --- | --- | --- |
| North (forks up) | (324,46,257,603) | (128,574) |
| South (forks down) | (921,30,224,641) | (113,300) |
| East (forks right) | (64,675,616,356) | (153,325) |
| West (forks left) | (773,675,616,356) | (513,325) |

### CargoInspectionScale

Source: `Cargo inspection weighing station atlas-1.png`, 1536×1024; 1,013,252 fully transparent pixels. Initial Artwork Scale: 0.115.

| Supplied view / appearance | Crop rectangle | Floor anchor in crop |
| --- | --- | --- |
| North (display rear) | (154,47,460,483) | (230,358) |
| South (display front) | (923,54,459,476) | (229,351) |
| West (display left) | (75,628,638,343) | (319,272) |
| East (display right) | (823,629,638,342) | (319,271) |

### SecuredCylinderRack

Source: `Four-view industrial cylinder rack sprite sheet-3.png`, 1536×1024; 947,078 fully transparent pixels. Initial Artwork Scale: 0.11.

| Supplied view / appearance | Crop rectangle | Floor anchor in crop |
| --- | --- | --- |
| North (cross-braced rear) | (166,48,557,420) | (279,394) |
| South (restraint straps) | (822,48,549,420) | (275,394) |
| West (cylinders left) | (336,526,255,441) | (127,414) |
| East (cylinders right) | (938,526,256,441) | (128,414) |

### MaintenanceTrolley

Source: `Four-view cargo maintenance trolley-4.png`, 1536×1024; 899,517 fully transparent pixels. Initial Artwork Scale: 0.09.

| Supplied view / appearance | Crop rectangle | Floor anchor in crop |
| --- | --- | --- |
| North (rear panel) | (122,19,583,474) | (290,442) |
| South (drawers) | (844,27,585,466) | (292,434) |
| East (push-handle end) | (332,507,289,471) | (144,439) |
| West (plain end) | (931,507,291,471) | (146,439) |

### CargoLocker

Source: `locker-handle-slim.png`, 1448×1086; 771,689 fully transparent pixels. Initial Artwork Scale: 0.145.

| Supplied view / appearance | Crop rectangle | Floor anchor in crop |
| --- | --- | --- |
| North (rear) / Intact - Closed | (162,13,205,350) | (102,327) |
| South (door front) / Intact - Closed | (495,13,209,350) | (105,327) |
| East (door right) / Intact - Closed | (810,13,181,350) | (89,327) |
| West (door left) / Intact - Closed | (1077,13,187,351) | (93,327) |
| North (rear) / Intact - Open | (162,338,265,379) | (102,356) |
| South (door front) / Intact - Open | (434,361,271,356) | (166,333) |
| East (door right) / Intact - Open | (809,361,224,356) | (90,333) |
| West (door left) / Intact - Open | (1046,339,235,378) | (124,355) |
| North (rear) / Damaged - Closed | (161,720,206,357) | (103,334) |
| South (door front) / Damaged - Closed | (495,720,210,357) | (105,334) |
| East (door right) / Damaged - Closed | (809,720,183,357) | (90,334) |
| West (door left) / Damaged - Closed | (1080,720,189,357) | (90,334) |

### TiedBoxBundle

Source: `Three-crate pixel-art cargo bundle.png`, 1263×1246; 672,353 fully transparent pixels. Initial Artwork Scale: 0.07.

| Supplied view / appearance | Crop rectangle | Floor anchor in crop |
| --- | --- | --- |
| As drawn | (129,65,1005,1141) | (502,970) |

The tied-box bundle supplies one perspective only. No additional directions or
states were invented. The other five assets supply four views. Only the locker
supplies extra open/damaged rows; the other props use their supplied intact view.

## Validation and capture

- Launched the playable walkthrough through **Godot MCP**.
- Ran the MCP-compatible validation scene, which instantiates the real
  walkthrough and writes captures without saving game state.
- Final rendered validation: **PASS — 435 checks, zero failures**.
- All 29 supplied direction/appearance combinations were rendered and checked:
  crops, root/sprite transforms, filtering, floor anchors, Inspector labels and
  independent artwork/footprint scale.
- Also loaded all 29 combinations in Godot editor mode with Engine editor hint
  enabled: editor preview checks passed.
- Solid shapes were detected with the player's collision query; disabling
  collision disabled all body/fork/crate shapes.
- Pixel comparisons using the actual player confirmed occlusion behind and full
  foreground drawing in front of every prop. Transparent antialiasing is
  excluded from the opaque-player comparison.
- Floor/collision path search and physical player movement checked both north
  door approaches, the west dogleg, the south entrance, locker access, bundle
  access and the space behind the bundle.
- Footprints remained on the original floor and outside existing door trigger
  rectangles.
- Before/after hashes and a scene-text comparison confirmed preservation of
  existing assets, manual placements and unrelated files.

Run again through MCP with scene
`res://tools/cargo_bay_validation.tscn`, or launch that validation scene from
Godot. It exits after its checks. In-memory test placements, door states,
temporary player poses and preview viewports are not saved.

Captures and a machine-readable report are in
`res://.godot/cargo_validation/` (ignored by Git):

- `cargo_bay_gameplay.png`: normal gameplay zoom and HUD.
- `cargo_bay_close.png`: clear room view at 2.7×.
- `<PropName>_views.png`: per-prop artwork contact sheets.
- `<PropName>_front.png` / `_behind.png`: actual-player sorting checks.
- `report.json`: check totals, routes, placements and sorting results.

Existing project GDScript warnings and the Windows certificate/global editor
settings/shutdown diagnostics are unrelated to these props. Final cargo runtime
checks are recorded separately in report.json.

## Files added or changed

- Modified only `res://scenes/ship/bare_ship_walkthrough.tscn`: one resource,
  one CargoBayProps instance and its Editable Children entry.
- Added `res://scenes/ship/props/cargo_bay_props.tscn`.
- Added the six reusable scenes listed above and
  `res://scenes/ship/props/cargo_bay/cargo_bay_prop.tscn`.
- Added `res://scripts/ship/cargo_bay_prop.gd` and its UID.
- Added `res://shaders/cargo_atlas_clip.gdshader` and its UID.
- Generated six PNG import metadata files alongside the provided cargo PNGs.
  Original PNG bytes are unchanged.
- Added `res://tools/validate_cargo_bay.gd` (and UID),
  `res://tools/cargo_bay_validation.tscn`, and this README.

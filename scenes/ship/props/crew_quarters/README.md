# Crew living quarters furniture

The reference map's **05 crew_quarters** corresponds to the western portion of
the current **R07 mid-left compartment**, below the bridge corridor and above
hydroponics. The current floor is a continuous compartment toward the reference
mess hall. This integration adds no partition and changes no floor or walls.

Collection: `res://scenes/ship/props/crew_living_quarter_props.tscn`.
It is instanced at `(300, 450)` in
`res://scenes/ship/bare_ship_walkthrough.tscn`, with Editable Children enabled.
There was no existing quarters furniture collection to reuse.

## Editing in the full walkthrough

1. Open `bare_ship_walkthrough.tscn` in the 2D editor. Expand
   `CrewLivingQuarterProps` in the Scene tree. Select the **named prop root**,
   rather than its Sprite2D or collision child. If the tree is collapsed, expand
   it; Editable Children is already enabled on this collection instance.
2. Drag that prop's move gizmo, or edit **Node2D > Transform > Position** in the
   Inspector. Positions are relative to the collection. Sprite and collision
   move together. Save the walkthrough to retain your instance overrides.
3. Change **Artwork Scale** on the prop's script properties to resize its artwork.
   Keep root **Scale = (1, 1)** and **Rotation = 0**. Artwork Scale intentionally
   does not resize collision. If making a substantial size change, also adjust
   **Floor Footprint > Size / Side Size** and **Offset**, in world units.
4. Use **Direction** for a supplied alternate view. It updates the atlas region,
   floor anchor, and the appropriate footprint size in the editor. The bed has
   only one approved view, so no Direction control is shown. The table's views
   use descriptive orientation names because its nearly symmetrical drawings
   do not establish reliable north/south identities.
5. Use **Debug > Visible Collision Shapes** when running to check the footprint.
   Size applies to views 0/1; Side Size applies to views 2/3. Chairs use an oval
   base; other props use a rectangle with an adjustable Corner Cut. Offset moves
   only the collision relative to the stable floor anchor.

Drag any of these concrete scenes from the FileSystem dock into another room:

| Scene under `res://scenes/ship/props/crew_quarters/` | Artwork Scale | Supplied views |
| --- | ---: | --- |
| `stacked_capsule_bed.tscn` | 0.075 | Fixed south-facing entrances |
| `personal_computer_desk.tscn` | 0.11 | North rear, South front, West screen-left, East screen-right |
| `blue_crew_chair.tscn` | 0.08 | North rear, South front, West seat-left, East seat-right |
| `communal_table_with_plant.tscn` | 0.12 | Horizontal A/B, Vertical A/B |
| `storage_cabinet.tscn` | 0.12 | North rear, South doors, East handles-right, West handles-left |
| `three_drawer_chest.tscn` | 0.085 | North rear, South drawers, East drawers-right, West drawers-left |

`crew_quarters_prop.tscn` is the shared implementation base, not an additional
furniture type. All six scenes inherit it and use
`res://scripts/ship/crew_quarters_prop.gd`. They use nearest filtering locally,
solid collision layer 1, and root Z = 3 to match the existing player and shared
walkthrough Y-sorting. Each instance owns its mutable collision shape. No
interaction, state, lighting, sleeping, sitting, storage or hiding behavior is
added. Only the supplied intact artwork is used; no sprite is rotated/flipped.

The approved bed remains one intact sprite and one body with one shared floor
footprint. Its rectangular frame, bedding, ladder and perspective are unaltered.

## Starter instance positions

Local coordinates are relative to `CrewLivingQuarterProps`; world coordinates
include its `(300,450)` offset. These are initial positions for later adjustment.

| Instance | Local Position | World Position | View |
| --- | --- | --- | --- |
| `StackedCapsuleUnit` | 44,118 | 344,568 | Fixed supplied view |
| `PersonalComputerDesk` | 158,28 | 458,478 | South |
| `DeskChair` | 158,63 | 458,513 | North |
| `CommunalTable` | 185,124 | 485,574 | Horizontal A |
| `TableChairNorth` | 185,88 | 485,538 | South |
| `TableChairSouth` | 185,161 | 485,611 | North |
| `TableChairWest` | 127,128 | 427,578 | East |
| `TableChairEast` | 243,128 | 543,578 | West |
| `StorageCabinet` | 268,43 | 568,493 | South |
| `ThreeDrawerChest` | 98,30 | 398,480 | South |
| `StorageCabinet02` | 308,43 | 608,493 | South |
| `StorageCabinet03` | 48,17 | 348,467 | South |
| `StorageCabinet04` | 208,32 | 508,482 | South |
| `ThreeDrawerChest02` | 127,63 | 427,513 | South |
| `StackedCapsuleUnit02` | 91,158 | 391,608 | Fixed supplied view |
| `StackedCapsuleUnit03` | 282,158 | 582,608 | Fixed supplied view |
| `StackedCapsuleUnit04` | 330,158 | 630,608 | Fixed supplied view |

The expanded arrangement contains four wardrobes, two drawer chests and four
stacked capsule units (17 furniture instances total). The three additional beds
use Artwork Scale `0.07` and Footprint Size `(36,12)` to fit the available bays;
the original bed and all other original placements/settings are unchanged.

## Inspected artwork and atlas measurements

All six original PNGs remain in
`res://art/concepts/crew_living_quarter_props/`, unchanged. Each is RGBA with
genuine transparent background (including alpha-zero corners), not a baked
checkerboard. They contain intact views only, with no alternate damage/state
rows. Low-alpha outer halos are omitted from the tight regions where practical
and never define collision. Bounds were measured separately for every view,
with two source pixels of edge padding around alpha >= 128 coverage; every
pixel at that alpha threshold is covered. Sheet halves are not uniform cells.

Rectangles below are `(x, y, width, height)` in source pixels. Floor anchors are
`(x,y)` **relative to the crop's top-left**, marking the center of the floor base
rather than the center of the tall sprite. Artwork Scale is applied around that
anchor. Changing view or artwork scale leaves the root floor point fixed.

| Source PNG | Dimensions |
| --- | --- |
| `Sleeping Pod With Continuous Right-Side Ladder.png` | 1024 x 1536 |
| `Four-view crew work desk sprite.png` | 1536 x 1024 |
| `Blue crew chair, four orthographic views.png` | 1536 x 1024 |
| `Four-view crew table with potted plant.png` | 1536 x 1024 |
| `Four-Way Crew Wardrobe Sprite Sheet.png` | 1536 x 1024 |
| `Four-direction crew quarters drawer chest.png` | 1536 x 1024 |

| Prop / view | Atlas rectangle | Floor anchor |
| --- | --- | --- |
| Bed fixed | 194,99,637,1312 | 322,1216 |
| Desk North | 162,133,507,288 | 253,211 |
| Desk South | 868,133,506,288 | 253,211 |
| Desk West | 307,540,261,336 | 132,259 |
| Desk East | 984,540,245,336 | 122,259 |
| Chair North | 310,106,282,364 | 142,324 |
| Chair South | 945,101,282,369 | 139,329 |
| Chair West | 329,565,269,376 | 121,335 |
| Chair East | 939,565,269,376 | 145,335 |
| Table Horizontal A | 181,167,502,248 | 251,178 |
| Table Horizontal B | 856,167,500,248 | 251,178 |
| Table Vertical A | 339,551,192,345 | 95,267 |
| Table Vertical B | 1006,552,192,344 | 96,266 |
| Cabinet North | 386,35,307,425 | 154,360 |
| Cabinet South | 843,35,308,425 | 154,360 |
| Cabinet East | 472,526,164,438 | 81,374 |
| Cabinet West | 901,526,163,438 | 81,374 |
| Chest North | 223,85,450,359 | 225,285 |
| Chest South | 864,85,449,359 | 223,285 |
| Chest East | 350,510,224,406 | 110,334 |
| Chest West | 962,509,225,407 | 113,335 |

## Validation

`res://tools/validate_crew_living_quarters.gd` checks all 21 crops, opacity
coverage, editor property labels, per-instance collision independence, anchor
stability under resizing/view changes, root transforms, collection editability,
solid furniture and non-overlap. It flood-fills the actual player footprint
over the existing floor mask from the north entrance staging area to 17 access
points, including the bed, all table seats and the south exit staging area.

Run with Godot `--path . --script tools/validate_crew_living_quarters.gd`.
Add `--resolution 1280x720 -- --render` for rendered front/behind checks across
all six prop types and screenshots under
`res://.godot/crew_quarters_validation/`. The render harness only temporarily
positions the player/camera in memory; it does not save walkthrough overrides.

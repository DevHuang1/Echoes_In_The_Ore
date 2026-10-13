# Mission-planning table

Reusable scene: `res://scenes/ship/props/mission_planning_table.tscn`.
Approved source: `art/concepts/bridge_room_props/Pixel-art mission planning table sprite sheet.png`.
This is the low flat ship deck-plan table shown in the supplied crop; the separate
Mission Map Table sheet instead depicts a tall navigation/star-map cabinet.

The 1774 x 887 PNG has real alpha transparency. Visually inspected columns are
North/horizontal rear (no lower-edge controls), South/horizontal front (buttons
on lower edge), East/vertical controls on right, West/vertical controls on left.
The top row is Operational; the bottom row is Damaged with cracked screens and
housings. Explicit crops use alpha >= 8/255 bounds with two pixels of padding:

| Direction | Operational x,y,w,h | Damaged x,y,w,h |
| --- | --- | --- |
| North | 27,142,500,241 | 27,547,500,245 |
| South | 587,142,510,241 | 583,548,515,244 |
| East | 1150,81,216,331 | 1150,497,216,329 |
| West | 1509,81,214,332 | 1508,497,218,329 |

Inspector controls preview immediately: Direction, State, Artwork Scale, and
Floor Footprint North South Size / East West Size / Corner Cut / Offset. Defaults
are artwork scale 0.13, horizontal footprint (58,16), vertical footprint (22,16),
and corner cut 3. Every instance owns its collision. Leave root scale (1,1) and
rotation zero. Use actual directional artwork without rotating/flipping it.
Artwork sizing never changes collision; per-view/state anchors preserve the
floor center and a consistent lower base tip.

`MissionPlanningTable` is added once to BridgeRoomProps, North/Operational, at
local (214,347.565), world floor anchor (221,359.565). Its 65 x 31.33 world-unit
artwork has its visible center exactly at (221,353), the center of the red circle
in the full supplied screenshot (camera center 200,345, zoom 3, 1280 x 720).
The floor anchor sits slightly below the visible center because of the cabinet's
front face. Existing console/chair placements and all walkthrough overrides are
preserved. No chairs were added around the table.

In the walkthrough, expand the editable BridgeRoomProps children and select
MissionPlanningTable. Change Position for placement and Artwork Scale for visible
size. Change Floor Footprint separately for collision. Save the walkthrough to
retain instance overrides. Nearest filtering and existing Z=3 Y-sorting apply.
The table is decorative solid furniture, without mission interaction or lights.

Validation: `godot --headless --path . --script tools/validate_mission_planning_table.gd`.
Omit --headless and append `-- --render` for overlap checks and screenshots under
`.godot/mission_table_validation/`. Checks cover all eight crops, state/view anchors,
separate art/collision sizing, one table and unchanged chair count, circle-center
placement, no solid overlaps, player-sized walking routes, two-sided collision,
and rendered sorting. For manual checks, enable Debug > Visible Collision Shapes
and walk around the table and above/below it before fine-tuning placement.

# Flight-control station

Drag `res://scenes/ship/props/flight_control_station.tscn` into BridgeRoomProps.
The original project sheet matches the supplied attachment exactly; no duplicate
texture was copied from the Desktop folder.

Select the root in the Inspector to choose Direction (North rear, South front,
East right, West left), State (Operational or Malfunctioning), Artwork Scale,
and Floor Footprint dimensions/offset. All preview in the editor. Keep root scale
(1,1) and rotation zero. Artwork size is independent of floor collision.
Nearest filtering, solid collision, and existing Z=3 Y-sorting are used; there
are no interactions, hiding behaviors, or lights.

The 1774 x 887 RGBA sheet has low-alpha background artifacts. Crops enclose every
pixel at alpha >= 8/255 with two pixels of padding and use separate floor anchors:

| Direction | Operational x,y,w,h | Malfunctioning x,y,w,h |
| --- | --- | --- |
| North | 28,94,440,315 | 28,503,440,319 |
| South | 500,84,603,340 | 500,497,603,340 |
| East | 1131,82,289,324 | 1129,493,291,326 |
| West | 1456,82,289,324 | 1458,493,287,326 |

UpperFlightControlStation replaces the navigation instance and inherits its
saved local position (221,265), world (228,277). It faces South into the room.
LowerFlightControlStation is North-facing at local (221,435), world (228,447),
showing its rear from the room. The bridge offset (7,12) and both manually placed
diagonal consoles are retained. The original navigation scene remains reusable.

Use Editable Children on BridgeRoomProps in the walkthrough to fine-tune placement
or save Inspector overrides. Adjust the root Floor Footprint controls rather than
the generated CollisionShape2D dimensions. Default artwork scale is 0.12;
footprints are 52 x 18 for North/South and 28 x 18 for East/West.

Validation: `godot --headless --path . --script tools/validate_flight_control_station.gd`.
For rendered overlap checks and bridge screenshots, omit --headless and append
`-- --render`. Screenshots are saved to `.godot/flight_station_validation/`.
Walk around both stations with Debug > Visible Collision Shapes enabled; check
front/behind overlap, central-route clearance, scale, and all eight view/state
combinations before refining placement.

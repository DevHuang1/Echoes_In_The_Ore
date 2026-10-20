# Captain's chair

Reusable scene: `res://scenes/ship/props/captain_chair.tscn`.
Source: `art/concepts/bridge_room_props/Four-way captain's chair sprite sheet.png`.
The 1536 x 1024 RGBA sheet was visually inspected: the intact top-row views are
North/rear, South/front, East/right-facing side, West/left-facing side. The damaged
bottom row is unused. Sprites are independently drawn, never rotated or flipped.

| Direction | Atlas rectangle x,y,w,h | Crop-relative floor anchor |
| --- | --- | --- |
| North | 19,52,385,419 | 193,371 |
| South | 406,52,357,419 | 178,371 |
| East | 815,52,303,419 | 152,371 |
| West | 1181,52,303,419 | 154,371 |

Crops use measured opaque-alpha body bounds (alpha >= 128/255), plus two pixels.
They exclude the sheet's broad faint glow and every damaged view. Anchors refer
to the pedestal floor center, rather than the backrest or image center.

Root Inspector controls preview in the editor:

- **Direction:** North, South, East, West.
- **Artwork Scale:** default 0.065; visible chair height is about 27 world units.
- **Floor Footprint / Size:** default (16,6), a convex oval over the pedestal feet.
- **Offset:** move collision independently of the root/artwork.

Keep root scale (1,1) and rotation zero. Use these properties rather than editing
the generated CollisionShape2D points. Each instance owns its collision shape.
Nearest filtering and the existing Z=3 Y-sorting are used. Chairs remain solid
decorations without sitting, interaction, or lights.

Three instances are appended to BridgeRoomProps, preserving its (7,12) walkthrough
offset and every existing console override:

| Instance | Direction | Local position | World position |
| --- | --- | --- | --- |
| UpperStationChair | North, rear shown | 224,311 | 231,323 |
| MainHelmChair | West, left-facing side | 144,347 | 151,359 |
| LowerStationChair | South, front shown | 217,394 | 224,406 |

In the walkthrough, expand the editable BridgeRoomProps children and select a
chair. Adjust Position for placement and Artwork Scale for visible size; adjust
Floor Footprint separately if the base size changes. Save the walkthrough to
retain its instance overrides. The player art and movement are untouched.

Validation: run `godot --headless --path . --script tools/validate_captain_chairs.gd`.
Omit --headless and append `-- --render` to test rendered overlap and save
`.godot/chair_validation/bridge_chairs.png`. Checks include direction mapping,
intact crops, stable anchors, separate collision sizing, instance count, no
collision overlaps, player-sized walking routes around each chair, and sorting.
For manual checks, enable Debug > Visible Collision Shapes, walk around each
pedestal and approach the consoles, then fine-tune Position and Artwork Scale.

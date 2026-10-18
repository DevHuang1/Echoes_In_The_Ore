# Diagonal flight-control console

Reusable scene: `res://scenes/ship/props/diagonal_flight_console.tscn`.
The source is `art/concepts/bridge_room_props/diagonal-flight-console-v2.png`.
NE/NW show the corrected solid cabinet backs; SE/SW show the twin throttles and
displays. The previous source PNG remains in its original location.

Select the console root in the Inspector:

- **Direction:** Northeast, Northwest, Southeast, Southwest. These use the four
  real diagonal views, in left-to-right sheet order; the sprite never rotates.
- **State:** Operational (top row) or Malfunctioning (bottom row).
- **Artwork Scale:** sprite size only. Default 0.17 produces approximately
  65–73 world units of width, depending on view. Per-view/state normalization
  preserves the previous world widths and saved Artwork Scale adjustments while
  accommodating the new crop sizes. It uses uniform scaling, without distortion.
- **Floor Footprint / Length, Depth, Offset:** independent world-unit controls.
  Defaults are length 60, depth 12, offset (0,0). The generated convex polygon
  projects along the cabinet's +/-30-degree ground-plane axes. It excludes the
  large empty corners of an axis-aligned bounding box.

All selectors and dimensions preview in the editor. Keep root scale (1,1) and
rotation zero. Adjust the footprint using these root properties rather than
editing its generated CollisionShape2D points, which refresh with selectors.
The floor-center anchor is fixed; artwork has per-crop offsets, and each instance
owns its collision shape. Filtering is nearest on this prop alone.

The original PNG is 1774 x 887 RGBA, with genuine transparency. It also contains
very low-alpha background specks. Each crop encloses all sprite pixels at alpha
8/255 or greater, with two pixels of padding; no uniform cell division is used.

| Direction | Operational x,y,w,h | Malfunctioning x,y,w,h |
| --- | --- | --- |
| Northeast | 36,58,395,380 | 36,465,397,384 |
| Northwest | 451,55,392,381 | 451,463,392,386 |
| Southeast | 875,49,427,386 | 875,456,428,389 |
| Southwest | 1336,49,421,386 | 1336,456,422,389 |

All eight floor anchors were updated for these crops. At Artwork Scale 0.17 the
base's lower tip remains 18.7 world units below the root in every view/state.
State changes preserve the artwork width and horizontal center as well.

The existing BridgeRoomProps collection contains two operational instances:

- `UpperBowFlightConsole`: (132,278), Southeast, controls facing into the room.
- `LowerBowFlightConsole`: (132,405), Northeast, controls facing into the room.

The collection and walkthrough already share Y sorting with the Z=3 player.
These props also use Z=3. No shared sorting or lighting settings were changed.
The walkthrough's saved NavigationConsole overrides remain intact. To fine-tune
positions or Inspector properties there, use its existing Editable Children setup
on BridgeRoomProps; changes save as walkthrough instance overrides.

Run validation with the installed Godot executable:

```sh
godot --headless --path . --script tools/validate_diagonal_flight_console.gd --log-file .godot/diagonal_validation.log
godot --path . --script tools/validate_diagonal_flight_console.gd --log-file .godot/diagonal_validation.log --audio-driver Dummy -- --render
```

Checks cover all eight crops, anchors, collision independence, diagonal corner
clearance, solid player collision, deck coverage, central route, and rendered
front/behind sorting. Rendered previews are saved under
`.godot/diagonal_console_validation/`, including `bridge_v2_operational.png`
and `bridge_v2_malfunctioning.png` showing the corrected lower cabinet back.

Manual checks: enable Debug > Visible Collision Shapes, walk around the end
housings and both sides, verify the player draws behind/above and in front/below,
then try every direction/state and tune artwork size separately from footprint.
The center and east entrance should stay clear. These remain decorative solid
furniture with no interaction, hiding, or new lights.

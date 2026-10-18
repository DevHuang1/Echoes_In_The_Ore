# Navigation console

Drag `navigation_console.tscn` into `BridgeRoomProps` in the ship walkthrough.
Select the console root in the Inspector:

- **Direction:** North, South, East, West. North is the flat rear panel;
  East faces screen-right and West faces screen-left.
- **State:** Operational or Malfunctioning.
- **Artwork Scale:** changes only the sprite. Default 0.12 gives a south-view
  cabinet approximately 65 x 49 world units.
- **Floor Footprint:** edit North South Size, East West Size, and Offset in
  world units. Defaults are 58 x 18 and 28 x 18, centered on the root.
  These controls update the visible CollisionShape2D in the editor. Edit these
  controls rather than its generated shape dimensions, which refresh with selectors.

The `@tool` script previews all selections in the editor. Leave root scale at
`(1, 1)` and rotation at zero. Its position is the center of the floor footprint.
Each view has an individual crop-relative floor anchor; state changes keep the
cabinet base stable. Each instance owns its collision shape independently.

The original RGBA PNG stays at
`art/concepts/bridge_room_props/Flat rear console panel redesign.png`.
It is 1774 x 887, with transparent background (alpha zero), not baked checkerboard.
Atlas regions use measured alpha bounds and nearest filtering on this sprite only.
No texture copying, direction rotation, interaction, hiding, or lights are used.

| Direction | Operational region x,y,w,h | Malfunctioning region x,y,w,h |
| --- | --- | --- |
| North | 46,31,488,404 | 46,449,487,414 |
| South | 557,31,540,405 | 555,449,540,404 |
| East | 1110,27,303,410 | 1110,450,297,393 |
| West | 1451,25,289,413 | 1449,451,293,394 |

`bridge_room_props.tscn` contains one south-facing operational console at world
`(200, 315)`. It leaves the bridge's east entrance and surrounding floor clear.
The walkthrough and bridge collection enable Y sorting. Player Z=3 was moved
from its sprite to its CharacterBody2D root, leaving the sprite's effective Z=3.
The console also uses Z=3, so their floor anchors determine overlap. Existing
room props remain at Z=0, walls at -1 and doors at -2. Existing light ranges
remain unchanged, including the player's exclusion from lights ending at Z=2.
Other levels using this console also need a shared Y-sorted ancestor with the player.

Validation commands (use the installed Godot executable):

```sh
godot --headless --path . --script tools/validate_navigation_console.gd --log-file .godot/console_validation.log
godot --path . --script tools/validate_navigation_console.gd --log-file .godot/console_validation.log --audio-driver Dummy -- --render
```

The second command tests actual rendered draw order and saves bridge previews
under `.godot/console_validation/`. Checks also cover all eight atlas bounds,
anchors, filtering, per-instance collision, player blocking, and adjacent routes.

Manual checks:

1. Run the walkthrough, dismiss the arrival briefing, and walk to the left bow.
2. Walk above and below the console: the player should disappear behind its
   cabinet above it and draw in front below it. Walk around both sides.
3. Enable **Debug > Visible Collision Shapes** and confirm only the cabinet's
   floor base blocks movement; keep enough clearance for the player's radius 8.
4. Switch all direction/state combinations in the Inspector. Confirm the floor
   anchor stays fixed and the collision changes width for the side views.
5. Check scale beside the player and the open east entrance. Adjust artwork
   scale and footprint dimensions separately when needed.

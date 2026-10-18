# Main helm console

Reusable scene: `res://scenes/ship/props/main_helm_console.tscn`.
Artwork: `art/concepts/bridge_room_props/Rotated twin-screen operational helm console.png`.
This is the single supplied overhead operational image: cyan displays on the left,
U-shaped yoke on the right, and vertical long axis. There are no invented states
or directions. The sprite is never rotated or flipped.

The original image is 1024 x 1536 RGBA. Alpha >= 8/255 cabinet bounds are
(244,130,578,1292); its much wider faint halo is retained visually but excluded
from collision. The floor-center anchor is source pixel (533,776).

The Inspector offers:

- **Artwork Scale:** default 0.058, approximately 34 x 75 world units of visible
  cabinet. Sprite scale changes independently of the unscaled root and collision.
- **Floor Footprint / Size:** default (28,66) world units.
- **Corner Cut:** default 8 world units, clipping the empty cabinet corners.
- **Offset:** moves only the footprint relative to the floor-center root.

All controls preview in the editor. Adjust these root properties instead of
the generated CollisionShape2D points. Every instance has an independent convex
shape. Keep root scale (1,1) and rotation zero. Nearest filtering and existing
Z=3 player/prop Y sorting apply. It is decorative solid furniture with no mission
interaction, hiding, or added lighting.

`MainHelmConsole` is appended once to BridgeRoomProps at local (101,335), world
(108,347) with the saved bridge offset (7,12). It sits inside the central bow
windows between the diagonal consoles. The yoke and clear operator route are
on its right. Existing room instances and their saved walkthrough overrides are
preserved. In the walkthrough, expand the editable BridgeRoomProps children and
move the helm using Position; use Artwork Scale for visible size and Floor
Footprint controls for solidity. Save the walkthrough to retain instance overrides.

Validation:

```sh
godot --headless --path . --script tools/validate_main_helm_console.gd --log-file .godot/main_helm_validation.log
godot --path . --script tools/validate_main_helm_console.gd --log-file .godot/main_helm_validation.log --audio-driver Dummy -- --render
```

The checks verify solid-alpha footprint edges, stable anchor when art scales,
independent collision, one instance, saved placements, deck coverage, no overlap
with neighboring furniture, right-side player access, central route, and rendered
player sorting. Screenshots are under `.godot/main_helm_validation/`.
For manual checks, enable Debug > Visible Collision Shapes, approach the yoke
from the right, walk above and below, and adjust size/footprint separately.

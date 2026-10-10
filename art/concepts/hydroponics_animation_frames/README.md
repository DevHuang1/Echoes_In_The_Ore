# Hydroponics prop animation frames

Each `*_sheet.png` is a transparent 2×2 sprite sheet. Read frames left-to-right across the top row, then left-to-right across the bottom row. Matching individually cropped PNGs are in each `*_frames/` folder.

The grow tray sequence is full light, slightly dimmed, recovering, then full power. Leaves sway subtly while the tray stays fixed. The other sheets provide four-frame loops for the seedling rack, nutrient pump, control console, potted herb, and wall herb shelf.

These are generated sprites wired into the ship map as separate animated nodes. `scenes/ship/props/hydroponics_room_props.tscn` places two grow trays, one seedling rack, a console, a nutrient pump, a wall herb shelf, and ten individually animated pots along the upper, lower, and right edges. The placement follows the supplied room reference and keeps the center floor and north and east door approaches open. The scene is instanced in `scenes/ship/bare_ship_walkthrough.tscn` in the lower-left hydroponics compartment.

Run `res://scenes/ship/hydroponics_room_preview.tscn` to view the room at close range using the same floor and wall textures as the playable map. `hydroponics_room_live_preview.gif` is a four-frame composite preview rendered from those map layers and the scene's individual sprite frames at the reference crop; each frame displays for 250 ms. Matching PNGs for the full-room frames are saved beside the GIF.

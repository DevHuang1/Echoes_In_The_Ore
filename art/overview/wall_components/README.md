# Reusable wall components

This kit contains transparent 2x PNG wall sprites and one drop-in Godot `Sprite2D` scene per sprite. Components are cropped from `art/overview/asteria_overview_walls_2x.png` and scaled to the original world size, so they stay aligned with the existing Asteria layout while retaining more texture detail when zoomed in.

## Component types

- Straight runs: short/long horizontal, vertical, and service-panel variants.
- Corners and joins: inner/outer corners, a T-junction, a service turn, and an open-passage pair.
- Ship structure: curved hull sections, a windowed bow segment, an aft hull cluster, and a vertical service spine.

Add a `.tscn` from `scenes/ship/wall_components/` to a level, or use the PNG directly. Each scene is centered on its sprite for straightforward rotation. The JSON manifest gives texture size, source rectangle, scene path, and component type. These are visual assets; add collision to match the specific level geometry.

Run `godot --headless --path . --script tools/prepare_wall_layer_hires.gd` to regenerate the aligned 2x wall layer from the original alpha mask and the detail pass. Then run `python3 tools/build_wall_component_kit.py` to regenerate the modular pieces from that layer.

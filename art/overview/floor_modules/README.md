# Asteria modular flooring

The floor-only source layer is `asteria_overview_floor.png` (1774 × 887, transparent outside the deck floors). This pack contains:

- 10 named room-floor modules.
- 17 connector/support floor modules covering every remaining floor pixel, including corridors and narrow passages.
- 10 reusable tile patches for metal panels, grates, markings, and corridors.
- A top-left-anchored Godot `Sprite2D` scene for every component under `scenes/ship/floor_modules/`.
- `floor_wall_alignment_preview.png` shows the extracted floor assembled under the wall-only layer.

The 30 room and connector/support modules are transparent, non-overlapping, and reassemble the source floor layer exactly at the positions in `floor_modules_manifest.json`. The 10 tile patches are additional crops for reuse and may overlap those modules. `Sprite2D` scenes are visual-only; define collision through the walls or level-specific collision shapes.

Run `python3 tools/split_floor_into_modules.py` to regenerate the modules, contact sheets, scenes, and ZIP pack from the full floor layer. The extraction used built-in imagegen to remove walls, contents, and starfield while preserving the floor plate art.

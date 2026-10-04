# Echoes in the Ore — visual concepts

These PNGs are visual-development references for the Godot 4 game. They are not yet imported into scenes or prepared as production runtime sprites/tiles.

- `../characters/spaceCharacter.png` — canonical character sheet supplied by the user. Keep these exact crew designs; Thura is the star-marked character at the upper left. Build his movement frames from this design.
- `../characters/thura_walk_cycle_reference.png` — four-pose downward-walk study made from the canonical Thura. It preserves the design and transparent background, but remains a visual reference; more distinct poses and other directions are still needed before import.
- `../characters/thura_walk_4dir_reference.png` — 4×4 movement study from the canonical Thura: rows face down, up, left, then right. Use this for directional pose reference; it still needs exact cell cleanup before Godot import.
- `asteria_crew_concepts.png` — original project copy of the same canonical six-crew-and-Echo sheet.
- `asteria_crew_sprite_draft.png` — bolder cast exploration based on the canonical sheet; not the production source.
- `thura_playable_sprite_concept.png` — alternate one-pose exploration; not the game's character design and not a source for production sprites.
- `thura_walk_4dir_atlas_draft.png` — rough walk-cycle contact sheet. Some side-facing poses are mixed and the cell alignment drifts, so use it as a motion reference rather than an import-ready atlas.
- `asteria_return_ship_layout.png` — overhead ship-room layout reference for blockout.

Thura's Myanmar background appears in small personal details: his mother's folded paper star and a restrained longyi-inspired woven cuff/cloth accent in his berth. The ship layout and crew designs are original; the Among Us reference is limited to clear top-down room navigation and readable task spaces.

Production animation target: four aligned walk frames in each direction plus one idle pose per direction. Add a separate short slither cycle for the Echo.

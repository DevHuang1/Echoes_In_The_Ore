# Echoes in the Ore — landing screen and Earth-years intro

The project opens on a landing screen. **Start** plays a 14-frame Earth-years prologue for Thura with slow image movement, fades, and typewriter subtitles; **Skip Intro** jumps directly to the existing ship walkthrough. At the end of the prologue, **Board Asteria-1** opens the walkthrough and presents Thura's Asteria-1 arrival briefing before movement begins. The walkthrough combines the transparent floor and wall layers with Thura's four-direction walking sprite. Movement is constrained to the visible deck by the floor layer's alpha mask.

## Run

Open `project.godot` in Godot 4.7.2 and press **F5**, or run from the project directory:

```sh
godot --path .
```

## Controls

- **Start** — begin Thura's prologue.
- **Space**, **Enter**, or **Next** — reveal the current subtitle, then advance to the next frame.
- **Enter the Ship**, **Space**, or **Enter** — dismiss the arrival briefing and begin moving.
- **Skip Intro** — open the ship walkthrough.
- **WASD** or **arrow keys** — walk in the ship walkthrough.

## Reusable ship art

- `art/overview/asteria_overview_floor.png` and `art/overview/asteria_overview_walls_2x.png` are the aligned full-layout layers used by the walkthrough. The 2× wall texture keeps the same world footprint and uses lossless import so its baked highlights and shadows stay crisp when the camera follows the astronaut.
- `art/overview/space_frames/` contains the forty looping, double-resolution starfield frames drawn behind the ship. The background covers the ship with overscan and drifts gently while the floor and hull stay fixed.
- `scenes/ship/floor_modules/` contains drop-in floor Sprite2D scenes; their source images and manifest are in `art/overview/floor_modules/`.
- `scenes/ship/wall_components/` contains drop-in wall Sprite2D scenes; their source images and notes are in `art/overview/wall_components/`.
- The original overview pieces remain in `art/overview/pieces/` with a manifest and layout guide.

Regenerate the assets with `tools/split_floor_into_modules.py`, `tools/prepare_wall_layer_hires.gd`, `tools/build_wall_component_kit.py`, `tools/build_space_backdrop_frames.gd`, and `tools/split_ship_overview.py`.

## Web export

The project uses the Compatibility renderer. A Web build can be exported with the `Web` preset after installing the matching Godot 4.7.2 export templates.

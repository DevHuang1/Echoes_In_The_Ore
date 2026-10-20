# Shared pixel GUI

`res://themes/ship_pixel_theme.tres` supplies the game's reusable pixel skin.
It is applied locally to UI roots, without changing room or gameplay resources.
`res://scripts/ui/pixel_ui.gd` applies it to procedural screens and supplies
padded frame styles and the square close control.

## Audited screens

| Area | Script | Coverage |
| --- | --- | --- |
| Landing | `res://scripts/ui/landing_screen.gd` | Title panel, Start, footer |
| Earth-years intro | `res://scripts/ui/earth_years_montage.gd` | Chapter, subtitles, progress, Show Text, Next, Skip, Board |
| Arrival | `res://scripts/ui/arrival_briefing.gd` | Welcome, mission cards, crew/duty text, Enter Ship |
| Crew dialogue | `res://scripts/ui/crew_dialogue.gd` | Speaker, typewriter text, advance/accept/decline hints |
| Service tasks | `res://scripts/ui/service_task_console.gd` | Power, filter removal/alignment/pressure, irrigation, disabled controls, completion, return/close |
| Walkthrough HUD | `res://scripts/ui/walk_hud.gd` | Inventory/loadout, drag preview/tooltips, settings/volume, blank map, menu buttons, mission/context display, markers, nine-slot hotbar |

The audit found six UI scene roots, with controls constructed by these scripts.
Existing story text, sequence/timing, task targets, completion signals, input
handlers, inventory/item data, and player movement gates are retained. Service
Return to Ship is placed in the footer so completion does not push the task
workspace out of the window.

## Shared skin

- Small code-authored SVG textures provide navy panels, steel/ivory stepped
  borders, amber hover/selection, and cyan slider fill. StyleBoxTexture preserves
  corners while stretching the middle. UI texture filtering is nearest.
- CloseButton is a square 48x48 steel frame with a separate cross glyph and
  amber hover/focus. Disabled buttons share a muted texture style.
- The authored 5x7 bitmap font includes ASCII, checkbox/check glyphs and the
  story/task punctuation, arrows and degree symbol. It needs no installed font.
- Text, items, diagrams, slots, sliders and buttons remain separate dynamic
  controls or live drawing. Full mockup screenshots are not the interface.
- Background story illustrations and all original reference PNGs are retained.
  The four references in `res://art/concepts/gui/` are unchanged.

## Blank ship map

The map uses only an AtlasTexture of the approved blank `Map.png` central frame:
`(20,112,1594,747)`. Title, close control and footer are live controls. Hidden
map markers have mouse filtering IGNORE and no keyboard focus. Underlying map
and task data, and the world service markers, remain available.

## Layout and behavior

Inventory retains 27 cargo cells, four compatible equipment slots and nine
quick slots, including transfer/swap checks, tooltips, number keys and wheel
selection. I opens inventory, M toggles map, and Escape closes HUD windows or
opens settings. Volume, modal focus, player pause/resume and service/dialogue
signals use their existing architecture.

The project retains canvas-items stretch and its 1280x720 design viewport.
A 1024x576 window scales this same logical viewport. Bitmap text wraps within
cards; service close controls retain their square dimensions. Intro frame bands
use viewport-relative layout.

## Validation

Run in a rendered Godot window:

```
Godot --path . --script tools/validate_pixel_gui.gd --audio-driver Dummy --resolution 1280x720
Godot --path . --script tools/validate_all_gui.gd --audio-driver Dummy --resolution 1280x720
```

The first suite checks actual viewport mouse/keyboard input for all HUD menu and
close buttons, hotbar cells and shortcuts, wheel wraparound, real inventory and
equipment drag/drop including invalid/occupied transfers, volume mute/max/drag/
keyboard input, focus, modal movement gates, blank-map input exclusion and text/
control bounds. Captures: `res://.godot/gui_validation/`.

The second suite runs the actual walkthrough, dismisses the arrival briefing,
exercises crew dialogue reveal/advance/accept/decline, completes all three service
tasks through real controls, tests every filter stage and disabled/enabled state,
checks completion and movement signals, tests square close and Escape, inspects
all 14 story frames, and exercises Start, Show Text, Next, Board and Skip scene
transitions. It checks control bounds, text fit and bitmap glyph coverage at
1280x720 and 1024x576. Captures: `res://.godot/all_gui_validation/`.

Both suites only modify in-memory game state. Screenshots and logs are ignored
under `.godot/`; no room files or player settings are saved by the tests.

## Latest validation and changed files

- Remaining-screen suite: PASS, 19,809 assertions, zero failures.
- Existing HUD suite: PASS, 627 assertions, zero failures.
- Both ran at 1280x720 and 1024x576. Captures were visually reviewed.
- Godot editor import completed with no script parse or compile errors.
- The existing Windows certificate-store diagnostic, sandbox restriction on
  saving global editor settings, and shutdown resource warnings still occur.
  Neither UI suite reported a UI runtime error.
- A before/after hash comparison confirmed all pre-existing room scenes,
  placements, gameplay scripts and unrelated import changes were preserved.

Files changed by this consistency pass:

- The six UI scripts listed in the audit table above.
- `res://scripts/ui/pixel_ui.gd` and its generated UID.
- `res://themes/ship_pixel_theme.tres` and this README.
- `res://art/ui/pixel/ore_pixel_font.fnt`,
  `res://art/ui/pixel/ore_pixel_font.svg`, and the font atlas's SVG import
  metadata (Godot marks this atlas as handled by the bitmap-font importer).
- `res://tools/validate_all_gui.gd` and its generated UID.

No room scene, original reference PNG, project configuration or gameplay-data
file was changed by this pass.

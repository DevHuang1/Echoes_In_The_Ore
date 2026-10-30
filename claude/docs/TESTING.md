# Testing and previews

All commands are run from the project root. `godot` = the Godot 4.7.2 binary.
- On Linux without a display, prefix rendering runs with `xvfb-run -a -s "-screen 0 1280x720x24"`.
- On Windows, just run them; omit `--headless` when a screenshot is taken.

## Rebuild the theme (after changing eito_theme.gd / eito_style.gd)

```
godot --headless --path . --script res://tools/build_eito_theme.gd -- assets
godot --headless --path . --import
godot --headless --path . --script res://tools/build_eito_theme.gd -- theme
```

## Preview screens

Redesigned phase-2 screens:

```
godot --path . --script res://tools/gui_preview.gd --resolution 1280x720 -- <kind> <out.png> [arg]
```

The `<kind>` values are:
- `landing`
- `intro [frame#]`
- `briefing`
- `hud`
- `inventory`
- `map`
- `settings`
- `dev`
- `prompt`
- `station <prop id>`, e.g. `station life.filter`, `station cargo.scale`, `station bridge.helm`
- `service <task>`, e.g. `service air_filter`

Phase-1 station screens in any state:

```
godot --path . --script res://tools/eito_preview.gd --resolution 1280x720 -- power|irrigation|records|dialogue <preset> <out.png> [seconds]
```

- `power` presets: `start`, `interlocked`, `working`, `verified`
- `irrigation` presets: `start`, `interlocked`, `power`, `working`, `verified`
- `records` presets: `start`, `wrong`, `right`
- `dialogue` presets: `maya`, `maya_more`, `amara`, `amara_long`, `amara_typing`, `amara_echo`, `ribbon`

## Validators and their last known results

Baseline is the user's original project before any redesign. Phase 1 is the state now in the game.

| Command | Baseline | After phase 1 |
|---|---|---|
| `godot --path . --script res://tools/validate_eito_flow.gd` (new) | — | PASS 26/0 |
| `godot --path . res://tools/ship_missions_validation.tscn` | 18 failures | 17 failures. All remaining come from the old air-filter console cascade, not the redesign |
| `godot --path . res://tools/first_watch_validation.tscn` | 17 checks / 1 failure | same (the existing route-walking failure near (228,126)→(231,349)) |
| `godot --path . res://tools/first_watch_recovery.tscn` | 278 / 4 | 278 / 4 |
| `godot --path . res://tools/ship_interactions_validation.tscn` | 673 / 0 | 673 / 0 |
| `godot --path . res://tools/ship_interface_validation.tscn` | timed out | 1262 / 2. The 2 need `rendered_return.json`, which ship_missions_rendered writes; run that first |
| `godot --path . res://tools/ship_interface_rollout_validation.tscn` | timed out | timed out |
| `godot --path . res://tools/ship_missions_rendered_validation.tscn` | 267 / 0 | 245 / 0 |
| `godot --path . --script res://tools/validate_all_gui.gd` | hung; with a 200 s watchdog, existing failures were "Button uses old style" ×28, dialogue accept, level completion ×3, service close square ×4, missing glyph ● | same set minus "Dialogue decline" |
| `godot --path . --script res://tools/validate_pixel_gui.gd` | not run yet | not run yet. Phase 2 needs its `StyleBoxTexture` hover check updated (HANDOFF section 5, step 4) |

The phase-2 WIP has **not** been run through these yet. Expected phase-2 breakages are only the two "old style" checks listed in HANDOFF section 5, step 4.

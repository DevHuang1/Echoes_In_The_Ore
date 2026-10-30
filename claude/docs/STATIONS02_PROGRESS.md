# Stations 02: Claude review of Codex's work (2026-10-30)

Read this together with `codex/docs/STATIONS02_HANDOFF.md`, which is Codex's handoff. This file records what Claude checked and changed after that handoff. Work stopped early because usage was running out.

## Checks that passed

These checks ran on a Linux copy of the project with Godot 4.7.2 and Xvfb, using the GL Compatibility renderer.

- **Pointer flow test** (`tools/validate_eito_flow.gd`):
  - 1280×720: `EITO FLOW: PASS (418 checks, 0 failures)`, exit code 0.
  - 1024×576 (`-- --small`): same result, exit code 0.
  - The Windows 1024×576 crash that Codex reported (exit code -1073741819 after the PASS line) **does not happen on Linux**. It is probably a Windows/GL shutdown fault rather than a game-code bug. It still needs one rerun on Windows.
- **Visual comparison of all 17 boards in their start state:** each native Godot render was compared with the artifact board, using `tools/eito_preview.gd <kind> start`.
  - Layout, materials, fonts and graphics match closely.
  - The remaining differences are the authorized live-data substitutions listed in `docs/stations02_mapping.md`. Examples: dashes where the game has no sensor, the blank planning schematic, live stock in the supply stores, and the turbine's read-only cooling lamp.

## Changes made (written back to the live project)

1. **`tools/validate_eito_flow.gd`**
   - Waits for `_ship_points_ready` (up to 20 s) before opening stations. On slower machines the first `_open("bridge.planning")` used to fail with "Invalid access to key 'bridge.planning'", and the whole run cascaded into failures.
   - Watchdog timeout raised from 150 s to 600 s, because slow machines timed out before finishing.
2. **Valve manifold gauges**
   - "BAR", "UPSTREAM" and "DOWNSTREAM" had been baked into the gauge textures in a serif fallback font.
   - The text was removed from the PNG and `.res` versions of `art/ui/eito/stations02/graphics/valve_{up,down}_gauge_base{,_dim}`.
   - `valve_manifold_panel.gd` `_gauge()` now draws those captions in Silkscreen.
3. **`communications_panel.gd`**
   - The protocol help text overflowed the bottom of its module. It now uses the artifact's shorter sentence.
   - Once Earth acknowledges, a stale "Waiting for relay acknowledgement…" or "Report due this watch." line in the feedback strip is replaced with "Earth relay acknowledged <id>."

The flow test was **not rerun after changes 2 and 3**. They are drawing-only changes, but rerun it to confirm.

## Not yet done (continue here)

1. Rerun `validate_eito_flow.gd` at both sizes on Windows. Check whether the 1024×576 shutdown crash still happens.
2. Capture and compare the non-start states (blocked, working, completed) for every board. The preset names are in `tools/eito_preview.gd` (`_apply_*`). This check was interrupted before it produced results.
   - Capture with: `godot --path . --script res://tools/eito_preview.gd -- <kind> <preset> <out.png> 1.5`
   - Look for text overflow, stale feedback, and wrong fonts in baked textures. Grep the other `stations02/graphics` textures for baked serif text, as the valve gauges had.
3. Recapture the pallet mover after Codex's `TROLLEY` label change. Its start state looked correct in this pass.
4. Run the story/mission/hiding validators that Codex lists as not rerun: `validate_first_watch`, `validate_ship_missions(_rendered)`, `validate_ship_interactions`, `validate_ship_interfaces`.
5. Play the real story once by hand. Codex's handoff (step 4) lists what to check.
6. Update the stale "148 checks" sentence in `docs/stations02_mapping.md` to 418.
7. Nothing is committed. Everything is still uncommitted on branch `kaung`, as Codex left it.

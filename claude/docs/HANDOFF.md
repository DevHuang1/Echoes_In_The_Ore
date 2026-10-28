# GUI redesign: handoff

Last updated: 2026-10-28 (Asia/Rangoon), by Claude.
Read this first, then `UI_KIT.md` (the code kit) and `TESTING.md` (how to check work).

## 1. What the user asked for

The game is **Echoes in the Ore**, a Godot 4.7 2D pixel-art survival/horror game in `C:\GodotProjects\Echoes_In_The_Ore`.

The reference design is the HTML artifact **"Echoes in the Ore UI"**. It lives in the claude.ai project "GUI Redesign" as `Echoes in the Ore UI.html`, and is also published at https://claude.ai/artifact/ApFc4H1iiz9xcbDz6FHcRB.

**Phase 1 (done, already in the game).** Replace the GUIs that the artifact shows, matching it 1:1:
- Auxiliary power panel
- Irrigation panel
- Crew records
- Dialogue: Amara in person; Maya and Leila over comms

The user said:
- Do **not** implement the artifact's "hiding" or "sleeping/rest" features.
- Leave the existing locker hiding alone.

**Phase 2 (in progress).** The user asked:

> "change the other GUIs that are not originally listed … map GUI, inventory, settings, other menus, and the GUI at the intro, etc. … apply the same theme from the design artifact and re-design them using appropriate graphic elements."

There is no artifact mockup for these screens. Build them in the same visual language:
- Notched metal plates with screws and stamped Silkscreen headers
- Bezel keycap buttons
- Paper push-caps for primary actions
- Recessed slot wells
- Phosphor glass screens
- Paper dossiers
- Status lamps
- Kbd keycaps
- Segmented cell meters
- Hazard tape
- Palette from `scripts/ui/eito/eito_ui.gd`

**Keep gameplay behaviour, signals, node names and member variables the same.** Validators and level code reach into them (see section 6).

**Phase 3 (design done, implementation is for the next agent).** The user asked for the remaining station GUIs (pallet mover, air duct, cargo scale, maintenance trolley, etc.) as a *design proposal only*, not built in the game. The design is the Design canvas **"Echoes in the Ore UI · Stations 02"**: https://claude.ai/artifact/8gftdt7Y13fgpS66G8qfHM (private to the user until shared).
- 19 clickable 1280×720 boards: Main (kit + index), then one per station: CargoScale, PalletMover, MaintenanceTrolley, CylinderRack, CargoBundle, SupplyStores, AirDuct, FilterCartridge, AirScrubber, OxygenRack, CoolantPump, Turbine, ValveManifold, HelmConsole, CommsStation, PlanningTable, NutrientPump, SeedlingRack.
- Every board uses the phase-1 layout: HUD on top, drawn equipment in the middle, the paper procedure card bottom-left (step, do, why, feedback lamp), controls bottom-right.
- Each board's script holds a `STEPS` list (id / do / why / ok text) and the wrong-order messages. Use it as the spec for step order and feedback text. Check it against `ship_mission_state.gd` before wiring: the design numbers (pressures, masses, 62–72% bands) come from the mission model where they exist and were invented where they don't.
- SupplyStores is storage only. It has no hiding, per the user's rule.
- Lab devices are not in the ship scene, so they have no board.
- The Turbine board has a "PUMP VERIFIED" button that only stands in for the coolant pump result. In the game that is a lamp, not a button.

**Aux power fix (done 2026-10-28, in the game).** Clicking the outbound power panel did nothing, because `ShipMissionState._gated()` rejected `diagnose` while the story/duty prerequisite was unmet. The fix:
- `_gated()`: outbound `power` and `hydro` skip the duty prerequisite. The panels keep their own step interlocks, as in the design.
- `ship_mission_walkthrough.gd`: the power-ack intercept, the "Hear engineering's reply" objective and the power-verify story hook now also require `amara.observation_reported`. `_ship_panel.story_mode` is off for power until then.
- Checked: a click run in the real level completes with and without story mode, real mouse clicks work at 1280×720 and 2000×1121, and `validate_eito_flow` passes 26/0.

## 2. Status at a glance

| Area | Script(s) | Status |
|---|---|---|
| Aux power / irrigation / crew records | `scripts/ui/eito/*_panel.gd`, `eito_layer.gd` | DONE, in the game |
| Dialogue (person + comms) | `scripts/ui/crew_dialogue.gd`, `eito/dialogue_screen.gd` | DONE, in the game |
| Story wiring (Leila comms card, objective ribbon, HUD hide in dialogue) | `scripts/ship/ship_mission_walkthrough.gd`, `bare_ship_walkthrough.gd` | DONE, in the game |
| Mission model changes (power plans, sync/align, crew answer) | `scripts/ship/ship_mission_state.gd` | DONE, in the game |
| Shared theme (all Control-based GUIs) | `eito/eito_style.gd`, `eito/eito_theme.gd`, `themes/*.tres` | WIP, built (see section 3) |
| Walking HUD: tracker, nav buttons, prompt, hotbar, task markers | `scripts/ui/walk_hud.gd` | WIP, built and rendered |
| Inventory, ship map, settings, dev menu | `scripts/ui/walk_hud.gd` | WIP, built and rendered |
| Title screen | `scripts/ui/landing_screen.gd` | WIP, built and rendered |
| Intro montage (Earth years) | `scripts/ui/earth_years_montage.gd` | WIP, built and rendered |
| Arrival briefing | `scripts/ui/arrival_briefing.gd` | WIP, built and rendered (paper dossier) |
| Generic station panel (cargo, life support, engines, helm, comms, planning, storage…) | `equipment_ui.gd`, `ship_procedure_panel.gd`, `ship_equipment_diagram.gd`, `ship_station_presentation.gd` | DESIGNED (Stations 02 canvas), NOT IMPLEMENTED |
| Service consoles (air filter, lab devices, return-phase power/irrigation) | `scripts/ui/service_task_console.gd` | Air filter DESIGNED (FilterCartridge board); rest NOT STARTED |
| Aux power panel not responding to clicks | `ship_mission_state.gd`, `ship_mission_walkthrough.gd` | FIXED 2026-10-28 |
| Validators updated for the new look | `tools/validate_pixel_gui.gd`, `tools/validate_all_gui.gd` | DONE (style/font checks accept EitoStyle and FontVariation); not yet run |
| Write phase-2 files into the live game folder | — | DONE 2026-10-28 19:05: installed into the live project; `claude/wip/` is now just a backup copy |

Screenshots of the phase-2 WIP renders and of the finished phase-1 screens are in `claude/docs/screenshots/`.

## 3. Where the phase-2 work is

**Update 2026-10-28 19:05:** at the user's request, the phase-2 files below are now installed in the live project. `claude/wip/` keeps an identical backup. Skip the copy step and just run the import/editor scan.

All phase-2 changes are mirrored under `claude/wip/` at the same relative paths. `claude/.gdignore` makes Godot skip that folder, so it doesn't clash with live scripts or class names.

To continue, copy everything from `claude/wip/` over the project root, keeping paths. Then:
1. Open the project in the Godot editor once, or run `godot --headless --path . --import`. This registers the new global classes `EitoStyle` and `EitoControls` and imports the knob PNGs.
2. If the theme looks wrong, rebuild it (see `TESTING.md` → "Rebuild the theme").

Files in `claude/wip/`:

```
art/ui/eito/fader_knob.png(.import), fader_knob_hover.png(.import)   NEW  slider knob art
scripts/ui/eito/eito_ui.gd            MODIFIED  @tool; painter takes any canvas (RidCanvas adapter);
                                                textures tile by hand; draw_lamp() moved here
scripts/ui/eito/eito_style.gd(.uid)   NEW  class_name EitoStyle (scriptable StyleBox)
scripts/ui/eito/eito_theme.gd(.uid)   NEW  builds the shared Theme
scripts/ui/eito/eito_controls.gd(.uid) NEW class_name EitoControls (Plate, Lamp, Keycap, Cells, Hazard, label(), stamp(), panel())
themes/ship_pixel_theme.tres          REGENERATED (keeps uid://cojsd52dev885)
themes/eito_body_font.tres            NEW  Pixelify Sans Medium, ligatures off, bitmap-font fallback
themes/eito_label_font.tres           NEW  Silkscreen +1px tracking, fallbacks
scripts/ui/pixel_ui.gd                MODIFIED  panel() returns StyleBox (was StyleBoxTexture)
scripts/ui/walk_hud.gd                MODIFIED  HUD/inventory/map/settings/dev redesign
scripts/ui/landing_screen.gd          MODIFIED  title screen redesign
scripts/ui/earth_years_montage.gd     MODIFIED  intro chrome redesign (+ _set_progress helper)
scripts/ui/arrival_briefing.gd        MODIFIED  paper dossier redesign
tools/build_eito_theme.gd(.uid)       NEW  regenerates fonts/knob/theme
tools/gui_preview.gd(.uid)            NEW  renders any screen to PNG for review
```

Phase-2 status of these files:
- **Parse-checked and rendered:** landing, intro, briefing, HUD, inventory, map, settings, dev menu.
- **Not yet run:** the validators. Expect two known failures (section 5, step 4).

## 4. What each redesigned phase-2 screen does now

- **Watch log (HUD tracker)**
  - `EitoControls.Plate` "WATCH LOG" with a stamped header strip.
  - Phosphor mission count, and a segmented ProgressBar drawn as cells.
  - Work-order rows: Silkscreen amber tag + Pixelify title + status.
  - In story mode the single objective's title moves to its own 20px line (`set_story_objective`).
  - `_fit_story_tracker` sizes to min height, at most 296px. A validator needs ≤ 300.
- **Nav buttons**: bezel keycaps with the pixel icon, a Silkscreen title and a `Keycap` for M / I / Esc / F3.
- **Interaction prompt**: notched dark chip + `Keycap("E")` + 17px text.
- **Hotbar**: module plate. InventorySlot wells; the selected slot gets a CUE border and corner brackets.
- **World task marker**: notched chip with a pulsing warn lamp, cue brackets and a stem (`TaskLocationMarker._draw`).
- **Modals** (inventory, map, settings): dimmer + screwed module plate, stamped title, square `CloseButton`.
- **Inventory**: operator on phosphor glass (with a suit "cells" meter), cargo in a bezel, quick access with a `1-9` keycap, footer keycaps.
- **Map**: glass viewport with the `MapScreen` phosphor grid, a sweep line and "DECK CHART NOT LOADED".
  - Map content stays disabled: `MAP_CONTENT_VISIBLE=false`, and there is no TextureRect, as the validator requires.
  - The legend uses lamps.
- **Settings**:
  - Audio bezel: slider (track + phosphor cells + paper knob) with the value on a small glass readout.
  - Controls bezel with keycaps.
- **Dev menu**: module plate with hazard tape, amber stamped title, themed keycap buttons.
- **Title screen**:
  - Hero art on the left.
  - Right side: screwed plate "ASTERIA-1 / FLIGHT DECK" with a live lamp chip, a 60px stamped title, and a phosphor status screen.
  - Paper push-caps "CONTINUE WATCH" / "START A NEW WATCH" ("BEGIN EXPEDITION" when there is no save).
- **Intro montage**:
  - Top: dark notched chip strip with a live lamp and "SKIP DOSSIER" keycap.
  - Bottom: screwed caption plate. Amber chapter stamp, phosphor counter, 22px typewriter text, "PROCEED" push-cap, and a thin phosphor progress line above the plate.
  - Button texts lost their `[ … → ]` brackets.
- **Arrival briefing**:
  - Paper dossier with ink text.
  - "MISSION BRIEFING" ink badge, three phosphor glass cards, "ENTER SHIP DECK" push-cap with an Enter keycap.

## 5. Remaining work, in order

1. **Install `claude/wip/` and import** (section 3). Render every screen with `tools/gui_preview.gd` to confirm it still matches the screenshots.
2. **Generic station panel.** Build each station to its board in the Stations 02 canvas (Phase 3 above). The notes below still apply to the shared plumbing.
   - `scripts/ui/equipment_ui.gd` builds its own Theme with StyleBoxFlat (`theme()`, `box()`). Replace it with `preload("res://scripts/ui/eito/eito_theme.gd").build()` plus tweaks, or `EitoStyle.make(...)`.
   - Restyle the inner classes:
     - `Readout`: glass well, Silkscreen heading, phosphor value, `Cells`-style meter.
     - `SegmentedMeter`
     - `Lamp`: use `EitoControls.Lamp` sprites.
     - `Chassis`: screws.
   - In `ship_procedure_panel.gd`:
     - frame → screwed module (`EitoStyle.make("module", 16, true)`)
     - header → stamped Silkscreen title
     - stage tabs → keycaps; active = `key_active`, which already gives an amber underline when `toggle_mode` is pressed
     - feedback strip → dark strip with a lamp, like `eito_screen.procedure()`'s feedback
     - records → paper
     - footer → keycaps "Tab" / "Esc"
   - In `ship_equipment_diagram.gd`, recolour to phosphor-on-glass (PHOS / PHOS_DIM / PHOS_FAINT, WARN/FAULT for alerts).
   - **Keep these exactly**, because validators use them: `_controls[...].button`, `_condition.caption.text` ("VERIFIED", etc.), `_metrics[i].reading.text`, `_tabs` children named `PAGE+"Tab"`, `_select_stage`, `_select_record`, `reveal_action`, `_pages`, `_stage`, `ProcedureFrame` node name, `Close` button name.
   - The procedure panel opens for every station the artifact didn't cover. Power/irrigation/records in the outbound phase use the phase-1 screens instead.
3. **Service consoles** (`scripts/ui/service_task_console.gd`, about 1900 lines).
   - Palette constants at the top → design palette (as in walk_hud).
   - `_panel_style()` → EitoStyle bezel/well/glass.
   - Header badge, sidebar task cards (`SKIN.panel(.., inset, active)` already maps to slot styles), footer.
   - Diagram classes `PowerDiagram`, `FilterDiagram`, `NutrientDiagram`, `LabStationDisplay` → glass + phosphor colours.
   - **Keep:**
     - `_close_button` exactly **48×48** with variation `CloseButton`: `validate_all_gui` checks it.
     - The `_return_button` and `_power_*` / `_filter_*` / `_nutrient_*` members.
4. **Validators.**
   - `tools/validate_pixel_gui.gd:93` checks `get_theme_stylebox("hover") is StyleBoxTexture`. Change to `is StyleBox`, or `get_script()==EitoStyle`.
   - `tools/validate_all_gui.gd` `_layout()`:
     - It checks Buttons for `StyleBoxTexture` ("Button uses old style") and Labels for `font == SKIN.THEME.default_font`.
     - Update both for EitoStyle and type-variation fonts. Labels now use `EitoTag` (Silkscreen) as well as the default font.
     - Its "Missing bitmap glyph" check calls `font.has_char`. Make sure fallbacks count, or check with `TextServer`.
   - Then run everything in `TESTING.md` and compare with the baseline numbers there.
5. **Write back** all changed files to the live folder. Tell the user what changed, then clear `claude/wip/`.
6. Optional polish:
   - Settings has empty space at the bottom of the controls bezel.
   - The map close keycaps sit inside the legend flow.
   - The landing title uses Pixelify's "Ɛ"-style E.

## 6. Contracts you must not break

- **Walk HUD** (`walk_hud.gd`). These members are used by validators and the level:
  - `_root`, `_mission_panel` (size.y ≤ 300 in story mode), `_context_label`
  - `_hotbar_slots`, `_storage_cells`, `_equipment_cells`, `_inventory_hotbar_cells` (all `WalkHud.InventoryCell`)
  - `_overlay_nodes`, `_modal_frames`, `_active_overlay`
  - `_map_surface` (no TextureRect children), `_map_player_marker`, `_map_task_markers`
  - `_volume_slider`, `_volume_label` (text "NN%"), `_dev_panel`, `_toggle_dev_menu`, `_world_task_markers`, `_walking_visible`
  - Node names: `TopRightControls/SHIPMAP|INVENTORY|SETTINGS`, `Close` (square, `CloseButton`).
  - The dev button text "TEST RETURN".
  - `_mission_stack` must keep its first 3 children (heading, progress bar, subheading). `set_ship_objectives` deletes the rest.
- **Landing, intro, briefing** members: `_start_button`, `_continue_button`, `_skip_button`, `_next_button`, `_fade_overlay`, `_transitioning`, `_finished`, `_is_subtitle_typing`, `_frame_index`.
- **Dialogue** (`crew_dialogue.gd`). Keep:
  - `class_name CrewDialogue`
  - signals `dialogue_finished`, `conversation_finished`
  - `start_dialogue(lines, offer, context{id,speaker,choices,objective})`, `cancel_dialogue()`, `flash_objective()`
  - fields `_active`, `phase`, `choices`, `_lines`, `_index`, `_generation`, `_continue_choice`
- **Mission model** (`ship_mission_state.gd`): the outbound rules are in `POWER_PLANS`, `POWER_MIN`, `VERIFY_SECONDS`, the `sync`/`align` actions, and crew answer `one_missing`. Return phase unchanged.
- **Do not implement** hiding or rest/sleep from the artifact.

## 7. Environment notes

- The project was worked on in a Linux container using Godot 4.7.2 (headless + Xvfb for screenshots). The user's machine is Windows. Files reach it through the Claude desktop bridge.
- Fonts in `art/ui/fonts/`: Pixelify Sans Medium and Silkscreen, bundled under the Open Font License.
  - VT323 is not installed. The phase-1 kit falls back to a condensed system monospace.
  - If the user adds `VT323-Regular.ttf` and the full Pixelify Sans files, `eito_ui.font()` picks them up automatically. The theme `.tres` fonts use only the bundled files.
- The fonts' "fi"/"fl" ligatures are turned off on purpose: they rendered as "A" ("Aow" for "flow").
- `EitoStyle` / `EitoControls` use `class_name`. After adding them, the editor (or `--import`) must refresh the global class cache before scripts that reference the class names compile.
- The project's GDScript treats `:=` from Variant as an error. Type values pulled from Dictionaries explicitly.

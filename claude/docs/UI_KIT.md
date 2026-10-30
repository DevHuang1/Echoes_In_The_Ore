# Design-language UI kit (`scripts/ui/eito/`)

Everything visual comes from one painter, so the phase-1 screens and the restyled Godot Controls share the same materials and type.

## Files

- **`eito_ui.gd`**: the base kit (static functions).
  - Palette constants: `VOID BULK HULL HULL_2 HULL_HI HULL_LO EDGE LABEL GLASS GLASS_2 PHOS PHOS_DIM PHOS_FAINT PAPER PAPER_HI PAPER_LO INK INK_2 OK WARN FAULT LIVE WATER WATER_HI CUE VOICE VOICE_HI VOICE_INK TEXT`.
  - Fonts: `font(kind, weight, letter_spacing)`. Kinds are `"body"` (Pixelify Sans), `"label"` (Silkscreen) and `"num"` (VT323, or the fallback).
  - Text: `text()`, `paragraph()`, `wrap_text()`, `tw()`.
  - Box painter: `box(ci, rect, {notch, bg, grad, hgrad, tex, border, bw, insets, outer})`. It is a port of the artifact's CSS: stepped notch corners, gradients, the noise texture, 2px border, inset bevels.
  - Material presets: `metal_module`, `bezel`, `paper`, `glass` (+ `glass_overlay`).
  - Generated sprites through `tex(name)`:
    - `screw`, `lock`, `lockA`
    - lamps `l_ok|warn|fault|live|off`, with glows `g_*`
    - icons
    - `noise`, `paper`
    - portraits `face_*` / `bust_*`
  - `draw_lamp(ci, pos, state, now)`.
  - `ci` can be any CanvasItem, or a `RidCanvas` wrapping an RID. That is how StyleBoxes use the painter.
- **`eito_screen.gd`**: base Control for the phase-1 immediate-mode screens: a 1280×720 stage, hit regions, keyboard focus. Its helpers:
  - `module()`, `push()`, `tagbtn()`, `kbd()`, `lamp()`, `hud()`
  - `procedure()`: the paper step card + feedback strip
  - `drawer()`, `comms_card()`, `ribbon()`, `cell_row()`, `hazard()`, `cue()`
- **`eito_layer.gd`**: CanvasLayer host for the phase-1 station screens. Same API as the old procedure panel.
- **`eito_style.gd`** (`class_name EitoStyle`): a scriptable `StyleBox`.
  - `EitoStyle.make(kind, margin, screws, accent)`.
  - Kinds:
    - Materials: `module` (screws optional), `bezel`, `well`, `glass` (with scanlines), `paper`, `chip`, `voice`
    - Keycaps: `key`, `key_hover`, `key_down`, `key_active` (amber underline, used for pressed/toggled), `key_off`
    - Paper push-caps: `push`, `push_hover`, `push_down`, `push_off`
    - `close`, `close_hover`
    - Slots: `slot`, `slot_hover`, `slot_selected` (CUE border + corner brackets)
    - `focus` (CUE ring), `rule`, `track`, `fill`, `cells`, `none`
  - `EitoStyle.paint(ci, rect, kind)` lets a custom `_draw` paint the same material.
- **`eito_theme.gd`**: `build()` returns the shared Theme.
  - Type variations:
    - PanelContainer: `EitoModule` (screwed), `EitoBezel`, `EitoWell`, `EitoGlass`, `EitoPaper`, `EitoChip`, `EitoVoice`
    - Button: `PushButton` (paper push-cap, Silkscreen dark text), `KeyButton` (= default Button), `CloseButton`
    - Label: `EitoTag` (Silkscreen 14, label grey-green), `EitoAmber`, `EitoValue` (phosphor), `EitoInk` (on paper), `EitoTitle` (28), `EitoHint`
  - It also styles: InventorySlot, MapViewport (glass), Tooltip, HSeparator (rule), HSlider (track + phosphor cells + paper knob), ProgressBar (track + cells), LineEdit/TextEdit (well, phosphor text), ItemList, PopupMenu, scrollbars, RichTextLabel.
- **`eito_controls.gd`** (`class_name EitoControls`):
  - `Plate`: PanelContainer with a stamped header strip, optional chip + lamp, and screws. Content sits below the header.
  - `Lamp`, `Keycap`, `Cells`, `Hazard`.
  - Helpers `label(text, role, size, color)`, `stamp(label)` (2px dark drop shadow, as in the artifact) and `panel(material, margin)`.
- **Phase-1 screens**: `power_panel.gd`, `irrigation_panel.gd`, `crew_records_panel.gd`, `dialogue_screen.gd`.

## Theme file

`themes/ship_pixel_theme.tres` is generated; don't hand-edit it.
- Every older screen preloads it, either directly or through `scripts/ui/pixel_ui.gd`.
- Regenerate it after changing `eito_theme.gd` or `eito_style.gd`. See TESTING.md.
- It keeps its UID `uid://cojsd52dev885`.

## Typical restyle recipe for an old Control-built screen

```gdscript
const EC := preload("res://scripts/ui/eito/eito_controls.gd")
const ESTYLE := preload("res://scripts/ui/eito/eito_style.gd")
panel.add_theme_stylebox_override("panel", ESTYLE.make("module", 20, true))  # screwed plate
var title := EC.stamp(EC.label("CARGO HOLD", "EitoTag", 16))               # stamped header
button.theme_type_variation = &"PushButton"                                 # primary action
row.add_child(EC.Keycap.new("Esc")); row.add_child(EC.Lamp.new("ok"))
```

Conventions used so far:
- Silkscreen caps for tags, keys and section headers.
- Pixelify for sentences and values: body 15–17, titles 20–36.
- Phosphor (PHOS) for live readings.
- Amber (WARN) only for warnings, pending states and accent tags.
- CUE (#fff2b8) for selection and focus.
- No `[ … → ]` bracket decorations on buttons.

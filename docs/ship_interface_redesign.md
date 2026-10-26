# Ship equipment interface rollout

Baseline: `kaung`, `747a1dcd6cc72be4bbaaeb976e0af01d3c67ed17`.
Nine existing edits are preserved under `.godot/ui_restyle_baseline/` with SHA256
hashes for every tracked file. No commit, push, merge or geometry edit is in scope.

## Visual specification

The interface is the face of a shipboard instrument: a bolted grey housing around
recessed blue-green displays, short labelled controls, and visible instrument
connections. Equipment and measured condition lead; operating stages follow;
procedures, records and history are secondary pages. No reference screenshot is
embedded and no depicted cable is a wire-joining puzzle.

Palette: housing #89969a, housing shadow #303e43, instrument #101f25,
ivory #eee7d3, muted text #a5b7bb, cyan #68dce5, amber #edb953, fault #f17c71.
Signal colours always accompany words, numeric values or component positions.
Use the existing bitmap font, nearest filtering, integer-aligned drawn detail,
12px utility text, 14px body/control text, 20px titles, 24px primary readings.
Native Controls remain individually live; reusable drawing renders only the
housing, lamps, segmented meters and connected equipment schematics.

Measured contrast against instrument #101f25: ivory 13.66:1, muted text 8.11:1,
cyan 10.41:1, amber 9.37:1, fault 6.32:1. The metal housing was lightened after
review so its dark utility labels also meet the small-text contrast threshold.

Regular and compact widths share the same capabilities:

```
1280x720 / 1024x576
+-- station identity / watch context / condition / square close --------+
| EQUIPMENT                       | INSPECT | SERVICE | VERIFY          |
| primary live readouts           | prominent stage                    |
|                                 | short controls + selectors          |
| task-specific connected diagram | one shared prerequisite notice      |
| condition / observation timer   | individual interlock tooltips       |
|---------------- RECORDS / PROCEDURE / REPORT -------------------------|
| latest command result                            ESC closes           |
+---------------------------------------------------------------------+
```

Keep supported 1280x720 and 1024x576 layouts readable, with explicit focus and
hover/pressed states. Restore focus and unsubmitted selector values through
model refresh. No extra game-state owner or save-schema change.

Review principles used: local Apple design skill foundations only, translated
to desktop Godot game controls. `feedback.md > Best practices` supports status
near equipment; `buttons.md > Style` supports a clear primary action;
`keyboards.md > Best practices` supports keyboard access. Platform-specific
Apple window appearances do not define this game's art direction.

## Completion checklist

- [x] Read brief, six references, project guides, UI/model/owner and validators.
- [x] Record Git and byte-level preservation baseline.
- [x] Shared metal housing, controls, lamps, meters, stages, notices, tooltips.
- [x] Breaker cabinet complete and rendered review; compact defects corrected.
- [x] Power: buses, allocations, voltage, bank state and isolation controls.
- [x] Cargo: scale/container, identity, mass/tolerance, seal/custody, supplies.
- [x] Engines: connected loops, four turbines, load/flow/temp/pressure, service.
- [x] Life: scrubber/filter/airflow, O2/CO2, reserve and service verification.
- [x] Hydro: reservoir/manifold/growing circuit, EC/flow/environment/recovery.
- [x] Bridge: duties/evidence, navigation, report/protocol/acknowledgement.
- [x] Quarters: roster/check-ins, storage and conditional rest.
- [x] Original three service interfaces match the instrument system.
- [x] Both sizes inspected for every group, blocked/active/completed samples.
- [x] Input, cancel/reopen, focus, transfers, save/load and original tasks pass.
- [x] Existing mission/physical/rendered validators pass without weakened checks.
- [x] Final preservation audit, changed-file list and evidence report.

## Progress log

- Inspection: current procedure screen is two scrolling text/action columns;
  original service tasks have useful diagrams but oversized fixed frame/sidebar.
  Preserve the existing state/action APIs, inventory owner and original games.
- Design: reusable native instrument components and per-room schematics, with
  stage pages and separate records. Original task callbacks and ranges remain.
- Breaker foundation: normal-renderer screenshots inspected at both sizes.
  Corrected compact observation clipping and abbreviated selectors while keeping
  full option explanations in tooltips. Real mouse actions isolated the service
  circuit and changed allocation; original bank controls completed. Detailed
  result logging/remaining rollout verification follows; screenshot creation
  alone is never counted as visual approval.

- First complete rollout: both sequences passed 1,353 inherited/extended rendered checks with no failures.
- Original regressions: 271 state/save and 663 physical checks passed, normal OpenGL, exit 0.
- All-host access audit found a keyboard-focus loss when numeric widgets rebuilt. Restoring focus by action identity (including the SpinBox child editor) fixed it; 1,249 focused checks then passed.
- Visual review: inspected all seven room groups at 1280x720 and 1024x576. Adjusted engine pressure spacing, compact hints, status lamps, one-control stage width, and return-roster wording. The bank completion footer now fits the smaller window.

- Final completion audit: 271 state/save checks (exit 0 on final normal retry), 663 physical checks, 1,361 focused UI checks, and 1,473 inherited/extended rendered checks, all zero assertions failed. Final headless editor import exited 0 with no blocking errors.
- Final rendered review: all seven room groups and bridge/navigation/transmission/storage/evidence/report plus the original service games inspected at both supported sizes. Source and screenshot hashes are in ship_interface_validation.json.
- Applied selector values now reflect saved quarantine/crew/protocol decisions; crew status uses duty ID crew rather than room ID quarters. Secondary records tabs show the current selection.
- Native limitation audit: a normal shutdown/reload crash reproduced with pre-redesign scripts at 0xc0000005 / 0x321fccb. The redesigned build also completed the full state/save retry with exit 0. The pre-existing native reload issue remains documented and is not hidden by a skipped test or engine upgrade.
- Preservation: all nine baseline local edits exact; HUD, original validators, project settings, artwork and saved room scenes unchanged. No commit/push/merge performed.

# First-watch acceptance evidence

The approved five-mission first-watch chapter and all four existing hiding
instances are implemented. This report separates actual input traversal, recovery
fixtures, rendering, process exits and preservation.

## Tests actually run

Godot 4.7.2 Compatibility / NVIDIA OpenGL; captures at 1280x720 and 1024x576.
All saves are isolated under `.godot/mission_validation/`.

| Suite | Assertions | Failures | Process exit |
|---|---:|---:|---:|
| chapter | 549 | 0 | 0 |
| intro checkpoint | 6 | 0 | 0 |
| cold intro continue | 14 | 0 | -1073741819 |
| full intro | 10 | 0 | 0 |
| continue roster | 10 | 0 | 0 |
| continue power | 10 | 0 | 0 |
| continue complete | 10 | 0 | -1073741819 |
| hiding each instance | 268 | 0 | 0 |
| cue dialogue recovery | 123 | 0 | 0 |
| maintenance state | 271 | 0 | 0 |
| maintenance physical | 673 | 0 | 0 |
| maintenance interface | 1361 | 0 | 0 |
| maintenance rendered | 1473 | 0 | 0 |

Total: **4778 behavioral assertions, zero failures**. A native process
exit is recorded honestly even if all assertions and reports completed first.
The known intermittent native shutdown/reload fault is `0xc0000005` at offset
`0x321fccb`, matching the previous interface validation record. No engine upgrade
or unrelated renderer change was made.

## What the evidence proves

- The chapter suite starts through actual landing/montage input, then walks
  traversable routes with normal player and NPC physics. It accepts/declines Maya,
  reviews the roster, holds Amara still for 9.2 seconds through the real lock,
  observes/reports, operates the original capacitor/manifold controls, verifies,
  reports back and receives the production text acknowledgement. No completed
  flag injection or fixture NPC freeze proves this route. Actual walking:
  **6233.0 pixels**.
- New-story unselected systems are healthy without service signoffs; only roster,
  power and irrigation have technical results. The five story missions complete
  with no all-eight-duty report and no correction chemical transaction.
- Separate processes stop during the live intro, then Continue at its safe opening
  frame. Full/skip converge on the same arrival objective. Intro receipts persist
  before boarding, request tokens change on resume, and the saved scene spawn is
  validated before a live actor position replaces the pending-spawn marker.
- Fresh-process Continue preserves roster, power and completed stages, inventory,
  equipment and validated position. New Start preserves an older campaign byte
  for byte. Version-1 saves stay maintenance contexts with their actual progress.
- Recovery fixtures verify reachable conversations outside hydroponics, cancel /
  reopen, stale replies, inventory plus dialogue ownership, current healthy and
  regressed readings, retained repair history, and optional observations before
  the still-unrepaired irrigation duty.
- Cue fixtures verify missing resources/actors, node exit, failed/cancelled/complete/
  skipped outcomes, duplicate/stale tokens, old briefing dismissals after reload,
  pending arrival/handoff recovery, an accelerated actual 90-second watchdog,
  invalid landing and full camera/input restoration. The real montage adapter
  is also exercised; fixture signals/cameras are not invented cinematic content.
- Both ordinary airlock input and the walk-through boundary stay guarded in story
  mode, including after handoff. The explicit development missing-scene fixture
  intentionally logs a resource error, then proves controls/transit metadata recover.
- The original maintenance state, physical, interface and two-context rendered
  suites retain their behavioral assertions. Hiding assertions now wait for real
  asynchronous phases; fully blocked loads assert recoverable refusal instead of
  the audited unsafe distant-position fallback.

## Hiding results, per instance

All paths start at `BareShipWalkthrough`. The four instances are independently
reserved and preserve their saved transform, art direction/scale and footprint.

| Stable ID | Existing node | Result |
|---|---|---|
| `cargo.locker` | `CargoBayProps/CargoLocker` | WEST open/closed door artwork, full portal route, safe connected exit. |
| `engine.locker.1` | `EngineRoomProps/LockerUpper` | Same shared behavior and independent occupancy. |
| `engine.locker.2` | `EngineRoomProps/LockerLower` | Same behavior; saved `(233,179)` override preserved. |
| `cargo.bundle` | `CargoBayProps/TiedBoxBundle` | Full-size route around sealed crate bodies to genuine behind-stack cover. |

Each is tested against a thin external entry/exit wall, occupied reservation and
real character body, normal / partially blocked / fully blocked exit, repeated
entry/exit, actual Hide/Q inputs, new obstacles during transitions, inventory while
concealed, hidden load and an obstructed saved exit. No wall ejection, body shrink,
crate removal or unsupported open/damaged artwork is used. A traversal interruption
can stop visibly on clear outside floor or safely concealed inside a cabinet.
The bundle cover probe temporarily reveals the unchanged standing sprite at the
actual pocket; existing crate artwork/Y-sorting covers it. No new squeeze pose is
claimed. Compatible enemy evasion remains unimplemented.

## Preservation and changed files

Protected artwork, room/prop scenes, audio, project settings and import metadata:
**804 files, zero changes**. No baseline file is missing.
Existing user save files are unchanged. The detailed JSON contains aggregate
protection hashes, exact changed/new paths and current runtime/test source hashes.
No furniture, floor, wall, door geometry or manual instance override was resaved.

Runtime changes are confined to the existing walkthrough/model, Amara, supported
hiding exports, dialogue/intro/arrival/landing/HUD and station presentation, plus
the two data-only story/save helpers. Validation tools and narrative/play guides
supply the remaining files. `6a4d431` is the user-requested WIP checkpoint; these
follow-up fixes are local and uncommitted.

## Reproduce and play

Use F5 normally, Start or Continue, then follow the one primary objective. The
[play guide](ship_missions_playguide.md) has the five missions, original equipment
solutions, optional/required distinction and hiding controls. Fixtures are separate
from production saves. Run `res://tools/first_watch_validation.tscn` for the input
chapter; run `res://tools/first_watch_recovery.tscn -- --mode=contracts` for recovery.
Other modes: `intro_checkpoint`, `restart_intro`, `restart_roster`, `restart_power`,
`restart_complete`, `hiding`; the main runner also supports `intro_full`. Run the
chapter / intro producer before their cold-restart consumers.

Later dependencies remain teammate cinematics/voices, approved incident and crew
presence facts, survey deployment/shared surface persistence, and compatible enemy
perception/survival rules. Desk/table/wardrobe/capsule hiding still needs eligibility,
space, pose and occlusion assets. The chapter ends at survey briefing pending.

## Representative captures

![Amara report-back and primary objective](C:/GodotProjects/Echoes_In_The_Ore/.godot/first_watch_validation/screenshots/amara_repair_report_1024x576.png)

![Completed five-mission chapter](C:/GodotProjects/Echoes_In_The_Ore/.godot/first_watch_validation/screenshots/chapter_complete_1280x720.png)

![WEST cargo locker during actual entry](C:/GodotProjects/Echoes_In_The_Ore/.godot/first_watch_validation/screenshots/cargo_locker_door_open_1280x720.png)

![Safe pending-intro Continue checkpoint](C:/GodotProjects/Echoes_In_The_Ore/.godot/first_watch_validation/screenshots/continue_intro_1024x576.png)

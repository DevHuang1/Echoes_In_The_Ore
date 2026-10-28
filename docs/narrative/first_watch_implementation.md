# First-watch implementation and evidence

Scope: the approved five-mission chapter, reliable Amara conversations, versioned
story persistence/Continue, the four existing hiding instances, and minimal
intro/arrival/command-handoff cue handling. No incident, Echo, enemy AI, ending,
new cinematic production or surface rewrite.

## Baseline and ownership

Started from `kaung` at `eaf38ccd994146fc48b91c5cfff55cf4a4c15467` (2026-10-27).
Only the four narrative audit documents were initially untracked. Exact hashes
and backups cover 951 tracked files plus those documents in the ignored
`.godot/first_watch_baseline/`. The user subsequently requested the WIP checkpoint
commit/push `6a4d431`; follow-up fixes remain local. No merge/reset was performed.

BareShipWalkthrough remains the interaction/progression owner, WalkHud owns the
inventory/equipment, and ShipMissionState owns equipment truth. FirstWatchStory
and ShipStorySave are data/validation helpers, not new global managers.

## Implementation

- [x] Reconcile the four audits, original guides, source and saved scene baseline.
- [x] Five ordered mission receipts and explicit scoped technical work orders.
- [x] Maya/Leila terminal text, contextual Amara conversation and one primary HUD objective.
- [x] Versioned saves, conservative v1 migration and minimal landing Continue.
- [x] Three WEST lockers: supplied door states, portal-only transitions and safe recovery.
- [x] Cargo stack: full-size walk-around route to the existing covered pocket.
- [x] Intro/arrival/handoff cue receipts, production text acknowledgement and departure guards.
- [x] Actual-input chapter traversal, fresh-process Continue and full maintenance regressions.
- [x] Final rendered/evidence reconciliation and preservation audit.

The normal chapter is `chapter.asteria.first_watch`:

| Mission | Required result |
|---|---|
| `story.a1.010_watch_briefing` | Accept Maya's scoped watch; compare quarters roster/watch records. |
| `story.a1.020_meet_amara` | Introduction, real hydro readings/diagnosis and explicit observation report. |
| `story.a1.030_aux_service` | Original bank controls, safe allocation/isolation, restored science feed, stable verification and Leila's acknowledgement. |
| `story.a1.040_irrigation_report` | Actual manifold repair, restoration, stable verification and explicit healthy report to Amara. |
| `story.a1.050_watch_handoff` | Measured before/after summary and Maya's production terminal-text acknowledgement. |

Only power and irrigation are required equipment repairs. New-story life support,
cooling and navigation readings begin in range without invented completed-duty
flags. The old eight-duty maintenance graph and return scenario remain explicit
development/legacy contexts. Useful observations can precede assignment. Tool,
isolation, labelled controls, stock transactions and stable verification remain.
Normal EC does not consume correction chemical. Optional observations cannot
replace irrigation or enlarge the five-mission denominator.

Maya and Leila are identified terminal text; no physical actor, portrait or voice
was invented. Amara remains MED. Dialogue holds a named interaction lock for its
entire duration, preserves patrol/path timers, cancels safely and works at actual
reachable locations outside hydroponics. Story mode gives conversation priority;
legacy maintenance retains station/optional-job selection behavior. Barks and
report-back follow current readings while preserving earned repair history.

## Hiding, per instance

All scene paths begin at `BareShipWalkthrough` and retain the saved transforms,
artwork scales, geometry, floor anchors and stable IDs.

| ID | Existing node | Result |
|---|---|---|
| `cargo.locker` | `CargoBayProps/CargoLocker` | WEST-only entry, intact open/closed sprites, reserved interior, connected WEST exit. |
| `engine.locker.1` | `EngineRoomProps/LockerUpper` | Same shared behavior, independent occupancy; original upper placement preserved. |
| `engine.locker.2` | `EngineRoomProps/LockerLower` | Same behavior; the saved `(233,179)` instance override is preserved. |
| `cargo.bundle` | `CargoBayProps/TiedBoxBundle` | Walks around the sealed stack into the existing behind-stack cover pocket; all three crate bodies remain respected. |

Outside → entering → concealed → exiting is explicit. Only the entrant's narrow
WEST cabinet portal/interior crossing can exclude that cabinet's bodies. External
solids, closed doors and character occupancy remain checked over each full route.
The cabinet stays solid to other actors. Repeated entry cannot reserve twice.
Q reverses the route already traversed. Inventory remains usable without unlocking
movement. Fully blocked exits remain concealed and retryable; partial endpoints
use connected alternatives. An interrupted traversal may stop visible on clear
outside floor, or concealed inside a cabinet; it cannot eject through a wall.
Hidden saves load safely outside only through a validated connected exit. A fully
blocked restoration is refused before changing live state or inventory.

Open/damaged combinations with no supplied artwork are refused. Desk/table,
wardrobe and capsule hiding remain unimplemented: they need approved eligibility,
space, entry/crouch pose and occlusion assets. No compatible enemy AI exists, so
concealment signals/group/metadata do not establish evasion or invulnerability.

## Persistence and cues

Version-2 outer/model snapshots add a versioned story section; existing boolean
flag dictionaries stay boolean. v1 saves preserve technical progress, inventory,
equipment and partial controls in maintenance context without invented chapter or
cinematic receipts. JSON numeric versions are validated numerically, including
cold reads where Godot returns floats. Writes use a temporary file and atomic
rename. New campaigns choose another filename when a campaign already exists.
Continue reads a validated current-campaign pointer/default/legacy save.

The existing montage and briefing are preserved. Request tokens identify cue
attempts; complete/skip share one authored result, failure/cancel grant none,
and stale/duplicate callbacks cannot apply it. Camera currentness, bounds, position,
offset, zoom, smoothing and aggregate input/NPC locks are restored. Control-based
assets use a temporary CanvasLayer. Optional required actor IDs resolve only to
existing actors. Missing resources/actors, asset exit, invalid landing and the
90-second lost-callback deadline recover safely. A new Start checkpoints the actual HUD/model defaults before the montage.
Pending intro Continue reoffers its opening frame with a new attempt token, then
resolves the initial actor landing against the saved scene spawn. No live actor
position is fabricated before boarding. Pending arrival reoffers the briefing;
pending handoff reoffers its safe bridge checkpoint. Tokens include fresh nonces
so an older save cannot reuse an active callback identity. Arrival dismissals and
dialogue choices also validate their originating attempt/generation. Watch completion
still guards both production departure paths. The mock surface remains an explicit
development route; failed loads release transition ownership and permit retry.

## Runtime evidence and remaining limits

Current reports and source hashes are collected in `docs/first_watch_validation.json`;
readable results and representative captures are in `docs/first_watch_validation.md`.
All test writes use `.godot/mission_validation/`, with no normal user save read or
written. Actual-input chapter proof uses normal player/NPC physics and walking
routes; separate recovery fixtures are clearly identified and do not substitute
for that proof. Door-open captures slow only the isolated fixture's clock so the
short supplied door state can be inspected. The lost-callback fixture accelerates
only its clock to exercise the actual owner deadline.

Previously documented Godot 4.7.2 native reload/shutdown access violations can occur
after all assertions and report writes complete. Process exit codes are reported
separately from assertion totals; they are not silently counted as clean exits.
No engine upgrade or unrelated renderer rewrite is part of this task.

Remaining production work is later canon/crew-presence decisions, teammate
cinematic/voice assets, authorized survey deployment/shared surface persistence,
and compatible enemy perception/survival rules. This chapter ends with the watch
acknowledged and survey briefing pending.

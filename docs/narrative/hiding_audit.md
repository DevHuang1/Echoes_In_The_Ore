# Hiding audit and required implementation changes

Historical audit/proposal at the baseline below. The implemented first-watch chapter
and current hiding/cue validation are recorded in [implementation status](first_watch_implementation.md).

Baseline/date and evidence labels are defined in
[narrative_audit.md](narrative_audit.md). This document records current behavior
and a **proposal**; no prop, collider, player, scene or hiding code was changed.

## Result

There is an existing concealment system worth extending. **Three WEST-facing
lockers and one cargo-bundle gap function mechanically**: the player disappears,
ordinary movement stops, distant equipment cannot open, E exits, and hidden saves
load outside on clear floor. They are not just menu labels/booleans.

They are **partial as physical/narrative hiding**. Entry teleports between checked
endpoints without validating the intervening route. The cargo gap's straight
entry crosses its own crate bodies. Blocked-exit fallback checks endpoints but can
cross an external wall. Locker doors never open during entry/exit, actor occupancy
is not tracked, and no compatible enemy consumes concealment. No detection or
invulnerability claim is supported.

Functional hiding is a required milestone in the subsequent implementation plan,
not an optional polish item. Repair the existing system before adding another.

## Existing ownership and mechanics

| Concern | Current implementation / source |
|---|---|
| Eligible instances | `ship_mission_catalog.gd:54`–`:67`: kinds `storage_hide` / `cargo_hide`; exactly four active instances. Storage/table/rest types do not automatically qualify. |
| Markers/art | `scripts/ship/cargo_bay_prop.gd:65`, `:157`; base `crew_quarters_prop.gd`; reusable `scenes/ship/props/cargo_bay/cargo_locker.tscn`, `tied_box_bundle.tscn`. Inspector values generate AccessPoint and HidePoint. |
| Actual interaction marker | `ship_mission_walkthrough.gd:98` builds `ShipInteractionPoint` from actual footprint, preferred/access direction, floor/body clearance and spawn-connected access. It may try other sides if the preferred side fails. It is **not** the authored AccessPoint itself. |
| Target reach | `ship_can_reach` at `:163`: distance, catalogue room, sampled floor/pressure-door barriers and furniture ray. This checks player→interaction marker, not marker→interior. |
| Entry | `ship_enter_hiding` at `:302`: validates eligible kind/reach, hide/exit endpoints; excludes **all own StaticBody2D RIDs** for interior clearance. Disables player's movement collision shape (deferred), teleports to HidePoint, sets concealment and movement lock. No door-state/crouch/entry-path handling. |
| Visibility/state | `player_controller.gd:75`: hides AnimatedSprite2D, sets `is_concealed`, `concealment_source`, signal `concealment_changed`, group `concealed_players`, metadata. `_physics_process` returns while hidden; owner also disables player physics. No hiding-specific pose frames exist. |
| Exit | Owner `ship_exit_hiding` at `:329`, `_ship_safe_position` at `:320`: preferred exit, then radius 8…96 at 16 angles, room/body-clear endpoint. If none, remain concealed and E retries. Restores sprite/collision/control on success. No connected route/sweep to the endpoint. |
| Inputs | E while hidden exits through the owner; station open explicitly refuses hidden control. Inventory, hotbar, blank map and Settings remain usable through HUD; opening/closing them keeps ordinary walking locked. Esc closes a modal/opens Settings, not a hiding exit command. No unfinished entry-animation cancellation because there is no entry animation/state yet. |
| Occupancy | Single player's `_ship_hide_id` prevents that player entering twice. No host occupancy/reservation property. Clearance queries use collision mask 1, ignoring character layers 2/4. Current game has one player and no hiding NPC AI; future multi-actor use is unsupported. |
| Save/load | Wrapper saves `concealed` ID and `hide_exit`; load intentionally resumes visible outside, restores collision/controls. Validates replacement state/clear floor before mutation. Fully obstructed saved exit can fall back to other clear floor/current position/spawn; no persistent inside/cinematic state. |

The scene-root input guard and `_update_player_walk_state` in
`bare_ship_walkthrough.gd:241`, `:547` preserve other modal locks. Do not replace
them with an independent hiding input manager.

## Current hiding instances, measured from the playable scene

All node paths below begin at `BareShipWalkthrough`. All four roots are scale
`(1,1)`, rotation 0, with separate sprite Artwork Scale and nearest filtering.
World coordinates include the saved ship offset `(-30,-23)`. They are evidence,
not replacement editor coordinates. Stored markers are local to the host.

| Stable ID / node path | Saved placement and artwork | Current entry / interior / exit | Status and required correction |
|---|---|---|---|
| `cargo.locker` — `CargoBayProps/CargoLocker` | Collection `(697,405)`; instance `(446,174)`; world `(1113,556)`. Direction 3 WEST, intact closed, Artwork Scale .145, footprint 18×12 at zero offset. | Authored Access `(-30,0)` → world `(1083,556)`; actual reachable interaction/normal exit `(1092,556)`. Hide `(0,-2)` → `(1113,554)`. | **R functional core / partial presentation.** Clear WEST approach; far EAST entry rejected. Use actual left-side door portal, open/close supplied frames, reserve occupancy and validate connected exit/entry. |
| `engine.locker.1` — `EngineRoomProps/LockerUpper` | Collection `(1347,224)`; instance `(233,128)`; world `(1550,329)`. Same WEST/.145/intact/18×12 settings. | Access `(-30,0)` → `(1520,329)`; actual entry/exit `(1529,329)`. Hide `(0,-2)` → `(1550,327)`. | **R functional core / partial presentation.** WEST approach is in accessible floor beside right boundary; preserve it. Same shared locker fixes, independently occupied instance. |
| `engine.locker.2` — `EngineRoomProps/LockerLower` | Saved walkthrough override `(233,179)`; world `(1550,380)`, **not** starter collection `(201,244)`. Same WEST/.145/intact/18×12 settings. | Access `(-30,0)` → `(1520,380)`; actual entry/exit `(1529,380)`. Hide `(0,-2)` → `(1550,378)`. | **R functional core / partial presentation.** WEST art and approach verified; preserve override. Same fixes and separate occupancy. |
| `cargo.bundle` — `CargoBayProps/TiedBoxBundle` | Saved override `(118,202)`; world `(785,584)`. One as-drawn view, .07 Artwork Scale; three projected crate polygons within 64×26, zero footprint offset. | Access `(0,34)` → `(785,618)`; actual entry/exit `(785,609)`. Hide `(0,-28)` → `(785,556)`, intended behind/between stack. | **R concealment core / blocked physical entry semantics.** Keep sealed crates sealed; enter an actual gap via a body/pose-compatible path. Do not simply teleport through the three crate bodies or call the crate interior a hiding place. |

`hiding_report.json.instances` records exact active atlas, transforms, shape
geometry and all marker values. All four have a spawn-connected walking route
to the interaction point, tested through the existing player movement methods.
That establishes accessible approach, **not** a valid interior passage.

### Artwork and available states

Original PNGs were opened and inspected visually, then their alpha measured
through Godot Image. Actual active regions/anchors were inspected from current
resources and runtime; no uniform cell assumption or image alteration was used.

- Locker `art/concepts/cargo_bay_props/locker-handle-slim.png`: **1448×1086**,
  **771,689 fully transparent pixels**. Four actual directional drawings; rows
  intact closed / intact open / damaged closed. Current WEST closed crop
  `(1077,13,187,351)`, anchor `(93,327)`; WEST open supplied crop
  `(1046,339,235,378)`, anchor `(124,355)`; damaged WEST crop
  `(1080,720,189,357)`, anchor `(90,334)`. Per-view polygon clipping already excludes
  neighboring open-door fragments. Use separately drawn states; no sprite rotation.
- Bundle `art/concepts/cargo_bay_props/Three-crate pixel-art cargo bundle.png`:
  **1263×1246**, **672,353 fully transparent pixels**; single perspective/state.
  Crop `(129,65,1005,1141)`, anchor `(502,970)`. Artwork shows tied solid crates and
  a narrow recessed gap, not a door or hollow crate interior. No open-crate or
  crouching person art supplied.
- These files also contain partial alpha, including nearly opaque machine pixels
  and soft edge/halo pixels. Partial alpha must **not** be equated with removable
  background. Current collisions are explicit geometry, not alpha silhouettes.
  Full statistics and used bounds including soft alpha are in the report.
- All three lockers remained `appearance=0` throughout actual hiding; no open
  state was triggered. Player disappears instantly, cabinet stays closed. The
  current invisible-inside result is real concealment but lacks a believable entry.

## Other candidate instances across furnished rooms

Every relevant candidate below was inspected by scene, artwork and current
runtime structure/actions. **Absent** means no Hide action/markers/behavior;
it is not a claim that hypothetical new behavior has been tested. Shared missing
capabilities for these candidates: no concealment pose/occupancy, no inside save
policy and no enemy handling. Their ordinary solid collisions remain active.

| Candidate instance / stable ID | Artwork, actual footprint and approach | Current status; eligibility recommendation |
|---|---|---|
| `CrewLivingQuarterProps/PersonalComputerDesk` / `quarters.desk` | SOUTH front view, crop `(868,133,506,288)`, .11 scale; 52×16 solid chamfered base, world `(542,438)`; interaction `(542,482)`. Clear knee recess left of drawers in front artwork, nearby DeskChair. | **Absent; plausible under-desk candidate, not ready.** Missing crouch, under-desk anchor/path/leg collision handling and occlusion separation. Check actual chair clearance; never conceal inside drawer cabinet. No standing sprite squeezed smaller or generic invisibility as a finished under-desk pose. |
| `CrewLivingQuarterProps/CommunalTable` / `quarters.table` | Horizontal A, crop `(181,167,502,248)`, .12 scale; 56×18 solid base, world `(582,574)`; current interaction `(518,574)` left of four chairs. Drawn space between two feet below top. | **Absent; conditional under-table candidate.** Needs measured crouch-space, suitable pose, leg-aware collision/occlusion and alternate clear access around chairs. Table art does not itself prove a full body fits. No new chair movement or footprint change during this audit. |
| `CrewLivingQuarterProps/StorageCabinet02` / `quarters.wardrobe` | SOUTH doors; crop `(843,35,308,425)`, .10 scale; 32×14 base, world `(585,451)`; interaction `(585,470)`. Four closed directional wardrobe views. | **Absent; potential cabinet only after approval.** Currently authorized supply storage, no open/interior artwork or markers. Capacity/interior eligibility unknown; do not assume any wardrobe can hide a person. Missing open art and access/presence rules. |
| `BridgeRoomProps/MissionPlanningTable` / `bridge.planning` | Low flat deck-plan cabinet/table, NORTH crop `(27,142,500,241)`, .16 scale; 58×16 base, world `(231,329)`; interaction `(231,349)`. Supplied operational/damaged views. | **Absent; unsuitable with current low enclosed base.** No clear under-table cavity. Keep planning/report controls; do not turn its cabinet body into generic enterable storage. |
| `ShuttleBayCargo` / `shuttle.bundle` | Similar three-crate artwork from bridge folder, .093 scale; saved whole rectangle **83×82**, child offset `(-3.5,-53)`, world root `(1284,644)`; current storage approach `(1280.5,538)`. | **Absent / currently blocked by full-footprint geometry.** No gap markers or split crate polygons. Possible later gap eligibility only after geometry/pose/access review; unfinished shuttle area must remain optional. Do not infer cargo-gap behavior from similar artwork. |
| `CrewLivingQuarterProps/StackedCapsuleUnit` / `quarters.bed.1` | Fixed SOUTH entrances, .07 scale; runtime 38×12 shared floor base; world `(295,494)`, approach `(295,512)`. | **Rest only; hiding absent.** Approved open sleeping capsules do not automatically provide visual concealment; no closing door/crouched cover art. Preserve as one stacked prop. |
| `.../StackedCapsuleUnit02` / `quarters.bed.2` | Same fixed art; saved/runtime 36×12 base, world `(339,495)`, approach `(339,513)`. | Same rest-only status, independently checked. No hide eligibility granted by a second bed instance. |
| `.../StackedCapsuleUnit03` / `quarters.bed.3` | Same fixed art; saved/runtime 36×12 base, world `(384,496)`, approach `(384,514)`. | Same rest-only status, independently checked. No new capsule perspective/door invented. |

Original source sheets for the desk and communal table were visually inspected.
Godot confirms transparency (desk 1,180,429 and table 1,230,621 zero-alpha pixels,
both 1536×1024). The wardrobe is also 1536×1024 with 1,165,644 zero-alpha pixels.
Their existing crop/footprint conventions can be reused, but do not prove a pose
or accessible interior. The bridge table sheet was also measured (1774×887,
844,878 zero-alpha pixels) and its low enclosed base visually reviewed.

The remaining major hosts are consoles, chairs, drawer chests, machinery, racks,
grow trays, herbs, pallet mover/scale/trolley and oxygen/air equipment. They have
examine/service/storage/operator actions, not designated person-sized concealment
spaces. Pipes, vents, mist, lighting and wall art are not enterable hiding assets.
No under-desk behavior is inferred for closed consoles, and no player can enter
a gas cylinder, drawer or sealed machine. The inactive lab is excluded from
current candidates rather than activated to provide new cover.

## Actual runtime observations and failure cases

The final normal-renderer physical/hiding run has **670 passing assertions**.
Its observers also deliberately record defects; those observations must not be
read as “all hiding requirements passed”. Inputs/actions use the actual current
owner/player. Controlled blockers and character fixtures exist only in memory.

| Case | Observed result | Interpretation |
|---|---|---|
| Enter each active instance from its actual point | All four disappear at their recorded HidePoint; sprite invisible, movement shape disabled, physics processing false | **R functional concealment**, not a menu-only boolean. |
| Hold ordinary movement / open distant bridge station | Zero position delta for all four; `ship_open_procedure("bridge.planning")` false | **R correct restrictions** in exposed gameplay. Inventory still available; not itself a bug. |
| E exit / three further entry-exit cycles each | Sprite, shape, control and clear-floor position restored; no inventory loss | **R correct baseline repeated recovery.** |
| Enter from opposite physical side | Clear-floor far EAST of each WEST locker / north of bundle rejected | **R** Existing distance/LOS check catches those cases. **S** No explicit door-side cone, and marker planner permits alternate sides; do not claim all wrong-side cases are solved. |
| Layer-1 blocker at bundle interior | Entry refused; actor stays outside | **R correct endpoint obstacle handling.** |
| Thin external wall between cargo access and interior | Access `(785,609)`, hide `(785,556)`, wall centered `(785,582.5)`; **entry still succeeds** | **R defect:** no entry sweep/path. Both endpoints are clear, so current checks miss the intervening wall. |
| Actual unchanged bundle entry corridor | Player-circle samples along access→hide: **29 of 54 intersect own crate bodies**, diameter 16 | **R defect/unsupported squeeze:** current transition crosses solid sealed crate footprints. A real gap route/pose must be designed and verified. Do not “fix” by disabling all crates. |
| Another character occupies gap (layer 2 fixture) | Entry succeeds with the other actor at HidePoint | **R limitation:** actor occupancy not checked/reserved. No active second hiding NPC exists, so this is a future-use defect rather than a claim of a current multi-NPC encounter. |
| Entire exit search obstructed by layer-1 circle | Remains concealed, E can retry; removal restores normal exit | **R correct no-ejection behavior**, inherited original failure-case tests rerun. |
| Partial exit obstruction / thin external wall | Fallback selected clear `(1077.22,562.12)` from preferred `(1092,556)`; excluding own cabinet from diagnostic ray, selected route **crosses inserted external wall** | **R defect:** clear endpoint is not proof of a connected safe exit. Current code could relocate to the wrong side of a barrier. |
| Save while hidden; load at clear exit | Restores outside, visible, collision/control enabled; inventory preserved | **R defined current save policy**, not “resume inside locker”. |
| Saved exit becomes fully obstructed | Load resolves another clear floor position before mutation; no solid-wall ejection | **R correct unoccupied endpoint fallback**, but connectivity and conservative relocation still need fixing. |
| Locker door / player pose | Same intact closed appearance before/during hiding; no crouch/squeeze/open/close animation | **R/S partial presentation.** Available open art is not currently driven by interaction. |

Evidence: `.godot/narrative_audit/hiding_report.json`, `hiding_runtime.log`,
observer `hiding.gd`. It reuses the original physical validator for selection,
routes, solidity, separation, existing hide/save/obstruction checks, then adds
the tests above. Pressure doors were held open only for route enumeration, not
to claim closed-door access works. Saved resource files were untouched.

Rendered, visually inspected examples:
[cargo gap concealed](../../.godot/narrative_audit/screenshots/hide_cargo_bundle_concealed.png),
[cargo locker concealed](../../.godot/narrative_audit/screenshots/hide_cargo_locker_concealed.png),
[upper engine locker concealed](../../.godot/narrative_audit/screenshots/hide_engine_locker_1_concealed.png),
[lower engine locker outside](../../.godot/narrative_audit/screenshots/hide_engine_locker_2_outside.png).
They show actual hidden/visible state and unchanged closed-door artwork; they do
not show a finished entry animation or an enemy evasion.

## Enemy integration

Source inventory and reference searches found no active enemy actor, perception,
attack/damage controller or consumer of `is_concealed`/`concealed_players`/
`concealment_changed`. Existing Amara AI is a friendly patrol and does not
consume concealment; nearby greetings and automatic doors still use
`ship_player` position without a concealment check. Those are not tested enemy
line-of-sight rules.

Therefore detection prevention, witnessed-entry pursuit, enemy memory, searching,
hearing and susceptibility to damage while concealed are **missing/unverified**.
The currently disabled player collision shape cannot be taken as an approved
invulnerability rule. No test double or absent enemy proves escape from a real
enemy. Do not infer Echo's senses or capabilities from machinery observations.

Later AI integration should distinguish visual exposure, source/occluder,
entry witnessed by that enemy, last-known position and occupancy. Concealment
must not erase existing knowledge, disengage pursuit unconditionally, or cancel
approved attacks/hazards. Exact senses/damage/search rules require approved design.

## Required extension, keeping existing ownership

1. Add per-instance hide configuration/validation to the existing catalogue/host
   workflow: type, eligible states/views, actual access side/portal, interior or
   gap path/anchor, allowed exits, pose/occluder and one occupant/reservation.
   Keep stable IDs, saved transforms and existing markers; do not create a second
   interaction manager or rely on room-label numbers from the reference map.
2. Use a small existing-owner state sequence: outside → entering → concealed →
   exiting. Validate/reserve before movement; cancel/failure releases reservation
   and restores the exact previous player/modal/collision state. Input cannot
   operate other furniture during entering/hidden/exiting. Inventory policy may
   remain available, but cannot unlock walking after it closes.
3. For all **three WEST lockers**, require the WEST door approach. Drive the
   supplied intact-open WEST artwork during entry/exit, preserve floor anchor,
   then close while inside. Keep cabinet solid to everyone else. Permit crossing
   only the designated cabinet portal for the entrant, not arbitrary walls or
   every own footprint. Restore the previous saved appearance on cancellation;
   damaged/open art not supplied must not silently switch to an intact cabinet.
4. For **cargo.bundle**, use a genuine outside gap/behind-stack path. Validate a
   swept player or approved crouched shape against all crates and external walls.
   If the current gap cannot support a person/pose, keep entry unavailable with a
   clear reason until a suitable anchor/path or approved pose/art exists. Do not
   shrink the character or delete the user-set crate collision to fake fit.
5. Validate connected **exits**, not just radial endpoints. Prefer original door
   side and connected nearby walkable floor in the same compartment, respecting
   current pressure doors. If blocked, remain concealed and allow retry; never
   cross a wall to solve it. On load use a validated connected outside point or
   an explicit safe-load checkpoint policy; if none is valid, reject load before
   mutation with a recoverable message rather than becoming trapped/invisible.
6. Keep the existing concealment signal/group/metadata, extended with type/pose/
   exposure as needed. Occupancy must reject character occupants as well as
   layer-1 solids; repeated entry/save/load must not leave reservations behind.
   Movement collision is not a replacement for a future damage/targetability rule.
7. Add desk/table behavior only per eligible instance after fit/pose/occlusion
   checks. Under-table hiding uses crouch/cover beneath the top, never an interior
   storage menu. Preserve other tables, beds and cabinets as non-hiding props.

No new art is required to toggle the current intact locker door frames. A convincing
visible crouch/squeeze and table/desk entry need player pose art or an explicitly
approved alternative presentation; none is currently wired. A simple fade to a
closed locker after a valid door traversal can be an honest initial locker
presentation, but cannot be presented as existing animated artwork.

## Acceptance matrix for the later implementation

Every row must be checked per active locker instance and for the bundle type,
not only on a detached sample prop:

- Correct original directional/state crop, unchanged root transform, stable
  artwork anchor and saved manual footprint; matching floor/sprite Y sorting.
- Reachable approach, correct access face, blocked/closed-door/wall rejection;
  swept entry never crosses non-portal solids or sealed crates.
- Appropriate visible entry/occlusion: door open/close for lockers, approved
  squeeze/crouch/behind-stack presentation for gap; no ordinary movement, distant
  use or stale modal input while transitioning/concealed.
- Occupied/busy target rejected atomically; no double reservation or duplicated
  player after repeated E, cancel, scene exit or load.
- Safe normal/partially blocked/fully blocked exits; connected alternative only;
  persistent retry message; restore collision, animation, control and inventory.
- Hidden save/load and blocked saved exit follow a documented safe policy;
  version-1 saves still load without inside-wall spawning or lost equipment.
- Real active enemy tests only after compatible AI exists: unseen entry,
  witnessed entry, existing pursuit, partial exposure, enemy search and approved
  damage. No automatic memory wipe or invulnerability.

Until the last row is implemented and tested with approved enemy rules, describe
the feature as **functional concealment with unverified threat interaction**.

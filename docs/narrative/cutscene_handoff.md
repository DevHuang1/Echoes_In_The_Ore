# Cutscene integration handoff

## Implemented first-watch adapter (2026-10-27)

The existing walkthrough is the only progression/input owner. The shipped delivery
is the existing Earth-years montage, the existing arrival briefing and an approved
production **terminal-text** command acknowledgement. No teammate cinematic,
choreography, animation, voice or additional physical crew actor is fabricated.
Later incident/boarding/return entries below remain gated proposals.

- `FirstWatchStory` is data only: five mission receipts, evidence, and versioned
  cue attempts with monotonic counters and fresh request-token nonces and terminal outcomes.
- `ship_mission_walkthrough.gd` requests / finishes cues, atomically checkpoints
  receipts and restores gameplay camera zoom, offsets, bounds, current camera,
  smoothing and named NPC/input locks through the existing aggregate owner.
- The montage retains its fourteen existing frames, subtitles and advance/skip.
  Normal complete/skip carries the same first-watch arrival context. It also offers
  `play_cue(context)` / the signal below for explicit embedded integration.
- New Start atomically checkpoints the actual initial HUD/model data and a
  pending prologue before changing scenes. Continue of an interrupted prologue
  reoffers its opening frame with a fresh attempt identity. Its first actor landing
  uses the current scene spawn after clearance validation.
- Arrival dismissal validates its bound cue token and completes its receipt. A pending-arrival load reoffers the
  actual briefing at a validated checkpoint. A pending-handoff load cancels the
  stale attempt and reoffers the bridge summary/text acknowledgement; it does not
  deserialize an animation frame or grant completion.
- Handoff requires earned repair reports, current healthy assigned systems and a
  submitted scoped summary. Completion or authored skip acknowledges the watch
  once, leaves survey briefing pending and never calls the eight-duty file_report.
- Missing/bad resources, missing requested actors, node exit and a 90-second lost
  callback timeout fail safely. Stale/duplicate outcomes cannot advance. Unknown
  landing IDs cannot grant completion. Only `ship` is implemented for these cues.
- Optional `required_actor_ids()` is checked against existing `thura` and `amara`
  handles. Maya/Leila are terminal text; no physical substitute is created. Runtime
  handles in context are never serialized. No general actor/quest autoload exists.
- Both production airlock routes remain guarded. The mock surface is available only
  in explicitly identified maintenance development/legacy contexts. Scene-load
  failures clear transient transition ownership and leave retryable controls.

`tools/first_watch_cue_fixture.tscn` tests **contract behavior only**, with a temporary
camera and terminal signals. It contains no teammate cinematic or enemy behavior.
Current runtime evidence is recorded in `first_watch_implementation.md` and the
first-watch validation report; the original narrative audit remains historical.

## Smallest practical contract

Keep one owner: **the existing walkthrough/story owner** requests a cue and alone
commits progression. A cinematic instance receives a read-only context and emits
a terminal outcome. It does not call F3 reset, mutate mission flags/inventory,
create permanent crew, choose a chapter or save independently.

Implemented interface for the three scoped cues, independent of cinematic production format:

| Direction | Minimal data / behavior |
|---|---|
| Owner → asset | `play_cue(context)`: `cue_id`, unique `request_token`, contract version, chapter/phase, approved read-only fact payload, required actor IDs, validated entry/landing anchor IDs. Runtime node handles may be supplied separately, never serialized into the save. |
| Asset → owner | `cue_finished(request_token, cue_id, outcome, landing_id)`, with outcome `completed`, `skipped`, `cancelled` or `failed`. An optional diagnostic reason is non-authoritative. The owner validates token, active cue, allowed outcome and landing before applying an authored state delta. |
| Skip / cancel | `request_skip()` may finish at the authored final semantic state; `cancel()` restores the pre-cue playable checkpoint without granting completion. Skip must not mean “cancel without story facts”. |
| Dependencies | Per-cue manifest lists actual scene path, supported contract version, required actor/prop/room IDs, entry and exit anchors and whether skip is supported. Owner checks resource availability and required nodes before taking locks. |
| Save receipt | Store cue ID/version, pending/completed/skipped status, attempt token/sequence and applied story transaction ID in proposed versioned `story.cues`; no animation player, camera node or transient object reference. |

This can be a small helper on the current owner plus one consistent signal on
teammate assets; it does not require another autoload, cinematic framework or
replacement dialogue system. Parameterized existing `CrewDialogue` remains useful
for introductions, radio/text briefings and approved fallback delivery.

### Shared lifecycle rules applying to every cue below

1. Validate prerequisites, approved facts/actors, destination resource and safe
   entry/landing points. Capture current inventory/procedure progress through
   existing APIs before interrupting a modal; do not silently discard partial work.
   Save a **pending** pre-cue checkpoint before taking camera/input ownership.
2. Acquire one story-cue lock reason in the existing owner. Preserve other lock
   reasons (arrival, HUD, service, dialogue, hiding). Suspend the speaking/required
   actors' patrols using a real lock; a one-frame velocity reset is insufficient.
   Proposed actor-presence facts come from the story owner, not the asset.
3. Owner restores/retains player physics, collision, visibility, concealment and
   HUD/modal state consistently; restoration calls the normal aggregate lock
   calculation, never blindly `set_physics_process(true)`. If a cue requires the
   player outside concealment, perform a connected safe exit **before** playback
   or postpone it. Never eject an actor from a blocked locker for a cinematic.
4. Cinematic owns its temporary camera during playback. Owner retains the prior
   current camera, bounds/zoom/smoothing and actor-control states. On every terminal
   path—including failed resource load, node exit, cancellation or lost callback—
   remove temporary camera/input ownership, restore a valid gameplay camera and
   show the appropriate next/pending objective. No camera choreography is specified
   here; that belongs to the teammate.
5. `completed` and approved `skipped` apply the **same authored semantic delta**
   exactly once, after landing validation. They do not re-consume samples/items,
   duplicate crew, repeat rewards or auto-complete unrelated duties. The owner
   atomically saves gameplay state plus receipt; repeated/stale callbacks are ignored.
6. `cancelled` / `failed` grants no completion, preserves already-earned gameplay
   evidence, releases locks and returns to the safe pre-cue checkpoint/interaction
   with a visible retry. No production phase reset. If a new scene cannot load,
   retain the current usable scene until failure is handled; do not strand a black
   screen. Async loading/callback recovery needs explicit error paths.
7. Loading a pending cue resumes at a validated checkpoint and reoffers playback,
   not at a serialized animation frame. Completed/skipped receipts suppress automatic
   replay. A user-invoked replay may be presentation-only and cannot apply state again.
   Migration of existing version-1 saves must not fabricate watched incident scenes.
8. Missing resource handling never freezes gameplay. Leave a clear pending objective
   and optional ship activity. An **explicitly labelled development bypass** may use
   a textual event summary and the exact approved delta in an isolated test save;
   record `delivery=development_placeholder` separately from production completion.
   It is not a finished cinematic. A production text fallback is allowed only if
   the story owner has approved that text as a valid delivery of the required facts.

For cross-scene cues the input/camera contract applies on **both** sides of the
transition. Save/check destination readiness before committing arrival/phase;
do not depend solely on nonpersistent Engine metadata. Story data must preserve
outbound evidence and stock rather than using the development `reset("return")`.

## Proposed cue catalogue

IDs describe integration boundaries. Exact incident/boarding/return chronology
is unresolved locally; this list does **not** establish that ordering or crew fate.
The three later cues must remain gated by the approved chronology/payload.

### `cue.thura.earth_years`

- **Trigger/event:** New campaign Start; no ship mission prerequisite. Current
  asset is `scenes/ui/earth_years_montage.tscn`.
- **Preconditions/actors/location:** Thura/parents/May as already rendered in the
  supplied image frames, no live ship actors required. New campaign context must
  be explicit so normal Continue/load cannot replay the montage accidentally.
- **Before playback:** Campaign initialized; proposed intro receipt pending.
  Inventory/ship phase not advanced by individual frame changes.
- **Complete/skip:** Reuse current fourteen-frame/final boarding flow or existing
  intro Skip; record intro seen once, then request ship-arrival handoff. Both reach
  the same approved pre-incident context; skipping reveals no new incident facts.
- **Cancel/failure:** Landing/start remains usable with retry; do not mark seen
  on texture/scene-load failure. Preserve existing fade recovery behavior.
- **After:** Proposed `story.intro_seen`, next cue arrival. No missing-crew flag.
- **Input/camera/persistence:** Montage keeps existing UI input and image motion;
  shared lifecycle restores next owner. Receipt belongs to campaign; optional
  replay cannot reinitialize save/inventory.
- **Missing asset:** Existing montage is available now. If replacement cinematic
  is pending, retain this working montage; no remake requested by this audit.

### `cue.asteria.arrival`

- **Trigger/event:** Montage boarding or explicit intro skip into a new campaign;
  not ordinary mock-planet reboarding.
- **Preconditions/actors/location:** `bare_ship_walkthrough.tscn` loaded with
  authoritative floor/collision ready; Thura at valid arrival point. Proposed
  command message can be remote Maya context. No physical Maya asset is required
  until the teammate explicitly supplies one.
- **Before:** Outbound chapter initialized, no accepted scoped watch, arrival lock.
  Existing briefing is the current available delivery. Fix its assignment wording
  in the later gameplay milestone; do not silently alter it during this audit.
- **Complete/skip:** Present/acknowledge the essential immediate objective even
  when a cinematic is skipped: go to bridge table for the watch. Record arrival
  receipt; release movement and make mission 010 available. Do not accept work or
  verify equipment merely because the welcome played.
- **Cancel/failure:** Remain on safe ship floor with briefing/retry available;
  maintain arrival lock only while an actual modal is open. No repeated automatic
  welcome after a saved completed receipt.
- **After:** `story.arrival_seen`; primary objective 010. No incident or return.
- **Input/camera/persistence:** Shared lifecycle; current `ArrivalBriefing.dismissed`
  is an existing hook. Keep root offset, spawn geometry, HUD and player camera.
- **Missing asset:** Use the existing briefing as an explicitly acknowledged
  non-cinematic handoff after approved wording changes, or a labelled development
  placeholder. Do not claim a new animated arrival scene exists.

### `cue.asteria.watch_handoff`

- **Trigger/mission:** `story.a1.050_watch_handoff` summary submitted.
- **Preconditions/actors/location:** First-watch scope complete, power/irrigation
  genuinely healthy, Amara report receipt; Thura at `bridge.planning`. Maya as
  command contact; live actor only if supplied. Existing planning table/bridge
  remains in place; no newly furnished ops room needed.
- **Before:** Five-mission chapter awaiting acknowledgement; measured summary
  retained, no survey-deployment receipt.
- **Complete/skip:** Acknowledge the measured work and communicate survey briefing
  as next objective. Commit handoff/chapter receipt once; no eight-duty fabrication.
- **Cancel/failure:** Summary remains ready; table offers retry, no duplicate
  consumption/reward or involuntary launch.
- **After:** `story.first_watch_filed` / first-watch chapter complete; next survey
  briefing pending. Completion is not surface deployment.
- **Input/camera/persistence:** Shared lifecycle, return to existing bridge gameplay
  camera/clear access point; snapshot scoped evidence and receipt together.
- **Missing asset:** Author-approved text/radio acknowledgement can be valid chapter
  delivery. Until approved, label any developer summary as placeholder; optional
  tasks remain available and a pending handoff must be understandable.

### `cue.erebos.survey_deployment`

- **Trigger/event:** A subsequent, explicitly authorized survey briefing/deployment
  event after the first watch; not merely walking through today's exterior gate.
- **Preconditions/actors/location:** Authored deployment readiness and actual safe
  systems/loadout, cleared airlock approach, correct location name/chronology.
  Thura required; Elias/Mateo only as approved contact/participants, not presumed
  physical expedition companions. Current mock surface is a development destination.
- **Before:** Outbound ship snapshot, inventory, approved sample kit/authorization
  and cue pending. No incident facts; first watch alone cannot assert all EVA
  readiness or undocumented tools.
- **Complete/skip:** Transfer to the approved survey scene/validated landing ID;
  preserve same inventory and campaign sample ledger. Commit deployment once only
  when destination is ready. Skip reaches identical gameplay purpose/state.
- **Cancel/failure:** Remain aboard at clear airlock with controls restored, no
  lost items or half-applied scene transition.
- **After:** Proposed `story.survey_deployed`, active survey objective and shared
  evidence; phase remains outbound/pre-incident until the approved incident event.
- **Input/camera/persistence:** Shared lifecycle across ship/destination; save
  source/destination/checkpoint IDs, not temporary camera nodes.
- **Missing asset:** Explicit development-only route to current mock surface may
  test the same inventory/progression contract. Never present that as finished
  survey cinematic or use its VESPERA-IV label as approved Erebos canon.

### `cue.erebos.sampling_incident`

- **Trigger/event:** The exact approved sampling/incident beat, supplied by story
  owner. **Not** automatically three mock E samples or a maintenance report.
- **Preconditions/actors/location:** Approved incident chronology, participants,
  samples, scene/anchors and information payload; resources actually supplied.
  Current repository cannot name required missing/dead crew or stage their actions.
- **Before:** Immutable collected evidence and inventory checkpoint, outbound
  knowledge, no inferred fates/cause; cue pending.
- **Complete/skip:** Apply only the approved incident fact delta, custody changes,
  knowledge and safe aftermath checkpoint. If there are required player choices,
  they belong to an approved gameplay decision before/after the cue; skipping
  must not invent a choice on the player's behalf.
- **Cancel/failure:** Preserve earned samples and restore pre-incident checkpoint;
  no partial crew deletion, threat spawning or forced return. Retry is idempotent.
- **After:** `story.incident_recorded` plus explicit approved fact IDs; next cue/
  objective determined by approved chronology. No generic “all crew dead” boolean.
- **Input/camera/persistence:** Shared lifecycle; commit inventory/custody/fact
  transaction once. Pending-cue load retries safely; receipt suppresses replay.
- **Missing asset:** Production incident remains pending. An approved-fact summary
  can be an explicitly isolated development placeholder, never the unexplained F3
  reset or a claim that the incident cinematic has been integrated.

### `cue.asteria.echo_boarding`

- **Trigger/event:** Approved event establishing Echo reaching the ship. Its order
  relative to reboarding/return entry is **not established** by current sources.
- **Preconditions/actors/location:** Approved facts, actual creature/actor assets
  and teammate scene/entry/landing anchors. No new ability, disguise, transmission
  route or crew identity is chosen by this handoff.
- **Before:** Cue pending at the approved point in chronology; preserve all known
  facts and no threat/crew mutation merely because the cinematic is requested.
- **Complete/skip:** Commit the approved boarding receipt and exactly the
  information the player is meant to know then. Enable compatible threat gameplay
  only if that stage has approved rules and actual AI dependencies ready.
- **Cancel/failure:** Restore prior usable checkpoint; no hidden duplicate enemy,
  automatic death or unseen continuing threat with lost controls.
- **After:** `story.echo_boarding_recorded` / approved knowledge stage; does not
  grant the player omniscient knowledge or establish creature weakness.
- **Input/camera/persistence:** Shared lifecycle; receiver validates one threat/
  presence transaction ID, duplicate callbacks cannot spawn twice.
- **Missing asset:** Production gate remains pending. Explicit approved-state
  development fixture only; no invented substitute creature or art.

### `cue.asteria.return_entry`

- **Trigger/event:** Approved post-incident return-chapter authorization, not
  `returning_from_planet` by itself.
- **Preconditions/actors/location:** Approved incident receipt and authorized
  chronology/phase delta. Require boarding receipt **only if** that chronology
  places boarding before this entry. Explicit crew-presence policy, validated ship
  landing point, retained outbound evidence and current inventory.
- **Before:** Campaign snapshot/receipts saved; no wholesale default reset.
  Current TEST RETURN defaults are a test reference, not the authoritative delta.
- **Complete/skip:** Apply approved changed faults, information and actor presence;
  set return chapter and mission `story.return.010_confirm_conditions`. Preserve
  consumption transactions/stocks and outbound records; no false clean inventory.
- **Cancel/failure:** Prior phase/checkpoint remains usable; do not half-reset model
  or spawn a missing crew member by default. Retry after dependencies are supplied.
- **After:** Return phase with one immediate objective and approved world presence.
  Current live Amara fixture is **not** evidence for her canonical return presence.
- **Input/camera/persistence:** Shared lifecycle; source→destination state and receipt
  committed atomically, old saves explicitly migrate; normal reload never replays
  an incident to reconstruct missing flags.
- **Missing asset:** Labelled development handoff uses exact approved return delta
  and isolated saves. Keep F3 TEST RETURN visibly separate as a disposable mechanics
  fixture, not the normal-story fallback.

### `cue.asteria.return_escalation`

- **Trigger/mission:** Approved escalation after a return report/repair such as
  `story.return.020_restore_safe_route`, or another authored event—not a universal
  “all machines serviced” trigger.
- **Preconditions/actors/location:** Approved threat/presence rules, compatible
  AI, tested hiding, known safe gameplay resume point and actual cinematic asset.
  Required actors/rooms must be supplied rather than guessed from the map.
- **Before:** Earned repair/measurement report retained; player outside a blocked
  transition/hide state; cue pending. Do not make successful concealment imply safety.
- **Complete/skip:** Apply approved escalation stage and next objective once.
  Preserve technical progress, player equipment and enemy knowledge according to
  approved rules. No ending choice or named fate invented in the adapter.
- **Cancel/failure:** Restore playable pre-cue state and retry; never leave an
  offscreen active attack while input remains locked.
- **After:** Explicit authored next stage, not an unspecified death/win/reset.
- **Input/camera/persistence:** Shared lifecycle; AI ownership paused/restored in
  agreement with gameplay owner, threat/cue receipts idempotent across reload.
- **Missing asset:** Clearly pending production stage; only labelled isolated
  development bypass with approved payload. No new monster/cinematic is produced
  by this audit. Ending cues are intentionally unspecified until approved design.

## Teammate delivery checklist

For each asset ready for integration, provide:

1. Exact `.tscn`/resource path and cue/contract version; supported skip behavior.
2. Required **canonical** actor IDs and whether live actor nodes or cinematic-only
   representations are needed. Identify missing actor assets explicitly.
3. Existing room/prop IDs, entry and landing anchor requirements. New runtime
   markers may be proposed later; do not move saved furniture, doors or floors.
4. Read-only fact payload needed at start and the proposed semantic facts to commit
   on completion/skip, reviewed by story owner. No independent inventory/quest edits.
5. Terminal signals for completion/skip/cancel/failure and ownership of temporary
   camera/audio/UI nodes; no call to `change_scene_to_file` behind the owner's back.
6. Production missing-resource/fallback policy and whether a textual version is
   approved. A developer bypass is visibly labelled and saved separately.

The integration owner supplies tokens, current gameplay nodes/approved facts,
safe checkpoints, locks, persistence and idempotent state application. The teammate
supplies cinematic content and terminal outcomes. Neither side must infer a
missing person's fate, enemy ability or ending from a UI prototype record.

## Integration acceptance tests (subsequent implementation)

- Current Start/full montage/Skip/boarding routes converge on the same intended
  arrival objective; existing saved campaigns do not replay automatically.
- Each cue: complete, skip, cancel, resource missing, scene-load failure, missing
  required actor, duplicate/stale callback, interrupted save/load and repeat E.
- All outcomes leave a valid camera, correct prior input/modal/hiding state,
  safe collision position and understandable next/pending objective.
- No duplicate items/stock, samples, actors, enemy spawns, report or chapter rewards.
- Outbound evidence survives incident/return; only approved knowledge is exposed
  at each cue. Ordinary surface reboarding cannot unlock return/survival.
- Production route reaches the intended chapter through actual cues/approved
  fallbacks; a labelled development bypass is tested separately and never counted
  as evidence that a cinematic exists.

The narrative audit predates implementation. Consult the current implementation
log for tests actually run. Contract fixtures do not establish that later teammate
cinematics, incident canon, compatible enemy AI or deployment persistence exist.

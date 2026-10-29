# Story mission implementation proposal

Historical audit/proposal at the baseline below. The implemented first-watch chapter
and current hiding/cue validation are recorded in [implementation status](first_watch_implementation.md).

This is a **new recommendation**, based on the current-state
[narrative audit](narrative_audit.md). Nothing in this document has been
implemented by the audit. Dialogue entries below describe required beats, not
final lines, new canon, cinematics or promises about crew fates.

## Preserve and connect

Preserve the seven furnished collections, all saved transforms and footprints,
original floor mask/doors/lighting, player movement/art, inventory and nine quick
slots, redesigned equipment UI, original power/filter/manifold games, transactional
supplies, observations/diagnoses and stable verification. Keep `WalkHud` as inventory
owner and `BareShipWalkthrough` as interaction/progression owner. Reuse
`CrewDialogue`, `ShipMissionState` and `ShipProcedurePanel`.

The present technical watch requires all eight procedures. A story chapter must
not simply rename that checklist. Its mandatory goals should reflect a person's
request, a measured problem, a useful consequence and a report-back. The other
equipment remains available for optional work or a later authored event.

## High-level progression and information order

| Story portion | Existing material to reuse | Intended player purpose and reveal boundary | Missing connection |
|---|---|---|---|
| Earth years | Fourteen-frame montage, Thura's family/training/star | Establish why he listens, diagnoses and perseveres. No later threat explanation. | Durable once-only completion/skip receipt; keep teammate's cinematic ownership. |
| Asteria watch before deployment | Furnished ship, roster, Amara, power/hydro procedures | Learn people and ship through a small useful watch; understand immediate next destination. | Five-mission chapter below, NPC reliability, scoped assignments, report-back. |
| Surface survey/deployment | Exterior gate and mock surface with three sites | Apply Thura's geology/robotics assignment. Identify collected evidence without treating it as proof of a creature property. | Real briefing/readiness, shared inventory/sample ledger, persistence, authored planet content/cutscene handoff. |
| Sampling incident / crew uncertainty | Broad user premise; no current scene | The player experiences approved incident facts, then knows what is missing versus merely unconfirmed. | **Canon and teammate assets required.** No invented participants, death, cause or order. |
| Echo reaching ship / return entry | Existing changed return measurements | Establish the approved aboard-ship situation once, preserve outbound knowledge and records, present an immediate need. | Explicit incident/boarding/return receipts and approved actor-presence policy; F3 is not the implementation. |
| Return maintenance and survival | Scrubber/load/valve/dose discrepancies; existing concealment API | Choose urgent repairs from evidence while managing the approved threat rules; use learned locations/hiding. | Repair concealment, compatible enemy perception/harm rules, authored escalation and consequences. No all-room reset checklist. |
| Resolution | No executable ending found | Only the approved outcome/decision once supplied. | Exact canon/choices, cinematic and gameplay consequences; do not infer a destroy/escape/sacrifice ending. |

“Departure” after this arrival means **surface-survey deployment**, provisionally.
The current intro already spans Earth departure and jumps to DAY 184 near Erebos.
Do not add an Earth launch after the orbital welcome. Resolve approach-versus-
orbit and VESPERA-IV wording with the story owner before a production chapter
transition; the initial watch can be built without inventing that chronology.

## Next playable chapter: an assigned watch

Proposed chapter ID: `chapter.asteria.first_watch`.
Endpoint: a measured watch summary is acknowledged by command, and the player is
told to await/attend the survey briefing. This is a complete small chapter; it is
**not** a claim that the incident, survey cinematic or ending is finished.

Mandatory order:

1. `story.a1.010_watch_briefing` — Receive the watch.
2. `story.a1.020_meet_amara` — Meet a crewmate and inspect the problem.
3. `story.a1.030_aux_service` — Restore the service supply.
4. `story.a1.040_irrigation_report` — Restore delivery and report to Amara.
5. `story.a1.050_watch_handoff` — Hand over the verified watch.

Only **two equipment repairs**, power and irrigation, are required in this
proposed chapter. Crew introductions/check-in and report-back supply the story
structure. Navigation, cargo, filter work, cooling, sensor check and rest must
not silently become prerequisites for every story event.

### Required change to assignment/scenario semantics

Current `ship_mission_state.gd:73` enforces crew→cargo→power→life→hydro and
communications requires all seven. The chapter cannot work merely by changing
the HUD. In a subsequent implementation:

- Author a chapter work-order scope (power + hydro) in the existing owner/model;
  make the current fixed graph a **maintenance test/watch scenario**, still
  reachable through the explicitly labelled development fixtures.
- Separate authorization/story order from physical safety. Allow observation of
  live readings before accepting a repair; keep technical interlocks for safe
  isolation, tools, real supplied items, allocation, restoration and verification.
  Power must not need an unrelated cargo signoff; hydro must not need a filter
  objective solely because it was the earlier checklist order.
- Initialize the story watch's **unselected** life/cooling systems to genuinely
  healthy routine readings. Do not leave their present 18% airflow / 35% pump /
  90°C faults untreated and call departure safe. This is proposed scenario data,
  not a request to alter current geometry or fake completed flags. If the story
  owner retains a critical fault, assign a justified mission/crew response and
  delay departure rather than silently skipping it.
- Healthy optional systems remain inspectable; they do not consume filters or
  coolant just to generate a completion mark. Never mark an unplayed duty done
  to bypass a prerequisite. Preserve real `completed`/equipment history.
- Add a scoped chapter summary/acknowledgement action; do not call current
  `file_report`, whose legitimate condition is eight completed procedures, with
  fabricated completions. Retain the existing full measured-report behavior for
  the complete maintenance watch.
- Display one primary next objective and separately optional tasks. Accepting an
  optional Amara check must not change the chapter's completion denominator.
  Keep the blank map; provide room name, useful landmark and existing world prompt.

### 010 — Receive the watch

**ID/title:** `story.a1.010_watch_briefing` / Receive the watch.

**Purpose and initiator:** Introduce Thura's immediate shipboard responsibility
and crew roles before machinery. A command briefing attributed to Maya (CDR)
through the **existing bridge planning table/dialogue overlay** is a proposed
text/radio delivery, not a newly available Maya actor.

**Start/prerequisites:** Arrival dismissed, story chapter not yet accepted;
approved current orbit/approach context. Proposed `story.arrival_seen` receipt;
no cargo/equipment completion required. Immediate objective: go to the bridge
planning table and receive the watch assignment, then check in at quarters.

**Ordered actions/locations/items:** (1) Arrival gives that exact next objective;
(2) E at `BridgeRoomProps/MissionPlanningTable` (`bridge.planning`); (3) read the
named roster/roles and accept the scoped watch; (4) visit
`CrewLivingQuarterProps/PersonalComputerDesk` (`quarters.desk`) and compare the
authorised roster/watch using the existing crew controls. No new item; no private
property search. Do not turn a terminal record into a claim of meeting each actor.

**Dialogue beats:** Maya's role/assignment, reason the service feed matters to
Amara's grow beds, where to find Amara, and who has authority for other systems.
Optional short existing-role introductions via terminal contacts for Elias,
Leila and Mateo; each clearly remote/recorded until actor art exists. Do not
invent histories, personalities or later disappearances.

**Completion/state/response:** Accepted scope + supported routine record
comparison; proposed `story.watch_accepted`, `story.roster_reviewed` and mission
receipt. Reuse existing roster evidence rather than duplicating its truth. Command
confirms assignment, tracker selects 020. No ship launch or incident flag.

**Optional/recovery:** Decline/close keeps objective and reoffers without a second
assignment. Inventory/room exploration optional. Save after acceptance and roster
comparison; interruption resumes the first unfinished action, without replaying
the prologue or erasing records.

**Dependencies/priority:** **P0.** Contextual briefing text and minimal speaker/
beat parameters in `CrewDialogue`; story save migration; primary-objective view;
assignment graph change. No new room or actor artwork required for text/radio.

### 020 — Meet Amara and inspect delivery

**ID/title:** `story.a1.020_meet_amara` / Meet Amara and inspect delivery.

**Purpose/assigner:** Maya's directed introduction leads to Amara's practical
concern. Establish a relationship through a supported observation, not a pump
repair falsely completed by a single E press.

**Start/prerequisites:** 010 complete; Amara physically available under the
pre-incident chapter's presence policy. Immediate objective: speak to Amara in
hydroponics, then compare the reservoir/pump/delivery readings with her.

**Actions/locations/items:** (1) Talk at actual reachable Amara position;
(2) inspect `hydro.console`/`hydro.pump`, record normal EC and healthy pump capacity
versus inadequate delivery and unavailable science/service feed; (3) return to
Amara with this observation. No consumable or new diagnostic gadget; the existing
multitool may stay carried for later work. Do not force optional pump/sensor tasks
to intercept the primary E target.

**Dialogue beats:** Existing Amara introduction preserved; distinguish inspection
from verified repair. She explains what she observed and requests restoration of
the service supply before manifold work. Leila's engineering authorization may
arrive as a named terminal/radio note; final wording is new content to author.

**Completion/state/response:** Supported readings recorded + Amara report-back;
`story.amara_introduced`, `story.delivery_observed`, mission receipt. Amara
acknowledges the actual problem and sends the player to 030. No “beds recovered”
response until actual restoration.

**Optional/recovery:** Her sensor calibration/check can remain a separate optional
offer. If she is walking elsewhere, allow reach/line-of-sight conversation there
or supply a visible rendezvous state, never a hidden hydro-only interaction gate.
Lock the NPC while talking. A declined conversation resumes; saved observations
prevent repeated scanning as a penalty.

**Dependencies/priority:** **P0.** Fix conversation/patrol ownership and room rule,
state-aware barks, dialogue branches and saved report-back receipt. Observation
must be available without the unrelated life-support completion gate.

### 030 — Restore the service supply

**ID/title:** `story.a1.030_aux_service` / Restore the service supply.

**Purpose/assigner:** Engineering watch (Leila, ENG, through recorded/radio
instruction) authorizes a measured repair whose consequence helps Amara. Connects
Thura's diagnose-before-repair background to an observable effect.

**Start/prerequisites:** 020 complete, chapter-authorized power work order; no
cargo duty. Immediate objective: restore auxiliary/science service while retaining
essential supply, then report the verified readings.

**Actions/locations/items:** At `power.breaker`, capture loads/diagnose unsynced
bank → isolate auxiliary/science circuit. At `power.converter`, choose valid
70/20/10 or 70/10/20 allocation. At `power.cell`, carry
`engineering_multitool` and operate the **existing** capacitor control ranges
(67/43/77 is one valid solution). Restore circuit, observe six healthy seconds
and verify at breaker. Read the restored service feed at hydro; optional response
from Leila confirms measurements. Obtain a stored multitool from
`quarters.wardrobe` if necessary; preserve shared stock/inventory safeguards.

**Dialogue beats:** Essential versus science service, why a deferral matters,
confirmation based on recorded voltage/allocation, no abstract “do every machine”.
No wire joining or new matching puzzle.

**Completion/state/response:** Actual `completed.power` + `bus_powered("science")`
and report acknowledgement; `story.service_supply_reported`. Use existing
transaction/verification logic. Terminal and Amara's state-aware response confirm
that supply is restored, while manifold restriction remains. Next: 040.

**Optional/recovery:** Either safe allocation acceptable; record chosen deferral.
Closing preserves isolation/partial bank settings; Restore cancels safely.
Reopen resumes; duplicate report has no duplicate reward/consumption. If supply
is later isolated, 040's physical operation waits for restoration and explains why.

**Dependencies/priority:** **P0.** Chapter authorization instead of cargo gate,
contextual messages and one report-back receipt; preserve existing bank game/UI.

### 040 — Restore irrigation and report to Amara

**ID/title:** `story.a1.040_irrigation_report` / Restore delivery.

**Purpose/assigner:** Finish the task Amara actually asked for and receive an
appropriate response. Teach comparing pump health, reservoir chemistry and flow
before the return watch presents a different problem.

**Start/prerequisites:** 030 complete; science feed currently available;
`story.delivery_observed`; Amara's authorized manifold work. Immediate objective:
correct the restricted manifold, verify delivery, tell Amara what changed.

**Actions/locations/items:** `hydro.console`/`hydro.pump`: capture current normal EC,
healthy pump/poor delivery → diagnose restriction → isolate → use multitool and
original labelled nutrient-manifold controls → restore → observe recovery for six
healthy seconds → verify → talk to Amara at a reachable point. The original
1/3/2 valve rotations are a valid solution, not a new arbitrary matching game;
preserve diagram/flow explanation. No BUFFER-A consumption in a normal-EC fault.

**Dialogue beats:** Amara compares before/after delivery and plant observation,
thanks the player for the measured outcome, offers optional relationship/social
conversation. She does not infer an Echo weakness or promise a future fate.

**Completion/state/response:** Actual `completed.hydro`, sustained delivery ≥90%,
EC within 1.8–2.4, power restored, plus `story.amara_repair_reported`. Do not substitute
the old optional task boolean. Acknowledge exactly once; optional repeat dialogue
can summarize the result. Next: 050.

**Optional/recovery:** Inspect herbs/seedlings or finish sensor check. Interrupted
valve control resumes from existing snapshot. If readings regress, retain repair
history but require safe restoration before the report says “currently healthy”.
No repeated item reward, diagnosis or artificial task reset after load.

**Dependencies/priority:** **P0.** Remove unrelated filter duty prerequisite from
this chapter; couple Amara response to real measurements and report receipt;
existing valve game retained. No new room or repair animation required.

### 050 — Hand over the watch

**ID/title:** `story.a1.050_watch_handoff` / Hand over the verified watch.

**Purpose/initiator:** Maya's follow-up acknowledges useful work, introduces the
next survey purpose and gives a clear chapter endpoint instead of an endless
checklist.

**Start/prerequisites:** 010–040 receipts, actual required equipment healthy,
Amara report-back complete. Immediate objective: return to `bridge.planning`
and submit this watch's measured summary.

**Actions/locations/items:** Review scoped before/after power/delivery evidence
at planning table → submit/receive command acknowledgement → get survey-briefing
next objective. No consumable. Navigation briefing/contacts can be read at the
existing helm/flight consoles; do not require the all-eight communications report
unless a later authored deployment mission expressly needs it.

**Dialogue beats:** Maya acknowledges the completed work; Elias can describe his
pilot handoff through the existing bridge station and Mateo's role can be named
for survey handling. These are proposed role-consistent beats, not existing NPC
conversations or new incident facts.

**Completion/state/response:** `story.first_watch_filed`,
`chapter.asteria.first_watch.complete`; immutable measured summary/receipt and
next objective. Proposed cue `cue.asteria.watch_handoff` requests teammate work;
an authored text briefing can fulfill the practical acknowledgement. No automatic
conversion to return phase. Endpoint is “watch handed over / survey briefing next”.

**Optional/recovery:** Optional chores remain optional and retain their records.
Save before/after handoff; repeated submit/duplicate cinematic callback must not
advance twice. If a cinematic is missing, show the clearly labelled development
fallback or production pending brief described in the handoff document; do not
pretend a launch played. Airlock access follows a separate survey-readiness gate.

**Dependencies/priority:** **P1**, after the complete P0 slice. Scoped summary/action,
command dialogue, explicit next-objective/chapter receipt and cue contract.

## Optional work, separate from chapter completion

Each ID below is proposed. Its UI must say OPTIONAL and not affect the five-step
chapter gate. Existing work is reused where meaningful; no repeated mandatory
repair is manufactured on an already healthy component.

| ID/title | Trigger / assigner / prerequisites; immediate objective | Actual actions, tools and evidence | Completion / reaction / recovery / priority |
|---|---|---|---|
| `optional.a1.cargo_check` / Check routine stores | Offered by cargo watch/recorded Mateo context after roster review; accepting is optional. Inspect the routine load before release. | `cargo.bundle` manifest/seal → `cargo.scale` tare/reference → `cargo.mover` transfer → scale mass/disposition. No consumable; existing ID/mass/seal judgement. | Actual `completed.cargo` + optional report receipt; role contact acknowledges supported custody. Wrong disposition changes nothing; full inventory safe. No mandatory engine-service chain. New assignment/reaction text **P1**. |
| `optional.a1.seedling_check` / Calibrate the seedling sensor | Existing Amara offer, after meeting her; optional. Check the labelled sensor, not “repair irrigation”. | Existing `amara_seedling_sensor` E action may remain an observation checkpoint initially; for a meaningful calibration extension, read actual reference and record one adjusted sensor value. Never claim the existing single-E check is a full mechanical repair. No invented gadget. | Distinct optional evidence/thanks; no `completed.hydro` write. Keep Q decline/reoffer and saved task flag. New reference/value UI only if retained as calibration **P2**. |
| `optional.a1.routine_inspection` / Read the remaining systems | Engineering watch offer after 030; inspect, do not consume spares to earn a mark. | Existing life O2/CO2/airflow, cooling-loop pressure/temperature, labelled cylinders, corrected-heading reference. Use standing controls, carried multitool only when an authorized real fault calls for it. | Journal observations and contextual response; no false verified repairs. Return later for genuine incident-specific work. No timed failure for declining. Healthy story-scenario data and optional assignment presentation **P1**. |
| `optional.a1.safety_access` / Learn a concealment route | Engineering safety instruction offered after quarters orientation, only after hiding fixes. Optional tutorial; no invented active enemy attack. | Approach a real WEST locker door; open/enter/close; E safe exit. Optionally inspect the cargo gap and use the approved gap route only after geometry/presentation proves it. No item; no sealed-crate entry. | Tutorial receipt + acknowledgement that controls work, **not** immunity. Cancel/interruption/blocked exit as hiding audit. Implementation of both existing hiding types is a required **P0/P1** milestone even if the tutorial is optional. |
| `optional.a1.rest` / Take a short rest | Existing capsule action when essential systems are truly safe; initiated by player. | Shared capsule prop and fatigue state; no new sleeping art, time skip or crew-event assumption. | Fatigue reduction only, never advances chapter or completes duties; resume after cancellation/save. Align safety condition with healthy chapter scenario rather than requiring every historical duty complete. **P2**. |

Supply storage/retrieval is supporting gameplay, not another mission. Keep full
inventory atomic transfers, transaction IDs, bounded replacement kit and explicit
item labels. Private belongings remain private.

## Later return/survival mission designs

These are **conditional proposals**, not canon-approved chapter ordering. The
high-level incident/deployment beats above are not ready mission specifications:
they cannot be implemented faithfully until the missing story facts are supplied.
The following two bounded designs explain reuse and required threat dependencies.

### `story.return.010_confirm_conditions` — Confirm what changed

- **Purpose/initiator:** First approved post-incident return-entry event. Replace
  the reset checklist with one immediate evidence-based situation assessment.
- **Prerequisites:** Approved incident/boarding cue receipts, explicit return
  chapter initialization, approved actor-presence policy. Never trigger from
  ordinary mock-planet reboarding or old outbound report completion.
- **Immediate objective/actions:** Reach the already-furnished crew desk/bridge
  records, compare old check-ins without assigning fates; inspect cargo seal/mass
  if the approved returned load is present; record uncertainty and quarantine
  when readings support it; report confirmed conditions at `bridge.planning`.
- **Items/locations:** Existing quarters/cargo/bridge; no new lab or mandatory
  unfinished area, no consumable for reading/weighing. Preserve the actual
  recovered-load identity when the canon handoff supplies it; do not invent its
  contents from the current CARGO-A12 development placeholder.
- **Dialogue:** Author a surviving/contact-available speaker only after presence
  is confirmed, or use an explicitly recorded system log. No live Amara voice
  inferred from the development fixture. Distinguish absence of check-in from death.
- **Completion/response/next:** Supported records and discrepancy saved under
  return evidence + `story.return_conditions_reported`; a specific urgent measured
  fault becomes the next assignment, not every system simultaneously. Threat
  escalation occurs only at an approved cue boundary.
- **Optional/recovery:** Compare outbound evidence from same campaign; do not
  erase it during phase transition. Revisit records without repeated reward;
  interrupted inspection resumes, quarantine cannot open/release a sealed load.
- **Dependencies/priority:** **P2, canon blocked** for participants/custody/presence;
  mechanics reusable now. Chapter carryover must preserve stock/transactions and
  apply only approved fault deltas, unlike `reset("return")` test fixtures.

### `story.return.020_restore_safe_route` — Restore a safe operating window

- **Purpose/initiator:** An approved return fault/route event requires a selected
  repair while danger makes location and concealment knowledge consequential.
  This ID does not specify an unapproved Echo power, attack or kill rule.
- **Prerequisites:** 010 report; approved fault and compatible threat AI enabled
  at the intended cue; functional hiding acceptance gate passed. The safe endpoint
  and required systems are authored data, not an every-room repair requirement.
- **Immediate objective/actions:** Diagnose the single urgent system from current
  evidence, obtain the correct tool/supply via existing stores, isolate/service/
  restore/verify, then reach the approved report point. Example selectable faults:
  normal airflow/high CO2 → `life.scrubber` with SCRUB-A; or healthy pump/high valve
  drop → `engine.valve.2`, reduced output and multitool. Use different evidence
  from outbound filter/manifold work. Do not make both examples mandatory by default.
- **Items/locations:** Actual life/engine/cargo paths and items already in model;
  locker/gap concealment as eligible routes. Gas identity remains meaningful;
  O2 does not fix CO2. No wire-joining, arbitrary new match puzzle or hold-E-only repair.
- **Dialogue/response:** Available NPC/radio/log explains the measured urgency
  and reacts only to confirmed restoration. Player may hide while danger passes
  under approved perception rules; witnessed entry retains enemy knowledge.
- **Completion/state/next:** Real system verification + safe arrival/report receipt
  `story.return_window_reported`. Proceed to next **approved** escalation/cue, not
  an invented final choice. Failure/interruption does not delete consumed-item or
  restored-system state; a real loss condition needs the story/gameplay owner's rules.
- **Optional/recovery:** Other safe inspections optional; partial procedures and
  hiding exit/load recovery persist. Ensure a reachable alternate hide/retreat path
  before disabling a route. Hiding never automatically clears pursuit or damage.
- **Dependencies/priority:** **P2/P3, blocked for threat/canon**, not for the reusable
  machinery. AI must consume concealment source/knowledge appropriately and be
  tested before any “evades detection” acceptance claim.

## Minimal integration architecture

1. Extend the **existing owner** with a small story/chapter state section:
   current chapter, mission-stage receipts, named conversation/knowledge receipts,
   approved actor presence, sample evidence and cinematic receipts. Stable IDs
   distinguish chapter work from the existing technical duties. This is proposed
   data, not a new autoload/global quest framework.
2. Read the existing model's equipment values and completions as the authoritative
   technical truth. Use `objective_completed` for a pending report-back/objective
   update, not an unconditional chapter jump. UI reconstructs from saved state.
3. Parameterize `CrewDialogue.start_dialogue` with speaker/beat context and a
   result ID while retaining typewriter/input/theme. The owner checks prerequisites
   and records results once. Freeze both player's movement and the speaking NPC's
   patrol; restore the previous state on close/cancel/scene exit.
4. Add a versioned owner save envelope with a **v1 migration**. Keep the v1 mission
   snapshot/inventory unchanged where possible and add optional `story` alongside
   it; accept old files as legacy maintenance watches without fabricating story
   completion. If model authorization/scenario fields are added later, version
   and migrate them explicitly too. Current flag dictionaries only accept booleans;
   do not insert nested mission/cinematic objects into them.
5. Persist on meaningful acceptance/report/cue/sample checkpoints atomically;
   retain explicit F6/F9. Story transition uses an in-memory validated snapshot
   plus durable receipt, not only Engine metadata. Restore-safe position, modal,
   actor and concealment policy before releasing input.
6. Surface scene must bind the existing inventory and campaign sample evidence
   rather than making disposable independent HUD data. Carry actual completed
   sites/items/IDs back; test re-entry/restart without duplication. Leave existing
   mock sampling content clearly labelled until the real survey beat is integrated.
7. Cue interface follows [cutscene handoff](cutscene_handoff.md). Teammate owns
   cinematics; owner alone commits story changes. Scenario reset buttons remain
   development-only and never simulate earned production progression silently.

## Implementation milestones and acceptance gates

| Order | Small deliverable and likely files | Acceptance criteria |
|---|---|---|
| **M1 — recommended first** | Arrival→one contextual bridge assignment→reachable Amara introduction. Owner/root, `CrewDialogue`, primary objective view, small save envelope migration. No room edits. | Fresh Start and intro skip give the same first objective; player finds table without map content; named speaker/role is accurate; decline/reoffer/save/reload preserve progress; Amara cannot patrol during dialogue and can talk at valid actual locations; no premature incident/return event. v1 saves still load. |
| M2 | 030 power vertical slice and state-based report-back; scoped work authorization; healthy unselected story-scenario data. | Arrive→assigned repair→actual bank controls→restored science feed→NPC acknowledgement works without cargo/life/hydro checklist. Interruption/restore/duplicate/save cases pass; full original maintenance validators remain meaningful and pass in their fixture context. |
| M3 | 020/040 measured irrigation and Amara report-back; scoped 050 summary. | Two required repairs finish five-mission chapter; optional tasks do not increase required total. Dialogue/barks agree with actual flow; old optional E check cannot impersonate repair. Handoff receipt idempotent, next survey-briefing objective visible. |
| **M4 — required before survival** | Fix the two existing hiding types, three locker instances + one gap. Add candidate table/desk only after eligibility/pose/space approval. | Per-instance entry/exit connected and side-correct; existing external-wall/blocked-exit/occupancy fixtures pass; genuine concealment presentation, repeats/load/control restoration; no wall ejection, sealed-crate entry or automatic AI immunity. See hiding acceptance matrix. |
| M5 | Teammate cue adapter + survey gate + shared surface evidence. No cinematic production by integration owner. | Complete/skip/cancel/missing/error/reload each restore input/camera; one receipt per cue. Ordinary reboard preserves outbound phase until approved incident. Sample/item duplication and loss checks pass. Production gate cannot silently use TEST RETURN. |
| M6 | Approved incident/crew-presence/boarding/return integration and one urgent return mission. | Canon facts match authored handoff; outbound logs persist; only selected faults assigned; no live NPC with unknown presence; interrupted transition resumes once. |
| M7 | Compatible enemy perception, witnessed concealment and approved survival/escalation outcomes. | Real active AI tests visible, unnoticed concealment, witnessed entry, blocked escape, load and damage cases; hiding does not clear enemy memory by itself. Endings only after approved design/assets. |

For every milestone: diff/hash saved room/art/collision resources; run relevant
normal-renderer behavior checks and current isolated-save regressions; inspect
screenshots rather than using totals as narrative proof. Update old “future
markers only”, intro and assignment documentation when behavior actually changes.

## Specific unresolved information

The first watch proposal needs new dialogue beats and a final chronology wording
decision, but can reuse the available rooms/art. Later work genuinely needs:

- Authoritative incident timeline, participants, what becomes known when, named
  crew presence/uncertainty and which outcomes are intentionally unresolved.
- The approved account/order of Echo reaching the ship and its actual perception,
  witnessed-entry, interaction/damage rules; approved resolution/ending choices.
- Erebos versus VESPERA-IV and approach versus orbit wording; whether the surface
  departure uses current airlock directly or a teammate-produced deployment scene.
- Teammate's cinematic scene paths, actor requirements, payloads/landing points,
  and what is already supplied versus pending; production skip/missing-asset policy.
- Approved crouch/squeeze/entry frames if table/desk/gap concealment is to show a
  body pose. No such player frames are currently wired; do not redraw the approved
  furniture or borrow walking sprites to claim a finished crouch.

No design approval was requested during this AFK audit. These are scoped inputs
for later implementation, not reasons to leave the current inspection unfinished.

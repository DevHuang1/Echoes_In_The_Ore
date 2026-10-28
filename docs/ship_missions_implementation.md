# Ship-side mission implementation

## Scope and preservation

Implement the user's attached seven-room mission brief: outbound routines and a
development-only post-incident return scenario, using the current walkthrough,
inventory, dialogue, pixel UI and working power/filter/nutrient minigames.
No branch merges, pushes, artwork regeneration, furniture movement, map drawing,
planet/prologue replacement, invented crew fates or Echo biology.

Baseline: local `kaung` at `a3f8239`; 23 pre-existing modified files, including the
saved walkthrough and import metadata. Exact backups/hashes are recorded under
the ignored `.godot/mission_baseline/` before implementation.

## Checkpoints

- [x] Audit canon, interaction, inventory, dialogue, objectives, persistence,
      prop transforms and collisions. Record actual constraints.
- [x] Extend the existing walkthrough/HUD with stable prop IDs, reachable
      markers, one-target selection, room/door checks and contextual procedures.
- [x] Complete one operational room loop with diagnosis, supplies, state and UI.
- [x] Complete bridge, quarters, cargo, engines, power, life support and
      hydroponics; preserve the existing three service games and Amara's jobs.
- [x] Connect outbound/return sequences, evidence, prerequisites and consequences.
- [x] Add safe hiding, appropriate seating/rest and shared inventory storage.
- [x] Persist relevant mission/inventory/equipment state with safe test save paths.
- [x] Run automated transitions, cancellation, duplicate, phase, save/load and
      reachability tests, plus rendered Godot MCP walkthrough/UI regression checks.
- [x] Finish prop manifest, play instructions, verification evidence and limits.

## Implementation decisions / audit

- The walkthrough currently owns interactions, three room-task completion flags,
  Amara's dialogue/jobs and HUD modal movement control. Extend this owner.
- The HUD owns the existing inventory/quickbar/equipment. Add access and snapshot
  methods there rather than creating another inventory.
- No mission save system or complete return-incident transition has been found
  in the initial audit. Verify before adding persistence or a debug scenario.
- The overlapping lab remains a separate, inactive scene. Its six missing
  `room_additions` images must not become dependencies of required missions.
- Map centre must remain blank with hidden markers non-interactive.

## Progress log

### Checkpoint 0 — started

Read the complete attached brief; confirmed current Git baseline and inspected
root documentation/project settings. Next: finish code/canon audit, preserve the
baseline, and implement the first complete procedure with shared state integrated
into the current walkthrough and HUD.

### Checkpoint 1 — working procedures and persistence

- Baseline recorded for 913 tracked files; exact copies of all 23 existing local
  edits preserved. No scene, artwork or furniture file has been changed.
- Canon found in briefing/prologue: Thura, Asteria-1, Erebos and five crew names/
  role codes. No detailed incident timeline, named missing-crew outcomes or ending
  implementation exists. Return records therefore flag uncertainty without
  inventing identities, deaths, Echo biology or a canonical transition.
- Added a state model/content catalogue owned by the existing walkthrough root,
  a pixel procedure panel, HUD inventory transfer/snapshot APIs and inherited
  walkthrough methods. The HUD remains the only inventory; the existing mission
  tracker remains the objective display. No new autoload or parallel manager.
- Implemented both contexts: roster comparison, cargo ID/tare/mass/seal decision,
  load allocation and original power controls, filter/scrubber diagnosis, original
  manifold/dosing, coupled pump/valve cooling, signed navigation correction and
  signal-aware reporting/acknowledgement. Runtime prop points are host children.
- First headless Godot runtime pass: **230 checks, 0 failures**, both complete
  sequences, original three service games, filter cancellation/resumption,
  inventory consumption and isolated save/load. This is state/UI-construction
  evidence, not yet a claim of complete physical or rendered validation.
- Next: verify real approach routes, selection, wall/door separation, concealment,
  safe exits, moving-instance attachment, UI at both sizes, normal launch and
  preservation hashes; strengthen malformed-save and duplicate-operation tests.

### Checkpoint 2 — physical integration and complete rendered sequences

- All 52 prop access points have a connected route on the existing player-sized
  floor mask and furniture collisions. Four initially isolated approach candidates
  were replaced with connected candidates; no furniture or collision was moved.
- Actual E/Esc tests select/open/cancel each prop, restore movement and prove the
  child interaction marker follows its host transform. Closed doors and room
  boundaries reject remote operations. All four concealment points enter/exit
  safely and publish the player's signal, group and metadata.
- Corrected a PhysicsShapeQueryParameters2D exclude-array copy issue in hiding.
  Concealed saves intentionally resume at their clear exit, with collision and
  control restored. No compatible enemy AI exists, so detection is unverified.
- Godot MCP rendered both full sequences through real Control nodes, including
  normal landing -> prologue -> walkthrough entry and the original three service
  games: **225 checks, 0 failures**. A verifier now waits for the panel's 5 Hz
  enabled-state refresh rather than treating a sub-frame timing race as failure.
- Physical validation: **534 checks, 0 failures**. Amara's original two jobs now
  use the same safe prop approach points and were completed with E, preserving
  her dialogue/task progression. Map references were changed to the duty tracker
  because the approved map viewport remains blank.
- State/persistence validation: **263 checks, 0 failures**, both contexts,
  shared-bus irrigation effects, labelled O2 reserve use, rejected malformed
  saves, a fresh-scene full reload and a fresh-scene partial filter reload with
  exactly one successful cartridge consumption.
- One headless validation launch exited with an engine access violation before
  producing a report. A diagnostic rerun completed all 263 checks with exit 0;
  the final import/runtime pass will check the settled files again.
- Next: finish the prop manifest/play guide, import/parse, inspect final rendered
  room/UI/sorting evidence and compare every baseline hash, including the exact
  23 existing edits. No commit, push or merge is authorised for this goal.

### Checkpoint 3 — final integration and acceptance audit

- Fixed shared-array inventory snapshots: saved/scenario inventory now owns its
  arrays, so later drag/drop cannot mutate the baseline. Added a direct regression
  check, full-inventory atomic transfers and fresh-scene partial-filter recovery.
- Communications now retains a named report containing the actual cargo, power,
  gas, irrigation, cooling and corrected-heading measurements plus phase evidence.
  Acknowledgement records that report ID and retains the transmitted snapshot.
- Added explicit scene-owner cleanup and weak inventory ownership. Existing
  planet transit retains the mission state, inventory and separate save namespace.
  The rendered runner traverses the original ship → planet → ship scenes and
  confirms walking resumes without replaying arrival or changing mission phase.
- The mission HUD keeps the existing tracker/marker architecture. Objective data
  now uses actual station access points; retired service markers are hidden rather
  than remaining at screen origin. The approved map stays blank/non-interactive.
- Final normal-renderer state/persistence test: **271 checks, 0 failures, exit0**.
- Final normal-renderer physical test: **663 checks, 0 failures, exit0**. Includes
  all52 targets/routes/solid footprints, four hiding places, obstructed exit/load
  recovery, Amara E jobs and correct objective-marker data.
- Final Godot MCP rendered test: **267 checks, 0 failures**. Both full sequences,
  original three service games, normal landing/prologue entry, all seven room
  captures, front/behind overlap, HUD/inventory/settings/blank map at1280×720 and
  1024×576, and the original planet round trip. Captures were visually inspected.
- Headless editor import completed with exit0 and no import/parse errors after
  allowing Godot access to its normal editor settings. Runtime headless reloads
  can still hit a native access violation while recreating hydroponics visuals;
  the cause is unresolved and that path is **not** claimed as passing. The same
  full automated test and three reloads pass in normal OpenGL. No engine upgrade
  or visual/collision alteration was made to work around the headless diagnostic.
- Prop manifest (52 hosts), full play guide, exact changed-file list and the
  requirement-by-requirement validation report are under `docs/`. The final JSON
  records current source hashes and actual reports; caches hold full logs/PNGs.
- Preservation audit:913 tracked baseline hashes checked, all23 existing edits
  byte-identical, no missing files and HEAD unchanged. Only the four intended
  existing scripts differ from baseline. All furniture/room scenes, artwork,
  transforms, collision geometry, imports, story scenes and project settings are
  preserved. Generated new-script UID sidecars are included. No commit/push/merge.
- Required normal-game acceptance criteria are satisfied. Limits remain explicit:
  development-only return entry, chair examine rather than unavailable seated
  animation, concealed saves resuming on safe floor, no enemy-detection claim,
  inactive lab/missing artwork deferred, and the headless runtime reload issue.

# Narrative and progression audit

Audit date: 2026-10-27. Repository: `C:/GodotProjects/Echoes_In_The_Ore`.
Baseline: branch `kaung`, commit `eaf38ccd994146fc48b91c5cfff55cf4a4c15467`.
The initial worktree was clean. This run changes audit documentation only;
isolated runners, screenshots, reports and test saves are ignored local evidence.
No gameplay, scene, dialogue, artwork, placement, collision or user-save edit is
part of this audit. No commit, push, merge or reset was performed.

## Finding

The project has a working prologue, walkable furnished ship, one conversational
crew NPC, substantial equipment procedures, and a mock surface excursion. It
does **not** yet have the story progression connecting those pieces. Finishing
either eight-duty watch records a report and leaves the player in that watch.
The incident, crew disappearance, Echo boarding, survival escalation and ending
are not playable transitions in this checkout.

The next work should connect a small arrival chapter through NPC assignments,
two selected procedures and a report-back, while repairing the existing hiding
system. Do not build a second inventory, dialogue framework or interaction owner.
See [mission plan](mission_story_plan.md), [hiding audit](hiding_audit.md) and
[cutscene handoff](cutscene_handoff.md).

## Evidence labels and scope

- **R — runtime verified:** normal Godot 4.7.2 Compatibility/OpenGL, RTX 4060;
  current game scripts/scenes, isolated test instances and saves.
- **S — source supported:** inspected current implementation/resources; not a
  claim of an observed normal-play transition.
- **D — documentation claim:** earlier report or concept note; checked against
  source/runtime below. Historical test counts are not new acceptance evidence.
- **B — brief premise:** requested broad storyline, without a repository-defined
  incident sequence or outcome. It constrains future work but does not fill canon.
- **P — proposed:** new recommendations in the companion documents, not shipped
  behavior or approved dialogue/cinematic content.
- **Missing/unverified:** no implementation, or evidence insufficient to claim it.

Inspection covered `project.godot`, root/storyboard/prop READMEs, all supplied
recent mission/interface documents, every runtime script's file inventory and
transition/concealment references, NPC/dialogue scripts, mission catalogue/model/
owner, HUD, player, planet, active scene overrides, separate lab scene and its
terminal controls. No on-disk `AGENTS.md` was found at the project/ancestor paths
or inside the repository. The user-supplied cross-project glass note is unrelated.
There is no fuller story bible, dialogue database or narrative design document
in the tracked repository. The prologue and arrival text are the strongest local
canon sources; mission development notes are not an independent story bible.

Preservation evidence: `.godot/narrative_audit/baseline.json` records all **951**
tracked-file SHA256 values and the initial Git status. The Godot user directory
is `C:/Users/Omen 16/AppData/Roaming/Godot/app_userdata/Echoes in the Ore`;
there were no non-log/cache user files at baseline. Test writes use only the
already-supported `res://.godot/mission_validation/narrative_audit/` namespace.
Final preservation results are in `.godot/narrative_audit/preservation.json`.

## Current player journey

| Transition | Actual owner/resource and trigger | What the player gets; saved state; next unlock | Finding |
|---|---|---|---|
| Launch → Start | `project.godot:14`; `scenes/ui/landing_screen.tscn`; `scripts/ui/landing_screen.gd:137` | One INITIALIZE EXPEDITION button fades to `earth_years_montage.tscn`. No Continue/load-chapter action. | **R** Actual keyboard activation tested. Root README's landing Skip Intro description is stale. |
| Thura's Earth years | `scripts/ui/earth_years_montage.gd:10` (`STORY_FRAMES`), `:309` (`_advance`) | Fourteen images/subtitles: Yangon parents, scholarship, failed assessment/retry, repair training, selection at 34, May's paper star. Space reveals/advances; intro Skip enters ship. | **R** All fourteen textures and ordered frame transitions traversed, then DAY 184 / approaching Erebos. No durable intro/cue-completed flag. |
| Montage → ship arrival | Montage `_enter_game` at `:338`; `scenes/ship/bare_ship_walkthrough.tscn`; root script `_ready` at `scripts/ship/bare_ship_walkthrough.gd:152` | Spawn `(900,500)` world; arrival overlay freezes player. Text says DAY 184, low Erebos orbit, survey/extraction, roster and three failed services. | **R** Arrival is automatic on ordinary ship instantiation; not an NPC welcome. Fresh mission model is outbound, no accepted assignment. |
| Arrival → first objective | `scenes/ui/arrival_briefing.tscn`, `scripts/ui/arrival_briefing.gd:102`; root dismissal `:536` | Directive: restore auxiliary power, filter and hydroponics; M advertised as deck schematic. HUD immediately lists all eight duties, all pending. | **R** Power CAPTURE/DIAGNOSE is interlocked: accept bridge-table duties first. Briefing omits that step, crew records and cargo prerequisite. Map is intentionally blank, so its advertised guidance is unavailable. This is a guidance gap, not a physically inaccessible table. |
| Bridge acceptance → duties | `ship_mission_catalog.gd:5`; `ship_mission_state.gd:73`, `:176`, `:289`; `ship_mission_walkthrough.gd:220` | Table `bridge.planning` sets `flags.assigned`; tells player to begin crew records then cargo. Roster terminal verifies records, not introductions to actual NPCs. Equipment work remains at its physical hosts. | **R/S** Accept → crew → cargo → power → life → hydro; engines need cargo+power; navigation needs crew+engines; comms needs all seven. All eight required to file the current watch. |
| Meet Amara → optional jobs | Root `_begin_amara_dialogue` `:426`, `_on_amara_dialogue_finished` `:461`; `crew_dialogue.gd:49` | E opens typewriter conversation. E accepts two jobs; Q declines at the offer. Flags: `_amara_intro_seen`, `_crew_tasks_unlocked`, `_completed_crew_tasks`. | **R** Decline/reoffer, accept, both E jobs, partial report-back and final thanks work. No mandatory introduction directs the player to her. See NPC findings. |
| Finish equipment → responses | Model `_done` `:67`, `act` `:261`; owner `_ship_state_changed` `:266` | Completed dictionary, equipment state, evidence, journal, dependent UI actions and HUD update. Science isolation affects irrigation; return power fault affects room flicker. | **R/S** Actual technical consequences work. No listener connects `objective_completed` to NPC report-back, relationship, cinematic or chapter advancement. |
| Duty completion → endpoint | Model `file_report`, `:290`; communications `:385`–`:401` | Prepare actual measured report, viable Earth protocol, three-second ACK, file at table. Sets `flags.report_filed`. | **R** Both full watches completed in rendered controls. Remains outbound/return respectively; no launch, incident, cutscene, credits or new chapter. |
| Ship → expedition | Root `_exit_ship_to_planet` `:264`; `ship_refresh_prompt` in base `:177`; airlock script | Nearby E or walking north through open exterior gate changes to `scenes/planet/mock_planet_exterior.tscn`. Mission snapshot/save path retained in Engine metadata. | **R** E exits with **zero** required duties complete. There is no readiness, EVA gear, crew briefing or report gate. This is mock surface transit, not a finished deployment cinematic. |
| Surface activities | `scripts/planet/mock_planet_exterior.gd:8`, `:148` | Three nearby E samples/scans increment scene-local `_sampled_sites`, HUD and feedback. No inventory item, incident cue, missing-crew flag or story evidence transaction. | **R/S** All three complete. Feedback calls location **VESPERA-IV**, conflicting with Erebos elsewhere. Source shows sample state is lost when the scene is recreated. |
| Surface → ship | Planet `_board_ship` `:162`; ship `_ready`; `ship_begin` in base `:43` | `returning_from_planet` skips arrival, restores ship-side snapshot, inventory and saved namespace, spawns at airlock. | **R** All samples collected → reboard still **outbound**, with no required duties complete in the fresh-route test. Amara job flags survive same-process transit. Surface sample progress is not handed back. |
| Return problems | HUD development controls `walk_hud.gd:1534`; owner `ship_start_development_scenario` `:417` | F3 TEST RETURN resets model/inventory and optional Amara flags to a separate fixture/save namespace. Changed evidence and procedures, not a canonical incident transition. | **R** Explicit menu tested. This shortcut proves the return procedures exist; it does not prove narrative entry. Amara remains physically present and offers jobs in this fixture. |

Normal transitions were invoked with actual keyboard/E events. Station-to-station
travel in the rendered narrative runner positions the test player at real access
points; it does not pretend to be manual traversal. A separate physical runner
traversed the floor routes with the real player movement/collision methods.

## Canon boundaries

| Subject | Confirmed implementation/content | What must not be inferred |
|---|---|---|
| Thura Min | Earth montage; planetary geology/robotics, selected at 34; mother/father, Yangon, sister May and paper star. Storyboard README identifies May as younger sister. | No new family fate, trauma outcome, romance or later ending choice. The star is a story image, not a current inventory/quest item. |
| Asteria-1 / Erebos | Montage/arrival/catalogue: crewed survey, autonomous ore extraction, anomalous magnetic signature; DAY 184. | “Approaching” vs “already in low orbit” needs an authored chronology decision, not a second invented voyage. Surface VESPERA-IV is a prototype inconsistency. |
| Crew | Maya Chen (CDR), Elias Ward (PLT), Amara Okoye (MED), Leila Haddad (ENG), Mateo Ruiz (MIN), from arrival and catalogue. | The codes support commander/pilot/medical/engineering/mining functions. They do not establish personalities, relationships, deaths or who took part in the incident. Amara's additional hydroponics work is implemented; it does not rewrite her listed MED role. |
| Incident, missing crew, Echo aboard, dangerous return | **B** Broad requested premise; return model contains explicitly uncertain old check-ins, recovered-material custody discrepancy and changed machinery evidence. | No exact incident scene/order, named missing/dead crew, boarding mechanism, creature capability/weakness, detection or damage rules, confirmed explanation or ending exists locally. Never derive Echo biology from EC/oxygen/electrical readings. |
| Lab records | Inactive `service_task_console.gd:1251` includes a Day 183 operator **M. Ilyanov**, specimen ERE-07/08 and containment records. | Prototype terminal records are not evidence of a sixth active crew member or a resolved canon identity. Do not equate M. Ilyanov with Taki or Thura. |

Return `crew.confirmed=true` means the **comparison conclusion** was recorded,
including “whereabouts unconfirmed”; it does not mean the named crew have been
found. The redesigned GUI correctly distinguishes that wording.

## NPC inventory and integration

| Person/content | Resource/scene; availability | Existing branches and flags | Verification / missing work |
|---|---|---|---|
| Thura | `scenes/player/player.tscn`, `scripts/player/player_controller.gd`; active player, four walking rows | Prologue text, HUD equipment and mission actions; no spoken dialogue tree or sitting/crouching frames | **R/S** Movement/input/collision used in tests. Do not duplicate player art as other named crew. |
| Amara Okoye | `scenes/ship/crew/amara_okoye.tscn`, `scripts/ship/amara_okoye.gd`, active root `BareShipWalkthrough/AmaraOkoye` | Intro; repeat offer after decline; accepted 0/1/2 jobs; phase-sensitive system observation appended by owner. Persistent intro/unlocked/completed flags saved in ship wrapper. | **R** Actual reachable E interaction and assignment→two tasks→report-back. Existing dialogue needs repair/extension, not replacement. |
| Maya Chen (CDR) | Name in arrival/catalogue/roster only | No actor, schedule, conditional conversation, assignment callback or story flags | **S/missing** May later introduce the watch via existing bridge terminal/dialogue overlay; this is **P**, not current content. Physical actor art unavailable. |
| Elias Ward (PLT) | Same roster sources; bridge equipment exists | No NPC/conversation/assignment | **S/missing** Proposed navigation/deployment handoff speaker after approved text; no new pilot biography assumed. |
| Leila Haddad (ENG) | Same roster sources; engineering workstations exist | No NPC/conversation/assignment | **S/missing** Proposed contextual engineering instructions/reaction through terminal/radio using current UI. |
| Mateo Ruiz (MIN) | Same roster sources; cargo/surface prototypes exist | No NPC/conversation/assignment | **S/missing** Proposed cargo/sample handling handoff; no incident participation/fate presumed. |
| Parents and May | Montage image/subtitle frames and storyboard notes | Ordered linear backstory only; no current ship actor/interactive branch | **R/S** Frames loaded in fresh route. No required later phone conversation or family outcome invented. |
| Taki-associated work | Merged separate `scenes/ship/lab_room.tscn`, `lab_room_preview.tscn`, `LAB_DEVICES` and lab controls/records in service console; history includes merges retaining the lab | Terminal UI variables/callbacks, not NPC narrative flags. No NPC called Taki, Taki sprite, dialogue resource or runtime Taki actor found. | **S/inactive** `LabRoom` absent from playable scene; initialized ship prompt path returns before legacy lab selection. Six image references unresolved. Do not activate/relocate the overlapping lab to make a story beat work. |
| M. Ilyanov | Inactive lab archive text only | No actor or dialogue; no mission write on reading archive | **S/inactive** Canon/identity unresolved, not an assigned player objective. |

### Amara behavior needing attention

- Saved placement is `(320,746)` relative to the translated ship; she snaps to
  nearby navigation floor, patrols eight hydro stations, then makes ship
  excursions after 10–15 stops and returns. Timers/random waypoints are behavior,
  not a persistent story schedule (`amara_okoye.gd:11`, `:169`, `:406`).
- Interaction is hard-coded to catalogue area `hydro`, even during ship
  excursions (`ship_mission_walkthrough.gd:190`). A controlled outside-hydro
  fixture at 20 px distance rejected TALK. Random excursion arrival itself was
  not awaited; source and this fixture establish the incompatible room rule.
- `set_in_dialogue(true)` stops the current animation/velocity once but does not
  suspend the patrol (`amara_okoye.gd:710`). With normal NPC physics enabled, she
  moved **29.01 px in 9 seconds while the dialogue remained open** in the final
  journey run; an earlier observer attempt saw a larger drift. Add a real dialogue
  lock with symmetric restoration, not a one-frame stop.
- Optional jobs complete immediately at E (`bare_ship_walkthrough.gd:520`). They
  write only `_completed_crew_tasks` and HUD, not the main measured hydro system.
  Runtime flow remained **25%**, aligned/restored false, before and after both
  jobs. Her “pump is flowing” thanks can contradict those readings. Label them
  as observations/calibration checks or connect their evidence to the actual work;
  do not quietly mark a real repair complete.
- Routine barks declare normal flow/oxygen/current regardless of phase/system
  state (`amara_okoye.gd:26`, `:125`, `:160`). Gate barks by actual knowledge and
  physical presence. The development return fixture still spawns her; it does
  not establish that Amara survived or is one of the missing crew.
- `CrewDialogue` is a reusable typewriter/offer overlay, but its speaker label
  and offer result are Amara-specific (`crew_dialogue.gd:49`, `:112`). Parameterize
  speaker, conversation/beat identity and completion payload minimally. Q only
  declines an end-of-offer; it is not a general dialogue cancellation command.
  Add interruption/resume policy without discarding the current UI/theme.
- NPC AI navigation reads the current visual floor texture; player walkability
  reads `FLOOR_TEXTURE`'s original mask (`bare_ship_walkthrough.gd:153`, `:167`,
  `amara_okoye.gd:643`). Share authoritative clearance for mandatory rendezvous;
  do not move floors/walls to solve NPC targeting.

## State, persistence and consequences

`ShipMissionState` is RefCounted; the existing walkthrough root owns it through
`ship_mission_walkthrough.gd`. `WalkHud` remains the sole inventory/equipment/
quickbar owner. `ShipProcedurePanel` and the existing service controls are views
and controllers. The only autoloads are input bindings and background music.

| Saved/temporary data | Current behavior and audit implication |
|---|---|
| Model snapshot (`ship_mission_state.gd:439`) | Version 1; phase, boolean flags/completions, phase evidence, bounded journal, stocks, partial original service progress, simulated systems, verification timers, consumption transactions, elapsed time. No chapter, cue receipt, NPC knowledge, conversation cursor, incident or ending state. |
| Owner wrapper (`ship_mission_walkthrough.gd:342`) | `echoes_ship_side`, version 1; model plus HUD inventory, position, legacy task/Amara flags, concealment source/exit. Validates before mutation; hidden loads resume on clear outside floor. |
| Save/load | Explicit F6/F9 or bridge table; atomic temp replacement. No automatic load at landing or regular ship start. No automatic save on every conversation/task/chapter. Normal default `user://ship_side_missions_v1.json`; F3 fixtures have separate filenames. |
| Planet transit | Engine metadata carries ship snapshot/save path within one process. Planet scene constructs its own fresh HUD inventory, does not consume ship inventory for samples, and does not persist `_sampled_sites`. Reboarding restores the old ship snapshot, so it does not incorporate surface item/progression changes. **S**, with three-sample/outbound-phase route **R**. |
| Narrative responses | Model completion emits `objective_completed`, but no current consumer starts NPC dialogue/cutscenes. Equipment state drives UI, downstream power availability and limited return power-room flicker; not new crew schedules or mission scenes. |
| Rest / storage | Rest reduces fatigue only; when assigned, requires verified power/life/cooling. Shared storage and recovery stock prevent simple lost-supply softlocks. Neither advances chapters. |

Do not use the current `systems.crew.confirmed`, a sampled-site boolean, or
`report_filed` as an invented all-purpose chapter flag. A small versioned story
section and explicit transitions are proposed in the plan; they do not exist now.

## Room integration constraints

The seven furnished groups and stable IDs should remain intact:

| Group | Actual collection in `BareShipWalkthrough` | Lighting/internal room |
|---|---|---|
| Bridge | `BridgeRoomProps` | `r01_bridge` |
| Crew quarters | `CrewLivingQuarterProps` | `r07_crew_quarters` (reference map label 05 is not the internal ID) |
| Cargo | `CargoBayProps` | `r08_central_bay` |
| Engines | `EngineRoomProps` | `r06_engine_room` (reference label 04) |
| Power | `PowerMaintenanceRoomProps` | `r04_power_maint` |
| Life support | `LifeSupportRoomProps` | `r05_life_support` |
| Hydroponics | `HydroponicsRoomProps` | `r10_hydroponics_west` |

Catalogue room rectangles are interaction regions, not new room geometry.
Saved root offset `(-30,-23)` and walkthrough instance overrides take precedence
over starter coordinates in prop READMEs. The actual floor mask, doors, furniture
physics and dynamic access points govern routes. All 52 catalogued targets still
have reachable access paths in the physical audit. Planning route tests held
pressure doors open **in the test instance only**; separate separation checks
verified closed-door and cross-room rejection. No wall/floor/door edits were used.

Ops/mess, med/recess, shuttle and especially the overlapping lab are not silently
required by the proposed chapter. Active shuttle cargo is optional storage;
the lab needs six missing `art/concepts/lab_props/room_additions/*.png` files and
a separate ownership/layout decision before any required narrative use. The exact
unresolved files are `sample_cabinet_user_4dir.png`, `ppe_rack_user_4dir.png`,
`decon_sink_user_4dir.png`, `lab_waste_user_4dir.png`, `wash_sink_user_4dir.png` and
`analysis_table_user_4dir.png` in that `room_additions` directory.

## Documentation claims checked

| Earlier source | What current evidence supports or corrects |
|---|---|
| `docs/ship_missions_playguide.md` | Accurate eight-duty gates, explicit development return, safe supply transactions and watch endpoint. Its “usable concealment” is mechanically true but incomplete for wall-safe entry, occupancy, connected exit and physical presentation; see hiding audit. |
| `docs/ship_prop_interaction_manifest.md` | 52 active hosts match source/runtime. Four hiding hosts match. The per-host interaction coverage does not prove NPC story responses, cinematic progression or appropriate entry choreography. |
| `docs/ship_missions_validation.md` | “Coherent sequences” establishes technical dependencies, not coherent story transitions. Earlier Amara test directly called conversation setup and froze her physics; it could not catch current patrol/dialogue drift or outside-hydro interaction failure. |
| `docs/ship_interface_redesign.md`, `ship_interface_validation.md` | Native dynamic equipment UI, model/action binding and phase readouts are present and reused. This audit completed both watches with those controls. Prior broad GUI/drag-drop totals were not rerun as a substitute for narrative checks. |
| Cargo/engine prop READMEs | Their original “no hiding system / future markers only” paragraphs predate the mission layer and are now stale. Starter placement tables also omit saved walkthrough overrides. |
| `art/storyboards/thura_earth/README.md` | “Not wired into a game scene” is stale: all fourteen current montage frames are reachable at normal Start. |
| Root README | Overview/controls predate some UI changes; intro has Skip but landing no longer has a separate skip button. Generator helper filenames listed there are absent. No restoration done. |

## Runtime evidence and limits

Isolated observers live under `.godot/narrative_audit/`. They inherit existing
validators where useful, without editing them or changing game rules. The
completion runner's copied test base only redirects test output/save paths.

| Current run | Evidence and meaning |
|---|---|
| Fresh journey: **32 checks, zero assertion failures** | `journey_report.json`, `journey_runtime.log`: actual Start, all 14 prologue frames, arrival, first-duty interlock, table acceptance, reachable Amara decline/accept/tasks/report-back, ordinary airlock→three samples→reboard, explicitly separate TEST RETURN. Findings above are observations, not incorrectly counted as failures of the audit tool. |
| Physical/hiding: **670 checks, zero assertion failures** | `hiding_report.json`, `hiding_runtime.log`: 52 selectable targets, continuous real-player routes, solidity, closed-door/room separation, all four hide entries/exits, repeats, blocked entry/exit/load, inputs, current transforms/markers and controlled failure fixtures. Reproduced defects are recorded as observations, not claimed fixed. |
| Complete watches: **219 checks, zero assertion failures** | `completion_report.json`, `completion_runtime.log`: real procedure Controls and original three service games, live six-second stable verification, both full watches, reports/ACK/file. Return is entered explicitly through the development menu. Both remain in the same phase after filing. |
| Readable dialogue captures | `dialogue_visual_report.json`: additional current NPC introduction, offer and thanks captures after actual reveal input. |

Fresh-run captures include [arrival](../../.godot/narrative_audit/screenshots/04_arrival_briefing.png),
[initial tracker](../../.godot/narrative_audit/screenshots/05_fresh_deck_tracker.png),
[blocked directive](../../.godot/narrative_audit/screenshots/06_arrival_directive_blocked.png),
[Amara introduction](../../.godot/narrative_audit/screenshots/15_amara_introduction_readable.png),
[report-back](../../.godot/narrative_audit/screenshots/17_amara_reportback_readable.png),
[mock samples](../../.godot/narrative_audit/screenshots/12_samples_complete.png),
[reboard still outbound](../../.godot/narrative_audit/screenshots/13_return_still_outbound.png),
[filed outbound watch](../../.godot/narrative_audit/screenshots/complete_outbound_complete.png)
and [filed return watch](../../.godot/narrative_audit/screenshots/complete_return_complete.png).
These are local ignored evidence, not shipped assets. Screenshot existence alone
is not proof of canon or of a tested transition.

The first journey observer stopped on a **test-script** freed-Node typed-argument
error after the airlock transition. Its partial report is retained as
`journey_attempt1.json`; the observer was corrected and the complete route rerun.
No gameplay code was changed to make it pass. Current runs retained existing
enum/shadowing warnings. The previously known intermittent native reload/shutdown
crash remains a limitation; it was not observed in the completed audit runs and
no unrelated engine investigation or upgrade was attempted.

## Priority gaps

1. **Arrival guidance and chapter state:** one understandable immediate objective;
   assignment/diary/procedure gates must agree. Stop advertising an unfinished map
   as a route solution. Preserve the intentionally blank map.
2. **NPC reliability and consequence:** lock patrol during talk, allow legitimate
   conversation where the NPC actually is, preserve conversation state, and base
   responses/barks on verified equipment and known story facts.
3. **Avoid the all-machine story checklist:** scope chapter work orders explicitly;
   separate physical safety from the arbitrary crew→cargo→all-services graph.
   Keep the full maintenance scenario for testing/optional work.
4. **Departure and surface handoff:** gate normal deployment deliberately, share
   inventory/sample evidence, resolve location wording, and persist incident/cue
   receipts. Do not relabel current mock reboarding as the return chapter.
5. **Functional hiding:** repair connected entry/exit, crate-gap semantics and
   occupancy/presentation. Compatible enemy perception and harm rules are absent;
   concealment cannot be claimed to prevent detection or confer invulnerability.
6. **Incident/return/ending:** exact canon and teammate cinematic interfaces are
   missing. Bridge evidence can acknowledge uncertainty, but cannot invent fates.

No irreversible mission softlock was found in the tested maintenance procedures:
restore/cancel, partial-service snapshots, shared stock and recovery issue exist.
There are substantial **progression dead ends** (filed watch has no next chapter),
guidance contradictions and hiding path defects. Those distinctions matter more
than a green aggregate test count.

One further **source-supported latent transition risk**: ship `_exit_ship_to_planet`
and planet `_board_ship` set their transitioning flag and ignore the return value
of `change_scene_to_file`. Unlike the montage's recovery branch, a failed target
load has no retry/reset path and can leave interaction suppressed. Both supplied
target scenes loaded in this audit; a load failure was not injected. Handle that
error in the later handoff milestone rather than claiming the current success
path proves cancellation/resource-failure safety.

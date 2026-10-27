# First-watch implementation log

Scope: approved five-mission first watch, reliable NPC conversations, versioned
story persistence/Continue, existing hiding repairs and intro/arrival/text-handoff
cue contract. No incident, Echo, enemy AI, ending or planet rewrite.

Baseline 2026-10-27: `kaung` at `eaf38ccd994146fc48b91c5cfff55cf4a4c15467`.
Only the four prior narrative documents are untracked. Exact hashes/backups for
951 tracked files plus those four documents are in `.godot/first_watch_baseline/`.
Preserve all room/art/geometry/instance overrides; no Git mutation is authorized.

## Checkpoints

- [x] Read approved brief and reconcile audit/source baseline.
- [ ] Scoped technical work orders and five-mission story state.
- [ ] Contextual Maya/Amara/Leila dialogue, NPC lock and primary-objective HUD.
- [ ] Versioned saves, conservative legacy migration and landing Continue.
- [ ] Three WEST locker transitions, connected route/occupancy/load recovery.
- [ ] Cargo behind-stack route/cover feasibility and implementation or exact blocker.
- [ ] Intro/arrival/handoff receipts, production text acknowledgement, departure guards.
- [ ] Actual-input first-watch traversal and restart/legacy/fixture regressions.
- [ ] Two-size rendered review, preservation audit and final guide/status.

## Decisions

- Existing walkthrough remains the input/interaction owner. Pure story/save data
  helpers may support it; no new autoload, active inventory or dialogue framework.
- New story watch requires power and irrigation only. Existing maintenance
  fixtures keep their original eight-duty graph and real procedure assertions.
- Locker entry uses supplied open/closed WEST states, controlled movement and
  validated external clearance. Cargo uses a real walk-around route if a covered
  pocket fits; never ignore its crate bodies or shrink the player.

## Progress

Initial reconciliation confirms the audit defects remain present and all baseline
game files match the audited commit. Implementation has begun; acceptance remains
unproven until the runtime and persistence checks below are completed.

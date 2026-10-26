# Ship-side missions: play and edit guide

## Start and controls

Run `project.godot` normally (F5). Start/Skip Intro and the Asteria-1 arrival
briefing retain their existing flow. The ship starts with the pre-incident duty
context; the existing arrival text/date has not been rewritten. Go to the bridge
`MissionPlanningTable`, approach its clear edge, press **E**, and accept duties.
The table contains all eight objectives, prerequisites, recorded evidence and the
recent log. Seven rooms provide those objectives; the bridge provides two.

- WASD/arrows: existing walking. Nearby doors retain their existing automatic use.
- E: access the single station named in the prompt; when concealed, exit safely.
- Esc or square X: close procedure controls. Completed steps/isolation remain
  recorded; unspent supplies stay carried. Use Restore to cancel an isolation.
- I: existing inventory/equipment. 1–9/mouse wheel: existing quick slots.
- M: approved blank ship-map frame. It has no visible/clickable task/player pins.
- F6/F9: save/load ship-side progress. The table also has Save/Load controls.
- F3: existing development menu. **TEST OUTBOUND / TEST RETURN** reset only the
  ship-side scenario and its inventory to a clean starting fixture. These are
  explicitly development entries, not canonical chapter transitions. They use
  separate save names. Save your current watch before switching a test scenario.

Measurements are labelled gameplay simulations, not operating instructions for
real machinery. Action prerequisites and unavailable-action reasons appear at
each station. Both columns scroll when necessary. All diagnostics and clues are
available in the game; the steps below are a solution guide.

## Outbound duty sequence

1. **Bridge planning table:** accept duties. Optional Record actions collect the
   phase's crew/system notes into the table's evidence log.
2. **Crew quarters desk/table:** read A1-DUTY, review authorised watch/check-in
   entries, then conclude that routine records match the expected watch. Shared
   drawers/wardrobe store/retrieve supplies through the same HUD inventory.
3. **Cargo:** read CARGO-A12's manifest and exterior seal at the bundle. Zero the
   empty scale (20 kg check reference). At the mover transfer the identified load
   to the scale. Read 84.0 kg against 84.0 ±0.5, then accept/secure it. This bounded
   handling changes custody/location state; it does not move saved furniture.
4. **Power:** observe loads and diagnose an unsynchronised auxiliary bank. Isolate
   the auxiliary/science service circuit; essential allocation stays at 70. At
   the converter choose 70/20/10 or 70/10/20. Carry the engineering multitool
   (already in the initial inventory, or retrieve it from shared storage). At
   the power-cell module use the original capacitor controls, targeting the
   displayed ranges (67/43/77 works). Restore at the breaker, observe six healthy
   seconds, then verify. An attempted 115-unit allocation is rejected safely.
5. **Life support:** normal oxygen with low airflow identifies the filter
   restriction. Retrieve FILTER-A from drawer 1 or the cargo locker, isolate the
   housing, and use the original filter controls: release latch, rotate twice,
   seat, set airflow in 62–72% (67 works). Successful completion consumes one
   filter. Restore circulation, observe six healthy seconds and verify.
6. **Hydroponics:** normal EC/pump capacity with poor delivery identifies the
   manifold restriction. Isolate delivery and use the original labelled valves
   (rotations 1/3/2), carrying the multitool. Restore, observe delivery/plant
   recovery for six seconds and verify. Amara still offers her separate optional
   pump inspection and seedling sensor jobs through her existing dialogue.
7. **Engines:** compare both loops. Pump 1's delivery is weak while its valve is
   open. Diagnose pump service, request 60% output and isolate pump 1. Use the
   trolley to transfer a sealed COOL-02 kit from cargo to the upper engine
   locker, retrieve it there (or issue the labelled coolant from the rack), and
   service pump 1 with the multitool. Restore the loop. Wait until both flows
   recover and temperature is ≤65°C for six stable seconds, then verify.
   Restore nominal output at a turbine. All four turbines have separate IDs and
   identify their assigned cooling loop; pumps/valves affect the shared readings.
8. **Bridge helm/flight console:** compare planned 92° and instrument 98°.
   Apply -6° correction and verify within ±0.2°.
9. **Bridge flight-control station:** prepare the verified report. With 82%
   signal, select Earth relay / standard packet, transmit, and wait three seconds
   for acknowledgement. The local crew channel cannot acknowledge an Earth report.
   The report preview retains the actual cargo, circuit, gas, irrigation, cooling
   and corrected-heading readings plus the evidence recorded for this phase.
10. **Planning table:** file the eight verified procedures. This finishes the
    ship-side watch; it does not advance/replace the planet, incident or ending.

After cargo and power verification, cooling can be done before or after the
life-support/hydro chain. Communications waits for all seven preceding duties.

## Post-incident return development sequence

F3 → TEST RETURN gives a separate test context. No complete planet-to-incident
transition, named missing-crew outcomes or ending implementation was found in
the checkout. Existing Thura/Asteria-1/Erebos/crew identities and roles are kept.
The new return notes describe uncertain records and confirmed system conditions;
they do not establish a cause, power or weakness of Echo.

Accept duties at the table and follow the same dependency sequence, with these
changed diagnoses and decisions:

| Duty | Return evidence and procedure |
|---|---|
| Crew check-in | The watch record predates the incident. Record present whereabouts as **unconfirmed**, not matched; no named fate is assigned. |
| Cargo | CARGO-A12 reads **86.0 kg** and has a seal/custody-record gap. **Quarantine unopened** after the normal tare/transfer/weigh comparison. |
| Power | Banks are already calibrated, but 70+35+10 exceeds capacity. Diagnose **load**, isolate science service, choose a safe allocation, restore and verify. No repeated bank game is needed. |
| Life support | Oxygen 20.9%, airflow 67%, CO₂ 0.17%: diagnose **poor scrubber performance**. Retrieve SCRUB-A, isolate and service the scrubber with the multitool. Restore and verify CO₂ recovery. Replacing the outbound filter is unavailable here. |
| Optional O₂ reserve | Reserve is 20%; retrieve **O2-01** from the cylinder rack and swap the labelled reserve at the tank rack after diagnosis. It restores reserve charge and does **not** repair CO₂ removal. |
| Hydroponics | Healthy pump, EC3.6 and poor delivery identify **reservoir imbalance**. Isolate and retrieve BUFFER-A. One dose reduces EC by 1.6 → 2.0. Wrong doses are rejected before consumption. Restore and verify. |
| Cooling | Both pumps are healthy; loop 2 has a large valve pressure drop. Diagnose **valve 2 restriction**, reduce output to 60%, isolate valve 2, open it with the multitool, restore and verify both loops/temperature. Restore nominal output after sign-off. |
| Navigation | Planned272°, instrument281°: apply **-9°**, then verify. |
| Communications | Signal45% cannot support the standard packet. Select **Earth relay / repeated critical packet**, transmit, await acknowledgement, then file the table report. |

Power state is connected to equipment: science-service isolation stops irrigation
delivery and gates navigation correction/transmission, while essential supply
remains live. A safe restore re-enables the downstream system. Return flicker is
limited to the power room until its fault is verified.

## Storage, rest, concealment and recovery

Shared drawers, the wardrobe, cargo/engine lockers and the optional shuttle
bundle use the existing inventory slots. Full inventories reject retrieval
without decrementing stock. Items can be stored at another designated point and
retrieved there. Cylinders retain COOL-02/O2-01/N2-03 identities; inert gas cannot
substitute for coolant/oxygen. The cargo locker can issue a logged replacement
kit only when total service stock is low; repeated requests do not multiply it.

Capsule rest reduces fatigue without changing chapter/events, objectives or
unresolved evidence. Once duties are accepted, essential power/air/cooling must
be verified first. Chairs have operator-access/examine actions: only walking
frames exist in the supplied player setup, so no seated/tool animation was
fabricated.

Cargo locker, tied-box bundle, and both engine lockers have usable concealment.
Enter from the clear access point. E validates a safe exit; if every nearby exit
is obstructed, remain concealed and retry after it clears. The player exposes
`concealment_changed`, `is_concealed`, `concealment_source`, group
`concealed_players`, and matching metadata for future enemy integration. **No
compatible enemy AI exists here, so detection behavior is not validated.**

## Persistence

Default save: `user://ship_side_missions_v1.json`. Development contexts use
`user://ship_side_missions_dev_outbound.json` and
`user://ship_side_missions_dev_return.json`. Tests only use
`res://.godot/mission_validation/`; no existing user save is read or overwritten.

Saving includes the phase, objectives, evidence/log, storage ledgers, consumed
transaction IDs, equipment readings/isolation, partial original service controls,
HUD inventory/hotbar/equipment selection, Amara progress and player location.
Load is explicit (F9/table), not an automatic chapter/phase change. Close an open
legacy service game before loading. Partial work resumes on reopening it.
Concealed saves deliberately resume outside at a validated exit with movement
and collision restored. The existing planet transition carries the same state
in memory; it does not automatically convert it to the return development phase.

## Editing furniture and interactions

Open `scenes/ship/bare_ship_walkthrough.tscn`. Expand the existing room collection
(enable **Editable Children** on its instance if needed), select the individual
prop root and move it with the 2D Move tool/Inspector Position. Leave its existing
art direction, Artwork Scale, root scale, footprints and sorting conventions as
appropriate for that reusable scene. No placement or collision values were
changed by this work.

At runtime the walkthrough adds a `ShipInteractionPoint` child to each catalogued
host, using its actual collision bounds, saved transform and reachable floor.
Moving the host moves that child; on a new run its access point is recomputed.
Runtime-only markers are not extra saved furniture instances. The inspector on
the walkthrough exposes **Ship Interaction Reach** (default30) and its save path.
Stable IDs/host paths live in `scripts/ship/ship_mission_catalog.gd`; update the
catalogue when renaming a prop node. See the adjacent prop manifest for every ID.

## Deferred areas and presentation limits

Shuttle stores are optional. Med-bay/central recess remains environmental; there
is no claim of finished medical gameplay. Ops/mess hall/other unfinished rooms
retain their existing layouts for future duty/social stations. The separate lab
remains inactive, with its six missing `room_additions` images unresolved; no
required objective or active walkthrough dependency loads it. Existing floors,
wall-art alignment limitations, doors, furniture sorting and lighting architecture
are preserved. The blank map remains blank.

Verification scripts and actual results are recorded in
`ship_missions_validation.md`; screenshots are under the ignored
`.godot/mission_validation/screenshots/` directory.

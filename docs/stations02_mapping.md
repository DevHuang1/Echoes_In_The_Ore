# Stations 02 board to gameplay mapping

Every applicable station type below now opens its own fixed 1280×720 Stations 02
board, with proportional 1024×576 scaling. Visual verification is in progress:
rendered comparisons still show text, control, and rasterization differences,
so this document does not claim a 1:1 match. The tied-bundle board is deliberately
excluded from the hiding bundle.

The approved HTML export supplies the station materials, controls, diagrams, and
layout reference. `EitoLayer` hosts the individual native Control screens, while
`ShipMissionState` owns actual actions and equipment truth. The HTML demonstration
state does not become game state. The generic `ShipProcedurePanel` remains a
fallback for content not covered by the artifact. Existing approved Eito power,
irrigation, and crew-record screens retain their separate layouts and fonts.

| Export board | Playable station | Native action and data mapping |
| --- | --- | --- |
| Cargo inspection scale | `cargo.scale` | Read manifest and exterior seal, zero the empty platform, use the mover to transfer the identified load, read mass, then record accept/quarantine. Mass, location, and seal state come from `systems.cargo`. |
| Electric pallet mover | `cargo.mover` | The illustrated key, fork, destination, and tiller sequence ends in one real `move_load` action. The route animation is a schematic of the handling instruction; no physical driving is simulated. A blocked click explains the next step. Battery, fork-height, speed, and pre-weigh load-cell values are shown as unknown because the game has no such telemetry. |
| Maintenance trolley | `cargo.trolley` | The artifact's trolley, drawer, destination, custody, and route composition remains. Its engine-locker destination and physical pushing claim are replaced with real trolley drawer stock and carried inventory. The final ISSUE control calls `transfer_kit` only after cargo inspection; one issue deducts one kit once. Other stock uses the existing drawer transfer controls pending this board's remaining port work. |
| Secured cylinder rack | `cargo.cylinders` | The illustrated work-order, label, chain, and lift sequence ends in one real `cylinder` issue of COOL-02 from stock to carried inventory. Wrong O2/N2 selections warn without issue. Repeated clicks do not deduct stock. The model has no pressure telemetry, so the reader displays an unknown pressure and no live pressure cells. |
| Tied cargo bundle | `cargo.bundle` | Hiding only. Its prototype inspection board is not connected to the hiding bundle. Inspection belongs to `cargo.scale`. |
| Supply stores and lockers | Quarters drawers/wardrobe and trolley drawers | The dedicated supply-store board opens at each actual quarters drawer or wardrobe and uses live stock and carried inventory. Transfers use the real take/store actions, one item per click. Its four metal store tabs retain the artifact arrangement, but remote stores cannot be operated from the current furniture. Cargo and engine lockers expose H hiding and no storage or task panel. The trolley retains its dedicated issue board. The prototype's fictitious stocked locker bins and duty-kit button are excluded. |
| Air duct assembly | `life.duct` | Dedicated section illustration and controls use live airflow, oxygen, CO2, and reserve readings. The model has no filter differential-pressure sensor or twelve-sample trend, so those readouts show unavailable/current-only data in their original positions. Observe, diagnose, isolate, restore and verify use existing actions. Verification stays locked until the actual healthy-reading timer elapses. Routine first-watch inspection cannot authorize an unassigned repair. |
| Air filter service | `life.filter` | The eight illustrated housing controls replace the old three-stage service screen while retaining its prerequisite, FILTER-A consumption receipt, isolation, restoration, and healthy observation semantics. The percentage setting is labelled airflow, not prime pressure. Mid-procedure steps and setting are saved in the existing mission snapshot; the final confirm calls the existing one-time `legacy_complete("air_filter")` receipt. |
| CO2 scrubber | `life.scrubber` | The return-watch board uses current CO2, aggregate scrubber performance, and the actual SCRUB-A service action. The dual-bed drawing remains an equipment mimic; the game has no individual bed saturation or two-hour trend, so the data panels explicitly show current-only and unavailable bed detail. The clamp step requires the multitool. Restoration and verification still use the ship's six-second healthy-reading timer. |
| Oxygen supply rack | `life.oxygen` | The seven-step rack drawing and controls guide a reserve service; the final check calls the actual one-time `oxygen_reserve` action, which consumes O2-01 only when reserve is below 50% and a diagnosis exists. Cabin oxygen and aggregate reserve are live. Individual tank levels, outlet kPa, and physical valve telemetry do not exist, so the corresponding labels show unknown or checklist status. It cannot substitute for CO2 removal. |
| Coolant pump | `engine.pump.1` and `.2` | Both instances open the extracted cutaway and charge-port board with their own live loop flow and pump health. The ship has no suction/discharge pressure, RPM or sight-glass sensor, so the corresponding numerals are unknown and the readouts use pump health, flow and shared engine temperature. In outbound maintenance, pump 1 retains comparison, diagnosis, turbine reduction, isolation, multitool and one-time COOL-02 service, restoration and six-second stable verification. Pump 2 is inspectable but cannot repeat pump-1 service. The seal check is a UI checklist; the real service result occurs only at `engine_service`. |
| Main turbine | `engine.turbine.1` through `.4` | Each turbine opens the dedicated board with its mapped cooling loop (1 and 3 use loop 1; 2 and 4 use loop 2). Inspect records this machine's inspection, while 60% output and nominal restoration call the existing engine actions. The prototype's clickable PUMP VERIFIED button is a read-only indicator driven by engine verification, mapped loop flow, and temperature. The ship has no RPM, exhaust, or thrust telemetry; the gauge illustrates commanded output and the data display uses actual output, loop flow, and temperature instead. |
| Valve manifold | `engine.valve.1` and `.2` | Each instance opens the extracted three-wheel manifold with its own loop flow and opening. The ship records one valve per loop: the two outer wheels are schematic and cannot change gameplay state. In the return-watch valve-2 service, the centre handwheel guides three visual turns, while live opening stays unchanged until the final real `engine_service` action. Diagnosis, turbine reduction, isolation, multitool, restoration, and six-second verification remain required. The model has no numeric pressure sensors, so its dial numerals and pressure-drop label are replaced by unavailable pressure readings and live flow. |
| Helm console | `bridge.helm` and flight consoles | The extracted compass layers, flight-plan paper, four readouts and correction encoder show actual planned/instrument/correction values. Reading both references calls `route`; APPLY calls `correction`; VERIFY calls `nav_verify` with the existing ±0.2° tolerance. All consoles share navigation state. The game has no burn countdown or leg number, so those sample values are replaced by the actual phase and an unknown burn time. |
| Communications station | Upper/lower flight stations | The meter, teletype, protocol selector, guarded switch and log use the actual duty report and signal. Both stations share the retained report, selected protocol, transmission and ACK. The original three-second acknowledgement timer remains authoritative; CHECK ACK only reads it. Cells display that timer rather than fictitious packet telemetry. The full live report can be scrolled in the original paper viewport. |
| Planning table | `bridge.planning` | The central schematic viewport remains blank, without room markers or hit targets. Duties, briefing and records use actual first-watch receipts, objective, measured summary and Maya actions; the maintenance scenario separately lists its existing eight duties. Hearing the briefing opens the existing conversation. Summary sign-off still requires the authored repair/report prerequisites. The game has one real save slot: the first tape connects to it; the other two tapes are visibly unavailable. |
| Nutrient pump check | `hydro.pump` | The original pump, meter, handhelds and card remain, with live nutrient-flow percentage and the existing optional Amara receipt. There are no vibration, bearing-temperature, hours or prior-check readings in the game, so those instruments show unavailable data. The unavailable probes cannot simulate healthy readings. Service remains on the hydro control console. |
| Seedling rack check | `hydro.seedlings` | The rack and instrument composition remain, but no humidity/reference/offset telemetry exists. The dial is visibly unavailable and cannot change mist control. Inspecting the housing then recording calls only the existing optional crew-check receipt; it does not claim a calibration or repair. |

The rendered in-level flow currently passes 418 checks at both 1280×720 and
1024×576 on Windows, including the planning
table's actual briefing entry, optional activity authorization, wrong heading
corrections, shared alternate consoles, and a real elapsed ACK timer. This is
behavioral evidence, not a visual-fidelity claim.

## Gameplay constraints retained

- Maya's and Amara's story authorization gates still apply in normal first-watch play. A blocked control shows the current prerequisite.
- Power, life support, hydroponics, and engine verification still require sustained healthy readings; the interface does not replace timers with a series of confirmations.
- The prototype's sample stock counts, telemetry, report prose, and six-duty planning sequence are not copied into the game.
- Existing map/task data remains intact, while the ship map and planning schematic stay visually blank until approved artwork and behavior exist.
- Hiding uses the existing single controller. H enters/exits the cargo locker, cargo tied bundle, and both engine lockers; those props offer no supply transfer, inventory, or task GUI.

Locker enter/exit uses the existing pressure-door sound at −18 dB through the
project's Master bus, so it follows the existing volume control. The project
has no separate effects bus. The tied bundle stays silent because no suitable
existing rope/fabric movement sound was found.

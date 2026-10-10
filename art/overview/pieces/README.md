# Asteria hollow overview pieces

This pack splits `asteria_overview_hollow.png` into **10 named room pieces** and **20 non-room structure pieces**.

- `rooms/` contains transparent PNGs clipped to the room outlines shown in `piece_layout_guide.png`.
- `non_rooms/` contains a 4 × 5 set of transparent tiles for all remaining pixels: corridors, connectors, bulkheads, hull, windows, antennas, thrusters, exterior structures, and starfield.
- `piece_manifest.json` records each piece's original pixel origin and bounds. Composite each PNG at its recorded origin on a 1774 × 887 canvas to reconstruct the source exactly.
- `rooms_contact_sheet.png` and `non_rooms_contact_sheet.png` preview the pieces.
- The split was checked for complete pixel coverage and exact reconstruction of the source.

Room polygons follow the visible wall boundaries; some shared wall pixels are assigned to the first room listed in the manifest. The source overview remains unchanged.

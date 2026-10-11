# Wall matched pressure doors

`pressure_door.tscn` is the reusable top-down pressure door, using the wall-matched sprite at `art/overview/door_components/pressure_door_wallmatched.png`. Each active opening is a separate named instance. The panel rotates only at the vertical opening (marker 06).

The eight active doors correspond to markers 02–09 in the supplied placement markup. Marker 01 is omitted as requested. The marker crosses landed on different sides of the wall strips, so each gate center is placed at the midpoint of its visible wall thickness; `wall_depth` matches that strip. Coordinates in this table are map/world centers. The walkthrough parent offset is `(3, -4)`, so scene-local positions compensate for it. The artwork is drawn at 90% of `wall_depth`, symmetrically around the same center, to keep its outer frame inside the wall edges; door blocking still uses the full configured depth.

| Marker | Door id | Wall center | Orientation | Opening width × wall depth |
| --- | --- | ---: | --- | ---: |
| 02 | `upper_service_south_entry` | (1052, 363) | Horizontal | 40 × 30 |
| 03 | `spine_south_entry` | (1206, 362) | Horizontal | 38 × 32 |
| 04 | `central_bay_north_entry` | (684, 431) | Horizontal | 42 × 26 |
| 05 | `starboard_service_entry` | (1260, 431) | Horizontal | 40 × 26 |
| 06 | `central_bay_west_entry` | (710.5, 500) | Vertical | 36 × 28 |
| 07 | `lower_deck_west_entry` | (530, 660) | Horizontal | 30 × 28 |
| 08 | `lower_deck_center_entry` | (870, 660.5) | Horizontal | 34 × 30 |
| 09 | `shuttle_bay_north_entry` | (1263, 528) | Horizontal | 24 × 30 |

The two leaves meet in the middle while closed. As the player approaches, they split and slide in opposite directions behind the wall layer, then meet again after `close_delay`. Set `locked` to keep an instance shut. Closed instances join `ship_door` and answer `blocks_position()` for movement.

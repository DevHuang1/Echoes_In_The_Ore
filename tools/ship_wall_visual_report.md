# Valkyrie wall visual integration

## Changed files

- `res://scenes/ship/bare_ship_walkthrough.tscn`: only the wall texture
  reference, WallLayer texture filtering and WallLayer scale changed.
- `res://README.md`: current wall asset and link to this report.
- `res://tools/validate_ship_wall_visual.gd` (and generated UID): runtime audit
  and screenshot capture.
- `res://tools/ship_wall_visual_report.md`: this report.

The supplied wall PNG and its existing import settings are unchanged. Original
wall files remain in place. The separately supplied replacement floor image was
not used or changed.

## Existing setup and alignment

The walkthrough root has a saved translation of (-30,-23). FloorLayer is an
uncentered Sprite2D at local (0,0), scale (1,1), Z=-2. Player walkability and the
crew navigation grid sample the original floor's alpha, independently of wall
art. Furniture and the center recess have separate collisions. Pressure doors
have their own scripted blocking and opening logic. WallLayer is visual only.

| Image | Native dimensions | Alpha-used bounds | Display scale |
| --- | --- | --- | --- |
| Original walls | 3548×1774 | (0,0,3548,1774) | Previously (0.5,0.5) |
| Valkyrie walls | 1774×887 | (0,0,1774,887) | (1,1) |
| Original floor | 1774×887 | (63,24,1641,839) | Unchanged (1,1) |

All three source PNGs are 8-bit RGBA. The wall images contain real transparent
regions, with no uniform outer transparent margin to trim. The new PNG has
828,949 fully transparent pixels, 4,029 fully opaque pixels, and 740,560 partially
transparent pixels; most visible artwork has alpha 252–254, so partial alpha
does not mean the whole wall is translucent.

The new wall is at local (0,0), global (-30,-23), matching FloorLayer. Its native
canvas, bow, corridor intersections and engine layout establish the common
coordinate system. No floor or furniture transform was changed.

An alpha comparison at the old layer's world resolution shows local shape and
thickness changes. Searching translations within ±10 pixels offers only about
0.3 percentage points of improvement in opaque-mask overlap at (3,0), while
doorways shift in opposing directions. A global shift or stretch cannot align
all room edges and entrances. The common canvas/origin is retained rather than
moving every feature to optimize one subset.

Import verified at runtime: Lossless (`compress/mode=0`), size limit disabled
(`process/size_limit=0`), no mipmaps. The loaded texture is the full 1774×887.
WallLayer uses Nearest. The source itself has soft shading; nearest filtering
does not create extra detail. The new art has half the original wall texture's
linear resolution, which is visible at closer zoom.

## Remaining artwork mismatches

These are visual differences. No collision, navigation, door, lighting or room
logic was moved to match them. The player can therefore overlap some of the
new, thicker trim while remaining on the original valid floor.

**Center recess south access:** the existing traversable entrance and collision
gap near floor coordinates x=840–882, y=358–381 remain intact. The new image
draws continuous, mostly opaque lower trim across this route. At x=861, old
strong trim occupies roughly y=366–370; new strong trim occupies roughly
y=360–380. This entrance needs a local artwork correction for a clear visual
opening. The validation physically traversed the saved entrance at x=862.

Representative inner-edge changes were measured with a 15% alpha threshold.
Values below are approximate world pixels, after normalizing the original
2× image. They are artwork samples, not modified collision bounds.

| Existing room region | Local visual differences |
| --- | --- |
| R01 Bridge | Bow edge extends 18 px inward; sampled upper/lower angled edges extend about 20/17 px inward. Main helm and bow consoles now touch/overlap thicker trim. |
| R02 Upper main room | North edge 12 px inward, east edge 11 px inward, south edge 5 px inward. |
| R03 Center recess | North/east edges 6/8 px inward; heavier south trim obscures access as described above. |
| R04 Upper service / power | East edge 11 px inward; north edge 3 px inward. Existing prop floor patch and lights retained. |
| R05 Upper-right / life support | North/east edges 10/9 px inward. Existing equipment remains at its saved position. |
| R06 Starboard aft / engine room | East edge 14 px inward; north/south edges about 10/9 px inward. Exhaust/plume transforms unchanged. |
| R07 Crew quarters | Sampled west/north/south edges about 4/5/4 px inward; all beds, desk, chairs, table and cabinets preserved. |
| R08 Central lower bay | West/east/north/south edges about 6/9/7/6 px inward. |
| R09 Shuttle bay | East edge 17 px inward; north/south edges about 4/7 px inward. |
| R10 Lower deck, hydroponics side | West edge 20 px inward; south edge 16 px inward. |
| R10 Lower deck, east side | South edge 14 px inward; west edge extends about 8 px outward. |

The broad bridge corridor stays open. All 11 pressure-door locations retain
transparent gaps in the new art, but their gaps do not precisely match saved
door frames. The table samples the row through each door's actual transformed
position, including the saved ShipDoors parent offset (3,-4) and rotation.

| Saved door instance | Old/new clear width | New gap center relative to saved door center |
| --- | --- | --- |
| UpperServiceSouthEntry | 34 / 35 px | 2.8 px left |
| SpineSouthEntry | 32 / 34 px | 7.3 px left |
| CentralBayNorthEntry | 32 / 27 px | 2.2 px right |
| LowerDeckWestEntry | 23 / 26 px | 8.2 px left |
| LowerDeckWestEntry2 | 18 / 20 px | 1.2 px left |
| LowerDeckWestEntry3 | 21 / 20 px | 4.3 px left |
| LowerDeckWestEntry4 | 22 / 19 px | 4.9 px left |
| LowerDeckCenterEntry | 27 / 23 px | 0.7 px left |
| LowerDeckCenterEntry2 | 21 / 23 px | 1.2 px right |
| LowerDeckCenterEntry3 | 19 / 20 px | 6.3 px left |
| ShuttleBayNorthEntry | 20 / 18 px | 7.2 px left |

These clear widths describe the wall PNG's transparency, not the exported
opening_width or physical passage width. Door properties were preserved.

## Validation

Rendered walkthrough at 1280×720:

- Wall visual audit: PASS, 72 checks, zero failures.
- All 11 pressure doors opened automatically, blocked while closed, unblocked
  while open, and were traversed with the existing player and floor rules.
- Doorway movement results were identical with old and new wall textures.
- Center-recess south entrance remained physically traversable.
- Actual movement input worked in bridge, central bay and engine room.
- Collision shape transforms/settings, static bodies, navigation region data,
  light settings and furniture transforms matched across the visual swap.
- Every room region was captured for boundary inspection.
- Normal gameplay zoom (1.75×) and closer zoom (3×) were rendered and inspected.
- Existing floor validator: PASS, 14,241 samples, zero floor-mask mismatches;
  22 saved bridge/quarters prop anchors aligned, and 20 earlier movement probes
  still succeeded.
- Before/after source hashes confirmed preservation of unrelated local changes.
  The scene differs from its saved pre-task version in exactly the three wall
  properties described above.

Existing Windows certificate-store, sandboxed global editor-settings save and
shutdown resource diagnostics remain. No wall-related parse or runtime errors
were present in the final validation.

Run the visual check from the project directory:

```
Godot --path . --script tools/validate_ship_wall_visual.gd --audio-driver Dummy --resolution 1280x720
```

Screenshots and machine-readable door/movement results are under
`res://.godot/wall_validation/` (ignored by Git):

- `bridge_normal.png`, `bridge_close.png`
- `central_corridors_normal.png`, `central_corridors_close.png`
- `engine_area_normal.png`, `engine_area_close.png`
- `upper_engine_normal.png`, `upper_engine_close.png`
- `lower_engine_normal.png`, `lower_engine_close.png`
- `room_R01.png` through `room_R10.png`, `whole_ship.png`
- `*_old_close.png` comparisons and `report.json`

Camera targets for the exterior engine shots are outside the playable floor;
the test actor is hidden in those captures. No exterior player position is
saved. All probes, zoom changes and door state changes are in memory only.

## Revert the visual

Select WallLayer in bare_ship_walkthrough, set Texture to
`res://art/overview/asteria_overview_walls_2x.png` and Scale to (0.5,0.5).
For the exact previous appearance, set Texture Filter to Linear; retaining
Nearest also works. Keep Position at (0,0), Centered off and Z at -1.


# Player floor-boundary alignment

The saved walkthrough root is translated by `(-30,-23)`. The visible floor,
walls, doors and furniture inherit that transform. Previously, the player was
given `FloorLayer.position` (local zero) as its floor-mask origin while movement
checked global player positions. This displaced invisible walkable boundaries
30 pixels right and 23 down relative to the visible deck across the ship.

`bare_ship_walkthrough.gd` now passes `FloorLayer.global_position`. No room,
prop, collision footprint or player movement settings are changed. Doors already
convert global positions with `to_local`; Amara already uses the global floor
origin, so those systems do not need the same correction.

Run `godot --headless --path . --script tools/validate_floor_alignment.gd`.
The test compares the player's nine floor samples with the rendered floor's
coordinates across all ten room regions (14,241 sampled positions). Gates are
opened only in the test instance to distinguish door blocking from floor-mask
blocking. It also checks the saved bridge/quarters sprite and collider anchors.

Before the correction, `-- --audit-only` recorded 4,152 mismatches. The baseline
report under `.godot/floor_alignment_before.json` includes 20 clear-floor,
furniture-free positions that were wrongly blocked. When that baseline exists,
the regular test verifies actual player movement at those same positions.
Reports/logs remain under ignored `.godot/`; the test does not save room edits.

# Asteria space backdrop frames

This folder holds forty 3548 × 1774 high-quality JPEG frames used by the ship walkaround's looping animated background. They are generated from the remastered high-resolution starfield source and keep the same composition in every frame. Each frame shifts the starfield 3 pixels farther right, opposite the ship's left-facing bow, to make forward travel visible. The runtime sprite is centered on the map at 1:1 scale, preserving the previous overscan while providing twice the pixel dimensions.

Regenerate them from `art/overview/asteria_space_backdrop_source_hires.png` with:

```sh
godot --headless --path . --script tools/build_space_backdrop_frames.gd
```

The sequence is loaded by `scripts/ship/space_backdrop.gd` at 12 frames per second and loops every 3.33 seconds.

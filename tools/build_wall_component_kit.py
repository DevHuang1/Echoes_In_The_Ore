#!/usr/bin/env python3
"""Export reusable transparent wall sprites and drop-in Godot Sprite2D scenes."""

from __future__ import annotations

import json
import math
import textwrap
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/overview/asteria_overview_walls_2x.png"
SOURCE_SCALE = 2
SCENE_SCALE = 1.0 / SOURCE_SCALE
ART_DIR = ROOT / "art/overview/wall_components"
SCENE_DIR = ROOT / "scenes/ship/wall_components"
ARCHIVE = ROOT / "art/overview/asteria_wall_component_kit.zip"

COMPONENTS = [
    {"id": "wall_straight_h_long", "label": "Straight wall — long", "kind": "straight", "box": (775, 248, 965, 286), "rotate": True},
    {"id": "wall_straight_h_short", "label": "Straight wall — short", "kind": "straight", "box": (884, 412, 1010, 463), "rotate": True},
    {"id": "wall_straight_v", "label": "Straight wall — vertical", "kind": "straight", "box": (689, 282, 742, 374), "rotate": True},
    {"id": "wall_vertical_service_panel", "label": "Vertical service panel", "kind": "straight_detail", "box": (1177, 410, 1255, 522), "rotate": True},
    {"id": "wall_corner_inner", "label": "Inner corner", "kind": "corner", "box": (683, 405, 782, 502), "rotate": True},
    {"id": "wall_corner_outer", "label": "Outer corner", "kind": "corner", "box": (252, 390, 360, 494), "rotate": True},
    {"id": "wall_hull_bend_upper_port", "label": "Upper port hull bend", "kind": "hull_curve", "box": (270, 105, 653, 337), "rotate": True},
    {"id": "wall_windowed_bow", "label": "Windowed bow wall", "kind": "hull_window", "box": (0, 275, 100, 430), "rotate": True},
    {"id": "wall_lower_partition_pair", "label": "Lower partition pair", "kind": "partition", "box": (468, 625, 571, 734), "rotate": True},
    {"id": "wall_t_junction", "label": "T-junction", "kind": "junction", "box": (636, 488, 782, 663), "rotate": True},
    {"id": "wall_diagonal_aft_hull", "label": "Angled aft hull", "kind": "hull_curve", "box": (1125, 627, 1445, 812), "rotate": True},
    {"id": "wall_aft_hull_cluster", "label": "Aft hull cluster", "kind": "hull_module", "box": (1490, 270, 1774, 677), "rotate": True},
    {"id": "wall_service_turn", "label": "Service turn", "kind": "junction", "box": (1125, 482, 1268, 585), "rotate": True},
    {"id": "wall_open_passage_pair", "label": "Open passage wall pair", "kind": "doorway", "box": (492, 390, 693, 490), "rotate": True},
    {"id": "wall_lower_hull_curve", "label": "Lower hull curve", "kind": "hull_curve", "box": (0, 625, 346, 887), "rotate": True},
    {"id": "wall_vertical_spine", "label": "Vertical service spine", "kind": "junction", "box": (1080, 25, 1208, 298), "rotate": True},
]


def font(size: int) -> ImageFont.ImageFont:
    for path in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def make_contact_sheet(entries: list[dict]) -> None:
    cols, cell_w, cell_h, label_h, margin = 4, 300, 230, 42, 18
    rows = math.ceil(len(entries) / cols)
    width = margin + cols * (cell_w + margin)
    height = 60 + margin + rows * (cell_h + label_h + margin)
    sheet = Image.new("RGB", (width, height), (12, 18, 27))
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 14), "Reusable Asteria wall components", font=font(27), fill=(241, 245, 249))
    for index, item in enumerate(entries):
        row, col = divmod(index, cols)
        x = margin + col * (cell_w + margin)
        y = 60 + margin + row * (cell_h + label_h + margin)
        draw.rectangle((x, y, x + cell_w, y + cell_h), fill=(27, 38, 51))
        image = Image.open(ART_DIR / f"{item['id']}.png").convert("RGBA")
        image.thumbnail((cell_w - 12, cell_h - 12), Image.Resampling.LANCZOS)
        sheet.paste(image, (x + (cell_w - image.width) // 2, y + (cell_h - image.height) // 2), image)
        label = textwrap.fill(f"{item['id']} — {item['label']}", width=37)
        draw.multiline_text((x, y + cell_h + 5), label, font=font(12), fill=(226, 233, 240), spacing=1)
    sheet.save(ART_DIR / "wall_components_contact_sheet.png", optimize=True)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    ART_DIR.mkdir(parents=True, exist_ok=True)
    SCENE_DIR.mkdir(parents=True, exist_ok=True)
    entries = []

    for item in COMPONENTS:
        world_box = item["box"]
        source_box = tuple(coordinate * SOURCE_SCALE for coordinate in world_box)
        crop = source.crop(source_box)
        if crop.getchannel("A").getbbox() is None:
            raise RuntimeError(f"Source region has no visible wall pixels: {item['id']}")
        png_path = ART_DIR / f"{item['id']}.png"
        crop.save(png_path, optimize=True)
        width, height = crop.size
        scene_name = "".join(part.title() for part in item["id"].split("_"))
        scene_path = SCENE_DIR / f"{item['id']}.tscn"
        scene_path.write_text(
            "[gd_scene load_steps=2 format=3]\n\n"
            f'[ext_resource type="Texture2D" path="res://art/overview/wall_components/{item["id"]}.png" id="1_texture"]\n\n'
            f'[node name="{scene_name}" type="Sprite2D"]\n'
            'centered = true\n'
            f'scale = Vector2({SCENE_SCALE}, {SCENE_SCALE})\n'
            'texture = ExtResource("1_texture")\n',
            encoding="utf-8",
        )
        entries.append(
            {
                **item,
                "source_rectangle": list(source_box),
                "size": [width // SOURCE_SCALE, height // SOURCE_SCALE],
                "texture_size": [width, height],
                "scene_scale": [SCENE_SCALE, SCENE_SCALE],
                "texture": str(png_path.relative_to(ROOT)),
                "scene": str(scene_path.relative_to(ROOT)),
                "origin": "center",
                "rotation_recommended": item["rotate"],
                "collision": "visual-only Sprite2D scene; add level-specific collision separately",
            }
        )

    make_contact_sheet(entries)
    manifest = {
        "source": str(SOURCE.relative_to(ROOT)),
        "canvas_size": list(source.size),
        "world_canvas_size": [source.width // SOURCE_SCALE, source.height // SOURCE_SCALE],
        "pixels_per_world_unit": SOURCE_SCALE,
        "component_count": len(entries),
        "components": entries,
    }
    (ART_DIR / "wall_components_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    readme = """# Reusable wall components

This kit contains transparent 2x PNG wall sprites and one drop-in Godot `Sprite2D` scene per sprite. Components are cropped from `art/overview/asteria_overview_walls_2x.png` and scaled to the original world size, so they stay aligned with the existing Asteria layout while retaining more texture detail when zoomed in.

## Component types

- Straight runs: short/long horizontal, vertical, and service-panel variants.
- Corners and joins: inner/outer corners, a T-junction, a service turn, and an open-passage pair.
- Ship structure: curved hull sections, a windowed bow segment, an aft hull cluster, and a vertical service spine.

Add a `.tscn` from `scenes/ship/wall_components/` to a level, or use the PNG directly. Each scene is centered on its sprite for straightforward rotation. The JSON manifest gives texture size, source rectangle, scene path, and component type. These are visual assets; add collision to match the specific level geometry.

Run `godot --headless --path . --script tools/prepare_wall_layer_hires.gd` to regenerate the aligned 2x wall layer from the original alpha mask and the detail pass. Then run `python3 tools/build_wall_component_kit.py` to regenerate the modular pieces from that layer.
"""
    (ART_DIR / "README.md").write_text(readme, encoding="utf-8")

    with zipfile.ZipFile(ARCHIVE, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(ART_DIR.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(ROOT))
        for path in sorted(SCENE_DIR.glob("*.tscn")):
            archive.write(path, path.relative_to(ROOT))

    print(f"Built {len(entries)} reusable wall sprites and scenes")
    print(f"Contact sheet: {ART_DIR / 'wall_components_contact_sheet.png'}")
    print(f"Pack: {ARCHIVE}")


if __name__ == "__main__":
    main()

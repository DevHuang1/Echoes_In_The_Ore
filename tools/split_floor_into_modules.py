#!/usr/bin/env python3
"""Split the extracted Asteria floor layer into room and non-room modules."""

from __future__ import annotations

import json
import math
import textwrap
import zipfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

from split_ship_overview import NONROOM_ZONE_NAMES, ROOMS


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/overview/asteria_overview_floor.png"
OUTPUT = ROOT / "art/overview/floor_modules"
SCENES = ROOT / "scenes/ship/floor_modules"
ARCHIVE = ROOT / "art/overview/asteria_modular_flooring.zip"
GRID_ROWS, GRID_COLS = 4, 5

TILES = [
    {"id": "floor_tile_upper_plate", "label": "Upper deck panel", "kind": "panel", "box": (782, 113, 910, 241)},
    {"id": "floor_tile_lower_plate", "label": "Lower bay panel", "kind": "panel", "box": (908, 466, 1036, 594)},
    {"id": "floor_tile_small_grate", "label": "Small inset grate", "kind": "grate", "box": (810, 190, 906, 286)},
    {"id": "floor_tile_cargo_grate", "label": "Cargo bay grate", "kind": "grate", "box": (814, 510, 910, 606)},
    {"id": "floor_tile_hazard_zone", "label": "Hazard inset", "kind": "marking", "box": (1464, 317, 1592, 465)},
    {"id": "floor_tile_hangar_bay", "label": "Hangar floor marking", "kind": "marking", "box": (1204, 521, 1392, 691)},
    {"id": "floor_tile_corridor_horizontal", "label": "Horizontal corridor", "kind": "corridor", "box": (718, 374, 968, 423)},
    {"id": "floor_tile_corridor_vertical", "label": "Vertical corridor", "kind": "corridor", "box": (636, 258, 716, 416)},
    {"id": "floor_tile_bridge_marking", "label": "Bridge floor marking", "kind": "marking", "box": (99, 283, 277, 425)},
    {"id": "floor_tile_lower_panel", "label": "Lower deck panel", "kind": "panel", "box": (635, 698, 863, 828)},
]


def font(size: int) -> ImageFont.ImageFont:
    for path in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def write_scene(scene_path: Path, texture_path: str, node_name: str) -> None:
    scene_path.parent.mkdir(parents=True, exist_ok=True)
    scene_path.write_text(
        "[gd_scene load_steps=2 format=3]\n\n"
        f'[ext_resource type="Texture2D" path="res://{texture_path}" id="1_texture"]\n\n'
        f'[node name="{node_name}" type="Sprite2D"]\n'
        'centered = false\n'
        'texture = ExtResource("1_texture")\n',
        encoding="utf-8",
    )


def save_piece(source: Image.Image, alpha: Image.Image, output: Path, spec: dict) -> dict:
    bounds = alpha.getbbox()
    if bounds is None:
        raise RuntimeError(f"Empty floor component: {spec['id']}")
    crop = source.crop(bounds)
    crop.putalpha(alpha.crop(bounds))
    output.parent.mkdir(parents=True, exist_ok=True)
    crop.save(output, optimize=True)
    left, top, right, bottom = bounds
    return {
        **spec,
        "origin": [left, top],
        "size": [right - left, bottom - top],
        "pixel_area": sum(alpha.histogram()[1:]),
        "file": str(output.relative_to(ROOT)),
    }


def contact_sheet(entries: list[dict], title: str, output: Path, columns: int, cell_size: tuple[int, int]) -> None:
    margin, label_height, title_height = 16, 40, 52
    rows = math.ceil(len(entries) / columns)
    width = margin + columns * (cell_size[0] + margin)
    height = title_height + margin + rows * (cell_size[1] + label_height + margin)
    sheet = Image.new("RGB", (width, height), (11, 17, 25))
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 12), title, font=font(25), fill=(240, 244, 248))
    for index, item in enumerate(entries):
        row, col = divmod(index, columns)
        x = margin + col * (cell_size[0] + margin)
        y = title_height + margin + row * (cell_size[1] + label_height + margin)
        draw.rectangle((x, y, x + cell_size[0], y + cell_size[1]), fill=(24, 34, 46))
        image = Image.open(ROOT / item["file"]).convert("RGBA")
        image.thumbnail((cell_size[0] - 12, cell_size[1] - 12), Image.Resampling.LANCZOS)
        sheet.paste(image, (x + (cell_size[0] - image.width) // 2, y + (cell_size[1] - image.height) // 2), image)
        text = textwrap.fill(f"{item['id']} — {item['label']}", width=max(22, cell_size[0] // 8))
        draw.multiline_text((x, y + cell_size[1] + 5), text, font=font(12), fill=(226, 233, 240), spacing=1)
    sheet.save(output, optimize=True)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    width, height = source.size
    OUTPUT.mkdir(parents=True, exist_ok=True)
    alpha_source = source.getchannel("A")
    ownership = Image.new("L", source.size, 0)
    module_entries: list[dict] = []

    for room in ROOMS:
        candidate = Image.new("L", source.size, 0)
        ImageDraw.Draw(candidate).polygon(room["polygon"], fill=255)
        available = ImageChops.subtract(candidate, ownership)
        alpha = ImageChops.multiply(alpha_source, available)
        ownership = ImageChops.lighter(ownership, available)
        name = f"{room['id'].lower()}_{room['name']}_floor"
        relative = Path("art/overview/floor_modules/rooms") / f"{name}.png"
        entry = save_piece(source, alpha, ROOT / relative, {
            "id": room["id"], "label": room["label"], "kind": "room_floor", "polygon": room["polygon"]
        })
        scene_rel = Path("scenes/ship/floor_modules/rooms") / f"{name}.tscn"
        write_scene(ROOT / scene_rel, str(relative), f"{room['name'].title().replace('_', '')}Floor")
        entry["scene"] = str(scene_rel)
        module_entries.append(entry)

    residual_entries: list[dict] = []
    for row in range(GRID_ROWS):
        y0, y1 = row * height // GRID_ROWS, (row + 1) * height // GRID_ROWS
        for col in range(GRID_COLS):
            x0, x1 = col * width // GRID_COLS, (col + 1) * width // GRID_COLS
            grid = Image.new("L", source.size, 0)
            ImageDraw.Draw(grid).rectangle((x0, y0, x1 - 1, y1 - 1), fill=255)
            available = ImageChops.subtract(grid, ownership)
            alpha = ImageChops.multiply(alpha_source, available)
            ownership = ImageChops.lighter(ownership, available)
            tile_id = f"F{row + 1:02d}{col + 1:02d}"
            spec = {
                "id": tile_id,
                "label": NONROOM_ZONE_NAMES[row][col],
                "kind": "connector_or_support_floor",
                "grid_cell": [row + 1, col + 1],
                "grid_bounds": [x0, y0, x1, y1],
            }
            if alpha.getbbox() is None:
                continue
            name = f"{tile_id.lower()}_r{row + 1:02d}_c{col + 1:02d}_floor"
            relative = Path("art/overview/floor_modules/non_rooms") / f"{name}.png"
            entry = save_piece(source, alpha, ROOT / relative, spec)
            scene_rel = Path("scenes/ship/floor_modules/non_rooms") / f"{name}.tscn"
            write_scene(ROOT / scene_rel, str(relative), f"{tile_id}Floor")
            entry["scene"] = str(scene_rel)
            residual_entries.append(entry)
            module_entries.append(entry)

    # Room and non-room modules form an exact, non-overlapping partition of the floor layer.
    rebuilt = Image.new("RGBA", source.size, (0, 0, 0, 0))
    occupancy = Image.new("L", source.size, 0)
    for entry in module_entries:
        image = Image.open(ROOT / entry["file"]).convert("RGBA")
        x, y = entry["origin"]
        alpha_canvas = Image.new("L", source.size, 0)
        alpha_canvas.paste(image.getchannel("A"), (x, y))
        if ImageChops.multiply(alpha_canvas, occupancy).getbbox() is not None:
            raise RuntimeError(f"Overlapping floor modules found at {entry['id']}")
        occupancy = ImageChops.lighter(occupancy, alpha_canvas)
        rebuilt.alpha_composite(image, (x, y))
    if ImageChops.difference(source, rebuilt).getbbox() is not None:
        raise RuntimeError("Floor modules did not reconstruct the floor source exactly")

    tile_entries = []
    for tile in TILES:
        crop = source.crop(tile["box"])
        if crop.getchannel("A").getbbox() is None:
            raise RuntimeError(f"Empty floor tile: {tile['id']}")
        relative = Path("art/overview/floor_modules/tiles") / f"{tile['id']}.png"
        (ROOT / relative).parent.mkdir(parents=True, exist_ok=True)
        crop.save(ROOT / relative, optimize=True)
        scene_rel = Path("scenes/ship/floor_modules/tiles") / f"{tile['id']}.tscn"
        write_scene(ROOT / scene_rel, str(relative), tile["id"].title().replace("_", ""))
        tile_entries.append({
            **tile,
            "source_rectangle": list(tile["box"]),
            "size": list(crop.size),
            "file": str(relative),
            "scene": str(scene_rel),
            "origin": "top_left",
            "note": "Reusable visual floor patch; may overlap the room/non-room reconstruction modules.",
        })

    all_entries = module_entries + tile_entries
    contact_sheet(module_entries[:len(ROOMS)], "Modular flooring — room modules", OUTPUT / "room_modules_contact_sheet.png", 2, (480, 210))
    contact_sheet(residual_entries, "Modular flooring — connector/support modules", OUTPUT / "connector_modules_contact_sheet.png", 4, (320, 150))
    contact_sheet(tile_entries, "Modular flooring — reusable tile patches", OUTPUT / "floor_tile_patches_contact_sheet.png", 3, (360, 170))
    wall_layer = Image.open(ROOT / "art/overview/asteria_overview_walls.png").convert("RGBA")
    preview = Image.new("RGBA", source.size, (8, 13, 21, 255))
    preview.alpha_composite(source)
    preview.alpha_composite(wall_layer)
    preview.save(OUTPUT / "floor_wall_alignment_preview.png", optimize=True)

    manifest = {
        "source": str(SOURCE.relative_to(ROOT)),
        "canvas_size": [width, height],
        "room_module_count": len(ROOMS),
        "connector_support_module_count": len(residual_entries),
        "tile_patch_count": len(tile_entries),
        "reconstruction": "Alpha-composite room and connector/support modules at each origin on a transparent canvas. Those 30 modules reconstruct the floor-only source exactly. Tile patches are additional reusable crops and can overlap the reconstructed modules.",
        "modules": module_entries,
        "tile_patches": tile_entries,
    }
    (OUTPUT / "floor_modules_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    readme = f"""# Asteria modular flooring

The floor-only source layer is `{SOURCE.name}` ({width} × {height}, transparent outside the deck floors). This pack contains:

- {len(ROOMS)} named room-floor modules.
- {len(residual_entries)} connector/support floor modules covering every remaining floor pixel, including corridors and narrow passages.
- {len(tile_entries)} reusable tile patches for metal panels, grates, markings, and corridors.
- A top-left-anchored Godot `Sprite2D` scene for every component under `scenes/ship/floor_modules/`.
- `floor_wall_alignment_preview.png` shows the extracted floor assembled under the wall-only layer.

The 30 room and connector/support modules are transparent, non-overlapping, and reassemble the source floor layer exactly at the positions in `floor_modules_manifest.json`. The 10 tile patches are additional crops for reuse and may overlap those modules. `Sprite2D` scenes are visual-only; define collision through the walls or level-specific collision shapes.

Run `python3 tools/split_floor_into_modules.py` to regenerate the modules, contact sheets, scenes, and ZIP pack from the full floor layer. The extraction used built-in imagegen to remove walls, contents, and starfield while preserving the floor plate art.
"""
    (OUTPUT / "README.md").write_text(readme, encoding="utf-8")

    with zipfile.ZipFile(ARCHIVE, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        archive.write(SOURCE, SOURCE.relative_to(ROOT))
        for path in sorted(OUTPUT.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(ROOT))
        for path in sorted(SCENES.rglob("*.tscn")):
            archive.write(path, path.relative_to(ROOT))
    print(f"Built {len(module_entries)} non-overlapping floor modules and {len(tile_entries)} reusable tile patches")
    print(f"Exact floor reconstruction verified: {width}x{height}")
    print(f"Pack: {ARCHIVE}")


if __name__ == "__main__":
    main()

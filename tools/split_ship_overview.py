#!/usr/bin/env python3
"""Split the hollow Asteria overview into room masks and exhaustive non-room tiles."""

from __future__ import annotations

import json
import math
import textwrap
import zipfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/overview/asteria_overview_hollow.png"
OUTPUT = ROOT / "art/overview/pieces"
ARCHIVE = ROOT / "art/overview/asteria_overview_hollow_pieces.zip"

ROOMS = [
    {
        "id": "R01",
        "name": "bridge",
        "label": "Bridge",
        "polygon": [(0, 278), (34, 246), (78, 220), (158, 204), (247, 205), (318, 229), (355, 269), (357, 393), (326, 433), (276, 472), (194, 484), (111, 455), (55, 427), (0, 381)],
        "tag": (120, 328),
    },
    {
        "id": "R02",
        "name": "upper_main_room",
        "label": "Upper main room",
        "polygon": [(575, 72), (625, 42), (742, 28), (1064, 34), (1138, 64), (1152, 115), (1150, 222), (1125, 268), (612, 268), (576, 238)],
        "tag": (848, 156),
    },
    {
        "id": "R03",
        "name": "center_recess",
        "label": "Center recess",
        "polygon": [(682, 267), (1037, 267), (1040, 344), (1022, 378), (997, 389), (718, 389), (684, 370)],
        "tag": (860, 324),
    },
    {
        "id": "R04",
        "name": "upper_service_room",
        "label": "Upper service room",
        "polygon": [(1063, 265), (1206, 263), (1205, 358), (1187, 384), (1070, 384), (1058, 361)],
        "tag": (1126, 322),
    },
    {
        "id": "R05",
        "name": "upper_right_room",
        "label": "Upper right room",
        "polygon": [(1224, 198), (1302, 199), (1369, 222), (1367, 377), (1343, 397), (1244, 387), (1221, 363)],
        "tag": (1294, 305),
    },
    {
        "id": "R06",
        "name": "starboard_aft_room",
        "label": "Starboard aft room",
        "polygon": [(1341, 206), (1443, 207), (1538, 218), (1608, 251), (1624, 311), (1618, 479), (1596, 526), (1551, 551), (1380, 554), (1351, 523)],
        "tag": (1484, 375),
    },
    {
        "id": "R07",
        "name": "mid_left_room",
        "label": "Mid-left room",
        "polygon": [(268, 397), (337, 393), (476, 393), (506, 405), (529, 410), (630, 404), (661, 427), (661, 500), (690, 527), (697, 610), (675, 652), (624, 669), (343, 665), (292, 651), (267, 623)],
        "tag": (470, 530),
    },
    {
        "id": "R08",
        "name": "center_lower_room",
        "label": "Center lower room",
        "polygon": [(697, 410), (821, 405), (1192, 405), (1220, 436), (1218, 602), (1201, 649), (1153, 667), (867, 663), (801, 644), (753, 626), (730, 599), (729, 510), (698, 489)],
        "tag": (978, 537),
    },
    {
        "id": "R09",
        "name": "shuttle_bay",
        "label": "Shuttle bay",
        "polygon": [(1191, 524), (1228, 503), (1306, 503), (1368, 515), (1401, 550), (1399, 661), (1378, 698), (1260, 705), (1209, 682), (1192, 645)],
        "tag": (1300, 601),
    },
    {
        "id": "R10",
        "name": "lower_deck",
        "label": "Lower deck",
        "polygon": [(0, 679), (43, 650), (176, 642), (342, 648), (481, 649), (557, 649), (668, 663), (757, 667), (837, 670), (926, 681), (1009, 700), (1056, 742), (1065, 804), (1042, 839), (1002, 860), (177, 871), (68, 859), (17, 832), (0, 794)],
        "tag": (709, 762),
    },
]

NONROOM_ZONE_NAMES = [
    [
        "Forward upper starfield, antenna, and hull",
        "Upper-left hull and room frame",
        "Upper central hull and structural details",
        "Upper-right hull and service structure",
        "Aft engine pod and surrounding starfield",
    ],
    [
        "Bow glazing and outer frame",
        "Upper-left corridor and bulkhead sections",
        "Central corridor and service connectors",
        "Right-side corridor and structural frame",
        "Aft hull and upper engine structure",
    ],
    [
        "Port-side hull and exterior frame",
        "West connector corridor and bulkheads",
        "Central connector and cargo-bay walls",
        "Right connector and hangar approach",
        "Aft lower hull and thruster structure",
    ],
    [
        "Lower-left hull and starfield",
        "Lower-west passage and bulkhead sections",
        "Lower-central passage and structural sections",
        "Lower-right wing and support structure",
        "Aft exhausts and surrounding starfield",
    ],
]


def load_font(size: int) -> ImageFont.ImageFont:
    for candidate in (
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def make_mask(size: tuple[int, int], polygon: list[tuple[int, int]]) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    return mask


def get_nonempty_piece(source: Image.Image, mask: Image.Image, path: Path, metadata: dict) -> dict:
    bounds = mask.getbbox()
    if bounds is None:
        raise RuntimeError(f"Empty split region: {metadata['id']}")
    clipped = source.crop(bounds)
    clipped.putalpha(mask.crop(bounds))
    path.parent.mkdir(parents=True, exist_ok=True)
    clipped.save(path, optimize=True)
    left, top, right, bottom = bounds
    return {
        **metadata,
        "file": str(path.relative_to(OUTPUT)),
        "origin": [left, top],
        "size": [right - left, bottom - top],
        "pixel_area": sum(mask.histogram()[1:]),
    }


def create_contact_sheet(pieces: list[dict], title: str, output: Path, columns: int, cell_size: tuple[int, int]) -> None:
    margin = 18
    label_height = 40
    rows = math.ceil(len(pieces) / columns)
    width = columns * cell_size[0] + (columns + 1) * margin
    height = rows * (cell_size[1] + label_height) + (rows + 1) * margin + 52
    sheet = Image.new("RGB", (width, height), (11, 17, 25))
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 12), title, font=load_font(26), fill=(240, 244, 248))
    for index, piece in enumerate(pieces):
        row, col = divmod(index, columns)
        x = margin + col * (cell_size[0] + margin)
        y = 52 + margin + row * (cell_size[1] + label_height + margin)
        rect = (x, y, x + cell_size[0], y + cell_size[1])
        draw.rectangle(rect, fill=(20, 29, 40))
        image = Image.open(OUTPUT / piece["file"]).convert("RGBA")
        image.thumbnail(cell_size, Image.Resampling.LANCZOS)
        px = x + (cell_size[0] - image.width) // 2
        py = y + (cell_size[1] - image.height) // 2
        sheet.paste(image, (px, py), image)
        label = f"{piece['id']}  {piece['label']}"
        wrapped = textwrap.fill(label, width=max(24, cell_size[0] // 8))
        draw.multiline_text((x, y + cell_size[1] + 5), wrapped, font=load_font(12), fill=(229, 234, 239), spacing=1)
    sheet.save(output, optimize=True)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    width, height = source.size
    OUTPUT.mkdir(parents=True, exist_ok=True)
    room_dir = OUTPUT / "rooms"
    nonroom_dir = OUTPUT / "non_rooms"
    room_dir.mkdir(exist_ok=True)
    nonroom_dir.mkdir(exist_ok=True)

    ownership = Image.new("L", (width, height), 0)
    pieces: list[dict] = []
    room_masks: list[Image.Image] = []
    for room in ROOMS:
        candidate = make_mask(source.size, room["polygon"])
        mask = ImageChops.subtract(candidate, ownership)
        ownership = ImageChops.lighter(ownership, mask)
        room_masks.append(mask)
        piece = get_nonempty_piece(
            source,
            mask,
            room_dir / f"{room['id'].lower()}_{room['name']}.png",
            {
                "id": room["id"],
                "type": "room",
                "name": room["name"],
                "label": room["label"],
                "polygon": room["polygon"],
            },
        )
        pieces.append(piece)

    remaining = ImageChops.invert(ownership)
    row_count, col_count = 4, 5
    nonroom_pieces: list[dict] = []
    for row in range(row_count):
        y0 = row * height // row_count
        y1 = (row + 1) * height // row_count
        for col in range(col_count):
            x0 = col * width // col_count
            x1 = (col + 1) * width // col_count
            tile = Image.new("L", (width, height), 0)
            ImageDraw.Draw(tile).rectangle((x0, y0, x1 - 1, y1 - 1), fill=255)
            mask = ImageChops.multiply(tile, remaining)
            identifier = f"N{row + 1:02d}{col + 1:02d}"
            piece = get_nonempty_piece(
                source,
                mask,
                nonroom_dir / f"{identifier.lower()}_r{row + 1:02d}_c{col + 1:02d}.png",
                {
                    "id": identifier,
                    "type": "non_room",
                    "name": f"nonroom_r{row + 1:02d}_c{col + 1:02d}",
                    "label": NONROOM_ZONE_NAMES[row][col],
                    "grid_cell": [row + 1, col + 1],
                    "grid_bounds": [x0, y0, x1, y1],
                },
            )
            pieces.append(piece)
            nonroom_pieces.append(piece)

    # The pieces are an exhaustive, non-overlapping partition of the original image.
    rebuilt = Image.new("RGBA", source.size, (0, 0, 0, 0))
    ownership_check = Image.new("L", source.size, 0)
    for piece in pieces:
        image = Image.open(OUTPUT / piece["file"]).convert("RGBA")
        x, y = piece["origin"]
        rebuilt.alpha_composite(image, (x, y))
        alpha = Image.new("L", source.size, 0)
        alpha.paste(image.getchannel("A"), (x, y))
        overlap = ImageChops.multiply(alpha, ownership_check)
        if overlap.getbbox() is not None:
            raise RuntimeError(f"Overlapping pixels found in piece {piece['id']}")
        ownership_check = ImageChops.lighter(ownership_check, alpha)
    difference = ImageChops.difference(source, rebuilt)
    if difference.getbbox() is not None:
        raise RuntimeError("Split pieces did not reconstruct the source exactly")

    guide = source.convert("RGB")
    guide_draw = ImageDraw.Draw(guide, "RGBA")
    cell_colors = [(60, 220, 255, 150), (255, 90, 80, 150), (100, 255, 160, 150), (255, 210, 80, 150)]
    for row in range(row_count):
        y = (row + 1) * height // row_count
        guide_draw.line((0, y, width, y), fill=(70, 220, 255, 185), width=2)
    for col in range(1, col_count):
        x = col * width // col_count
        guide_draw.line((x, 0, x, height), fill=(70, 220, 255, 185), width=2)
    for index, room in enumerate(ROOMS):
        polygon = room["polygon"]
        color = cell_colors[index % len(cell_colors)]
        guide_draw.line(polygon + [polygon[0]], fill=color, width=5, joint="curve")
        tx, ty = room["tag"]
        guide_draw.rounded_rectangle((tx - 22, ty - 16, tx + 22, ty + 16), radius=7, fill=(7, 12, 18, 220), outline=(255, 255, 255, 220), width=1)
        guide_draw.text((tx - 18, ty - 11), room["id"], font=load_font(15), fill=(255, 255, 255, 255))
    guide_path = OUTPUT / "piece_layout_guide.png"
    guide.save(guide_path, optimize=True)

    create_contact_sheet(pieces[: len(ROOMS)], "Hollow ship — room pieces", OUTPUT / "rooms_contact_sheet.png", 2, (480, 225))
    create_contact_sheet(nonroom_pieces, "Hollow ship — non-room pieces (4 × 5 coverage grid)", OUTPUT / "non_rooms_contact_sheet.png", 4, (320, 160))

    manifest = {
        "source": str(SOURCE.relative_to(ROOT)),
        "image_size": [width, height],
        "piece_count": len(pieces),
        "room_piece_count": len(ROOMS),
        "non_room_piece_count": len(nonroom_pieces),
        "reconstruction": "Create a transparent image at image_size, then alpha-composite each piece at its origin in piece_manifest.json. The masks partition all source pixels without overlap.",
        "pieces": pieces,
    }
    manifest_path = OUTPUT / "piece_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    readme = f"""# Asteria hollow overview pieces

This pack splits `{SOURCE.name}` into **{len(ROOMS)} named room pieces** and **{len(nonroom_pieces)} non-room structure pieces**.

- `rooms/` contains transparent PNGs clipped to the room outlines shown in `piece_layout_guide.png`.
- `non_rooms/` contains a 4 × 5 set of transparent tiles for all remaining pixels: corridors, connectors, bulkheads, hull, windows, antennas, thrusters, exterior structures, and starfield.
- `piece_manifest.json` records each piece's original pixel origin and bounds. Composite each PNG at its recorded origin on a {width} × {height} canvas to reconstruct the source exactly.
- `rooms_contact_sheet.png` and `non_rooms_contact_sheet.png` preview the pieces.
- The split was checked for complete pixel coverage and exact reconstruction of the source.

Room polygons follow the visible wall boundaries; some shared wall pixels are assigned to the first room listed in the manifest. The source overview remains unchanged.
"""
    (OUTPUT / "README.md").write_text(readme, encoding="utf-8")

    with zipfile.ZipFile(ARCHIVE, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(OUTPUT.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(OUTPUT.parent))

    print(f"Wrote {len(ROOMS)} room pieces and {len(nonroom_pieces)} non-room tiles to {OUTPUT}")
    print(f"Exact reconstruction verified: {width}x{height}; archive: {ARCHIVE}")


if __name__ == "__main__":
    main()

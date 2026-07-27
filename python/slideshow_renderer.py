#!/usr/bin/env python3
"""Render one TikTok slideshow from a JSON request received on stdin."""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH = 1080
HEIGHT = 1920
ASSET_DIRECTORY = Path(__file__).resolve().parent
FONT_PATHS = {
    "body": ASSET_DIRECTORY / "Inter_28pt-Bold.ttf",
    "hook": ASSET_DIRECTORY / "Inter_28pt-ExtraBold.ttf",
    "label": ASSET_DIRECTORY / "Inter_28pt-SemiBold.ttf",
}
EMOJI_FONT_PATH = ASSET_DIRECTORY / "NotoColorEmoji.ttf"
EMOJI_SOURCE_SIZE = 109 # The only embedded bitmap strike in Noto Color Emoji.


def integer_style_value(style, key, default):
    value = style.get(key)
    if value is None or str(value).strip() == "":
        return default
    return int(value)


def color_style_value(style, key, default):
    value = style.get(key)
    if value is None or not str(value).strip():
        return default
    return value


def load_font(size, kind="body"):
    path = FONT_PATHS.get(kind, FONT_PATHS["body"])
    if not path.is_file():
        raise ValueError(f"Missing slideshow font: {path.name}")
    return ImageFont.truetype(path, size)


def is_emoji(character):
    codepoint = ord(character)
    return (
        0x1F000 <= codepoint <= 0x1FAFF
        or 0x2600 <= codepoint <= 0x27BF
        or codepoint in (0x00A9, 0x00AE, 0x203C, 0x2049, 0x2122, 0x2139, 0x3030, 0x303D, 0x3297, 0x3299)
    )


def emoji_image(character, target_size):
    """Rasterize Noto's fixed-size colour glyph and scale it for the text line."""
    font = ImageFont.truetype(EMOJI_FONT_PATH, EMOJI_SOURCE_SIZE)
    box = font.getbbox(character)
    canvas = Image.new("RGBA", (box[2] - box[0] + 8, box[3] - box[1] + 8), (0, 0, 0, 0))
    ImageDraw.Draw(canvas).text((4 - box[0], 4 - box[1]), character, font=font, embedded_color=True)
    glyph_box = canvas.getbbox()
    if not glyph_box:
        return None
    glyph = canvas.crop(glyph_box)
    height = max(1, round(target_size * 1.08))
    width = max(1, round(glyph.width * height / glyph.height))
    return glyph.resize((width, height), Image.Resampling.LANCZOS)


def line_parts(draw, line, size, stroke_width, kind="body"):
    """Return display parts and their combined bounds; coloured emoji are inline images."""
    parts, normal = [], ""
    def append_normal():
        nonlocal normal
        if normal:
            font = load_font(size, kind)
            box = draw.textbbox((0, 0), normal, font=font, stroke_width=stroke_width)
            parts.append(("text", normal, font, box[2] - box[0], box[3] - box[1], box))
            normal = ""
    for character in line:
        if is_emoji(character):
            append_normal()
            glyph = emoji_image(character, size)
            if glyph:
                parts.append(("emoji", glyph, None, glyph.width, glyph.height, None))
        elif ord(character) not in (0xFE0F, 0x200D):
            normal += character
    append_normal()
    width = sum(part[3] for part in parts)
    height = max((part[4] for part in parts), default=round(size * 1.2))
    return parts, width, height


def line_metrics(draw, line, size, stroke_width, kind="body"):
    parts, width, height = line_parts(draw, line, size, stroke_width, kind)
    return width, height, parts


def wrap_text(draw, text, size, max_width, stroke_width, kind="body"):
    lines = []
    for paragraph in text.splitlines() or [text]:
        words = paragraph.split()
        if not words:
            continue
        line = words.pop(0)
        for word in words:
            candidate = f"{line} {word}"
            if line_metrics(draw, candidate, size, stroke_width, kind)[0] <= max_width:
                line = candidate
            else:
                lines.append(line)
                line = word
        lines.append(line)
    return lines or [text]


def fit_text(draw, text, style, kind="body"):
    max_width = int(WIDTH * float(style.get("text_max_width_ratio", 0.86)))
    maximum = integer_style_value(style, "font_size", 58)
    minimum = integer_style_value(style, "min_font_size", 38)
    spacing = integer_style_value(style, "line_spacing", 8)
    stroke = integer_style_value(style, "stroke_width", 3)
    for size in range(maximum, minimum - 1, -4):
        lines = wrap_text(draw, text, size, max_width, stroke, kind)
        metrics = [line_metrics(draw, line, size, stroke, kind) for line in lines]
        height = sum(max(metric[1], round(size * 1.2)) for metric in metrics) + spacing * max(len(metrics) - 1, 0)
        if height <= HEIGHT * 0.28:
            return lines, size, height
    lines = wrap_text(draw, text, minimum, max_width, stroke, kind)
    height = sum(max(line_metrics(draw, line, minimum, stroke, kind)[1], round(minimum * 1.2)) for line in lines) + spacing * max(len(lines) - 1, 0)
    return lines, minimum, height


def draw_caption(image, text, y, style, background=True, kind="body"):
    draw = ImageDraw.Draw(image)
    lines, size, total_height = fit_text(draw, text, style, kind)
    spacing = integer_style_value(style, "line_spacing", 8)
    stroke = integer_style_value(style, "stroke_width", 3)
    padding_x = integer_style_value(style, "caption_background_padding_x", 28)
    padding_y = integer_style_value(style, "caption_background_padding_y", 16)
    for line in lines:
        width, height, parts = line_metrics(draw, line, size, stroke, kind)
        x = (WIDTH - width) / 2
        if background:
            draw.rounded_rectangle(
                (x - padding_x, y - padding_y, x + width + padding_x, y + height + padding_y),
                radius=integer_style_value(style, "caption_background_radius", 18),
                fill=color_style_value(style, "caption_background_color", "white"),
            )
        cursor = x
        for part_type, value, font, part_width, part_height, box in parts:
            if part_type == "emoji":
                image.alpha_composite(value, (round(cursor), round(y + (height - part_height) / 2)))
            else:
                draw.text(
                    (cursor - box[0], y - box[1]), value, font=font,
                    fill=color_style_value(style, "text_color", "black"),
                    stroke_width=stroke, stroke_fill=color_style_value(style, "stroke_color", "white"),
                )
            cursor += part_width
        y += max(height, round(size * 1.2)) + spacing
    return total_height


def draw_end_slide_branding(image, path):
    branding = Image.open(path).convert("RGBA")
    branding.thumbnail((740, 210), Image.Resampling.LANCZOS)
    x = (WIDTH - branding.width) // 2
    y = HEIGHT - branding.height - 100
    image.alpha_composite(branding, (x, y))


def crop_to_portrait(path):
    image = Image.open(path).convert("RGB")
    scale = max(WIDTH / image.width, HEIGHT / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - WIDTH) // 2
    top = (resized.height - HEIGHT) // 2
    return resized.crop((left, top, left + WIDTH, top + HEIGHT)).convert("RGBA")


def render(payload):
    slides = payload["slides"]
    backgrounds = payload["background_images"]
    output_directory = Path(payload["output_directory"])
    style = payload.get("style", {})
    output_directory.mkdir(parents=True, exist_ok=True)
    if not slides or not backgrounds:
        raise ValueError("At least one slide and one background image are required.")

    outputs = []
    for index, text in enumerate(slides):
        image = crop_to_portrait(backgrounds[index % len(backgrounds)])
        if index == 0 and payload.get("top_label"):
            label_style = style | {"font_size": style.get("tactic_font_size", 38), "min_font_size": 24, "stroke_width": 0}
            draw_caption(image, payload["top_label"], integer_style_value(style, "tactic_top_margin", 240), label_style, kind="label")
        draw = ImageDraw.Draw(image)
        font_kind = "hook" if index == 0 else "body"
        _, _, height = fit_text(draw, text, style, font_kind)
        draw_caption(image, text, (HEIGHT - height) / 2 + integer_style_value(style, "text_vertical_offset", 0), style, kind=font_kind)
        if index == len(slides) - 1 and payload.get("end_slide_branding"):
            draw_end_slide_branding(image, payload["end_slide_branding"])
        output = output_directory / f"slide_{index + 1}.jpg"
        image.convert("RGB").save(output, quality=95)
        outputs.append(str(output))
    return {"slides": outputs}


def main():
    try:
        print(json.dumps(render(json.load(sys.stdin))))
    except Exception as error:
        print(json.dumps({"error": str(error)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

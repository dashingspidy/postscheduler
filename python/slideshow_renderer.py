#!/usr/bin/env python3
"""Render one TikTok slideshow from a JSON request received on stdin."""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH = 1080
HEIGHT = 1920
FONT_CANDIDATES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf",
    "/System/Library/Fonts/SFCompactRounded.ttf",
)
EMOJI_FONT_CANDIDATES = (
    "/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf",
    "/System/Library/Fonts/Apple Color Emoji.ttc",
)
EMOJI_FONT_SIZES = (32, 40, 48, 52, 64, 96, 160)


def font_path(candidates):
    return next((path for path in candidates if Path(path).is_file()), None)


def load_font(size, emoji=False):
    path = font_path(EMOJI_FONT_CANDIDATES if emoji else FONT_CANDIDATES)
    if path:
        try:
            return ImageFont.truetype(path, min(EMOJI_FONT_SIZES, key=lambda available: abs(available - size)) if emoji else size)
        except OSError:
            pass
    return ImageFont.truetype(font_path(FONT_CANDIDATES), size)


def is_emoji(char):
    code = ord(char)
    return 0x1F000 <= code <= 0x1FAFF or 0x2600 <= code <= 0x27BF


def text_runs(text, size):
    runs, current, emoji = [], "", False
    for char in text:
        kind = is_emoji(char) if char not in ("\ufe0f", "\u200d") else emoji
        if current and kind != emoji:
            runs.append((current, load_font(size, emoji), emoji))
            current = ""
        current += char
        emoji = kind
    if current:
        runs.append((current, load_font(size, emoji), emoji))
    return runs


def line_metrics(draw, line, size, stroke_width):
    runs = text_runs(line, size)
    measured = []
    for text, font, emoji in runs:
        box = draw.textbbox((0, 0), text, font=font, stroke_width=0 if emoji else stroke_width, embedded_color=emoji)
        measured.append((text, font, emoji, box, box[2] - box[0], box[3] - box[1]))
    return measured, sum(run[4] for run in measured), max((run[5] for run in measured), default=0)


def wrap_text(draw, text, size, max_width, stroke_width):
    lines = []
    for paragraph in text.splitlines() or [text]:
        words = paragraph.split()
        if not words:
            continue
        line = words.pop(0)
        for word in words:
            candidate = f"{line} {word}"
            if line_metrics(draw, candidate, size, stroke_width)[1] <= max_width:
                line = candidate
            else:
                lines.append(line)
                line = word
        lines.append(line)
    return lines or [text]


def fit_text(draw, text, style):
    max_width = int(WIDTH * float(style.get("text_max_width_ratio", 0.86)))
    maximum = int(style.get("font_size", 58))
    minimum = int(style.get("min_font_size", 38))
    spacing = int(style.get("line_spacing", 8))
    stroke = int(style.get("stroke_width", 3))
    for size in range(maximum, minimum - 1, -4):
        lines = wrap_text(draw, text, size, max_width, stroke)
        metrics = [line_metrics(draw, line, size, stroke) for line in lines]
        height = sum(metric[2] for metric in metrics) + spacing * max(len(metrics) - 1, 0)
        if height <= HEIGHT * 0.28:
            return metrics, height
    lines = wrap_text(draw, text, minimum, max_width, stroke)
    metrics = [line_metrics(draw, line, minimum, stroke) for line in lines]
    return metrics, sum(metric[2] for metric in metrics) + spacing * max(len(metrics) - 1, 0)


def draw_caption(image, text, y, style, background=False):
    draw = ImageDraw.Draw(image)
    metrics, total_height = fit_text(draw, text, style)
    spacing = int(style.get("line_spacing", 8))
    stroke = int(style.get("stroke_width", 3))
    padding_x = int(style.get("caption_background_padding_x", 28))
    padding_y = int(style.get("caption_background_padding_y", 16))
    radius = int(style.get("caption_background_radius", 18))

    for runs, width, height in metrics:
        x = (WIDTH - width) / 2
        if background:
            draw.rounded_rectangle(
                (x - padding_x, y - padding_y, x + width + padding_x, y + height + padding_y),
                radius=radius,
                fill=style.get("caption_background_color", "#000000"),
            )
        cursor_x = x
        for run, font, emoji, box, run_width, run_height in runs:
            draw_y = y + (height - run_height) / 2 - box[1]
            draw.text(
                (cursor_x - box[0], draw_y), run, font=font,
                fill=style.get("text_color", "white"),
                stroke_width=0 if emoji else stroke, stroke_fill=style.get("stroke_color", "black"), embedded_color=emoji,
            )
            cursor_x += run_width
        y += height + spacing
    return total_height


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
    background_offset = int(payload.get("background_offset", 0))
    for index, text in enumerate(slides):
        image = crop_to_portrait(backgrounds[(background_offset + index) % len(backgrounds)])
        if index == 0 and payload.get("tactic"):
            tactic_style = style | {"font_size": style.get("tactic_font_size", 38), "min_font_size": 24, "stroke_width": 0}
            draw_caption(image, payload["tactic"], int(style.get("tactic_top_margin", 240)), tactic_style, background=True)
        draw = ImageDraw.Draw(image)
        _, height = fit_text(draw, text, style)
        draw_caption(image, text, (HEIGHT - height) / 2 + int(style.get("text_vertical_offset", 0)), style)
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

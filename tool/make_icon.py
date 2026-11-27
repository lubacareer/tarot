"""Render the original astrolabe app mark. Run from any directory with Pillow."""
from math import cos, pi, sin
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
EDGE = 768
ink = "#11182D"
brass = "#E5C78F"
image = Image.new("RGBA", (EDGE, EDGE))
draw = ImageDraw.Draw(image)
draw.rounded_rectangle((28, 28, 740, 740), radius=155, fill=ink)
center = EDGE // 2


def polar(angle, radius):
    return (center + radius * cos(angle), center + radius * sin(angle))


for radius, width, color in [(265, 9, brass), (239, 3, brass), (150, 3, "#63647F")]:
    draw.ellipse((center-radius, center-radius, center+radius, center+radius), outline=color, width=width)
for tick in range(48):
    angle = tick * pi / 24
    draw.line([polar(angle, 241), polar(angle, 258 if tick % 4 == 0 else 249)], fill=brass, width=3)
points = [polar(i * pi / 8, (191 if i % 4 == 0 else 102) if i % 2 == 0 else 44) for i in range(16)]
draw.polygon(points, fill=brass)
draw.ellipse((363, 363, 405, 405), fill=ink)

for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    out = ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
    image.resize((size, size), Image.Resampling.LANCZOS).save(out)
image.save(ROOT / "windows/runner/resources/app_icon.ico", sizes=[(s, s) for s in [16, 24, 32, 48, 64, 128, 256]])

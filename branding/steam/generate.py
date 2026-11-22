"""Steam library artwork for the Resonance shortcut (Gaming Mode / Big Picture).

Writes SVG sources next to this script and renders the PNGs Steam expects with Inkscape:
  python3 branding/steam/generate.py
"""
import math
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
GREEN, DARK = "#1DB954", "#121212"
FONT = "font-family:'Inter Display','Inter',sans-serif;font-weight:800"


def mark(cx, cy, size, ring=GREEN, ink=DARK):
    """The app logo (branding/logo.svg) at the given centre and diameter."""
    s = size / 108
    arcs = []
    for r in (17, 27, 37):
        a = math.radians(42 if r == 17 else 48 if r == 27 else 53.5)
        dx, dy = r * math.sin(a), r * math.cos(a)
        for side in (1, -1):
            sweep = 1 if side == 1 else 0
            arcs.append(
                f'<path d="M{54 + side * dx:.2f} {54 - dy:.2f}A{r} {r} 0 0 {sweep} {54 + side * dx:.2f} {54 + dy:.2f}"/>'
            )
    return (
        f'<g transform="translate({cx - size / 2:.2f} {cy - size / 2:.2f}) scale({s:.4f})">'
        f'<circle cx="54" cy="54" r="54" fill="{ring}"/><circle cx="54" cy="54" r="8" fill="{ink}"/>'
        f'<g fill="none" stroke="{ink}" stroke-linecap="round" stroke-width="6.5">{"".join(arcs)}</g></g>'
    )


def waves(cx, cy, start, step, count, width, opacity):
    """Concentric sound-wave arcs on both sides of a point, fading outwards."""
    out = []
    for i in range(count):
        r = start + i * step
        o = opacity * (1 - i / count)
        for side in (1, -1):
            a = math.radians(55)
            dx, dy = r * math.sin(a), r * math.cos(a)
            sweep = 1 if side == 1 else 0
            out.append(
                f'<path d="M{cx + side * dx:.1f} {cy - dy:.1f}A{r} {r} 0 0 {sweep} {cx + side * dx:.1f} {cy + dy:.1f}" '
                f'stroke-opacity="{o:.3f}"/>'
            )
    return f'<g fill="none" stroke="{GREEN}" stroke-linecap="round" stroke-width="{width}">{"".join(out)}</g>'


def background(w, h, gx, gy, gr):
    return (
        f'<defs><radialGradient id="glow" cx="{gx}" cy="{gy}" r="{gr}" gradientUnits="userSpaceOnUse">'
        f'<stop offset="0" stop-color="{GREEN}" stop-opacity="0.45"/>'
        f'<stop offset="0.45" stop-color="{GREEN}" stop-opacity="0.12"/>'
        f'<stop offset="1" stop-color="{GREEN}" stop-opacity="0"/></radialGradient></defs>'
        f'<rect width="{w}" height="{h}" fill="{DARK}"/><rect width="{w}" height="{h}" fill="url(#glow)"/>'
    )


def svg(w, h, body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>'


def text(x, y, size, value, anchor="middle", fill="#FFFFFF", extra=""):
    return (
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" fill="{fill}" '
        f'style="{FONT};font-size:{size}px;letter-spacing:{-size * 0.02:.1f}px{extra}">{value}</text>'
    )


ART = {
    # Library grid (portrait capsule).
    "capsule_600x900": svg(600, 900, background(600, 900, 300, 380, 520)
        + waves(300, 380, 170, 46, 7, 10, 0.35) + mark(300, 380, 260)
        + text(300, 700, 92, "Resonance") + text(300, 760, 30, "MUSIC", fill=GREEN, extra=";letter-spacing:10px")),
    # Horizontal capsule (home shelf, recent games).
    "header_920x430": svg(920, 430, background(920, 430, 230, 215, 460)
        + waves(230, 215, 130, 38, 6, 8, 0.35) + mark(230, 215, 200)
        + text(390, 245, 88, "Resonance", anchor="start")),
    # Hero banner above the game page; Steam lays the logo over its lower left.
    "hero_3840x1240": svg(3840, 1240, background(3840, 1240, 2900, 620, 1500)
        + waves(2900, 620, 140, 110, 11, 26, 0.5)),
    # Logo shown over the hero (transparent).
    "logo_1280x720": svg(1280, 720, mark(250, 360, 300) + text(450, 405, 150, "Resonance", anchor="start")),
    # Shortcut icon.
    "icon_256x256": svg(256, 256, mark(128, 128, 256)),
}

for name, source in ART.items():
    path = HERE / f"{name}.svg"
    path.write_text(source)
    subprocess.run(
        ["inkscape", str(path), "--export-text-to-path", "--export-type=png", f"--export-filename={HERE / name}.png"],
        check=True, capture_output=True,
    )
    print(f"{name}.png")

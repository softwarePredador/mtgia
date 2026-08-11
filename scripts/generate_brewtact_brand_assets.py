#!/usr/bin/env python3
"""Generate the deterministic BrewTact Tactical Stack brand asset set.

The source geometry and palette live in this file. Raster exports are produced
with ImageMagick and the wordmark is outlined with HarfBuzz from the bundled
Fraunces font, so no network access or proprietary design application is
required.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import tempfile
from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"
BRAND_ROOT = ROOT / "docs" / "brand" / "brewtact" / "final" / "tactical-stack"
MASTER = BRAND_ROOT / "master"
PREVIEWS = BRAND_ROOT / "previews"
FONT = APP / "assets" / "lotus" / "fonts" / "Fraunces.ttf"

PALETTE = {
    "abyss": "#0B0D12",
    "slate": "#151821",
    "elevated_slate": "#1D222C",
    "brass": "#C58B2A",
    "brass_highlight": "#E0A93B",
    "brass_shadow": "#8E641B",
    "frost": "#6FA8DC",
    "deep_frost": "#3E5F8A",
    "ivory": "#F3EFE3",
    "mist": "#B8C0CC",
    "muted_outline": "#293041",
}

SVG_NS = "http://www.w3.org/2000/svg"
XLINK_NS = "http://www.w3.org/1999/xlink"
ET.register_namespace("", SVG_NS)
ET.register_namespace("xlink", XLINK_NS)


def write_text(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value.rstrip() + "\n", encoding="utf-8")


def command(*args: str) -> None:
    subprocess.run(args, cwd=ROOT, check=True)


def svg_document(*, width: int, height: int, body: str, title: str) -> str:
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="{SVG_NS}" xmlns:xlink="{XLINK_NS}" width="{width}" height="{height}"
  viewBox="0 0 {width} {height}" role="img" aria-labelledby="title">
  <title id="title">{title}</title>
{body}
</svg>'''


def mark_body(*, mono: str | None = None) -> str:
    brass = mono or PALETTE["brass"]
    brass_highlight = mono or PALETTE["brass_highlight"]
    brass_shadow = mono or PALETTE["brass_shadow"]
    frost = mono or PALETTE["frost"]
    deep_frost = mono or PALETTE["deep_frost"]
    return f'''  <g id="tactical-stack-mark">
    <path fill="{brass}" d="M44 52L178 89Q190 92 190 105V132Q190 140 183 144L153 161V130L160 126V114L76 91V125L112 145L84 162L52 144Q44 139 44 130Z"/>
    <path fill="{brass_highlight}" d="M44 52L178 89Q190 92 190 105V114L160 114L76 91V101L44 92Z"/>
    <path fill="{brass_shadow}" d="M76 101V125L112 145L84 162L52 144Q44 139 44 130V113Z"/>
    <path fill="{frost}" d="M107 144L160 116L190 125V154L146 178V207L114 226V176L86 191V160Z"/>
    <path fill="{deep_frost}" d="M146 178V207L114 226V176Z"/>
  </g>'''


def mark_svg(*, mono: str | None = None) -> str:
    suffix = "monochrome" if mono else "full color"
    return svg_document(
        width=256,
        height=256,
        title=f"BrewTact Tactical Stack mark, {suffix}",
        body=mark_body(mono=mono),
    )


def outline_wordmark(target: Path, *, mono: str | None = None) -> str:
    with tempfile.TemporaryDirectory(prefix="brewtact-wordmark-") as temp_dir:
        raw_path = Path(temp_dir) / "wordmark.svg"
        command(
            "hb-view",
            "--output-format=svg",
            f"--output-file={raw_path}",
            "--background=none",
            f"--foreground={PALETTE['ivory'][1:]}",
            "--font-size=128",
            "--margin=0",
            "--shapers=ot",
            "--direction=ltr",
            "--language=en",
            "--script=Latn",
            str(FONT),
            "BrewTact",
        )
        tree = ET.parse(raw_path)

    root = tree.getroot()
    root.set("role", "img")
    root.set("aria-labelledby", "title")
    title = ET.Element(f"{{{SVG_NS}}}title", {"id": "title"})
    title.text = "BrewTact wordmark"
    root.insert(0, title)

    uses = root.findall(f".//{{{SVG_NS}}}use")
    for index, use in enumerate(uses):
        use.set(
            "fill",
            mono or (PALETTE["ivory"] if index < 4 else PALETTE["brass_highlight"]),
        )
    for group in root.findall(f".//{{{SVG_NS}}}g"):
        group.attrib.pop("fill", None)
        group.attrib.pop("fill-opacity", None)

    ET.indent(tree, space="  ")
    tree.write(target, encoding="utf-8", xml_declaration=True)
    return target.read_text(encoding="utf-8")


def wordmark_fragments(svg: str) -> tuple[str, str]:
    """Extract outlined glyph definitions and the positioned use-group."""
    defs_start = svg.index("<defs>")
    defs_end = svg.index("</defs>", defs_start) + len("</defs>")
    group_start = svg.index("<g>", defs_end)
    group_end = svg.rindex("</g>") + len("</g>")
    return svg[defs_start:defs_end], svg[group_start:group_end]


def lockup_svg(*, wordmark_svg: str, stacked: bool, mono: str | None = None) -> str:
    mark = mark_body(mono=mono)
    wordmark_defs, wordmark_uses = wordmark_fragments(wordmark_svg)
    if stacked:
        body = f'''  {wordmark_defs}
  <g transform="translate(224 52) scale(1.25)">
{mark}
  </g>
  <g transform="translate(60 454) scale(1.0015)">
{wordmark_uses}
  </g>'''
        return svg_document(
            width=768,
            height=680,
            title="BrewTact Tactical Stack stacked lockup",
            body=body,
        )

    body = f'''  {wordmark_defs}
  <g transform="translate(12 0) scale(1)">
{mark}
  </g>
  <g transform="translate(286 49) scale(1.0974)">
{wordmark_uses}
  </g>'''
    return svg_document(
        width=1024,
        height=256,
        title="BrewTact Tactical Stack horizontal lockup",
        body=body,
    )


def icon_canvas_svg(*, transparent: bool = False, mark_scale: float = 3.55) -> str:
    background = "" if transparent else f'  <rect width="1024" height="1024" fill="{PALETTE["abyss"]}"/>\n'
    # Center the visible mark bounds (x=44..190, y=52..226), not the roomy
    # 256-unit master canvas.
    offset_x = 512 - (117 * mark_scale)
    offset_y = 512 - (139 * mark_scale)
    return svg_document(
        width=1024,
        height=1024,
        title="BrewTact app icon",
        body=(
            background
            + f'  <g transform="translate({offset_x:.3f} {offset_y:.3f}) scale({mark_scale})">\n'
            + mark_body()
            + "\n  </g>"
        ),
    )


def adaptive_foreground_svg() -> str:
    # The mark remains inside the Android adaptive icon 66/108 safe zone.
    return svg_document(
        width=432,
        height=432,
        title="BrewTact adaptive icon foreground",
        body='  <g transform="translate(34.65 0.55) scale(1.55)">\n'
        + mark_body()
        + "\n  </g>",
    )


def lotus_bridge_icon_svg() -> str:
    scale = 1.78
    offset_x = 256 - (117 * scale)
    offset_y = 256 - (139 * scale)
    return svg_document(
        width=512,
        height=512,
        title="BrewTact app icon",
        body=(
            f'  <rect width="512" height="512" fill="{PALETTE["abyss"]}"/>\n'
            f'  <g transform="translate({offset_x:.3f} {offset_y:.3f}) scale({scale})">\n'
            + mark_body()
            + "\n  </g>"
        ),
    )


def hero_art_svg() -> str:
    p = PALETTE
    body = f'''  <g opacity="0.98">
    <g transform="translate(190 120) rotate(-13 300 350)">
      <rect x="110" y="84" width="410" height="590" rx="42" fill="{p['slate']}" fill-opacity="0.74" stroke="{p['muted_outline']}" stroke-width="8"/>
      <path d="M156 184H472M156 540H472" stroke="{p['deep_frost']}" stroke-opacity="0.36" stroke-width="5"/>
    </g>
    <g transform="translate(300 72) rotate(9 300 350)">
      <rect x="110" y="84" width="410" height="590" rx="42" fill="{p['elevated_slate']}" fill-opacity="0.88" stroke="{p['brass_shadow']}" stroke-opacity="0.72" stroke-width="8"/>
      <path d="M156 184H472M156 540H472" stroke="{p['brass']}" stroke-opacity="0.42" stroke-width="5"/>
    </g>
    <g transform="translate(350 176)">
      <rect x="110" y="84" width="410" height="590" rx="42" fill="{p['slate']}" stroke="{p['brass']}" stroke-width="9"/>
      <rect x="145" y="126" width="340" height="258" rx="24" fill="{p['abyss']}" stroke="{p['muted_outline']}" stroke-width="5"/>
      <path d="M164 484H466M164 536H406" stroke="{p['mist']}" stroke-opacity="0.34" stroke-width="12" stroke-linecap="round"/>
      <g transform="translate(194 128) scale(0.95)">
{mark_body()}
      </g>
    </g>
  </g>
  <path d="M120 760C266 622 382 808 526 688C640 592 716 658 886 514" fill="{p['abyss']}" fill-opacity="0" stroke="{p['frost']}" stroke-opacity="0.52" stroke-width="6" stroke-linecap="round" stroke-dasharray="6 22"/>
  <circle cx="120" cy="760" r="12" fill="{p['brass_highlight']}"/>
  <circle cx="526" cy="688" r="12" fill="{p['frost']}"/>
  <circle cx="886" cy="514" r="12" fill="{p['brass']}"/>'''
    return svg_document(width=1000, height=970, title="BrewTact tactical card stack artwork", body=body)


def banner_svg() -> str:
    p = PALETTE
    body = f'''  <rect width="1200" height="520" fill="{p['abyss']}"/>
  <path d="M456 0H1200V520H354Z" fill="{p['slate']}" fill-opacity="0.58"/>
  <path d="M704 0H1200V520H570Z" fill="{p['elevated_slate']}" fill-opacity="0.34"/>
  <g transform="translate(670 -76) scale(0.72)" opacity="0.96">
    <rect x="210" y="130" width="360" height="520" rx="36" fill="{p['slate']}" stroke="{p['muted_outline']}" stroke-width="8" transform="rotate(-14 390 390)"/>
    <rect x="300" y="106" width="360" height="520" rx="36" fill="{p['elevated_slate']}" stroke="{p['brass_shadow']}" stroke-width="8" transform="rotate(11 480 366)"/>
    <rect x="374" y="160" width="360" height="520" rx="36" fill="{p['slate']}" stroke="{p['brass']}" stroke-width="9"/>
    <g transform="translate(426 238) scale(1.02)">
{mark_body()}
    </g>
  </g>
  <path d="M592 442C706 362 792 450 888 356C974 272 1018 306 1150 206" fill="{p['abyss']}" fill-opacity="0" stroke="{p['frost']}" stroke-opacity="0.42" stroke-width="5" stroke-linecap="round" stroke-dasharray="5 18"/>
  <circle cx="592" cy="442" r="9" fill="{p['brass_highlight']}"/>
  <circle cx="888" cy="356" r="9" fill="{p['frost']}"/>
  <circle cx="1150" cy="206" r="9" fill="{p['brass']}"/>'''
    return svg_document(width=1200, height=520, title="BrewTact home hero banner", body=body)


def splash_svg(*, wide: bool) -> str:
    p = PALETTE
    width, height = (2560, 1440) if wide else (1179, 2556)
    cx, cy = width / 2, height * (0.39 if wide else 0.34)
    card_w = width * (0.15 if wide else 0.34)
    card_h = card_w * 1.42
    radius = card_w * 0.085
    route_y = height * (0.62 if wide else 0.65)
    route_dots = "\n".join(
        f'    <circle cx="{width*x:.1f}" cy="{route_y + height*y:.1f}" r="{max(2.4, width/520):.1f}" fill="{p["frost"]}" fill-opacity="0.58"/>'
        for x, y in (
            (0.14, -0.01),
            (0.23, -0.045),
            (0.33, -0.035),
            (0.42, -0.005),
            (0.58, -0.045),
            (0.68, -0.09),
            (0.79, -0.125),
            (0.87, -0.16),
        )
    )
    body = f'''  <rect width="{width}" height="{height}" fill="{p['abyss']}"/>
  <ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{width*0.46:.1f}" ry="{height*0.34:.1f}" fill="{p['slate']}" fill-opacity="0.42"/>
  <ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{width*0.32:.1f}" ry="{height*0.23:.1f}" fill="{p['elevated_slate']}" fill-opacity="0.24"/>
  <g opacity="0.52">
    <rect x="{cx-card_w*1.15:.1f}" y="{cy-card_h*0.46:.1f}" width="{card_w:.1f}" height="{card_h:.1f}" rx="{radius:.1f}" fill="{p['slate']}" fill-opacity="0.46" stroke="{p['deep_frost']}" stroke-width="{max(3, width/360):.1f}" transform="rotate(-14 {cx-card_w*0.65:.1f} {cy:.1f})"/>
    <rect x="{cx+card_w*0.15:.1f}" y="{cy-card_h*0.46:.1f}" width="{card_w:.1f}" height="{card_h:.1f}" rx="{radius:.1f}" fill="{p['elevated_slate']}" fill-opacity="0.46" stroke="{p['brass_shadow']}" stroke-width="{max(3, width/360):.1f}" transform="rotate(14 {cx+card_w*0.65:.1f} {cy:.1f})"/>
    <rect x="{cx-card_w*0.5:.1f}" y="{cy-card_h*0.55:.1f}" width="{card_w:.1f}" height="{card_h:.1f}" rx="{radius:.1f}" fill="{p['slate']}" fill-opacity="0.64" stroke="{p['brass']}" stroke-width="{max(4, width/300):.1f}"/>
  </g>
  <g opacity="0.58">
{route_dots}
    <circle cx="{width*0.08:.1f}" cy="{route_y:.1f}" r="{max(7, width/170):.1f}" fill="{p['brass_highlight']}"/>
    <circle cx="{width*0.52:.1f}" cy="{route_y-height*0.02:.1f}" r="{max(7, width/170):.1f}" fill="{p['frost']}"/>
    <circle cx="{width*0.92:.1f}" cy="{route_y-height*0.18:.1f}" r="{max(7, width/170):.1f}" fill="{p['brass']}"/>
  </g>'''
    return svg_document(width=width, height=height, title="BrewTact splash background", body=body)


def native_launch_svg(*, width: int, height: int) -> str:
    scale = (min(width, height) * 0.28) / 146
    offset_x = (width / 2) - (117 * scale)
    offset_y = (height / 2) - (139 * scale)
    body = (
        f'  <rect width="{width}" height="{height}" fill="{PALETTE["abyss"]}"/>\n'
        f'  <g transform="translate({offset_x:.3f} {offset_y:.3f}) scale({scale:.6f})">\n'
        + mark_body()
        + "\n  </g>"
    )
    return svg_document(width=width, height=height, title="BrewTact native launch image", body=body)


def render_svg(source: Path, target: Path, width: int, height: int, *, opaque: bool = False) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    prefix = "PNG24:" if opaque else "PNG32:"
    command(
        "magick",
        "-background",
        PALETTE["abyss"] if opaque else "none",
        str(source),
        "-resize",
        f"{width}x{height}!",
        "-strip",
        prefix + str(target),
    )


def resize_png(source: Path, target: Path, size: int) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    command(
        "magick",
        str(source),
        "-filter",
        "Lanczos",
        "-resize",
        f"{size}x{size}!",
        "-strip",
        "PNG24:" + str(target),
    )


def copy(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)


def generate() -> None:
    for directory in (MASTER, PREVIEWS):
        directory.mkdir(parents=True, exist_ok=True)

    mark = MASTER / "brewtact-tactical-stack-mark.svg"
    mark_mono_light = MASTER / "brewtact-tactical-stack-mark-mono-light.svg"
    mark_mono_dark = MASTER / "brewtact-tactical-stack-mark-mono-dark.svg"
    wordmark = MASTER / "brewtact-wordmark.svg"
    wordmark_mono = MASTER / "brewtact-wordmark-mono.svg"
    horizontal = MASTER / "brewtact-lockup-horizontal.svg"
    stacked = MASTER / "brewtact-lockup-stacked.svg"
    horizontal_mono = MASTER / "brewtact-lockup-horizontal-mono.svg"
    icon_canvas = MASTER / "brewtact-app-icon.svg"
    adaptive_foreground = MASTER / "brewtact-adaptive-foreground.svg"
    hero = MASTER / "brewtact-home-hero.svg"
    banner = MASTER / "brewtact-home-hero-banner.svg"
    splash_portrait = MASTER / "brewtact-splash-portrait.svg"
    splash_wide = MASTER / "brewtact-splash-wide.svg"

    write_text(mark, mark_svg())
    write_text(mark_mono_light, mark_svg(mono=PALETTE["ivory"]))
    write_text(mark_mono_dark, mark_svg(mono=PALETTE["abyss"]))
    wordmark_svg = outline_wordmark(wordmark)
    wordmark_mono_svg = outline_wordmark(wordmark_mono, mono=PALETTE["ivory"])
    write_text(horizontal, lockup_svg(wordmark_svg=wordmark_svg, stacked=False))
    write_text(stacked, lockup_svg(wordmark_svg=wordmark_svg, stacked=True))
    write_text(
        horizontal_mono,
        lockup_svg(
            wordmark_svg=wordmark_mono_svg,
            stacked=False,
            mono=PALETTE["ivory"],
        ),
    )
    write_text(icon_canvas, icon_canvas_svg())
    write_text(adaptive_foreground, adaptive_foreground_svg())
    write_text(hero, hero_art_svg())
    write_text(banner, banner_svg())
    write_text(splash_portrait, splash_svg(wide=False))
    write_text(splash_wide, splash_svg(wide=True))

    app_branding = APP / "assets" / "branding"
    app_logo = app_branding / "app_logo.png"
    render_svg(icon_canvas, app_logo, 1024, 1024, opaque=True)
    render_svg(hero, app_branding / "home_hero.png", 1000, 970)
    render_svg(banner, app_branding / "home_hero_banner.png", 1200, 520, opaque=True)
    render_svg(splash_portrait, app_branding / "splash_art.png", 1179, 2556, opaque=True)
    render_svg(splash_wide, app_branding / "splash_art_wide.png", 2560, 1440, opaque=True)

    copy(mark, APP / "assets" / "icons" / "brand.svg")
    write_text(APP / "assets" / "lotus" / "images" / "app-icon.svg", lotus_bridge_icon_svg())
    copy(wordmark, app_branding / "brewtact_wordmark.svg")
    copy(horizontal, app_branding / "brewtact_lockup_horizontal.svg")
    copy(stacked, app_branding / "brewtact_lockup_stacked.svg")

    public_branding = ROOT / "web-public" / "public" / "branding"
    for filename in (
        "app_logo.png",
        "home_hero.png",
        "home_hero_banner.png",
        "splash_art_wide.png",
        "brewtact_wordmark.svg",
        "brewtact_lockup_horizontal.svg",
        "brewtact_lockup_stacked.svg",
    ):
        copy(app_branding / filename, public_branding / filename)
    copy(mark, public_branding / "brewtact_mark.svg")

    ios_icon_dir = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios_sizes.items():
        resize_png(app_logo, ios_icon_dir / filename, size)

    launch_dir = APP / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    for filename, width, height in (
        ("LaunchImage.png", 393, 852),
        ("LaunchImage@2x.png", 786, 1704),
        ("LaunchImage@3x.png", 1179, 2556),
    ):
        launch_source = Path(tempfile.gettempdir()) / f"brewtact-{filename}.svg"
        write_text(launch_source, native_launch_svg(width=width, height=height))
        render_svg(launch_source, launch_dir / filename, width, height, opaque=True)
        launch_source.unlink(missing_ok=True)

    android_res = APP / "android" / "app" / "src" / "main" / "res"
    foreground = android_res / "drawable-nodpi" / "ic_launcher_foreground.png"
    render_svg(adaptive_foreground, foreground, 432, 432)
    native_fallback = Path(tempfile.gettempdir()) / "brewtact-native-launch-1080x2400.svg"
    write_text(native_fallback, native_launch_svg(width=1080, height=2400))
    render_svg(
        native_fallback,
        android_res / "drawable-nodpi" / "launch_image.png",
        1080,
        2400,
        opaque=True,
    )
    native_fallback.unlink(missing_ok=True)

    android_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in android_sizes.items():
        for filename in ("ic_launcher.png", "ic_launcher_round.png"):
            resize_png(app_logo, android_res / f"mipmap-{density}" / filename, size)

    web_dir = APP / "web"
    normal_192 = web_dir / "icons" / "Icon-192.png"
    normal_512 = web_dir / "icons" / "Icon-512.png"
    resize_png(app_logo, normal_192, 192)
    resize_png(app_logo, normal_512, 512)

    maskable_source = MASTER / "brewtact-app-icon-maskable.svg"
    write_text(maskable_source, icon_canvas_svg(mark_scale=3.40))
    render_svg(maskable_source, web_dir / "icons" / "Icon-maskable-192.png", 192, 192, opaque=True)
    render_svg(maskable_source, web_dir / "icons" / "Icon-maskable-512.png", 512, 512, opaque=True)
    favicon_source = MASTER / "brewtact-favicon-optical.svg"
    favicon_raster = PREVIEWS / "favicon-optical-1024.png"
    write_text(favicon_source, icon_canvas_svg(mark_scale=4.65))
    render_svg(favicon_source, favicon_raster, 1024, 1024, opaque=True)
    resize_png(favicon_raster, web_dir / "favicon.png", 32)
    command(
        "magick",
        str(favicon_raster),
        "-define",
        "icon:auto-resize=16,24,32,48,64",
        str(web_dir / "favicon.ico"),
    )

    public_root = ROOT / "web-public" / "public"
    copy(web_dir / "favicon.png", public_root / "favicon.png")
    copy(web_dir / "favicon.ico", public_root / "favicon.ico")
    for filename in (
        "Icon-192.png",
        "Icon-512.png",
        "Icon-maskable-192.png",
        "Icon-maskable-512.png",
    ):
        copy(web_dir / "icons" / filename, public_root / "icons" / filename)

    render_svg(horizontal, PREVIEWS / "horizontal-lockup.png", 1536, 384)
    render_svg(stacked, PREVIEWS / "stacked-lockup.png", 1024, 907)
    render_svg(icon_canvas, PREVIEWS / "app-icon-1024.png", 1024, 1024, opaque=True)
    render_svg(mark, PREVIEWS / "mark-256.png", 256, 256)
    render_svg(mark, PREVIEWS / "mark-64.png", 64, 64)
    render_svg(mark, PREVIEWS / "mark-32.png", 32, 32)
    render_svg(mark, PREVIEWS / "mark-16.png", 16, 16)
    resize_png(favicon_raster, PREVIEWS / "favicon-16.png", 16)
    resize_png(favicon_raster, PREVIEWS / "favicon-32.png", 32)
    resize_png(favicon_raster, PREVIEWS / "favicon-48.png", 48)

    tracked_roots = [
        MASTER,
        PREVIEWS,
        public_branding,
        web_dir / "icons",
        public_root / "icons",
        ios_icon_dir,
        launch_dir,
    ]
    tracked_files: list[Path] = [
        app_branding / "app_logo.png",
        app_branding / "home_hero.png",
        app_branding / "home_hero_banner.png",
        app_branding / "splash_art.png",
        app_branding / "splash_art_wide.png",
        app_branding / "brewtact_wordmark.svg",
        app_branding / "brewtact_lockup_horizontal.svg",
        app_branding / "brewtact_lockup_stacked.svg",
        APP / "assets" / "icons" / "brand.svg",
        APP / "assets" / "lotus" / "images" / "app-icon.svg",
        APP / "assets" / "lotus" / "images" / "dagger.svg",
        web_dir / "favicon.png",
        web_dir / "favicon.ico",
        web_dir / "manifest.json",
        public_root / "favicon.png",
        public_root / "favicon.ico",
        android_res / "drawable-nodpi" / "ic_launcher_foreground.png",
        android_res / "drawable-nodpi" / "launch_image.png",
        android_res / "drawable" / "launch_mark.xml",
        android_res / "drawable" / "ic_launcher_monochrome.xml",
        android_res / "drawable" / "ic_stat_manaloom_notification.xml",
        android_res / "drawable" / "launch_background.xml",
        android_res / "drawable-v21" / "launch_background.xml",
        android_res / "values" / "colors.xml",
        android_res / "values-v31" / "styles.xml",
        android_res / "values-night-v31" / "styles.xml",
        APP / "ios" / "Runner" / "Base.lproj" / "LaunchScreen.storyboard",
    ]
    for density in android_sizes:
        tracked_files.extend(
            [
                android_res / f"mipmap-{density}" / "ic_launcher.png",
                android_res / f"mipmap-{density}" / "ic_launcher_round.png",
            ]
        )
    tracked_files.extend(
        [
            android_res / "mipmap-anydpi-v26" / "ic_launcher.xml",
            android_res / "mipmap-anydpi-v26" / "ic_launcher_round.xml",
            android_res / "mipmap-anydpi-v33" / "ic_launcher.xml",
            android_res / "mipmap-anydpi-v33" / "ic_launcher_round.xml",
        ]
    )
    for tracked_root in tracked_roots:
        tracked_files.extend(
            path for path in tracked_root.rglob("*") if path.is_file() and path.name != "asset-manifest.json"
        )
    unique_files = sorted(set(tracked_files))
    manifest = {
        "brand": "BrewTact",
        "direction": "Tactical Stack",
        "palette": PALETTE,
        "generator": "scripts/generate_brewtact_brand_assets.py",
        "files": [
            {
                "path": str(path.relative_to(ROOT)),
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "bytes": path.stat().st_size,
            }
            for path in unique_files
        ],
    }
    write_text(BRAND_ROOT / "asset-manifest.json", json.dumps(manifest, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    generate()

#!/usr/bin/env python3
"""App Store composer (Pillow port of assets/brand/compose_screenshots.js).

Raw 1320x2868 iPhone renders -> branded 1320x2868 PNG (no alpha), gradient style,
same captions as the Play set. Used because sharp may be unavailable.
usage: python tool/compose_screenshots_ios.py <rawDir> <outDir> <lang>
"""
import os
import re
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

raw_dir, out_dir, lang = sys.argv[1:4]
os.makedirs(out_dir, exist_ok=True)

# Captions are read from the Play composer so both sets stay in sync.
here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, '..', 'assets', 'brand', 'compose_screenshots.js'), encoding='utf-8').read()
CAP = {}
for m in re.finditer(r"'(0\d-[a-z-]+)':\s*\{\s*en: \[([^\]]*)\],\s*tr: \[([^\]]*)\],\s*es: \[([^\]]*)\]", src):
    key = m.group(1)
    CAP[key] = {l: re.findall(r"'([^']*)'", g) for l, g in zip(('en', 'tr', 'es'), m.groups()[1:])}

W, H = 1320, 2868
K = W / 1080  # scale vs. the Play layout
CROP_TOP = 59 * 3  # Dynamic Island / status bar; home indicator is bled off the bottom
PHONE_W, RADIUS, BORDER = 1160, 68, 7
PHONE_X, PHONE_Y = (W - PHONE_W) // 2, 540
BG0, BG1 = (0x0f, 0xb8, 0x8e), (0x25, 0x63, 0xeb)
GLOW_OP = 0.18
T1, T2, BAR, BORDER_C = (255, 255, 255), (0xd8, 0xff, 0xf3), (255, 255, 255), (0xe6, 0xf2, 0xff)
FONT = 'C:/Windows/Fonts/segoeuib.ttf'


def background(lines):
    u = (np.arange(W) + 0.5) / W
    v = (np.arange(H) + 0.5) / H
    uu, vv = np.meshgrid(u, v)
    t = ((uu + vv) / 2)[..., None]
    img = np.array(BG0) * (1 - t) + np.array(BG1) * t
    r = np.sqrt(((uu - 0.5) / 0.6) ** 2 + ((vv - 0.62) / 0.6) ** 2)
    a = (GLOW_OP * np.clip(1 - r, 0, 1))[..., None]
    img = img * (1 - a) + 255 * a
    im = Image.fromarray(np.clip(img + 0.5, 0, 255).astype('uint8'), 'RGB')
    d = ImageDraw.Draw(im)
    font = ImageFont.truetype(FONT, round(78 * K))
    for i, line in enumerate(lines):
        y = round((150 + i * 84) * K)
        d.text((W / 2, y), line, font=font, fill=T2 if i == 1 else T1, anchor='ms')
    bw, bh = round(120 * K), round(8 * K)
    by = round((150 + 84 + 40) * K)
    d.rounded_rectangle((W / 2 - bw / 2, by, W / 2 + bw / 2, by + bh), radius=bh // 2, fill=BAR)
    return im


def rounded_mask(w, h, r, scale=4):
    m = Image.new('L', (w * scale, h * scale), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w * scale - 1, h * scale - 1), radius=r * scale, fill=255)
    return m.resize((w, h), Image.LANCZOS)


for f in sorted(os.listdir(raw_dir)):
    if not f.endswith('.png'):
        continue
    key = f[:-4]
    lines = CAP.get(key, {}).get(lang, ['', ''])
    raw = Image.open(os.path.join(raw_dir, f)).convert('RGB')
    crop = raw.crop((0, CROP_TOP, raw.width, raw.height))
    ph = round(PHONE_W * crop.height / crop.width)
    phone = crop.resize((PHONE_W, ph), Image.LANCZOS)
    canvas = background(lines).convert('RGBA')
    # shadow
    sh = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        (PHONE_X + 12, PHONE_Y + 36, PHONE_X + PHONE_W + 12, PHONE_Y + ph + 36),
        radius=RADIUS, fill=(0, 0, 0, round(255 * 0.45)))
    sh = sh.filter(ImageFilter.GaussianBlur(34))
    canvas = Image.alpha_composite(canvas, sh)
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    layer.paste(phone, (PHONE_X, PHONE_Y), rounded_mask(PHONE_W, ph, RADIUS))
    canvas = Image.alpha_composite(canvas, layer)
    # frame (stroke centered on the phone edge, like the Play composer)
    S = 4
    fr = Image.new('RGBA', ((PHONE_W + 2 * BORDER) * S, (ph + 2 * BORDER) * S), (0, 0, 0, 0))
    ImageDraw.Draw(fr).rounded_rectangle(
        (BORDER * S / 2, BORDER * S / 2, (PHONE_W + 1.5 * BORDER) * S, (ph + 1.5 * BORDER) * S),
        radius=(RADIUS + BORDER / 2) * S, outline=BORDER_C + (255,), width=BORDER * S)
    fr = fr.resize((PHONE_W + 2 * BORDER, ph + 2 * BORDER), Image.LANCZOS)
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    layer.paste(fr, (PHONE_X - BORDER, PHONE_Y - BORDER))
    canvas = Image.alpha_composite(canvas, layer)
    out = canvas.convert('RGB')  # flatten: no alpha channel
    out.save(os.path.join(out_dir, key + '.png'), optimize=True)
    print('ok', key, f'{W}x{H}')

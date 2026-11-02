"""Flattens the raw IAP-review renders to RGB PNGs (no alpha) in
store_assets/iap_review/ and verifies size/mode. Usage: python tool/iap_review_finalize.py"""
from PIL import Image
import os
RAW, OUT = "store_assets/iap_review/raw", "store_assets/iap_review"
MAP = {"credits_top": "credits", "credits_scroll_1000": "credits_2",
       "pro_scroll_3000": "pro", "pro_top": "pro_top"}
for src, dst in MAP.items():
    im = Image.open(f"{RAW}/{src}.png")
    bg = Image.new("RGB", im.size, (0, 0, 0))
    bg.paste(im, mask=im.getchannel("A") if im.mode == "RGBA" else None)
    bg.save(f"{OUT}/{dst}.png", optimize=True)
    chk = Image.open(f"{OUT}/{dst}.png")
    assert chk.size == (1320, 2868) and chk.mode == "RGB", (dst, chk.size, chk.mode)
    print(dst, chk.size, chk.mode)

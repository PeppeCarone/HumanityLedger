"""Slice the category-B map sprite-sheets (Assets/*.png, 1024x559) into
individual transparent PNGs.

Strategy: remove the sheet background (checker / dark / parchment), build an
alpha mask, dilate it so within-asset gaps (sparkles, dashes) merge, label
connected components, then crop each component's tight bbox from the
background-cleared image.

Run from project root:
    python tools/slice_map_assets.py          # write crops + debug overlays
    python tools/slice_map_assets.py --debug   # only debug overlays
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

SRC = "Assets/art/_sheets"
OUT = "Assets/art/map"
DBG = "tools/_preview"


# ---------- background predicates (operate on np uint8 HxWx3) ----------

def mask_checker(rgb):
    r, g, b = rgb[..., 0].astype(int), rgb[..., 1].astype(int), rgb[..., 2].astype(int)
    avg = (r + g + b) / 3.0
    chroma = np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)
    return (chroma <= 22) & (avg >= 70) & (avg <= 250)


def mask_dark(rgb):
    r, g, b = rgb[..., 0].astype(int), rgb[..., 1].astype(int), rgb[..., 2].astype(int)
    avg = (r + g + b) / 3.0
    chroma = np.maximum(np.maximum(r, g), b) - np.minimum(np.minimum(r, g), b)
    return (avg <= 52) & (chroma <= 16)


def mask_parchment(rgb):
    r, g, b = rgb[..., 0].astype(int), rgb[..., 1].astype(int), rgb[..., 2].astype(int)
    # cream: high, r>=g>=b, low saturation
    return (r >= 200) & (r >= g - 4) & (g >= b - 6) & ((r - b) <= 70) & (b >= 150)


BG = {"checker": mask_checker, "dark": mask_dark, "parchment": mask_parchment}


def flood_bg(rgb, predicate):
    """Flood-fill from the borders over pixels matching predicate.
    Returns boolean bg mask (True = background to clear)."""
    h, w = rgb.shape[:2]
    cand = predicate(rgb)
    bg = np.zeros((h, w), bool)
    seen = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        q.append((0, x)); q.append((h - 1, x))
    for y in range(h):
        q.append((y, 0)); q.append((y, w - 1))
    while q:
        y, x = q.popleft()
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x]:
            continue
        seen[y, x] = True
        if not cand[y, x]:
            continue
        bg[y, x] = True
        q.append((y + 1, x)); q.append((y - 1, x))
        q.append((y, x + 1)); q.append((y, x - 1))
    return bg


# ---------- segmentation ----------

def segment(sheet, bg_type, dilate, min_area, min_side, alpha_thr=40, min_sat_frac=0.0):
    path = os.path.join(SRC, sheet + ".png")
    im = Image.open(path).convert("RGBA")
    rgb = np.array(im)[..., :3]
    bg = flood_bg(rgb, BG[bg_type])

    rgba = np.array(im)
    rgba[bg, 3] = 0
    cleared = Image.fromarray(rgba, "RGBA")

    mask = rgba[..., 3] > alpha_thr
    if dilate > 0:
        mask_d = ndimage.binary_dilation(mask, iterations=dilate)
    else:
        mask_d = mask
    lbl, n = ndimage.label(mask_d)
    boxes = []
    for i in range(1, n + 1):
        ys, xs = np.where(lbl == i)
        if ys.size == 0:
            continue
        # tight bbox from the ORIGINAL (undilated) mask within this component
        comp = mask & (lbl == i)
        cy, cx = np.where(comp)
        if cy.size == 0:
            continue
        y0, y1, x0, x1 = cy.min(), cy.max() + 1, cx.min(), cx.max() + 1
        if (y1 - y0) < min_side or (x1 - x0) < min_side:
            continue
        if comp.sum() < min_area:
            continue
        if min_sat_frac > 0.0:
            sub = rgb[y0:y1, x0:x1].astype(int)
            cm = sub.max(axis=2) - sub.min(axis=2)
            compsub = comp[y0:y1, x0:x1]
            sat = ((cm > 35) & compsub).sum()
            if sat < min_sat_frac * comp.sum():
                continue
        boxes.append((x0, y0, x1, y1))
    # reading order: top-to-bottom, left-to-right (row-banded)
    boxes.sort(key=lambda b: (round(b[1] / 40), b[0]))
    return cleared, boxes


def run(sheet, bg_type, dilate, min_area, min_side, pad=6, debug_only=False, min_sat_frac=0.0):
    cleared, boxes = segment(sheet, bg_type, dilate, min_area, min_side, min_sat_frac=min_sat_frac)
    os.makedirs(DBG, exist_ok=True)
    ov = cleared.copy()
    # put debug boxes over a neutral bg so transparent art is visible
    bg_img = Image.new("RGBA", ov.size, (40, 40, 46, 255))
    bg_img.alpha_composite(ov)
    d = ImageDraw.Draw(bg_img)
    for idx, (x0, y0, x1, y1) in enumerate(boxes):
        d.rectangle([x0, y0, x1, y1], outline=(255, 80, 80, 255), width=2)
        d.text((x0 + 2, y0 + 2), str(idx), fill=(255, 255, 0, 255))
    bg_img.convert("RGB").save(os.path.join(DBG, "dbg_" + sheet + ".png"))

    if not debug_only:
        out = os.path.join(OUT, sheet)
        os.makedirs(out, exist_ok=True)
        for idx, (x0, y0, x1, y1) in enumerate(boxes):
            cell = cleared.crop((x0, y0, x1, y1))
            canvas = Image.new("RGBA", (cell.width + pad * 2, cell.height + pad * 2), (0, 0, 0, 0))
            canvas.paste(cell, (pad, pad), cell)
            canvas.save(os.path.join(out, "%02d.png" % idx))
    print("%-22s -> %d assets" % (sheet, len(boxes)))


# per-sheet tuning
CONFIG = [
    # sheet, bg, dilate, min_area, min_side, min_sat_frac
    ("interactive_marker", "checker", 4, 220, 16, 0.0),
    ("live_feedback", "checker", 6, 600, 28, 0.0),
    ("Chosen_consequences", "dark", 2, 400, 22, 0.0),
    ("map_transformation", "checker", 3, 500, 20, 0.0),
    ("dynamic_lines", "parchment", 5, 300, 16, 0.22),
]


if __name__ == "__main__":
    debug_only = "--debug" in sys.argv
    for sheet, bg_type, dil, ma, ms, msf in CONFIG:
        run(sheet, bg_type, dil, ma, ms, debug_only=debug_only, min_sat_frac=msf)
    print("done -> %s  (debug: %s)" % (OUT, DBG))

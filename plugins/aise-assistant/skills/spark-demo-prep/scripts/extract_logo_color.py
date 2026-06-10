#!/usr/bin/env python3
"""
extract_logo_color.py
Given a domain, fetches the company's logo/favicon, extracts the dominant
non-neutral color, and maps it to the nearest Spark demo color scheme.

Usage:  python3 extract_logo_color.py qlik.com
Output: one of: orange-navy | teal-dark | purple-dark | FALLBACK
"""

import sys
import colorsys

try:
    import requests
    from PIL import Image
    from io import BytesIO
    from collections import Counter
except ImportError:
    print("FALLBACK")
    sys.exit(0)

# Scheme definitions: (H_min, H_max, S_min) in HSV degrees
# H: 0-360, S: 0-1
SCHEMES = {
    "orange-navy": {"hue_center": 18,   "hue_tolerance": 40, "s_min": 0.4},  # oranges/reds
    "teal-dark":   {"hue_center": 168,  "hue_tolerance": 45, "s_min": 0.3},  # greens/teals
    "purple-dark": {"hue_center": 270,  "hue_tolerance": 50, "s_min": 0.3},  # purples/blues
}


def fetch_logo(domain: str) -> "Image.Image | None":
    """Try Clearbit logo API first, then Google favicon as fallback."""
    sources = [
        f"https://logo.clearbit.com/{domain}",
        f"https://www.google.com/s2/favicons?domain={domain}&sz=128",
        f"https://{domain}/favicon.ico",
    ]
    headers = {"User-Agent": "Mozilla/5.0"}
    for url in sources:
        try:
            r = requests.get(url, headers=headers, timeout=5)
            if r.status_code == 200 and len(r.content) > 200:
                img = Image.open(BytesIO(r.content)).convert("RGBA")
                return img
        except Exception:
            continue
    return None


def dominant_hue(img: "Image.Image") -> "tuple[float, float] | None":
    """
    Return (hue_degrees, saturation) of the most common non-neutral, non-white,
    non-black pixel. Returns None if no suitable color found.
    """
    img = img.resize((64, 64), Image.LANCZOS)
    pixels = list(img.getdata())

    hsv_pixels = []
    for px in pixels:
        if len(px) == 4:
            r, g, b, a = px
        else:
            r, g, b = px
            a = 255
        if a < 30:  # skip transparent
            continue
        rn, gn, bn = r / 255, g / 255, b / 255
        h, s, v = colorsys.rgb_to_hsv(rn, gn, bn)
        if s < 0.15 or v < 0.1 or v > 0.97:
            continue
        hsv_pixels.append((h * 360, s, v))

    if not hsv_pixels:
        return None

    # Bucket hues into 36 x 10 degree bins, find most populated
    buckets: Counter = Counter()
    for h, s, v in hsv_pixels:
        bucket = int(h / 10) * 10
        buckets[bucket] += 1

    dominant_bucket = buckets.most_common(1)[0][0]
    matching = [(s, v) for h, s, v in hsv_pixels if abs(h - dominant_bucket) < 15]
    avg_s = sum(s for s, _ in matching) / len(matching)
    return (dominant_bucket, avg_s)


def map_to_scheme(hue: float, saturation: float) -> str:
    """Map a hue + saturation to the nearest defined scheme."""
    best_scheme = None
    best_distance = float("inf")

    for name, params in SCHEMES.items():
        if saturation < params["s_min"]:
            continue
        diff = abs(hue - params["hue_center"])
        dist = min(diff, 360 - diff)
        if dist < params["hue_tolerance"] and dist < best_distance:
            best_distance = dist
            best_scheme = name

    return best_scheme or "FALLBACK"


def main():
    if len(sys.argv) < 2:
        print("FALLBACK")
        sys.exit(0)

    domain = sys.argv[1].strip().lstrip("https://").lstrip("http://").split("/")[0]
    img = fetch_logo(domain)
    if img is None:
        print("FALLBACK")
        sys.exit(0)

    result = dominant_hue(img)
    if result is None:
        print("FALLBACK")
        sys.exit(0)

    hue, saturation = result
    scheme = map_to_scheme(hue, saturation)
    print(scheme)


if __name__ == "__main__":
    main()

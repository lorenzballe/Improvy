"""Sets the real app screens under their headlines, at the exact sizes the
stores ask for, into store_listing/.

    flutter test test/store_listing_test.dart --run-skipped --update-goldens
    python3 tool/store_screenshots.py [ios-widgets-dir] [android-widgets-dir]

The screens come from test/store/ (rendered from the shipping widgets by
test/store_listing_test.dart). The widget slide uses the real widget renders
the Widgets workflows publish (branches widget-renders and
android-widget-renders); pass their `unplayed` folders to include it.

Output (JPEG, no alpha — App Store Connect refuses transparency):
  store_listing/1 - Apple App Store (iPhone e iPad)/
      Telefono - iPhone 6.9 pollici/   1320x2868
      Tablet - iPad 13 pollici/        2064x2752
  store_listing/2 - Google Play (Android)/
      Telefono/                        1080x1920
      Tablet/                          1536x2048
      Immagine in evidenza 1024x500.jpg
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "test", "store")
OUT = os.path.join(ROOT, "store_listing")
FONTS = os.path.join(ROOT, "assets", "fonts")

BG = (15, 10, 26)
BRAND = [(34, 211, 238), (148, 77, 255), (239, 68, 68)]  # the IMPROVY logo

# (raw screen, headline line 1, headline line 2 in the brand gradient,
#  subline, accent glow)
SLIDES = [
    ("1_chromatic", "Every degree.", "Every key.", "Name it before you can count it.", (148, 77, 255)),
    ("2_home", "All 12 keys,", "one by one.", "Watch each one fill up as you learn it.", (236, 72, 153)),
    ("3_daily", "One challenge", "a day.", "The same for everyone. Keep the streak.", (16, 185, 129)),
    ("4_stats", "See what slows", "you down.", "Speed and accuracy for every key and degree.", (34, 211, 238)),
    ("5_pocket", "Train with the", "screen off.", "Pocket Mode asks out loud, then answers.", (99, 102, 241)),
    ("6_n2n", "Both", "directions.", "See a note, name its degree. And back.", (59, 130, 246)),
]
PHONE = ["1_chromatic", "3_daily", "4_stats", "5_pocket"]
TABLET = ["1_chromatic", "2_home", "3_daily", "4_stats", "5_pocket"]
WIDGETS = ("A question on", "your home screen.", "A new degree every hour. Tap to reveal it.", (249, 115, 22))


def font(weight, size):
    return ImageFont.truetype(os.path.join(FONTS, f"Lexend-{weight}.ttf"), size)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient_strip(w, h, stops):
    """A horizontal gradient through [stops]."""
    img = Image.new("RGB", (w, h))
    px = img.load()
    for x in range(w):
        t = x / max(1, w - 1) * (len(stops) - 1)
        i = min(int(t), len(stops) - 2)
        c = lerp(stops[i], stops[i + 1], t - i)
        for y in range(h):
            px[x, y] = c
    return img


def background(w, h, accent):
    """The app's own backdrop: near-black violet, lit by the slide's accent."""
    img = Image.new("RGB", (w, h), BG)
    glow = Image.new("RGB", (w, h), (0, 0, 0))
    d = ImageDraw.Draw(glow)
    r = int(w * 0.75)
    d.ellipse([w * 0.5 - r, -r * 0.9, w * 0.5 + r, r * 0.6], fill=tuple(int(c * 0.42) for c in accent))
    r2 = int(w * 0.6)
    d.ellipse([w - r2 * 0.6, h * 0.55, w + r2 * 1.2, h * 0.55 + r2 * 1.6], fill=(70, 22, 90))
    d.ellipse([-r2 * 1.1, h * 0.35, r2 * 0.5, h * 0.35 + r2 * 1.5], fill=(28, 24, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(w * 0.16))
    return _screen(img, glow)


def _screen(a, b):
    """Screen blend: lightens a by b, never darkens."""
    from PIL import ImageChops
    return ImageChops.screen(a, b)


def headline(canvas, top, line1, line2, sub, size, sub_size, width):
    d = ImageDraw.Draw(canvas)
    f = font("Bold", size)
    fs = font("Regular", sub_size)
    cx = canvas.width // 2
    gap = int(size * 1.12)

    def fitted(text, fnt, maxw):
        s = fnt.size
        while fnt.getlength(text) > maxw and s > 20:
            s -= 2
            fnt = font("Bold", s)
        return fnt

    f1 = fitted(line1, f, width)
    w1 = f1.getlength(line1)
    d.text((cx - w1 / 2, top), line1, font=f1, fill=(255, 255, 255))

    f2 = fitted(line2, f, width)
    w2 = int(f2.getlength(line2))
    bbox = f2.getbbox(line2)
    mask = Image.new("L", (w2 + 10, bbox[3] + 20), 0)
    ImageDraw.Draw(mask).text((0, 0), line2, font=f2, fill=255)
    grad = gradient_strip(mask.width, mask.height, BRAND)
    canvas.paste(grad, (int(cx - w2 / 2), top + gap), mask)

    sy = top + gap * 2 + int(size * 0.18)
    sw = fs.getlength(sub)
    while sw > width and fs.size > 18:
        fs = font("Regular", fs.size - 2)
        sw = fs.getlength(sub)
    d.text((cx - sw / 2, sy), sub, font=fs, fill=(196, 190, 214))
    return sy + int(fs.size * 1.4)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def status_bar(screen, scale, island, points_w):
    """9:41, the battery, and the Dynamic Island or a punch-hole camera, at
    real iPhone geometry: the app's render already leaves the room for them."""
    d = ImageDraw.Draw(screen)
    s = screen.width / points_w  # pixels per point in this screen
    f = font("SemiBold", int(17 * s))
    y = int(19 * s)
    d.text((int(52 * s) if island else int(26 * s), y), "9:41", font=f, fill=(255, 255, 255))
    bw, bh = 25 * s, 12 * s
    bx = screen.width - (52 if island else 30) * s - bw
    by = y + 3 * s
    d.rounded_rectangle([bx, by, bx + bw, by + bh], 3.5 * s, outline=(255, 255, 255, 110), width=max(1, int(s)))
    d.rounded_rectangle([bx + 2 * s, by + 2 * s, bx + bw * 0.78, by + bh - 2 * s], 2 * s, fill=(255, 255, 255))
    d.rounded_rectangle([bx + bw + 1.5 * s, by + 4 * s, bx + bw + 3 * s, by + bh - 4 * s], 1 * s, fill=(255, 255, 255, 110))
    if island:
        iw, ih = 126 * s, 37 * s
        d.rounded_rectangle([screen.width / 2 - iw / 2, 11 * s, screen.width / 2 + iw / 2, 11 * s + ih], ih / 2, fill=(0, 0, 0))
    else:
        r = 6 * s
        d.ellipse([screen.width / 2 - r, 14 * s, screen.width / 2 + r, 14 * s + 2 * r], fill=(0, 0, 0))


def device(screen, width, radius_ratio, bezel_ratio):
    """The screen inside a thin dark bezel with a soft edge light and shadow."""
    scale = width / screen.width
    shot = screen.resize((width, round(screen.height * scale)), Image.LANCZOS)
    bezel = max(6, int(width * bezel_ratio))
    r = int(width * radius_ratio)
    W, H = shot.width + bezel * 2, shot.height + bezel * 2
    body = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle([0, 0, W - 1, H - 1], r + bezel, fill=(8, 6, 14))
    d.rounded_rectangle([1, 1, W - 2, H - 2], r + bezel, outline=(70, 62, 92), width=max(2, bezel // 6))
    body.alpha_composite(rounded(shot.convert("RGBA"), r), (bezel, bezel))
    return body


def place(canvas, body, x, y):
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sm = Image.new("L", body.size, 0)
    sm.paste(body.split()[3])
    blur = int(body.width * 0.05)
    s = Image.new("RGBA", body.size, (0, 0, 0, 170))
    shadow.paste(s, (x, y + blur // 2), sm)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(body, (x, y))


def compose(screen, W, H, words, *, head, sub, radius, bezel, island, points_w, top_ratio=0.065, side=0.11):
    line1, line2, subline, accent = words
    canvas = background(W, H, accent).convert("RGBA")
    text_bottom = headline(canvas, int(H * top_ratio), line1, line2, subline, head, sub, int(W * 0.86))
    screen = screen.convert("RGB").copy()
    status_bar(screen, 1, island, points_w)
    avail_h = H - text_bottom - int(H * 0.03)
    width = int(W * (1 - 2 * side))
    body = device(screen, width, radius, bezel)
    if body.height > avail_h:
        width = int(width * avail_h / body.height)
        body = device(screen, width, radius, bezel)
    place(canvas, body, (W - body.width) // 2, text_bottom + int(H * 0.012))
    return canvas.convert("RGB")


def home_screen(size, widgets, wallpaper_accent):
    """A phone home screen holding the real widget renders."""
    w, h = size
    img = background(w, h, wallpaper_accent).convert("RGBA")
    s = w / 440  # pixels per point
    pad = int(24 * s)
    y = int(80 * s)
    gap = int(22 * s)
    full = w - pad * 2

    def put(path, x, y, width):
        im = Image.open(path).convert("RGBA")
        im = im.resize((int(width), int(im.height * width / im.width)), Image.LANCZOS)
        img.alpha_composite(im, (int(x), int(y)))
        return im.height

    rows = widgets
    for row in rows:
        if len(row) == 1:
            y += put(row[0], pad, y, full) + gap
        else:
            half = (full - gap) / 2
            h1 = put(row[0], pad, y, half)
            put(row[1], pad + half + gap, y, half)
            y += h1 + gap
    return img.convert("RGB")


def save(img, *parts):
    path = os.path.join(OUT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "JPEG", quality=92, optimize=True, progressive=True)
    print(path, img.size)


def main():
    ios_widgets = sys.argv[1] if len(sys.argv) > 1 else None
    android_widgets = sys.argv[2] if len(sys.argv) > 2 else None
    by_name = {slide[0]: slide for slide in SLIDES}
    # Five a device: the strongest four screens, then the widgets on phones
    # (the home-screen slide) and Home on the iPad, which has no widget slide.
    for n, name in enumerate(PHONE, 1):
        _, l1, l2, sub, accent = by_name[name]
        phone = Image.open(os.path.join(RAW, f"iphone_{name}.png"))
        save(compose(phone, 1320, 2868, (l1, l2, sub, accent), head=128, sub=50,
                     radius=0.125, bezel=0.022, island=True, points_w=440),
             "1 - Apple App Store (iPhone e iPad)", "Telefono - iPhone 6.9 pollici", f"{n:02d}_{name[2:]}.jpg")
        save(compose(phone, 1080, 1920, (l1, l2, sub, accent), head=92, sub=36,
                     radius=0.09, bezel=0.022, island=False, points_w=440, top_ratio=0.055),
             "2 - Google Play (Android)", "Telefono", f"{n:02d}_{name[2:]}.jpg")
    for n, name in enumerate(TABLET, 1):
        _, l1, l2, sub, accent = by_name[name]
        tablet = Image.open(os.path.join(RAW, f"ipad_{name}.png"))
        save(compose(tablet, 2064, 2752, (l1, l2, sub, accent), head=150, sub=58,
                     radius=0.03, bezel=0.014, island=False, points_w=1032, top_ratio=0.055, side=0.1),
             "1 - Apple App Store (iPhone e iPad)", "Tablet - iPad 13 pollici", f"{n:02d}_{name[2:]}.jpg")
        save(compose(tablet, 1536, 2048, (l1, l2, sub, accent), head=112, sub=44,
                     radius=0.03, bezel=0.014, island=False, points_w=1032, top_ratio=0.055, side=0.1),
             "2 - Google Play (Android)", "Tablet", f"{n:02d}_{name[2:]}.jpg")

    for folder, store, size, island, sizes in [
        (ios_widgets, ("1 - Apple App Store (iPhone e iPad)", "Telefono - iPhone 6.9 pollici"), (1320, 2868), True, None),
        (android_widgets, ("2 - Google Play (Android)", "Telefono"), (1080, 1920), False, None),
    ]:
        if not folder:
            continue
        files = sorted(os.listdir(folder))

        def pick(*keys):
            for k in keys:
                for f in files:
                    if k in f:
                        return os.path.join(folder, f)
            raise SystemExit(f"no widget render for {keys} in {folder}")

        rows = [
            [pick("daily_wide", "_daily.png")],
            [pick("01_question", "_quiz.png"), pick("04_streak", "_streak.png")],
            [pick("10_map", "_map.png")],
            [pick("03_level", "_level.png"), pick("05_weakest", "_weakest.png")],
        ]
        screen = home_screen((1320, 2868), rows, (99, 102, 241))
        if store[0].startswith("2 -"):
            screen = screen  # the same widgets, drawn by Android
        n_w = len(PHONE) + 1
        W, H = size
        if store[0].startswith("1 -"):
            save(compose(screen, W, H, WIDGETS, head=128, sub=50, radius=0.125, bezel=0.022,
                         island=True, points_w=440), *store, f"{n_w:02d}_widgets.jpg")
        else:
            save(compose(screen, W, H, WIDGETS, head=92, sub=36, radius=0.09, bezel=0.022,
                         island=False, points_w=440, top_ratio=0.055), *store, f"{n_w:02d}_widgets.jpg")

    # Google Play feature graphic: the name, the promise, and the app.
    W, H = 1024, 500
    fg = background(W, H, (148, 77, 255)).convert("RGBA")
    d = ImageDraw.Draw(fg)
    logo = ImageFont.truetype(os.path.join(FONTS, "Outfit-SemiBold.ttf"), 118)
    lw = int(logo.getlength("IMPROVY"))
    mask = Image.new("L", (lw + 10, 150), 0)
    ImageDraw.Draw(mask).text((0, 0), "IMPROVY", font=logo, fill=255)
    fg.paste(gradient_strip(mask.width, mask.height, BRAND), (64, 120), mask)
    d.text((68, 270), "Know every note by number.", font=font("SemiBold", 40), fill=(255, 255, 255))
    d.text((68, 326), "Scale degrees in all 12 keys.", font=font("Regular", 30), fill=(196, 190, 214))
    phone = Image.open(os.path.join(RAW, "iphone_1_chromatic.png")).convert("RGB").copy()
    status_bar(phone, 1, True, 440)
    body = device(phone, 300, 0.125, 0.022)
    place(fg, body, W - body.width - 70, 70)
    save(fg.convert("RGB"), "2 - Google Play (Android)", "Immagine in evidenza 1024x500.jpg")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Turns AnimalIcon's SVG paths into Android VectorDrawables.

The widget has to draw the same animal the app draws. The app builds each one
from path data in lib/widgets/animal_icon.dart; Android's android:pathData is
the same syntax, so this copies it across rather than anyone redrawing eight
animals by hand and getting seven of them slightly wrong.

    python3 tool/gen_animal_drawables.py

Run it whenever _animalPaths changes. Circles are the one thing that does not
carry over — SVG has a <circle> element and pathData does not — so they are
written out as the two half-arcs that mean the same thing.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'lib/widgets/animal_icon.dart')
OUT = os.path.join(ROOT, 'android/app/src/main/res/drawable')

TEMPLATE = """<?xml version="1.0" encoding="utf-8"?>
<!-- Generated from AnimalIcon\'s own paths (lib/widgets/animal_icon.dart) by
     tool/gen_animal_drawables.py. The widget must draw the same animal the app
     draws, so there is one source and this is a copy of it, not a redrawing.
     Stroked in white and tinted at runtime, like every other shape here. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
{paths}</vector>
"""

PATH = """    <path
        android:pathData="{d}"
        android:strokeColor="#FFFFFFFF"
        android:strokeWidth="2"
        android:strokeLineCap="round"
        android:strokeLineJoin="round" />
"""


def circle_to_path(cx, cy, r):
    cx, cy, r = float(cx), float(cy), float(r)
    return f'M{cx - r} {cy}a{r} {r} 0 1 0 {2 * r} 0a{r} {r} 0 1 0 {-2 * r} 0'


def main():
    src = open(SRC).read()
    block = src[src.index('const Map<String, String> _animalPaths'):]
    entries = re.findall(r"\'(\w+)\':\s*((?:\s*\'(?:[^\'\\\\]|\\\\.)*\'\s*)+),", block)
    for name, literals in entries:
        body = ''.join(re.findall(r"\'((?:[^\'\\\\]|\\\\.)*)\'", literals))
        ds = []
        for m in re.finditer(
                r'<path d="([^"]+)"\s*/>|<circle cx="([^"]+)" cy="([^"]+)" r="([^"]+)"\s*/>',
                body):
            ds.append(m.group(1) if m.group(1)
                      else circle_to_path(m.group(2), m.group(3), m.group(4)))
        assert ds, name
        xml = TEMPLATE.format(
            paths=''.join(PATH.format(d=d.replace('&', '&amp;')) for d in ds))
        open(os.path.join(OUT, f'ic_animal_{name.lower()}.xml'), 'w').write(xml)
    print(f'wrote {len(entries)} animals to {OUT}')


if __name__ == '__main__':
    main()

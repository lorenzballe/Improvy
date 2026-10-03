#!/usr/bin/env python3
"""Turns AnimalIcon's SVG paths into SwiftUI paths for the iOS widgets.

The widgets must draw the animal the app draws — the line art from
lib/widgets/animal_icon.dart — not an emoji. Android gets VectorDrawables from
tool/gen_animal_drawables.py; iOS has no SVG renderer in a widget, so this
writes the same outlines as Path code, arcs turned into cubic curves, into the
generated region of ios/ImprovyWidget/ImprovyKit.swift (kept in that file so
the widget target needs no new source file).

    pip install svgpathtools
    python3 tool/gen_animal_swift.py

Run it whenever _animalPaths changes.
"""
import os
import re

from svgpathtools import Arc, CubicBezier, Line, QuadraticBezier, parse_path

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "lib/widgets/animal_icon.dart")
KIT = os.path.join(ROOT, "ios/ImprovyWidget/ImprovyKit.swift")
BEGIN = "// BEGIN GENERATED ANIMALS (tool/gen_animal_swift.py)"
END = "// END GENERATED ANIMALS"

# Level order, 1-8, as in lib/constants/levels.dart and the Android widget.
ORDER = ["Snail", "Turtle", "Penguin", "Rabbit", "Fox", "Horse", "Falcon", "Cheetah"]


def circle(cx, cy, r):
    cx, cy, r = float(cx), float(cy), float(r)
    return f"M{cx - r} {cy}a{r} {r} 0 1 0 {2 * r} 0a{r} {r} 0 1 0 {-2 * r} 0"


def pt(z):
    return f"CGPoint(x: {z.real:.3f}, y: {z.imag:.3f})"


def swift_for(d):
    out = []
    last = None
    for seg in parse_path(d):
        if last is None or abs(seg.start - last) > 1e-6:
            out.append(f"p.move(to: {pt(seg.start)})")
        if isinstance(seg, Line):
            out.append(f"p.addLine(to: {pt(seg.end)})")
        elif isinstance(seg, CubicBezier):
            out.append(f"p.addCurve(to: {pt(seg.end)}, control1: {pt(seg.control1)}, control2: {pt(seg.control2)})")
        elif isinstance(seg, QuadraticBezier):
            out.append(f"p.addQuadCurve(to: {pt(seg.end)}, control: {pt(seg.control)})")
        elif isinstance(seg, Arc):
            for c in seg.as_cubic_curves():
                out.append(f"p.addCurve(to: {pt(c.end)}, control1: {pt(c.control1)}, control2: {pt(c.control2)})")
        last = seg.end
    if d.strip().lower().endswith("z"):
        out.append("p.closeSubpath()")
    return out


def main():
    src = open(SRC).read()
    block = src[src.index("const Map<String, String> _animalPaths"):]
    entries = dict(re.findall(r"'(\w+)':\s*((?:\s*'(?:[^'\\]|\\.)*'\s*)+),", block))
    funcs = []
    for name in ORDER:
        body = "".join(re.findall(r"'((?:[^'\\]|\\.)*)'", entries[name]))
        lines = []
        for m in re.finditer(r'<path d="([^"]+)"\s*/>|<circle cx="([^"]+)" cy="([^"]+)" r="([^"]+)"\s*/>', body):
            d = m.group(1) if m.group(1) else circle(m.group(2), m.group(3), m.group(4))
            lines += swift_for(d)
        funcs.append((name, lines))

    code = [BEGIN,
            "// Do not edit by hand: regenerate from lib/widgets/animal_icon.dart.",
            "",
            "/// The eight level animals as the app draws them, on a 24 x 24 grid.",
            "enum AnimalArt {",
            "    /// Level 1-8, clamped, so a payload from a newer app never breaks an older widget.",
            "    static func outline(level: Int) -> Path {",
            "        switch min(max(level, 1), 8) {"]
    for i, (name, _) in enumerate(funcs, 1):
        code.append(f"        case {i}: return {name.lower()}()")
    code += ["        default: return snail()", "        }", "    }", ""]
    for name, lines in funcs:
        code.append(f"    private static func {name.lower()}() -> Path {{")
        code.append("        var p = Path()")
        code += ["        " + l for l in lines]
        code.append("        return p")
        code.append("    }")
        code.append("")
    code[-1] = "}"
    code.append(END)
    generated = "\n".join(code)

    kit = open(KIT).read()
    if BEGIN in kit:
        a = kit.index(BEGIN)
        b = kit.index(END) + len(END)
        kit = kit[:a] + generated + kit[b:]
    else:
        kit = kit.rstrip("\n") + "\n\n// MARK: - Level animals\n\n" + generated + "\n"
    open(KIT, "w").write(kit)
    print("wrote", len(funcs), "animals")


if __name__ == "__main__":
    main()

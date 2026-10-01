#!/usr/bin/env bash
# Renders the real widget views on a booted iOS simulator.
#   ios/WidgetRender/render.sh <payload dir> <out dir>
# Expects a booted simulator (xcrun simctl boot …).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
payload="$1"; out="$2"
work="$(mktemp -d)"
cp "$here/../ImprovyWidget/ImprovyKit.swift" "$here/../ImprovyWidget/ImprovyWidgets.swift" "$here/RenderApp.swift" "$work/"

# Three patches, all outside the widgets' own drawing:
# 1. the widget bundle's @main — this harness has its own;
# 2. containerBackground only draws inside WidgetKit's host; here the same
#    background goes behind the content with iOS 17's 16pt widget margins;
# 3. the quiz provider's entry builder, so the real rotation can be read.
sed -i '' 's/^@main$//' "$work/ImprovyWidgets.swift"
sed -i '' 's/self.containerBackground(for: .widget) { background() }/self.padding(16).background(background())/' "$work/ImprovyKit.swift"
sed -i '' 's/private func entry(for date: Date)/func entry(for date: Date)/' "$work/ImprovyWidgets.swift"
grep -q 'self.padding(16).background(background())' "$work/ImprovyKit.swift"

app="$work/Render.app"
mkdir -p "$app"
cp "$here/Info.plist" "$app/"
cp "$payload"/*.json "$app/"
arch="$(uname -m)"
xcrun --sdk iphonesimulator swiftc -parse-as-library -O \
  -target "$arch-apple-ios17.0-simulator" \
  "$work/ImprovyKit.swift" "$work/ImprovyWidgets.swift" "$work/RenderApp.swift" \
  -o "$app/Render"
codesign -s - --force "$app"

xcrun simctl install booted "$app"
xcrun simctl launch --console-pty --terminate-running-process booted com.improvy.widgetrender | tee "$work/log.txt" || true
grep -q "RENDER DONE" "$work/log.txt"
data="$(xcrun simctl get_app_container booted com.improvy.widgetrender data)"
mkdir -p "$out"
cp -R "$data/Documents/." "$out/"
ls -R "$out"

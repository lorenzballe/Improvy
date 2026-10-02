#!/usr/bin/env bash
# Installs the debug app and androidTest/WidgetRenderTest on the running
# emulator, runs the test, and pulls the widget PNGs into $1.
set -euo pipefail
out=${1:-out}
mkdir -p "$out"
adb install -r -t build/app/outputs/flutter-apk/app-debug.apk
adb install -r -t build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
adb shell am instrument -w -e class com.improvy.improvy.WidgetRenderTest \
  com.improvy.app.test/androidx.test.runner.AndroidJUnitRunner | tee "$out/instrument.txt"
grep -q "OK (" "$out/instrument.txt"
for f in $(adb shell run-as com.improvy.app ls files/renders | tr -d '\r'); do
  adb exec-out run-as com.improvy.app cat "files/renders/$f" > "$out/$f"
done
ls -la "$out"

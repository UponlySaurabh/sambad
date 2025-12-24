#!/usr/bin/env bash
set -euo pipefail

SIM_NAME="${1:-iPhone 14}"
echo "[run_ios] Simulator name: $SIM_NAME"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found. Ensure Xcode and command-line tools are installed." >&2
  exit 2
fi

echo "Locating UDID for simulator '$SIM_NAME'..."
UDID=$(xcrun simctl list devices --json | python3 - <<PY
import sys, json
name = "$SIM_NAME"
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('name') == name:
            print(d.get('udid'))
            sys.exit(0)
sys.exit(0)
PY
)

if [ -z "$UDID" ]; then
  echo "Could not find a simulator named '$SIM_NAME'. Run 'xcrun simctl list devices' to see available simulators." >&2
  exit 3
fi

echo "Found UDID: $UDID"

# Boot if not already booted
BOOTED=$(xcrun simctl list devices | grep "$UDID" | grep -i "Booted" || true)
if [ -z "$BOOTED" ]; then
  echo "Booting simulator $SIM_NAME ($UDID)..."
  xcrun simctl boot "$UDID" || true
  open -a Simulator || true
else
  echo "Simulator already booted."
fi

echo "Waiting for device to appear to Flutter..."
timeout=60
elapsed=0
while ! flutter devices | grep -q "$UDID"; do
  sleep 2
  elapsed=$((elapsed+2))
  if [ $elapsed -ge $timeout ]; then
    echo "Timed out waiting for Flutter to detect simulator (waited ${timeout}s)." >&2
    echo "Run 'flutter devices' to inspect available devices." >&2
    exit 4
  fi
done

echo "Device detected by Flutter. Launching app on simulator ($UDID)..."
flutter run -d "$UDID"

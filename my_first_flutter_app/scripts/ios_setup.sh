#!/usr/bin/env bash
set -e

echo "== iOS Setup helper for Private app =="

# Check for Xcode
if xcode-select -p >/dev/null 2>&1; then
  echo "Xcode developer tools found at: $(xcode-select -p)"
else
  echo "Xcode developer tools not found. Please install Xcode from the App Store or https://developer.apple.com/xcode/"
  exit 1
fi

# If Xcode.app exists, try to switch developer dir
if [ -d "/Applications/Xcode.app" ]; then
  echo "Setting Xcode developer directory to /Applications/Xcode.app/Contents/Developer"
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer || true
fi

echo "Running first-launch tasks for Xcode (may require sudo)"
sudo xcodebuild -runFirstLaunch || true

# Check CocoaPods
if command -v pod >/dev/null 2>&1; then
  echo "CocoaPods found: $(pod --version)"
else
  echo "CocoaPods not found. Installing CocoaPods via gem requires sudo."
  echo "You can install now with: sudo gem install cocoapods"
  read -p "Install CocoaPods now? (y/N) " install_pod
  if [[ "$install_pod" == "y" || "$install_pod" == "Y" ]]; then
    sudo gem install cocoapods
  else
    echo "Skipping CocoaPods install. You must install CocoaPods to build iOS plugins."
  fi
fi

# Run pod install in iOS folder
if [ -d "ios" ]; then
  echo "Running pod install in ios/"
  pushd ios >/dev/null
  if [ -f "Podfile" ]; then
    pod install || { echo "pod install failed. Try running 'pod repo update' then 'pod install'"; exit 1; }
  else
    echo "No Podfile found in ios/ - skipping pod install"
  fi
  popd >/dev/null
else
  echo "No ios/ directory found. Are you in the Flutter project root?"
fi

echo "iOS setup script finished. You can now run: open -a Simulator && flutter run -d ios"

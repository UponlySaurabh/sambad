# my_first_flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## iOS setup (macOS)

If you want to run this app on an iOS Simulator you must have Xcode and CocoaPods installed and configured.

Quick steps:

1. Install Xcode from the App Store or from https://developer.apple.com/xcode/
2. After installing Xcode run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

3. Install CocoaPods (if not already installed):

```bash
sudo gem install cocoapods
```

4. From the project root run the helper script (it will run `pod install` for you):

```bash
chmod +x scripts/ios_setup.sh
./scripts/ios_setup.sh
```

5. Start the iOS Simulator and run the app:

```bash
open -a Simulator
# Optionally list and boot a specific simulator
xcrun simctl list devices
xcrun simctl boot "iPhone 14"

flutter pub get
flutter run -d ios
```

Notes:
- The helper script attempts to set the Xcode path and run initial setup. It will prompt before installing CocoaPods.
- If `xcrun simctl` is not available it indicates the Xcode command-line tools are not ready; follow the steps above and re-run the script.

---

## Node OTP server (development)

The project includes a small demo Node.js server at `server_node/` that implements `/send-otp` and `/verify-otp` for local testing.

Run the server locally (on your machine):

```bash
cd server_node
npm install
npm start
```

When running the Android emulator use `http://10.0.2.2:3000` as the host to reach the Node server from the emulator.


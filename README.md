# BuzzIt

BuzzIt is a local-network game buzzer with a Windows/Linux host and one shared
Android buzzer. The Android screen is split into two landscape team buttons.
The first tap is locked immediately, confirmed by the host, announced with a
team sound, and synchronized back to the phone.

![BuzzIt logo](assets/images/buzzit_logo.png)

## Features

- Host-authoritative first-buzz arbitration with numbered rounds.
- One shared Android device with two full-screen team buzzers.
- QR pairing plus manual host IP, port, and six-digit code entry.
- Automatic reconnect and full match-state synchronization.
- Host-controlled manual or 3–10 second automatic reset.
- Team names and colors editable from either app and persisted by the host.
- Built-in original chimes plus imported WAV, MP3, OGG, or M4A sounds.
- Generated Android, Windows, and Linux application artwork.
- Responsive Material 3 UI, haptics, accessible contrast, and restrained motion.

## Requirements

- Flutter 3.44.8 or a compatible newer stable release.
- Android 7.0 (API 24) or newer.
- Windows 10/11 or a Linux desktop with GTK 3 and GStreamer.
- The host and phone must be connected to the same local network.

No account, cloud service, database, or internet connection is required during
a match.

## 🚀 Getting Started (For New Clones)

If you have just cloned the project, follow these steps to get everything running:

1. **Fetch dependencies**:
```bash
flutter pub get
```
2. **Run the host on Linux/Windows**:
```bash
flutter run -d linux
# or
flutter run -d windows
```
3. **Run the buzzer on an Android device**:
```bash
flutter run -d <android-device-id>
```

The shared `lib/main.dart` automatically selects the Android player experience on Android and the Host server experience on Windows or Linux.

## Pair a buzzer

1. Start the desktop host and connect the computer to the intended Wi-Fi or LAN.
2. If the operating system asks, allow BuzzIt on private/local networks.
3. Open BuzzIt on Android.
4. Scan the host QR code, or enter the displayed IP, port, and pairing code.
5. Keep both devices on the same network and begin the round.

If pairing fails, verify that client isolation is disabled on the router and
that the host TCP port is allowed through the desktop firewall. On Windows,
allow the application on **Private networks** rather than disabling the
firewall.

## 📦 Generating Executables & APKs

To build the final production files that you can share with others, use the following commands. 

### Android

```bash
flutter build apk
```
**Where is the file?** ➔ The final APK is located at: `build/app/outputs/flutter-apk/app-release.apk`.

### Linux

Install the Flutter Linux prerequisites and GStreamer development packages, then run:

```bash
flutter build linux
```
**Where is the file?** ➔ The final compiled Linux executable folder is located at: `build/linux/x64/release/bundle/`.

### Windows

*Note: Windows applications must be compiled on an actual Windows machine.*

```powershell
flutter build windows
```
**Where is the file?** ➔ The final compiled Windows folder is located at: `build\windows\x64\runner\Release\`.

## Project structure

```text
lib/
├── app/          # Platform-specific app roots
├── controllers/  # Thin UI coordinators
├── core/         # Global theme and application constants
├── models/       # Match, connection, and protocol state
├── services/     # Audio, network, pairing, and persistence
├── views/        # Host, player, settings, and feature widgets
└── widgets/      # Reusable cross-feature widgets
```

The wire protocol is documented in [docs/PROTOCOL.md](docs/PROTOCOL.md).

## Network and security model

BuzzIt listens only while the host application is running. A new six-digit code
is generated for every host session and only one buzzer client is accepted.
Messages use unencrypted local WebSockets (`ws://`), so BuzzIt is intended for
trusted home, classroom, office, or event networks—not public or hostile Wi-Fi.

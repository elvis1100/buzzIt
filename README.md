# BuzzIt

BuzzIt is a local-network game buzzer. A Windows or Linux computer hosts the
match, and one shared Android phone displays two portrait team buttons facing
opposite sides of a table. When either team taps, the computer accepts
the first valid buzz, shows the winner on both devices, and controls
when the next round begins.

![BuzzIt logo](assets/images/buzzit_logo.png)

## What you need

| Device | Requirements |
| --- | --- |
| Host computer | Windows 10/11 or Linux with GTK 3 and GStreamer |
| Buzzer | Android 7.0 (API 24) or newer, with a camera for QR pairing |
| Network | Both devices on the same trusted Wi-Fi or local network |

No account, cloud service, or internet connection is needed during a match.
Manual IP, port, and code entry works if the phone has no camera.

## Download builds

The current Android build is available as [BuzzIt-Android.apk](BuzzIt-Android.apk).
It is signed with a development key, so use it for direct testing rather than
as an official app-store release. On the phone, allow installation from your
browser or file manager when Android asks.

The Windows host installer is
[BuzzIt-Windows-Setup.exe](BuzzIt-Windows-Setup.exe). The Linux host build is
[BuzzIt-Linux-x64.tar.gz](BuzzIt-Linux-x64.tar.gz); it contains the executable
**and** its required Flutter libraries and data. All three downloads were
built by the **Build and verify** GitHub Actions workflow. Check Linux
compatibility on your distribution and test both hosts before wider
distribution.

On Linux, extract the archive and run the executable from its bundle:

```bash
tar -xzf BuzzIt-Linux-x64.tar.gz
./bundle/buzzit
```

Linux still needs compatible system GTK 3 and GStreamer libraries. Builds
should be tested on the target devices before wider distribution.

## Run from source

Install [Flutter](https://docs.flutter.dev/get-started/install) 3.44.8 and its
platform toolchains. This project uses Dart 3.12.2 and includes a
`pubspec.lock` for repeatable dependency resolution. Run the commands below
from the repository root.

```bash
flutter pub get
flutter devices
```

Start the host on your desktop:

```bash
flutter run -d linux
# On a Windows development machine, use: flutter run -d windows
```

On Linux, install Flutter's desktop prerequisites plus GTK 3 and GStreamer
development packages. For Ubuntu or Debian, the CI package list is in
[.github/workflows/build.yml](.github/workflows/build.yml). Windows builds
require the Windows Flutter desktop toolchain and must run on Windows.

Connect an Android phone with USB debugging enabled, find its ID in
`flutter devices`, then run:

```bash
flutter run -d <android-device-id>
```

`lib/main.dart` selects the host on Windows/Linux and the buzzer on Android.
The Chrome/web target is not part of this app.

## Play a match

1. Start BuzzIt on the computer. Confirm **Server running** and choose the
   computer's Wi-Fi or Ethernet address if more than one is shown.
2. Open BuzzIt on the Android phone. Scan the host QR code, or enter the shown
   host IP address, port, and six-digit pairing code manually.
3. Place the phone between two teams. Each team taps its half of the screen.
   The host confirms the first valid tap and announces the winner.
4. The host resets the round manually or after the configured 3–10 second
   countdown. The host and phone settings can change team names and colors;
   the host persists those changes.

The host accepts one buzzer connection at a time. A new pairing code is created
for each host session. Custom host sounds can be imported as WAV, MP3, OGG, or
M4A files up to 10 MB. Sound selections take effect when host settings are
saved; Cancel discards the selection.

### If pairing fails

- Confirm both devices are on the same LAN and that the host displays
  **Server running**. If the host cannot listen on its port, choose another
  available port in host settings.
- Allow BuzzIt through the computer firewall on **private/local** networks.
  On Windows, allow the application on Private networks instead of disabling
  the firewall.
- Use the host's private Wi-Fi/Ethernet address (often `192.168.x.x`), not a
  VPN, Docker, or virtual-machine adapter address. Disable router client
  isolation if the devices cannot reach each other.
- If scanning fails, use the IP address, port, and code printed on the host.
  An old code or a code from another host session will not pair.

## Build installable files

These commands build local artifacts. Test the resulting files on the target
platform before sharing them.

| Platform | Command | Output |
| --- | --- | --- |
| Android | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |
| Windows | `flutter build windows --release` on Windows | `build/windows/x64/runner/Release/` |

The Android release build currently uses the **debug signing key** configured
in `android/app/build.gradle.kts`. Set up a private release key before treating
an APK as an official signed release. Never commit the key or its passwords.

For Linux, copy the **entire** release bundle to the target computer, not just
the `buzzit` executable. Launch `buzzit` from inside that bundle. For Windows,
copy the entire Release folder; `BuzzIt.exe` is the application. The optional
Inno Setup script is at `packaging/windows/BuzzIt.iss` and expects a completed
Windows release build. Generated installer output is kept out of source control.

The [GitHub Actions workflow](.github/workflows/build.yml) builds Android,
Linux, and Windows files on their respective runners. On the default `master`
branch, use **Actions → Build and verify → Run workflow**, then select
**update_root_downloads** to commit the three fresh build files to the root
after all jobs pass. This job needs permission to write repository contents and
may be blocked by branch protection. A passing CI build checks compilation and
automated tests; it does not prove camera, sound, firewall, or real LAN behavior
on physical devices.

## Develop and verify

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

The tests cover round arbitration, protocol validation, pairing, connection
lifecycle, persistence, and important buzzer UI behavior. Before distributing
builds, also test QR and manual pairing, disconnect/reconnect, both team sounds,
reset timing, and firewall behavior on a real host and Android phone.

## Code layout

```text
lib/
├── app/          # Platform-specific application roots
├── controllers/  # Match and connection state; UI intent coordination
├── core/         # Shared constants and design tokens
├── models/       # Typed match, settings, and wire data
├── services/     # Network, pairing, audio, and local storage
├── views/        # Host, player, and settings screens with feature widgets
└── widgets/      # Controls shared across features
```

The host is authoritative for the winner, reset, and shared settings. The
phone's immediate button lock is responsive feedback; the host's state wins if
a delayed or duplicate message arrives. See [the wire protocol](docs/PROTOCOL.md)
for message types and round IDs.

## Network and license

BuzzIt uses unencrypted local WebSockets (`ws://`) and a six-digit session
pairing code. Use it on trusted home, classroom, office, or event networks,
not public or hostile Wi-Fi.

The source code, documentation, and generated default tones are released under
the [MIT License](LICENSE). The BuzzIt logo was generated with Gemini from the
maintainer's prompt. The default tones are created by
[`tools/generate_default_sounds.py`](tools/generate_default_sounds.py); no
third-party recordings are bundled in the current app.

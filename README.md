# Drishti-Transit

**Drishti (दृष्टि — "sight")** is an on-device AI that turns a city's public bus fleet into a live, always-on urban sensing grid. Cameras paired with edge AI on each bus continuously watch the road and translate what they see into real-time transit intelligence — no cloud, no dependency on third-party vision APIs.

> Built for the Smart India Hackathon as a working prototype of a national-scale public-transit sensing layer.

## What it does

- **Live incident feed** — potholes, road fractures, faded/invisible sign boards, congestion, pedestrian-risk clusters, and number-plate captures streamed from GPS-tracked buses (`PB-01` … `PB-12`), each with a confidence score and a severity class.
- **Command-centre dock** — three operational views (`Command`, `Edge`, `Insight`) that model how a real command centre would triage a city corridor in real time.
- **Live map** — `flutter_map` bus positions, incident pins with confidence chips, moving vehicle glow halos, geo-heat overlays, and city-grid ripple pulses.
- **Corridor analytics** — per-corridor health scores, congestion series charts, OD (origin–destination) desk counts, and fleet/coverage KPIs.
- **Edge philosophy** — detection runs on-device (edge AI) and only aggregated insights are visualised, keeping the system fast, privacy-preserving, and offline-capable.

## Stack

- **Flutter 3.47 / Dart 3.13** (stable), `Material 3`
- **Routing:** `go_router` with custom `CustomTransitionPage` scene transitions
- **Maps:** `flutter_map` / `latlong2`
- **Charts:** `fl_chart`
- **State:** `provider` (+ `ChangeNotifier` command centre), `ValueNotifier` streams for live telemetry
- **Design system:** bespoke tokens (`Drishti Palette`, `Mo` motion, `AppText`/`monoTxt` typography, glyph set) with a scifi command-centre aesthetic

## Screens

| Route | File | Purpose |
|---|---|---|
| `/` → `/command` | `lib/screens/onboard_screen.dart` | Boot/command centre entry with live fleet feed |
| `/command` | `lib/screens/command_screen.dart` | Live incident feed + map + dock |
| `/edge` | `lib/screens/edge_screen.dart` | Edge-AI device view |
| `/insight` | `lib/screens/analytics_screen.dart` | Corridor analytics, congestion & OD charts |
| `/incident/:id` | `lib/screens/incident_detail_screen.dart` | Per-incident investigation detail |

## Getting started

```bash
flutter pub get
flutter run            # pick your device/emulator
flutter build apk      # Android
flutter test           # widget tests
```

## Releases

`.github/workflows/release.yml` builds the Android release APK and iOS IPA and publishes them as a GitHub Release. It runs when you push a tag (`v*`) or on manual dispatch from the **Actions** tab.

**iOS signing (optional):** add the repo secrets `CERTIFICATE_BASE64`, `CERTIFICATE_PASSWORD`, `IOS_DISTRIBUTION_PROFILE_BASE64` and set `SIGN_IOS == 'true'`; otherwise the workflow exports an unsigned IPA (`--no-codesign`), which is fine for demo/test-flight artifacts but not App Store distribution.

## Project layout

```
lib/
  app/            app-wide bootstrapping & app widget
  core/           palette, motion, typography, glyphs, chrome
  core/services/  fleet & detection telemetry simulators
  core/state/     command centre (ChangeNotifier)
  engine/         procedural street-scene renderer
  router/         go_router config + custom scene transitions
  screens/        command, edge, analytics, incident detail
  widgets/        map overlays, dock, shared UI
```

*Prototype source for the Smart India Hackathon. Drishti-Transit.*

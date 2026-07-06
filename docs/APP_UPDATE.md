# Force & Optional App Update

This document describes the end-to-end flow for splash-gated app updates. Configuration lives in Firestore (`settings/appConfig`) so you can change update behavior without shipping a new build.

## Overview

On every cold start, the splash screen:

1. Waits for the splash animation (~2.8s).
2. Fetches version config from Firestore (5s timeout).
3. Compares the running app version (`package_info_plus`) against `latestVersion`.
4. Shows a dialog if an update is available, or continues into the app.

**Fail-open policy:** If Firestore is unreachable, times out, or parsing fails, the app continues normally. Users are never locked out by transient errors.

## Architecture

```
Firestore (settings/appConfig)
        │
        ▼
SettingsRepository.checkAppVersion()
        │  reads PackageInfo + Firestore config
        │  uses VersionUtils for semver compare
        ▼
appUpdateCheckProvider (Riverpod FutureProvider, 5s timeout)
        │  returns null on any error → fail open
        ▼
SplashPage._navigate()
        │  decides: block / show optional dialog / continue
        ▼
showUpdateDialog() → url_launcher → Play Store
```

### File map

| File | Role |
|------|------|
| `lib/core/utils/version_utils.dart` | Segment-wise semver comparison |
| `lib/data/models/app_settings_model.dart` | Firestore config model (`latestVersion`, `forceUpdate`, `releaseNotes`, `storeUrl`) |
| `lib/data/models/app_update_status.dart` | Result object passed from repository → UI |
| `lib/data/repositories/settings_repository.dart` | Fetches config, compares versions, builds `AppUpdateStatus` |
| `lib/presentation/providers/app_update_provider.dart` | Riverpod provider with timeout + fail-open |
| `lib/presentation/widgets/common/update_dialog.dart` | Force (blocking) and optional (skippable) dialogs |
| `lib/presentation/pages/splash/splash_page.dart` | Entry point — gates navigation before home/onboarding/login |
| `lib/core/constants/app_constants.dart` | `defaultPlayStoreUrl` fallback when Firestore `storeUrl` is empty |

## End-to-end flow

```mermaid
flowchart TD
  A[App cold start] --> B[SplashPage shown]
  B --> C[Wait 2800ms animation]
  C --> D[appUpdateCheckProvider]
  D --> E{Firestore fetch OK?}
  E -->|No / timeout| F[Continue to app — fail open]
  E -->|Yes| G{current < latestVersion?}
  G -->|No| F
  G -->|Yes| H{forceUpdate?}
  H -->|Yes| I[Blocking dialog — Update only]
  H -->|No| J[Optional dialog — Update + Later]
  I --> K[User taps Update → Play Store]
  J -->|Later| F
  J -->|Update| K
  F --> L{Auth state}
  L -->|Logged in| M[/home]
  L -->|Onboarding incomplete| N[/onboarding]
  L -->|Otherwise| O[/login]
```

### Step-by-step

1. **Splash delay** — `SplashPage._navigate()` waits 2.8 seconds so branding animation finishes.

2. **Update check** — `ref.read(appUpdateCheckProvider.future)` runs once per cold start:
   - Calls `SettingsRepository.checkAppVersion()`.
   - Wrapped in a 5-second timeout.
   - On any exception → returns `null` (treated as "no update").

3. **Version comparison** — `SettingsRepository`:
   - Reads `PackageInfo.fromPlatform().version` (e.g. `1.0.0` from `pubspec.yaml`).
   - Reads `settings/appConfig` from Firestore.
   - Uses `VersionUtils.isUpdateAvailable(current, latest)` — **not** string equality.
   - Resolves `storeUrl` from Firestore, or falls back to `AppConstants.defaultPlayStoreUrl`.

4. **Routing decision** — `SplashPage`:
   - `updateStatus == null` → continue (fail open).
   - `updateAvailable == false` → continue.
   - `forceUpdate == true` → show blocking dialog, **do not navigate**.
   - Optional update → show dialog; continue only if user taps **Later**.

5. **Dialog** — `showUpdateDialog()`:
   - **Force:** `PopScope(canPop: false)`, `barrierDismissible: false`, single **Update** button.
   - **Optional:** dismissible, **Update** + **Later** buttons.
   - **Update** opens `storeUrl` via `url_launcher` (`LaunchMode.externalApplication`).

6. **Normal routing** — `_continueNavigation()` uses existing auth/onboarding logic.

## Firestore configuration

Document path: `settings/appConfig`

```json
{
  "latestVersion": "1.1.0",
  "forceUpdate": false,
  "releaseNotes": "Bug fixes and a faster redeem flow.",
  "storeUrl": "https://play.google.com/store/apps/details?id=com.nawaz.ff.ff_redeem_code"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `latestVersion` | string | Minimum version considered "up to date". Use semver: `major.minor.patch`. |
| `forceUpdate` | boolean | When `true` **and** the user is outdated, show a blocking dialog. |
| `releaseNotes` | string | Shown in the update dialog. Optional. |
| `storeUrl` | string | Play Store link opened by **Update**. Falls back to `AppConstants.defaultPlayStoreUrl` if empty. |

Changes take effect on the user's **next app launch** — no new APK required to change messaging or gating.

### Common scenarios

| Goal | Firestore values |
|------|------------------|
| No prompt | `latestVersion` ≤ current app version (e.g. `1.0.0`) |
| Soft nudge | `latestVersion: "1.1.0"`, `forceUpdate: false` |
| Hard block old builds | `latestVersion: "1.1.0"`, `forceUpdate: true` |
| Emergency unblock | Set `forceUpdate: false` or lower `latestVersion` |

## Version comparison

Implemented in `VersionUtils` (no `pub_semver` dependency).

Rules:

- Split on `.` (e.g. `1.2.10` → `[1, 2, 10]`).
- Strip leading `v` / `V`.
- Ignore build metadata after `+` (e.g. `1.0.0+42` → `1.0.0`).
- Pad missing segments with `0` (`1.2` equals `1.2.0`).
- Non-numeric segments parse as `0`.

Examples:

| Current | Latest | Update? |
|---------|--------|---------|
| `1.0.0` | `1.1.0` | Yes |
| `1.2.9` | `1.2.10` | Yes (string compare would wrongly say no) |
| `1.2.0` | `1.2` | No |
| `2.0.0` | `1.9.9` | No |

The running version comes from `pubspec.yaml` (`version: 1.0.0+1` → `1.0.0`).

## Error handling

| Condition | Behavior |
|-----------|----------|
| Offline / Firestore error | `appUpdateCheckProvider` → `null` → app continues |
| 5s timeout | Same — fail open |
| Missing `appConfig` doc | `AppSettingsModel.defaults()` — no update unless defaults say otherwise |
| Empty `storeUrl` | Uses `AppConstants.defaultPlayStoreUrl` |
| User on latest version | `updateAvailable: false` — no dialog |

Only an explicit **outdated version + `forceUpdate: true`** blocks entry to the app.

## Testing locally

1. Note current version in `pubspec.yaml` (e.g. `1.0.0`).
2. In Firebase Console → Firestore → `settings/appConfig`:
   - Set `latestVersion` to `1.1.0`.
   - Set `forceUpdate` to `false` for optional, `true` for force.
   - Add `releaseNotes` for dialog copy.
3. Cold restart the app (kill and relaunch).
4. Optional: set `latestVersion` back to `1.0.0` to confirm the dialog disappears.

## Dependencies

All already in `pubspec.yaml` — no new packages:

- `package_info_plus` — current app version
- `url_launcher` — open Play Store
- `cloud_firestore` — remote config
- `flutter_riverpod` — provider layer

## Future extensions (not implemented)

- Separate iOS App Store URL
- Caching last-known config in `SharedPreferences` for offline resilience
- In-app update API (Play Core) instead of store redirect
- Maintenance mode gate on splash (separate from version check)

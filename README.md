# Game redeem Code

A complete Flutter application for earning coins through games, ads, and referrals, and redeeming them for Free Fire diamonds or Google Play redeem codes.

## Features

- **Authentication**: Device ID-based registration ensuring one account per device.
- **Earn Coins**:
  - Daily Login Rewards
  - Scratch Cards
  - Spin the Wheel
  - Watch Video Ads
  - Referral System
- **Redeem**: Exchange earned coins for game currencies or gift cards.
- **Admin Panel**: Manage users, approve/reject withdrawals, manage redeem codes, and broadcast push notifications.
- **Architecture**: Built using Clean Architecture and SOLID principles.
- **State Management**: Riverpod for predictable and scalable state.

## Folder Structure (Layer-Based)

```text
lib/
├── core/
│   ├── animations/     # Reusable animation widgets
│   ├── constants/      # App config and constants
│   ├── errors/         # Custom exceptions
│   ├── extensions/     # Dart extensions for Date, String, BuildContext
│   ├── routes/         # GoRouter configuration
│   ├── services/       # Firebase, Ads, Network, Notifications
│   ├── theme/          # App colors and themes
│   └── utils/          # Helpers and formatters
├── data/
│   ├── models/         # Firestore data models
│   └── repositories/   # Firebase interaction layer
├── presentation/
│   ├── pages/          # UI Screens (auth, home, admin, games, settings)
│   ├── providers/      # Riverpod state notifiers
│   └── widgets/        # Reusable UI components
└── main.dart
```

## Setup Instructions

1. **Firebase Configuration**:
   - The app uses `firebase_options.dart` generated via FlutterFire CLI.
   - Configure Firebase Authentication (Anonymous or Email/Password if enabled later).
   - Set up Firestore Database using the provided `firestore.rules`.
   - Set up Firebase Cloud Messaging for Push Notifications.
   - Enable Firebase App Check for security (Play Integrity).

2. **AdMob Configuration**:
   - Update the `APPLICATION_ID` in `android/app/src/main/AndroidManifest.xml` with your real AdMob App ID for production.
   - Update the Ad Unit IDs in `lib/core/constants/app_constants.dart`.

3. **Running the App**:
   ```bash
   flutter pub get
   flutter run
   ```

## Admin Access
To make a user an admin, manually update their document in the `users` Firestore collection: set the `isAdmin` field to `true`.

## Security & Rules
- All coin operations use `firestore.runTransaction` for concurrency safety.
- Daily limits are enforced locally and verified server-side.
- The `firestore.rules` file contains strict permissions to prevent unauthorized writes or coin manipulation.

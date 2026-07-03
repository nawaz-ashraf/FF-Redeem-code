# FF Redeem Code - Setup Guide

## Prerequisites
- Flutter SDK (installed)
- Firebase account
- Google AdMob account
- Android Studio / VS Code

## 1. Firebase Setup

### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named **"FF Redeem Code"**
3. Enable Analytics

### Enable Services
In Firebase Console, enable:
- **Authentication** → Email/Password sign-in
- **Cloud Firestore** → Start in production mode
- **Firebase Storage** → For profile pictures
- **Cloud Messaging** → For push notifications
- **Analytics** → Already enabled
- **Crashlytics** → Enable crash reporting
- **Remote Config** → For dynamic settings
- **App Check** → Enable with Play Integrity (Android) / DeviceCheck (iOS)

### Connect Flutter App
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (generates firebase_options.dart)
flutterfire configure

# Select your Firebase project when prompted
```

> This automatically generates `lib/firebase_options.dart` with correct credentials.

## 2. Firestore Setup

### Deploy Security Rules
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize (select Firestore)
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

### Create Initial Collections
In Firestore Console, create:
- `users` (empty - auto-created on register)
- `settings/announcements` → Add field `active: false`
- `redeemCodes` (empty - admin adds codes)

### Create Admin User
After registering normally, go to Firestore → `users` → find your user document → Set `isAdmin: true`

## 3. AdMob Setup

1. Go to [AdMob Console](https://admob.google.com/)
2. Create app for Android and iOS
3. Create Rewarded Ad unit
4. Replace test IDs in `lib/core/constants/app_constants.dart`:
   ```dart
   static const String admobRewardedAdId = 'ca-app-pub-XXXXX/XXXXX';
   ```
5. Update `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-YOUR_REAL_APP_ID"/>
   ```

## 4. Run the App

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## 5. Firebase Cloud Messaging (FCM)

### Android
The FCM service is already configured in `AndroidManifest.xml`.

### iOS
1. Upload APNs key in Firebase Console
2. Add `GoogleService-Info.plist` to `ios/Runner/`

## 6. Firestore Indexes

Create composite indexes in Firebase Console:
- `transactions`: `userId` ASC, `createdAt` DESC
- `withdrawals`: `userId` ASC, `createdAt` DESC  
- `withdrawals`: `status` ASC, `createdAt` DESC
- `adRewards`: `userId` ASC, `createdAt` DESC

## Architecture Overview

```
lib/
├── core/
│   ├── constants/      # App-wide constants
│   ├── errors/         # Custom exceptions
│   ├── services/       # Firebase, Router, AdMob
│   ├── theme/          # Dark gaming theme
│   └── utils/          # Helper functions
├── data/
│   ├── models/         # Firestore models
│   └── repositories/   # Data access layer
└── presentation/
    ├── pages/          # All screens
    ├── providers/      # Riverpod state management
    └── widgets/        # Reusable UI components
```

## Key Features

| Feature | Implementation |
|---------|---------------|
| Auth | Firebase Auth (Email/Password) |
| Data | Cloud Firestore (real-time) |
| State | Riverpod |
| Navigation | GoRouter with auth guard |
| Ads | Google Mobile Ads (Rewarded) |
| Notifications | Firebase Cloud Messaging |
| Storage | Firebase Storage |
| Analytics | Firebase Analytics |
| Crash Reporting | Firebase Crashlytics |

## Security

- One FF UID per account
- One device per account
- Firestore rules enforce ownership
- Firebase App Check prevents abuse
- Admin-only withdrawal approval
- Ban detection and enforcement

## Legal Compliance

- App never promises "unlimited diamonds"
- All reward screens show "subject to availability"
- Privacy Policy and Terms of Service links
- User data deletion option in profile

---

> Built with ❤️ for FF players

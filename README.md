# CampusBusAI 360

**Tagline:** Track • Predict • Protect

CampusBusAI 360 is a Flutter Web prototype for college bus tracking and safety. It currently includes student, parent, and driver-facing screens, Firebase Authentication integration, a Firestore profile/driver-request flow, and a map demo using Flutter Map.

## Project structure

```text
campus_bus_ai/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── services/
│   │   └── auth_service.dart
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   ├── driver_registration_screen.dart
│       │   └── role_dashboard_screen.dart
│       ├── student/
│       │   ├── student_dashboard.dart
│       │   ├── student_feature_screen.dart
│       │   └── google_map_tracking.dart
│       ├── parent/
│       │   └── parent_dashboard.dart
│       └── driver/
│           └── driver_dashboard.dart
├── test/
├── web/
├── firestore.rules
├── firebase.json
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml`
- Chrome (for running the web prototype)
- A Firebase project with Email/Password Authentication enabled and Cloud Firestore created

## Run locally

From this folder (the folder containing `pubspec.yaml`):

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

The project uses Firebase options in `lib/firebase_options.dart`. These are client-side Firebase configuration values, not a substitute for database security. Confirm the configuration points to the Firebase project you intend to use.

## Firebase setup and security

1. In Firebase Console, enable **Authentication → Email/Password**.
2. Create a Cloud Firestore database.
3. Review `firestore.rules` and deploy them from Firebase Console or with the Firebase CLI.
4. Public registration is limited to Student and Parent profiles. Driver registration submits a **pending request**; it does not grant the driver role. Admin role assignment must be performed through a trusted, authenticated administrative workflow.
5. The rules in this repository are starter rules for the user profile and driver request flows. They do not yet authorize bus, trip, live location, attendance, or SOS collections. Add narrowly scoped rules before enabling those features with real data.
6. Never commit service-account private keys, passwords, `.env` files, or other private credentials. Keep Firestore rules restrictive.

## Current prototype limitations

- Bus positions, ETAs, attendance, and some dashboard content may still use demo/sample data.
- Parent and driver screens are prototypes; confirm which actions are connected to Firebase before relying on them.
- The web Firebase configuration is for the configured Firebase project. Re-run FlutterFire configuration if using a different project or adding platforms.

## GitHub collaboration workflow

Use feature branches instead of committing directly to `main`.

```bash
git switch main
git pull origin main
git switch -c feature/your-feature
# make and test changes
git add .
git commit -m "Describe your change"
git push -u origin feature/your-feature
```

Then open a Pull Request on GitHub, review the changes, and merge into `main` only after checking the diff and tests.

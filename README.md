# Divine Arc

A Flutter application with Firebase integration, supporting multiple authentication methods including Google Sign-In, Apple Sign-In, and Facebook Login.

## Features

- 🔐 **Multi-platform Authentication**
  - Email/Password authentication
  - Google Sign-In
  - Facebook Login
  - OTP verification
  - Forgot Password & Reset Password flows

- 🔔 **Push Notifications**
  - Firebase Cloud Messaging integration
  - Local notifications support

- 🌍 **Internationalization**
  - Multi-language support (English & Hindi)
  - Localization using flutter_localization

- 🎨 **Modern UI/UX**
  - Material Design 3
  - Custom fonts (Warnes, DM Sans)
  - Loading animations
  - Toast notifications

## Prerequisites

- Flutter SDK (^3.7.2)
- Dart SDK
- Xcode (for iOS development)
- Android Studio (for Android development)
- CocoaPods (for iOS dependencies)
- Firebase project setup

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd divinearc-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

This project uses Firebase for authentication and messaging. The Firebase configuration is already set up in:

- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Android**: `android/app/google-services.json`
- **Flutter**: `lib/firebase_options.dart`

The `firebase_options.dart` file contains platform-specific Firebase configuration and is automatically used during initialization.

### 4. iOS Setup

#### Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

#### Configure Info.plist

The `ios/Runner/Info.plist` file is already configured with:
- Facebook App ID and URL schemes
- Google Sign-In URL schemes
- Required permissions (camera, microphone, photo library, notifications)

### 5. Android Setup

The Android configuration is already set up in:
- `android/app/build.gradle.kts` - Contains Firebase and Google Services plugin
- `android/app/google-services.json` - Firebase configuration
- `android/app/src/main/res/values/strings.xml` - Facebook App ID

## Running the Application

### iOS

```bash
flutter run
```

Or from the iOS directory:

```bash
cd ios
flutter run
```

### Android

```bash
flutter run
```

## Project Structure

```
lib/
├── APIs/
│   └── AuthFlow/          # Authentication BLoC
├── Screens/               # UI screens
├── Utils/                 # Utilities and helpers
│   ├── app_imports.dart   # Common imports
│   └── notification_service.dart
├── l10n/                  # Localization files
├── firebase_options.dart  # Firebase configuration
└── main.dart             # Application entry point
```

## Firebase Configuration Details

### Project Information
- **Project ID**: geetagpt-50aba
- **Storage Bucket**: geetagpt-50aba.firebasestorage.app
- **Messaging Sender ID**: 1072160672117

### iOS Configuration
- **Bundle ID**: com.divinearc.app
- **App ID**: 1:1072160672117:ios:23f77eda4c0fc43c442b3c

### Android Configuration
- **Package Name**: com.divinearc.app
- **App ID**: 1:1072160672117:android:fe2d731e62be2294442b3c

## Troubleshooting

### Firebase Initialization Error

If you encounter the error:
```
[core/not-initialized] Firebase has not been correctly initialized
```

**Solution**: Ensure that `lib/firebase_options.dart` exists and `main.dart` imports it:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### iOS Pod Installation Issues

If you encounter CocoaPods issues:

```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Hot Restart After Configuration Changes

After making configuration changes, perform a hot restart:
- Press `R` (capital R) in the Flutter terminal
- Or stop and restart: `flutter run`

## Dependencies

### Core Dependencies
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `firebase_messaging` - Push notifications
- `flutter_local_notifications` - Local notifications

### Authentication
- `google_sign_in` - Google Sign-In
- `sign_in_with_apple` - Apple Sign-In
- `flutter_facebook_auth` - Facebook Login

### State Management
- `flutter_bloc` - BLoC pattern implementation
- `provider` - State management

### UI & Utilities
- `fluttertoast` - Toast notifications
- `loading_animation_widget` - Loading animations
- `flutter_localization` - Internationalization
- `connectivity_plus` - Network connectivity
- `shared_preferences` - Local storage
- `permission_handler` - Runtime permissions

### Media & Audio
- `image_picker` - Image selection
- `record` - Audio recording
- `just_audio` - Audio playback
- `flutter_sound` - Audio recording/playback
- `audioplayers` - Audio player

### Other
- `url_launcher` - URL handling
- `flutter_svg` - SVG support
- `share_plus` - Share functionality
- `flutter_markdown` - Markdown rendering

## Version

Current version: **1.0.0+4**

## License

[Add your license information here]

## Support

For issues and questions, please [create an issue](link-to-issues) in the repository.

# MoodEats Mobile Application (Flutter)

Cross-platform mobile client for MoodEats (iOS & Android) delivering real-time sentiment-based culinary discovery and conversational commerce.

## Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version >= 3.22.0)
- Android Studio / Xcode for device emulation and compilation toolchains.

## Environment Configuration
Ensure the `.env` file exists in this directory (copied from `.env.example` or `.env.local`):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
ADK_AGENT_BASE_URL=http://10.0.2.2:8080   # 10.0.2.2 for Android Emulator
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
FIREBASE_API_KEY=your_firebase_api_key_here
FIREBASE_PROJECT_ID=your-project-id
```

## Running the Application
1. Download package dependencies:
   ```bash
   flutter pub get
   ```
2. Run on connected physical device or emulator:
   ```bash
   flutter run
   ```
3. Or compile a standalone debug APK:
   ```bash
   flutter build apk --debug
   ```

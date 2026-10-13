# MoodEats Mobile Application (Flutter)

Aplikasi mobile MoodEats berbasis Flutter (iOS & Android) untuk penemuan kuliner berbasis sentimen emosional pengguna secara real-time.

## Prasyarat Lingkungan
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi >= 3.2.0)
- Android Studio / Xcode untuk emulator dan toolchain kompilasi.

## Konfigurasi Environment
Pastikan file `.env` di folder ini sudah ada (disalin dari `.env.example` atau `.env.local`):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
ADK_AGENT_BASE_URL=http://10.0.2.2:8080   # 10.0.2.2 untuk emulator Android
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
FIREBASE_API_KEY=your_firebase_api_key_here
FIREBASE_PROJECT_ID=your_firebase_project_id
```

## Menjalankan Aplikasi
1. Download package dependencies:
   ```bash
   flutter pub get
   ```
2. Jalankan aplikasi pada simulator/perangkat fisik:
   ```bash
   flutter run
   ```

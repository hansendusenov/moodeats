# 🍲 MoodEats — Autonomous Hyperlocal Sentiment Commerce & Culinary Discovery Engine

> **AI Builder Cup 2026 Submission**  
> *Track: Retail & Commerce: Intelligent Customer and Business Experiences*

MoodEats adalah platform *hyperlocal conversational commerce* berbasis AI yang mentransformasi luapan emosi dan suasana hati (*mood*) pengguna menjadi keputusan transaksi kuliner fisik secara *real-time*. Platform ini memadukan **Gemini Flash Reasoning**, sistem kurasi tempat makan hibrida (**Google Places API + Overpass OpenStreetMap**), gamifikasi interaktif (**Bite Roulette**), voucher dinamis berbatas waktu, serta sistem **Smart Offline Cache** yang menjamin pengalaman pengguna tetap mulus tanpa terputus.

---

## 🏛️ Arsitektur Sistem

MoodEats dibangun dengan arsitektur modular yang memisahkan client mobile, AI agent reasoning engine, backoffice web admin, dan cloud database:

```
┌─────────────────────────────────┐      ┌──────────────────────────────────┐      ┌─────────────────────────────────┐
│          flutter_app/           │      │            adk_agent/            │      │           web_admin/            │
│       Flutter 3.x (Dart)        │      │   FastAPI + Google GenAI SDK     │      │     CodeIgniter 4 (PHP 8.2+)    │
│  - Multimodal STT & Camera      │      │  - Gemini Flash Sentiment Agent  │      │  - Live Telemetry & Analytics   │
│  - Bite Roulette (Bilingual)    │◄────►│  - Hybrid Places Resolver        │◄────►│  - Time-Parting Banner Geofence │
│  - Smart Offline Cache Layer    │      │  - History & Telemetry Logger    │      │  - User Ban & Voucher Injection │
│  - Dynamic Voucher Countdown    │      │  - Multi-Turn Context & Replay   │      │  - Curated Comfort Food Manager │
└────────────────┬────────────────┘      └────────────────┬─────────────────┘      └────────────────┬────────────────┘
                 │                                        │                                         │
                 └───────────────────┬────────────────────┴─────────────────────────────────────────┘
                                     │
                           ┌─────────▼─────────┐
                           │     Supabase      │
                           │ (PostgreSQL 15+)  │
                           │  - 11 Tables      │
                           │  - Realtime & RLS │
                           └───────────────────┘
```

### Rincian Sub-sistem:

| Modul | Stack Teknologi | Port / Endpoint | Tanggung Jawab & Fitur Utama |
|:---|:---|:---|:---|
| **`flutter_app/`** | Flutter 3.x (Dart), Riverpod, Material 3 | Android / iOS / Web | Mobile client responsif, OS STT, Kamera Multimodal, GPS, Countdown Voucher `1D : HH:MM:SS`, Cache Offline Dual Memory-Disk, Bouncy Micro-animations, Dukungan multi-bahasa (ID/EN). |
| **`adk_agent/`** | Python 3.13, FastAPI, Google GenAI SDK | `http://localhost:8080` | Engine AI penalaran sentimen, ekstraksi mood, hybrid resolver (Google Places + Overpass OSM), logging telemetri perangkat, filter jam operasional (`only_open_now`). |
| **`web_admin/`** | CodeIgniter 4, PHP 8.2, Bootstrap 5, Chart.js | `http://localhost:8081` | Dashboard analitik sentimen AI live, telemetri mobile (OS, versi aplikasi), manajemen pengguna (ban/unban status), injeksi voucher instan ke dompet user, manajemen banner geofence. |
| **`database/`** | PostgreSQL 15 (Supabase) | Cloud Hosted | DDL 11 tabel relasional: pengguna, sesi percakapan, preferensi diet, merchant, voucher terbitan, riwayat klaim, analitik sentimen, banner promo, dan menu kurasi. |

---

## ✨ Fitur-Fitur Utama Terkini

### 1. 🧠 Autonomous Sentiment Reasoning & Multimodal Input
- **Curhat Bebas Bahasa Alami**: AI membedah emosi kompleks (stres kerja, lelah lembur, selebrasi, patah hati) menjadi kebutuhan gizi dan rasa kuliner (*comfort food, kuah hangat, pedas melek, manis penenang*).
- **Speech-to-Text (STT) Terintegrasi**: Perekaman suara langsung dari sistem operasi dilengkapi rekomendasi curhat cepat (*Quick Voice Suggestions*).
- **Kamera Multimodal**: Analisis foto makanan atau menu fisik secara instan menggunakan visi multimodal Gemini.
- **Filter Jam Operasional ("Buka Sekarang")**: Toggle pintar untuk hanya menampilkan tempat kuliner yang saat ini berstatus buka (*open now*).
- **Preferensi Makanan & Alergi**: Pengaturan Wajib Halal, Vegan, Vegetarian, Bebas Gluten, serta daftar pantangan alergi yang secara ketat dihormati oleh AI.

### 2. 📶 Sistem Smart Offline & Persistent Device Cache
- **Dual Layer Cache (In-Memory + File Storage)**: Menyimpan salinan data JSON di storage aplikasi (`app_flutter/moodeats_cache_*.json`) dan RAM untuk kecepatan instan.
- **Ketahanan Jaringan Penuh**: Jika server mati, koneksi timeout, atau kuota Gemini API habis (*429 RESOURCE_EXHAUSTED*), aplikasi **tidak pernah blank atau crash**.
- **Fitur yang Tersedia Offline**:
  - Banner promo kurasi lokal.
  - Daftar Comfort Food pilihan lengkap dengan harga & foto.
  - Roda **Bite Roulette** tetap dapat berputar dan memilih menu.
  - Riwayat sesi pencarian sebelumnya.
  - Voucher aktif yang tersimpan.
- **Badge Mode Offline Cerdas**: Indikator transparan `[📶 Mode Offline Cerdas: Server tidak dapat dihubungi, menampilkan rekomendasi tersimpan dari cache perangkat]` memberitahu pengguna tanpa merusak alur aplikasi.

### 3. 🎲 Bite Roulette (Gamifikasi Penuntas Bingung Makan)
- **Wheel Physics Deceleration**: Animasi putaran roda keberuntungan yang realistis dengan perlambatan kurva mulus.
- **Sepenuhnya Bilingual (ID / EN)**: Pergantian bahasa aplikasi langsung mengubah nama hidangan dan deskripsi manfaat mood pada roda roulette secara real-time.
- **Direct Search Shortcut**: Tombol "Cari Tempat Kuliner Ini Sekarang" langsung menghubungkan hasil roulette ke daftar restoran terdekat tanpa perlu mengetik ulang.

### 4. 📜 Riwayat Sesi Pintar & Zero-Token Recommendation Replay
- **Filter Hari Ini (Today-Only Default)**: Riwayat memprioritaskan pencarian hari ini agar pengguna tidak kewalahan melihat daftar panjang.
- **Date Range Picker & View All**: Memungkinkan pengguna memeriksa riwayat sesi kuliner pada rentang tanggal spesifik.
- **Lazy Loading Pagination**: Optimasi pemuatan data dengan batasan 10 sesi per request dan indikator loading yang mulus.
- **AI-Free Instant Replay**: Membuka kembali detail rekomendasi sesi sebelumnya secara instan dari cache lokal tanpa memanggil ulang Gemini AI (menghemat kuota & token 100%).

### 5. 🎟️ Dynamic Voucher Engine & Countdown Timer
- **Format Countdown Presisi**: Tampilan durasi hitung mundur dinamis dalam format `1D : 23:59:59` untuk voucher jangka panjang dan `MM:SS` untuk voucher *flash dine-in*.
- **Letak Voucher Terpadu**: Terpasang di banner Beranda dan kartu mengambang di tab Riwayat.
- **QR Code Kasir Dialog**: Dialog pop-up khusus yang menampilkan kode QR dan barcode untuk dipindai oleh kasir merchant saat transaksi fisik.

### 6. 📊 Web Admin Console & Live Telemetry
- **Telemetry Device Real-Time**: Memantau jenis perangkat pengguna (Model HP, OS Android/iOS, Versi Aplikasi) secara langsung saat request dikirim.
- **Analitik Sentimen AI Live**: Grafik visual dinamika mood harian, kata kunci makanan paling dicari, dan distribusi sentimen pengguna.
- **Injeksi Voucher Langsung**: Admin dapat menginjeksi voucher promo kustom langsung ke akun pengguna tertentu yang otomatis muncul di aplikasi mobile mereka.
- **Manajemen Status Pengguna (Ban/Unban)**: Pengendalian akses pengguna langsung dari dashboard web.

---

## 🚀 Panduan Instalasi & Menjalankan Sistem

### 1. Prasyarat Lingkungan
- **Node.js** (v18+) & **npm**
- **Python** 3.11 atau 3.13+
- **PHP** 8.2+ dengan ekstensi `intl`, `mbstring`, `pdo_pgsql`, `curl` aktif
- **Composer** 2.x
- **Flutter SDK** 3.22+
- **Android Device** atau Emulator dengan USB Debugging aktif

---

### 2. Konfigurasi Environment (`.env`)

Salin file template `.env.example` di masing-masing folder:
```bash
# Root
cp .env.example .env

# Web Admin
cp web_admin/.env.example web_admin/.env

# AI Agent
cp adk_agent/.env.example adk_agent/.env

# Flutter App
cp flutter_app/.env.example flutter_app/.env
```

Isikan variabel penting seperti `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan kredensial database Supabase PostgreSQL.

---

### 3. Menjalankan Database Migration
Jalankan skrip inisialisasi database di database Supabase:
```bash
# Melalui Supabase SQL Editor atau CLI:
psql "postgresql://postgres:<password>@db.tpkchcrwqjrfprdibawz.supabase.co:5432/postgres" -f database/run_all.sql
```

---

### 4. Menjalankan AI Agent (FastAPI Backend)
```bash
cd adk_agent
python -m venv .venv

# Windows:
.venv\Scripts\activate
# Linux/macOS:
# source .venv/bin/activate

pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8080 --reload
```
> Server berjalan di: `http://localhost:8080` (Dokumentasi API Swagger di `http://localhost:8080/docs`)

---

### 5. Menjalankan Web Admin Console (CodeIgniter 4)
```bash
cd web_admin
composer install
php spark serve --port 8081
```
> Console Admin berjalan di: `http://localhost:8081`

---

### 6. Menjalankan Mobile Client (Flutter)
```bash
cd flutter_app
flutter pub get

# Jalankan ke device fisik atau emulator:
flutter run

# Atau compile debug APK:
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📡 Daftar Endpoint Utama API (`adk_agent`)

| Method | Endpoint | Deskripsi |
|:---|:---|:---|
| `POST` | `/api/v1/agent/recommend` | Analisis sentimen, mood-to-food mapping, dan rekomendasi tempat makan via Gemini Flash & Google Places. Menerima telemetri perangkat & filter `only_open_now`. |
| `POST` | `/api/v1/agent/analyze-image` | Analisis gambar multimodal (foto hidangan/struk/menu). |
| `GET` | `/api/v1/banners` | Mengambil daftar banner promo aktif berbasis geofencing kota dan jam tayang. |
| `GET` | `/api/v1/menus/default` | Mengambil daftar menu comfort food kurasi lokal. |
| `GET` | `/api/v1/roulette` | Mengambil item menu acak untuk Bite Roulette (bilingual ID & EN). |
| `GET` | `/api/v1/sessions/history` | Mengambil riwayat sesi rekomendasi dengan pagination (`offset`, `limit`) dan filter rentang tanggal (`start_date`, `end_date`). |
| `POST` | `/api/v1/users/sync` | Sinkronisasi profil pengguna (nama lengkap, tanggal lahir, gender, preferensi diet, dan telemetri perangkat). |
| `GET` | `/api/v1/vouchers/my` | Mengambil daftar voucher aktif milik pengguna. |
| `POST` | `/api/v1/vouchers/claim` | Mengklaim voucher diskon restoran tertentu. |

---

## 📁 Struktur Direktori Repositori

```
mood_eats/
├── README.md                                    # Dokumentasi utama proyek
├── FLOW.md                                      # Diagram alur sistem & user flow lengkap
├── moodeats_master_product_requirement_document.md # Master PRD dokumen resmi
├── database/                                    # SQL Migration & Seeding files
│   ├── run_all.sql
│   ├── 01_tables.sql
│   └── ...
├── adk_agent/                                   # Backend Agentic Reasoning (FastAPI)
│   ├── main.py                                  # Entry point server & route handler
│   ├── agent/
│   │   ├── moodeats_agent.py                    # Gemini reasoning logic & tool caller
│   │   ├── tools/places_resolver.py             # Hybrid Google Places & Overpass OSM
│   │   └── ...
│   └── requirements.txt
├── web_admin/                                   # Backoffice Admin Console (CodeIgniter 4)
│   ├── app/Controllers/                         # Dashboard, Analytics, Users, Vouchers, Banners
│   ├── app/Views/                               # Antarmuka Admin Console
│   └── composer.json
└── flutter_app/                                 # Mobile Application (Flutter)
    ├── lib/
    │   ├── core/constants/ & localization/     # Tema warna & dukungan bahasa ID/EN
    │   ├── data/
    │   │   ├── models/                          # Data model serializable
    │   │   ├── services/
    │   │   │   ├── api_service.dart             # HTTP client dengan auto-caching
    │   │   │   ├── app_cache_service.dart       # Smart Offline dual-storage cache
    │   │   │   └── ...
    │   │   └── providers/app_providers.dart     # Riverpod state management
    │   └── presentation/screens/
    │       ├── home/home_screen.dart            # Beranda utama & OmniSearchBar
    │       ├── roulette/bite_roulette_screen.dart # Gamifikasi Bite Roulette
    │       ├── history/history_screen.dart      # Riwayat & Replay rekomendasi
    │       ├── account/account_screen.dart      # Manajemen profil & bahasa
    │       └── results/results_screen.dart      # Hasil rekomendasi & kartu tempat
    └── pubspec.yaml
```

---

## 📄 Lisensi
Hak Cipta © 2026 Tim MoodEats. Dikembangkan khusus untuk **AI Builder Cup 2026 Submission**.

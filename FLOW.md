# 🔄 MoodEats — Diagram Alur & User Flow Sistem

Dokumen ini mendeskripsikan seluruh alur sistem (*system workflow*) dan alur interaksi pengguna (*user journey*) pada aplikasi **MoodEats**, mulai dari inisialisasi awal, kurasi sentimen berbasis AI, ketahanan offline, gamifikasi, hingga dashboard operasional.

---

## 📑 Daftar Isi Alur

1. [Arsitektur Global & Alur Data End-to-End](#1-arsitektur-global--alur-data-end-to-end)
2. [Alur Inisialisasi Aplikasi & Dual-Storage Cache](#2-alur-inisialisasi-aplikasi--dual-storage-cache)
3. [Alur Curhat Multimodal & Penalaran Sentimen AI (Online vs Offline)](#3-alur-curhat-multimodal--penalaran-sentimen-ai-online-vs-offline)
4. [Alur Gamifikasi Bite Roulette (Bilingual & Direct Search)](#4-alur-gamifikasi-bite-roulette-bilingual--direct-search)
5. [Alur Riwayat Sesi, Lazy Pagination & Zero-Cost Replay](#5-alur-riwayat-sesi-lazy-pagination--zero-cost-replay)
6. [Alur Mesin Voucher Dinamis (Klaim, Injeksi Admin & Countdown 1D : HH:MM:SS)](#6-alur-mesin-voucher-dinamis-klaim-injeksi-admin--countdown-1d--hhmmss)
7. [Alur Telemetri Mobile & Analitik Sentimen Real-Time di Web Admin](#7-alur-telemetri-mobile--analitik-sentimen-real-time-di-web-admin)

---

## 1. Arsitektur Global & Alur Data End-to-End

```mermaid
flowchart TD
    subgraph MobileApp ["📱 Flutter Mobile App"]
        UI_Home["Beranda / OmniSearchBar"]
        UI_Voice["Voice STT / Kamera"]
        UI_Roulette["Bite Roulette Wheel"]
        UI_History["Riwayat & Replay"]
        LocalCache[("AppCacheService<br/>In-Memory + Device Storage")]
    end

    subgraph BackendAgent ["🧠 Python AI Engine (FastAPI :8080)"]
        Router["API Route Handler"]
        GeminiAgent["Google GenAI SDK<br/>(Gemini 2.5 Flash)"]
        PlacesResolver["Hybrid Places Resolver<br/>(Google Places + Overpass OSM)"]
        TelemetryLogger["Session & Telemetry Logger"]
    end

    subgraph CloudDB ["☁️ Supabase PostgreSQL 15"]
        UsersTbl[("users & profiles")]
        SessionsTbl[("sentiment_sessions")]
        VouchersTbl[("vouchers & claims")]
        BannersTbl[("geofenced_banners")]
    end

    subgraph WebAdminConsole ["💻 Web Admin (CodeIgniter 4 :8081)"]
        AdminAuth["RBAC Superadmin / Ops"]
        AnalyticsView["Live Sentiment Analytics"]
        VoucherInjector["User Ban & Voucher Injection"]
        BannerCMS["Time-Parting Banner CMS"]
    end

    %% User Interaction
    UI_Home -->|1. Kirim Prompt / Curhat| Router
    UI_Voice -->|Audio STT / Foto| Router
    UI_Home <-->|Baca / Tulis Cache Lokal| LocalCache

    %% Agent Reasoning
    Router -->|2. Analisis Sentimen & Mood| GeminiAgent
    GeminiAgent -->|3. Tool Calling Radius| PlacesResolver
    PlacesResolver -->|4. Daftar Restoran Nyata| Router
    Router -->|5. Catat Sesi & Telemetri| TelemetryLogger
    TelemetryLogger -->|Insert / Update| SessionsTbl

    %% Response to Mobile
    Router -->|6. JSON Hasil Rekomendasi| UI_Home
    UI_Home -->|Simpan Rekomendasi Terakhir| LocalCache

    %% Admin Flow
    SessionsTbl -->|Query Analitik Sentimen| AnalyticsView
    UsersTbl -->|Kelola Status & Injeksi Voucher| VoucherInjector
    BannerCMS -->|Kelola Iklan Wilayah| BannersTbl
    BannersTbl -->|Fetch Banner Geofence| Router
```

---

## 2. Alur Inisialisasi Aplikasi & Dual-Storage Cache

Alur ini memastikan pengguna selalu melihat konten instan tanpa jeda blank screen atau crash saat membuka aplikasi, baik dalam kondisi online maupun saat server tidak dapat dihubungi.

```mermaid
flowchart TD
    Start([Pengguna Buka Aplikasi]) --> CheckMem{Data ada di In-Memory Cache?}
    
    CheckMem -- Ya --> RenderCachedUI[Tampilkan Konten Seketika]
    CheckMem -- Tidak --> CheckDisk{File Cache Ada di Storage Perangkat?}
    
    CheckDisk -- Ya --> LoadDisk[Baca & Parse JSON dari Storage] --> SetMem[Simpan ke In-Memory] --> RenderCachedUI
    CheckDisk -- Tidak --> FallbackDefaults[Gunakan Built-in Curated Defaults] --> RenderCachedUI

    RenderCachedUI --> BackgroundFetch[Lakukan HTTP Fetch ke Server]
    
    BackgroundFetch --> NetworkCheck{Server Berhasil Merespons?}
    
    NetworkCheck -- 200 OK --> UpdateCache[Simpan Data Terbaru ke In-Memory & Storage File]
    UpdateCache --> UpdateUI[Perbarui Tampilan dengan Data Terbaru]
    
    NetworkCheck -- Timeout / Offline / 429 --> KeepCached[Pertahankan Tampilan Cache Sebelumnya]
    KeepCached --> SilentLog[Catat Log Mode Offline Tanpa Mengganggu Pengguna]
```

### Komponen Cache:
1. **Banners Cache (`moodeats_cache_banners.json`)**: Menyimpan banner promo wilayah.
2. **Default Menus Cache (`moodeats_cache_default_menus.json`)**: Menyimpan hidangan kenyamanan (*comfort food*) lokal.
3. **Roulette Cache (`moodeats_cache_roulette_items.json`)**: Menyimpan opsi makanan & manfaat suasana hati.
4. **History Cache (`moodeats_cache_history_<userId>.json`)**: Menyimpan sesi pencarian pengguna sebelumnya.
5. **Recommendation Cache (`moodeats_cache_rec_<prompt>.json` & `rec_latest`)**: Menyimpan kartu hasil rekomendasi.

---

## 3. Alur Curhat Multimodal & Penalaran Sentimen AI (Online vs Offline)

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna (Mobile)
    participant UI as HomeScreen / OmniSearchBar
    participant Cache as AppCacheService
    participant API as ApiService (HTTP Client)
    participant Agent as FastAPI Backend (:8080)
    participant Gemini as Gemini 2.5 Flash
    participant Places as Google Places / Overpass OSM
    participant DB as Supabase DB

    User->>UI: Input Curhat (Ketik / Voice STT / Foto Kamera)
    User->>UI: Pilih Filter (Wajib Halal, Buka Sekarang, Preferensi Diet)
    UI->>UI: Tampilkan Dialog Loading ("Menganalisis suasana hati kamu...")

    UI->>API: POST /api/v1/agent/recommend (Prompt, Lat, Lng, Filter, Telemetri)
    
    alt Skenario Online (Server Berjalan Normal)
        API->>Agent: Menerima Payload
        Agent->>Gemini: Prompt Emosional + Filter Halal/Jam
        Gemini-->>Agent: Reasoning: Mood Terdeteksi, Kategori Makanan, Search Keyword
        Agent->>Places: Cari Tempat Terdekat Sesuai Keyword & Geolocation
        Places-->>Agent: Daftar Restoran Nyata (Rating, Alamat, Jarak, Buka/Tutup)
        Agent->>DB: Catat Sesi & Telemetri Pengguna
        Agent-->>API: 200 OK (RecommendationResponse JSON)
        API->>Cache: Simpan Hasil ke Cache Lokal
        API-->>UI: Kembalikan Objek Rekomendasi
        UI->>User: Buka ResultsScreen (Daftar Restoran, Maps, Pesan Antar)

    else Skenario Offline / Gangguan Server / Kuota Gemini Habis (429)
        API-xAgent: Koneksi Gagal / Timeout (Max 12 Detik) / Error 429
        API->>Cache: Panggil getCachedRecommendation(prompt)
        Cache-->>API: Kembalikan Data Tersimpan / Generator Rekomendasi Lokal
        API-->>UI: Kembalikan RecommendationResponse (Status: offline_mode)
        UI->>User: Buka ResultsScreen dengan Badge:<br/>"[📶 Mode Offline Cerdas: Server tidak dapat dihubungi...]"
    end
```

---

## 4. Alur Gamifikasi Bite Roulette (Bilingual & Direct Search)

```mermaid
flowchart TD
    OpenTab([Pengguna Buka Tab Roulette]) --> CheckLang{Pilihan Bahasa Aktif?}
    
    CheckLang -- Bahasa Indonesia --> RenderID[Tampilkan Label & Mood Benefit dalam Bahasa Indonesia]
    CheckLang -- English --> RenderEN[Tampilkan Label & Mood Benefit dalam Bahasa Inggris]
    
    RenderID --> TapSpin[Pengguna Menekan 'Putar Roda Keberuntungan']
    RenderEN --> TapSpin

    TapSpin --> AnimationSpin[Animasi Putar Roda: Easing Curve easeOutCubic ~4.5 Detik]
    AnimationSpin --> PickWinner[Roda Berhenti pada Item Terpilih, misal: 'Mie Ayam Bakso']
    
    PickWinner --> ShowCard[Munculkan Kartu Pilihan Makanan & Mood Benefit]
    ShowCard --> TapDirectSearch[Pengguna Tekan 'Cari Tempat Kuliner Ini Sekarang!']
    
    TapDirectSearch --> AutoPrompt[Otomatis Susun Prompt Sesuai Bahasa:<br/>'Lagi bingung mau makan apa, hasil roulette: Mie Ayam Bakso...']
    AutoPrompt --> ExecSearch[Jalankan Eksekusi Rekomendasi Terdekat]
    ExecSearch --> ResultsScreen([Masuk ke Halaman Hasil Rekomendasi])
```

---

## 5. Alur Riwayat Sesi, Lazy Pagination & Zero-Cost Replay

```mermaid
flowchart TD
    OpenHistory([Pengguna Buka Tab Riwayat]) --> FilterDefault[Filter Default: 'Hari Ini' (Today Only)]
    FilterDefault --> FetchBatch1[Fetch Batch Awal (Offset: 0, Limit: 10)]

    FetchBatch1 --> RenderCards[Tampilkan Daftar Kartu Sesi]
    
    RenderCards --> UserAction{Aksi Pengguna?}
    
    %% Aksi 1: Replay Rekomendasi
    UserAction -- Klik Salah Satu Kartu Riwayat --> CheckSavedData{Detail Rekomendasi Tersimpan di Sesi?}
    CheckSavedData -- Ya --> InstantReplay[Buka ResultsScreen Seketika dari Cache Lokal<br/>(0 Token AI, 0 Delay API)]
    CheckSavedData -- Tidak --> ReQueryAI[Kirim Ulang Prompt ke AI Agent]

    %% Aksi 2: Ubah Filter Tanggal
    UserAction -- Pilih 'Pilih Rentang' --> OpenDateRangePicker[Buka Dialog Kalender Material]
    OpenDateRangePicker --> ApplyRange[Filter Data Berdasarkan Tanggal Mulai & Selesai]
    ApplyRange --> FetchFiltered[Fetch Sesi Sesuai Rentang Tanggal] --> RenderCards

    %% Aksi 3: Scroll ke Bawah (Lazy Load)
    UserAction -- Scroll Mendekati Bawah --> CheckMore{has_more == true?}
    CheckMore -- Ya --> LoadNextPage[Panggil API dengan Offset += 10]
    LoadNextPage --> AppendList[Tambahkan 10 Item Baru ke Daftar] --> RenderCards
    CheckMore -- Tidak --> ShowEndNotice[Tampilkan 'Semua riwayat telah dimuat']

    %% Aksi 4: Klik Tab Riwayat saat Berada di Bawah
    UserAction -- Klik Ikon Tab Riwayat --> SmoothScrollUp[Otomatis Scroll Mulus Kembali ke Atas]
```

---

## 6. Alur Mesin Voucher Dinamis (Klaim, Injeksi Admin & Countdown 1D : HH:MM:SS)

```mermaid
stateDiagram-v2
    [*] --> TersediaDiRestoran : Merchant Memasang Promo Diskon
    [*] --> InjeksiAdmin : Admin Console Menginjeksi Voucher ke User

    TersediaDiRestoran --> DiklaimUser : Pengguna Menekan 'Klaim Voucher' di Restoran
    InjeksiAdmin --> DiklaimUser : Otomatis Tersimpan di Dompet Voucher User

    state DiklaimUser {
        [*] --> TimerBerjalan
        TimerBerjalan --> FormatCountdown : Hitung Selisih Waktu Realtime
        
        state FormatCountdown {
            DurasiPanjang : Durasi > 24 Jam -> Format '1D : 23:59:59'
            DurasiPendek : Durasi < 24 Jam -> Format '14:59'
        }
    }

    DiklaimUser --> TampilkanDiHome : Tampil di Banner Bawah Beranda
    DiklaimUser --> TampilkanDiRiwayat : Tampil di Kartu Mengambang Tab Riwayat

    DiklaimUser --> KlikVoucher : Pengguna Mengetuk Voucher
    KlikVoucher --> DialogQRCashier : Muncul Pop-up Barcode & QR Code untuk Kasir

    DialogQRCashier --> ScanKasirSukses : Kasir Memindai & Diskon Diterapkan
    ScanKasirSukses --> [*] : Voucher Selesai Digunakan

    TimerBerjalan --> WaktuHabis : Countdown Menyentuh 00:00
    WaktuHabis --> Kedaluwarsa : Voucher Hangus Otomatis
    Kedaluwarsa --> [*]
```

---

## 7. Alur Telemetri Mobile & Analitik Sentimen Real-Time di Web Admin

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna Mobile
    participant Mobile as Flutter App
    participant Agent as FastAPI Backend (:8080)
    participant DB as Supabase PostgreSQL
    participant Admin as Web Admin Console (:8081)
    actor Ops as Administrator

    User->>Mobile: Melakukan Interaksi / Pencarian Curhat
    Mobile->>Mobile: Ekstraksi Telemetri (Model HP, OS Android/iOS, Versi App)
    Mobile->>Agent: POST /api/v1/agent/recommend + Header Telemetri
    
    Agent->>DB: Simpan Telemetri ke Tabel session_telemetry
    Agent->>DB: Simpan Hasil Sentimen ke Tabel sentiment_analytics

    Ops->>Admin: Membuka Menu /analytics di Web Console
    Admin->>DB: Query Agregasi Real-Time (Sentimen Harian, Top Cravings, Device OS)
    DB-->>Admin: Kembalikan Data Agregasi
    Admin->>Ops: Render Grafik Chart.js: Tren Sentimen & Sebaran Perangkat

    Ops->>Admin: Membuka Menu /users (User Management)
    Admin->>DB: Query Daftar Pengguna Terdaftar & Status Ban
    DB-->>Admin: Data Pengguna
    Ops->>Admin: Klik 'Inject Voucher' ke User Tertentu
    Admin->>DB: INSERT ke Tabel user_vouchers
    DB-->>Mobile: Voucher Otomatis Muncul di Aplikasi Mobile Pengguna Saat Dibuka
```

---

## 📌 Ringkasan Status Alur Sistem

| Fitur | Status Alur | Verifikasi Lapangan |
|:---|:---|:---|
| **Inisialisasi & Cache Perangkat** | 🟢 Selesai & Terverifikasi | Diuji cold start & reboot aplikasi |
| **Pencarian Sentimen Multimodal** | 🟢 Selesai & Terverifikasi | Teks, STT suara, dan kamera berfungsi |
| **Resiliensi Mode Offline** | 🟢 Selesai & Terverifikasi | Diuji saat server mati total; UI tetap utuh & kartu lokal tersaji |
| **Bite Roulette Bilingual** | 🟢 Selesai & Terverifikasi | Label & mood berganti instan saat ubah bahasa |
| **Riwayat & Replay Tanpa AI** | 🟢 Selesai & Terverifikasi | Replay instan dari cache sesi lokal |
| **Timer Voucher `1D : HH:MM:SS`** | 🟢 Selesai & Terverifikasi | Ticker countdown berjalan akurat di Beranda & Riwayat |
| **Admin Console & Telemetri** | 🟢 Selesai & Terverifikasi | Data perangkat & sentimen tercatat di dashboard |

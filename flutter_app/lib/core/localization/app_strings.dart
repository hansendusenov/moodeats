enum AppLanguage { id, en }

class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  static AppStrings of(AppLanguage lang) => AppStrings(lang);

  bool get isId => language == AppLanguage.id;

  // Common
  String get appTitle => 'MoodEats';
  String get cancel => isId ? 'Batal' : 'Cancel';
  String get save => isId ? 'Simpan' : 'Save';
  String get error => isId ? 'Kesalahan' : 'Error';
  String get loading => isId ? 'Memuat...' : 'Loading...';
  String get refresh => isId ? 'Perbarui' : 'Refresh';

  // Navigation
  String get navHome => isId ? 'Beranda' : 'Home';
  String get navRoulette => 'Roulette';
  String get navHistory => isId ? 'Riwayat' : 'History';
  String get navAccount => isId ? 'Akun' : 'Account';

  // Auth - General & Login
  String get loginTitle => isId ? 'Selamat Datang Kembali!' : 'Welcome Back!';
  String get loginSubtitle => isId
      ? 'Masuk untuk simpan riwayat emosi & klaim voucher diskon kuliner favoritmu.'
      : 'Sign in to save your emotion history & claim special culinary discount vouchers.';
  String get email => 'Email';
  String get emailHint => 'nama@email.com';
  String get password => isId ? 'Kata Sandi' : 'Password';
  String get passwordHint => '••••••••';
  String get loginBtn => isId ? 'Masuk ke MoodEats' : 'Sign In to MoodEats';
  String get orDivider => isId ? 'atau masuk dengan' : 'or continue with';
  String get googleSignIn => isId ? 'Masuk dengan Google' : 'Sign in with Google';
  String get googleSignUp => isId ? 'Daftar dengan Google' : 'Sign up with Google';
  String get noAccount => isId ? 'Belum punya akun?' : "Don't have an account?";
  String get registerNow => isId ? 'Daftar Sekarang' : 'Register Now';

  // Auth - Register
  String get registerTitle => isId ? 'Daftar Akun MoodEats' : 'Create MoodEats Account';
  String get registerSubtitle => isId
      ? 'Lengkapi data dirimu untuk mendapatkan kurasi rasa & voucher diskon.'
      : 'Fill in your details to get personalized food curation & discount vouchers.';
  String get fullName => isId ? 'Nama Lengkap' : 'Full Name';
  String get fullNameHint => isId ? 'Nama kamu' : 'Your name';
  String get birthDate => isId ? 'Tanggal Lahir' : 'Date of Birth';
  String get selectBirthDate => isId ? 'Pilih Tanggal Lahir' : 'Select Date of Birth';
  String get gender => isId ? 'Jenis Kelamin' : 'Gender';
  String get genderMale => isId ? 'Laki-laki' : 'Male';
  String get genderFemale => isId ? 'Perempuan' : 'Female';
  String get confirmPassword => isId ? 'Konfirmasi Kata Sandi' : 'Confirm Password';
  String get registerBtn => isId ? 'Daftar Akun Baru' : 'Register New Account';
  String get alreadyHaveAccount => isId ? 'Sudah punya akun?' : 'Already have an account?';
  String get loginNow => isId ? 'Masuk di Sini' : 'Sign In Here';

  // Google & Email Account Picker & Profile Flow
  String get chooseAccountTitle => isId ? 'Login dengan Email yang Mana?' : 'Which Email to Sign In With?';
  String get chooseGoogleAccount => isId ? 'Pilih Akun Email / Google' : 'Choose Email / Google Account';
  String get chooseAccountSubtitle => isId
      ? 'Pilih email atau ketik email baru untuk langsung masuk via Firebase'
      : 'Select an email or enter a new email to sign in directly via Firebase';
  String get fastEmailSignInBtn => isId ? 'Masuk Langsung dengan Email / Google' : 'Direct Sign In with Email / Google';
  String get useOtherGoogleAccount => isId ? 'Gunakan Email Lain / Baru' : 'Use Another / New Email';
  String get enterGoogleEmail => isId ? 'Masukkan Alamat Email' : 'Enter Email Address';
  String get enterEmailPlaceholder => isId ? 'nama@email.com' : 'name@email.com';
  String get signInDirectBtn => isId ? 'Masuk Langsung' : 'Sign In Directly';
  String get registerCompleteProfileLater => isId
      ? 'Akun berhasil dibuat! Selamat datang di MoodEats.'
      : 'Account created! Welcome to MoodEats.';
  String get pleaseCompleteProfile => isId
      ? 'Yuk lengkapi profil tanggal lahir & gender agar rekomendasi lebih akurat.'
      : 'Please complete your birth date & gender for personalized curation.';
  String get welcomeBack => isId ? 'Selamat datang kembali' : 'Welcome back';
  String get googleProfileTitle => isId ? 'Lengkapi Profil Kamu' : 'Complete Your Profile';
  String get googleProfileSubtitle => isId
      ? 'Masukkan tanggal lahir dan jenis kelamin untuk rekomendasi kuliner yang lebih akurat.'
      : 'Enter your date of birth and gender for more personalized food curation.';
  String get setPasswordTitle => isId ? 'Buat Kata Sandi Akun' : 'Create Account Password';
  String get passwordNote => isId
      ? 'Kata sandi ini opsional agar kamu juga bisa login manual tanpa Google Auth di masa mendatang.'
      : 'This password is optional so you can also log in manually without Google Auth in the future.';
  String get completeAndContinue => isId ? 'Simpan & Lanjutkan' : 'Save & Continue';
  String get skipForNow => isId ? 'Nanti Saja' : 'Skip for Now';
  String get profileIncomplete => isId ? 'Profil Belum Lengkap ⚠️' : 'Profile Incomplete ⚠️';
  String get profileIncompleteDesc => isId
      ? 'Lengkapi tanggal lahir & jenis kelamin agar rekomendasi lebih personal.'
      : 'Complete your birth date & gender for more tailored recommendations.';
  String get completeProfileNow => isId ? 'Lengkapi Sekarang' : 'Complete Now';
  String get editProfile => isId ? 'Ubah Profil' : 'Edit Profile';
  String get profileCompletedSuccess => isId ? 'Profil berhasil disimpan!' : 'Profile saved successfully!';

  // Errors & Validations
  String get fillAllFields => isId ? 'Harap lengkapi semua data!' : 'Please fill in all required fields!';
  String get passwordMismatch => isId ? 'Konfirmasi kata sandi tidak cocok!' : 'Passwords do not match!';
  String get passwordMinLength => isId ? 'Kata sandi minimal 6 karakter!' : 'Password must be at least 6 characters!';
  String get invalidEmail => isId ? 'Format email tidak valid!' : 'Invalid email format!';
  String get loginSuccess => isId ? 'Berhasil masuk!' : 'Login successful!';
  String get registerSuccess => isId ? 'Pendaftaran berhasil!' : 'Registration successful!';

  // Account Screen
  String get accountTitle => isId ? 'Akun & Pengaturan ⚙️' : 'Account & Settings ⚙️';
  String get verifiedAccount => isId ? 'Akun Firebase Terverifikasi' : 'Verified Firebase Account';
  String get languageSetting => isId ? 'Pilihan Bahasa' : 'Language Selection';
  String get indonesian => '🇮🇩 Bahasa Indonesia';
  String get english => '🇬🇧 English';
  String get activeGpsLocation => isId ? 'Lokasi GPS Aktif' : 'Active GPS Location';
  String get flashVoucher15Min => isId ? 'Voucher Flash 15 Menit' : '15-Minute Flash Voucher';
  String get noActiveVoucher => isId ? 'Tidak ada voucher aktif saat ini' : 'No active voucher currently';
  String get appVersion => isId ? 'Versi Aplikasi' : 'App Version';
  String get statusAndServices => isId ? 'Status & Informasi Layanan' : 'Service Status & Information';
  String get logout => isId ? 'Keluar Akun' : 'Log Out';
  String get logoutConfirmTitle => isId ? 'Konfirmasi Keluar' : 'Confirm Logout';
  String get logoutConfirmMsg => isId
      ? 'Apakah kamu yakin ingin keluar dari akun MoodEats?'
      : 'Are you sure you want to log out of MoodEats?';

  // Home Screen
  String get whatDoYouFeel => isId ? 'Apa yang kamu rasakan sekarang?' : 'How are you feeling right now?';
  String get curhatPlaceholder => isId
      ? 'Curhat di sini: misal "Lagi stres deadline pengen kuah pedas nampol..."'
      : 'Share here: e.g. "Stressed with deadlines, need spicy comfort soup..."';
  String get findFoodBtn => isId ? 'Temukan Makanan' : 'Find Food';
  String get quickMoodTitle => isId ? 'Pilihan Cepat Suasana Hati ✨' : 'Quick Mood Picker ✨';
  String get comfortFoodTitle => isId ? 'Comfort Food Pilihan 🍜' : 'Curated Comfort Food 🍜';
  String get availableInYourArea => isId ? 'Tersedia di Area Kamu' : 'Available in Your Area';
  String get activeVoucherSticky => isId ? 'Voucher Aktif' : 'Active Voucher';
  String get culinaryLocation => isId ? 'Lokasi Kuliner Kamu' : 'Your Culinary Location';
  String get detectGpsNow => isId ? 'Deteksi GPS Sekarang' : 'Detect GPS Now';
  String get orChooseCity => isId ? 'Atau Pilih Kota Cepat:' : 'Or Quick Select City:';

  // Roulette Screen
  String get rouletteTitle => isId ? 'Bingung Mau Makan Apa Hari Ini?' : 'Confused About What to Eat Today?';
  String get rouletteSubtitle => isId
      ? 'Putar roda keberuntungan dan biarkan MoodEats memilihkan santapan terbaik untukmu!'
      : 'Spin the wheel of fortune and let MoodEats choose the best meal for you!';
  String get spinWheelBtn => isId ? 'Putar Roda Keberuntungan 🎯' : 'Spin the Lucky Wheel 🎯';
  String get spinResultTitle => isId ? 'Pilihan Roulette Kamu:' : 'Your Roulette Pick:';
  String get spinResultSubtitle => isId
      ? 'Cocok banget buat mood kamu sekarang!'
      : 'Perfect match for your mood right now!';
  String get spinAgain => isId ? 'Putar Lagi' : 'Spin Again';
  String get searchThisMenu => isId ? 'Cari Tempat Makan Ini' : 'Search Places for This';

  // History Screen
  String get historyTitle => isId ? 'Riwayat & Aktivitas 📜' : 'History & Activities 📜';
  String get activeVoucherSection => isId ? 'Voucher Sedang Aktif 🔥' : 'Active Vouchers 🔥';
  String get recentRecommendations => isId ? 'Riwayat Rekomendasi Terakhir' : 'Recent Recommendations';
  String get noHistoryYet => isId ? 'Belum ada riwayat rekomendasi' : 'No recommendation history yet';
  String get emptyHistorySub => isId
      ? 'Curhatkan mood makanan kamu di Beranda untuk mendapatkan rekomendasi!'
      : 'Share your food mood on Home to receive smart recommendations!';

  // Results Screen
  String get resultsTitle => isId ? 'Rekomendasi Mood Kamu' : 'Your Mood Recommendations';
  String get yourQuery => isId ? 'Curhatan Kamu:' : 'Your Input:';
  String get aiAnalysis => isId ? 'Analisis AI' : 'AI Analysis';
  String get recommendedPlaces => isId ? 'Tempat Makan Rekomendasi' : 'Recommended Places';
  String get locationsCount => isId ? 'Lokasi' : 'Locations';
  String get noPlacesFound => isId
      ? 'Tidak ditemukan lokasi terdekat. Coba cari dengan kata kunci lain.'
      : 'No nearby places found. Try searching with different keywords.';
  String get homeCookingIdeas => isId ? 'Ide Masak Sendiri di Rumah 🍳' : 'Home Cooking Ideas 🍳';
  String get sponsoredMerchant => isId
      ? 'MERCHANT SPONSOR PILIHAN - KLAIM DISKON SPESIAL'
      : 'FEATURED SPONSOR MERCHANT - CLAIM SPECIAL DISCOUNT';
  String get claimVoucher => isId ? 'Klaim' : 'Claim';
  String get openMaps => isId ? 'Buka Maps' : 'Open Maps';
  String get orderDelivery => isId ? 'Pesan Antar' : 'Delivery';
  String get valid15Min => isId ? 'Berlaku 15 menit setelah diklaim' : 'Valid for 15 minutes after claiming';

  // Voucher Countdown Dialog
  String get voucherFlash15 => isId ? 'VOUCHER FLASH 15 MENIT' : '15-MINUTE FLASH VOUCHER';
  String get remainingTime => isId ? 'SISA WAKTU BERLAKU' : 'TIME REMAINING';
  String get routeMaps => isId ? 'Rute Maps' : 'Directions';
  String get understood => isId ? 'Mengerti' : 'Understood';
  String get copyCode => isId ? 'Salin Kode' : 'Copy Code';
  String get codeCopied => isId ? 'Kode voucher disalin!' : 'Voucher code copied!';
  String get voucherInstruction => isId
      ? 'Tunjukkan kode ini ke kasir sebelum timer habis untuk mendapatkan diskon langsung.'
      : 'Show this code to the cashier before the timer ends to get your discount.';

  // Voice & Camera Input
  String get analyzingEmotion => isId ? 'AI Sedang Menganalisis Emosimu...' : 'AI is Analyzing Your Emotion...';
  String get connectingHunger => isId
      ? 'Menghubungkan rasa lapar & lokasi terbaik'
      : 'Connecting hunger & the best locations';
  String get voiceInput => isId ? 'Input Suara' : 'Voice Input';
  String get foodPhoto => isId ? 'Foto Makanan' : 'Food Photo';
  String get detectingLocation => isId ? 'Mendeteksi...' : 'Detecting...';
  String get listeningVoice => isId ? 'Mendengarkan suaramu...' : 'Listening to your voice...';
  String get voiceSpeakPrompt => isId
      ? 'Katakan apa yang sedang kamu rasakan atau makanan apa yang kamu inginkan...'
      : 'Say how you are feeling or what food you are craving...';
  String get choosePhotoSource => isId ? 'Pilih Sumber Foto' : 'Choose Photo Source';
  String get takePhoto => isId ? 'Ambil Foto dari Kamera' : 'Take Photo with Camera';
  String get chooseFromGallery => isId ? 'Pilih dari Galeri' : 'Choose from Gallery';
  String get applyVoiceText => isId ? 'Gunakan Teks Ini' : 'Use This Text';
  String get cancelVoice => isId ? 'Batal' : 'Cancel';
  String get startListening => isId ? 'Mulai Bicara' : 'Start Speaking';
  String get stopListening => isId ? 'Selesai Bicara' : 'Done Speaking';
  String get micListening => isId ? 'Sedang mendengarkan... Katakan curhatanmu' : 'Listening... Say what you crave';
  String get micTapToSpeak => isId ? 'Ketuk mikrofon untuk mulai bicara' : 'Tap microphone to start speaking';
  String get speechNotAvailable => isId
      ? 'Mikrofon siap. Kamu juga bisa memilih saran cepat di bawah.'
      : 'Microphone ready. You can also pick quick suggestions below.';
  String get analyzingImageWithAi => isId
      ? 'AI Gemini sedang menganalisis foto...'
      : 'Gemini AI is analyzing your photo...';
  String get imageAnalyzedSuccess => isId
      ? 'Foto berhasil dianalisis! Tinjau dan tekan Temukan Makanan.'
      : 'Photo analyzed! Review and tap Find Food.';
  String get imageAnalysisFailed => isId
      ? 'Gagal menganalisis foto, silakan coba lagi.'
      : 'Failed to analyze photo, please try again.';

  // Quick Moods
  String get quickMood1 => isId ? 'Lembur Lelah 😴' : 'Overtime Tired 😴';
  String get quickMood2 => isId ? 'Pedas Nampol 🌶️' : 'Super Spicy 🌶️';
  String get quickMood3 => isId ? 'Manis Hangat 🍵' : 'Sweet & Warm 🍵';
  String get quickMood4 => isId ? 'Hemat Tanggal Tua 🪙' : 'Budget Friendly 🪙';

  // Gender Helper
  bool isFemale(String? val) {
    if (val == null) return false;
    final lower = val.toLowerCase().trim();
    return lower == 'female' ||
        lower == 'perempuan' ||
        lower == 'wanita' ||
        lower.startsWith('fem') ||
        lower.startsWith('perem');
  }

  bool isMale(String? val) {
    if (val == null) return false;
    if (isFemale(val)) return false;
    final lower = val.toLowerCase().trim();
    return lower == 'male' ||
        lower == 'laki-laki' ||
        lower == 'pria' ||
        lower == 'laki' ||
        lower.startsWith('lak');
  }

  String formatGender(String? val) {
    if (val == null || val.isEmpty || val == '-') return '-';
    if (isFemale(val)) return genderFemale;
    if (isMale(val)) return genderMale;
    return val;
  }
}

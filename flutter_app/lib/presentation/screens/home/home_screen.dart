// import 'dart:io'; (omitted for web compatibility)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/models/banner_model.dart';
import 'package:moodeats_app/data/models/recommendation_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moodeats_app/data/providers/app_providers.dart';
import 'package:moodeats_app/presentation/screens/results/results_screen.dart';
import 'package:moodeats_app/presentation/widgets/voucher_countdown_dialog.dart';
import 'package:moodeats_app/presentation/widgets/location_picker_sheet.dart';
import 'package:flutter/services.dart';
import 'package:moodeats_app/data/services/location_service.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:moodeats_app/data/services/device_info_service.dart';
import 'package:moodeats_app/data/services/preferences_service.dart';
import 'package:moodeats_app/presentation/widgets/dietary_preferences_modal.dart';
import 'package:moodeats_app/presentation/widgets/bouncy_tap.dart';
import 'package:moodeats_app/data/services/app_cache_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  List<Map<String, String>> _getQuickMoods(AppStrings tr) => [
    {
      'label': tr.quickMood1,
      'query': tr.isId
          ? 'Lagi lembur lelah banget kerjaan numpuk, butuh makanan penenang pikiran yang hangat.'
          : 'Working late and exhausted, need warm comforting food to relax.',
    },
    {
      'label': tr.quickMood2,
      'query': tr.isId
          ? 'Lagi stres pengen teriak, butuh makanan super pedas berkuah yang bikin melek!'
          : 'Super stressed, need extremely spicy hot soup to boost energy!',
    },
    {
      'label': tr.quickMood3,
      'query': tr.isId
          ? 'Lagi mellow sedih, butuh minuman manis hangat atau dessert penyejuk hati.'
          : 'Feeling sad and mellow, need warm sweet drinks or comforting dessert.',
    },
    {
      'label': tr.quickMood4,
      'query': tr.isId
          ? 'Tanggal tua dompet menipis, butuh makanan kenyang enak di bawah 25 ribu.'
          : 'Tight budget at the end of the month, need hearty delicious food under 25k.',
    },
    {
      'label': 'Bite Roulette 🎲',
      'query': 'ROULETTE',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(userLocationProvider.notifier).detectCurrentLocation();
      final auth = ref.read(firebaseAuthServiceProvider).currentUser;
      if (auth != null && auth.id.isNotEmpty) {
        final telemetry = await DeviceInfoService.getTelemetry();
        final prefs = ref.read(userPreferencesProvider);
        ref.read(apiServiceProvider).syncUserProfile(
          userId: auth.id,
          email: auth.email,
          displayName: auth.displayName.isNotEmpty ? auth.displayName : auth.email.split('@').first,
          birthDate: auth.birthDate,
          gender: auth.gender,
          deviceModel: telemetry.model,
          deviceOs: telemetry.os,
          appVersion: telemetry.appVersion,
          isHalalOnly: prefs.isHalalOnly,
          dietaryType: prefs.dietaryType,
          allergies: prefs.allergies,
        );
        ref.read(activeVoucherProvider.notifier).fetchUserVouchers(auth.id);
        ref.invalidate(userVouchersProvider);
      }
    });
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % 3;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _executeAgentSearch(String prompt, AppStrings tr) async {
    if (prompt.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    // Show Loading Modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr.analyzingEmotion,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr.connectingHunger,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final userLoc = ref.read(userLocationProvider);
    final authUser = ref.read(firebaseAuthServiceProvider).currentUser;
    final telemetry = await DeviceInfoService.getTelemetry();
    final prefs = ref.read(userPreferencesProvider);
    try {
      final response = await ref.read(apiServiceProvider).getRecommendation(
        prompt: prompt,
        city: userLoc.cityName,
        lat: userLoc.latitude,
        lng: userLoc.longitude,
        userId: authUser?.id,
        isHalalOnly: prefs.isHalalOnly,
        dietaryType: prefs.dietaryType,
        allergies: prefs.allergies,
        onlyOpenNow: prefs.isOpenNowOnly,
        deviceOs: telemetry.os,
        appVersion: telemetry.appVersion,
      );

      // Refresh history state so new search immediately appears in History tab
      ref.read(historyNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              response: response,
              userPrompt: prompt,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.isId
                ? 'Gagal menganalisis: ${e.toString().replaceAll("Exception: ", "")}'
                : 'Failed to analyze: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _handleQuickMoodTap(Map<String, String> mood, AppStrings tr) {
    if (mood['query'] == 'ROULETTE') {
      ref.read(mainTabProvider.notifier).state = 1;
    } else {
      _searchController.text = mood['query']!;
      _executeAgentSearch(mood['query']!, tr);
    }
  }

  Future<void> _initSpeech() async {
    if (!_speechAvailable) {
      try {
        _speechAvailable = await _speech.initialize(
          onError: (e) {
            debugPrint('STT Error: $e');
            if (mounted) setState(() => _isListening = false);
          },
          onStatus: (status) {
            debugPrint('STT Status: $status');
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isListening = false);
            }
          },
        );
      } catch (e) {
        debugPrint('STT init exception: $e');
        _speechAvailable = false;
      }
    }
  }

  Future<void> _openVoiceSheet(AppStrings tr) async {
    await _initSpeech();
    String liveWords = '';
    bool listeningNow = false;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> toggleListening() async {
              if (listeningNow) {
                await _speech.stop();
                setSheetState(() => listeningNow = false);
                if (mounted) setState(() => _isListening = false);
              } else {
                if (!_speechAvailable) {
                  await _initSpeech();
                }
                if (_speechAvailable) {
                  setSheetState(() {
                    listeningNow = true;
                    liveWords = '';
                  });
                  if (mounted) setState(() => _isListening = true);
                  final localeId = tr.isId ? 'id_ID' : 'en_US';
                  await _speech.listen(
                    // ignore: deprecated_member_use
                    localeId: localeId,
                    onResult: (result) {
                      setSheetState(() {
                        liveWords = result.recognizedWords;
                      });
                      if (result.finalResult && liveWords.isNotEmpty) {
                        _searchController.text = liveWords;
                      }
                    },
                  );
                } else {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(tr.speechNotAvailable),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr.voiceInput,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listeningNow ? tr.micListening : tr.micTapToSpeak,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: listeningNow ? FontWeight.w700 : FontWeight.normal,
                      color: listeningNow ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: toggleListening,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: listeningNow ? AppColors.primary : AppColors.redBg,
                        boxShadow: listeningNow
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        listeningNow ? Icons.mic : Icons.mic_none,
                        color: listeningNow ? Colors.white : AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (liveWords.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '"$liveWords"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(tr.applyVoiceText, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _searchController.text = liveWords;
                          if (listeningNow) _speech.stop();
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 6),
                  Text(
                    tr.isId ? '💡 Pilih Inspirasi Curhatan Cepat:' : '💡 Quick Voice Suggestions:',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Text('🍜'),
                        label: Text(tr.isId ? 'Capek butuh kuah hangat' : 'Tired, need hot soup'),
                        onPressed: () {
                          if (listeningNow) _speech.stop();
                          _searchController.text = tr.isId
                              ? 'Lagi capek banget setelah seharian kerja, butuh sup kuah hangat yang menenangkan.'
                              : 'Exhausted after a long day of work, need warm soothing soup.';
                          Navigator.pop(ctx);
                        },
                      ),
                      ActionChip(
                        avatar: const Text('🌶️'),
                        label: Text(tr.isId ? 'Stres butuh pedas nampol' : 'Stressed, need spicy food'),
                        onPressed: () {
                          if (listeningNow) _speech.stop();
                          _searchController.text = tr.isId
                              ? 'Lagi stres deadline numpuk, butuh makanan ekstra pedas gurih yang bikin melek!'
                              : 'Stressed with deadlines, need extra spicy savory food to wake up!';
                          Navigator.pop(ctx);
                        },
                      ),
                      ActionChip(
                        avatar: const Text('🍰'),
                        label: Text(tr.isId ? 'Pengen manis penyejuk hati' : 'Need sweet comfort dessert'),
                        onPressed: () {
                          if (listeningNow) _speech.stop();
                          _searchController.text = tr.isId
                              ? 'Lagi galau pengen dessert manis creamy atau pastry hangat.'
                              : 'Feeling down, craving creamy sweet dessert or warm pastry.';
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (listeningNow) _speech.stop();
                        Navigator.pop(ctx);
                      },
                      child: Text(tr.cancel),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (_speech.isListening) {
      await _speech.stop();
    }
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _openCameraSheet(AppStrings tr) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr.choosePhotoSource,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.redBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: Text(tr.takePhoto, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _processImageAnalysis(ImageSource.camera, tr);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.redBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: Text(tr.chooseFromGallery, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _processImageAnalysis(ImageSource.gallery, tr);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImageAnalysis(ImageSource source, AppStrings tr) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (photo == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tr.analyzingImageWithAi,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );

      final imageBytes = await photo.readAsBytes();
      final mimeType = photo.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      // Cross-platform: XFile handles in-memory buffer cleanup
      final api = ref.read(apiServiceProvider);
      final analyzedPrompt = await api.analyzeImage(
        imageBytes: imageBytes,
        mimeType: mimeType,
        lang: tr.isId ? 'id' : 'en',
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (analyzedPrompt.isNotEmpty) {
          setState(() {
            _searchController.text = analyzedPrompt;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr.imageAnalyzedSuccess),
              backgroundColor: AppColors.happyGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.imageAnalysisFailed),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  String _getTimeGreeting(bool isId) {
    final hour = DateTime.now().hour;
    if (isId) {
      if (hour >= 4 && hour < 11) return 'Selamat Pagi';
      if (hour >= 11 && hour < 15) return 'Selamat Siang';
      if (hour >= 15 && hour < 18) return 'Selamat Sore';
      return 'Selamat Malam';
    } else {
      if (hour >= 4 && hour < 12) return 'Good Morning';
      if (hour >= 12 && hour < 17) return 'Good Afternoon';
      if (hour >= 17 && hour < 21) return 'Good Evening';
      return 'Good Night';
    }
  }

  Widget _buildGreetingHeader(AppStrings tr, UserModel? user) {
    final greeting = _getTimeGreeting(tr.isId);
    final rawName = user?.displayName.trim() ?? '';
    final fullName = (rawName.isNotEmpty && rawName.toLowerCase() != 'hansendusenov')
        ? rawName
        : (user?.email == 'hansendusenov@gmail.com' ? 'Hansen Dusenov' : (rawName.isNotEmpty ? rawName : (user?.email.split('@').first ?? 'Sobat Kuliner')));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$greeting, $fullName! 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tr.isId
                ? 'Mau makan apa sesuai suasana hatimu saat ini?'
                : 'What would you like to eat to match your current mood?',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final comfortRestaurantsAsync = ref.watch(nearbyComfortRestaurantsProvider);
    final voucherState = ref.watch(activeVoucherProvider);
    final userLocation = ref.watch(userLocationProvider);
    final authUser = ref.watch(authUserProvider);
    final homeScrollController = ref.watch(homeScrollControllerProvider);
    final lang = ref.watch(appLanguageProvider);
    final tr = AppStrings.of(lang);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop ? null : _buildTopAppBar(context, voucherState, userLocation, tr),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1080 : double.infinity),
            child: SingleChildScrollView(
              controller: homeScrollController,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32.0 : 0.0,
                vertical: isDesktop ? 24.0 : 0.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Voucher Floating Notification Banner (if claimed)
                  if (voucherState.isActive) _buildActiveVoucherBar(context, voucherState, tr),

                  // Time-based Greeting with User Full Name
                  _buildGreetingHeader(tr, authUser),

                  // Banners Carousel
                  _buildBannersSection(bannersAsync),
                  const SizedBox(height: 16),

                  // Omni-Input Sentiment Search Bar
                  _buildOmniSearchBar(tr, lang),
                  const SizedBox(height: 20),

                  // Quick Mood Chips Carousel
                  _buildQuickMoodsSection(tr),
                  const SizedBox(height: 24),

                  // Curated Comfort Food Nearest Restaurants Section (~10 restaurants)
                  _buildCuratedComfortSection(comfortRestaurantsAsync, tr),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(
    BuildContext context,
    ActiveVoucherState voucherState,
    UserLocation userLocation,
    AppStrings tr,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.redBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset('assets/images/moodeats_mascot.png', width: 22, height: 22, fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          const Text(
            'MoodEats',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Location Badge (Interactive with live GPS)
          GestureDetector(
            onTap: () => _showLocationPickerSheet(context, userLocation, tr),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width >= 800 ? 320 : 185),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    userLocation.isGpsAcquired ? Icons.my_location : Icons.location_on,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      userLocation.displayLabel.isEmpty ? tr.detectingLocation : userLocation.displayLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary),
          onPressed: () {
            ref.read(mainTabProvider.notifier).state = 3;
          },
        ),
      ],
    );
  }

  Widget _buildActiveVoucherBar(BuildContext context, ActiveVoucherState voucherState, AppStrings tr) {
    return BouncyTap(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => VoucherCountdownDialog(
            merchantName: voucherState.merchantName ?? 'Merchant Sponsor',
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    voucherState.discountText != null && voucherState.discountText!.isNotEmpty
                        ? '${tr.activeVoucherSticky} : ${voucherState.voucherCode} (${voucherState.discountText})'
                        : '${tr.activeVoucherSticky} : ${voucherState.voucherCode}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          voucherState.formattedTime,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BouncyTap(
              scaleFactor: 0.85,
              onTap: () {
                ref.read(activeVoucherProvider.notifier).cancelVoucher();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannersSection(AsyncValue<List<BannerModel>> bannersAsync) {
    return bannersAsync.when(
      loading: () => Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) {
        final cached = AppCacheService.getCachedBanners();
        if (cached.isNotEmpty) {
          return _buildBannersContent(cached);
        }
        return const SizedBox.shrink();
      },
      data: (banners) {
        final displayBanners = banners.isNotEmpty ? banners : AppCacheService.getCachedBanners();
        if (displayBanners.isEmpty) return const SizedBox.shrink();
        return _buildBannersContent(displayBanners);
      },
    );
  }

  Widget _buildBannersContent(List<BannerModel> banners) {
    return Column(
          children: [
            SizedBox(
              height: 145,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _currentBannerIndex = i),
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          index % 2 == 0 ? const Color(0xFFDC2626) : const Color(0xFF991B1B),
                          const Color(0xFFEF4444),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PROMO SPESIAL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                banner.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner.targetCity ?? 'Diskon Kuliner Jakarta',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Image.asset('assets/images/moodeats_mascot.png', width: 56, height: 56, fit: BoxFit.contain),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => Container(
                  width: _currentBannerIndex == i ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
  }

  Widget _buildOmniSearchBar(AppStrings tr, AppLanguage lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderRed),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr.whatDoYouFeel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_isListening) ...[
                const SizedBox(width: 8),
                Text(
                  '🎙️ ${tr.listeningVoice}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            maxLines: 2,
            textInputAction: TextInputAction.send,
            onSubmitted: (val) => _executeAgentSearch(val, tr),
            decoration: InputDecoration(
              hintText: tr.curhatPlaceholder,
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          _buildDietaryFilterBar(tr, lang),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.mic,
                  color: _isListening ? AppColors.primary : AppColors.textSecondary,
                ),
                tooltip: tr.voiceInput,
                onPressed: () => _openVoiceSheet(tr),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary),
                tooltip: tr.foodPhoto,
                onPressed: () => _openCameraSheet(tr),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  tr.findFoodBtn,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                onPressed: () => _executeAgentSearch(_searchController.text, tr),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryFilterBar(AppStrings tr, AppLanguage lang) {
    final prefs = ref.watch(userPreferencesProvider);
    final isId = lang == AppLanguage.id;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Halal Toggle Chip
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(userPreferencesProvider.notifier).toggleHalalOnly();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: prefs.isHalalOnly ? const Color(0xFFDCFCE7) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: prefs.isHalalOnly ? const Color(0xFF16A34A) : Colors.grey.shade300,
                  width: prefs.isHalalOnly ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prefs.isHalalOnly ? '🟢' : '⚪',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isId ? 'Wajib Halal' : 'Halal Only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: prefs.isHalalOnly ? FontWeight.w800 : FontWeight.w600,
                      color: prefs.isHalalOnly ? const Color(0xFF15803D) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Open Now Toggle Chip
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(userPreferencesProvider.notifier).toggleOpenNowOnly();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: prefs.isOpenNowOnly ? const Color(0xFFEFF6FF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: prefs.isOpenNowOnly ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                  width: prefs.isOpenNowOnly ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prefs.isOpenNowOnly ? '🕒' : '⚪',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isId ? 'Buka Sekarang' : 'Open Now',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: prefs.isOpenNowOnly ? FontWeight.w800 : FontWeight.w600,
                      color: prefs.isOpenNowOnly ? const Color(0xFF1D4ED8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Dietary Style Chip
          GestureDetector(
            onTap: () => DietaryPreferencesModal.show(context, lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: prefs.dietaryType != 'none'
                    ? AppColors.redBg
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: prefs.dietaryType != 'none'
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  width: prefs.dietaryType != 'none' ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prefs.getDietaryLabel(lang),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: prefs.dietaryType != 'none'
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: prefs.dietaryType != 'none'
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Allergies chip if any
          if (prefs.allergies.isNotEmpty) ...[
            GestureDetector(
              onTap: () => DietaryPreferencesModal.show(context, lang),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD97706)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(
                      isId ? '${prefs.allergies.length} Pantangan' : '${prefs.allergies.length} Excluded',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Filter Settings Icon Button
          GestureDetector(
            onTap: () => DietaryPreferencesModal.show(context, lang),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    isId ? 'Atur' : 'Edit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMoodsSection(AppStrings tr) {
    final quickMoods = _getQuickMoods(tr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            tr.quickMoodTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: quickMoods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mood = quickMoods[index];
              final isRoulette = mood['query'] == 'ROULETTE';

              return ActionChip(
                backgroundColor: isRoulette ? AppColors.redBg : Colors.white,
                side: BorderSide(
                  color: isRoulette ? AppColors.primary : AppColors.border,
                ),
                label: Text(
                  mood['label']!,
                  style: TextStyle(
                    fontWeight: isRoulette ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                    color: isRoulette ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                onPressed: () => _handleQuickMoodTap(mood, tr),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCuratedComfortSection(AsyncValue<List<PlaceModel>> comfortAsync, AppStrings tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                tr.comfortFoodTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      tr.availableInYourArea,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        comfortAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 10),
                  Text(
                    'Mencari restoran terdekat...',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          error: (err, _) {
            debugPrint('Error loading comfort food places: $err');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  tr.isId
                      ? 'Gagal memuat rekomendasi terdekat. Coba refresh.'
                      : 'Unable to load nearby restaurants. Please refresh.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            );
          },
          data: (places) {
            if (places.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    tr.isId ? 'Belum ada restoran terdekat ditemukan' : 'No nearby restaurants found',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              );
            }
            return _buildComfortRestaurantsList(places, tr);
          },
        ),
      ],
    );
  }

  Widget _buildComfortRestaurantsList(List<PlaceModel> places, AppStrings tr) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    if (isDesktop) {
      final crossAxisCount = screenWidth >= 1150 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: places.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 2.3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (context, index) {
          final place = places[index];
          return _buildComfortRestaurantCard(place, tr);
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final place = places[index];
        return _buildComfortRestaurantCard(place, tr);
      },
    );
  }

  Widget _buildComfortRestaurantCard(PlaceModel place, AppStrings tr) {
    return BouncyTap(
      onTap: () {
        _searchController.text = tr.isId
            ? 'Cari menu dan suasana di ${place.name}, ${place.category}'
            : 'Explore menu and atmosphere at ${place.name}, ${place.category}';
        _executeAgentSearch(_searchController.text, tr);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Image.network(
                  place.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.redBg,
                    child: const Center(
                      child: Text('🍲', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade300, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Category & Distance
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          place.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      const Icon(Icons.location_on, size: 11, color: AppColors.primary),
                      Text(
                        '${place.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Address
                  Text(
                    place.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Open Status & Actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: place.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          place.isOpen
                              ? (tr.isId ? 'Buka' : 'Open')
                              : (tr.isId ? 'Tutup' : 'Closed'),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: place.isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Maps Button
                      if (place.actionLinks.googleMaps != null)
                        GestureDetector(
                          onTap: () => _openExternalLink(place.actionLinks.googleMaps!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined, size: 11, color: AppColors.textPrimary),
                                SizedBox(width: 3),
                                Text(
                                  'Maps',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      // Delivery Button
                      GestureDetector(
                        onTap: () {
                          final delUrl = (place.actionLinks.deliveryApp != null &&
                                  place.actionLinks.deliveryApp!.isNotEmpty &&
                                  !place.actionLinks.deliveryApp!.contains('gofood.link'))
                              ? place.actionLinks.deliveryApp!
                              : 'https://gofood.co.id/jakarta/search?q=${Uri.encodeComponent(place.name)}';
                          _openExternalLink(delUrl);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00AA13),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delivery_dining, size: 11, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                tr.isId ? 'Pesan' : 'Order',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch url $url: $e');
    }
  }

  void _showLocationPickerSheet(BuildContext context, UserLocation currentLocation, AppStrings tr) {
    showLocationPickerSheet(
      context: context,
      ref: ref,
      currentLocation: currentLocation,
      tr: tr,
    );
  }
}

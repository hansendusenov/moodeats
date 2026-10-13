import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moodeats_app/core/constants/app_colors.dart';
import 'package:moodeats_app/core/localization/app_language.dart';
import 'package:moodeats_app/core/localization/app_strings.dart';
import 'package:moodeats_app/data/services/firebase_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleOAuthScreen extends ConsumerStatefulWidget {
  final String? initialAuthUrl;

  const GoogleOAuthScreen({
    super.key,
    this.initialAuthUrl,
  });

  @override
  ConsumerState<GoogleOAuthScreen> createState() => _GoogleOAuthScreenState();
}

class _GoogleOAuthScreenState extends ConsumerState<GoogleOAuthScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _authUrl;
  bool _isProcessingAuth = false;

  @override
  void initState() {
    super.initState();
    _initOAuth();
  }

  Future<void> _initOAuth() async {
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final url = widget.initialAuthUrl ?? await authService.createGoogleOAuthUri();
      setState(() {
        _authUrl = url;
      });

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 14; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() {
                _isLoading = true;
              });
              _checkRedirect(url);
            },
            onPageFinished: (url) {
              setState(() {
                _isLoading = false;
              });
              _checkRedirect(url);
            },
            onUrlChange: (change) {
              if (change.url != null) {
                _checkRedirect(change.url!);
              }
            },
            onNavigationRequest: (request) {
              if (_checkRedirect(request.url)) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      setState(() => _controller = controller);
    } catch (e) {
      debugPrint('Error init OAuth: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _checkRedirect(String url) {
    if (_isProcessingAuth) return false;

    // Check if redirected to Firebase Auth Handler or contains token
    if (url.contains('firebaseapp.com/__/auth/handler') ||
        url.contains('id_token=') ||
        url.contains('oauth_callback')) {
      _processOAuthResult(url);
      return true;
    }
    return false;
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding JWT payload: $e');
      return null;
    }
  }

  String? _extractParam(String url, String param) {
    try {
      final regExp = RegExp('$param=([^&#]+)');
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return Uri.decodeComponent(match.group(1)!);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _processOAuthResult(String url) async {
    if (_isProcessingAuth) return;
    setState(() => _isProcessingAuth = true);

    try {
      String? idToken = _extractParam(url, 'id_token');
      String? extractedEmail = _extractParam(url, 'email') ?? _extractParam(url, 'login_hint');
      String? extractedName;

      if (idToken == null || idToken.isEmpty) {
        final uri = Uri.parse(url);
        if (uri.fragment.isNotEmpty) {
          final frag = Uri.splitQueryString(uri.fragment);
          idToken = frag['id_token'];
        }
        idToken ??= uri.queryParameters['id_token'];
        extractedEmail ??= uri.queryParameters['email'];
      }

      // Decode claims from Google JWT to extract real user email & name
      if (idToken != null && idToken.isNotEmpty) {
        final payload = _decodeJwtPayload(idToken);
        if (payload != null) {
          if (payload['email'] != null) {
            extractedEmail = (payload['email'] as String).trim().toLowerCase();
          }
          if (payload['name'] != null) {
            extractedName = payload['name'] as String;
          } else if (payload['given_name'] != null) {
            extractedName = payload['given_name'] as String;
          }
        }
      }

      final authService = ref.read(firebaseAuthServiceProvider);
      AuthResult? result;

      if (idToken != null && idToken.isNotEmpty) {
        result = await authService.signInWithGoogleOAuthToken(
          idToken: idToken,
          fallbackEmail: extractedEmail,
          fallbackDisplayName: extractedName,
        );
      } else if (extractedEmail != null && extractedEmail.isNotEmpty) {
        result = await authService.completeGoogleSignIn(
          email: extractedEmail,
          displayName: extractedName,
        );
      } else {
        throw Exception('Tidak ada akun Google yang berhasil diverifikasi.');
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      debugPrint('Error processing OAuth result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop(null);
      }
    } finally {
      if (mounted) setState(() => _isProcessingAuth = false);
    }
  }

  Future<void> _openExternalBrowser() async {
    if (_authUrl != null) {
      final uri = Uri.parse(_authUrl!);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4285F4))),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Google Sign-In (Firebase)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _openExternalBrowser,
            icon: const Icon(Icons.open_in_browser, size: 16, color: AppColors.primary),
            label: Text(
              lang == AppLanguage.id ? 'Buka Browser' : 'Open Browser',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          if (_isLoading || _isProcessingAuth)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      _isProcessingAuth
                          ? (lang == AppLanguage.id ? 'Memverifikasi akun Google dengan Firebase...' : 'Verifying Google account with Firebase...')
                          : (lang == AppLanguage.id ? 'Memuat Google OAuth...' : 'Loading Google OAuth...'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
}

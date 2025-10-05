// forgot_password.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:trashvisor/core/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:trashvisor/globals.dart';
import 'create_new_password.dart';

// --- Konstan & Dimensi ---
class LoginDimens {
  static const double bannerSideMargin = 24.0;
  static const Duration bannerShowTime = Duration(
    seconds: 4,
  ); // DURASI BANNER DITAMBAHKAN
  static const Duration bannerAnimDuration = Duration(
    milliseconds: 300,
  ); // DURASI ANIMASI DITAMBAHKAN
}

const String _logoPath = 'assets/images/logo_apk.png';
const String _illustrationPath =
    'assets/images/login_and_register/send_email.png';

final RegExp _isValidEmailRegex = RegExp(
  r"^[a-zA-Z0-9.a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$",
);

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (Platform.isAndroid) {
      return GlowingOverscrollIndicator(
        axisDirection: details.direction,
        color: Colors.transparent,
        child: child,
      );
    }
    return super.buildOverscrollIndicator(context, child, details);
  }
}

// Halaman Lupa Password
class ForgotPasswordScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ForgotPasswordScreen({super.key, required this.cameras});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  String? _emailErrorText;
  bool _isLoading = false;

  final SupabaseClient supabase = Supabase.instance.client;

  // *** VARIABEL TOP BANNER DIKEMBALIKAN (DITAMBAH DEFIINSI) ***
  late AnimationController _bannerCtl;
  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;
  String _bannerMessage = '';
  // ************************************************************

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmailLive);

    // Inisialisasi AnimationController
    _bannerCtl = AnimationController(
      vsync: this,
      duration: LoginDimens.bannerAnimDuration,
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmailLive);
    _emailController.dispose();
    _bannerCtl.dispose();
    _bannerTimer?.cancel();
    _bannerEntry?.remove(); // Pastikan entry dihapus saat dispose
    super.dispose();
  }

  // ---------------------- Fungsi Show Top Banner (ASLI ANDA) ----------------------
  void _showTopBanner(
    String message, {
    Color bg =
        AppColors.errorBg, // Diubah default ke Colors.red/white untuk kemudahan
    Color fg = AppColors.errorText,
  }) {
    // Cari Overlay menggunakan GlobalKey yang sudah diimpor
    final OverlayState? overlay = navigatorKey.currentState?.overlay;

    if (overlay == null) {
      // Fallback: Jika Overlay tidak dapat ditemukan, gunakan Snackbar standar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message'), backgroundColor: bg),
      );
      return;
    }

    _bannerTimer?.cancel();
    _bannerMessage = message;

    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    const left = LoginDimens.bannerSideMargin;
    const right = LoginDimens.bannerSideMargin;

    if (_bannerEntry == null) {
      _bannerEntry = OverlayEntry(
        builder: (_) {
          return Positioned(
            top: topPad + 8,
            left: left,
            right: right,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _bannerCtl,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ),
                  ),
              child: FadeTransition(
                opacity: _bannerCtl,
                child: Material(
                  color: bg,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _bannerMessage,
                            style: TextStyle(
                              color: fg,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(_bannerEntry!);
    } else {
      _bannerEntry!.markNeedsBuild();
    }

    _bannerCtl.forward(from: 0);

    // Auto-dismiss setelah durasi
    _bannerTimer = Timer(LoginDimens.bannerShowTime, () {
      _bannerCtl.reverse().then((_) {
        _bannerEntry?.remove();
        _bannerEntry = null;
      });
    });
  }

  // ---------------------- Sembunyikan top-banner (ASLI ANDA) ----------------------
  void _hideTopBanner() {
    _bannerTimer?.cancel();
    if (_bannerCtl.isAnimating || _bannerCtl.isCompleted) {
      _bannerCtl.reverse().then((_) {
        _bannerEntry?.remove();
        _bannerEntry = null;
      });
    } else {
      _bannerEntry?.remove();
      _bannerEntry = null;
    }
  }

  // ---------------------- Fungsi Validasi ----------------------
  bool _isValidEmail(String s) {
    return _isValidEmailRegex.hasMatch(s.trim());
  }

  String? _buildEmailError(String s) {
    if (s.isEmpty) return 'Email wajib diisi!';
    if (!_isValidEmail(s)) {
      return 'Format email tidak valid. Contoh: nama@contoh.com';
    }
    return null;
  }

  void _validateEmailLive() {
    final msg = _buildEmailError(_emailController.text);
    if (msg != _emailErrorText) {
      setState(() => _emailErrorText = msg);
    }
  }

  // ---------------------- Aksi Kirim Email ----------------------
  Future<void> _sendRecoveryEmail() async {
    FocusScope.of(context).unfocus();
    _hideTopBanner(); // Sembunyikan banner lama sebelum aksi baru

    final email = _emailController.text.trim();
    final emailErr = _buildEmailError(email);

    // 1. Validasi Email
    if (emailErr != null) {
      setState(() => _emailErrorText = emailErr);
      _showTopBanner(emailErr, bg: AppColors.errorBg, fg: AppColors.errorText);
      return;
    } else {
      setState(() => _emailErrorText = null);
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const String redirectTo = 'trashvisor://update-password';
      await supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);

      if (!mounted) return;

      // 2. Tampilkan Top Banner Hijau (SUKSES)
      _showTopBanner(
        'Pesan email untuk reset password berhasil dikirim',
        bg: AppColors.successBg,
        fg: AppColors.successText,
      );

      await Future.delayed(
        LoginDimens.bannerAnimDuration + const Duration(milliseconds: 900),
      );

      if (!mounted) {
        _hideTopBanner();
        return;
      }

      _hideTopBanner();

      const String snackbarBiruMessage =
          'Silakan periksa kotak masuk email Anda untuk reset password!';

      final userEmail = _emailController.text.trim();

      // 3. Navigasi ke CreateNewPasswordScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CreateNewPasswordScreen(
            cameras: widget.cameras,
            isFromEmailLink: false,
            resendAttemptCount: 0,
            initialMessage: snackbarBiruMessage,
            email: userEmail,
          ),
        ),
      );
    } on AuthException catch (e) {
      // --- ALUR GAGAL ---
      String errorMessage = e.message;
      if (e.statusCode == '429') {
        errorMessage =
            'Terlalu banyak permintaan. Coba lagi dalam beberapa menit.';
      } else if (e.statusCode == '400') {
        errorMessage = 'Email tidak ditemukan atau tidak valid di sistem kami.';
      }

      _showTopBanner(
        'Error: $errorMessage',
        bg: AppColors.errorBg,
        fg: AppColors.errorText,
      );
    } catch (e) {
      _showTopBanner(
        'Terjadi kesalahan: ${e.toString()}',
        bg: AppColors.errorBg,
        fg: AppColors.errorText,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------------- Widget Build ----------------------
  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled = _isLoading;

    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,

      // --- APP BAR (TETAP) ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 5.0),
          child: AppBar(
            elevation: 0,
            backgroundColor: AppColors.whiteSmoke,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 40,
            leading: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.fernGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.whiteSmoke,
                    size: 20,
                  ),
                  onPressed: () {
                    _hideTopBanner();
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  _logoPath,
                  height: 40,
                  errorBuilder: (_, _, _) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.fernGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 28,
                      color: AppColors.whiteSmoke,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Transform.translate(
                  offset: const Offset(0, 6),
                  child: const Text(
                    'Trashvisor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF244D24),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            titleSpacing: 0,
          ),
        ),
      ),

      // --- END APP BAR ---
      body: ScrollConfiguration(
        behavior: const NoGlowScrollBehavior(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 24),
                // ... (Widget konten lainnya tetap sama)
                const Text(
                  'Lupa Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                    color: Color(0xFF244D24),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Masukkan email untuk memulihkan akun dan melanjutkan aksi cerdas demi bumi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.75,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: Image.asset(
                      _illustrationPath,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, error, stackTrace) => const Icon(
                        Icons.email,
                        size: 80,
                        color: AppColors.darkMossGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    color: AppColors.darkMossGreen,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: _emailErrorText == null ? 52 : null,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendRecoveryEmail(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Masukkan email kamu',
                      hintStyle: const TextStyle(
                        color: Colors.black54,
                        fontFamily: 'Roboto',
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.mail_outline),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF244D24),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (_emailErrorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _emailErrorText!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // --- TOMBOL KIRIM (TETAP) ---
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isButtonDisabled ? null : _sendRecoveryEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fernGreen,
                      disabledBackgroundColor: AppColors.fernGreen,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirim',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              fontFamily: 'Nunito',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class LoginDimens {
  // ---------- HERO (ilustrasi atas) — proporsional terhadap tinggi layar ----------
  static const double heroRatioTall = 0.38;
  static const double heroRatioShort = 0.3;

  // ---------- KONTEN ----------
  static const double contentMaxWidth =
      500; // batasi lebar konten agar rapi di tablet
  static const double sidePadding = 24; // <<< UBAH padding kiri/kanan konten

  // ---------- JARAK ATAS ----------
  static const double gapAfterHero =
      -40; // <<< boleh negatif (narik konten ke atas)
  static const double brandTopGap =
      0; // padding murni di atas brand (jangan negatif)
  static const double logoTopOffset =
      -6; // geser vertikal ikon logo relatif teks

  // ---------- SPACING LAIN ----------
  static const double gapAfterBrand = 12; // jarak brand → judul
  static const double gapTitleToDesc = 10; // jarak judul → deskripsi
  static const double gapAfterDesc = 20; // jarak deskripsi → field pertama
  static const double gapBetweenFields = 16; // jarak antar field
  static const double gapBeforeButton = 20; // jarak field terakhir → tombol
  static const double bottomPadding = 10; // padding bawah konten

  // ---------- BRAND ----------
  static const double brandIcon = 40; // ukuran logo
  static const EdgeInsets brandTextMargin = EdgeInsets.only(
    left: 15,
  ); // jarak teks dari logo

  // ---------- TIPOGRAFI ----------
  static const double title = 22;
  static const double body = 14;

  // ---------- FIELD & BUTTON ----------
  static const double fieldHeight = 52; // tinggi TextField
  static const double fieldRadius = 14; // radius TextField
  static const EdgeInsets fieldContentPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 14,
  );
  static const double btnHeight = 54; // tinggi tombol
  static const double btnRadius = 16; // radius tombol

  // ---------- TOP-BANNER (animasi & posisi) ----------
  static const Duration bannerInDuration = Duration(
    milliseconds: 220,
  ); // durasi masuk
  static const Duration bannerOutDuration = Duration(
    milliseconds: 180,
  ); // durasi keluar
  static const Duration bannerShowTime = Duration(
    milliseconds: 5000,
  ); // lama tampil
  static const double bannerSideMargin = 12; // jarak kiri/kanan
  static const Duration bannerAnimDuration = Duration(
    milliseconds: 300,
  ); // Durasi Animasi
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.darkMossGreen,
        fontWeight: FontWeight.bold,
        fontFamily: 'Nunito',
        fontSize: 14,
      ),
    );
  }
}

/// Custom TextField untuk layout ini
class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final String? errorText;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.textInputAction,
    this.errorText, // Ditambahkan untuk menampilkan error
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: AppColors.black,
        fontFamily: 'Roboto',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.white,
        hintText: hint,
        errorText: errorText, // Tampilkan error text
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Roboto',
          fontSize: 14,
        ),
        contentPadding: LoginDimens.fieldContentPadding,
        prefixIcon: prefix,
        suffixIcon: suffix,
        // Border akan berubah otomatis jika ada errorText
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(LoginDimens.fieldRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.deepGreen, width: 1.2),
          borderRadius: BorderRadius.circular(LoginDimens.fieldRadius),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
          borderRadius: BorderRadius.circular(LoginDimens.fieldRadius),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade900, width: 1.5),
          borderRadius: BorderRadius.circular(LoginDimens.fieldRadius),
        ),
        errorStyle: TextStyle(
          color: Colors.red.shade700,
          fontSize: 12,
          height: 1.3,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}

/// Logo dan nama aplikasi di bagian atas konten
class _BrandHeader extends StatelessWidget {
  final String assetPath;
  final String text;

  const _BrandHeader({required this.assetPath, required this.text});

  @override
  Widget build(BuildContext context) {
    const double iconSize = LoginDimens.brandIcon;
    const EdgeInsets textMargin = LoginDimens.brandTextMargin;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, LoginDimens.logoTopOffset),
          child: Image.asset(
            assetPath,
            height: iconSize,
            errorBuilder: (_, _, _) => Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.fernGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.eco, size: iconSize * 0.7, color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: textMargin,
          child: const Text(
            'Trashvisor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGreen,
              fontFamily: 'Nunito',
            ),
          ),
        ),
      ],
    );
  }
}

// (NEW) Widget untuk menampilkan status ketentuan password
class _PasswordRequirementIndicator extends StatelessWidget {
  final String label;
  final bool isMet;

  const _PasswordRequirementIndicator({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    // Warna akan berubah menjadi hijau sukses jika terpenuhi (isMet=true)
    final color = isMet ? Color(0xFF244D24) : AppColors.isMet;
    // Ikon akan berubah dari lingkaran (belum) menjadi centang (sudah)
    final icon = isMet ? Icons.check_circle_rounded : Icons.circle_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Penting agar tidak melebar
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color, fontFamily: 'Roboto'),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// LAYOUT UTAMA: CreateNewPasswordScreen
// ===================================================================

class CreateNewPasswordScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isFromEmailLink;
  final int resendAttemptCount;
  final String email;
  final String? initialMessage;

  const CreateNewPasswordScreen({
    super.key,
    required this.cameras,
    this.isFromEmailLink = true,
    this.resendAttemptCount = 0,
    required this.email,
    this.initialMessage,
  });

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Instance Supabase
  final SupabaseClient supabase = Supabase.instance.client;

  final _newPassC = TextEditingController();
  final _confirmPassC = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isResending = false;

  String? _newPassError;
  String? _confirmPassError;

  // Variabel Top Banner
  late AnimationController _bannerCtl;
  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;
  String _bannerMessage = '';

  Timer? _resendTimer;
  int _resendCooldownSeconds = 0;
  int _resendAttemptCount = 0;

  String _formatDuration(int seconds) {
    if (seconds <= 60) {
      return seconds.toString();
    } else {
      // Hitung menit (e.g., 3600 detik / 60 = 60 menit)
      final minutes = seconds ~/ 60; 
        
      // Hitung sisa detik (e.g., 3600 % 60 = 0 detik)
      final remainingSeconds = seconds % 60; 

      // Format menit dan detik dengan padding nol
      final minuteString = minutes.toString().padLeft(2, '0');
      final secondString = remainingSeconds.toString().padLeft(2, '0');
        
      return '$minuteString:$secondString';
    }
  }

  // Kriteria Password
  static const int _minPassLength = 8;

  // States untuk validasi dinamis password
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _bannerCtl = AnimationController(
      vsync: this,
      duration: LoginDimens.bannerAnimDuration,
    )..addStatusListener((status) {
    // Logika ini yang akan menghapus OverlayEntry setelah animasi reverse selesai
      if (status == AnimationStatus.dismissed) {
        _bannerEntry?.remove();
        _bannerEntry = null;
        _bannerTimer?.cancel();
      }
    });
    _newPassC.addListener(_validateLive);
    _confirmPassC.addListener(_validateLive);
    _newPassC.addListener(_validatePasswordRealTime);

    if (!widget.isFromEmailLink) {
      final int initialDuration = widget.resendAttemptCount >= 2 ? 3600 : 60;
      _startResendCooldown(initialDuration);
    }

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      debugPrint('DEBUG: initialMessage Diterima: ${widget.initialMessage}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTopBanner(
            widget.initialMessage!,
            bg: Colors.blue,
            fg: Colors.white,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _newPassC.removeListener(_validateLive);
    _confirmPassC.removeListener(_validateLive);
    _newPassC.removeListener(_validatePasswordRealTime);

    _newPassC.dispose();
    _confirmPassC.dispose();

    _bannerCtl.dispose();
    _bannerTimer?.cancel();
    _bannerEntry?.remove();

    _cancelResendCooldown();

    super.dispose();
  }

  // ---------------------- Fungsi Show Top Banner (TIDAK BERUBAH) ----------------------
  void _showTopBanner(
    String message, {
    Color bg = AppColors.errorBg,
    Color fg = AppColors.errorText,
  }) {
    _bannerTimer?.cancel();
    _bannerCtl.stop();
    _bannerEntry?.remove();
    _bannerEntry = null;
    
    final OverlayState? overlay = navigatorKey.currentState?.overlay;

    if (overlay == null) {
      // Fallback safety check jika Overlay belum siap (walaupun jarang terjadi)
      debugPrint(
        'ERROR: OverlayState tidak ditemukan. Gagal menampilkan banner.',
      );
      return;
    }

    _bannerTimer?.cancel(); // reset timer (kalau ada banner yang masih jalan)
    _bannerMessage = message; // simpan pesan yang mau ditampilkan

    final media = MediaQuery.of(context);
    final topPad = media.padding.top; // SafeArea atas (hindari notch)
    final left = LoginDimens.bannerSideMargin;
    final right = LoginDimens.bannerSideMargin;

    if (_bannerEntry == null) {
      // Buat OverlayEntry SEKALI → builder akan membaca _bannerMessage saat rebuild
      _bannerEntry = OverlayEntry(
        builder: (_) {
          return Positioned(
            top: topPad + 8, // posisi dari atas
            left: left, // jarak kiri (UBAH di Dimens)
            right: right, // jarak kanan (UBAH di Dimens)
            child: SlideTransition(
              // ANIMASI GESER VERTIKAL
              position:
                  Tween<Offset>(
                    begin: const Offset(0, -0.2), // start sedikit di atas
                    end: Offset.zero, // berakhir tepat di posisinya
                  ).animate(
                    CurvedAnimation(
                      parent: _bannerCtl,
                      curve: Curves.easeOutCubic, // easing saat masuk
                      reverseCurve: Curves.easeInCubic, // easing saat keluar
                    ),
                  ),
              child: FadeTransition(
                // ANIMASI FADE
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
                          Icons.error_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        // NOTE: Text membaca _bannerMessage yang bisa berubah
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
      // Masukkan overlay ke atas layar
      overlay.insert(_bannerEntry!);
    } else {
      // Overlay sudah ada → minta rebuild agar pesan terbarui
      _bannerEntry!.markNeedsBuild();
    }

    // Mainkan animasi masuk dari awal
    _bannerCtl.forward(from: 0);

    // Auto-dismiss setelah durasi yang ditentukan
    _bannerTimer = Timer(LoginDimens.bannerShowTime, () {
      _bannerCtl.reverse();
    });
  }

  // ---------------------- Sembunyikan top-banner (TIDAK BERUBAH) ----------------------
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

  // (NEW) FUNGSI VALIDASI REAL-TIME UNTUK INDIKATOR
  void _validatePasswordRealTime() {
    if (!mounted) return;

    final password = _newPassC.text;

    // Kriteria 1: Minimal 8 Karakter
    final minLength = password.length >= _minPassLength;

    // Kriteria 2: Mengandung 1 Huruf Besar (Uppercase)
    // RegExp(r'[A-Z]') memeriksa apakah ada karakter A-Z
    final uppercase = RegExp(r'[A-Z]').hasMatch(password);

    // Kriteria 3: Mengandung 1 Angka
    // RegExp(r'[0-9]') memeriksa apakah ada karakter 0-9
    final number = RegExp(r'[0-9]').hasMatch(password);

    // Kriteria Gabungan (untuk tombol submit, akan dicek di _isFormValid)
    // final isValid = minLength && uppercase && number;

    // Update state untuk merefresh indikator
    setState(() {
      _hasMinLength = minLength;
      _hasUppercase = uppercase;
      _hasNumber = number;
    });
  }

  // ---------------------- LOGIKA VALIDASI ----------------------
  // (MODIFIED) Validasi untuk Supabase API (akan ditambahkan cek Huruf Besar dan Angka)
  String? _validateNewPassword(String s) {
    if (s.isEmpty) return 'Password wajib diisi.';
    if (s.length < _minPassLength) {
      return 'Password minimal $_minPassLength karakter.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(s)) {
      return 'Password harus mengandung minimal satu huruf kapital.';
    }
    if (!RegExp(r'[0-9]').hasMatch(s)) {
      return 'Password harus mengandung minimal satu angka.';
    }
    return null;
  }

  String? _validateConfirmPassword(String s) {
    if (s.isEmpty) return 'Konfirmasi password wajib diisi.';
    if (s != _newPassC.text) {
      return 'Konfirmasi password tidak cocok dengan password baru.';
    }
    return null;
  }

  void _validateLive() {
    final newMsg = _validateNewPassword(_newPassC.text);
    final confirmMsg = _validateConfirmPassword(_confirmPassC.text);

    if (newMsg != _newPassError || confirmMsg != _confirmPassError) {
      setState(() {
        _newPassError = newMsg;
        _confirmPassError = confirmMsg;
      });
    }
  }

  bool _isFormValid() {
    final newPass = _newPassC.text;
    final confirmPass = _confirmPassC.text;

    final newErr = _validateNewPassword(newPass);
    final confirmErr = _validateConfirmPassword(confirmPass);

    setState(() {
      _newPassError = newErr;
      _confirmPassError = confirmErr;
    });

    return newErr == null && confirmErr == null;
  }

  // ---------------------- Aksi Kirim/Submit (TIDAK BERUBAH) ----------------------
  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    _hideTopBanner();

    if (!_isFormValid()) {
      final firstError = _newPassError ?? _confirmPassError;
      if (firstError != null) {
        _showTopBanner(
          firstError,
          bg: AppColors.errorBg,
          fg: AppColors.errorText,
        );
      }
      return;
    }

    // --- MULAI PROSES RESET PASSWORD NYATA ---
    setState(() {
      _isLoading = true;
    });

    final newPass = _newPassC.text;

    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPass),
      );

      if (response.user != null) {
        if (!mounted) return;

        // LOGIKA SUKSES NYATA
        _showTopBanner(
          'Password berhasil diperbarui! Silakan login dengan password baru.',
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

        rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar(
          reason: SnackBarClosedReason.remove
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              cameras: widget.cameras,
              initialMessage: 'Password berhasil diubah. Silakan masuk.',
            ),
          ),
        );
      } else {
        // Jika user null (jarang terjadi pada update sukses), berikan pesan default
        throw const AuthException('Gagal memperbarui password. Coba kembali.');
      }
    } on AuthException catch (error) {
      // --- LOGIKA GAGAL NYATA: Error Autentikasi Supabase ---
      String errorMessage = error.message.toLowerCase(); // Ambil pesan dan ubah ke lowercase

      String translatedMessage;

      if (errorMessage.contains('user already has a password')) {
          translatedMessage = 'Pengguna sudah memiliki password. Silakan coba login.';
      } else if (errorMessage.contains('password should be at least')) {
          translatedMessage = 'Password terlalu pendek. Pastikan password minimal 6 karakter.';
      } else if (errorMessage.contains('invalid login credentials')) {
          translatedMessage = 'Email atau password salah. Mohon periksa kembali.';
      } else if (errorMessage.contains('email not confirmed')) {
          translatedMessage = 'Akun belum terverifikasi. Mohon cek email Anda untuk verifikasi.';
      } else if (errorMessage.contains('network request failed')) {
          translatedMessage = 'Koneksi jaringan gagal. Mohon periksa koneksi internet Anda.';
      } else if (errorMessage.contains('user not found')) {
          translatedMessage = 'Pengguna tidak ditemukan. Email yang Anda masukkan tidak terdaftar.';
      } else if (errorMessage.contains('token has expired')) {
          translatedMessage = 'Link pemulihan kadaluarsa. Silakan coba minta pemulihan password lagi.';
      } else if (errorMessage.contains('invalid token')) {
          translatedMessage = 'Token tidak valid atau sudah digunakan. Silakan minta link baru.';
      } else {
          // Fallback untuk error yang tidak terduga
          translatedMessage = 'Gagal memperbarui password. Error tidak dikenal: ${error.message}';
      }

      _showTopBanner(
          'Error: $translatedMessage',
          bg: AppColors.errorBg,
          fg: AppColors.errorText,
      );
    } catch (e) {
      // Tangani error umum (misalnya: network, error parsing)
      _showTopBanner(
        'Terjadi kesalahan: ${e.toString()}',
        bg: AppColors.errorBg,
        fg: AppColors.errorText,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startResendCooldown(int durationInSeconds) {
    if (_resendTimer?.isActive ?? false) return;

    setState(() {
      _resendCooldownSeconds = durationInSeconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldownSeconds == 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() {
          _resendCooldownSeconds--;
        });
      }
    });
  }

  void _cancelResendCooldown() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  // ---------------------- Fungsi Kirim Ulang OTP/Email (TIDAK BERUBAH) ----------------------
  Future<void> _resendPasswordEmail() async {
      // VVV--- PASTIKAN WIDGET ANDA MEMILIKI properti final String email; ---VVV
      final email = widget.email; 
      
      // 1. Cek Pra-kondisi & Cooldown
      if (_resendCooldownSeconds > 0) return; // Tombol harusnya disabled, tapi ini pengamanan
      
      // Cek apakah email tersedia
      if (email.isEmpty) {
          _showTopBanner('Alamat email tidak ditemukan.', bg: AppColors.errorBg, fg: AppColors.errorText);
          return;
      }
      
      if (widget.isFromEmailLink) {
        _showTopBanner(
          'Fitur kirim ulang tidak diperlukan jika Anda berasal dari tautan email.',
          bg: Colors.orange,
          fg: Colors.white,
        );
        return;
      }

      _hideTopBanner();
      setState(() {
        _isResending = true;
      });

      try {
        const String redirectTo = 'trashvisor://update-password';
        
        // *** FUNGSI SUPABASE ASLI: Mengirim ulang link reset baru ***
        // Link baru akan menggantikan/membatalkan link reset yang lama.
        await supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: redirectTo,
        );

        if (!mounted) return;
        
        // 2. Tampilkan Sukses & Update State
        setState(() {
          _isLoading = false;
          _resendAttemptCount++; // Tambah hitungan percobaan
        });

        _showTopBanner(
          'Email untuk reset password berhasil dikirim ulang.',
          bg: AppColors.successBg,
          fg: AppColors.successText,
        );

        // 3. Tentukan & Mulai Cooldown Baru
        // Jika _resendAttemptCount (setelah penambahan) >= 3, cooldown 1 jam (3600 detik).
        final int nextDuration = _resendAttemptCount >= 3 ? 3600 : 60; 
        
        _startResendCooldown(nextDuration);
        
      } on AuthException catch (e) {
        if (!mounted) return;
        
        // Default message untuk error Supabase yang tidak terdefinisi
        String userFacingMessage = 'Reset password gagal. Silakan coba lagi.';
        
        // Periksa pesan error teknis dari Supabase
        if (e.message.contains('Auth session missing') || 
            e.message.contains('Invalid Refresh Token') ||
            e.message.contains('Token has expired')) {
            
            // Terjemahkan error umum sesi/link kedaluwarsa
            userFacingMessage = 'Tautan tidak valid atau sudah kedaluwarsa. Silakan minta kirim ulang email reset.';
            
        } else if (e.statusCode == '429') {
            // Logika untuk error "Too Many Requests" yang sudah ada
            userFacingMessage = 'Terlalu banyak permintaan. Coba lagi dalam beberapa menit.';
        } else {
            // Untuk error Supabase lainnya (misalnya, network issues)
            userFacingMessage = 'Kesalahan saat reset password: ${e.message}';
        }
        
        // Tampilkan pesan yang sudah dilokalisasi
        _showTopBanner(
            userFacingMessage,
            bg: AppColors.errorBg, 
            fg: AppColors.errorText,
        );
        
    } catch (e) {
        if (!mounted) return;
        _showTopBanner('Terjadi kesalahan umum: ${e.toString()}', bg: AppColors.errorBg, fg: AppColors.errorText);
    } finally {
        if (mounted) {
            setState(() {
                _isResending = false;
            });
        }
    }
  }

  // ---------------------- Widget Build (DIMODIFIKASI) ----------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isShort = size.height < 700;

    final heroH =
        size.height *
        (isShort ? LoginDimens.heroRatioShort : LoginDimens.heroRatioTall);

    final double safeTopPad = LoginDimens.gapAfterHero > 0
        ? LoginDimens.gapAfterHero
        : 0;
    final double pullUpY = LoginDimens.gapAfterHero < 0
        ? LoginDimens.gapAfterHero
        : 0;

    final bool isButtonDisabled = _isLoading;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportH = constraints.maxHeight;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =========================== HERO IMAGE ===========================
                      SizedBox(
                        height: heroH,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/login_and_register/new_password_top.png',
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          cacheWidth: size.width.ceil(),
                          filterQuality: FilterQuality.none,
                          errorBuilder: (_, _, _) =>
                              Container(color: AppColors.fernGreen),
                        ),
                      ),

                      // ========================== KONTEN UTAMA ==========================
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          LoginDimens.sidePadding,
                          safeTopPad + LoginDimens.brandTopGap,
                          LoginDimens.sidePadding,
                          LoginDimens.bottomPadding,
                        ),
                        child: Transform.translate(
                          offset: Offset(0, pullUpY),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: LoginDimens.contentMaxWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ------------------------- BRAND -------------------------
                                  const Center(
                                    child: _BrandHeader(
                                      assetPath: 'assets/images/logo_apk.png',
                                      text: 'Trashvisor',
                                    ),
                                  ),
                                  const SizedBox(
                                    height: LoginDimens.gapAfterBrand,
                                  ),

                                  // ------------------------- TITLE -------------------------
                                  const Center(
                                    child: Text(
                                      'Buat Password Baru',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: LoginDimens.title,
                                        height: 1.25,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepGreen,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: LoginDimens.gapTitleToDesc,
                                  ),

                                  // ------------------------ SUBTITLE -----------------------
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 25,
                                      ),
                                      child: Text(
                                        'Masukkan password baru untuk memulihkan '
                                        'akun dan memulai kembali aksi nyata untuk '
                                        'menyelamatkan bumi',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: LoginDimens.body,
                                          height: 1.75,
                                          color: AppColors.black,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: LoginDimens.gapAfterDesc,
                                  ),

                                  // ---------------------- PASSWORD BARU --------------------
                                  const _FieldLabel('Password Baru'),
                                  const SizedBox(height: 8),
                                  _AppTextField(
                                    controller: _newPassC,
                                    hint: 'Masukkan password baru',
                                    obscure: _obscureNew,
                                    textInputAction: TextInputAction.next,
                                    prefix: const Icon(Icons.lock_outline),
                                    errorText: _newPassError,
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () => _obscureNew = !_obscureNew,
                                      ),
                                      icon: Icon(
                                        _obscureNew
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),

                                  // (NEW) INDIKATOR KETENTUAN PASSWORD
                                  const SizedBox(height: 8),
                                  _PasswordRequirementIndicator(
                                    label: 'Minimal $_minPassLength karakter',
                                    isMet: _hasMinLength,
                                  ),
                                  _PasswordRequirementIndicator(
                                    label:
                                        'Mengandung satu huruf kapital (A-Z)',
                                    isMet: _hasUppercase,
                                  ),
                                  _PasswordRequirementIndicator(
                                    label: 'Mengandung satu angka (0-9)',
                                    isMet: _hasNumber,
                                  ),

                                  const SizedBox(
                                    // Atur jarak ke field berikutnya
                                    height: LoginDimens.gapBetweenFields,
                                  ),

                                  // ------------------ KONFIRMASI PASSWORD BARU ------------------
                                  const _FieldLabel('Konfirmasi Password Baru'),
                                  const SizedBox(height: 8),
                                  _AppTextField(
                                    controller: _confirmPassC,
                                    hint: 'Masukkan ulang password baru',
                                    obscure: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    prefix: const Icon(Icons.lock_outline),
                                    errorText: _confirmPassError,
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: LoginDimens.gapBeforeButton + 10,
                                  ),

                                  // -------------------------- BUTTON -----------------------
                                  SizedBox(
                                    width: double.infinity,
                                    height: LoginDimens.btnHeight,
                                    child: ElevatedButton(
                                      onPressed: isButtonDisabled
                                          ? null
                                          : _onSubmit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.fernGreen,
                                        disabledBackgroundColor: AppColors.fernGreen,
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            LoginDimens.btnRadius,
                                          ),
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

                                  const SizedBox(height: 10),

                                  // -------------------------- KIRIM ULANG -------------------------
                                  GestureDetector(
                                    onTap: (_resendCooldownSeconds > 0 || _isResending) ? null : _resendPasswordEmail, 
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Tidak menerima kode? ',
                                            style: TextStyle(
                                              color: AppColors.black,
                                              fontSize: 13,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          Text(
                                            _resendCooldownSeconds > 0 
                                              ? 'Kirim Ulang (${_formatDuration(_resendCooldownSeconds)})' 
                                              : 'Kirim Ulang',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Nunito',
                                              color: (_resendCooldownSeconds > 0 || _isResending)
                                                ? AppColors.darkMossGreen.withAlpha((255 * 0.5).round())
                                                : AppColors.darkMossGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ======================== END KONTEN =========================
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

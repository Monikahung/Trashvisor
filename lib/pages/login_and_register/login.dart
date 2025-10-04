import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:trashvisor/pages/login_and_register/register.dart'
    show RegisterPage;
import '../home_profile_notifications/home.dart' show HomePage;
import 'forgot_password.dart';
import 'package:trashvisor/globals.dart';
import 'package:camera/camera.dart';
import 'package:app_links/app_links.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // (NEW) Supabase auth

/// ===================================================================
///  DIMENSI / KNOB UBAHAN (semua angka tinggal diatur di sini)
///  --- BAGIAN INI ADALAH "TITIK UBAHAN" UTAMA UNTUK JARAK/UKURAN ---
/// ===================================================================
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
}

/// ===================================================================
///  LOCALE STRING (ID) — pusat semua teks banner di sini
///  SAFE TO CHANGE: Silakan edit untuk kebutuhan copywriting
/// ===================================================================
/// (NEW) Semua copy untuk error/sukses ditaruh di satu tempat agar
/// mudah dirawat/diterjemahkan di kemudian hari.
class L10n {
  static const loginInvalid =
      'Email atau kata sandi salah.'; // aman: generik (anti user-enum)
  static const emailNotConfirmed =
      'Email belum dikonfirmasi. Silakan cek kotak masuk untuk verifikasi.';
  static const userNotFound =
      'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
  static const tooManyRequests =
      'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.';
  static const networkError =
      'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
  static const unknown = 'Terjadi kesalahan. Coba lagi.';
}

/// ===================================================================
///  LOGIN PAGE — Opsi B: SATU AnimationController di-reuse
/// ===================================================================
class LoginPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  final String? initialMessage;
  final bool showResendEmail;
  final String? registeredEmail;
  final bool ignoreDeepLink;

  const LoginPage({
    super.key,
    required this.cameras,
    this.initialMessage,
    this.showResendEmail = false,
    this.registeredEmail,
    this.ignoreDeepLink = false,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // ---------------------- Controller Form ----------------------
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _obscure = true;
  bool _verificationHandled = false;

  late final AppLinks _appLinks;
  StreamSubscription? _sub;
  int _resendAttemptCount = 0;
  static const int _maxResendAttempts = 2; // Batas percobaan sebelum 1 jam

  // Link "Daftar Sekarang" (gunakan TapGestureRecognizer supaya bisa di-dispose)
  late final TapGestureRecognizer _toRegister;

  // State untuk menyimpan email yang baru didaftarkan (untuk Kirim Ulang)
  String? _resendEmail; // STATE UNTUK KIRIM ULANG EMAIL
  bool _isResending = false; // STATE UNTUK MENUNJUKKAN LOADING (JIKA PERLU)
  Timer? _resendTimer; // TIMER UNTUK MENCEGAH SPAM KIRIM ULANG
  int _resendCountdown = 0; // DETIK HITUNG MUNDUR KIRIM ULANG
  bool _isHourlyRateLimited = false; // STATE UNTUK RATE LIMIT 1 JAM
  Timer? _hourlyRateLimitTimer; // TIMER UNTUK RESET RATE LIMIT 1 JAM
  int _hourlyResendCountdown = 0; // DETIK HITUNG MUNDUR 1 JAM

  // ---------------------- Top Banner (satu controller) ----------------------
  // NOTE (OPS B): Satu controller untuk semua banner. Hindari "multiple tickers" error.
  late final AnimationController _bannerCtl; // controller animasi masuk/keluar
  OverlayEntry? _bannerEntry; // entry overlay yang ditempel ke Overlay
  Timer? _bannerTimer; // auto-dismiss timer
  String _bannerMessage = ''; // pesan aktif yang sedang ditampilkan

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    // Hanya tampilkan bagian yang relevan (H:M:S)
    if (duration.inHours > 0) {
      return '$hours jam $minutes menit';
    } else if (duration.inMinutes > 0) {
      return '$minutes menit $seconds detik';
    } else {
      return '$seconds detik';
    }
  }

  @override
  void initState() {
    super.initState();

    _verificationHandled = false;
    _resendEmail = null;
    _isResending = false;
    _isHourlyRateLimited = false;
    
    if (!widget.ignoreDeepLink) {
      _initUniLinks(); // Panggil fungsi yang mengaktifkan listener stream/initial link
    }

    // (1) Buat controller SEKALI dan di-reuse → lebih efisien & aman memory
    _bannerCtl =
        AnimationController(
          vsync: this,
          duration: LoginDimens.bannerInDuration,
          reverseDuration: LoginDimens.bannerOutDuration,
        )..addStatusListener((status) {
          // Saat animasi reverse selesai (status: dismissed) → lepas overlay agar bersih
          if (status == AnimationStatus.dismissed) {
            _bannerEntry?.remove();
            _bannerEntry = null;
            _bannerTimer?.cancel();
          }
        });

    // (2) Siapkan recognizer untuk link "Daftar Sekarang"
    _toRegister = TapGestureRecognizer()
      ..onTap = () {
        _hideTopBanner();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RegisterPage(cameras: widget.cameras),
          ),
        );
      };

    if (widget.showResendEmail && widget.registeredEmail != null) {
      _resendEmail = widget.registeredEmail;

      // Isi otomatis field email dengan email yang baru didaftarkan
      _emailC.text = widget.registeredEmail!;

      _startResendTimer();
    }

    // Tampilkan pesan sukses/instruksi dari halaman register
    if (widget.initialMessage != null) {
      // Kita gunakan Future.microtask untuk memastikan `build` sudah selesai
      // dan `Overlay` tersedia, baru banner ditampilkan.
      Future.microtask(
        () => _showTopBanner(
          widget.initialMessage!,
          bg: AppColors.successBg,
          fg: AppColors.successText,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Penting: release semua resource
    _toRegister.dispose();
    _emailC.dispose();
    _passC.dispose();

    _bannerTimer?.cancel(); // hentikan timer jika masih aktif
    _bannerCtl.dispose(); // dispose controller tunggal
    _bannerEntry?.remove(); // copot overlay jika masih ada
    _bannerEntry = null;

    _resendTimer?.cancel(); // Pastikan timer dibatalkan
    _hourlyRateLimitTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  // ---------------------- Validasi ringan ----------------------
  bool _isBlank(String s) => s.trim().isEmpty;
  bool _isValidEmail(String s) {
    // regex sederhana untuk email
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(s.trim());
  }

  // ---------------------- Tampilkan top-banner ----------------------
  void _showTopBanner(
    String message, {
    Color bg = AppColors.errorBg,
    Color fg = AppColors.errorText,
  }) {
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

  // ---------------------- Sembunyikan top-banner ----------------------
  void _hideTopBanner() {
    _bannerTimer?.cancel(); // hentikan timer jika ada
    if (_bannerCtl.isAnimating || _bannerCtl.isCompleted) {
      _bannerCtl.reverse(); // mainkan animasi keluar
    } else {
      _bannerEntry?.remove(); // langsung lepas kalau tidak ada animasi
      _bannerEntry = null;
    }
  }

  // ---------------------- Hitung Mundur (60 detik) ----------------------
  void _startResendTimer() {
    // Batalkan timer lama jika ada
    _resendTimer?.cancel();

    // Set state awal
    if (mounted) {
      setState(() {
        _resendCountdown = 60; // Set nilai awal
        _isResending = true; // Set state tombol ke disabled/countdown
      });
    }

    // Buat timer periodik yang berjalan setiap 1 detik
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        // Jika hitungan mundur selesai atau mencapai 0
        timer.cancel();
        if (mounted) {
          setState(() {
            _isResending = false;
            _resendCountdown = 0;
          });
        }
      } else {
        // Kurangi hitungan mundur setiap detik
        if (mounted) {
          setState(() {
            _resendCountdown--;
            debugPrint('Countdown: $_resendCountdown');
          });
        }
      }
    });
  }

  // ---------------------- Hitung Mundur (1 jam) ----------------------
  void _startHourlyRateLimitTimer() {
    _hourlyRateLimitTimer?.cancel();

    if (mounted) {
      setState(() {
        // Set nilai awal 1 jam (3600 detik)
        _hourlyResendCountdown = 3600;
        _isHourlyRateLimited = true;
      });
    }

    _hourlyRateLimitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_hourlyResendCountdown == 0) {
        timer.cancel(); // Hentikan timer

        setState(() {
          _isHourlyRateLimited = false;

          _resendAttemptCount = 0;

          _hourlyResendCountdown = 3600;
        });
      } else {
        setState(() {
          _hourlyResendCountdown--;
        });
      }
    });
  }

  // ---------------------- Kirim Ulang Verifikasi ----------------------
  void _resendConfirmationEmail() async {
    if (_isHourlyRateLimited) return;

    if (_resendAttemptCount >= _maxResendAttempts) {
      // Langsung panggil timer 1 jam tanpa perlu memanggil Supabase lagi
      _showTopBanner(
        'Batas kirim 2 email/jam telah tercapai. Silakan tunggu 1 jam sebelum mencoba lagi.',
        bg: AppColors.errorBg,
        fg: AppColors.errorText,
      );

      _startHourlyRateLimitTimer();

      if (mounted) {
        setState(() {
          _isHourlyRateLimited = true;
          _isResending = false; // Pastikan tombol unlock/loading berhenti
        });
      }

      return; // Hentikan eksekusi
    }

    // Pastikan ada email yang bisa dikirim ulang
    if (_resendEmail == null || _isResending) return;

    // Asumsikan akan menampilkan loading state atau mengunci UI
    // setState(() => _isResending = true); // Jika ada state _isResending
    setState(() {
      _isResending = true; // Set state untuk menonaktifkan tombol
    });

    try {
      final supa = Supabase.instance.client;
      await supa.auth.resend(
        // Gunakan OtpType.signup
        type: OtpType.signup,
        email: _resendEmail!,
      );

      _resendAttemptCount++;

      // Tampilkan banner sukses
      _showTopBanner(
        'Link verifikasi baru sudah terkirim ke $_resendEmail!',
        bg: AppColors.successBg,
        fg: AppColors.successText,
      );

      // Mulai timer hitung mundur setelah sukses
      _startResendTimer();
    } on AuthException catch (e) {
      // JIKA GAGAL: Tangani error, khususnya Rate Limit
      final String errorMessage = e.message.toLowerCase();

      if (errorMessage.contains('rate limit') ||
          errorMessage.contains('too many requests')) {
        // KASUS SPESIFIK: Rate Limit Supabase (2 email/jam) tercapai
        _showTopBanner(
          'Batas kirim 2 email/jam telah tercapai. Silakan tunggu 1 jam sebelum mencoba lagi.',
          bg: AppColors.errorBg,
          fg: AppColors.errorText,
        );

        _startHourlyRateLimitTimer(); // Mulai timer 1 jam

        // Karena gagal, kita harus me-reset _isResending agar tombol bisa ditekan lagi,
        if (mounted) {
          setState(() {
            _isResending = false;
            _isHourlyRateLimited = true;
          });
        }
      } else {
        // Kasus error Auth Supabase umum lainnya (misalnya, email tidak valid, dll.)
        _showTopBanner(_mapAuthError(e));

        // Karena gagal, reset _isResending agar tombol bisa dicoba lagi
        if (mounted) {
          setState(() => _isResending = false);
        }
      }
    } catch (e) {
      // Error tak terduga (misalnya koneksi terputus)
      _showTopBanner(_mapAuthError(e));

      // Reset _isResending
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  // =========================================================
  // LOGIKA DEEP LINKING
  // =========================================================
  void _initUniLinks() async {
    _appLinks = AppLinks();

    // 1. Initial Link (Hanya untuk peluncuran awal)
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // 2. Latest Link (Stream untuk event baru)
    _sub = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        // handle error
        debugPrint("Deep link error: $err");
      },
    );
  }

  // Deklarasikan fungsi ini di dalam class State Anda
  Future<bool> _waitForVerification(int timeoutMs, int intervalMs) async {
    final completer = Completer<bool>();
    final int maxTries = (timeoutMs / intervalMs).floor();
    int tries = 0;

    Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      tries++;
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null && user.emailConfirmedAt != null) {
        timer.cancel();
        completer.complete(true);
      } else if (tries >= maxTries) {
        timer.cancel();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (_verificationHandled) return;

    if (uri.scheme == 'trashvisor') {
      // Gunakan polling, bukan Future.delayed statis
      final isVerificationSuccessful = await _waitForVerification(5000, 100);

      if (isVerificationSuccessful || 
          Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null) {
        // === BLOK VERIFIKASI BERHASIL ===
        if (mounted) {
          _resendTimer?.cancel();
          _hourlyRateLimitTimer?.cancel();
          _sub?.cancel();

          setState(() {
            _verificationHandled = true;
            _resendEmail = null; // sembunyikan tombol "Kirim Ulang"
            _isResending = false;
            _isHourlyRateLimited = false;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showTopBanner(
                'Verifikasi email berhasil! Silakan masuk.',
                bg: AppColors.successBg,
                fg: AppColors.successText,
              );
            }
          });
        }
      } else {
        // === BLOK GAGAL / KEDALUWARSA (timeout polling) ===
        if (mounted) {
          final currentUser = Supabase.instance.client.auth.currentUser;

          if (currentUser == null || currentUser.emailConfirmedAt == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showTopBanner(
                  'Silakan login untuk memastikan email Anda sudah terverifikasi.',
                  bg: Colors.blue,
                  fg: AppColors.errorText,
                );
              }
            });
          }

          _sub?.cancel();

          setState(() {
            _verificationHandled = true;
          });
        }
      }
    }
  }

  // (NEW) Ambil nama lengkap dari: metadata user → tabel profiles → fallback email
  Future<String?> _resolveFullName() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    // 1) user_metadata (mis. 'full_name' saat register)
    final meta = user.userMetadata;
    if (meta != null) {
      for (final key in ['full_name', 'name', 'nama']) {
        final v = meta[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }

    // 2) tabel profiles (kolom full_name)
    try {
      final data = await client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final name = (data?['full_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {
      // abaikan error baca profil
    }

    // 3) fallback dari email
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return null;
  }

  // (NEW) Ekstrak nama depan dari nama lengkap
  String _firstNameOf(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Pengguna';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  /// (NEW) Map pesan Supabase → Bahasa Indonesia.
  /// SECURITY NOTE:
  /// - Supabase mengembalikan "Invalid login credentials" untuk email ATAU
  ///   password yang salah. Di sisi klien **tidak aman** & **tidak akurat**
  ///   membedakan mana yang salah (anti user-enumeration).
  /// - Karena itu, kita tampilkan pesan generik yang aman.
  /// - Beberapa pesan lain kita tangani bila Supabase memang memberi sinyal jelas.
  String _mapAuthError(Object e) {
    final raw = (e is AuthException ? e.message : e.toString()).toLowerCase();

    if (raw.contains('invalid login credentials')) {
      return L10n.loginInvalid;
    }
    if (raw.contains('email not confirmed')) {
      return L10n.emailNotConfirmed;
    }
    if (raw.contains('user not found') || raw.contains('invalid email')) {
      return L10n.userNotFound;
    }
    if (raw.contains('too many requests') || raw.contains('rate limit')) {
      return L10n.tooManyRequests;
    }
    if (raw.contains('network') || raw.contains('timeout')) {
      return L10n.networkError;
    }
    return L10n.unknown; // fallback aman
  }

  // ---------------------- Aksi tombol Masuk ----------------------
  void _onLogin() async {
    // Validasi berurutan (meniru "cek dari atas")
    if (_isBlank(_emailC.text)) {
      _showTopBanner('Email anda belum terisi');
      return;
    }
    if (!_isValidEmail(_emailC.text)) {
      _showTopBanner('Format email tidak valid');
      return;
    }
    if (_isBlank(_passC.text)) {
      _showTopBanner('Password anda belum terisi');
      return;
    }

    // Proses login sebenarnya (call API di sini)

    // (NEW) Login dengan Supabase Auth
    try {
      final supa = Supabase.instance.client;
      await supa.auth.signInWithPassword(
        email: _emailC.text.trim(),
        password: _passC.text,
      );

      // (NEW) Ambil nama, tampilkan banner hijau “berhasil”, lalu navigasi
      final fullName = await _resolveFullName();
      final firstName = _firstNameOf(fullName);

      _showTopBanner(
        'Selamat datang, $firstName!',
        bg: AppColors.successBg,
        fg: AppColors.successText,
      );

      // (NEW) beri jeda sebentar agar banner terlihat
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      _hideTopBanner();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              HomePage(cameras: widget.cameras), // <- siapkan HomePage sendiri
          settings: const RouteSettings(name: 'HomePage'),
        ),
      );
    } on AuthException catch (e) {
      _showTopBanner(_mapAuthError(e)); // (NEW) tampilkan pesan ID yang rapi
    } catch (e) {
      _showTopBanner(_mapAuthError(e)); // (NEW) fallback non-AuthException
    }

    // (SIMULASI lama) — dibiarkan sebagai referensi:
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(
    //     builder: (_) => HomePage(cameras: widget.cameras),
    //     settings: const RouteSettings(name: 'HomePage'),
    //   ),
    // );
    // ScaffoldMessenger.of(context)
    //   .showSnackBar(const SnackBar(content: Text('Login dikirim!')));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isShort = size.height < 700;

    // Tinggi hero responsif (UBAH di LoginDimens jika ingin)
    final heroH =
        size.height *
        (isShort ? LoginDimens.heroRatioShort : LoginDimens.heroRatioTall);

    // gapAfterHero: kalau negatif → dipakai di Transform.translate (pullUpY)
    final double safeTopPad = LoginDimens.gapAfterHero > 0
        ? LoginDimens.gapAfterHero
        : 0;
    final double pullUpY = LoginDimens.gapAfterHero < 0
        ? LoginDimens.gapAfterHero
        : 0;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.deferToChild, // link RichText tetap menang
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
                      // =========================== HERO ===========================
                      SizedBox(
                        height: heroH,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/login_and_register/login_top.png',
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          cacheWidth: size.width.ceil(),
                          filterQuality: FilterQuality.none,
                        ),
                      ),

                      // ========================== KONTEN ==========================
                      Padding(
                        // <<< semua jarak horizontal/vertical diatur dari LoginDimens
                        padding: EdgeInsets.fromLTRB(
                          LoginDimens.sidePadding,
                          safeTopPad + LoginDimens.brandTopGap,
                          LoginDimens.sidePadding,
                          LoginDimens.bottomPadding,
                        ),
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            pullUpY,
                          ), // narik konten ke atas jika negatif
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
                                      iconSize: LoginDimens.brandIcon,
                                      textMargin: LoginDimens.brandTextMargin,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: LoginDimens.gapAfterBrand,
                                  ),

                                  // ------------------------- TITLE -------------------------
                                  const Center(
                                    child: Text(
                                      'Selamat Datang Kembali',
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
                                        'Masuk sekarang untuk melanjutkan aksi '
                                        'cerdas memilah dan mengelola sampah demi '
                                        'bumi yang lebih bersih',
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

                                  // -------------------------- EMAIL -------------------------
                                  const _FieldLabel('Email'),
                                  const SizedBox(height: 8),
                                  _AppTextField(
                                    controller: _emailC,
                                    hint: 'Masukkan email kamu',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    prefix: const Icon(Icons.mail_outline),
                                  ),
                                  const SizedBox(
                                    height: LoginDimens.gapBetweenFields,
                                  ),

                                  // ------------------------ PASSWORD -----------------------
                                  const _FieldLabel('Password'),
                                  const SizedBox(height: 8),
                                  _AppTextField(
                                    controller: _passC,
                                    hint: 'Masukkan password kamu',
                                    obscure: _obscure,
                                    textInputAction: TextInputAction.done,
                                    prefix: const Icon(Icons.lock_outline),
                                    suffix: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        _hideTopBanner();

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ForgotPasswordScreen(
                                                  cameras: widget.cameras,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Lupa Password?',
                                        style: TextStyle(
                                          color: AppColors.darkMossGreen,
                                          fontSize: 13,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  if (_resendEmail != null)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        // Tombol dinonaktifkan jika sedang cooldown (60s) ATAU Rate Limit 1 jam aktif
                                        onTap:
                                            _isResending || _isHourlyRateLimited
                                            ? null
                                            : _resendConfirmationEmail,
                                        child: Text(
                                          // Prioritas tertinggi: Tampilkan pesan 1 jam jika batas server tercapai
                                          _isHourlyRateLimited
                                              ? 'Batas Kirim Ulang Tercapai (Tunggu: ${_formatDuration(_hourlyResendCountdown)})'
                                              // Prioritas kedua: Tampilkan hitungan mundur 60 detik (client-side cooldown)
                                              : _isResending
                                              ? 'Kirim Ulang Email Verifikasi! ($_resendCountdown)'
                                              // Default: Tampilkan teks biasa (tombol aktif)
                                              : 'Kirim Ulang Email Verifikasi!',

                                          style: TextStyle(
                                            // Warna buram jika sedang cooldown (60s) ATAU Rate Limit (1h)
                                            color:
                                                _isResending ||
                                                    _isHourlyRateLimited
                                                ? AppColors.darkMossGreen
                                                      .withAlpha(
                                                        (255 * 0.5).round(),
                                                      )
                                                : AppColors.darkMossGreen,
                                            fontSize: 13,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(
                                    height: LoginDimens.gapBeforeButton,
                                  ),

                                  // -------------------------- BUTTON -----------------------
                                  SizedBox(
                                    width: double.infinity,
                                    height: LoginDimens.btnHeight,
                                    child: ElevatedButton(
                                      onPressed: _onLogin, // validasi + banner
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.fernGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            LoginDimens.btnRadius,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // --------------------------- CTA -------------------------
                                  Center(
                                    child: Text.rich(
                                      TextSpan(
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontFamily: 'Nunito',
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Belum punya akun? ',
                                          ),
                                          TextSpan(
                                            text: 'Daftar Sekarang',
                                            style: const TextStyle(
                                              color: AppColors.darkMossGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            recognizer: _toRegister,
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

/// ===================================================================
///  KOMPONEN UI KECIL (label + textfield + brand)
/// ===================================================================
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

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LoginDimens.fieldHeight,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Roboto',
            fontSize: 14,
          ),
          contentPadding:
              LoginDimens.fieldContentPadding, // <<< padding dalam field
          prefixIcon: prefix,
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.border),
            borderRadius: BorderRadius.circular(
              LoginDimens.fieldRadius,
            ), // <<< radius field
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.deepGreen,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(LoginDimens.fieldRadius),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final double iconSize;
  final String assetPath;
  final String text;
  final EdgeInsets textMargin;

  const _BrandHeader({
    this.iconSize = LoginDimens.brandIcon,
    required this.assetPath,
    required this.text,
    this.textMargin = LoginDimens.brandTextMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Geser ikon relatif ke teks (lihat LoginDimens.logoTopOffset)
        Transform.translate(
          offset: const Offset(0, LoginDimens.logoTopOffset),
          child: Image.asset(
            assetPath,
            height: iconSize, // <<< ubah ukuran logo dari LoginDimens.brandIcon
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
          padding: textMargin, // <<< atur jarak teks dari logo
          child: Text(
            text,
            style: const TextStyle(
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

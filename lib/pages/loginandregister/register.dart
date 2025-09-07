import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:trashvisor/pages/loginandregister/login.dart' show LoginPage;
import 'package:supabase_flutter/supabase_flutter.dart'; // (NEW) Supabase

/// ===================================================================
///  WARNA (samakan dengan login)
/// ===================================================================
class AppColors {
  static const Color green = Color(0xFF4CAF50);
  static const Color deepGreen = Color(0xFF244D24);
  static const Color blackText = Colors.black87;
  static const Color textMuted = Colors.black54;
  static const Color border = Color(0xFFE0E0E0);
  static const Color fieldBg = Colors.white;

  // Top-banner
  static const Color errorBg = Color(0xFFEA4335);
  static const Color errorText = Colors.white;

  // (NEW) Sukses
  static const Color successBg = Color(0xFF34A853);
  static const Color successText = Colors.white;
}

/// ===================================================================
///  DIMENSI / KNOB UBAHAN (SEMUA JARAK/UKURAN ADA DI SINI)
/// ===================================================================
class RegisterDimens {
  // ---------- HERO ----------
  static const double heroRatioTall = 0.30;
  static const double heroRatioShort = 0.34;
  static const String heroAsset = 'assets/illustrations/register_top.png';

  // ---------- KONTEN ----------
  static const double contentMaxWidth = 500;
  static const double sidePadding = 24; // <<< padding kiri/kanan konten

  // ---------- ATAS ----------
  static const double gapAfterHero = -35; // <<< boleh negatif (narik konten)
  static const double brandTopGap = 0;
  static const double logoTopOffset = -6;

  // ---------- SPACING ----------
  static const double gapAfterBrand = 12; // brand → judul
  static const double gapTitleToDesc = 8; // judul → deskripsi
  static const double gapAfterDesc = 20; // deskripsi → field pertama
  static const double gapBetweenFields = 18; // antar field
  static const double gapBeforeButton = 20; // field terakhir → tombol
  static const double bottomPadding = 24; // padding bawah

  // ---------- BRAND ----------
  static const double brandIcon = 40;
  static const EdgeInsets brandTextMargin = EdgeInsets.only(left: 15);

  // ---------- TIPOGRAFI ----------
  static const double title = 22;
  static const double body = 14;

  // ---------- FIELD & BUTTON ----------
  static const double fieldHeight = 52;
  static const double fieldRadius = 14;
  static const EdgeInsets fieldContentPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 14,
  );
  static const double btnHeight = 54;
  static const double btnRadius = 16;

  // ---------- BANNER ----------
  static const Duration bannerInDuration = Duration(milliseconds: 220);
  static const Duration bannerOutDuration = Duration(milliseconds: 180);
  static const Duration bannerShowTime = Duration(milliseconds: 2000);
  static const double bannerSideMargin = 12;
}

/// (NEW) Parameter kebijakan password (ubah di sini kalau kebijakan berubah)
const int _kMinPasswordLength = 8;
final RegExp _hasUpper = RegExp(r'[A-Z]');
final RegExp _hasLower = RegExp(r'[a-z]');
final RegExp _hasDigit = RegExp(r'[0-9]');

/// ===================================================================
///  (NEW) HELPER BANNER — reusable, rapi, 1 controller saja
/// ===================================================================
class _TopBanner {
  final AnimationController _ctl;
  OverlayEntry? _entry;
  Timer? _timer;

  String _message = '';
  Color _bg = AppColors.errorBg;
  Color _fg = AppColors.errorText;

  _TopBanner({
    required TickerProvider vsync,
    required Duration inDur,
    required Duration outDur,
  }) : _ctl = AnimationController(
         vsync: vsync,
         duration: inDur,
         reverseDuration: outDur,
       ) {
    _ctl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _entry?.remove();
        _entry = null;
      }
    });
  }

  void show(
    BuildContext context,
    String message, {
    Color bg = AppColors.errorBg,
    Color fg = AppColors.errorText,
    Duration showFor = const Duration(milliseconds: 2000),
    double sideMargin = 12,
    double topOffset = 8,
    IconData icon = Icons.error_outline, // (NEW) ikon default untuk error
  }) {
    _timer?.cancel();
    _message = message;
    _bg = bg;
    _fg = fg;

    final topPad = MediaQuery.of(context).padding.top;

    if (_entry == null) {
      _entry = OverlayEntry(
        builder: (_) => Positioned(
          top: topPad + topOffset,
          left: sideMargin,
          right: sideMargin,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _ctl,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                ),
            child: FadeTransition(
              opacity: _ctl,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: _bg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message,
                          style: TextStyle(
                            color: _fg,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_entry!);
    } else {
      _entry!.markNeedsBuild();
    }

    _ctl.forward(from: 0);
    _timer = Timer(showFor, () => _ctl.reverse());
  }

  void dispose() {
    _timer?.cancel();
    _ctl.dispose();
    _entry?.remove();
    _entry = null;
  }
}

/// ===================================================================
///  REGISTER PAGE — Opsi B: satu controller banner di-reuse
/// ===================================================================
class RegisterPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const RegisterPage({super.key, required this.cameras});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  // ---------------------- Form controllers ----------------------
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;

  // (NEW) error teks di bawah field password (null = tidak tampil)
  String? _passErrorText; // akan diisi bila tidak memenuhi syarat

  // Link ke Login
  late final TapGestureRecognizer _toLogin;

  // ---------------------- Top Banner (satu controller) ----------------------
  late final _TopBanner _banner; // (NEW) pakai helper

  @override
  void initState() {
    super.initState();

    // (1) Controller dibuat SEKALI → reusable
    _banner = _TopBanner(
      vsync: this,
      inDur: RegisterDimens.bannerInDuration,
      outDur: RegisterDimens.bannerOutDuration,
    );

    // (2) Gesture untuk "Masuk Sekarang"
    _toLogin = TapGestureRecognizer()
      ..onTap = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LoginPage(cameras: widget.cameras)),
        );
      };

    // (NEW) Validasi password live saat user mengetik (tanpa ubah bentuk _AppTextField)
    _passC.addListener(_validatePasswordLive);
  }

  @override
  void dispose() {
    _toLogin.dispose();
    _nameC.dispose();
    _emailC.dispose();
    _passC.removeListener(_validatePasswordLive); // (NEW) lepas listener
    _passC.dispose();
    _confirmC.dispose();

    _banner.dispose(); // (NEW) rapikan helper
    super.dispose();
  }

  // ---------------------- Validasi ringkas ----------------------
  bool _isBlank(String s) => s.trim().isEmpty;
  bool _isValidEmail(String s) {
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(s.trim());
  }

  // (NEW) buat pesan error dinamis yang informatif (di bawah field password)
  String? _buildPasswordError(String s) {
    if (s.isEmpty) return null; // kosong → tidak perlu merah dulu
    final need = <String>[];
    if (s.length < _kMinPasswordLength) need.add('minimal $_kMinPasswordLength karakter');
    if (!_hasUpper.hasMatch(s)) need.add('huruf besar');
    if (!_hasLower.hasMatch(s)) need.add('huruf kecil');
    if (!_hasDigit.hasMatch(s)) need.add('angka');
    if (need.isEmpty) return null;
    // NB: kode unik/simbol opsional → tidak dimasukkan ke pesan
    return 'Password harus ${need.join(', ')}.';
  }

  // (NEW) Listener untuk update error saat mengetik password
  void _validatePasswordLive() {
    final msg = _buildPasswordError(_passC.text);
    if (msg != _passErrorText) {
      setState(() => _passErrorText = msg);
    }
  }

  // ---------------------- Aksi tombol Kirim ----------------------
  void _onSubmit() async {
    // Cek berurutan dari atas agar pesan spesifik
    if (_isBlank(_nameC.text)) {
      _banner.show(
        context,
        'Nama lengkap belum terisi',
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
      return;
    }
    if (_isBlank(_emailC.text)) {
      _banner.show(
        context,
        'Email anda belum terisi',
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
      return;
    }
    if (!_isValidEmail(_emailC.text)) {
      _banner.show(
        context,
        'Format email tidak valid',
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
      return;
    }

    // (NEW) Cek password kuat → tampilkan error di bawah field, bukan banner
    final passErr = _buildPasswordError(_passC.text);
    if (passErr != null) {
      setState(() => _passErrorText = passErr);
      return;
    }

    if (_isBlank(_confirmC.text)) {
      _banner.show(
        context,
        'Konfirmasi password belum terisi',
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
      return;
    }
    if (_passC.text != _confirmC.text) {
      _banner.show(
        context,
        'Konfirmasi password tidak cocok',
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
      return;
    }
    if (!_agree) {
      _banner.show(
        context,
        'Harap setujui Ketentuan dan Kebijakan Privasi',
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
      return;
    }

    // Kirim data register ke backend
    // (NEW) Registrasi dengan Supabase Auth
    try {
      final supa = Supabase.instance.client;

      // (NOTE) metadata 'full_name' akan ikut ke user_metadata dan (opsional)
      // bisa dimirror ke table profiles via trigger SQL yang sudah kamu setup.
      final res = await supa.auth.signUp(
        email: _emailC.text.trim(),
        password: _passC.text,
        // metadata opsional, bisa dipakai trigger untuk isi profiles
        data: {'full_name': _nameC.text.trim()},
      );

      // Tergantung setting email confirmation. Di sini langsung arahkan ke Login.
      if (!mounted) return;

      // (NEW) gunakan ikon sukses untuk banner sukses
      _banner.show(
        context,
        res.user == null
            ? 'Registrasi berhasil, cek email untuk konfirmasi.'
            : 'Pendaftaran berhasil!',
        bg: AppColors.successBg,
        fg: AppColors.successText,
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: const Duration(milliseconds: 900),
        icon: Icons.check_circle_outline,
      );

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage(cameras: widget.cameras)),
      );
    } on AuthException catch (e) {
      _banner.show(
        context,
        e.message,
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
    } catch (_) {
      _banner.show(
        context,
        'Terjadi kesalahan. Coba lagi.',
        sideMargin: RegisterDimens.bannerSideMargin,
        showFor: RegisterDimens.bannerShowTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isShort = size.height < 700;

    // Tinggi hero responsif (atur di RegisterDimens.heroRatio*)
    final heroH =
        size.height *
        (isShort
            ? RegisterDimens.heroRatioShort
            : RegisterDimens.heroRatioTall);

    // Terapkan strategi "narik konten ke atas" jika gapAfterHero negatif
    final double safeTopPad = RegisterDimens.gapAfterHero > 0
        ? RegisterDimens.gapAfterHero
        : 0;
    final double pullUpY = RegisterDimens.gapAfterHero < 0
        ? RegisterDimens.gapAfterHero
        : 0;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
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
                          RegisterDimens.heroAsset,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          cacheWidth: size.width.ceil(),
                          filterQuality: FilterQuality.none,
                        ),
                      ),

                      // ========================== KONTEN ==========================
                      Padding(
                        // Semua jarak horizontal/vertical diambil dari RegisterDimens
                        padding: EdgeInsets.fromLTRB(
                          RegisterDimens.sidePadding,
                          safeTopPad + RegisterDimens.brandTopGap,
                          RegisterDimens.sidePadding,
                          RegisterDimens.bottomPadding,
                        ),
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            pullUpY,
                          ), // narik ke atas jika negatif
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: RegisterDimens.contentMaxWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ------------------------- BRAND -------------------------
                                  const Center(
                                    child: _BrandHeader(
                                      assetPath: 'assets/images/logo_apk.png',
                                      text: 'Trashvisor',
                                      iconSize: RegisterDimens.brandIcon,
                                      textMargin:
                                          RegisterDimens.brandTextMargin,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: RegisterDimens.gapAfterBrand,
                                  ),

                                  // ------------------------- TITLE -------------------------
                                  const Center(
                                    child: Text(
                                      'Gabung Bersama Trashvisor',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: RegisterDimens.title,
                                        height: 1.25,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.deepGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: RegisterDimens.gapTitleToDesc,
                                  ),

                                  // ------------------------ SUBTITLE -----------------------
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'Daftar sekarang dan jadilah bagian dari \n'
                                        'perubahan demi lingkungan yang lebih bersih',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: RegisterDimens.body,
                                          height: 1.75,
                                          color: AppColors.blackText,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: RegisterDimens.gapAfterDesc,
                                  ),

                                  // --------------------------- FORM ------------------------
                                  const _FieldLabel('Nama'),
                                  const SizedBox(height: 8),
                                  _AppTextField(
                                    controller: _nameC,
                                    hint: 'Masukkan nama lengkap kamu',
                                    prefix: const Icon(Icons.person_outline),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(
                                    height: RegisterDimens.gapBetweenFields,
                                  ),

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
                                    height: RegisterDimens.gapBetweenFields,
                                  ),

                                  const _FieldLabel('Buat Password'),
                                  const SizedBox(height: 8),
                                  _AppTextField(
                                    controller: _passC,
                                    hint: 'Masukkan password kamu',
                                    obscure: _obscure1,
                                    textInputAction: TextInputAction.next,
                                    prefix: const Icon(Icons.lock_outline),
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () => _obscure1 = !_obscure1,
                                      ),
                                      icon: Icon(
                                        _obscure1
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),

                                  // (NEW) Pesan error di bawah field password (hanya jika tidak memenuhi syarat)
                                  if (_passErrorText != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _passErrorText!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(
                                    height: RegisterDimens.gapBetweenFields,
                                  ),

                                  const _FieldLabel('Konfirmasi Password'),
                                  const SizedBox(height: 8),
                                  _AppTextField(
                                    controller: _confirmC,
                                    hint: 'Masukkan ulang password kamu',
                                    obscure: _obscure2,
                                    textInputAction: TextInputAction.done,
                                    prefix: const Icon(Icons.lock_outline),
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () => _obscure2 = !_obscure2,
                                      ),
                                      icon: Icon(
                                        _obscure2
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // --------------------- CHECKBOX AGREE ---------------------
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox.adaptive(
                                          value: _agree,
                                          onChanged: (v) => setState(
                                            () => _agree = v ?? false,
                                          ),
                                          activeColor: AppColors.deepGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 13,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'Saya menyetujui ',
                                              ),
                                              TextSpan(
                                                text: 'Ketentuan Penggunaan',
                                                style: const TextStyle(
                                                  color: AppColors.deepGreen,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Buka Ketentuan Penggunaan',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                              ),
                                              const TextSpan(text: ' dan '),
                                              TextSpan(
                                                text: 'Kebijakan Privasi',
                                                style: const TextStyle(
                                                  color: AppColors.deepGreen,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Buka Kebijakan Privasi',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: RegisterDimens.gapBeforeButton,
                                  ),

                                  // ------------------------- BUTTON ------------------------
                                  SizedBox(
                                    width: double.infinity,
                                    height: RegisterDimens.btnHeight,
                                    child: ElevatedButton(
                                      onPressed: _onSubmit, // validasi + banner
                                      style: ElevatedButton.styleFrom(
                                        // warna tombol Kirim khusus (#528123)
                                        backgroundColor: const Color(
                                          0xFF528123,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            RegisterDimens.btnRadius,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Kirim',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
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
                                          color: Colors.black87,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'Sudah punya akun? ',
                                          ),
                                          TextSpan(
                                            text: 'Masuk Sekarang',
                                            style: const TextStyle(
                                              color: AppColors.deepGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            recognizer: _toLogin,
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
                      // ========================= END KONTEN =========================
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
///  KOMPONEN REUSABLE
/// ===================================================================
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
        fontFamily: 'assets/fonts/nunito/nunito-bold.ttf', // Nunito Bold
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
      height: RegisterDimens.fieldHeight, // UBAH tinggi field dari sini
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.fieldBg,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          contentPadding:
              RegisterDimens.fieldContentPadding, // padding dalam field
          prefixIcon: prefix,
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.border),
            borderRadius: BorderRadius.circular(RegisterDimens.fieldRadius),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.deepGreen,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(RegisterDimens.fieldRadius),
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
    this.iconSize = RegisterDimens.brandIcon,
    required this.assetPath,
    required this.text,
    this.textMargin = RegisterDimens.brandTextMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Geser ikon relatif ke teks (lihat RegisterDimens.logoTopOffset)
        Transform.translate(
          offset: const Offset(0, RegisterDimens.logoTopOffset),
          child: Image.asset(
            assetPath,
            height: iconSize, // UBAH ukuran logo dari RegisterDimens.brandIcon
            errorBuilder: (_, _, _) => Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.eco, size: iconSize * 0.7, color: Colors.white),
            ),
          ),
        ),
        Padding(
          padding: textMargin, // UBAH jarak teks dari logo
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGreen,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:trashvisor/core/colors.dart';

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

// ===================================================================
// COMPONENT UI KECIL (SAMA DENGAN LOGIN.DART)
// ===================================================================

/// Label teks tebal di atas input field
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

  const _AppTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.prefix,
    this.suffix,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LoginDimens.fieldHeight,
      child: TextField(
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
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Roboto',
            fontSize: 14,
          ),
          contentPadding: LoginDimens.fieldContentPadding,
          prefixIcon: prefix,
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.border),
            borderRadius: BorderRadius.circular(LoginDimens.fieldRadius),
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

/// Logo dan nama aplikasi di bagian atas konten
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

// ===================================================================
// LAYOUT UTAMA: CreateNewPasswordScreen
// ===================================================================

class CreateNewPasswordScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CreateNewPasswordScreen({super.key, required this.cameras});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  // Controller untuk mengontrol input field
  final _newPassC = TextEditingController();
  final _confirmPassC = TextEditingController();

  // State untuk mengontrol visibilitas password (tombol mata)
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // DUMMY LOGIC saat tombol Kirim ditekan
  void _onSubmit() {
    // Di sini Anda akan menambahkan logika validasi dan reset password (mis. API call)
    debugPrint('Password Baru: ${_newPassC.text}');
    debugPrint('Konfirmasi Password: ${_confirmPassC.text}');
  }

  @override
  void dispose() {
    _newPassC.dispose();
    _confirmPassC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    // Tentukan apakah layar termasuk kategori pendek (tinggi < 700)
    final isShort = size.height < 700;

    // Tinggi hero responsif (disesuaikan agar tidak memenuhi layar kecil)
    final heroH =
        size.height *
        (isShort ? LoginDimens.heroRatioShort : LoginDimens.heroRatioTall);

    // Hitung padding atas dan 'pull up' untuk efek menindih
    final double safeTopPad = LoginDimens.gapAfterHero > 0
        ? LoginDimens.gapAfterHero
        : 0;
    final double pullUpY = LoginDimens.gapAfterHero < 0
        ? LoginDimens.gapAfterHero
        : 0;

    return Scaffold(
      body: GestureDetector(
        // Menutup keyboard saat user tap di luar field
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top:
              false, // Matikan SafeArea di atas karena Hero Image sudah menangani status bar
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportH = constraints.maxHeight;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                // Padding bawah untuk keyboard (mencegah overflow)
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                child: ConstrainedBox(
                  // Memastikan konten mengambil tinggi minimum viewportH
                  constraints: BoxConstraints(minHeight: viewportH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =========================== HERO IMAGE ===========================
                      SizedBox(
                        height: heroH,
                        width: double.infinity,
                        child: Image.asset(
                          // Asumsi path hero image sama dengan login
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
                          offset: Offset(
                            0,
                            pullUpY, // Menerapkan efek 'pull up' jika gapAfterHero negatif
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: LoginDimens
                                    .contentMaxWidth, // Batasan lebar
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
                                      'Buat Password Baru', // Judul sesuai tampilan
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
                                        'menyelamatkan bumi', // Subtitle sesuai tampilan
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
                                  const SizedBox(
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
                                      onPressed: _onSubmit,
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
                                        'Kirim', // Teks tombol sesuai tampilan
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          fontFamily: 'Nunito',
                                        ),
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

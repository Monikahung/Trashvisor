import 'package:flutter/material.dart';
import 'package:trashvisor/pages/loginandregister/login.dart' as auth;
import 'package:trashvisor/pages/loginandregister/register.dart' as reg; // <<< tambah import
import 'package:camera/camera.dart';

/// =======================================================
///  WARNA APLIKASI
/// =======================================================
class AppColors {
  static const Color green = Color(0xFF528123);
  static const Color deepGreen = Color(0xFF244D24);
  static const Color textMuted = Colors.black87;
}

/// =======================================================
///  KONSTAN / TITIK UBAHAN
/// =======================================================
class AppConstants {
  // Area ilustrasi (hero)
  static const double heroHeightRatio = 0.44;       // <<< besar area puzzle
  static const double heroHeightRatioSmall = 0.40;  // <<< untuk layar <700px tinggi

  // Padding & spacing konten
  static const double contentSidePadding = 24.0;    // <<< padding kiri/kanan
  static const double contentBottomPadding = 16.0;  // <<< padding bawah
  static const double contentTopSpacing = 2.0;      // <<< jarak dari batas atas konten ke logo
  static const double contentMaxWidth = 480.0;      // <<< rapi di tablet

  static const double spacing24 = 24.0;
  static const double spacing16 = 16.0;
  static const double spacing12 = 12.0;
  static const double textButtonSpacing = 40.0;     // <<< jarak teks -> tombol

  // Brand & tombol
  static const double brandIconSize = 32.0;         // <<< ukuran logo
  static const double buttonHeight = 54.0;          // <<< tinggi tombol
  static const double buttonRadius = 16.0;          // <<< radius tombol

  // Fokus pola background (−1=atas, 1=bawah)
  static const double bgAlignmentY = 0.50;          // <<< geser pola bg
}

/// =======================================================
///  HALAMAN LOGIN / REGISTER (tanpa panel putih)
/// =======================================================
class LoginRegisterPage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const LoginRegisterPage({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, _) {
          final size = MediaQuery.of(context).size;
          final isSmallHeight = size.height < 700;

          // Tinggi ilustrasi adaptif
          final heroHeight = size.height *
              (isSmallHeight
                  ? AppConstants.heroHeightRatioSmall
                  : AppConstants.heroHeightRatio);

          return Stack(
            children: [
              // ===================================================
              // LAYER 0: BACKGROUND (assets/bg/bg_loginregis.png)
              // ===================================================
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/bg/bg_loginregis.png'),
                      fit: BoxFit.cover, // full-bleed
                      alignment: Alignment(0, AppConstants.bgAlignmentY),
                    ),
                  ),
                ),
              ),

              // ===================================================
              // LAYER 1: ILUSTRASI PUZZLE (assets/illustrations/puzzle_top.png)
              // ===================================================
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: heroHeight,
                child: Image.asset(
                  'assets/illustrations/puzzle_top.png',
                  fit: BoxFit.fitWidth,           // <<< tidak over-zoom
                  alignment: Alignment.topCenter, // <<< posisikan di atas
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

              // ===================================================
              // LAYER 2: KONTEN TRANSPARAN (tanpa panel)
              // ===================================================
              Positioned(
                left: 0,
                right: 0,
                top: heroHeight, // mulai tepat setelah area ilustrasi
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.contentMaxWidth, // <<< Ubah jika perlu
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppConstants.contentSidePadding,
                          AppConstants.contentTopSpacing, // <<< jarak awal
                          AppConstants.contentSidePadding,
                          AppConstants.contentBottomPadding +
                              MediaQuery.of(context).padding.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // -------------------------------
                            // BRAND (Logo + teks)
                            // -------------------------------
                            const BrandHeader(
                              assetPath: 'assets/images/logo_apk.png',
                              text: 'Trashvisor',
                              iconSize: AppConstants.brandIconSize,
                              // atur "margin teks" di sini:
                              textMargin: EdgeInsets.only(
                                left: 12, right: 6, top: 8, bottom: 2,
                              ),
                            ),

                            const SizedBox(height: AppConstants.spacing24),

                            // -------------------------------
                            // JUDUL
                            // -------------------------------
                            const Text(
                              'Mari Mulai Perubahan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'assets/fonts/nunito/nunito-bold.ttf',
                                fontSize: 24, // <<< TITIK UBAHAN
                                height: 1.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepGreen,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacing12),

                            // -------------------------------
                            // DESKRIPSI
                            // -------------------------------
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Bersama Trashvisor, setiap langkah kecilmu berarti besar untuk bumi. Ayo mulai sekarang!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'assets/fonts/roboto/roboto-regular.ttf',
                                  fontSize: 15, // <<< TITIK UBAHAN
                                  height: 1.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),

                            // Jarak besar sebelum tombol
                            const SizedBox(height: AppConstants.textButtonSpacing),

                            // -------------------------------
                            // TOMBOL AUTH
                            // -------------------------------
                            AuthButtons(cameras: cameras),

                            const SizedBox(height: AppConstants.spacing24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// =======================================================
///  BRAND HEADER (punya margin teks)
/// =======================================================
class BrandHeader extends StatelessWidget {
  final double iconSize;
  final String assetPath;
  final String text;

  /// Jarak di sekitar TEKS (mis. EdgeInsets.only(left: 12, top: 2))
  final EdgeInsets textMargin; // <<< TITIK UBAHAN

  const BrandHeader({
    super.key,
    this.iconSize = AppConstants.brandIconSize,
    required this.assetPath,
    required this.text,
    this.textMargin = const EdgeInsets.only(left: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          height: iconSize,
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
        Padding(
          padding: textMargin, // <<< di sinilah "margin teks"
          child: Text(
            text, // gunakan nilai dari properti
            style: const TextStyle(
              fontSize: 18, // bisa diubah
              fontWeight: FontWeight.w700,
              color: AppColors.deepGreen,
            ),
          ),
        ),
      ],
    );
  }
}

/// =======================================================
///  TOMBOL AUTH
/// =======================================================
class AuthButtons extends StatelessWidget {
  final List<CameraDescription> cameras;

  const AuthButtons({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton(
            onPressed: () => NavigationHelper.goToLogin(context, cameras),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
            ),
            child: const Text(
              'Masuk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacing16),
        SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton(
            onPressed: () => NavigationHelper.goToRegister(context, cameras),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
            ),
            child: const Text(
              'Daftar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// =======================================================
///  NAVIGATION HELPER
/// =======================================================
class NavigationHelper {
  static Future<void> goToLogin(BuildContext context, List<CameraDescription> cameras) async {
    // Pre-cache hero image supaya transisi halus
    try {
      await precacheImage(
        const AssetImage('assets/illustrations/login_top.png'),
        context,
      );
    } catch (_) {/* ignore */}

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => auth.LoginPage(cameras: cameras),
        settings: const RouteSettings(name: 'LoginPage'),
      ),
    );
  }

  static Future<void> goToRegister(BuildContext context, List<CameraDescription> cameras) async {
    // Pre-cache asset yang sama (dipakai juga di RegisterPage)
    try {
      await precacheImage(
        const AssetImage('assets/illustrations/register_top.png'),
        context,
      );
    } catch (_) {/* ignore */}

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => reg.RegisterPage(cameras: cameras), // <<< langsung ke RegisterPage
        settings: const RouteSettings(name: 'RegisterPage'),
      ),
    );
  }
}

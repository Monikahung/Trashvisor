import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page.dart';
import 'package:trashvisor/pages/home_profile_notifications/home.dart';
import 'package:trashvisor/pages/loginandregister/login.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ========================================
/// KONSTANTA DESAIN DAN UKURAN
/// ========================================
const double kLogoHeight = 160;
const double kIconSize = 120;
const double kSponsorLogoHeight = 50;
const double kBottomPadding = 20;
const double kSponsorLogoSpacing = 35;
const double kTitleFontSize = 28;
const double kDidukungFontSize = 12;
const double kSpacerAfterDidukung = 25;
const Color kTrashvisorTitleColor = Color(0xFF2C5E2B);

/// ========================================
/// FUNGSI UTAMA APLIKASI
/// ========================================
/// Inisialisasi environment (.env), Supabase, dan jalankan aplikasi.
/// Pastikan .env sudah berisi SUPABASE_URL dan SUPABASE_ANON_KEY.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat variabel .env (Supabase URL dan anon key)
  await dotenv.load(fileName: ".env");

  // Inisialisasi Supabase sebelum menjalankan aplikasi
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

/// ========================================
/// WIDGET UTAMA APLIKASI
/// ========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trashvisor App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: kTitleFontSize,
            fontWeight: FontWeight.w600,
            color: kTrashvisorTitleColor,
            letterSpacing: 0.2,
          ),
          bodySmall: const TextStyle(
            fontSize: kDidukungFontSize,
          ),
        ),
      ),
      // FutureBuilder digunakan untuk memuat daftar kamera.
      // Setelah kamera siap, kita cek apakah user sudah login.
      home: FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Menunggu kamera tersedia → tampilkan progress.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // Kamera tersedia: cek sesi Supabase.
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              // Jika ada sesi (sudah login), langsung ke HomePage.
              return HomePage(cameras: snapshot.data!);
            }
            // Jika belum login, tampilkan splash & onboarding.
            return _SplashScreen(cameras: snapshot.data!);
          } else {
            // Perangkat tidak memiliki kamera.
            return const Scaffold(
              body: Center(
                child: Text('Tidak ada kamera yang tersedia pada perangkat ini.'),
              ),
            );
          }
        },
      ),
    );
  }
}

/// ========================================
/// SPLASH SCREEN
/// ========================================
/// Menampilkan logo dan sponsor selama beberapa detik,
/// kemudian menavigasi ke OnBoardingPage atau LoginPage.
/// Onboarding hanya akan ditampilkan pertama kali instal aplikasi.
/// Setelah user menyelesaikan onboarding, setel flag 'onboardingComplete'
/// di SharedPreferences menjadi true (harus dilakukan di OnBoardingPage).
class _SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const _SplashScreen({required this.cameras});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  static const _onboardingAssets = <String>[
    'assets/images/onboarding/onboarding1.png',
    'assets/images/onboarding/onboarding2.png',
    'assets/images/onboarding/onboarding3.png',
    'assets/images/onboarding/onboarding4.png',
  ];

  @override
  void initState() {
    super.initState();
    _prepareAndGo();
  }

  Future<void> _prepareAndGo() async {
    // Cache gambar onboarding agar nanti mulus.
    await Future.wait(_onboardingAssets.map((path) async {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }));

    // Pastikan splash tampil minimal 3 detik.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Periksa apakah onboarding sudah pernah diselesaikan.
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

    // Navigasi sesuai kondisi:
    if (onboardingComplete) {
      if (!mounted) return; // pastikan widget masih ada
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage(cameras: widget.cameras)),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnBoardingPage(cameras: widget.cameras)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: _buildLogoSection()),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: kBottomPadding),
                child: _buildSponsorSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Logo Trashvisor
  Widget _buildLogoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_apk.png',
          height: kLogoHeight,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.delete,
            size: kIconSize,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Trashvisor',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ],
    );
  }

  /// Bagian sponsor di bawah
  Widget _buildSponsorSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Didukung oleh',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: kSpacerAfterDidukung),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _SponsorLogo('assets/images/sponsors/skilvuv_logo.png'),
            SizedBox(width: kSponsorLogoSpacing),
            _SponsorLogo('assets/images/sponsors/polman_logo.png'),
            SizedBox(width: kSponsorLogoSpacing),
            _SponsorLogo('assets/images/sponsors/team_logo.png'),
          ],
        ),
      ],
    );
  }
}

/// ========================================
/// WIDGET LOGO SPONSOR
/// ========================================
class _SponsorLogo extends StatelessWidget {
  final String path;
  const _SponsorLogo(this.path);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      height: kSponsorLogoHeight,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: kSponsorLogoHeight,
        height: kSponsorLogoHeight,
      ),
    );
  }
}
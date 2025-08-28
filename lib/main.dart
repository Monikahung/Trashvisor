import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ========================================
// KONSTANTA DESAIN DAN UKURAN
// ========================================
const double kLogoHeight = 160;
const double kIconSize = 120;
const double kSponsorLogoHeight = 50;
const double kBottomPadding = 20;
const double kSponsorLogoSpacing = 35;
const double kTitleFontSize = 28;
const double kDidukungFontSize = 12;
const double kSpacerAfterDidukung = 25;
const Color kTrashvisorTitleColor = Color(0xFF2C5E2B);

// ========================================
// FUNGSI UTAMA APLIKASI
// ========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

// ========================================
// WIDGET UTAMA APLIKASI
// ========================================
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
      home: FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return _SplashScreen(cameras: snapshot.data!);
          } else {
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

// ========================================
// SPLASH SCREEN
// ========================================
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
    await Future.wait(_onboardingAssets.map((path) async {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }));

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OnBoardingPage(cameras: widget.cameras)),
    );
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

// ========================================
// WIDGET LOGO SPONSOR
// ========================================
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
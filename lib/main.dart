import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page.dart';
import 'package:trashvisor/pages/home_profile_notifications/home.dart';
import 'package:trashvisor/pages/login_and_register/first_login_and_register.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart';

/// ========================================
/// KONSTANTA DESAIN DAN UKURAN
/// ========================================
/// Catatan: ubah nilai-nilai di bawah ini untuk men-tune tampilan.
/// - Gunakan unit piksel langsung (double) yang konsisten.
/// - Untuk layout responsif, pertimbangkan menggunakan multipliers
///   berdasarkan MediaQuery.size (mis. size.width * 0.2) daripada nilai statis.
const double kLogoHeight = 160;
const double kIconSize = 120;
const double kSponsorLogoHeight = 50;
const double kBottomPadding =
    30; // Semakin besar, bisa buat logo sponsor dengan teks nya agak lebih keatas mendekat logo utama
const double kSponsorLogoSpacing = 40;
const double kTitleFontSize = 28;
const double kDidukungFontSize = 14;
const double kSpacerAfterDidukung = 25;
const Color kTrashvisorTitleColor = Color(0xFF2C5E2B);
const Color fernGreen = Color(0xFF528123);

/// Penjelasan singkat konstanta:
/// - kLogoHeight: tinggi logo utama pada splash. Turunkan/naikkan untuk skala visual.
/// - kIconSize: fallback icon size jika gambar logo gagal dimuat.
/// - kSponsorLogoHeight: tinggi logo sponsor di bagian bawah splash.
/// - kBottomPadding: jarak vertikal dari bawah layar untuk bagian sponsor.
/// - kSponsorLogoSpacing: jarak antar logo sponsor horizontal.
/// - kTitleFontSize / kDidukungFontSize: font size untuk teks pada splash.
///   Jika ingin tampilan lebih responsif, ganti constant dengan scale berdasarkan MediaQuery.

/// ========================================
/// FUNGSI UTAMA APLIKASI
/// ========================================
/// Inisialisasi environment (.env), Supabase, dan jalankan aplikasi.
/// Pastikan .env sudah berisi SUPABASE_URL dan SUPABASE_ANON_KEY.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        // Catatan: ubah seedColor atau gunakan ThemeData.light/dark sesuai kebutuhan.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // TextTheme: pusatkan styling teks yang dipakai di splash dan komponen lain.
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: kTitleFontSize,
            fontWeight: FontWeight.bold,
            color: kTrashvisorTitleColor,
            letterSpacing: 0.2,
            fontFamily: 'Nunito',
          ),
          bodySmall: const TextStyle(
            fontSize: kDidukungFontSize,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      // ========================================
      // FUTUREBUILDER: memuat daftar kamera sebelum menampilkan root screen
      // ========================================
      // Penjelasan:
      // - availableCameras() mengambil daftar kamera perangkat (front/back).
      // - Splash/Onboarding/Login hanya ditampilkan setelah kamera siap
      //   karena beberapa halaman (mis. pendaftaran/fitur) memerlukan CameraDescription.
      // - Jika ingin menunda pemanggilan availableCameras (mis. untuk faster startup),
      //   pertimbangkan inisialisasi kamera di halaman yang benar-benar membutuhkannya.
      home: FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (context, snapshot) {
          // Tampilkan loading saat menunggu ketersediaan kamera.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: fernGreen)),
            );
          } else if (snapshot.hasError) {
            // Jika error mengambil kamera, tampilkan pesan error agar mudah debug.
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            // Kamera ada → cek sesi Supabase
            final session = Supabase.instance.client.auth.currentSession;
            // Cek dan kirimkan status login ke _SplashScreen
            final bool isLoggedIn = session != null;
            return _SplashScreen(
              cameras: snapshot.data!,
              isLoggedIn: isLoggedIn,
            );
          } else {
            // Perangkat tidak memiliki kamera → fallback UI
            // Jika aplikasi harus berjalan tanpa kamera, ganti fallback ini dengan rute alternatif.
            return const Scaffold(
              body: Center(
                child: Text(
                  'Tidak ada kamera yang tersedia pada perangkat ini.',
                ),
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
  final bool isLoggedIn;
  const _SplashScreen({required this.cameras, required this.isLoggedIn});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  // Daftar aset onboarding yang ingin dicache untuk transisi mulus.
  // Jika menambah slide onboarding, tambahkan path file di list ini.
  static const _onboardingAssets = <String>[
    'assets/images/onboarding/onboarding.png',
    'assets/images/onboarding/onboarding_2.png',
    'assets/images/onboarding/onboarding_3.png',
    'assets/images/onboarding/onboarding_4.png',
  ];

  @override
  void initState() {
    super.initState();
    _prepareAndGo();
  }

  /// _prepareAndGo
  /// - Cache image onboarding untuk transisi yang lebih mulus.
  /// - Tunggu minimal 3 detik supaya splash terlihat.
  /// - Cek SharedPreferences untuk flag 'onboardingComplete'.
  /// - Navigasi ke LoginPage / OnBoardingPage sesuai status.
  Future<void> _prepareAndGo() async {
    // Cache gambar onboarding agar nanti mulus.
    await Future.wait(
      _onboardingAssets.map((path) async {
        try {
          await precacheImage(AssetImage(path), context);
        } catch (_) {
          // Jika gagal precache, biarkan — app masih jalan tapi transisi mungkin kurang mulus.
        }
      }),
    );

    // Pastikan splash tampil minimal 3 detik.
    // Ubah Duration di sini jika mau splash lebih panjang/pendek.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Periksa status isLoggedIn yang dikirim dari MyApp
    if (widget.isLoggedIn) {
      // Jika pengguna sudah login, langsung ke HomePage.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(cameras: widget.cameras)),
      );
    } else {
      // Jika belum login, jalankan logika pengecekan onboarding yang sudah ada.
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

      if (!mounted) return;

      if (onboardingComplete) {
        // Navigasi ke Masuk/Daftar
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginRegisterPage(cameras: widget.cameras)),
        );
      } else {
        // Navigasi ke OnBoardingPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OnBoardingPage(cameras: widget.cameras),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash menggunakan SafeArea + Stack untuk menempatkan logo di tengah
    // dan sponsor di bagian bawah.
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
  /// - Ubah path gambar jika ingin menggunakan logo berbeda.
  /// - kLogoHeight mengatur tinggi logo; untuk responsif, gunakan ukuran relatif.
  Widget _buildLogoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_apk.png',
          height: kLogoHeight,
          fit: BoxFit.contain,
          // errorBuilder menampilkan icon fallback jika asset gagal dimuat.
          errorBuilder: (_, _, _) => const Icon(Icons.delete, size: kIconSize),
        ),
        const SizedBox(height: 16),
        Text('Trashvisor', style: Theme.of(context).textTheme.headlineLarge),
      ],
    );
  }

  /// Bagian sponsor di bawah
  /// - Ubah daftar gambar sponsor atau spacing sesuai kebutuhan.
  Widget _buildSponsorSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Didukung oleh', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: kSpacerAfterDidukung),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _SponsorLogo('assets/images/sponsors/itfest_logo.png'),
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
/// - Hanya menampilkan asset image dengan tinggi kSponsorLogoHeight.
/// - Gunakan errorBuilder untuk fallback bila asset tidak tersedia.
class _SponsorLogo extends StatelessWidget {
  final String path;
  const _SponsorLogo(this.path);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      height: kSponsorLogoHeight,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          SizedBox(width: kSponsorLogoHeight, height: kSponsorLogoHeight),
    );
  }
}
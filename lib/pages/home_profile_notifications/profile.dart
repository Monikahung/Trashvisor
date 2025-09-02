import 'dart:async'; // (NEW) untuk Timer banner
import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
// (NEW) untuk logout & tarik data user
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:trashvisor/pages/loginandregister/login.dart' show LoginPage; 

// Widget utama untuk halaman profil pengguna.
// (NEW) Diubah ke Stateful karena kita menambah animasi top-banner
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // ------------------------ (NEW) Top-banner (success) ------------------------
  late final AnimationController _bannerCtl;
  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;
  String _bannerMessage = '';

  @override
  void initState() {
    super.initState();
    _bannerCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _bannerEntry?.remove();
          _bannerEntry = null;
        }
      });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtl.dispose();
    _bannerEntry?.remove();
    _bannerEntry = null;
    super.dispose();
  }

  // (NEW) Menampilkan top-banner hijau di atas layar (gaya sama seperti login.dart)
  void _showTopBanner(
    String message, {
    Color bg = AppColors.fernGreen,
    Color fg = Colors.white,
  }) {
    _bannerTimer?.cancel();
    _bannerMessage = message;

    final media = MediaQuery.of(context);
    final topPad = media.padding.top; // SafeArea atas
    const double side = 12;

    if (_bannerEntry == null) {
      _bannerEntry = OverlayEntry(
        builder: (_) => Positioned(
          top: topPad + 8,
          left: side,
          right: side,
          child: SlideTransition(
            position: Tween<Offset>(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _bannerMessage,
                          style: TextStyle(
                            color: fg,
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
      Overlay.of(context).insert(_bannerEntry!);
    } else {
      _bannerEntry!.markNeedsBuild();
    }

    _bannerCtl.forward(from: 0);
    _bannerTimer = Timer(const Duration(milliseconds: 1200), () {
      _bannerCtl.reverse();
    });
  }
  // ---------------------------------------------------------------------------

  // (NEW) Helper: ambil info profil (nama & email)
  Future<Map<String, String>> _loadProfileInfo() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    // fallback default kalau belum login (seharusnya tidak terjadi di halaman ini)
    if (user == null) {
      return {'name': 'Pengguna', 'first': 'Pengguna', 'email': ''}; // (NEW) tambah 'first'
    }

    // 1) coba dari user_metadata (mis. 'full_name' diset saat register)
    String? fullName;
    final meta = user.userMetadata;
    if (meta != null) {
      for (final key in ['full_name', 'name', 'nama']) {
        final v = meta[key];
        if (v is String && v.trim().isNotEmpty) {
          fullName = v.trim();
          break;
        }
      }
    }

    // 2) kalau belum, coba tabel profiles.full_name
    if (fullName == null || fullName.isEmpty) {
      try {
        final row = await client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        final v = (row?['full_name'] as String?)?.trim();
        if (v != null && v.isNotEmpty) fullName = v;
      } catch (_) {
        // abaikan error baca profil
      }
    }

    // 3) fallback: ambil bagian depan email
    final email = user.email ?? '';
    if (fullName == null || fullName.isEmpty) {
      fullName = email.split('@').first;
    }

    // Format:
    // - (Tetap) ambil **2 kata pertama** untuk tampilan nama di layar profil
    // - (NEW) ambil **1 kata pertama** untuk pesan "Selamat tinggal"
    String titleTwoWords(String s) {
      final parts = s
          .split(RegExp(r'[\s._-]+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'Pengguna';
      final chosen = parts.take(2).map((w) {
        final lower = w.toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
      }).join(' ');
      return chosen;
    }

    String titleFirstWord(String s) {
      final parts = s
          .split(RegExp(r'[\s._-]+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'Pengguna';
      final lower = parts.first.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }

    return {
      'name': titleTwoWords(fullName), // untuk UI (2 kata)
      'first': titleFirstWord(fullName), // (NEW) untuk goodbye (1 kata)
      'email': email,
    };
    // selesai
  }

  // (NEW) Helper logout: signOut Supabase lalu arahkan ke LoginPage
  Future<void> _logout(BuildContext context) async {
    // simpan Navigator agar aman dari lint "use BuildContext across async gaps"
    final nav = Navigator.of(context);

    // (NEW) Ambil nama ramah (first name/1 kata) SEBELUM signOut
    final info = await _loadProfileInfo();
    final friendlyFirst = info['first'] ?? 'Pengguna';

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    // (NEW) Top-banner hijau “Selamat tinggal, …” di atas (1 kata)
    _showTopBanner('Selamat tinggal, $friendlyFirst');

    // beri jeda singkat agar banner terlihat
    await Future.delayed(const Duration(milliseconds: 900));

    // Ambil kamera lagi untuk konstruksi LoginPage
    final cams = await availableCameras();

    if (!nav.mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(cameras: cams)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold memberikan struktur dasar untuk layar.
    return Scaffold(
      // Stack digunakan untuk menumpuk elemen, dalam hal ini
      // gambar latar belakang dan konten di atasnya.
      body: SingleChildScrollView(
        child: Container(
          // Background ada di sini sehingga ikut scroll
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg_profile.jpg'),
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tombol di pojok kiri atas dan kanan atas.
              _buildTombolAtas(context),
              // Memberi jarak kosong sebelum kartu utama.
              const SizedBox(height: 150),
              // Kartu utama berisi profil dan aktivitas.
              _buildKartuKonten(context)
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Pembantu untuk Keterbacaan yang Lebih Baik ---

  // Membangun tombol 'Kembali' dan 'Keluar'.
  Widget _buildTombolAtas(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali di sisi kiri.
          _buildTombolKembali(
            ikon: Icons.arrow_back_ios_new,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          // Tombol Keluar di sisi kanan.
          _buildTombolKeluar(
            teks: 'Keluar',
            ikon: Icons.exit_to_app,
            onPressed: () {
              // (NEW) panggil helper logout
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk membuat tombol kembali
  Widget _buildTombolKeluar({String? teks, required IconData ikon, required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.whiteSmoke, width: 2),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Row(
          children: [
            Icon(ikon, color: AppColors.whiteSmoke, size: 20),
            if (teks != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  teks,
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Fungsi pembantu untuk membuat tombol kembali
  Widget _buildTombolKembali({required IconData ikon, required VoidCallback onPressed}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        shape: BoxShape.circle,  // lingkaran sempurna
        border: Border.all(color: AppColors.whiteSmoke, width: 2),
      ),
      child: IconButton(
        icon: Icon(ikon, color: AppColors.whiteSmoke),
        onPressed: onPressed,
        padding: EdgeInsets.zero, // penting supaya lingkaran tidak oval
        iconSize: 20,
      ),
    );
  }

  // Membangun kartu putih utama yang berisi profil dan aktivitas.
  Widget _buildKartuKonten(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Bagian profil pengguna.
            _buildBagianProfilPengguna(context), // (NEW) kirim context (pakai FutureBuilder)
            // Jarak pemisah.
            const SizedBox(height: 20),
            // Bagian aktivitas mingguan.
            _buildBagianAktivitasMingguan(),
          ],
        ),
      ),
    );
  }

  // Membangun area profil pengguna dengan foto, nama, email, level, dan koin.
  Widget _buildBagianProfilPengguna(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _loadProfileInfo(), // (NEW) ambil nama & email dari Supabase
      builder: (context, snap) {
        final loading = !snap.hasData;
        final name = snap.data?['name'] ?? 'Pengguna';    // 2 kata (untuk tampilan)
        final email = snap.data?['email'] ?? '';

        return Row(
          children: [
            // Foto profil pengguna.
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: AppColors.fernGreen.withAlpha((255 * 0.2).round()), // Warna latar belakang ikon
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fernGreen, width: 2), // Garis luar lingkaran
              ),
              child: const Padding(
                padding: EdgeInsets.all(8), // Jarak antara ikon dan tepi lingkaran
                child: Icon(
                  Icons.person,
                  size: 60, // ukuran ikon bisa disesuaikan
                  color: AppColors.fernGreen,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Kolom untuk detail pengguna (nama, email, level).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // (NEW) nama dinamis (2 kata, Title Case)
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen
                    ),
                  ),
                  const SizedBox(height: 4),
                  // (NEW) email dinamis
                  Text(
                    loading ? 'Memuat…' : email,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Baris untuk level dan koin.
                  Row(
                    children: [
                      // Level pengguna (contoh: Level Silver).
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stars, color: Color(0xFFC0C0C0), size: 30),
                            SizedBox(width: 4),
                            Text(
                              'Level Silver', 
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkOliveGreen)
                            ),
                          ],
                        ),
                      ),
                      const Spacer(), // Mendorong container koin ke kanan.
                      // Saldo koin pengguna.
                      _buildContainerKoin(1771),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget pembantu untuk membangun container koin.
  Widget _buildContainerKoin(int jumlah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fernGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.amberAccent, // background ikon
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            jumlah.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: AppColors.whiteSmoke,
            ),
          ),
        ],
      ),
    );
  }

  // Membangun bagian aktivitas mingguan dengan hari dan ikon status.
  Widget _buildBagianAktivitasMingguan() {
    // Daftar status aktivitas statis untuk demonstrasi.
    final List<bool?> statusMingguan = [true, true, false, true, true, true, false];
    final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.fernGreen.withAlpha((255 * 1.0).round()),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Aktivitas Mingguan',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteSmoke,
                ),
              ),
              Text(
                '11/08/2025 - 17/08/2025',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Nunito',
                  color: AppColors.whiteSmoke,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row untuk menampilkan ikon status harian.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              return Column(
                children: [
                  _buildIkonStatus(statusMingguan[index]),
                  const SizedBox(height: 4),
                  Text(
                    hari[index],
                    style: const TextStyle(
                      color: AppColors.whiteSmoke, 
                      fontSize: 12,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIkonStatus(bool? isSelesai) {
    IconData ikon;
    Color warna;
    Color bgWarna;

    if (isSelesai == true) {
      ikon = Icons.check_circle;
      warna = Colors.green;
      bgWarna = AppColors.whiteSmoke; // background hijau lembut
    } else {
      ikon = Icons.cancel;
      warna = Colors.red;
      bgWarna = AppColors.whiteSmoke; // background merah lembut
    }

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: bgWarna,
        shape: BoxShape.circle, // membuatnya bulat
      ),
      child: Icon(
        ikon,
        color: warna,
        size: 32.5,
      ),
    );
  }
}
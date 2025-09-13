// home_profile_notifications/home.dart
import 'dart:async'; // 🔴 PENTING: untuk StreamSubscription
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart'; // untuk format 1.000
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔴 PENTING: ambil score dari DB

import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/trashreward/trashreward_page.dart';
import 'profile.dart';
import 'notifications.dart';
import '../trashvision/scan_camera.dart';
import '../trashchatbot/chatbot.dart';
import '../trashcapsule/capsule.dart';
import '../trashlocation/location_page.dart';

// HomePage diubah menjadi StatefulWidget
class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Kamera yang diterima dari main.dart
  List<CameraDescription>? _availableCameras;

  // ------------------- STATE: SCORE REALTIME -------------------
  int _score = 0; // nilai poin user
  bool _scoreLoaded = false; // agar bisa tampil loader / fallback saat awal
  StreamSubscription<List<Map<String, dynamic>>>? _scoreSub; // realtime
  final NumberFormat _nf = NumberFormat.decimalPattern('id_ID'); // 1.234

  @override
  void initState() {
    super.initState();
    _availableCameras = widget.cameras;
    _loadScore(); // ambil skor sekali saat start
    _subscribeScore(); // 🔴 PENTING: realtime subscribe agar ikut update
  }

  @override
  void dispose() {
    _scoreSub?.cancel(); // 🔴 PENTING: hindari memory leak
    super.dispose();
  }

  // Ambil skor awal dari DB (profiles.score)
  Future<void> _loadScore() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        setState(() {
          _score = 0;
          _scoreLoaded = true;
        });
        return;
      }

      final row = await client
          .from('profiles')
          .select('score')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _score = (row?['score'] as num?)?.toInt() ?? 0;
        _scoreLoaded = true;
      });
    } catch (e) {
      // Kalau gagal, jangan bikin crash — tampilkan 0
      setState(() {
        _scoreLoaded = true;
      });
    }
  }

  // Realtime subscription ke tabel profiles hanya untuk baris user aktif
  void _subscribeScore() {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // 🔴 PENTING:
    // butuh Realtime aktif di tabel `profiles` + RLS policy pf_select
    _scoreSub = client
        .from('profiles')
        .stream(primaryKey: ['id']) // wajib isi primaryKey untuk stream()
        .eq('id', user.id)
        .listen((rows) {
          if (!mounted) return;
          if (rows.isNotEmpty) {
            final s = (rows.first['score'] as num?)?.toInt() ?? 0;
            setState(() {
              _score = s; // akan auto update ketika score berubah di EcoReward
              _scoreLoaded = true;
            });
          }
        });
  }

  // Helper untuk menuju halaman yang mungkin mengubah poin (EcoReward)
  Future<void> _pushAndRefresh(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    // 🔁 setelah kembali, refresh manual juga (kalau realtime tidak terpanggil)
    await _loadScore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      body: SingleChildScrollView(
        child: Column(
          children: [buildHeader(context), buildMenuSection(context)],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_availableCameras != null && _availableCameras!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScanCamera(cameras: _availableCameras!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Kamera tidak tersedia. Mohon periksa izin atau perangkat.',
                ),
              ),
            );
          }
        },
        backgroundColor: AppColors.oliveGreen,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.darkOliveGreen, width: 1),
        ),
        child: const Icon(
          Icons.camera_alt_outlined,
          color: AppColors.whiteSmoke,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // --- HEADER (angka poin real-time muncul di kiri atas) ---
  Widget buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg_home.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkOliveGreen.withAlpha(204),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                // 🔴 PENTING: ganti angka statis jadi nilai dari DB
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.white),
                    const SizedBox(width: 5),
                    _scoreLoaded
                        ? Text(
                            _nf.format(_score), // contoh: 1.771 atau 12.345
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.darkOliveGreen.withAlpha(
                          204,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.darkOliveGreen.withAlpha(
                          204,
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -20,
          left: 0,
          right: 0,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkMossGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Divider(
                        color: AppColors.darkMossGreen,
                        thickness: 1,
                        height: 2.5,
                      ),
                      Divider(
                        color: AppColors.darkMossGreen,
                        thickness: 1,
                        height: 2.5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Menu tiles ---
  Widget buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildMenuItem(
                icon: Icons.camera_alt_outlined,
                title: 'Trash Vision',
                subtitle: 'Scan sampah untuk mendapatkan detail lebih lanjut',
                onTap: () {
                  // *** PEMERIKSAAN PENTING SEBELUM NAVIGASI ***
                  if (_availableCameras != null &&
                      _availableCameras!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Meneruskan _availableCameras ke ScanCamera
                        builder: (context) =>
                            ScanCamera(cameras: _availableCameras!),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Kamera tidak tersedia. Mohon periksa izin atau perangkat.',
                        ),
                      ),
                    );
                  }
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF205304),
                    Color(0xFF447D3A),
                    Color(0xFF719325),
                    Color(0xFFA2C96C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(width: 10),
              buildMenuItem(
                icon: Icons.location_on_outlined,
                title: 'Trash Location',
                subtitle: 'Temukan tempat pembuangan sampah terdekat',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationPage(),
                    ),
                  );
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF205304),
                    Color(0xFF447D3A),
                    Color(0xFF719325),
                    Color(0xFFA2C96C),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildMenuItem(
                icon: Icons.hourglass_bottom_outlined,
                title: 'Trash Capsule',
                subtitle: 'Ketahui dampak dari tindakan penanganan sampah',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrashCapsulePage(cameras: widget.cameras),
                    ),
                  );
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFA2C96C),
                    Color(0xFF719325),
                    Color(0xFF447D3A),
                    Color(0xFF205304),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              const SizedBox(width: 10),
              buildMenuItem(
                icon: Icons.card_giftcard_outlined,
                title: 'Trash Reward',
                subtitle: 'Kumpulkan poin dan tukar dengan lencana dan uang',
                onTap: () async {
                  // Setelah balik dari EcoReward, refresh skor
                  await _pushAndRefresh(EcoRewardPage(cameras: _availableCameras!));
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFA2C96C),
                    Color(0xFF719325),
                    Color(0xFF447D3A),
                    Color(0xFF205304),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          buildSingleMenuItem(
            icon: Icons.chat_outlined,
            title: 'Trash Chatbot',
            subtitle: 'Tanyakan sesuatu tentang sampah melalui Trash Chatbot',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrashChatbotPage(),
                ),
              );
            },
            gradient: const LinearGradient(
              colors: [
                Color(0xFFA2C96C),
                Color(0xFF719325),
                Color(0xFF447D3A),
                Color(0xFF205304),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient:
                gradient ??
                LinearGradient(
                  colors: [Colors.green.shade100, Colors.green.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            border: Border.all(color: AppColors.darkMossGreen, width: 1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha((255 * 0.2).round()),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.whiteSmoke,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: AppColors.darkMossGreen, size: 22),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSingleMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Gradient? gradient,
    Alignment? alignment,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              gradient ??
              LinearGradient(
                colors: [Colors.green.shade100, Colors.green.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          border: Border.all(color: AppColors.darkMossGreen, width: 1),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((255 * 0.2).round()),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.whiteSmoke,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.darkMossGreen),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Align(
                alignment: alignment ?? Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom nav (tidak diubah fungsinya; bisa diarahkan ke Reward juga bila mau)
  Widget buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () {},
          ),
          // Trash Chatbot
          IconButton(
            icon: const Icon(
              Icons.chat_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrashChatbotPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 48),
          // Trash Location
          IconButton(
            icon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationPage()),
              );
            },
          ),
          // Trash Reward
          IconButton(
            icon: const Icon(
              Icons.card_giftcard_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () async {
              // Buka reward dari bottom icon dan refresh score
              await _pushAndRefresh(EcoRewardPage(cameras: _availableCameras!));
            },
          ),
        ],
      ),
    );
  }
}
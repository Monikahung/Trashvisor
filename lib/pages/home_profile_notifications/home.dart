import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:trashvisor/core/colors.dart';
import 'profile.dart';
import 'notifications.dart';
import '../trashvision/scan_camera.dart';
import '../trashchatbot/chatbot.dart';
import '../trashcapsule/capsule.dart';

// HomePage diubah menjadi StatefulWidget
class HomePage extends StatefulWidget {
  // HomePage sekarang menerima `cameras` sebagai argumen wajib.
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variabel untuk menyimpan daftar kamera yang diterima.
  // Ini akan digunakan saat menavigasi ke ScanCamera.
  List<CameraDescription>? _availableCameras;

  @override
  void initState() {
    super.initState();
    // Inisialisasi _availableCameras dengan widget.cameras
    _availableCameras = widget.cameras;
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
          // *** PEMERIKSAAN PENTING SEBELUM NAVIGASI ***
          if (_availableCameras != null && _availableCameras!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Meneruskan _availableCameras ke ScanCamera.
                builder: (context) => ScanCamera(cameras: _availableCameras!),
              ),
            );
          } else {
            // Tampilkan pesan jika kamera tidak tersedia.
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

  // --- Metode buildHeader Anda tetap sama ---
  Widget buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
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
                child: const Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      '1,771',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
                          builder: (context) => const Notifications(),
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
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
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
                    children: [
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

  // --- Metode buildMenuSection Anda (perlu diperbaiki navigasinya) ---
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
                        // Meneruskan _availableCameras ke ScanCamera.
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
                onTap: () {},
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
                      builder: (context) => TrashCapsulePage(cameras: widget.cameras),
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
                onTap: () {},
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

  // --- Metode buildMenuItem tetap sama ---
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
    );
  }

  // --- Metode buildSingleMenuItem tetap sama ---
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
                alignment:
                    alignment ?? Alignment.centerLeft, // Default centerLeft
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

  // --- Metode buildBottomNavigationBar tetap sama ---
  Widget buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.chat_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 48), // Spacer untuk FloatingActionButton
          IconButton(
            icon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.card_giftcard_outlined,
              color: AppColors.darkOliveGreen,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

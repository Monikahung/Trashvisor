import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/home_profile_notifications/home.dart';
import 'true_capsule.dart';
import 'false_capsule.dart';
import 'package:camera/camera.dart';

// Widget untuk bilah pencarian
class _SearchBarSection extends StatelessWidget {
  const _SearchBarSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.fernGreen, width: 1),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Telusuri Jenis Sampah',
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.fernGreen,
              fontFamily: 'Roboto',
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.fernGreen),
            contentPadding: EdgeInsets.symmetric(vertical: 16),
            border: InputBorder.none, // Menghilangkan border default
          ),
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}

/// Bagian tombol pilihan (Penanganan Baik & Buruk)
class _ActionButtonsSection extends StatelessWidget {
  final List<CameraDescription> cameras;

  const _ActionButtonsSection({required this.cameras});

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.whiteSmoke, size: 32),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.whiteSmoke,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.whiteSmoke,
                fontWeight: FontWeight.bold,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.check_circle_outline,
              label: 'Penanganan Baik',
              color: Colors.green[800]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrueTrashCapsule(cameras: cameras),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.not_interested,
              label: 'Penanganan Buruk',
              color: Colors.red[800]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FalseTrashCapsule(cameras: cameras),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bagian kartu dampak
class _ImpactCardSection extends StatelessWidget {
  const _ImpactCardSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.fernGreen, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/capsule_earth.png',
                width: 75,
                height: 75,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Dampak akan muncul setelah kamu memilih tindak penanganan!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkMossGreen,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Halaman utama Trash Capsule
class TrashCapsulePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const TrashCapsulePage({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.mossGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.whiteSmoke,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(cameras: cameras),
              ),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.fernGreen,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.whiteSmoke, width: 1),
              ),
              child: const Center(
                child: Icon(
                  Icons.card_giftcard_outlined,
                  color: AppColors.whiteSmoke,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trash Capsule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Simulasi dampak pengelolaan sampah',
                    style: TextStyle(
                      color: Colors.white.withAlpha((255 * 0.8).round()),
                      fontSize: 12,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 30),
              _SearchBarSection(),
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Pilih Tindak Penanganan',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkMossGreen,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Tentukan tindakan penanganan sampah yang akan kamu lakukan.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              SizedBox(height: 24),
              _ActionButtonsSection(cameras: cameras),
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 1,
                  width: double.infinity,
                  color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Dampak di Masa Depan',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkMossGreen,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Tindakan yang kamu lakukan akan menentukan masa depan bumi.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              SizedBox(height: 24),
              _ImpactCardSection(),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

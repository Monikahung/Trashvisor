import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/home_profile_notifications/home.dart';
import 'true_capsule.dart';
import 'false_capsule.dart';
import 'package:camera/camera.dart';

/// ===================================================================
/// STATE GLOBAL SEDERHANA
/// ===================================================================
class CapsuleGlobal {
  static String searchText = '';
}

/// ===================================================================
/// TOAST KECIL DI ATAS LAYAR (posisi agak turun & bisa diatur)
/// ===================================================================
OverlayEntry? _topToastEntry;
Timer? _topToastTimer;

/// [extraTop] untuk menggeser toast sedikit ke bawah dari status bar.
/// default 44 agar tidak terlalu nempel.
void showTopToast(
  BuildContext context, {
  required String message,
  Color backgroundColor = const Color(0xFF2F3B4B),
  IconData icon = Icons.info_outline,
  Duration duration = const Duration(seconds: 2),
  double extraTop = 44,
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  _topToastTimer?.cancel();
  _topToastEntry?.remove();
  _topToastEntry = null;

  final topInset = MediaQuery.of(context).padding.top + 12;

  _topToastEntry = OverlayEntry(
    builder: (_) => Positioned(
      top: topInset + extraTop,
      left: 12,
      right: 12,
      child: IgnorePointer(
        ignoring: true,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black26)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
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

  overlay.insert(_topToastEntry!);
  _topToastTimer = Timer(duration, () {
    _topToastEntry?.remove();
    _topToastEntry = null;
  });
}

/// =========================
/// Search bar (pakai controller)
/// =========================
class _SearchBarSection extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBarSection({required this.controller});

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
        child: TextField(
          controller: controller,
          onChanged: (v) => CapsuleGlobal.searchText = v,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Telusuri Jenis Sampah',
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.fernGreen,
              fontFamily: 'Roboto',
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.fernGreen),
            contentPadding: EdgeInsets.symmetric(vertical: 16),
            border: InputBorder.none,
          ),
          style: const TextStyle(
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
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.whiteSmoke, size: 32),
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
                if (CapsuleGlobal.searchText.trim().isEmpty) {
                  showTopToast(
                    context,
                    message: 'Tulis dulu jenis sampah di kolom atas.',
                    backgroundColor: const Color(0xFFEA4335),
                    icon: Icons.error_outline,
                    extraTop: 44,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TrueTrashCapsule(cameras: cameras),
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
                if (CapsuleGlobal.searchText.trim().isEmpty) {
                  showTopToast(
                    context,
                    message: 'Tulis dulu jenis sampah di kolom atas.',
                    backgroundColor: const Color(0xFFEA4335),
                    icon: Icons.error_outline,
                    extraTop: 44,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FalseTrashCapsule(cameras: cameras),
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

/// Bagian kartu dampak (placeholder saat belum memilih)
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
    final controller = TextEditingController(text: CapsuleGlobal.searchText);
    final waste = CapsuleGlobal.searchText.trim();
    final desc = waste.isEmpty
        ? 'Tentukan tindakan penanganan sampah yang akan kamu lakukan.'
        : 'Tentukan tindakan penanganan sampah yang akan kamu lakukan terhadap "$waste".';

    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.mossGreen,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: AppColors.whiteSmoke),
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
                border:
                    Border.all(color: AppColors.whiteSmoke, width: 1),
              ),
              child: const Center(
                child: Icon(Icons.card_giftcard_outlined,
                    color: AppColors.whiteSmoke),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trash Capsule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Simulasi dampak pengelolaan sampah',
                    style: TextStyle(
                      color: Colors.white70,
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
              const SizedBox(height: 30),
              _SearchBarSection(controller: controller),
              const SizedBox(height: 24),
              const Padding(
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
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ActionButtonsSection(cameras: cameras),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 1,
                  width: double.infinity,
                  color: AppColors.darkMossGreen.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
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
              const SizedBox(height: 8),
              const Padding(
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
              const SizedBox(height: 24),
              const _ImpactCardSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

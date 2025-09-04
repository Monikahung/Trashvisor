import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/home_profile_notifications/home.dart';
import 'false_capsule.dart';
import 'capsule.dart';
import 'package:camera/camera.dart';

import 'capsule_models.dart';
import 'capsule_service.dart';

// ---- KARTU ----
class _ImpactCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final String? fallbackAsset;

  const _ImpactCard({
    required this.title,
    required this.description,
    this.imageUrl,
    this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = Image.network(
        imageUrl!,
        width: 90, height: 110, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      image = _fallback();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fernGreen, width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen, fontFamily: 'Nunito',
                    )),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(
                      fontSize: 14, color: Colors.black, fontFamily: 'Roboto',
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Image.asset(
      fallbackAsset ?? 'assets/images/true_capsule.png',
      width: 90, height: 110, fit: BoxFit.cover,
    );
  }
}

// ---- SEARCH BAR ----
class _SearchBarSection extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _SearchBarSection({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.fernGreen, width: 1),
        ),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Telusuri Jenis Sampah',
            hintStyle: TextStyle(fontSize: 14, color: AppColors.fernGreen, fontFamily: 'Roboto'),
            prefixIcon: Icon(Icons.search, color: AppColors.fernGreen),
            contentPadding: EdgeInsets.symmetric(vertical: 16),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto'),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmit(), // regenerate
        ),
      ),
    );
  }
}

// ---- ACTION BUTTONS ----
class _ActionButtonsSection extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String currentWaste;

  const _ActionButtonsSection({required this.cameras, required this.currentWaste});

  Widget _build({
    required IconData icon,
    required String label,
    required Color color,
    required IconData arrowIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(icon, color: AppColors.whiteSmoke, size: 32),
              Icon(arrowIcon, color: AppColors.whiteSmoke, size: 32),
            ]),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(
                  fontSize: 16, color: AppColors.whiteSmoke,
                  fontWeight: FontWeight.bold, fontFamily: 'Nunito',
                )),
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
            child: _build(
              icon: Icons.check_circle_outline,
              label: 'Penanganan Baik',
              color: Colors.green[800]!,
              arrowIcon: Icons.arrow_drop_up,
              onTap: () {
                // balik ke halaman pilih (capsule) — sesuai behaviour awalmu
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrashCapsulePage(cameras: cameras)),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _build(
              icon: Icons.not_interested,
              label: 'Penanganan Buruk',
              color: Colors.red[800]!,
              arrowIcon: Icons.arrow_drop_down,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FalseTrashCapsule(
                      cameras: cameras, initialWasteType: currentWaste,
                    ),
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

// ---- PAGE ----
class TrueTrashCapsule extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String? initialWasteType; // supaya teks search tetap kebawa

  const TrueTrashCapsule({super.key, required this.cameras, this.initialWasteType});

  @override
  State<TrueTrashCapsule> createState() => _TrueTrashCapsuleState();
}

class _TrueTrashCapsuleState extends State<TrueTrashCapsule> {
  final _svc = CapsuleService();
  late final TextEditingController _searchC;

  Future<CapsuleResult>? _future;

  @override
  void initState() {
    super.initState();
    _searchC = TextEditingController(text: widget.initialWasteType ?? '');
    _triggerGenerate();
  }

  void _triggerGenerate() {
    final waste = _searchC.text.trim();
    setState(() {
      _future = _svc.generate(
        wasteType: waste.isEmpty ? 'sampah plastik' : waste,
        scenario: CapsuleScenario.good,
      );
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.mossGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.whiteSmoke),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage(cameras: widget.cameras)));
          },
        ),
        title: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.fernGreen,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.whiteSmoke, width: 1),
              ),
              child: const Center(child: Icon(Icons.card_giftcard_outlined, color: AppColors.whiteSmoke)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Trash Capsule',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                const SizedBox(height: 4),
                Text('Simulasi dampak pengelolaan sampah',
                    style: TextStyle(color: Colors.white.withAlpha((255 * 0.8).round()),
                        fontSize: 12, fontFamily: 'Roboto')),
              ]),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            const SizedBox(height: 30),
            _SearchBarSection(controller: _searchC, onSubmit: _triggerGenerate),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Pilih Tindak Penanganan',
                  style: TextStyle(fontSize: 22, fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppColors.darkMossGreen)),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Tentukan tindakan penanganan sampah yang akan kamu lakukan.',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto')),
            ),
            const SizedBox(height: 24),
            _ActionButtonsSection(cameras: widget.cameras, currentWaste: _searchC.text.trim()),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 1, width: double.infinity,
                color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Dampak di Masa Depan',
                  style: TextStyle(fontSize: 22, fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppColors.darkMossGreen)),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text('Penanganan sampah yang benar akan menjaga kelestarian bumi di masa depan.',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto')),
            ),
            const SizedBox(height: 24),

            // ---------- HASIL ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FutureBuilder<CapsuleResult>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()));
                  }
                  if (!snap.hasData || snap.data == null) {
                    return const Text('Gagal memuat data.', style: TextStyle(fontFamily: 'Roboto'));
                  }
                  final items = snap.data!.items; // List<CapsuleItem>
                  return Column(
                    children: items.map((it) => _ImpactCard(
                      title: it.title,
                      description: it.description,
                      imageUrl: it.imageUrl,
                      fallbackAsset: it.fallbackAsset,
                    )).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

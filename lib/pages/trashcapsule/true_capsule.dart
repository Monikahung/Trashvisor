import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/home_profile_notifications/home.dart';
import 'false_capsule.dart';
import 'capsule.dart';
import 'package:camera/camera.dart';

import 'capsule_models.dart';
import 'capsule_service.dart';

class TrueTrashCapsule extends StatefulWidget {
  final List<CameraDescription> cameras;
  const TrueTrashCapsule({super.key, required this.cameras});

  @override
  State<TrueTrashCapsule> createState() => _TrueTrashCapsuleState();
}

class _TrueTrashCapsuleState extends State<TrueTrashCapsule> {
  final _service = CapsuleService();
  CapsuleResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final wt = CapsuleGlobal.searchText.trim();
    final res = await _service.generate(
      wasteType: wt,
      scenario: CapsuleScenario.good,
    );
    if (!mounted) return;
    setState(() {
      _result = res;
      _loading = false;
    });

    // ===== Notifikasi kaya (3 cabang) =====
    final textOk = res.textSuccess ?? (res.items.isNotEmpty);
    final imgOk  = res.imageSuccess ?? false;

    if (textOk && imgOk) {
      final remain = await _service.remainingLimit();
      if (!mounted) return;
      showTopToast(
        context,
<<<<<<< HEAD
        message: 'Gambar & narasi berhasil. Sisa limit ${remain ?? '-'}${kDailyLimit != null ? '/$kDailyLimit' : ''}',
        backgroundColor: const Color(0xFF34A853), // hijau
        icon: Icons.check_circle_outline,
        extraTop: 52,
      );
    } else if (textOk && !imgOk) {
      final remain = await _service.remainingLimit();
      if (!mounted) return;
      showTopToast(
        context,
        message: 'Narasi berhasil, gambar gagal. Pakai gambar default. Limit tidak berkurang (${remain ?? '-'}${kDailyLimit != null ? '/$kDailyLimit' : ''}).',
        backgroundColor: const Color(0xFFF9AB00), // kuning
        icon: Icons.info_outline,
        extraTop: 52,
      );
    } else {
      showTopToast(
        context,
        message: 'Narasi gagal; menampilkan konten default. Limit tidak berkurang.',
        backgroundColor: const Color(0xFFEA4335), // merah
=======
        message:
            'Gambar/Narasi gagal di-generate. Sisa Limit ${remain ?? '-'}${'/$kDailyLimit'}',
        backgroundColor: const Color(0xFFEA4335),
>>>>>>> 899d527a9c54c77858cc12de4e7fb681f920693b
        icon: Icons.error_outline,
        extraTop: 52,
      );
    }
  }

  /// Bagian visual: 1 gambar besar (dari item pertama) + daftar 3 judul & narasi
  Widget _storySection({
    required List<CapsuleItem> items,
    required String fallbackAsset,
  }) {
    final first = items.isNotEmpty ? items.first : null;
    final url = first?.imageUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar representatif (1 buah)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasUrl
                ? Image.network(
                    url,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      fallbackAsset,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    fallbackAsset,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 16),

          // 3 Judul + narasi (text only)
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkMossGreen,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waste = CapsuleGlobal.searchText.trim();
    final desc = waste.isEmpty
        ? 'Tentukan tindakan penanganan sampah yang akan kamu lakukan.'
        : 'Tentukan tindakan penanganan sampah yang akan kamu lakukan terhadap "$waste".';

    // Data final yang akan ditampilkan:
    final items = (_result?.items.isNotEmpty ?? false)
        ? _result!.items
        : <CapsuleItem>[
            // fallback kalau kosong benar-benar
            CapsuleItem(
              title: 'Lingkungan Sehat',
              description:
                  'Pengelolaan ${waste.isEmpty ? 'sampah' : waste.toLowerCase()} yang benar menjaga sungai, laut, dan tanah tetap bersih.',
              fallbackAsset: 'assets/images/true_capsule.png',
            ),
            CapsuleItem(
              title: 'Udara Bersih',
              description:
                  'Polusi berkurang karena tidak ada pembakaran sembarangan.',
              fallbackAsset: 'assets/images/true_capsule_2.png',
            ),
            CapsuleItem(
              title: 'Sumber Terjaga',
              description:
                  'Pemilahan & daur ulang membantu melestarikan sumber daya alam.',
              fallbackAsset: 'assets/images/true_capsule_3.png',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.mossGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.whiteSmoke),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(cameras: widget.cameras),
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
                child: Icon(Icons.card_giftcard_outlined, color: AppColors.whiteSmoke),
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
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 30),
                    const _SearchBarSection(),
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
                    _ActionButtonsSection(cameras: widget.cameras),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
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
                        'Penanganan sampah yang benar akan menjaga kelestarian bumi di masa depan.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==== 1 gambar + 3 narasi ====
                    _storySection(
                      items: items,
                      fallbackAsset: 'assets/images/true_capsule.png',
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Search bar (seed dari global agar teks persist)
class _SearchBarSection extends StatelessWidget {
  const _SearchBarSection();

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: CapsuleGlobal.searchText);
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

/// Tombol (naik/turun) di halaman BAIK
class _ActionButtonsSection extends StatelessWidget {
  final List<CameraDescription> cameras;
  const _ActionButtonsSection({required this.cameras});

  @override
  Widget build(BuildContext context) {
    Widget btn({
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
                  Icon(arrowIcon, color: AppColors.whiteSmoke, size: 32),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: btn(
              icon: Icons.check_circle_outline,
              label: 'Penanganan Baik',
              color: Colors.green[800]!,
              arrowIcon: Icons.arrow_drop_up,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrashCapsulePage(cameras: cameras),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: btn(
              icon: Icons.not_interested,
              label: 'Penanganan Buruk',
              color: Colors.red[800]!,
              arrowIcon: Icons.arrow_drop_down,
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

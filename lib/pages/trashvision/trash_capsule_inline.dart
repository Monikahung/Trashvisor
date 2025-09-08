// File: lib/pages/trashvision/trash_capsule_inline.dart
//
// UI gabungan Trash Capsule (tanpa search), dipanggil dari ResultScan.
// Layout:
// - Semua judul/teks left-aligned.
// - Padding horizontal 16 (lebih lebar).
// - Gambar header 1:1 & kartu narasi tidak “mengecil”.
// - Tombol aksi (Baik/Buruk) full width area konten.
// State UX:
// - Panah ▼ default; saat dipilih jadi ▲; tap lagi tombol yang sama -> deselect & balik ke placeholder.
// Toast:
// - Saat HALAMAN DIBUKA, tampil toast pengingat untuk memilih Baik/Buruk (sekali).
//
// Catatan: logic generate + toast hasil tidak diubah.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';

import 'package:trashvisor/pages/trashcapsule/capsule_models.dart';
import 'package:trashvisor/pages/trashcapsule/capsule_service.dart';

/// ===================================================================
/// TOAST KECIL DI ATAS LAYAR (posisi bisa disesuaikan lewat extraTop)
/// ===================================================================
OverlayEntry? _topToastEntry;
Timer? _topToastTimer;

void showTopToast(
  BuildContext context, {
  required String message,
  Color backgroundColor = const Color(0xFF2F3B4B),
  IconData icon = Icons.info_outline,
  Duration duration = const Duration(seconds: 2),
  double extraTop = 52,
}) {
  final overlay = Overlay.of(context);
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
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

/// ===================================================================
/// REUSABLE — 1 gambar header kotak (1:1). Jika `imageUrl` kosong -> fallback.
/// ===================================================================
class SquareHeaderImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  const SquareHeaderImage({super.key, required this.imageUrl, required this.fallbackAsset});

  @override
  Widget build(BuildContext context) {
    final Widget img = (imageUrl != null && imageUrl!.isNotEmpty)
        ? Image.network(imageUrl!, fit: BoxFit.contain)
        : Image.asset(fallbackAsset, fit: BoxFit.contain);

    return Padding(
      // 🔧 Lebar konten (ganti 16 jika ingin lebih mepet/lega)
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AspectRatio(
        aspectRatio: 1, // benar-benar kotak
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            // 🔧 Radius kartu gambar
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fernGreen, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: img, // tidak di-Center agar tidak ada padding ekstra
        ),
      ),
    );
  }
}

/// ===================================================================
/// HALAMAN: TrashCapsuleInline (dipanggil dari ResultScan)
/// ===================================================================
class TrashCapsuleInline extends StatefulWidget {
  final String wasteType; // contoh: "Anorganik Kardus" (sudah human-friendly)

  const TrashCapsuleInline({super.key, required this.wasteType});

  @override
  State<TrashCapsuleInline> createState() => _TrashCapsuleInlineState();
}

class _TrashCapsuleInlineState extends State<TrashCapsuleInline> {
  final _service = CapsuleService();

  CapsuleScenario? _selected; // good/bad (null = belum dipilih)
  CapsuleResult? _result;     // hasil generate dari server
  bool _loading = false;

  // ✅ TAMPILKAN TOAST PENGINGAT SEKALI SAAT MASUK HALAMAN
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 🔧 Ubah pesan/durasi/ikon di sini kalau mau
      showTopToast(
        context,
        message: 'Pilih “Penanganan Baik” atau “Penanganan Buruk” untuk melihat dampaknya.',
        icon: Icons.touch_app_outlined,
        duration: const Duration(seconds: 3),
        extraTop: 18,
        backgroundColor: const Color(0xFF2F3B4B),
      );
    });
  }

  // === Helper: selalu sediakan 3 narasi walau server gagal ===
  List<CapsuleItem> _fallbackItems(String waste, {required bool good}) {
    final w = waste.isEmpty ? 'sampah' : waste.toLowerCase();
    if (good) {
      return [
        CapsuleItem(
          title: 'Lingkungan Sehat',
          description: 'Pengelolaan $w yang benar menjaga sungai, laut, dan tanah tetap bersih.',
          fallbackAsset: 'assets/images/true_capsule.png',
        ),
        CapsuleItem(
          title: 'Udara Bersih',
          description: 'Polusi berkurang karena $w tidak dibakar sembarangan.',
          fallbackAsset: 'assets/images/true_capsule_2.png',
        ),
        CapsuleItem(
          title: 'Sumber Terjaga',
          description: 'Pemilahan & daur ulang $w membantu melestarikan sumber daya alam.',
          fallbackAsset: 'assets/images/true_capsule_3.png',
        ),
      ];
    } else {
      return [
        CapsuleItem(
          title: 'Lingkungan Rusak',
          description: '$w yang tercecer mencemari sungai, laut, dan tanah.',
          fallbackAsset: 'assets/images/false_capsule.png',
        ),
        CapsuleItem(
          title: 'Udara Tercemar',
          description: 'Pembakaran $w menghasilkan asap berbahaya.',
          fallbackAsset: 'assets/images/false_capsule_2.png',
        ),
        CapsuleItem(
          title: 'Sumber Habis',
          description: 'Produksi $w baru tanpa daur ulang menguras sumber daya alam.',
          fallbackAsset: 'assets/images/false_capsule_3.png',
        ),
      ];
    }
  }

  List<CapsuleItem> _itemsForUI() {
    if (_selected == null) return const <CapsuleItem>[];
    final list = _result?.items ?? const <CapsuleItem>[];
    if (list.isNotEmpty) return list;
    return _fallbackItems(widget.wasteType.trim(), good: _selected == CapsuleScenario.good);
  }

  Future<void> _generate(CapsuleScenario s) async {
    setState(() {
      _selected = s;
      _loading = true;
    });

    final res = await _service.generate(
      wasteType: widget.wasteType.trim(),
      scenario: s,
    );

    if (!mounted) return;
    setState(() {
      _result = res;
      _loading = false;
    });

    // ============= NOTIF (Toast) =============
    final items = _itemsForUI(); // narasi pasti tersedia
    final hasImage = items.isNotEmpty && (items.first.imageUrl?.isNotEmpty == true);

    final err = (_result?.errorMessage ?? '').toLowerCase();
    final limitBlockedNoImage =
        (err.contains('limit harian') || err.contains('limit tercapai')) && !hasImage;

    final remain = await _service.remainingLimit();
    if (!mounted) return;

    if (limitBlockedNoImage) {
      showTopToast(
        context,
        message:
            'Limit harian tercapai: gambar tidak dibuat. Narasi tetap tampil. Sisa limit ${remain ?? '-'} / $kDailyLimit',
        backgroundColor: const Color(0xFFFB8C00),
        icon: Icons.hourglass_empty_outlined,
        extraTop: 52,
      );
    } else if (hasImage) {
      showTopToast(
        context,
        message: 'Berhasil! Gambar + narasi dibuat. Sisa limit ${remain ?? '-'} / $kDailyLimit',
        backgroundColor: const Color(0xFF34A853),
        icon: Icons.check_circle_outline,
        extraTop: 52,
      );
    } else if (items.isNotEmpty) {
      showTopToast(
        context,
        message: 'Narasi berhasil, gambar gagal. Sisa limit tetap ${remain ?? '-'} / $kDailyLimit',
        backgroundColor: const Color(0xFFFFC107),
        icon: Icons.info_outline,
        extraTop: 52,
      );
    } else {
      showTopToast(
        context,
        message: 'Gagal membuat konten. Dipakai fallback.',
        backgroundColor: const Color(0xFFEA4335),
        icon: Icons.error_outline,
        extraTop: 52,
      );
    }
  }

  /// Header hero (pakai bg khusus Trash Capsule)
  Widget _heroHeader(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Stack(
      children: [
        Container(
          width: screenSize.width,
          height: screenSize.height * 0.35,
          decoration: const BoxDecoration(
            color: AppColors.whiteSmoke,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            image: DecorationImage(
              image: AssetImage('assets/images/bg_trash_capsule.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha((255 * 0.3).round()),
                  Colors.transparent,
                  Colors.black.withAlpha((255 * 0.3).round()),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: screenSize.height * 0.06,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context), // kembali ke ResultScan
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.fernGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.whiteSmoke, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        // 🔧 Padding horizontal konten
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 22,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: AppColors.darkMossGreen,
          ),
        ),
      );

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          height: 1,
          width: double.infinity,
          color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
        ),
      );

  /// ===============================
  /// Tombol Aksi (Baik / Buruk)
  /// with arrow toggle: ▼ default, ▲ saat terpilih; tap lagi = deselect
  /// ===============================
  Widget _actionButtons() {
    Widget btn({
      required IconData icon,
      required String label,
      required Color color,
      required bool selected,          // status terpilih
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
                  Icon(
                    selected ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: AppColors.whiteSmoke,
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: btn(
              icon: Icons.check_circle_outline,
              label: 'Penanganan Baik',
              color: Colors.green[800]!,
              selected: _selected == CapsuleScenario.good,
              onTap: () {
                // toggle behavior
                if (_selected == CapsuleScenario.good) {
                  setState(() {
                    _selected = null;   // deselect
                    _result = null;     // bersihkan hasil
                    _loading = false;
                  });
                } else {
                  _generate(CapsuleScenario.good);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: btn(
              icon: Icons.not_interested,
              label: 'Penanganan Buruk',
              color: Colors.red[800]!,
              selected: _selected == CapsuleScenario.bad,
              onTap: () {
                // toggle behavior
                if (_selected == CapsuleScenario.bad) {
                  setState(() {
                    _selected = null;   // deselect
                    _result = null;     // bersihkan hasil
                    _loading = false;
                  });
                } else {
                  _generate(CapsuleScenario.bad);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrativeCard(CapsuleItem item) {
    return Container(
      // 🔧 Padding isi kartu narasi
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fernGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkMossGreen,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontFamily: 'Roboto',
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Header image 1:1 (network jika ada, kalau tidak fallback sesuai skenario)
  Widget _headerImage() {
    if (_selected == null) return const SizedBox.shrink();

    final items = _itemsForUI();
    final url = items.isNotEmpty ? items.first.imageUrl : null;
    final fallback = (_selected == CapsuleScenario.good)
        ? 'assets/images/true_capsule.png'
        : 'assets/images/false_capsule.png';

    if (url != null && url.isNotEmpty) {
      return SquareHeaderImage(imageUrl: url, fallbackAsset: fallback);
    }

    // Pakai fallback, tapi "cover" agar terasa full
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fernGreen, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(fallback, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _impactPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Dampak akan muncul setelah kamu memilih tindak penanganan!',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkMossGreen,
                  fontFamily: 'Nunito',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waste = widget.wasteType.trim();
    final desc =
        'Lihat simulasi dampak pengelolaan sampah untuk meningkatkan kesadaran menjaga bumi.';
    final items = _itemsForUI();

    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      body: SafeArea(
        child: SingleChildScrollView(
          // Kolom konten selalu left-aligned
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heroHeader(context),

              // ===== Konten =====
              Padding(
                // 🔧 Padding horizontal global konten
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trash Capsule',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkMossGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        color: Colors.black,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              _divider(),
              const SizedBox(height: 16),

              _sectionTitle('Pilih Tindak Penanganan'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Tentukan tindakan untuk "$waste".',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _actionButtons(),
              const SizedBox(height: 24),

              _divider(),
              const SizedBox(height: 24),

              _sectionTitle('Dampak di Masa Depan'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _selected == null
                      ? 'Dampak akan ditampilkan setelah kamu memilih "Penanganan Baik" atau "Penanganan Buruk".'
                      : (_selected == CapsuleScenario.good
                          ? 'Penanganan sampah yang benar akan menjaga kelestarian bumi.'
                          : 'Penanganan sampah yang buruk akan berakibat fatal bagi masa depan bumi.'),
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: Colors.black,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: CircularProgressIndicator(color: AppColors.fernGreen),
                  ),
                )
              else ...[
                if (_selected == null) _impactPlaceholder() else ...[
                  _headerImage(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(children: items.map(_narrativeCard).toList()),
                  ),
                ],
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

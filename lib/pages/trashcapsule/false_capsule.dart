import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/home_profile_notifications/home.dart';
import 'true_capsule.dart';
import 'capsule.dart';
import 'package:camera/camera.dart';

import 'capsule_models.dart';
import 'capsule_service.dart';
import 'capsule_cache.dart'; // 🔹 clear cache saat search berubah

class FalseTrashCapsule extends StatefulWidget {
  final List<CameraDescription> cameras;
  const FalseTrashCapsule({super.key, required this.cameras});

  @override
  State<FalseTrashCapsule> createState() => _FalseTrashCapsuleState();
}

class _FalseTrashCapsuleState extends State<FalseTrashCapsule> {
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
      scenario: CapsuleScenario.bad,
    );
    if (!mounted) return;
    setState(() {
      _result = res;
      _loading = false;
    });

    // (toast hasil tetap seperti punyamu)
    final items = _itemsForUI();
    final hasImage = items.isNotEmpty && (items.first.imageUrl?.isNotEmpty == true);
    final err = (_result?.errorMessage ?? '').toLowerCase();
    final limitBlockedNoImage = (err.contains('limit harian') || err.contains('limit tercapai')) && !hasImage;
    final remain = await _service.remainingLimit();
    if (!mounted) return;

    if (limitBlockedNoImage) {
      showTopToast(context,
        message: 'Limit harian tercapai: gambar tidak dibuat. Narasi tetap tampil. Sisa limit ${remain ?? '-'} / $kDailyLimit',
        backgroundColor: const Color(0xFFFB8C00),
        icon: Icons.hourglass_empty_outlined,
        extraTop: 52,
      );
    } else if (hasImage) {
      showTopToast(context,
        message: 'Berhasil! Gambar + narasi dibuat. Sisa limit ${remain ?? '-'} / $kDailyLimit',
        backgroundColor: const Color(0xFF34A853),
        icon: Icons.check_circle_outline,
        extraTop: 52,
      );
    } else if (items.isNotEmpty) {
      showTopToast(context,
        message: 'Narasi berhasil, gambar gagal. Sisa limit tetap ${remain ?? '-'} / $kDailyLimit',
        backgroundColor: const Color(0xFFFFC107),
        icon: Icons.info_outline,
        extraTop: 52,
      );
    } else {
      showTopToast(context,
        message: 'Gagal membuat konten. Dipakai fallback.',
        backgroundColor: const Color(0xFFEA4335),
        icon: Icons.error_outline,
        extraTop: 52,
      );
    }
  }

  Widget _headerImage() {
    final items = _itemsForUI();
    final String? url = (items.isNotEmpty) ? items.first.imageUrl : null;

    if (url != null && url.isNotEmpty) {
      return SquareHeaderImage(imageUrl: url, fallbackAsset: 'assets/images/false_capsule.png');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fernGreen, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/images/false_capsule.png', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _narrativeCard(CapsuleItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fernGreen, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkMossGreen, fontFamily: 'Nunito')),
          const SizedBox(height: 6),
          Text(item.description, style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto')),
        ],
      ),
    );
  }

  List<CapsuleItem> _itemsForUI() {
    final list = _result?.items ?? const <CapsuleItem>[];
    if (list.isNotEmpty) return list;
    return _fallbackItems(CapsuleGlobal.searchText.trim(), good: false);
  }

  List<CapsuleItem> _fallbackItems(String waste, {required bool good}) {
    final w = waste.isEmpty ? 'sampah' : waste.toLowerCase();
    return [
      CapsuleItem(title: 'Lingkungan Rusak', description: '$w yang tercecer mencemari sungai, laut, dan tanah.', fallbackAsset: 'assets/images/false_capsule.png'),
      CapsuleItem(title: 'Udara Tercemar', description: 'Pembakaran $w menghasilkan asap berbahaya.', fallbackAsset: 'assets/images/false_capsule_2.png'),
      CapsuleItem(title: 'Sumber Habis', description: 'Produksi $w baru tanpa daur ulang menguras sumber daya alam.', fallbackAsset: 'assets/images/false_capsule_3.png'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final waste = CapsuleGlobal.searchText.trim();
    final desc = waste.isEmpty
        ? 'Tentukan tindakan penanganan sampah yang akan kamu lakukan.'
        : 'Tentukan tindakan penanganan sampah yang akan kamu lakukan terhadap "$waste".';

    final items = _itemsForUI();

    // 🔁 Tangkap back sistem
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        CapsuleGlobal.reset(); // 🧹 kosongkan search + cache saat keluar halaman
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteSmoke,
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: AppColors.mossGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.whiteSmoke),
            onPressed: () {
              // 🔁 Reset sebelum kembali via tombol back AppBar
              CapsuleGlobal.reset();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage(cameras: widget.cameras)),
              );
              // Atau gunakan Navigator.pop(context); sesuai pola navigasi kamu.
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
                child: const Center(child: Icon(Icons.card_giftcard_outlined, color: AppColors.whiteSmoke)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trash Capsule', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
                    SizedBox(height: 4),
                    Text('Simulasi dampak pengelolaan sampah', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Roboto')),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: Padding(padding: EdgeInsets.only(top: 48), child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 30),
                      const _SearchBarSection(),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text('Pilih Tindak Penanganan', style: TextStyle(fontSize: 22, fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppColors.darkMossGreen)),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(desc, style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto')),
                      ),
                      const SizedBox(height: 24),
                      _ActionButtonsSection(cameras: widget.cameras),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(height: 1, width: double.infinity, color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round())),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text('Dampak di Masa Depan', style: TextStyle(fontSize: 22, fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppColors.darkMossGreen)),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text('Penanganan sampah yang buruk akan berakibat fatal bagi masa depan bumi.', style: TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto')),
                      ),
                      const SizedBox(height: 16),
                      _headerImage(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(children: items.map(_narrativeCard).toList()),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

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
          onChanged: (v) {
            CapsuleGlobal.searchText = v;
            CapsuleCache.instance.clear(); // 🔸 invalidate cache saat search berubah
          },
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Telusuri Jenis Sampah',
            hintStyle: TextStyle(fontSize: 14, color: AppColors.fernGreen, fontFamily: 'Roboto'),
            prefixIcon: Icon(Icons.search, color: AppColors.fernGreen),
            contentPadding: EdgeInsets.symmetric(vertical: 16),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto'),
        ),
      ),
    );
  }
}

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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Icon(icon, color: AppColors.whiteSmoke, size: 32),
                Icon(arrowIcon, color: AppColors.whiteSmoke, size: 32),
              ]),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(fontSize: 16, color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontFamily: 'Nunito')),
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
              arrowIcon: Icons.arrow_drop_down,
              onTap: () {
                if (CapsuleGlobal.searchText.trim().isEmpty) {
                  showTopToast(context, message: 'Tulis dulu jenis sampah di kolom atas.', backgroundColor: const Color(0xFFEA4335), icon: Icons.error_outline, extraTop: 44);
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) => TrueTrashCapsule(cameras: cameras)));
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: btn(
              icon: Icons.not_interested,
              label: 'Penanganan Buruk',
              color: Colors.red[800]!,
              arrowIcon: Icons.arrow_drop_up,
              onTap: () {
                if (CapsuleGlobal.searchText.trim().isEmpty) {
                  showTopToast(context, message: 'Tulis dulu jenis sampah di kolom atas.', backgroundColor: const Color(0xFFEA4335), icon: Icons.error_outline, extraTop: 44);
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) => TrashCapsulePage(cameras: cameras)));
              },
            ),
          ),
        ],
      ),
    );
  }
}

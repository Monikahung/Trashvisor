import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// OnboardingTemplate
/// ------------------
/// Komponen *presentational* serbaguna untuk 1 layar onboarding.
/// - Ilustrasi, judul, deskripsi, tombol Next, dan tombol Lewati.
/// - Dots indikator (aktif/non-aktif) ditentukan dari `indicatorIndex / indicatorCount`.
/// - Latar belakang pakai gambar (`backgroundAsset`), default ada.
///
/// CATATAN ARSITEKTUR:
/// - Template ini tidak menyimpan state (StatelessWidget). Navigasi dan
///   penentuan slide berikutnya dilakukan di luar (parent) lewat `onNext`/`onSkip`.
/// - Semua aset (ilustrasi/tombol/bg) disuplai dari luar agar mudah dipakai ulang.
/// - Jika suatu saat perlu transisi antar slide otomatis, pertimbangkan ganti
///   ke Stateful + PageController (di *parent* agar template tetap ringan).
class OnboardingTemplate extends StatelessWidget {
  // Disimpan karena beberapa halaman onboarding kamu perlu akses kamera setelah selesai.
  final List<CameraDescription> cameras;

  // ------------------------
  // KONTEN & INTERAKSI
  // ------------------------
  /// Ilustrasi utama di bagian tengah/atas.
  final String illustrationAsset;

  /// Judul tebal (warna hijau tua).
  final String title;

  /// Deskripsi singkat di bawah judul (teks hitam soft).
  final String description;

  /// Gambar tombol "Next" (ikon panah, dsb).
  final String nextButtonAsset;

  /// Callback saat tombol "Next" ditekan (mis. pindah ke slide berikutnya).
  final VoidCallback onNext;

  /// Callback saat "Lewati" ditekan (umumnya langsung ke Login/Splash berikutnya).
  final VoidCallback onSkip;

  /// Index dot aktif (0-based).
  final int indicatorIndex;

  /// Jumlah total dot (jumlah total slide).
  final int indicatorCount;

  /// (Opsional) Gambar latar belakang seluruh layar.
  /// Ganti ini kalau ingin tema warna/gambar yang berbeda per slide.
  final String backgroundAsset;

  const OnboardingTemplate({
    super.key,
    required this.cameras,
    required this.illustrationAsset,
    required this.title,
    required this.description,
    required this.nextButtonAsset,
    required this.onNext,
    required this.onSkip,
    required this.indicatorIndex,
    required this.indicatorCount,
    this.backgroundAsset = 'assets/images/onboarding/bg_onboarding.png',
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    // Safe area top (status bar / notch) - digunakan untuk perhitungan posisi absolute
    final double safeTop = MediaQuery.of(context).padding.top;

    // ============================================================
    //  TITIK UBAHAN / KNOB JARAK (semua angka disentralisasi di sini)
    //  - BACA: Nilai negatif = geser ke ATAS (untuk *_PullUpY)
    // ============================================================
    const Color brandDeepGreen = Color(0xFF294B29); // warna brand untuk teks

    // Margin kiri/kanan keseluruhan konten
    const double sidePadding = 25.0;

    // Geser SELURUH KONTEN (ilustrasi, dots, teks, tombol) ke atas/bawah.
    // NEGATIF = naik; POSITIF = turun.
    const double contentPullUpY = -40.0;

    // Offset khusus untuk TOMBOL "LEWATI" agar tidak terlalu mepet notch.
    // POSITIF = dorong turun (mengimbangi contentPullUpY yang negatif).
    const double skipPullDownY = 48.0;

    // Ukuran ilustrasi terhadap lebar layar (0.0 - 1.0)
    const double imageWidthRatio = 0.25;

    // Jarak antara ilustrasi dan dots (harus >= 0; SizedBox tidak boleh negatif).
    const double gapImageToDots = 15.0;

    // Geser Dots ke atas/bawah secara halus.
    // NEGATIF = naik; POSITIF = turun.
    const double dotsPullUpY = -54.0;

    // Jarak dots → judul (perkecil untuk “mengangkat” konten).
    const double gapDotsToTitle = 0;

    // Jarak judul → deskripsi.
    const double gapTitleToDesc = 16.0;

    // Jarak deskripsi → tombol next.
    const double descToButton = 28.0;

    // ------------------------------------------------------------------
    // Dots indikator (aktif pakai hijau brand; non-aktif hijau dengan alpha)
    // UBAH DI SINI kalau ingin bentuknya bundar/panjang/animasi berbeda.
    // ------------------------------------------------------------------
    Widget dots(int current, int total) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final bool active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: active ? 24 : 8, // aktif dibuat lebih panjang
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? const Color.fromARGB(255, 113, 147, 37)
                  : Colors.green.withAlpha((255 * 0.3).round()),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    }

    // Hit position untuk tombol Lewati:
    // Kita hitung top absolute sehingga visual & hitbox pasti sejajar.
    // Rumus: safeTop (statusbar) + (offset visual yang kita inginkan)
    // Karena `contentPullUpY` mengangkat seluruh konten, jika kamu ingin
    // tombol mengikuti pergeseran itu plus penyesuaian skipPullDownY,
    // maka gunakan kombinasi contentPullUpY + skipPullDownY.
    final double skipTop = safeTop + (0 /*base*/ + contentPullUpY + skipPullDownY);

    return Scaffold(
      body: Container(
        // Latar belakang full-screen (gambar), supaya konsisten tiap slide.
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.fill, // TITIK UBAHAN: ganti ke cover/contain bila perlu
          ),
        ),
        // Gunakan Stack: child pertama adalah konten (yang bisa di-transform),
        // child kedua adalah tombol Lewati yang diposisikan absolut (Positioned).
        child: Stack(
          children: [
            // --------------------------
            // Konten utama (masih transformable)
            // --------------------------
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                child: Transform.translate(
                  offset: const Offset(0, contentPullUpY),
                  transformHitTests:
                      true, // agar hit-tests di dalam mengikuti transform (umumnya safe)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // NOTE: kita tidak lagi memasukkan tombol "Lewati" di sini.
                      // Biarkan tempat untuk jarak atas supaya layout tetap konsisten.
                      const SizedBox(height: 56), // cadangan ruang atas (visual)
                      const SizedBox(height: 0),
                      const SizedBox(height: 16),

                      // ILUSTRASI UTAMA
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 0.0),
                          child: Image.asset(
                            illustrationAsset,
                            fit: BoxFit.contain,
                            // TIP Pengukuran: kontrol lebar di sini kalau ingin
                            // ilustrasi terasa “ringan/compact”.
                            width: size.width * imageWidthRatio,
                          ),
                        ),
                      ),

                      // DOTS INDIKATOR
                      const SizedBox(height: gapImageToDots),
                      Transform.translate(
                        // NEGATIF = naik (aman, karena ini transform – bukan ukuran)
                        offset: const Offset(0, dotsPullUpY),
                        transformHitTests:
                            true, // optional: jika kamu juga ingin dots hit-test berubah
                        child: dots(indicatorIndex, indicatorCount),
                      ),

                      const SizedBox(height: gapDotsToTitle),

                      // JUDUL
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: brandDeepGreen,
                          fontFamily: 'Nunito',
                        ),
                      ),

                      const SizedBox(height: gapTitleToDesc),

                      // DESKRIPSI
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          height: 1.5, // line-height agar lebih nyaman dibaca
                          fontFamily: 'Roboto',
                        ),
                      ),

                      const SizedBox(height: descToButton),

                      // TOMBOL "NEXT"
                      Align(
                        alignment: Alignment.center,
                        child: InkWell(
                          onTap: onNext, // delegasi ke parent (pindah slide)
                          borderRadius: BorderRadius.circular(40),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            // TIP: jika nanti ingin pakai IconButton, cukup ganti di sini
                            child:
                                Image.asset(nextButtonAsset, fit: BoxFit.contain),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // --------------------------
            // Tombol "Lewati" — diposisikan absolut.
            // Dengan Positioned menggunakan 'skipTop' di atas, visual dan hitbox
            // persis sejajar.
            // --------------------------
            Positioned(
              top: skipTop,
              right: sidePadding,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // debug print; hapus saat rilis.
                  // ignore: avoid_print
                  print('Lewati ditekan (absolute Positioned)');
                  onSkip();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      color: brandDeepGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
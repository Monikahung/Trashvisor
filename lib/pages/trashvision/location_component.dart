import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';

// Kelas untuk Bagian Header di atas
class TrashLocationHeader extends StatelessWidget {
  const TrashLocationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk membuat UI responsif
    final Size screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Container untuk gambar latar belakang dan gradasi
        Container(
          width: screenSize.width,
          height: screenSize.height * 0.35, // Tinggi 35% dari layar
          decoration: const BoxDecoration(
            color: AppColors.whiteSmoke,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            image: DecorationImage(
              image: AssetImage('assets/images/bg_location.png'),
              fit: BoxFit.cover,
            ),
          ),
          // Layer gradasi di atas gambar untuk kontras
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
        // Tombol Kembali
        Positioned(
          top: screenSize.height * 0.06,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.fernGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.whiteSmoke,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Kelas untuk Kartu Lokasi yang dapat digunakan kembali
class TrashLocationCard extends StatelessWidget {
  final String distance;
  final String time;
  final String type;
  final String locationName;
  final double rating;
  final int reviewCount;
  final String imagePath; // Sekarang ini adalah URL dari API
  final VoidCallback onTap;

  const TrashLocationCard({
    super.key,
    required this.distance,
    required this.time,
    required this.type,
    required this.locationName,
    required this.rating,
    required this.reviewCount,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding di dalam container
      padding: const EdgeInsets.all(16),
      // Dekorasi container dengan border, warna, dan radius
      decoration: BoxDecoration(
        color: AppColors.mossGreen.withAlpha(15), // Warna dengan opacity 15%
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fernGreen, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar di sisi kiri
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 95,
                height: 95, // Tambahkan tinggi yang tetap untuk konsistensi
                // Ubah Image.asset menjadi Image.network
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  // Tampilkan gambar default jika pemuatan dari jaringan gagal
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("Gagal memuat gambar dari URL: $error");
                    return Image.asset(
                      'assets/images/default_location.png',
                      fit: BoxFit.cover,
                    );
                  },
                  // Tampilkan indikator loading saat gambar sedang dimuat
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.fernGreen,
                        ),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Kolom untuk informasi lokasi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teks jarak, waktu, dan tipe
                  Text(
                    '$distance | $time | $type',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Nama lokasi dengan font tebal
                  Text(
                    locationName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Baris untuk rating dan jumlah review
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.darkMossGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: AppColors.darkMossGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewCount)',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tombol "Lihat Peta"
                  SizedBox(
                    width: double
                        .infinity, // Membuat tombol mengisi lebar yang tersedia
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fernGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Lihat Peta',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: AppColors.whiteSmoke,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
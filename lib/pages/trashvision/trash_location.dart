import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/trashvision/nearest_location.dart';
import 'location_component.dart';

class TrashLocation extends StatelessWidget {
  const TrashLocation({super.key});

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Memanggil widget header yang sudah dipisahkan dalam satu file komponen
            const TrashLocationHeader(),

            // --- Bagian Konten (Judul, Peta & List Lokasi) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dan deskripsi
                  const Text(
                    'Trash Location',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temukan lokasi pembuangan sampah terdekat agar pengelolaan sampah lebih mudah dan tepat.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),

                  // === Bagian Peta ===
                  Stack(
                    alignment: Alignment.bottomRight, // Menempatkan tombol di kanan bawah
                    children: [
                      // Container untuk menampilkan gambar peta
                      Container(
                        width: double.infinity,
                        height: screenSize.height * 0.3, // Tinggi 30% dari layar
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.fernGreen, width: 1),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/map_layout.png'), 
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Tombol Zoom In dan Zoom Out
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.fernGreen, // warna border
                                  width: 1, // ketebalan border
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add, color: AppColors.fernGreen),
                                onPressed: () {
                                  // Logika untuk zoom in
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.fernGreen, // warna border
                                  width: 1, // ketebalan border
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.remove, color: AppColors.fernGreen),
                                onPressed: () {
                                  // Logika untuk zoom out
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Teks "Lokasi TPS Terdekat"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lokasi TPS Terdekat',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkMossGreen,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NearestLocationPage(),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: AppColors.darkMossGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Menggunakan widget kartu yang juga berada di file komponen
                  TrashLocationCard(
                    distance: '500 m',
                    time: '20 menit',
                    locationName: 'TPS Pemda Sungailiat',
                    rating: 4.5,
                    reviewCount: 10,
                    imagePath: 'assets/images/map.png',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  TrashLocationCard(
                    distance: '900 m',
                    time: '30 menit',
                    locationName: 'TPS Parit Padang',
                    rating: 4.0,
                    reviewCount: 30,
                    imagePath: 'assets/images/map_2.png',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  TrashLocationCard(
                    distance: '1.2 km',
                    time: '40 menit',
                    locationName: 'TPS Kudai',
                    rating: 4.5,
                    reviewCount: 70,
                    imagePath: 'assets/images/map_3.png',
                    onTap: () {},
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
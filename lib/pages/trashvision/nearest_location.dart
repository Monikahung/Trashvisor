import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';
import 'location_component.dart';

class NearestLocationPage extends StatelessWidget {
  const NearestLocationPage({super.key});

  // Data dummy untuk daftar lokasi
  static const List<Map<String, dynamic>> locationData = [
    {
      'distance': '500 m',
      'time': '20 menit',
      'name': 'TPS Pemda Sungailiat',
      'rating': 4.5,
      'reviews': 10,
      'image': 'assets/images/map.png',
    },
    {
      'distance': '900 m',
      'time': '30 menit',
      'name': 'TPS Parit Padang',
      'rating': 4.0,
      'reviews': 30,
      'image': 'assets/images/map_2.png',
    },
    {
      'distance': '1.2 km',
      'time': '40 menit',
      'name': 'TPS Kudai',
      'rating': 4.5,
      'reviews': 70,
      'image': 'assets/images/map_3.png',
    },
    {
      'distance': '2.2 km',
      'time': '43 menit',
      'name': 'TPS Karya Makmur',
      'rating': 4.7,
      'reviews': 13,
      'image': 'assets/images/map_4.png',
    },
    {
      'distance': '4.2 km',
      'time': '58 menit',
      'name': 'TPS Srimenanti',
      'rating': 3.5,
      'reviews': 59,
      'image': 'assets/images/map_5.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Memanggil widget header dari file komponen
            const TrashLocationHeader(),

            // --- Bagian Konten (Judul & Daftar Lokasi) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi TPS Terdekat',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),

                  // Menggunakan loop untuk membuat daftar kartu dari data
                  // dan memanggil widget TrashLocationCard dari file komponen
                  Column(
                    children: locationData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;

                      return Padding(
                        padding: EdgeInsets.only(bottom: index == locationData.length - 1 ? 0 : 16),
                        child: TrashLocationCard(
                          distance: data['distance'],
                          time: data['time'],
                          locationName: data['name'],
                          rating: data['rating'],
                          reviewCount: data['reviews'],
                          imagePath: data['image'],
                          type: data["type"],
                          onTap: () {}, // Aksi saat tombol diklik
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
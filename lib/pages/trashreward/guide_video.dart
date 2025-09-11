import 'package:flutter/material.dart';
import 'package:trashvisor/core/colors.dart';

class GuideVideo extends StatelessWidget {
  const GuideVideo({super.key});

  // Widget ini akan menampilkan jendela mengambang yang dapat digeser
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.whiteSmoke,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Pegangan/handle di bagian atas
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 75,
                height: 5,
                decoration: BoxDecoration(
                  color: Color(0xFFBABABA),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Panduan Trash Vision',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkMossGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildGuideItem('1. Arahkan kamera ke sampah.'),
                        _buildGuideItem('2. Tunggu hasil identifikasi AI.'),
                        _buildGuideItem('3. Gunakan Trash Chatbot untuk info lebih lanjut.'),
                        _buildGuideItem('4. Lihat rekomendasi penanganan sampah.'),
                        _buildGuideItem('5. Cek dampak melalui Trash Capsule.'),
                        _buildGuideItem('6. Temukan lokasi terdekat dengan Trash Location.'),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              // Tombol "Tutup"
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fernGreen,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget pembantu untuk item panduan
  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}
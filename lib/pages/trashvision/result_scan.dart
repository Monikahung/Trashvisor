import 'package:flutter/material.dart';
import 'dart:io';
import 'package:trashvisor/core/colors.dart';
import 'package:camera/camera.dart';
import 'scan_camera.dart';

class ResultScan extends StatefulWidget {
  final String? scannedImagePath;
  final Map<String, dynamic>? aiResult; // Tambahkan parameter ini
  
  const ResultScan({
    super.key,
    this.scannedImagePath,
    this.aiResult, // Tambahkan ini
  });

  @override
  State<ResultScan> createState() => _ResultScanState();
}

class _ResultScanState extends State<ResultScan> {
  String? _currentImagePath;
  String _predictedLabel = "Tidak teridentifikasi"; // Variabel baru
  String _predictedConfidence = "0.0%"; // Variabel baru

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.scannedImagePath;

    // Ekstrak data dari hasil AI jika tersedia
    if (widget.aiResult != null &&
        widget.aiResult!['data'] != null &&
        widget.aiResult!['data'].isNotEmpty) {
      final Map<String, dynamic> predictions = widget.aiResult!['data'][0];

      if (predictions.isNotEmpty) {
        var sortedEntries = predictions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        _predictedLabel = sortedEntries.first.key;
        double confidence = sortedEntries.first.value;
        _predictedConfidence = '${(confidence * 100).toStringAsFixed(2)}%';
      }
    }
  }

  Future<void> _startScanCamera() async {
    final cameras = await availableCameras();
    if (!mounted) return;

    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada kamera tersedia.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanCamera(cameras: cameras),
      ),
    );
    
    if (!mounted) return;

    // VERIFIKASI: Cek hasil yang diterima
    debugPrint("Hasil yang diterima dari kamera: $result");
    
    if (result != null && result is String) {
      // VERIFIKASI: Pastikan file ada sebelum setState
      final file = File(result);

      // PENTING: Periksa `mounted` sebelum melakukan operasi `await`
      if (!mounted) return;

      if (!await file.exists()) {
        debugPrint("Error: File gambar tidak ditemukan di jalur: $result");

        // PENTING: Periksa `mounted` lagi sebelum menggunakan `context`
        if (!mounted) return;

        // Tampilkan pesan error ke pengguna
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menampilkan gambar. File tidak ditemukan.')),
        );
        return; // Hentikan eksekusi
      }

      // PENTING: Periksa `mounted` sebelum memanggil `setState`
      if (!mounted) return;

      setState(() {
        _currentImagePath = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                // Menggunakan Image.file jika _currentImagePath tersedia
                Container(
                  width: screenSize.width,
                  height: screenSize.height * 0.35,
                  decoration: BoxDecoration(
                    color: AppColors.whiteSmoke,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    image: _currentImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_currentImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/images/bg_home.jpg'),
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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.fernGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: AppColors.whiteSmoke, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.fernGreen.withAlpha((255 * 0.15).round()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fernGreen, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _currentImagePath != null
                              ? Image.file(
                                  File(_currentImagePath!),
                                  width: 82.5,
                                  height: 82.5,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/bg_home.jpg',
                                  width: 82.5,
                                  height: 82.5,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sampah ini termasuk jenis sampah: ',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '$_predictedLabel ($_predictedConfidence)' , // Ganti ini
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              GestureDetector(
                                onTap: () {
                                  // Tambahkan fungsi untuk membuka chatbot
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'Tanya Trash Chatbot!',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.fernGreen,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: AppColors.fernGreen,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Informasi Penting',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
                    width: double.infinity, // full width
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    title: 'Saran\nPenanganan',
                    imagePath: 'assets/images/info_1.png',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Trash\nCapsule',
                    imagePath: 'assets/images/info_2.png',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Trash\nLocation',
                    imagePath: 'assets/images/info_3.png',
                    onTap: () {
                      _startScanCamera(); // Panggil fungsi scan kamera
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScanCamera, // Panggil fungsi scan kamera
        backgroundColor: AppColors.fernGreen,
        child: const Icon(Icons.camera_alt_outlined, color: AppColors.whiteSmoke),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: AppColors.fernGreen.withAlpha((255 * 0.15).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fernGreen, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.only(bottom: 10), // margin di sini
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fernGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'Selengkapnya',
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
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
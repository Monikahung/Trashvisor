// File: lib/pages/trashvision/result_scan.dart
//
// Layar hasil scan kamera (TIDAK DIUBAH strukturnya), hanya:
// - Tambah import TrashCapsuleInline
// - Kartu "Trash Capsule" -> onTap navigate ke TrashCapsuleInline(wasteType: _predictedLabel)
// - Back dari TrashCapsuleInline akan pop kembali ke sini.
//
// Catatan: _predictedLabel sudah dihumanize (ganti '_' menjadi ' ') di initState().

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:trashvisor/core/colors.dart';
import 'package:camera/camera.dart';
import 'package:trashvisor/pages/trashvision/handling_trash.dart';
import 'package:trashvisor/pages/trashchatbot/chatbot.dart';
import 'package:trashvisor/pages/trashvision/trash_location.dart';
import 'scan_camera.dart';

// >>> Tambahan: import layar capsule gabungan
import 'package:trashvisor/pages/trashvision/trash_capsule_inline.dart';

class ResultScan extends StatefulWidget {
  final String? scannedImagePath;
  final Map<String, dynamic>? aiResult;

  const ResultScan({super.key, this.scannedImagePath, this.aiResult});

  @override
  State<ResultScan> createState() => _ResultScanState();
}

class _ResultScanState extends State<ResultScan> {
  String? _currentImagePath;
  String _predictedLabel = "Tidak teridentifikasi";
  String _predictedConfidence = "0.0%";
  bool _isErrorResult = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.scannedImagePath;

    // Pastikan hasil AI tidak kosong
    if (widget.aiResult != null && widget.aiResult!.isNotEmpty) {
      final predictions = widget.aiResult!;

      // Mengonversi nilai dari String ke num untuk perbandingan yang aman
      List<MapEntry<String, dynamic>> safeEntries = [];
      predictions.forEach((key, value) {
        double parsedValue;
        if (value is num) {
          parsedValue = value.toDouble();
        } else if (value is String) {
          parsedValue = double.tryParse(value) ?? 0.0;
        } else {
          parsedValue = 0.0;
        }
        safeEntries.add(MapEntry(key, parsedValue));
      });

      // Urutkan entri berdasarkan nilai yang sudah dikonversi
      safeEntries.sort((a, b) => b.value.compareTo(a.value));

      // Ambil hasil prediksi teratas
      final topPrediction = safeEntries.first;
      _predictedLabel = topPrediction.key.replaceAll('_', ' ');
      double confidence = topPrediction.value;
      _predictedConfidence = '${(confidence * 100).toStringAsFixed(2)}%';

      // Check for error condition
      if (_predictedLabel.toLowerCase() == "error" || confidence < 0.01) {
        _isErrorResult = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startCountdown();
        });
      }
    } else {
      _isErrorResult = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCountdown();
      });
    }
  }

  // Hitung mundur kembali ke Scan Camera jika hasil deteksi error (0.00%)
  void _startCountdown() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Hasil tidak teridentifikasi. Kembali dalam 5 detik...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
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
      MaterialPageRoute(builder: (context) => ScanCamera(cameras: cameras)),
    );

    if (!mounted) return;

    debugPrint("Hasil yang diterima dari kamera: $result");

    if (result != null && result is String) {
      final file = File(result);
      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menampilkan gambar. File tidak ditemukan.')),
        );
        return;
      }
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
            // ===== Bagian Header Gambar =====
            Stack(
              children: [
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
            ),

            // ===== Bagian Konten =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Hasil Prediksi AI + Gambar ===
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.fernGreen.withAlpha((255 * 0.15).round()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fernGreen, width: 1),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 82.5,
                              height: 82.5,
                              child: _currentImagePath != null
                                  ? Image.file(File(_currentImagePath!), fit: BoxFit.cover)
                                  : Image.asset('assets/images/bg_home.jpg', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sampah ini termasuk jenis sampah:',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  '$_predictedLabel ($_predictedConfidence)',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                // Disable tombol Chatbot jika hasil error (0.00%)
                                Opacity(
                                  opacity: _isErrorResult ? 0.5 : 1.0,
                                  child: AbsorbPointer(
                                    absorbing: _isErrorResult,
                                    child: GestureDetector(
                                      onTap: () {
                                        final String question =
                                            "Tolong berikan informasi lebih detail mengenai sampah $_predictedLabel!";
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TrashChatbotPage(initialQuestion: question),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: const [
                                          Text(
                                            'Tanya Trash Chatbot!',
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.fernGreen,
                                            ),
                                          ),
                                          Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.fernGreen),
                                        ],
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
                  ),

                  const SizedBox(height: 24),

                  // === Informasi Penting ===
                  const Text(
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
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),

                  // Card: Saran Penanganan
                  _buildInfoCard(
                    title: 'Saran\nPenanganan',
                    imagePath: 'assets/images/info_1.png',
                    onTap: _isErrorResult
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HandlingTrash(trashType: _predictedLabel),
                              ),
                            );
                          },
                    isError: _isErrorResult,
                  ),

                  const SizedBox(height: 16),

                  // Card: Trash Capsule (-> TRASH CAPSULE INLINE)
                  _buildInfoCard(
                    title: 'Trash\nCapsule',
                    imagePath: 'assets/images/info_2.png',
                    onTap: _isErrorResult
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrashCapsuleInline(
                                  wasteType: _predictedLabel,
                                ),
                              ),
                            );
                          },
                    isError: _isErrorResult,
                  ),

                  const SizedBox(height: 16),

                  // Card: Trash Location
                  _buildInfoCard(
                    title: 'Trash\nLocation',
                    imagePath: 'assets/images/info_3.png',
                    onTap: _isErrorResult
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TrashLocation()),
                            );
                          },
                    isError: _isErrorResult,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScanCamera,
        backgroundColor: AppColors.fernGreen,
        child: const Icon(Icons.camera_alt_outlined, color: AppColors.whiteSmoke),
      ),
    );
  }

  // Reusable kartu “Informasi Penting”
  Widget _buildInfoCard({
    required String title,
    required String imagePath,
    required VoidCallback? onTap,
    required bool isError,
  }) {
    return Opacity(
      opacity: isError ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: AppColors.fernGreen.withAlpha((255 * 0.15).round()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.fernGreen, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkMossGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.fernGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text(
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
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.asset(imagePath, fit: BoxFit.cover, width: 130),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

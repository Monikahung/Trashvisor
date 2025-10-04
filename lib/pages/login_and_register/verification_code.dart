import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:trashvisor/core/colors.dart';
import 'package:flutter/services.dart';

// --- Konstan ---
const String _logoPath = 'assets/images/logo_apk.png';
const String _illustrationPath =
    'assets/images/login_and_register/authentication.png';

// --- Behavior Scroll Kustom (untuk menghilangkan glow overscroll pada Android) ---
class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (Platform.isAndroid) {
      return GlowingOverscrollIndicator(
        axisDirection: details.direction,
        color: Colors.transparent,
        child: child,
      );
    }
    return super.buildOverscrollIndicator(context, child, details);
  }
}

// --- Halaman Verifikasi Kode OTP ---
class VerificationCodeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  // Parameter cameras diperlukan karena ada di ForgotPasswordScreen
  const VerificationCodeScreen({super.key, required this.cameras});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  // Daftar controller untuk 5 kotak input OTP
  final List<TextEditingController> _otpControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );
  // Fokus node untuk mengontrol perpindahan fokus
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void dispose() {
    // Pastikan semua controller dan focus node dibuang saat widget dihancurkan
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Fungsi untuk menangani verifikasi kode OTP
  void _verifyOtp() {
    // Menggabungkan teks dari semua kotak input
    final String otpCode = _otpControllers
        .map((controller) => controller.text)
        .join();

    if (otpCode.length != 5) {
      // Tampilkan error jika kode belum lengkap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kode OTP harus 5 digit!',
            style: TextStyle(fontFamily: 'Roboto'),
          ),
        ),
      );
      return;
    }

    // Simulasi proses verifikasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Verifikasi kode $otpCode...',
          style: const TextStyle(fontFamily: 'Roboto'),
        ),
      ),
    );
  }

  // Fungsi untuk menangani pengiriman ulang kode OTP
  void _resendOtp() {
    // Simulasi proses kirim ulang
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mengirim ulang kode OTP...',
          style: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
    );
  }

  // --- Widget untuk satu kotak input OTP ---
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      height: 50,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          autofocus: index == 0, // Autofocus pada kotak pertama
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkMossGreen,
            fontFamily: 'Nunito',
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(1), // Batasi 1 karakter per kotak
            FilteringTextInputFormatter.digitsOnly, // Hanya izinkan angka
          ],
          decoration: InputDecoration(
            counterText: "", // Menghilangkan counter teks di bawah input
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF244D24),
                width: 2,
              ), // Warna fokus
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onChanged: (value) {
            // Logika perpindahan fokus
            if (value.isNotEmpty) {
              if (index < 4) {
                // Pindah ke kotak berikutnya jika bukan kotak terakhir
                _focusNodes[index + 1].requestFocus();
              } else {
                // Tutup keyboard jika sudah di kotak terakhir
                _focusNodes[index].unfocus();
                _verifyOtp(); // Coba verifikasi setelah input terakhir
              }
            } else if (value.isEmpty && index > 0) {
              // Pindah kembali ke kotak sebelumnya saat menghapus (backspace)
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      // --- AppBar Kustom ---
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 5.0),
          child: AppBar(
            elevation: 0,
            backgroundColor: AppColors.whiteSmoke,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leadingWidth: 40,
            leading: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.fernGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.whiteSmoke,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  _logoPath,
                  height: 40,
                  errorBuilder: (_, _, _) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.fernGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 28,
                      color: AppColors.whiteSmoke,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Transform.translate(
                  offset: const Offset(0, 6),
                  child: const Text(
                    'Trashvisor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF244D24),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            titleSpacing: 0,
          ),
        ),
      ),

      // --- Konten Utama (Body) ---
      body: ScrollConfiguration(
        behavior: const NoGlowScrollBehavior(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 30),

                // --- Judul Halaman ---
                const Text(
                  'Verifikasi Kode OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                    color: Color(0xFF244D24),
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 12),

                // --- Subjudul/Instruksi ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Masukkan kode dari email Anda untuk melanjutkan aksi cerdas demi bumi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.75,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // --- Ilustrasi ---
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: Image.asset(
                      _illustrationPath,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, error, stackTrace) => const Icon(
                        Icons.lock_open, // Fallback icon
                        size: 80,
                        color: AppColors.darkMossGreen,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // --- Kotak Input OTP (Row) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    5, // Membuat 5 kotak input
                    (index) => _buildOtpBox(index),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Teks Kirim Ulang Kode ---
                GestureDetector(
                  onTap: _resendOtp, // Memanggil fungsi kirim ulang
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tidak menerima kode? ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        Text(
                          'Kirim Ulang',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.darkMossGreen,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Tombol Verifikasi ---
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fernGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Verifikasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
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

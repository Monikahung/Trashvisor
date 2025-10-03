import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:trashvisor/core/colors.dart';

const String _logoPath = 'assets/images/logo_apk.png';
const String _illustrationPath =
    'assets/images/login_and_register/send_email.png';

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

// Halaman Lupa Password
class ForgotPasswordScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const ForgotPasswordScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    void sendRecoveryEmail(String email) {
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email tidak boleh kosong!')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permintaan reset password dikirim ke $email!')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 5.0),
          child: AppBar(
            elevation: 0,
            backgroundColor: AppColors.whiteSmoke,
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
                  offset: Offset(0, 6),
                  child: Text(
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

                const Text(
                  'Lupa Password?',
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

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Masukkan email untuk memulihkan akun dan melanjutkan aksi cerdas demi bumi',
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

                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: Image.asset(
                      _illustrationPath,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, error, stackTrace) => const Icon(
                        Icons.email,
                        size: 80,
                        color: AppColors.darkMossGreen,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    color: AppColors.darkMossGreen,
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 52,
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Masukkan email kamu',
                      hintStyle: const TextStyle(
                        color: Colors.black54,
                        fontFamily: 'Roboto',
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.mail_outline),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF244D24),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => sendRecoveryEmail(emailController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fernGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Kirim',
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

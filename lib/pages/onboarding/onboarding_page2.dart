import 'package:flutter/material.dart';
import 'package:trashvisor/pages/loginandregister/login.dart';
import 'package:trashvisor/pages/onboarding/onboarding_template.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page3.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingPage2 extends StatelessWidget {
  final List<CameraDescription> cameras;

  const OnBoardingPage2({super.key, required this.cameras});

  Future<void> _finish(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboardingComplete', true);

  if (!context.mounted) return;               // <— pastikan masih ter-mount
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LoginPage(cameras: cameras)),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      illustrationAsset: 'assets/images/onboarding/onboarding2.png', // ganti gambar
      cameras: cameras,
      title: 'Foto, Kenali, dan Kelola',                 // ganti teks
      description: 'Gunakan kamera ponsel untuk mengenali jenis sampah dengan mudah. Dapatkan saran penanganan serta lihat dampaknya bagi masa depan bumi',
      nextButtonAsset: 'assets/images/onboarding/next_onboarding2.png', // ganti gambar
      indicatorIndex: 1,
      indicatorCount: 4,
      onSkip: () => _finish(context),
      onNext: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OnBoardingPage3(cameras: cameras)));
      },
    );
  }
}
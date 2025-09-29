import 'package:flutter/material.dart';
import 'package:trashvisor/pages/login_and_register/first_login_and_register.dart';
import 'package:trashvisor/pages/onboarding/onboarding_template.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page_3.dart';
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
    MaterialPageRoute(builder: (_) => LoginRegisterPage(cameras: cameras)),
    (route) => false,
  );
}

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      backgroundAsset: 'assets/images/bg/bg_onboarding_2.png',
      illustrationAsset: 'assets/images/onboarding/onboarding_2.png', // ganti gambar
      cameras: cameras,
      title: 'Foto, Kenali, dan Pelajari',                 // ganti teks
      description: 'Gunakan kamera ponsel untuk mengenali jenis sampah dengan mudah. Dapatkan saran penanganan serta pelajari dampaknya bagi masa depan bumi',
      nextButtonAsset: 'assets/images/onboarding/next_onboarding_2.png', // ganti gambar
      indicatorIndex: 1,
      indicatorCount: 4,
      onSkip: () => _finish(context),
      onNext: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OnBoardingPage3(cameras: cameras)));
      },
    );
  }
}
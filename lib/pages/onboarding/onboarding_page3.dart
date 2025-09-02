import 'package:flutter/material.dart';
import 'package:trashvisor/pages/loginandregister/login.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page4.dart';
import 'package:trashvisor/pages/onboarding/onboarding_template.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingPage3 extends StatelessWidget {
  final List<CameraDescription> cameras;

  const OnBoardingPage3({super.key, required this.cameras});

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
      backgroundAsset: 'assets/images/onboarding/bg_onboarding2.png', // <-- PENTING
      cameras: cameras,
      illustrationAsset: 'assets/images/onboarding/onboarding3.png', // ganti gambar
      title: 'Buang Sampah dan Raih Poin',                 // ganti teks
      description: 'Temukan lokasi pembuangan sampah terdekat dan dapatkan poin setiap kali membuangnya dengan benar',
      nextButtonAsset: 'assets/images/onboarding/next_onboarding3.png', // ganti gambar
      indicatorIndex: 2,
      indicatorCount: 4,
      onSkip: () => _finish(context),
      onNext: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OnBoardingPage4(cameras: cameras)));
      },
    );
  }
}
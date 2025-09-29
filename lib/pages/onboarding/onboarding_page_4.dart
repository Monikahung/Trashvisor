import 'package:flutter/material.dart';
import 'package:trashvisor/pages/login_and_register/first_login_and_register.dart';
import 'package:trashvisor/pages/onboarding/onboarding_template.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingPage4 extends StatelessWidget {
  final List<CameraDescription> cameras;

  const OnBoardingPage4({super.key, required this.cameras});

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
      backgroundAsset: 'assets/images/bg/bg_onboarding_4.png',
      cameras: cameras,
      illustrationAsset: 'assets/images/onboarding/onboarding_4.png', // ganti gambar
      title: 'Belajar dan Lihat Dampaknya',                 // ganti teks
      description: 'Tanyakan pada chatbot seputar sampah dan lihat simulasi penanganan sampah di masa depan sebagai pembelajaran dari setiap pilihanmu',
      nextButtonAsset: 'assets/images/onboarding/next_onboarding_4.png', // ganti gambar
      indicatorIndex: 3,
      indicatorCount: 4,
      onSkip: () => _finish(context),
      // Di slide terakhir, NEXT = selesai onboarding juga
      onNext: () => _finish(context),
    );
  }
}
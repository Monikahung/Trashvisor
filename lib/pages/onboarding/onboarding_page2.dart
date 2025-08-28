import 'package:flutter/material.dart';
import 'package:trashvisor/pages/loginandregister/first_loginandregister.dart';
import 'package:trashvisor/pages/onboarding/onboarding_template.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page3.dart';
import 'package:camera/camera.dart';

class OnBoardingPage2 extends StatelessWidget {
  final List<CameraDescription> cameras;

  const OnBoardingPage2({super.key, required this.cameras});

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
      onSkip: () { 
        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginRegisterPage(cameras: cameras))); // Skip to LoginRegisterPage
      },
      onNext: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OnBoardingPage3(cameras: cameras)));
      },
    );
  }
}

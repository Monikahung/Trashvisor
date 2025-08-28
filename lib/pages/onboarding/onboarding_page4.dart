import 'package:flutter/material.dart';
import 'package:trashvisor/pages/loginandregister/first_loginandregister.dart';
import 'package:trashvisor/pages/onboarding/onboarding_template.dart';
import 'package:camera/camera.dart';


class OnBoardingPage4 extends StatelessWidget {
  final List<CameraDescription> cameras;

  const OnBoardingPage4({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      backgroundAsset: 'assets/images/onboarding/bg_onboarding2.png',
      cameras: cameras,
      illustrationAsset: 'assets/images/onboarding/onboarding4.png', // ganti gambar
      title: 'Belajar dan Lihat Dampaknya',                 // ganti teks
      description: 'Tanyakan pada chatbot tentang sampah dan lihat simulasi masa depan jika sampah diolah atau dibuang sembarangan',
      nextButtonAsset: 'assets/images/onboarding/next_onboarding4.png', // ganti gambar
      indicatorIndex: 3,
      indicatorCount: 4,
      onSkip: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginRegisterPage(cameras: cameras)));
      },
      onNext: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LoginRegisterPage(cameras: cameras)));
      },
    );
  }
}

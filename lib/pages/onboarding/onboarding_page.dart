import 'package:flutter/material.dart';
import 'package:trashvisor/pages/login_and_register/first_login_and_register.dart';
import 'package:trashvisor/pages/onboarding/onboarding_template.dart';
import 'package:trashvisor/pages/onboarding/onboarding_page_2.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingPage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const OnBoardingPage({super.key, required this.cameras});

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
      backgroundAsset: 'assets/images/bg/bg_onboarding.png',
      illustrationAsset: 'assets/images/onboarding/onboarding.png',
      cameras: cameras,
      title: 'Selamat Datang di Trashvisor',
      description:
          'Teman belajar interaktif yang siap membantumu memilah, membuang, dan mengelola sampah secara cerdas, praktis, serta ramah lingkungan',
      nextButtonAsset: 'assets/images/onboarding/next_onboarding.png',
      indicatorIndex: 0,
      indicatorCount: 4, // misal total 4 slide
      onSkip: () => _finish(context),
      onNext: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OnBoardingPage2(cameras: cameras)),
        );
      },
    );
  }
}
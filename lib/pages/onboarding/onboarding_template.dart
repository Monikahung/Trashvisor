import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class OnboardingTemplate extends StatelessWidget {
  final List<CameraDescription> cameras;


  final String illustrationAsset;
  final String title;
  final String description;
  final String nextButtonAsset;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int indicatorIndex; // 0-based
  final int indicatorCount; // total slide
  final String backgroundAsset;

  const OnboardingTemplate({
    super.key,
    required this.cameras,
    required this.illustrationAsset,
    required this.title,
    required this.description,
    required this.nextButtonAsset,
    required this.onNext,
    required this.onSkip,
    required this.indicatorIndex,
    required this.indicatorCount,
    this.backgroundAsset = 'assets/images/onboarding/bg_onboarding.png',
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    const Color brandDeepGreen = Color(
      0xFF294B29,
    ); // warna 'Lewati' yang kamu minta

    // Dots indikator (aktif pakai brandDeepGreen)
    Widget dots(int current, int total) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? Color.fromARGB(255, 113, 147, 37)
                  : Colors.green.withAlpha((255 * 0.3).round()),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onSkip,
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        color: brandDeepGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'assets/fonts/nunito/nunito-bold.ttf',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Image.asset(
                      illustrationAsset,
                      fit: BoxFit.contain,
                      width: size.width * 0.3,
                    ),
                  ),
                ),
                dots(indicatorIndex, indicatorCount),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: brandDeepGreen,
                    fontFamily: 'assets/fonts/nunito/nunito-extrabold.ttf',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    height: 1.5,
                    fontFamily: 'assets/fonts/roboto/roboto-regular.ttf',
                  ),
                ),
                const SizedBox(height: 36),
                Align(
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: onNext,
                    borderRadius: BorderRadius.circular(40),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Image.asset(nextButtonAsset, fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trashvisor/core/colors.dart';

// Panggil Supabase client secara global
final supabase = Supabase.instance.client;

class QuizResultPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;

  const QuizResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  bool _isClaiming = false;
  bool _hasClaimed = false;

  @override
  void initState() {
    super.initState();
    // Otomatis klaim hadiah jika ada jawaban benar
    if (widget.correctAnswers > 0) {
      _claimQuizReward();
    }
  }

  /// Menampilkan notifikasi sukses yang sudah disesuaikan gayanya.
  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selamat! +${widget.score} Poin telah ditambahkan.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: AppColors.bluest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.only(
          bottom: 100.0,
          left: 32.0,
          right: 32.0,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mengklaim hadiah kuis dengan memanggil Supabase RPC function.
  Future<void> _claimQuizReward() async {
    if (_isClaiming || _hasClaimed) return;

    setState(() {
      _isClaiming = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("Pengguna tidak login.");
      }

      // Panggil RPC Function untuk menambahkan poin
      await supabase.rpc('claim_quiz_reward', params: {
        'p_user_id': user.id,
        'p_mission_key': 'quiz',
        'p_points_to_add': widget.score,
      });

      if (mounted) {
        setState(() {
          _hasClaimed = true; // Tandai sudah berhasil klaim
        });
        _showSuccessSnackbar(); // Tampilkan notifikasi sukses
      }
    } catch (e) {
      // Di sini bisa ditambahkan logika untuk menangani error klaim
      debugPrint('Error claiming quiz reward: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/reward_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // --- Area Hasil Kuis dan Trofi ---
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trofi dengan latar belakang berlapis
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                          radius: 171, backgroundColor: AppColors.darkOliveGreen),
                      CircleAvatar(
                          radius: 170, backgroundColor: AppColors.lightSageGreen),
                      CircleAvatar(
                          radius: 151, backgroundColor: AppColors.darkOliveGreen),
                      CircleAvatar(
                          radius: 150, backgroundColor: AppColors.avocadoGreen),
                      CircleAvatar(
                          radius: 131, backgroundColor: AppColors.darkOliveGreen),
                      CircleAvatar(
                          radius: 130, backgroundColor: AppColors.fernGreen),
                      Image.asset(
                        'assets/images/features/throphy.png',
                        width: 165,
                        height: 165,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SELAMAT!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                      color: AppColors.fernGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kamu mendapatkan skor',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                        color: AppColors.fernGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.correctAnswers}/${widget.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: AppColors.fernGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Chips Hasil (Benar/Salah)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildResultChip(
                        icon: Icons.check_circle,
                        label: '${widget.correctAnswers}',
                        color: AppColors.fernGreen,
                      ),
                      const SizedBox(width: 16),
                      _buildResultChip(
                        icon: Icons.cancel,
                        label: '${widget.wrongAnswers}',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // --- Tombol Kembali ---
              ElevatedButton(
                onPressed: () {
                  // Kirim 'true' sebagai hasil saat kembali
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mossGreen,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Kembali ke Misi',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun widget Chip untuk menampilkan hasil (Benar/Salah).
  Widget _buildResultChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mossGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkOliveGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.white,
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trashvisor/core/colors.dart';
import 'package:intl/intl.dart';

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
    if (widget.correctAnswers > 0) {
      _claimQuizReward();
    }
  }

  Future<void> _claimQuizReward() async {
    // Tambahkan logika untuk menangani skor 0 dan mencegah klaim jika skor <= 0
    if (widget.score <= 0) {
      if (mounted) {
        // Notifikasi bahwa kuis bisa diulang jika skor 0
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Skor 0. Kuis bisa diulang!',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_isClaiming || _hasClaimed) return;
    setState(() => _isClaiming = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("Pengguna tidak login.");

      // Ambil tanggal hari ini (waktu lokal perangkat)
      final DateTime now = DateTime.now();
      // Format tanggal ke string YYYY-MM-DD
      final String todayDateString = DateFormat('yyyy-MM-dd').format(now);

      await supabase.rpc(
        'claim_quiz_reward_new',
        params: {
          'p_user_id': user.id,
          'p_mission_key': 'quiz',
          'p_points_to_add': widget.score,
          'p_local_date': todayDateString,
        },
      );

      if (mounted) {
        setState(() => _hasClaimed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selamat! +${widget.score} poin telah ditambahkan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Error 42P10 (ON CONFLICT) akan hilang dengan RPC yang baru
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengklaim poin: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil informasi ukuran layar
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Menentukan ukuran dasar berdasarkan lebar layar
    // Ini membantu skala elemen secara proporsional
    final double baseRadius = screenWidth * 0.34; // Untuk piala

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg/bg_reward.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Ilustrasi Piala dengan ukuran dinamis
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: baseRadius,
                    backgroundColor: AppColors.darkOliveGreen,
                  ),
                  CircleAvatar(
                    radius: baseRadius - 0.5,
                    backgroundColor: AppColors.lightSageGreen,
                  ),
                  CircleAvatar(
                    radius: baseRadius - 10.5,
                    backgroundColor: AppColors.darkOliveGreen,
                  ),
                  CircleAvatar(
                    radius: baseRadius - 10,
                    backgroundColor: AppColors.avocadoGreen,
                  ),
                  CircleAvatar(
                    radius: baseRadius - 20.5,
                    backgroundColor: AppColors.darkOliveGreen,
                  ),
                  CircleAvatar(
                    radius: baseRadius - 20,
                    backgroundColor: AppColors.fernGreen,
                  ),
                  Image.asset(
                    'assets/images/features/throphy.png',
                    width: baseRadius * 1.5,
                    height: baseRadius * 1.5,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Teks dengan ukuran font dinamis
              Text(
                'SELAMAT!',
                style: TextStyle(
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  color: AppColors.fernGreen,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Kamu mendapatkan skor',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  color: AppColors.fernGreen,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '${widget.correctAnswers}/${widget.totalQuestions}',
                style: TextStyle(
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
                  color: AppColors.fernGreen,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 24),

              // Ringkasan Benar / Salah
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

              const Spacer(flex: 2),

              // Tombol Kembali
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mossGreen,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Kembali ke Misi',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.05), // Jarak dari bawah layar
            ],
          ),
        ),
      ),
    );
  }

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.15).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.white,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }
}

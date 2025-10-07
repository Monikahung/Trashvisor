import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trashvisor/core/colors.dart';
import 'quiz_result_page.dart';

final supabase = Supabase.instance.client;

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  late List<String?> _userAnswers;

  bool _isLoading = true;
  List<Question> _questions = [];

  Timer? _timer;
  int _secondsLeft = 30;
  static const int _questionDuration = 30;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    // ... (Fungsi ini tidak perlu diubah)
    try {
      final response = await supabase.from('questions').select().limit(10);
      if (!mounted) return;

      final List<Question> fetchedQuestions = (response as List).map((data) {
        return Question.fromMap(data);
      }).toList();
      fetchedQuestions.shuffle();

      setState(() {
        _questions = fetchedQuestions;
        _userAnswers = List<String?>.filled(_questions.length, null);
        _isLoading = false;
      });
      _resetAndStartTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat soal: $e')),
      );
    }
  }

  void _resetAndStartTimer() {
    // ... (Fungsi ini tidak perlu diubah)
    _timer?.cancel();
    setState(() {
      _secondsLeft = _questionDuration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _nextQuestion();
      }
    });
  }

  void _calculateAndShowResults() async {
    // ... (Fungsi ini tidak perlu diubah)
    _timer?.cancel();
    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      int? userAnswerIndex;
      switch (_userAnswers[i]) {
        case 'A':
          userAnswerIndex = 0;
          break;
        case 'B':
          userAnswerIndex = 1;
          break;
        case 'C':
          userAnswerIndex = 2;
          break;
        case 'D':
          userAnswerIndex = 3;
          break;
        default:
          userAnswerIndex = null;
      }
      if (userAnswerIndex != null &&
          userAnswerIndex == _questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final int totalQuestions = _questions.length;
    final int wrongAnswers = totalQuestions - correctAnswers;
    final int score =
    totalQuestions > 0 ? ((correctAnswers / totalQuestions) * 100).round() : 0;

    final result = await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultPage(
          score: score,
          totalQuestions: totalQuestions,
          correctAnswers: correctAnswers,
          wrongAnswers: wrongAnswers,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _nextQuestion() {
    // ... (Fungsi ini tidak perlu diubah)
    _resetAndStartTimer();
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
      });
    } else {
      _calculateAndShowResults();
    }
  }

  void _previousQuestion() {
    // ... (Fungsi ini tidak perlu diubah)
    _resetAndStartTimer();
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = _userAnswers[_currentQuestionIndex];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.mossGreen,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.mossGreen,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Gagal memuat soal. Pastikan koneksi internet Anda stabil dan soal sudah tersedia.',
              textAlign: TextAlign.center,
              // --- PERUBAHAN: Menggunakan style Body Text ---
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    // --- PERUBAHAN: Mendapatkan ukuran layar untuk responsivitas ---
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // --- PERUBAHAN: Menggunakan style Heading 2 (Nunito, 20, SemiBold) ---
    const questionTextStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 20,
      fontWeight: FontWeight.w600, // SemiBold
      color: AppColors.deepForestGreen,
    );

    // --- PERUBAHAN: Lebar maksimal teks disesuaikan dengan lebar layar ---
    final double textMaxWidth = screenWidth - (screenWidth * 0.2) - (24 * 2);

    final textPainter = TextPainter(
      text:
      TextSpan(text: currentQuestion.questionText, style: questionTextStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxWidth);

    final lineCount = textPainter.computeLineMetrics().length;

    // --- PERUBAHAN: Padding atas disesuaikan dengan tinggi layar ---
    double paddingTopValue;
    if (lineCount >= 5) {
      paddingTopValue = screenHeight * 0.13;
    } else if (lineCount == 4) {
      paddingTopValue = screenHeight * 0.11;
    } else {
      paddingTopValue = screenHeight * 0.09;
    }

    return Scaffold(
      backgroundColor: AppColors.mossGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              // --- PERUBAHAN: Padding horizontal relatif terhadap lebar layar ---
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: _buildHeader(),
            ),
            // --- PERUBAHAN: Spasi vertikal relatif terhadap tinggi layar ---
            SizedBox(height: screenHeight * 0.03),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 50,
                    // --- PERUBAHAN: Posisi kiri dan kanan relatif ---
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    bottom: 30,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.045, // Padding relatif
                          paddingTopValue,
                          screenWidth * 0.045, // Padding relatif
                          16),
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/images/bg/bg_bubble_quiz.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(40),
                        border:
                        Border.all(color: AppColors.fernGreen, width: 2),
                      ),
                      child: SingleChildScrollView(
                        child: _buildAnswerOptions(currentQuestion.options),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    // --- PERUBAHAN: Posisi kiri dan kanan relatif ---
                    left: screenWidth * 0.1,
                    right: screenWidth * 0.1,
                    child: _buildQuestionCard(currentQuestion.questionText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
              // --- PERUBAHAN: Menggunakan style Small Text (Roboto, 14, Regular) ---
              label: Text('Keluar', style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AppColors.darkMossGreen,
              ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.darkMossGreen,
                backgroundColor: AppColors.white,
                shape: const StadiumBorder(),
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.white,
              child: Text(
                '$_secondsLeft',
                // --- PERUBAHAN: Style disamakan dengan Button Text (Nunito, 16, Bold) ---
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.darkMossGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'Soal ${_currentQuestionIndex + 1}/${_questions.length}',
            // --- PERUBAHAN: Menggunakan style Heading 1 (Nunito, 24, Bold) ---
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: List.generate(_questions.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: index < _currentQuestionIndex
                            ? AppColors.lightSageGreen.withOpacity(0.6)
                            : index == _currentQuestionIndex
                            ? AppColors.lightSageGreen
                            : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 6),
            if (isLastQuestion)
              ElevatedButton(
                onPressed: _calculateAndShowResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightSageGreen,
                  foregroundColor: AppColors.deepForestGreen,
                  shape: const StadiumBorder(),
                  // --- PERUBAHAN: Padding relatif ---
                  padding:
                  EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 12),
                ),
                child: const Text(
                  'Selesai',
                  // --- PERUBAHAN: Menggunakan style Button Text (Nunito, 16, Bold) ---
                  style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, fontSize: 16),
                ),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.white,
                child: IconButton(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.darkMossGreen, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      width: double.infinity,
      // --- PERUBAHAN: Padding relatif ---
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: AppColors.rewardCardBg,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.fernGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        question,
        textAlign: TextAlign.center,
        // --- PERUBAHAN: Menggunakan style Heading 2 (Nunito, 20, SemiBold) ---
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w600, // SemiBold
          color: AppColors.deepForestGreen,
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(List<String> options) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnswerOption(option: 'A', text: options[0]),
        _buildAnswerOption(option: 'B', text: options[1]),
        _buildAnswerOption(option: 'C', text: options[2]),
        _buildAnswerOption(option: 'D', text: options[3]),
      ],
    );
  }

  Widget _buildAnswerOption({required String option, required String text}) {
    final bool isSelected = _selectedAnswer == option;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnswer = option;
          _userAnswers[_currentQuestionIndex] = option;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.oliveGreen : AppColors.rewardCardBg,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.fernGreen, width: 2),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.oliveGreen.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.lightSageGreen
                    : AppColors.whiteSmoke.withOpacity(0.7),
                border: Border.all(
                    color: isSelected
                        ? AppColors.darkMossGreen
                        : AppColors.darkMossGreen),
              ),
              child: Text(
                option,
                // --- PERUBAHAN: Style untuk huruf Opsi (A, B, C, D) ---
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkMossGreen,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: Text(
                  text,
                  // --- PERUBAHAN: Menggunakan style Body Text (Roboto, 16, Regular) ---
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color:
                    isSelected ? AppColors.white : AppColors.darkMossGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASS MODEL UNTUK DATA SOAL ---
class Question {
  // ... (Class ini tidak perlu diubah)
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  const Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final List<String> options = [
      map['option_a'] as String,
      map['option_b'] as String,
      map['option_c'] as String,
      map['option_d'] as String,
    ];

    int correctIndex;
    switch (map['correct_answer']) {
      case 'A':
        correctIndex = 0;
        break;
      case 'B':
        correctIndex = 1;
        break;
      case 'C':
        correctIndex = 2;
        break;
      case 'D':
        correctIndex = 3;
        break;
      default:
        correctIndex = 0;
    }

    return Question(
      questionText: map['question_text'] as String,
      options: options,
      correctAnswerIndex: correctIndex,
    );
  }
}
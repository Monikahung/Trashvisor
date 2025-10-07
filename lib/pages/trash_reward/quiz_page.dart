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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat soal: $e')));
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
    final int score = totalQuestions > 0
        ? ((correctAnswers / totalQuestions) * 100).round()
        : 0;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.mossGreen,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.whiteSmoke),
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
            icon: const Icon(Icons.arrow_back, color: AppColors.whiteSmoke),
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
                fontSize: 14,
                color: AppColors.whiteSmoke,
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    const questionTextStyle = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      color: AppColors.darkOliveGreen,
    );

    // --- Lebar maksimal teks disesuaikan dengan lebar layar ---
    final double textMaxWidth = screenWidth - (screenWidth * 0.2) - (24 * 2);

    final textPainter = TextPainter(
      text: TextSpan(
        text: currentQuestion.questionText,
        style: questionTextStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxWidth);

    final lineCount = textPainter.computeLineMetrics().length;

    // Jarak TOP Bubble Jawaban
    const double answerBubbleTop = 50.0;

    // Jarak TOP Kotak Soal
    const double questionCardTop = 10.0;

    // --- Padding atas disesuaikan dengan tinggi layar ---
    double paddingTopValue;
    if (lineCount >= 7) {
      paddingTopValue = screenHeight * 0.17;
    } else if (lineCount == 6) {
      paddingTopValue = screenHeight * 0.15;
    } else if (lineCount == 5) {
      paddingTopValue = screenHeight * 0.13;
    } else if (lineCount == 4) {
      paddingTopValue = screenHeight * 0.12;
    } else if (lineCount == 3) {
      paddingTopValue = screenHeight * 0.09;
    } else if (lineCount == 2) {
      paddingTopValue = screenHeight * 0.07;
    } else {
      paddingTopValue = screenHeight * 0.05;
    }

    return Scaffold(
      backgroundColor: AppColors.mossGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              // --- Padding horizontal relatif terhadap lebar layar ---
              padding: EdgeInsets.only(
                left: screenWidth * 0.07,
                right: screenWidth * 0.07,
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.02,
              ),
              child: _buildHeader(),
            ),
            // --- Spasi vertikal relatif terhadap tinggi layar ---
            SizedBox(height: screenHeight * 0.01),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // 1. KOTAK JAWABAN (Bubble Background)
                  Positioned(
                    top: answerBubbleTop, // 50.0
                    left: screenWidth * 0.07,
                    right: screenWidth * 0.07,
                    child: IntrinsicHeight(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.055,
                          paddingTopValue,
                          screenWidth * 0.055,
                          16,
                        ),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/images/bg/bg_bubble_quiz.png',
                            ),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: AppColors.fernGreen,
                            width: 2,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: _buildAnswerOptions(currentQuestion.options),
                        ),
                      ),
                    ),
                  ),
                  // 2. KOTAK SOAL (Melayang)
                  Positioned(
                    top: questionCardTop, // 10.0
                    left: screenWidth * 0.125,
                    right: screenWidth * 0.125,
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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: AppColors.darkOliveGreen,
              ),
              // --- PERUBAHAN: Menggunakan style Small Text (Roboto, 14, Regular) ---
              label: Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkOliveGreen,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.darkOliveGreen,
                backgroundColor: AppColors.whiteSmoke,
                shape: const StadiumBorder(),
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.whiteSmoke,
              child: Text(
                '$_secondsLeft',
                // --- PERUBAHAN: Style disamakan dengan Button Text (Nunito, 16, Bold) ---
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.darkOliveGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'Soal ${_currentQuestionIndex + 1}/${_questions.length}',
            // --- PERUBAHAN: Menggunakan style Heading 1 (Nunito, 24, Bold) ---
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppColors.whiteSmoke,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 5),
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
                            ? AppColors.lightSageGreen.withAlpha(
                                (255 * 0.6).round(),
                              )
                            : index == _currentQuestionIndex
                            ? AppColors.lightSageGreen
                            : Colors.black.withAlpha((255 * 0.2).round()),
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
                  backgroundColor: AppColors.whiteSmoke,
                  foregroundColor: AppColors.darkOliveGreen,
                  shape: const StadiumBorder(),
                  // --- PERUBAHAN: Padding relatif ---
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Selesai',
                  // --- PERUBAHAN: Menggunakan style Button Text (Nunito, 16, Bold) ---
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.whiteSmoke,
                child: IconButton(
                  onPressed: _nextQuestion,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.darkOliveGreen,
                    size: 24,
                  ),
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
        color: AppColors.rewardCardBg.withAlpha((255 * 0.995).round()),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.fernGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
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
          fontFamily: 'Roboto',
          fontSize: 15,
          color: AppColors.darkOliveGreen,
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
        padding: const EdgeInsets.symmetric(vertical: 5),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.oliveGreen.withAlpha((255 * 0.995).round())
              : AppColors.rewardCardBg.withAlpha((255 * 0.995).round()),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.fernGreen, width: 1.5),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.oliveGreen.withAlpha((255 * 0.5).round()),
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
                    : AppColors.whiteSmoke.withAlpha((255 * 0.7).round()),
                border: Border.all(
                  color: isSelected
                      ? AppColors.darkOliveGreen
                      : AppColors.darkOliveGreen,
                ),
              ),
              child: Text(
                option,
                // --- PERUBAHAN: Style untuk huruf Opsi (A, B, C, D) ---
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: AppColors.darkOliveGreen,
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
                    fontSize: 15,
                    color: isSelected
                        ? AppColors.whiteSmoke
                        : AppColors.darkOliveGreen,
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

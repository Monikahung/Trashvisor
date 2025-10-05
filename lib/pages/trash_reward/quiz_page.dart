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

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
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

  void _calculateAndShowResults() async { // Tambahkan async
    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      int? userAnswerIndex;
      switch (_userAnswers[i]) {
        case 'A': userAnswerIndex = 0; break;
        case 'B': userAnswerIndex = 1; break;
        case 'C': userAnswerIndex = 2; break;
        default: userAnswerIndex = 3;
      }
      if (userAnswerIndex == _questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    final int totalQuestions = _questions.length;
    final int wrongAnswers = totalQuestions - correctAnswers;
    final int score = totalQuestions > 0 ? ((correctAnswers / totalQuestions) * 100).round() : 0;

    // --- PERUBAHAN UTAMA DI SINI ---
    // Tunggu hasil dari halaman QuizResultPage
    final result = await Navigator.push( // Ganti dari pushReplacement
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

    // Jika QuizResultPage kembali dengan sinyal 'true',
    // maka tutup juga QuizPage ini dan kirim sinyal 'true' ke belakang
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
    // --- AKHIR PERUBAHAN ---
  }

  void _nextQuestion() {
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
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Gagal memuat soal. Pastikan koneksi internet Anda stabil dan soal sudah tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final mediaQuery = MediaQuery.of(context);

    const questionTextStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.deepForestGreen,
    );

    final double textMaxWidth = mediaQuery.size.width - (55 * 2) - (24 * 2);

    final textPainter = TextPainter(
      text: TextSpan(text: currentQuestion.questionText, style: questionTextStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textMaxWidth);

    final lineCount = textPainter.computeLineMetrics().length;

    double paddingTopValue;
    if (lineCount >= 5) {
      paddingTopValue = 150.0;
    } else if (lineCount == 4) {
      paddingTopValue = 130.0;
    } else {
      paddingTopValue = 100.0;
    }

    return Scaffold(
      backgroundColor: AppColors.mossGreen,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 70,
                    left: 30,
                    right: 30,
                    bottom: 40,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(22, paddingTopValue, 22, 18),
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('assets/images/bg/bg_bubble_quiz.png'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: AppColors.fernGreen, width: 2),
                      ),
                      child: SingleChildScrollView(
                        child: _buildAnswerOptions(currentQuestion.options),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 55,
                    right: 55,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              label: const Text('Keluar'),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.darkMossGreen,
                backgroundColor: AppColors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'Soal ${_currentQuestionIndex + 1}/${_questions.length}',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
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
                      height: 8,
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
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.white,
              child: IconButton(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.chevron_left, color: AppColors.darkMossGreen, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 8),
            if (isLastQuestion)
              ElevatedButton(
                onPressed: _calculateAndShowResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightSageGreen,
                  foregroundColor: AppColors.deepForestGreen,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.white,
                child: IconButton(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.chevron_right, color: AppColors.darkMossGreen, size: 24),
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
      padding: const EdgeInsets.all(24),
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
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(vertical: 12),
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
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.lightSageGreen : AppColors.whiteSmoke.withOpacity(0.7),
                border: Border.all(
                    color: isSelected ? AppColors.darkMossGreen : AppColors.darkMossGreen),
              ),
              child: Text(
                option,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.darkMossGreen : AppColors.darkMossGreen,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.darkMossGreen,
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
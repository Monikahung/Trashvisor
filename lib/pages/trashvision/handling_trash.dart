import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/colors.dart';

class HandlingTrash extends StatefulWidget {
  final String trashType;
  const HandlingTrash({super.key, required this.trashType});

  @override
  State<HandlingTrash> createState() => _HandlingTrashState();
}

class _HandlingTrashState extends State<HandlingTrash> {
  String _generatedContent = "Memuat saran...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHandlingSuggestions();
  }

  Future<void> _fetchHandlingSuggestions() async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null) {
        setState(() {
          _generatedContent = "Gagal memuat: API Key tidak ditemukan.";
          _isLoading = false;
        });
        return;
      }

      final prompt =
          "Berikan 5 saran praktis dalam bentuk bullet points dengan judul singkat di setiap poin untuk penanganan sampah jenis ${widget.trashType} dalam bahasa indonesia. Gunakan format berikut: <emoji> Judul - Deskripsi. Pisahkan setiap poin dengan karakter '|'. Contoh: ♻️ Daur Ulang - Ubah botol plastik bekas menjadi barang baru, seperti pot tanaman.";

      final uri = Uri.parse('https://api.openai.com/v1/completions');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo-instruct",
          "prompt": prompt,
          "temperature": 0.7,
          "max_tokens": 256,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['choices'][0]['text'].trim();

        if (!mounted) return; // ✅ pastikan widget masih ada
        setState(() {
          _generatedContent = rawText;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _generatedContent = "Gagal mengambil data: ${response.statusCode}";
          _isLoading = false;
          debugPrint("Respons Gagal: ${response.body}");
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generatedContent = "Terjadi kesalahan: $e";
        _isLoading = false;
        debugPrint("Error: $e");
      });
    }
  }

  Widget _buildHandlingCard({
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fernGreen.withAlpha((255 * 0.15).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fernGreen, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkMossGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // Logika parsing yang diperbarui
    final List<String> rawSuggestions = _generatedContent.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final List<Widget> cards = [];

    for (var s in rawSuggestions) {
      final cleanString = s.trim();
      final dashIndex = cleanString.indexOf(' - ');

      if (dashIndex != -1) {
        final title = cleanString.substring(0, dashIndex).trim();
        final description = cleanString.substring(dashIndex + 3).trim();
        if (title.isNotEmpty && description.isNotEmpty) {
          cards.add(_buildHandlingCard(
            title: title,
            description: description,
          ));
          cards.add(const SizedBox(height: 16));
        }
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: screenSize.width,
                  height: screenSize.height * 0.35,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteSmoke,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/images/bg_handling.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha((255 * 0.3).round()),
                          Colors.transparent,
                          Colors.black.withAlpha((255 * 0.3).round()),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: screenSize.height * 0.06,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.fernGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.whiteSmoke, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saran Penanganan Sampah ${widget.trashType.replaceAll('_', ' ')}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temukan tindakan yang ramah lingkungan untuk menangani sampah demi kelestarian bumi.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.fernGreen,
                      ),
                    )
                  else if (cards.isEmpty)
                    const Text('Maaf, tidak ada saran yang ditemukan.')
                  else
                    ...cards,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
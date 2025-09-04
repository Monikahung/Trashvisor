import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'capsule_models.dart';

/// Service: langsung call OpenAI dari Flutter (PROTOTYPE)
/// - AMAN? Tidak. Untuk produksi, pindahkan ke server/edge function.
/// - Feature:
///   * 5 narasi + 5 gambar (768 px)
///   * Fallback asset & narasi jika gagal
///   * Log ke Supabase (simulation_logs)
class CapsuleService {
  final _client = Supabase.instance.client;
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 45),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Hitung jumlah *jenis sampah unik* yang dibuat hari ini (UX only).
  Future<int> countDistinctToday() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day).toIso8601String();

    final rows = await _client
        .from('simulation_logs')
        .select('waste_type')
        .gte('created_at', start)
        .eq('user_id', user.id);

    final set = <String>{};
    for (final r in rows as List) {
      final wt = (r['waste_type'] as String?)?.trim();
      if (wt != null && wt.isNotEmpty) set.add(wt.toLowerCase());
    }
    return set.length;
  }

  /// Generate 5 narasi + 5 gambar via OpenAI.
  /// Jika gagal → fallback lokal (asset + narasi default kontekstual).
  Future<CapsuleResult> generate({
    required String wasteType,
    required CapsuleScenario scenario,
  }) async {
    final openaiKey = dotenv.env['OPENAI_IMAGE_KEY_CAPSULE'];
    final good = scenario == CapsuleScenario.good;
    final waste = (wasteType.trim().isEmpty) ? 'sampah plastik' : wasteType.trim();

    // (Optional UX) Rate limit 2 jenis/hari di klien — tidak ngeblok.
    try {
      final n = await countDistinctToday();
      if (n >= 2) {
        // boleh tampilkan banner di UI kalau mau; di sini kita tetap lanjut.
      }
    } catch (_) {}

    // --------------- panggil OpenAI ---------------
    try {
      if (openaiKey == null || openaiKey.isEmpty) {
        throw Exception('OPENAI_IMAGE_KEY_CAPSULE tidak ditemukan di .env');
      }

      final authHeader = {'Authorization': 'Bearer $openaiKey'};

      // 1) Narasi (pakai Chat Completions supaya mudah JSON)
      final String narrativePrompt = _buildNarrativePrompt(waste, good);
      final chatResp = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: authHeader),
        data: {
          'model': 'gpt-4o-mini', // ringan & murah
          'temperature': 0.7,
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content':
                  'Kamu asisten edukasi pengelolaan sampah. Jawab dalam JSON sederhana.'
            },
            {
              'role': 'user',
              'content': narrativePrompt,
            }
          ],
        },
      );

      final content =
          chatResp.data['choices'][0]['message']['content'] as String;
      final Map<String, dynamic> j = json.decode(content);
      final List<dynamic> jItems = (j['items'] as List);

      // 2) Gambar (5 buah, 768px)
      final String imagePrompt = _buildImagePrompt(waste, good);
      final imgResp = await _dio.post(
        'https://api.openai.com/v1/images/generations',
        options: Options(headers: authHeader),
        data: {
          'model': 'gpt-image-1',
          'prompt': imagePrompt,
          'n': 5,
          'size': '768x768',
          'quality': 'high',
        },
      );

      final List<dynamic> imgList = imgResp.data['data'];
      final List<String?> urls = imgList.map((e) => e['url'] as String?).toList();

      // 3) Gabungkan jadi 5 item + fallback asset default
      final prefix =
          good ? 'assets/images/true_capsule' : 'assets/images/false_capsule';

      final items = <CapsuleItem>[];
      for (var i = 0; i < 5; i++) {
        final m = (jItems[i] as Map<String, dynamic>);
        items.add(
          CapsuleItem(
            title: (m['title'] as String).trim(),
            description: (m['description'] as String).trim(),
            imageUrl: (urls.length > i) ? urls[i] : null,
            fallbackAsset: '${prefix}${i == 0 ? '' : '_${i + 1}'}.png',
          ),
        );
      }

      final result = CapsuleResult(items: items, seed: _seed());
      await _logSimulation(waste, scenario, result);
      return result;
    } catch (_) {
      // --------------- fallback lokal ---------------
      final items = _fallbackItems(waste, scenario);
      final result =
          CapsuleResult(items: items, seed: 'local-${DateTime.now().millisecondsSinceEpoch}');
      await _logSimulation(waste, scenario, result);
      return result;
    }
  }

  // ---------- Helpers ----------

  String _seed() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _logSimulation(
      String wasteType, CapsuleScenario scenario, CapsuleResult result) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final imageUrls =
        result.items.map((e) => e.imageUrl ?? e.fallbackAsset ?? '').toList();
    final texts =
        result.items.map((e) => '${e.title}: ${e.description}').toList();

    try {
      await _client.from('simulation_logs').insert({
        'user_id': user.id,
        'waste_type': wasteType,
        'scenario': scenario.db, // 'BAIK' / 'BURUK'
        'image_urls': imageUrls,
        'texts': texts,
        'seed': result.seed,
      });
    } catch (_) {
      // abaikan error logging di prototype
    }
  }

  String _buildNarrativePrompt(String waste, bool good) {
    final titlesGood = [
      'Lingkungan Sehat',
      'Udara Bersih',
      'Sumber Terjaga',
      'Ekonomi Tumbuh',
      'Generasi Sehat',
    ];
    final titlesBad = [
      'Lingkungan Rusak',
      'Udara Tercemar',
      'Sumber Habis',
      'Ekonomi Rugi',
      'Generasi Terancam',
    ];

    final titles = good ? titlesGood : titlesBad;

    // Minta JSON { "items": [ { "title": "...", "description": "..." }, ... ] }
    return '''
Buat 5 narasi pendek (maks 2 kalimat, bahasa Indonesia natural) tentang dampak ${(good ? 'pengelolaan yang benar' : 'pengelolaan yang buruk')} untuk $waste.
Judul harus PERSIS berurutan:
${titles.map((t) => '- $t').join('\n')}
Tolong jawab dalam JSON valid:
{
  "items": [
    {"title":"${titles[0]}","description":"..."},
    {"title":"${titles[1]}","description":"..."},
    {"title":"${titles[2]}","description":"..."},
    {"title":"${titles[3]}","description":"..."},
    {"title":"${titles[4]}","description":"..."}
  ]
}
''';
  }

  String _buildImagePrompt(String waste, bool good) {
    // Prompt ringkas. Tiap request n=5 → minta variasi adegan yang merepresentasikan 5 aspek.
    // Semi-realistic, nuansa Indonesia, palet warna seimbang.
    return '''
${good ? 'Penanganan baik' : 'Penanganan buruk'} untuk $waste.
Buat lima ilustrasi semi-realistic bergaya edukatif dengan variasi adegan berbeda
yang merepresentasikan lima aspek dampak. Setting Indonesia (pepohonan tropis,
permukiman, sungai/laut khas Nusantara), palet warna seimbang (tidak terlalu gelap).
Rasio 1:1, detail jelas, tanpa teks di dalam gambar.
''';
  }

  // --------- Fallback lokal 5 kartu ---------
  List<CapsuleItem> _fallbackItems(String waste, CapsuleScenario scenario) {
    final good = scenario == CapsuleScenario.good;
    final prefix =
        good ? 'assets/images/true_capsule' : 'assets/images/false_capsule';

    if (good) {
      return [
        CapsuleItem(
          title: 'Lingkungan Sehat',
          description:
              'Pengelolaan $waste yang benar menjaga sungai, laut, dan tanah tetap bersih.',
          fallbackAsset: '$prefix.png',
        ),
        CapsuleItem(
          title: 'Udara Bersih',
          description: 'Polusi berkurang karena $waste tidak dibakar sembarangan.',
          fallbackAsset: '${prefix}_2.png',
        ),
        CapsuleItem(
          title: 'Sumber Terjaga',
          description:
              'Pemilahan & daur ulang $waste membantu melestarikan sumber daya alam.',
          fallbackAsset: '${prefix}_3.png',
        ),
        CapsuleItem(
          title: 'Ekonomi Tumbuh',
          description: '$waste yang dikelola baik bisa jadi peluang ekonomi sirkular.',
          fallbackAsset: '${prefix}_4.png',
        ),
        CapsuleItem(
          title: 'Generasi Sehat',
          description: 'Lingkungan bersih dari $waste membuat bumi tetap layak huni.',
          fallbackAsset: '${prefix}_5.png',
        ),
      ];
    } else {
      return [
        CapsuleItem(
          title: 'Lingkungan Rusak',
          description: '$waste yang tercecer mencemari sungai, laut, dan tanah.',
          fallbackAsset: '$prefix.png',
        ),
        CapsuleItem(
          title: 'Udara Tercemar',
          description: 'Pembakaran $waste menghasilkan asap berbahaya.',
          fallbackAsset: '${prefix}_2.png',
        ),
        CapsuleItem(
          title: 'Sumber Habis',
          description:
              'Produksi $waste baru tanpa daur ulang menguras sumber daya alam.',
          fallbackAsset: '${prefix}_3.png',
        ),
        CapsuleItem(
          title: 'Ekonomi Rugi',
          description:
              'Potensi ekonomi dari $waste terbuang, biaya pengelolaan meningkat.',
          fallbackAsset: '${prefix}_4.png',
        ),
        CapsuleItem(
          title: 'Generasi Terancam',
          description:
              'Pencemaran $waste memperburuk kualitas hidup generasi mendatang.',
          fallbackAsset: '${prefix}_5.png',
        ),
      ];
    }
  }
}

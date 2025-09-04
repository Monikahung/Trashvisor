import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'capsule_models.dart';

/// Service: panggil Edge Function + catat log + siapkan fallback
class CapsuleService {
  final _client = Supabase.instance.client;

  /// Cek berapa jenis sampah unik yang sudah dibuat hari ini (client-side UX).
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

  /// Panggil Edge Function. Jika gagal/timeout → fallback asset & narasi default.
  Future<CapsuleResult> generate({
    required String wasteType,
    required CapsuleScenario scenario,
  }) async {
    // OPTIONAL UX limit: 2 jenis/hari (enforce server-side juga ya).
    try {
      final distinct = await countDistinctToday();
      if (distinct >= 2) {
        // biarkan lanjut panggil API; kalau mau hard-block di klien, lempar exception di sini.
      }
    } catch (_) {}

    try {
      final res = await _client.functions.invoke(
        'capsule-generate',
        body: {
          'waste_type': wasteType,
          'scenario': scenario.wire, // 'good' | 'bad'
          'image_size': 768,         // hint untuk generator
        },
      );

      // Supabase FunctionsResponse.data bisa Map atau String JSON
      final data = res.data;
      final map =
          (data is Map<String, dynamic>) ? data : json.decode(data as String);
      final result = CapsuleResult.fromJson(map);

      // Simpan log
      await _logSimulation(wasteType, scenario, result);
      return result;
    } catch (_) {
      // Fallback lokal (pakai asset yang sudah ada di proyek)
      final items = _fallbackItems(wasteType, scenario);
      final result =
          CapsuleResult(items: items, seed: 'local-fallback-${DateTime.now().millisecondsSinceEpoch}');
      await _logSimulation(wasteType, scenario, result);
      return result;
    }
  }

  Future<void> _logSimulation(
      String wasteType, CapsuleScenario scenario, CapsuleResult result) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final imageUrls = result.items
        .map((e) => e.imageUrl ?? e.fallbackAsset ?? '')
        .toList();
    final texts =
        result.items.map((e) => '${e.title}: ${e.description}').toList();

    await _client.from('simulation_logs').insert({
      'user_id': user.id,
      'waste_type': wasteType,
      'scenario': scenario.db, // 'BAIK' / 'BURUK'
      'image_urls': imageUrls,
      'texts': texts,
      'seed': result.seed,
    });
  }

  // --------- Fallback lokal 5 kartu ---------
  List<CapsuleItem> _fallbackItems(
      String wasteType, CapsuleScenario scenario) {
    final w = wasteType.toLowerCase();
    final good = scenario == CapsuleScenario.good;

    // pilih prefix asset defaultmu
    final prefix = good ? 'assets/images/true_capsule' : 'assets/images/false_capsule';

    if (good) {
      return [
        CapsuleItem(
          title: 'Lingkungan Sehat',
          description:
              'Pengelolaan $w yang benar menjaga sungai, laut, dan tanah tetap bersih.',
          fallbackAsset: '$prefix.png',
        ),
        CapsuleItem(
          title: 'Udara Bersih',
          description:
              'Polusi berkurang karena $w tidak dibakar sembarangan.',
          fallbackAsset: '${prefix}_2.png',
        ),
        CapsuleItem(
          title: 'Sumber Terjaga',
          description:
              'Pemilahan & daur ulang $w membantu melestarikan sumber daya alam.',
          fallbackAsset: '${prefix}_3.png',
        ),
        CapsuleItem(
          title: 'Ekonomi Tumbuh',
          description:
              '$w yang dikelola baik bisa jadi peluang ekonomi sirkular.',
          fallbackAsset: '${prefix}_4.png',
        ),
        CapsuleItem(
          title: 'Generasi Sehat',
          description:
              'Lingkungan bersih dari $w membuat bumi tetap layak huni.',
          fallbackAsset: '${prefix}_5.png',
        ),
      ];
    } else {
      return [
        CapsuleItem(
          title: 'Lingkungan Rusak',
          description:
              '$w yang tercecer mencemari sungai, laut, dan tanah.',
          fallbackAsset: '$prefix.png',
        ),
        CapsuleItem(
          title: 'Udara Tercemar',
          description:
              'Pembakaran $w menghasilkan asap berbahaya.',
          fallbackAsset: '${prefix}_2.png',
        ),
        CapsuleItem(
          title: 'Sumber Habis',
          description:
              'Produksi $w baru tanpa daur ulang menguras sumber daya alam.',
          fallbackAsset: '${prefix}_3.png',
        ),
        CapsuleItem(
          title: 'Ekonomi Rugi',
          description:
              'Potensi ekonomi dari $w terbuang, biaya pengelolaan meningkat.',
          fallbackAsset: '${prefix}_4.png',
        ),
        CapsuleItem(
          title: 'Generasi Terancam',
          description:
              'Pencemaran $w memperburuk kualitas hidup generasi mendatang.',
          fallbackAsset: '${prefix}_5.png',
        ),
      ];
    }
  }
}

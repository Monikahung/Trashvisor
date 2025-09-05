import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'capsule_models.dart';

/// Ubah ke `null` jika ingin mematikan limit di sisi klien.
const int? kDailyLimit = 2;

class CapsuleService {
  final _client = Supabase.instance.client;

  /// Berapa JENIS SAMPAH unik yang sukses dibuat hari ini (WIB).
  Future<int> countDistinctSuccessToday() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    // Coba pakai kolom created_on_jkt (stored). Kalau belum ada, fallback created_at.
    try {
      final rows = await _client
          .from('simulation_logs')
          .select('waste_type')
          .eq('user_id', user.id)
          .eq('success', true)
          .eq('created_on_jkt', _todayJakarta())
          .limit(1000);
      final set = <String>{};
      for (final r in rows as List) {
        final wt = (r['waste_type'] as String?)?.trim();
        if (wt != null && wt.isNotEmpty) set.add(wt.toLowerCase());
      }
      return set.length;
    } catch (_) {
      // Fallback: pakai created_at rentang hari UTC (approx)
      final nowUtc = DateTime.now().toUtc();
      final start =
          DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day).toIso8601String();
      final rows = await _client
          .from('simulation_logs')
          .select('waste_type')
          .gte('created_at', start)
          .eq('user_id', user.id)
          .eq('success', true);
      final set = <String>{};
      for (final r in rows as List) {
        final wt = (r['waste_type'] as String?)?.trim();
        if (wt != null && wt.isNotEmpty) set.add(wt.toLowerCase());
      }
      return set.length;
    }
  }

  /// Helper untuk UI: sisa limit hari ini (berdasarkan success saja).
  Future<int?> remainingLimit() async {
    if (kDailyLimit == null) return null;
    final used = await countDistinctSuccessToday();
    final remain = (kDailyLimit! - used).clamp(0, kDailyLimit!);
    return remain;
  }

  /// Panggil Edge Function. Jika gagal → fallback asset & narasi default.
  Future<CapsuleResult> generate({
    required String wasteType,
    required CapsuleScenario scenario,
  }) async {
    final wt = wasteType.trim();
    if (wt.isEmpty) {
      return CapsuleResult(
        items: _fallbackItems(wt, scenario),
        seed: 'local-empty',
        success: false,
        errorMessage: 'waste_type kosong',
      );
    }

    try {
      // Opsional: kirim info sisa kuota ke server.
      int? remaining;
      if (kDailyLimit != null) {
        remaining = await remainingLimit();
      }

      final res = await _client.functions.invoke(
        'capsule-generate',
        body: {
          'waste_type': wt,
          'scenario': scenario.wire, // 'good' | 'bad'
          'image_size': 768,
          if (remaining != null) 'client_remaining': remaining,
        },
      );

      final data = res.data;
      final map = (data is Map<String, dynamic>)
          ? data
          : json.decode(data as String);
      final result = CapsuleResult.fromJson(map);

      await _logSimulation(wt, scenario, result);
      return result;
    } catch (e) {
      final items = _fallbackItems(wt, scenario);
      final result = CapsuleResult(
        items: items,
        seed: 'local-fallback-${DateTime.now().millisecondsSinceEpoch}',
        success: false,
        errorMessage: '$e',
      );
      await _logSimulation(wt, scenario, result);
      return result;
    }
  }

  // ============ Helpers ============
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
      'success': result.success,
      if (result.errorMessage != null) 'error_message': result.errorMessage,
    });
  }

  List<CapsuleItem> _fallbackItems(String wasteType, CapsuleScenario scenario) {
    final w = wasteType.isEmpty ? 'sampah' : wasteType.toLowerCase();
    final good = scenario == CapsuleScenario.good;
    final prefix =
        good ? 'assets/images/true_capsule' : 'assets/images/false_capsule';

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
          description: '$w yang tercecer mencemari sungai, laut, dan tanah.',
          fallbackAsset: '$prefix.png',
        ),
        CapsuleItem(
          title: 'Udara Tercemar',
          description: 'Pembakaran $w menghasilkan asap berbahaya.',
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

  String _todayJakarta() {
    final nowUtc = DateTime.now().toUtc();
    final jkt = nowUtc.add(const Duration(hours: 7));
    return '${jkt.year.toString().padLeft(4, '0')}-'
        '${jkt.month.toString().padLeft(2, '0')}-'
        '${jkt.day.toString().padLeft(2, '0')}';
  }
}

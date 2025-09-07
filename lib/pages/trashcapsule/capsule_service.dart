import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'capsule_models.dart';

/// Ubah ke `null` jika ingin mematikan limit di sisi klien.
/// Jika tidak null, dipakai untuk menampilkan "sisa limit" di toast.
/// ------------------------------------------------------------------
/// NOTE:
/// - Yang dihitung: JENIS SAMPAH unik yang BERHASIL (success=true)
///   pada hari ini (zona waktu Jakarta).
/// - Dengan desain baru, `success=true` hanya jika
///   textSuccess && imageSuccess (keduanya OK) sehingga
///   **narasi saja tidak mengurangi limit**.
/// ------------------------------------------------------------------
const int? kDailyLimit = 2;

/// (Tetap) default, bila kamu nanti pakai generator gambar OpenAI.
/// Untuk Gemini text-only saat ini tidak dipakai, tapi biarkan ada.
const String kDefaultImageSize = '1024x1024';

class CapsuleService {
  final _client = Supabase.instance.client;

  /// Hitung berapa JENIS SAMPAH unik yang sukses dibuat hari ini (zona WIB).
  /// ----------------------------------------------------------------------
  /// Prefer kolom `created_on_jkt` (stored, timezone Asia/Jakarta).
  /// Jika di DB-mu kolom itu belum ada, fallback ke `created_at` UTC (approx).
  Future<int> countDistinctSuccessToday() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

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
      // Fallback: pakai created_at hari UTC (approx)
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

  /// Sisa limit hari ini (hanya hitung yang benar-benar success=true).
  Future<int?> remainingLimit() async {
    if (kDailyLimit == null) return null;
    final used = await countDistinctSuccessToday();
    return (kDailyLimit! - used).clamp(0, kDailyLimit!);
  }

  /// Panggil Edge Function. Jika gagal total → fallback asset lokal.
  /// ----------------------------------------------------------------------
  /// Alur:
  /// 1) Validasi input kosong → langsung fallback lokal (guard).
  /// 2) Invoke edge function 'capsule-generate'.
  /// 3) Parse hasil:
  ///    - Jika ITEMS ADA (narasi berhasil) → gunakan items tsb,
  ///      walaupun success=false (gambar gagal). Limit tidak berkurang.
  ///    - Jika ITEMS KOSONG → pakai fallback lokal.
  /// 4) Catat log ke tabel `simulation_logs` (best-effort).
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
      int? remaining;
      if (kDailyLimit != null) {
        remaining = await remainingLimit();
      }

      final res = await _client.functions.invoke(
        'capsule-generate',
        body: {
          'waste_type': wt,
          'scenario': scenario.wire, // 'good' | 'bad'
          // 'image_size': kDefaultImageSize, // tidak dipakai Gemini text
          if (remaining != null) 'client_remaining': remaining,
        },
      );

      // Edge Function balikin JSON
      final data = res.data;
      final map = (data is Map<String, dynamic>)
          ? data
          : json.decode(data as String);

      final parsed = CapsuleResult.fromJson(map);

      // 🔴 Perubahan penting:
      // - Jika server mengembalikan items (narasi berhasil), pakai items tsb
      //   meskipun success=false (gambar gagal). Dengan begitu UI tetap
      //   menampilkan narasi hasil AI, dan limit tidak berkurang
      //   karena success=false.
      // - Jika items kosong → fallback lokal.
      final bool hasText = parsed.items.isNotEmpty;
      final result = hasText
          ? parsed
          : CapsuleResult(
              items: _fallbackItems(wt, scenario),
              seed: parsed.seed.isNotEmpty ? parsed.seed : 'edge-empty',
              success: false,
              errorMessage:
                  parsed.errorMessage ?? 'edge returned empty/failed',
            );

      await _safeLogSimulation(wt, scenario, result);
      return result;
    } catch (e) {
      // Jika call function melempar exception → fallback lokal
      final items = _fallbackItems(wt, scenario);
      final result = CapsuleResult(
        items: items,
        seed: 'local-fallback-${DateTime.now().millisecondsSinceEpoch}',
        success: false,
        errorMessage: '$e',
      );
      await _safeLogSimulation(wt, scenario, result);
      return result;
    }
  }

  // ============ Helpers ============

  Future<void> _safeLogSimulation(
    String wasteType,
    CapsuleScenario scenario,
    CapsuleResult result,
  ) async {
    try {
      await _logSimulation(wasteType, scenario, result);
    } catch (_) {
      // kegagalan logging tidak boleh mengganggu UI
    }
  }

  /// Insert log ke tabel `simulation_logs`.
  /// Kolom yang dicatat:
  /// - user_id, waste_type, scenario ('BAIK'/'BURUK')
  /// - image_urls (imageUrl atau fallbackAsset), texts (title+desc)
  /// - seed, success, error_message
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
      'scenario': scenario.db,
      'image_urls': imageUrls,
      'texts': texts,
      'seed': result.seed,
      'success': result.success,
      if (result.errorMessage != null) 'error_message': result.errorMessage,
    });
  }

  /// Paket fallback 3 judul (pakai aset lokal) — aman dipakai saat gagal.
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
      ];
    }
  }

  /// Ambil "tanggal" lokal Jakarta dari waktu sekarang (tanpa jam).
  String _todayJakarta() {
    final nowUtc = DateTime.now().toUtc();
    final jkt = nowUtc.add(const Duration(hours: 7));
    return '${jkt.year.toString().padLeft(4, '0')}-'
        '${jkt.month.toString().padLeft(2, '0')}-'
        '${jkt.day.toString().padLeft(2, '0')}';
  }
}

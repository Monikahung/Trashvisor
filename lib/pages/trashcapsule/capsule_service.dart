// / ===================================================================
// / CapsuleService — IO ke Supabase Edge Function + Logging + Limit
// / -------------------------------------------------------------------
// / Perubahan penting:
// / 1) AKTIFKAN CACHE: hasil generate disimpan di CapsuleCache,
// /    sehingga bolak-balik Baik/Buruk untuk waste yang sama
// /    TIDAK memicu request & log ulang.
// / 2) DEDUP IN-FLIGHT: jika tombol ditekan berkali-kali sebelum respons
// /    datang, hanya 1 request yang benar-benar berjalan.
// / 3) FALLBACK: hanya item[0] yang punya fallbackAsset untuk dipakai
// /    sebagai HEADER image; 3 kartu narasi di UI tidak pakai gambar.
// / 4) LIMIT: [CHANGED] kini dihitung per GAMBAR sukses (good/bad apa pun) dengan URL tersimpan
// /    pada hari JKT (bukan lagi distinct waste_type).
// / ===================================================================
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'capsule_models.dart';
import 'capsule_cache.dart';

/// Batas harian (total gambar sukses pada hari JKT).
const int kDailyLimit = 4; // ⬅️ CHANGED: limit harian jadi 4 (total gambar)

/// Default image size (dipakai kalau nanti kamu aktifkan image generator).
const String kDefaultImageSize = '1024x1024';

class CapsuleService {
  final _client = Supabase.instance.client;

  /// Dedup: menyimpan request yang sedang berjalan per key `<waste>|<scenario>`
  /// agar jika user menekan tombol berkali-kali, hanya 1 panggilan yang jalan.
  final Map<String, Future<CapsuleResult>> _inflight =
      <String, Future<CapsuleResult>>{};

  // -------------------------
  // === PUBLIC: GENERATE  ===
  // -------------------------
  Future<CapsuleResult> generate({
    required String wasteType,
    required CapsuleScenario scenario,
  }) async {
    final wt = wasteType.trim();
    if (wt.isEmpty) {
      // Guard kosong → langsung fallback lokal (tidak log ke DB).
      return CapsuleResult(
        items: _fallbackItems(wt, scenario),
        seed: 'local-empty',
        success: false,
        errorMessage: 'waste_type kosong',
      );
    }

    final key = _key(wt, scenario);

    // 1) Cek cache memori: jika ada → langsung pakai (NO log, NO request).
    final cached = CapsuleCache.instance.get(wt, scenario.db);
    if (cached != null) return cached;

    // 2) Cek in-flight: kalau sudah ada request yang sama → tunggu hasilnya.
    final inflight = _inflight[key];
    if (inflight != null) return await inflight;

    // 3) Buat request baru + simpan ke map dedup
    final future = _generateInner(wt, scenario);
    _inflight[key] = future;

    try {
      final result = await future;
      // Simpan ke cache agar navigasi bolak-balik tidak memicu request/log ulang
      CapsuleCache.instance.set(wt, scenario.db, result);
      return result;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<CapsuleResult> _generateInner(
    String wt,
    CapsuleScenario scenario,
  ) async {
    try {
      // Hitung sisa limit hanya untuk informasi di toast (tidak memblokir).
      final remaining = await remainingLimit();

      final res = await _client.functions.invoke(
        'capsule-generate',
        body: {
          'waste_type': wt,
          'scenario': scenario.wire, // 'good' | 'bad'
          if (remaining != null) 'client_remaining': remaining,
          // 'image_size': kDefaultImageSize, // aktifkan kalau generator gambar dipakai
        },
      );

      // Edge Function mengembalikan JSON: parse aman.
      final data = res.data;
      final map = (data is Map<String, dynamic>) ? data : json.decode(data as String);
      final parsed = CapsuleResult.fromJson(map);

      // Jika text berhasil (items non-empty) → pakai hasil server walau success=false.
      // Jika items kosong → pakai fallback lokal.
      final hasText = parsed.items.isNotEmpty;
      final result = hasText
          ? parsed
          : CapsuleResult(
              items: _fallbackItems(wt, scenario),
              seed: parsed.seed.isNotEmpty ? parsed.seed : 'edge-empty',
              success: false,
              errorMessage: parsed.errorMessage ?? 'edge returned empty/failed',
            );

      await _safeLogSimulation(wt, scenario, result); // log SEKALI di sini
      return result;
    } catch (e) {
      // Exception jaringan/edge → fallback lokal + log.
      final result = CapsuleResult(
        items: _fallbackItems(wt, scenario),
        seed: 'exception',
        success: false,
        errorMessage: '$e',
      );
      await _safeLogSimulation(wt, scenario, result);
      return result;
    }
  }

  String _key(String wt, CapsuleScenario s) => '${wt.toLowerCase()}|${s.db}';

  // -------------------------
  // === LIMIT (INFO TOAST) ===
  // -------------------------

  // (Fungsi lama dibiarkan ada untuk kompatibilitas, tapi tidak dipakai lagi)
  Future<int> countDistinctSuccessToday() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final rows = await _client
          .from('simulation_logs')
          .select('waste_type')
          .eq('user_id', user.id)
          .eq('success', true) // ⚠️ success=true artinya: text && image OK
          .eq('created_on_jkt', _todayJakarta())
          .limit(1000);

      final set = <String>{};
      for (final r in rows as List) {
        final wt = (r['waste_type'] as String?)?.trim();
        if (wt != null && wt.isNotEmpty) set.add(wt.toLowerCase());
      }
      return set.length;
    } catch (_) {
      // Fallback approx (UTC)
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

  // ⬅️ NEW: Hitung TOTAL gambar sukses hari ini (bukan distinct waste)
  // Kriteria "gambar sukses": ada URL http(s) pada kolom image_urls.
  Future<int> countImageSuccessToday() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    // Coba pakai kolom created_on_jkt (tanggal lokal Jakarta) bila tersedia
    try {
      final rows = await _client
          .from('simulation_logs')
          .select('image_urls')
          .eq('user_id', user.id)
          .eq('created_on_jkt', _todayJakarta())
          .limit(2000);

      int used = 0;
      for (final r in rows as List) {
        final urls = (r['image_urls'] as List?) ?? const [];
        final hasImage = urls.any((u) => u is String && (u).startsWith('http'));
        if (hasImage) used++;
      }
      return used;
    } catch (_) {
      // Fallback approx dengan jendela UTC untuk tanggal JKT
      final nowUtc = DateTime.now().toUtc();
      final jktToday = nowUtc.add(const Duration(hours: 7));
      final startUtc = DateTime.utc(jktToday.year, jktToday.month, jktToday.day).toIso8601String();
      final endUtc = DateTime.utc(jktToday.year, jktToday.month, jktToday.day, 23, 59, 59, 999).toIso8601String();

      final rows = await _client
          .from('simulation_logs')
          .select('image_urls, created_at')
          .gte('created_at', startUtc)
          .lte('created_at', endUtc)
          .eq('user_id', user.id)
          .limit(2000);

      int used = 0;
      for (final r in rows as List) {
        final urls = (r['image_urls'] as List?) ?? const [];
        final hasImage = urls.any((u) => u is String && (u).startsWith('http'));
        if (hasImage) used++;
      }
      return used;
    }
  }

  Future<int?> remainingLimit() async {
    final used = await countImageSuccessToday(); // ⬅️ CHANGED: pakai hitung per-GAMBAR
    final remain = kDailyLimit - used;
    return remain < 0 ? 0 : remain;
  }

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

  Future<void> _logSimulation(
    String wasteType,
    CapsuleScenario scenario,
    CapsuleResult result,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final imageUrls =
        result.items.map((e) => e.imageUrl ?? e.fallbackAsset ?? '').toList();
    final texts =
        result.items.map((e) => '${e.title}: ${e.description}').toList();

    await _client.from('simulation_logs').insert({
      'user_id': user.id,
      'waste_type': wasteType,
      'scenario': scenario.db, // 'BAIK' | 'BURUK'
      'image_urls': imageUrls,
      'texts': texts,
      'seed': result.seed,
      'success': result.success, // true kalau text && image sukses
      if (result.errorMessage != null) 'error_message': result.errorMessage,
    });
  }

  // -------------------------
  // === FALLBACK NARASI   ===
  // -------------------------
  List<CapsuleItem> _fallbackItems(String wasteType, CapsuleScenario scenario) {
    final w = wasteType.isEmpty ? 'sampah' : wasteType.toLowerCase();
    final good = scenario == CapsuleScenario.good;

    // Hanya header (item[0]) yang punya fallbackAsset → dipakai SquareHeaderImage
    final header =
        good ? 'assets/images/true_capsule.png' : 'assets/images/false_capsule.png';

    if (good) {
      return [
        CapsuleItem(
          title: 'Lingkungan Sehat',
          description:
              'Pengelolaan $w yang benar menjaga sungai, laut, dan tanah tetap bersih.',
          fallbackAsset: header,
        ),
        CapsuleItem(
          title: 'Udara Bersih',
          description: 'Polusi berkurang karena $w tidak dibakar sembarangan.',
        ),
        CapsuleItem(
          title: 'Sumber Terjaga',
          description: 'Pemilahan & daur ulang $w membantu melestarikan sumber daya alam.',
        ),
      ];
    } else {
      return [
        CapsuleItem(
          title: 'Lingkungan Rusak',
          description: '$w yang tercecer mencemari sungai, laut, dan tanah.',
          // header untuk skenario buruk
          fallbackAsset: header,
        ),
        CapsuleItem(
          title: 'Udara Tercemar',
          description: 'Pembakaran $w menghasilkan asap berbahaya.',
        ),
        CapsuleItem(
          title: 'Sumber Habis',
          description: 'Produksi $w baru tanpa daur ulang menguras sumber daya alam.',
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

import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'capsule_models.dart';

/// Ubah ke `null` jika ingin mematikan limit di sisi klien.
/// Jika tidak null, dipakai untuk menampilkan "sisa limit" di toast.
/// ------------------------------------------------------------------
/// NOTE:
/// - Yang dihitung: JENIS SAMPAH unik yang BERHASIL (success=true)
///   pada hari ini (zona waktu Jakarta).
/// - Error pada generate TIDAK mengurangi kuota harian.
/// ------------------------------------------------------------------
const int kDailyLimit = 2;

/// (BARU) Default image size yang valid untuk OpenAI Images saat ini.
/// Sisi server-mu sudah memvalidasi hanya menerima
/// '1024x1024' | '1024x1536' | '1536x1024' | 'auto'.
/// Di sini kita set aman ke '1024x1024' agar tidak 400 invalid_value.
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
      // Prefer kolom created_on_jkt (stored)
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

  /// Sisa limit hari ini (hanya hitung yang benar-benar sukses).
  /// ----------------------------------------------------------------------
  /// Return null jika `kDailyLimit` = null (berarti fitur limit dimatikan).
  Future<int?> remainingLimit() async {
    final used = await countDistinctSuccessToday();
    return (kDailyLimit - used).clamp(0, kDailyLimit);
  }

  /// Panggil Edge Function. Jika gagal / success=false → fallback asset lokal.
  /// ----------------------------------------------------------------------
  /// Alur:
  /// 1) Validasi input kosong → langsung fallback lokal (guard).
  /// 2) Invoke edge function 'capsule-generate' (kirim image_size VALID).
  /// 3) Parse hasil → jika success=false ATAU items kosong → paksa fallback lokal.
  /// 4) Catat log ke tabel `simulation_logs` (best-effort, tidak memblokir UI).
  Future<CapsuleResult> generate({
    required String wasteType,
    required CapsuleScenario scenario,
  }) async {
    final wt = wasteType.trim();
    if (wt.isEmpty) {
      // Tidak mungkin terjadi karena UI sudah validasi, tapi guard lagi saja.
      return CapsuleResult(
        items: _fallbackItems(wt, scenario),
        seed: 'local-empty',
        success: false,
        errorMessage: 'waste_type kosong',
      );
    }

    try {
      // Opsional: kirim info sisa kuota ke server (tidak wajib).
      int? remaining;
      remaining = await remainingLimit();
    
      final res = await _client.functions.invoke(
        'capsule-generate',
        body: {
          'waste_type': wt,
          'scenario': scenario.wire, // 'good' | 'bad'
          // PENTING: ukuran valid untuk OpenAI saat ini.
          // Hindari angka bulat seperti 768 yang memicu error 400 "invalid_value".
          'image_size': kDefaultImageSize,
          if (remaining != null) 'client_remaining': remaining,
        },
      );

      // Edge Function balikin JSON (bisa success=true/false)
      final data = res.data;
      final map = (data is Map<String, dynamic>)
          ? data
          : json.decode(data as String);

      final parsed = CapsuleResult.fromJson(map);

      // 🔴 FIX PENTING (tetap dipertahankan & diperjelas):
      // Jika edge function gagal (success=false) atau items kosong,
      // JANGAN biarkan UI kosong. Paksa fallback ke aset lokal,
      // namun tetap tandai success=false dan simpan errorMessage dari server.
      final result = (parsed.success && parsed.items.isNotEmpty)
          ? parsed
          : CapsuleResult(
              items: _fallbackItems(wt, scenario),
              seed: parsed.seed.isNotEmpty ? parsed.seed : 'edge-empty',
              success: false,
              errorMessage:
                  parsed.errorMessage ?? 'edge returned empty/failed',
            );

      // Logging ke DB (best-effort; jika gagal tidak mengganggu UI)
      await _safeLogSimulation(wt, scenario, result);
      return result;
    } catch (e) {
      // Jika call function melempar exception (network, parse, dsb) → fallback lokal
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

  /// Wrapper logging yang aman: jika insert gagal, error diabaikan.
  Future<void> _safeLogSimulation(
    String wasteType,
    CapsuleScenario scenario,
    CapsuleResult result,
  ) async {
    try {
      await _logSimulation(wasteType, scenario, result);
    } catch (_) {
      // Diamkan saja; kegagalan logging tidak boleh mengganggu UI.
    }
  }

  /// Insert log ke tabel `simulation_logs`.
  /// ----------------------------------------------------------------------
  /// Kolom yang dicatat:
  /// - user_id (current user)
  /// - waste_type
  /// - scenario ('BAIK' / 'BURUK') → sesuai CHECK constraint DB
  /// - image_urls (gabungan imageUrl atau fallbackAsset)
  /// - texts (gabungan "title: description")
  /// - seed (dari server atau 'local-fallback-...')
  /// - success (true/false sesuai hasil akhir yang dipakai UI)
  /// - error_message (opsional)
  Future<void> _logSimulation(
      String wasteType, CapsuleScenario scenario, CapsuleResult result) async {
    final user = _client.auth.currentUser;
    if (user == null) return; // jika belum login, abaikan pencatatan

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

  /// Paket fallback 5 kartu (pakai aset lokal) — aman dipakai saat gagal.
  /// ----------------------------------------------------------------------
  /// Teks disesuaikan dengan jenis sampah agar tetap terasa kontekstual.
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

  /// Ambil "tanggal" lokal Jakarta dari waktu sekarang (tanpa jam).
  /// ----------------------------------------------------------------------
  /// Dipakai untuk query kolom `created_on_jkt` di DB.
  String _todayJakarta() {
    final nowUtc = DateTime.now().toUtc();
    // offset Asia/Jakarta = +7 (Indonesia tidak pakai DST)
    final jkt = nowUtc.add(const Duration(hours: 7));
    return '${jkt.year.toString().padLeft(4, '0')}-'
        '${jkt.month.toString().padLeft(2, '0')}-'
        '${jkt.day.toString().padLeft(2, '0')}';
  }
}

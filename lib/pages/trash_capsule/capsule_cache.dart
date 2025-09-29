// / ===================================================================
// / CapsuleCache — cache ringan di memori aplikasi
// / -------------------------------------------------------------------
// / - Kunci: "<wasteLower>|<scenarioDb>" (contoh: "sampah plastik|BAIK").
// / - Tujuan: mencegah panggilan ulang Edge Function saat user bolak-balik
// /   Baik <-> Buruk selama teks pencarian belum berubah.
// / - Clear cache saat user mengubah isi search (lihat onChanged di UI).
// / ===================================================================
import 'capsule_models.dart';

class CapsuleCache {
  CapsuleCache._();
  static final CapsuleCache instance = CapsuleCache._();

  final Map<String, CapsuleResult> _mem = <String, CapsuleResult>{};

  String _key(String waste, String scenarioDb) =>
      '${waste.trim().toLowerCase()}|$scenarioDb';

  CapsuleResult? get(String waste, String scenarioDb) {
    return _mem[_key(waste, scenarioDb)];
  }

  void set(String waste, String scenarioDb, CapsuleResult result) {
    _mem[_key(waste, scenarioDb)] = result;
  }

  // Bersihkan semua (dipanggil ketika user mengubah teks search).
  void clear() => _mem.clear();

  // Opsional: bersihkan cache untuk satu waste (jika perlu di masa depan).
  void invalidateWaste(String waste) {
    final k = waste.trim().toLowerCase();
    _mem.removeWhere((key, _) => key.startsWith('$k|'));
  }
}
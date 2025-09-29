// Model ringan + enum untuk Trash Capsule
// Aman dipakai di 3 layar dan di service.

enum CapsuleScenario { good, bad }

extension CapsuleScenarioX on CapsuleScenario {
  // Label yang disimpan di DB (match CHECK constraint 'BAIK' | 'BURUK')
  String get db => this == CapsuleScenario.good ? 'BAIK' : 'BURUK';
  // Label yang dikirim ke Edge Function (lebih ringkas)
  String get wire => this == CapsuleScenario.good ? 'good' : 'bad';
}

/// Satu kartu/cerita dampak
class CapsuleItem {
  final String title;
  final String description;
  final String? imageUrl;      // hasil generator (jika sukses)
  final String? fallbackAsset; // asset lokal (fallback)

  CapsuleItem({
    required this.title,
    required this.description,
    this.imageUrl,
    this.fallbackAsset,
  });

  factory CapsuleItem.fromJson(Map<String, dynamic> j) => CapsuleItem(
        title: j['title'] as String,
        description: j['description'] as String,
        imageUrl: j['imageUrl'] as String?,
        fallbackAsset: j['fallbackAsset'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (fallbackAsset != null) 'fallbackAsset': fallbackAsset,
      };
}

/// Paket hasil generator
class CapsuleResult {
  final List<CapsuleItem> items;
  final String seed;

  /// success = "hasil akhir dipakai untuk hitung limit"
  /// Dengan logika baru: success=true hanya jika textSuccess && imageSuccess.
  final bool success;

  /// Rinciannya:
  final bool? textSuccess;  // true bila narasi dari server berhasil
  final bool? imageSuccess; // true bila gambar benar-benar dibuat

  /// Pesan error dari function (kalau ada).
  final String? errorMessage;

  CapsuleResult({
    required this.items,
    required this.seed,
    required this.success,
    this.textSuccess,
    this.imageSuccess,
    this.errorMessage,
  });

  factory CapsuleResult.fromJson(Map<String, dynamic> j) => CapsuleResult(
        items: (j['items'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(CapsuleItem.fromJson)
            .toList(),
        seed: (j['seed'] as String?) ?? 'local-fallback',
        success: (j['success'] as bool?) ?? false,
        textSuccess: j['textSuccess'] as bool?,
        imageSuccess: j['imageSuccess'] as bool?,
        errorMessage: j['errorMessage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'seed': seed,
        'success': success,
        if (textSuccess != null) 'textSuccess': textSuccess,
        if (imageSuccess != null) 'imageSuccess': imageSuccess,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}
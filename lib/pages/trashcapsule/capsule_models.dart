// Model ringan + enum untuk Trash Capsule
// Aman di-share di 3 layar dan service.

enum CapsuleScenario { good, bad }

extension CapsuleScenarioX on CapsuleScenario {
  // Label yang disimpan di DB (match CHECK constraint 'BAIK' | 'BURUK')
  String get db => this == CapsuleScenario.good ? 'BAIK' : 'BURUK';
  // Label yang dikirim ke Edge Function (lebih ringkas)
  String get wire => this == CapsuleScenario.good ? 'good' : 'bad';
}

/// Satu kartu dampak
class CapsuleItem {
  final String title;
  final String description;
  final String? imageUrl;      // hasil dari generator (kalau sukses)
  final String? fallbackAsset; // fallback asset lokal

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

/// Paket hasil generator (5 item + seed)
class CapsuleResult {
  final List<CapsuleItem> items;
  final String seed;

  CapsuleResult({required this.items, required this.seed});

  factory CapsuleResult.fromJson(Map<String, dynamic> j) => CapsuleResult(
        items: (j['items'] as List)
            .cast<Map<String, dynamic>>()
            .map(CapsuleItem.fromJson)
            .toList(),
        seed: (j['seed'] as String?) ?? 'local-fallback',
      );

  Map<String, dynamic> toJson() =>
      {'items': items.map((e) => e.toJson()).toList(), 'seed': seed};
}

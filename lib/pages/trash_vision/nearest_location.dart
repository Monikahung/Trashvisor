import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:trashvisor/core/colors.dart';
import 'location_component.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Model data untuk lokasi tempat sampah
class TrashLocationData {
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String placeId;
  final String photoReference;
  String? distance;
  String? duration;
  String? staticMapUrl;

  TrashLocationData({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.placeId,
    this.photoReference = '',
    this.distance,
    this.duration,
    this.staticMapUrl,
  });

  // Metode untuk membandingkan objek berdasarkan placeId
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrashLocationData && other.placeId == placeId;
  }

  // Metode untuk mendapatkan kode hash berdasarkan placeId
  @override
  int get hashCode => placeId.hashCode;
}

class NearestLocationPage extends StatefulWidget {
  const NearestLocationPage({super.key});

  @override
  NearestLocationPageState createState() => NearestLocationPageState();
}

class NearestLocationPageState extends State<NearestLocationPage> {
  final String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] ?? '';
  final Map<String, String> placeQueries = {
    'TPA': 'tempat pembuangan akhir',
    'TPS': 'tempat pembuangan sampah',
    'Bank Sampah': 'bank sampah',
    'Daur Ulang': 'recycling center',
  };

  List<TrashLocationData> nearbyTrashLocations = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllNearbyPlaces();
  }

  Future<void> _loadAllNearbyPlaces() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      Position position = await _getCurrentLocation();
      List<TrashLocationData> locations = await _fetchPlaces(position);
      List<TrashLocationData> locationsWithDistances =
          await _getDistancesForPlaces(position, locations);

      if (mounted) {
        setState(() {
          nearbyTrashLocations = locationsWithDistances;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat semua lokasi: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage =
              "Gagal memuat lokasi. Pastikan GPS aktif dan terhubung ke internet.";
        });
      }
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Layanan lokasi tidak diaktifkan.");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Izin lokasi ditolak.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Izin lokasi ditolak permanen.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<List<TrashLocationData>> _fetchPlaces(Position position) async {
    // Gunakan Set untuk menyimpan lokasi unik
    Set<TrashLocationData> locationsSet = {};

    for (var entry in placeQueries.entries) {
      final customName = entry.key;
      final keyword = entry.value;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${position.latitude},${position.longitude}'
        '&radius=50000'
        '&keyword=${Uri.encodeComponent(keyword)}'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          for (var result in data['results']) {
            final lat = (result['geometry']['location']['lat'] as num?)?.toDouble() ?? 0.0;
            final lng = (result['geometry']['location']['lng'] as num?)?.toDouble() ?? 0.0;
            final placeId = result['place_id'] ?? '';

            // Tambahkan objek baru ke dalam Set. Jika placeId sudah ada, tidak akan ditambahkan lagi.
            locationsSet.add(
              TrashLocationData(
                name: result['name'] ?? 'Tempat Sampah',
                type: customName,
                latitude: lat,
                longitude: lng,
                rating: (result['rating'] ?? 0.0).toDouble(),
                reviewCount: result['user_ratings_total'] ?? 0,
                placeId: placeId,
                photoReference: (result['photos'] != null && result['photos'].isNotEmpty)
                    ? result['photos'][0]['photo_reference']
                    : '',
              ),
            );
          }
        }
      } else {
        debugPrint('Error fetching $customName: ${response.statusCode}');
      }
    }
    // Konversi Set kembali ke List sebelum dikembalikan
    return locationsSet.toList();
  }

  Future<List<TrashLocationData>> _getDistancesForPlaces(
      Position userPosition, List<TrashLocationData> locations) async {
    if (locations.isEmpty) {
      return [];
    }

    final userLocation = LatLng(userPosition.latitude, userPosition.longitude);
    List<TrashLocationData> results = [];

    const int batchSize = 25;
    for (int i = 0; i < locations.length; i += batchSize) {
      final batch = locations.sublist(
        i,
        (i + batchSize > locations.length) ? locations.length : i + batchSize,
      );

      final destinations =
          batch.map((loc) => "${loc.latitude},${loc.longitude}").join("|");

      final url =
          "https://maps.googleapis.com/maps/api/distancematrix/json?origins=${userLocation.latitude},${userLocation.longitude}&destinations=$destinations&mode=driving&key=$apiKey";

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["status"] == "OK") {
            final elements = data["rows"][0]["elements"];
            for (int j = 0; j < batch.length; j++) {
              final loc = batch[j];
              final element = elements[j];

              if (element["status"] == "OK") {
                String markerColor = 'blue';
                switch (loc.type) {
                  case "TPA":
                    markerColor = 'red';
                    break;
                  case "TPS":
                    markerColor = 'violet';
                    break;
                  case "Bank Sampah":
                    markerColor = 'green';
                    break;
                  case "Daur Ulang":
                    markerColor = 'yellow';
                    break;
                }
                
                final staticMapUrl = 'https://maps.googleapis.com/maps/api/staticmap'
                    '?center=${loc.latitude},${loc.longitude}'
                    '&zoom=14'
                    '&size=400x200'
                    '&markers=color:$markerColor%7C${loc.latitude},${loc.longitude}'
                    '&key=$apiKey';

                loc.distance = element["distance"]["text"];
                loc.duration = element["duration"]["text"];
                loc.staticMapUrl = staticMapUrl;
                results.add(loc);
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error processing batch $i: $e");
      }
    }

    double parseDistance(String dist) {
      try {
        final parts = dist.split(" ");
        final value = double.tryParse(parts[0].replaceAll(",", ".")) ?? 9999999;
        final unit = parts.length > 1 ? parts[1] : "";
        return unit.startsWith("m") ? value / 1000.0 : value;
      } catch (e) {
        return 9999999;
      }
    }

    results.sort((a, b) {
      return parseDistance(a.distance ?? "9999999 km")
          .compareTo(parseDistance(b.distance ?? "9999999 km"));
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const TrashLocationHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Semua Lokasi Terdekat',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: AppColors.darkMossGreen.withAlpha((255 * 0.5).round()),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.fernGreen),
                    )
                  else if (errorMessage != null)
                    Center(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (nearbyTrashLocations.isEmpty)
                    const Center(
                      child: Text("Tidak ada lokasi yang ditemukan dalam radius 50 km."),
                    )
                  else
                    Column(
                      children: nearbyTrashLocations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final location = entry.value;

                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: index == nearbyTrashLocations.length - 1 ? 0 : 16),
                          child: TrashLocationCard(
                            distance: location.distance!,
                            time: location.duration!,
                            locationName: location.name,
                            rating: location.rating,
                            reviewCount: location.reviewCount,
                            imagePath: location.staticMapUrl ?? 'assets/images/features/default_location.png',
                            type: location.type,
                            destination: LatLng(location.latitude, location.longitude),
                            onTap: () {},
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:trashvisor/core/colors.dart';
import 'package:trashvisor/pages/trashvision/location_component.dart';
import 'nearest_location.dart';

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

  TrashLocationData({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.placeId,
    this.photoReference = '',
  });

  // Tambahkan kode ini untuk memastikan keunikan berdasarkan placeId
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrashLocationData && other.placeId == placeId;
  }

  @override
  int get hashCode => placeId.hashCode;
}

class TrashLocation extends StatefulWidget {
  const TrashLocation({super.key});

  @override
  TrashLocationState createState() => TrashLocationState();
}

class TrashLocationState extends State<TrashLocation> {
  final String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] ?? '';
  final Map<String, String> placeQueries = {
    'TPA': 'tempat pembuangan akhir',
    'TPS': 'tempat pembuangan sampah',
    'Bank Sampah': 'bank sampah',
    'Daur Ulang': 'recycling center',
  };

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  Position? currentPosition;
  List<TrashLocationData> nearbyTrashLocations = [];
  List<Map<String, dynamic>> top3NearestLocations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Mendapatkan lokasi pengguna saat ini
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi tidak diaktifkan.')),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        }
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi ditolak permanen, tidak bisa meminta izin lagi.',
            ),
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          currentPosition = position;
        });
        await _loadNearbyPlaces(position);
      }
    } catch (e) {
      debugPrint("Gagal mendapatkan lokasi: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal mendapatkan lokasi. Pastikan GPS aktif dan izinkan lokasi.",
            ),
          ),
        );
      }
    }
  }

  // Ambil lokasi sekitar sesuai placeQueries
  Future<void> _loadNearbyPlaces(Position position) async {
    // Gunakan Set untuk mencegah duplikasi
    Set<TrashLocationData> uniqueLocations = {};

    for (var entry in placeQueries.entries) {
      final customName = entry.key;
      final keyword = entry.value;

      try {
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

              // Tambahkan ke Set. Jika placeId sudah ada, tidak akan ditambahkan lagi.
              uniqueLocations.add(
                TrashLocationData(
                  name: result['name'] ?? 'Tempat Sampah',
                  type: customName,
                  latitude: lat,
                  longitude: lng,
                  rating: (result['rating'] ?? 0.0).toDouble(),
                  reviewCount: result['user_ratings_total'] ?? 0,
                  placeId: result['place_id'] ?? '',
                  photoReference:
                      (result['photos'] != null && result['photos'].isNotEmpty)
                          ? result['photos'][0]['photo_reference']
                          : '',
                ),
              );
            }
          }
        } else {
          debugPrint(
            'Error saat ambil data $customName: ${response.statusCode}',
          );
        }
      } catch (e) {
        debugPrint('Kesalahan saat memuat data: $e');
        continue;
      }
    }

    if (mounted) {
      setState(() {
        // Konversi Set ke List untuk digunakan di UI dan Distance Matrix API
        nearbyTrashLocations = uniqueLocations.toList();
        _addMarkers();
      });
    }

    final nearest = await _getTop3Nearest();
    if (mounted) {
      setState(() {
        top3NearestLocations = nearest;
        isLoading = false;
      });
    }
  }

  // Tambahkan marker
  void _addMarkers() {
    markers.clear();
    circles.clear();

    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("current_location"),
          position: LatLng(
            currentPosition!.latitude,
            currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: "Lokasi Anda"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      circles.add(
        Circle(
          circleId: const CircleId("radius"),
          center: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          radius: 50000,
          fillColor: AppColors.mossGreen.withAlpha((255 * 0.1).round()),
          strokeColor: AppColors.fernGreen.withAlpha((255 * 0.5).round()),
          strokeWidth: 1,
        ),
      );
    }

    for (var location in nearbyTrashLocations) {
      double hue;
      switch (location.type) {
        case "TPA":
          hue = BitmapDescriptor.hueRed;
          break;
        case "TPS":
          hue = BitmapDescriptor.hueViolet;
          break;
        case "Bank Sampah":
          hue = BitmapDescriptor.hueGreen;
          break;
        case "Daur Ulang":
          hue = BitmapDescriptor.hueYellow;
          break;
        default:
          hue = BitmapDescriptor.hueAzure;
      }

      markers.add(
        Marker(
          markerId: MarkerId(location.placeId),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(title: location.name, snippet: location.type),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
    }
  }

  // Ambil 3 lokasi terdekat via Distance Matrix
  Future<List<Map<String, dynamic>>> _getTop3Nearest() async {
    if (currentPosition == null || nearbyTrashLocations.isEmpty) {
      return [];
    }

    final userLocation = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );
    List<Map<String, dynamic>> allResults = [];

    const int batchSize = 25;
    for (int i = 0; i < nearbyTrashLocations.length; i += batchSize) {
      final batch = nearbyTrashLocations.sublist(
        i,
        (i + batchSize > nearbyTrashLocations.length)
            ? nearbyTrashLocations.length
            : i + batchSize,
      );

      final destinations = batch
          .map((loc) => "${loc.latitude},${loc.longitude}")
          .join("|");

      final url =
          "https://maps.googleapis.com/maps/api/distancematrix/json?origins=${userLocation.latitude},${userLocation.longitude}&destinations=$destinations&mode=driving&key=$apiKey";

      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode != 200) {
          debugPrint(
            "DistanceMatrix gagal untuk batch $i: ${response.statusCode}",
          );
          continue;
        }

        final data = jsonDecode(response.body);
        if (data["status"] != "OK") {
          debugPrint("DistanceMatrix error untuk batch $i: ${data["status"]}");
          continue;
        }

        final elements = data["rows"][0]["elements"];
        for (int j = 0; j < batch.length; j++) {
          final loc = batch[j];
          final element = elements[j];

          if (element["status"] == "OK" && element["distance"] != null && element["duration"] != null) {
            final ratingValue = loc.rating;
            final reviewCountValue = loc.reviewCount;

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

            final staticMapUrl =
                'https://maps.googleapis.com/maps/api/staticmap'
                '?center=${loc.latitude},${loc.longitude}'
                '&zoom=14'
                '&size=400x200'
                '&markers=color:$markerColor%7C${loc.latitude},${loc.longitude}'
                '&key=$apiKey';

            allResults.add({
              "name": loc.name,
              "rating": ratingValue.toDouble(),
              "reviewCount": reviewCountValue,
              "distance": element["distance"]["text"],
              "duration": element["duration"]["text"],
              "imagePath": staticMapUrl,
              "type": loc.type,
              "latitude": loc.latitude,
              "longitude": loc.longitude,
            });
          }
        }
      } catch (e) {
        debugPrint("Kesalahan saat memproses batch $i: $e");
      }
    }

    double parseDistance(String dist) {
      try {
        final parts = dist.split(" ");
        final value = double.tryParse(parts[0].replaceAll(",", ".")) ?? 9999999;
        final unit = parts.length > 1 ? parts[1] : "";
        return unit.startsWith("m") ? value / 1000.0 : value;
      } catch (e) {
        debugPrint("Error parsing distance: $dist");
        return 9999999;
      }
    }

    allResults.sort((a, b) {
      return parseDistance(
        a["distance"],
      ).compareTo(parseDistance(b["distance"]));
    });

    return allResults.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

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
                    'Trash Location',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkMossGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Temukan lokasi pembuangan sampah terdekat agar pengelolaan sampah lebih mudah dan tepat.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: AppColors.darkMossGreen.withAlpha(
                      (255 * 0.5).round(),
                    ),
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: screenSize.height * 0.3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fernGreen, width: 1),
                    ),
                    child: isLoading || currentPosition == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.fernGreen,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // ini yang bikin melengkung
                            child: GoogleMap(
                              onMapCreated: (controller) {
                                mapController = controller;
                              },
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  currentPosition!.latitude,
                                  currentPosition!.longitude,
                                ),
                                zoom: 12.0,
                              ),
                              markers: markers,
                              circles: circles,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lokasi Terdekat',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkMossGreen,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NearestLocationPage(),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: AppColors.darkMossGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.fernGreen,
                      ),
                    )
                  else if (top3NearestLocations.isEmpty)
                    const Center(
                      child: Text("Tidak ada lokasi terdekat ditemukan."),
                    )
                  else
                    Column(
                      children: top3NearestLocations.map((location) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TrashLocationCard(
                            locationName: location["name"],
                            rating: location["rating"],
                            reviewCount: location["reviewCount"],
                            imagePath: location["imagePath"],
                            distance: location["distance"],
                            time: location["duration"],
                            type: location["type"],
                            destination: LatLng(
                              (location["latitude"] as num?)?.toDouble() ?? 0.0,
                              (location["longitude"] as num?)?.toDouble() ??
                                  0.0,
                            ),
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

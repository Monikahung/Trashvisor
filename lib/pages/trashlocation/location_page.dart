import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trashvisor/core/colors.dart';

// Kelas untuk memanggil Google Places API
class MapsApi {
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static Future<Map<String, dynamic>> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    String? rankPreference,
  }) async {
    final baseUrl =
        'https://maps.googleapis.com/maps/api/place/textsearch/json';
    final params = {
      'query': query,
      'key': _apiKey,
      'language': 'id',
      'location': '$latitude,$longitude',
      'rankby': 'distance',
    };

    if (rankPreference != null) {
      params['rankby'] = rankPreference;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data dari Maps API: ${response.body}');
    }
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final TextEditingController _searchController = TextEditingController();

  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  double? _distanceInKm;
  String? _durationText;
  String? _destinationName;
  List<Map<String, dynamic>> _searchSuggestions = [];
  final List<Map<String, dynamic>> _nearbyPlaces = [];

  late final String _apiKey;

  String _getPhotoUrl(String? photoReference) {
    if (photoReference == null || photoReference.isEmpty) {
      return 'assets/images/default_location.png'; // fallback ke asset lokal
    }
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=600'
        '&photoreference=$photoReference'
        '&key=$_apiKey';
  }

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    _determinePosition().then((_) {
      if (_currentPosition != null) {
        _loadNearbyPlaces();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permission denied forever');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: _currentPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(title: 'Lokasi Saya'),
          ),
        );

        // Tambahkan Circle untuk visualisasi jarak
        _circles.add(
          Circle(
            circleId: const CircleId('range_circle'),
            center: _currentPosition!,
            radius:
                50000, // Radius dalam meter, sama dengan yang digunakan di API
            strokeWidth: 1,
            strokeColor: AppColors.fernGreen.withAlpha((255 * 0.5).round()),
            fillColor: AppColors.mossGreen.withAlpha((255 * 0.1).round()),
          ),
        );
      });
    }
  }

  // Menampilkan lokasi tempat pembuangan sampah dan daur ulang maksimal radius 50 km
  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null || _apiKey.isEmpty) {
      return;
    }

    // Bersihkan daftar _nearbyPlaces sebelum memuat data baru
    _nearbyPlaces.clear();

    final Map<String, String> placeQueries = {
      'TPA': 'tempat pembuangan akhir',
      'TPS': 'tempat pembuangan sampah',
      'Bank Sampah': 'bank sampah',
      'Daur Ulang': 'recycling center',
    };

    const radius = 50000;

    for (var entry in placeQueries.entries) {
      final customName = entry.key;
      final keyword = entry.value;

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
            '&radius=$radius'
            '&keyword=${Uri.encodeComponent(keyword)}'
            '&key=$_apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          if (!mounted) return;
          for (var result in data['results']) {
            final lat = result['geometry']['location']['lat'];
            final lng = result['geometry']['location']['lng'];

            final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              lat,
              lng,
            ) / 1000; // Hitung jarak dalam km

            // Simpan detail tempat dan jaraknya
            _nearbyPlaces.add({
              'name': result['name'],
              'type': customName,
              'location': LatLng(lat, lng),
              'place_id': result['place_id'],
              'distance': distance, // Simpan jarak
              'rating': result['rating']?.toDouble() ?? 0.0,
              'reviews': result['user_ratings_total'] ?? 0,
              'photo_reference': result['photos']?.first['photo_reference'],
            });

            // Buat marker seperti biasa
            BitmapDescriptor markerIcon;
            if (customName == 'TPA') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
            } else if (customName == 'TPS') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
            } else if (customName == 'Bank Sampah') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
            } else if (customName == 'Daur Ulang') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
            } else {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
            }

            setState(() {
              _markers.add(
                Marker(
                  markerId: MarkerId(result['place_id']),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: result['name'], snippet: customName),
                  icon: markerIcon,
                  onTap: () {
                    // Temukan data yang sudah disimpan untuk marker ini
                    final placeData = _nearbyPlaces.firstWhere((p) => p['place_id'] == result['place_id']);
                    _showInfoSheet(
                      name: placeData['name'],
                      type: placeData['type'],
                      rating: placeData['rating'],
                      reviews: placeData['reviews'],
                      imageUrl: _getPhotoUrl(placeData['photo_reference']),
                      destination: placeData['location'],
                    );
                  },
                ),
              );
            });
          }
        }
      } else {
        debugPrint('Error saat ambil data $customName: ${response.statusCode}');
      }
    }
    
    // Urutkan daftar tempat setelah semua data terisi
    if (!mounted) return;
    setState(() {
      _nearbyPlaces.sort((a, b) => a['distance'].compareTo(b['distance']));
    });
  }

  // Menampilkan informasi resmi dari setiap lokasi marker
  void _showInfoSheet({
    required String name,
    required String type,
    required double rating,
    required int reviews,
    required String imageUrl,
    required LatLng destination,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled:
          true, // Biarkan true agar sheet bisa muncul di atas keyboard
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          // Gunakan SingleChildScrollView agar konten bisa digulir jika terlalu panjang
          child: SingleChildScrollView(
            // Gunakan MainAxisSize.min agar Column hanya mengambil ruang vertikal sesuai kontennya
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 75,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Color(0xFFBABABA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/default_location.png',
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    color: AppColors.darkMossGreen,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _buildRatingStars(rating),
                    const SizedBox(width: 10),
                    Text(
                      '$rating ($reviews ulasan)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Jenis: $type',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fernGreen,
                    foregroundColor: AppColors.whiteSmoke,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _drawRoute(destination, _currentPosition!, name, (
                      distance,
                      duration,
                      points,
                    ) {
                      setState(() {
                        _polylines = {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: points,
                            color: AppColors.fernGreen,
                            width: 5,
                          ),
                        };
                        _distanceInKm = distance;
                        _durationText = duration;
                        _destinationName = name;
                      });
                    });
                  },
                  child: const Text(
                    'Lihat Rute',
                    style: TextStyle(
                      color: AppColors.whiteSmoke, // Warna teks yang sama
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Menggambar rute dari lokasi terkini pengguna ke lokasi tujuan (marker)
  final PolylinePoints polylinePoints = PolylinePoints();

  Future<void> _drawRoute(
    LatLng destination,
    LatLng origin,
    String destinationName,
    Function(double, String, List<LatLng>) onRouteCalculated,
  ) async {
    try {
      final directionsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_apiKey',
      );

      final response = await http.get(directionsUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final overviewPolyline = route['overview_polyline']['points'];

          final distance = leg['distance']['value'] / 1000.0;
          final duration = leg['duration']['text'];

          final polylinePointsResult = polylinePoints.decodePolyline(
            overviewPolyline,
          );
          final routePoints = polylinePointsResult
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();

          onRouteCalculated(distance, duration, routePoints);
        } else {
          debugPrint('No route found from API. Falling back to direct line.');
          final fallbackDistance =
              Geolocator.distanceBetween(
                origin.latitude,
                origin.longitude,
                destination.latitude,
                destination.longitude,
              ) /
              1000;
          const fallbackDuration = 'N/A';
          final fallbackPoints = [origin, destination];
          onRouteCalculated(fallbackDistance, fallbackDuration, fallbackPoints);
        }
      } else {
        debugPrint(
          'Error getting directions: ${response.statusCode}, ${response.body}',
        );
        final fallbackDistance =
            Geolocator.distanceBetween(
              origin.latitude,
              origin.longitude,
              destination.latitude,
              destination.longitude,
            ) /
            1000;
        const fallbackDuration = 'N/A';
        final fallbackPoints = [origin, destination];
        onRouteCalculated(fallbackDistance, fallbackDuration, fallbackPoints);
      }
    } catch (e) {
      debugPrint('Exception getting route: $e');
      final fallbackDistance =
          Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            destination.latitude,
            destination.longitude,
          ) /
          1000;
      const fallbackDuration = 'N/A';
      final fallbackPoints = [origin, destination];
      onRouteCalculated(fallbackDistance, fallbackDuration, fallbackPoints);
    }
  }

  // Rating setiap lokasi
  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
    }
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
    }
    int remainingStars = 5 - stars.length;
    for (int i = 0; i < remainingStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
    }
    return Row(children: stars);
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    // Kosongkan daftar saran sebelum mengisinya
    _searchSuggestions.clear();

    final filteredPlaces = _nearbyPlaces
        .where((place) =>
            (place['name'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();

    final uniqueSuggestions = filteredPlaces
        .map((place) => {
              'name': '${place['name']} (${(place['distance'] as double).toStringAsFixed(1)} km)',
              'place_id': place['place_id'],
            })
        .toSet()
        .toList();

    setState(() {
      _searchSuggestions = uniqueSuggestions;
    });
  }

  // Ubah parameter dari 'query' menjadi 'placeId'
  void _performSearch(String placeId) {
    if (!mounted) return;
    
    final place = _nearbyPlaces.firstWhere(
      (p) => p['place_id'] == placeId,
      orElse: () => {},
    );

    if (place.isNotEmpty) {
      final destination = place['location'] as LatLng;
      final destinationName = place['name'] as String;

      _mapController?.animateCamera(CameraUpdate.newLatLng(destination));
      
      setState(() {
        _polylines.clear();
      });

      _drawRoute(destination, _currentPosition!, destinationName, (
        distance,
        duration,
        points,
      ) {
        if (!mounted) return;
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: points,
              color: AppColors.fernGreen,
              width: 5,
            ),
          };
          _distanceInKm = distance;
          _durationText = duration;
          _destinationName = destinationName;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Konten SnackBar: ikon dan teks
          content: Row(
            children: const [
              // Ikon peringatan
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 10), // Jarak antara ikon dan teks
              // Teks pesan
              Text(
                'Lokasi tidak ditemukan!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto'
                ),
              ),
            ],
          ),
          
          // Warna latar belakang SnackBar
          backgroundColor: Colors.red.shade700,
          
          // Durasi SnackBar ditampilkan
          duration: const Duration(seconds: 3),
          
          // Perilaku SnackBar: floating agar muncul di tengah bawah dan tidak selebar layar
          behavior: SnackBarBehavior.floating,
          
          // Bentuk SnackBar: sudut membulat
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Sesuaikan radius untuk kelengkungan sudut
          ),
          
          // Margin dari tepi layar (opsional, untuk tampilan yang lebih "mengambang")
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          
          // Padding internal di dalam SnackBar (opsional, bisa diatur lewat content juga)
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = _currentPosition != null
        ? CameraPosition(target: _currentPosition!, zoom: 12)
        : const CameraPosition(
            target: LatLng(-2.1234520467333087, 106.14289369216657),
            zoom: 12,
          );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.mossGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.whiteSmoke),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.fernGreen,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.whiteSmoke, width: 1),
              ),
              child: const Center(
                child: Icon(Icons.location_on, color: AppColors.whiteSmoke),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trash Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Temukan lokasi TPS terdekat',
                  style: TextStyle(
                    color: Colors.white.withAlpha((255 * 0.8).round()),
                    fontFamily: 'Roboto',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.fernGreen),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  markers: _markers,
                  polylines: _polylines,
                  circles: _circles,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                ),
                if (_searchSuggestions.isNotEmpty) // Tampilkan hanya jika ada saran
                  Positioned(
                    top: 75, // Posisi dari atas
                    left: 16,
                    right: 16,
                    child: Container(
                      // Atur batas tinggi maksimum di sini
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7, // Contoh: maks 70% tinggi layar
                      ),
                      margin: EdgeInsets.only(bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((255 * 0.1).round()),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _searchSuggestions[index];
                          final placeName = suggestion['name'] as String;
                          final placeId = suggestion['place_id'] as String;

                          return ListTile(
                            title: Text(placeName),
                            onTap: () {
                              _performSearch(placeId);
                              setState(() {
                                _searchSuggestions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.fernGreen, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.1).round()),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: AppColors.fernGreen,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi',
                        hintStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: AppColors.fernGreen,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(Icons.search, color: AppColors.fernGreen),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      onChanged: _updateSuggestions,
                      onSubmitted: (value) {
                        _performSearch(value);
                        // Sembunyikan saran setelah pencarian
                        _searchSuggestions = [];
                      },
                      onTap: () {
                        // Tampilkan kembali saran jika ada teks
                        _updateSuggestions(_searchController.text);
                      },
                    ),
                  ),
                ),
                if (_distanceInKm != null && _durationText != null)
                  Positioned(
                    bottom: 100,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((255 * 0.1).round()),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Rute ke $_destinationName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _polylines.clear();
                                    _distanceInKm = null;
                                    _durationText = null;
                                    _destinationName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${_distanceInKm!.toStringAsFixed(2)} km',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 15),
                              const Icon(Icons.access_time, color: Colors.blue),
                              const SizedBox(width: 5),
                              Text(
                                _durationText!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

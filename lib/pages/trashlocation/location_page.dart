import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trashvisor/core/colors.dart';

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
  double? _distanceInKm;
  String? _destinationName;

  late final String _apiKey;

  final List<Map<String, dynamic>> trashLocations = const [
    {
      'name': 'TPA Parit Enam, Pangkal Pinang',
      'coordinates': LatLng(-2.1234520467333087, 106.14289369216657),
      'type': 'TPA',
      'rating': 3.7,
      'reviews': 19,
    },
    {
      'name': 'TPA Kenanga, Bangka',
      'coordinates': LatLng(-1.9359066298344438, 106.09228684232795),
      'type': 'TPA',
      'rating': 4.5,
      'reviews': 2,
    },
    {
      'name': 'TPA Simpang Tiga, Belinyu, Bangka',
      'coordinates': LatLng(-1.5712620008436808, 105.78217352700443),
      'type': 'TPA',
      'rating': 3.7,
      'reviews': 3,
    },
    {
      'name': 'TPS 3R KSM. Kawa Begawe, Selindung, Gabek, Bangka',
      'coordinates': LatLng(-2.0591132074953196, 106.13406335509498),
      'type': 'TPS',
      'rating': 5.0,
      'reviews': 3,
    },
    {
      'name': 'Bank Sampah PangkalPinang',
      'coordinates': LatLng(-2.120870189632584, 106.10659753486853),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 1,
    },
    {
      'name': 'Bank Sampah Desa Karya Makmur, Pemali, Bangka',
      'coordinates': LatLng(-1.8142061411797634, 106.09560997303396),
      'type': 'Bank Sampah',
      'rating': 0.0,
      'reviews': 0,
    },
    {
      'name': 'Bank sampah pelawan, Koba, PangkalPinang',
      'coordinates': LatLng(-2.2937790697102307, 106.18114676295912),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 2,
    },
    {
      'name': 'Bank Sampah Sepakat Desa Air Limau, Muntok',
      'coordinates': LatLng(-1.9523199095692418, 105.24653808093647),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 2,
    },
    {
      'name': 'PDUS PABRIK DAUR ULANG SAMPAH PEMALI',
      'coordinates': LatLng(-1.8343182051314526, 106.0727548640453),
      'type': 'Daur Ulang',
      'rating': 1.0,
      'reviews': 1,
    },
    {
      'name': 'Tempat Pembuangan Sampah (TPS) AIK Cemang, Belitung',
      'coordinates': LatLng(-2.918810335999189, 108.18281498431779),
      'type': 'TPS',
      'rating': 4.8,
      'reviews': 4,
    },
    {
      'name': 'TPA PILANG, Tanjung Pandan, Belitung',
      'coordinates': LatLng(-2.7357451934770998, 107.66404564051427),
      'type': 'TPA',
      'rating': 0.0,
      'reviews': 0,
    },
    {
      'name': 'Bank Sampah Induk Manggar Belitung Timur',
      'coordinates': LatLng(-2.78749946687104, 108.27651503156396),
      'type': 'Bank Sampah',
      'rating': 4.7,
      'reviews': 3,
    },
    {
      'name': 'BANK SAMPAH SIJUK, Belitung',
      'coordinates': LatLng(-2.5501377847133226, 107.68107859664937),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 1,
    },
    {
      'name': 'CV Trijaya - Parit Lalang, Pangkal Pinang',
      'coordinates': LatLng(-2.0697120128678166, 106.11539336412203),
      'type': 'Daur Ulang',
      'rating': 5.0,
      'reviews': 1,
    },
    {
      'name': 'Bangka Recycle - Pangkal Balam, PangkalPinang',
      'coordinates': LatLng(-2.0311130959553245, 106.14384019213588),
      'type': 'Daur Ulang',
      'rating': 4.8,
      'reviews': 6,
    },
    {
      'name': 'GreenVibe Tote - Merawang, Bangka',
      'coordinates': LatLng(-2.055204832796862, 106.0828241084341),
      'type': 'Daur Ulang',
      'rating': 0.0,
      'reviews': 0,
    },
    {
      'name': 'Ahau Kardus - Tanjung Pandan, Belitung',
      'coordinates': LatLng(-2.6957192547471416, 107.6708454483477),
      'type': 'Daur Ulang',
      'rating': 5.0,
      'reviews': 1,
    },
  ];

  String _getPhotoUrl(String? photoReference) {
    if (photoReference == null || photoReference.isEmpty) {
      return 'assets/images/bg_handling.png'; // fallback ke asset lokal
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
        _addManualMarkers();
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

    // Check if the widget is still in the tree before calling setState()
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
      });
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null || _apiKey.isEmpty) {
      return;
    }

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
          for (var result in data['results']) {
            final lat = result['geometry']['location']['lat'];
            final lng = result['geometry']['location']['lng'];
            final name = result['name'];
            final placeId = result['place_id'];

            // Ambil photo_reference kalau ada
            final photos = result['photos'] as List?;
            String? photoRef = photos != null && photos.isNotEmpty
                ? photos.first['photo_reference']
                : null;

            _getPhotoUrl(photoRef);

            BitmapDescriptor markerIcon;
            if (customName == 'TPA') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              );
            } else if (customName == 'TPS') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              );
            } else if (customName == 'Bank Sampah') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              );
            } else if (customName == 'Daur Ulang') {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueYellow,
              );
            } else {
              markerIcon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              );
            }

            setState(() {
              _markers.add(
                Marker(
                  markerId: MarkerId(placeId),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: name, snippet: customName),
                  icon: markerIcon,
                  onTap: () {
                    // ambil photoReference jika data Google, null kalau manual
                    final photos = result?['photos'] as List?;
                    String? photoRef = photos != null && photos.isNotEmpty
                        ? photos.first['photo_reference']
                        : null;

                    final imageUrl = _getPhotoUrl(photoRef);

                    _drawRoute(
                      LatLng(lat, lng), // destination
                      _currentPosition!, // origin
                      (distanceKm) {
                        _showInfoSheet(
                          name: name,
                          type: customName, // atau type manual
                          rating: result?['rating']?.toDouble() ?? 0.0,
                          reviews: result?['user_ratings_total'] ?? 0,
                          imageUrl: imageUrl,
                          distanceInKm: distanceKm,
                        );
                      },
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
  }

  void _addManualMarkers() {
    setState(() {
      for (var location in trashLocations) {
        final LatLng coordinates = location['coordinates'] as LatLng;
        final String name = location['name'] as String;
        final String type = location['type'] as String;

        BitmapDescriptor markerIcon;
        if (type.toLowerCase().contains('bank sampah') ||
            type.toLowerCase().contains('daur ulang')) {
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
        } else {
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          );
        }

        _markers.add(
          Marker(
            markerId: MarkerId(name),
            position: coordinates,
            icon: markerIcon,
            onTap: () async {
              // coba ambil gambar dari Google Places API
              String? photoRef;
              try {
                final url = Uri.parse(
                  'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
                  '?location=${coordinates.latitude},${coordinates.longitude}'
                  '&radius=50' // radius kecil
                  '&key=$_apiKey',
                );

                final response = await http.get(url);
                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  final results = data['results'] as List?;
                  if (results != null && results.isNotEmpty) {
                    final photos = results.first['photos'] as List?;
                    photoRef = photos != null && photos.isNotEmpty
                        ? photos.first['photo_reference']
                        : null;
                  }
                }
              } catch (_) {
                photoRef = null;
              }

              final imageUrl = _getPhotoUrl(
                photoRef,
              ); // fallback ke default otomatis

              _drawRoute(coordinates, _currentPosition!, (distanceKm) {
                _showInfoSheet(
                  name: name,
                  type: type,
                  rating: location['rating'] as double,
                  reviews: location['reviews'] as int,
                  imageUrl: imageUrl,
                  distanceInKm: distanceKm,
                );
              });
            },
          ),
        );
      }
    });
  }

  // Tambah parameter distanceInKm di _showInfoSheet
  void _showInfoSheet({
    required String name,
    required String type,
    required double rating,
    required int reviews,
    required String imageUrl,
    required double distanceInKm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/bg_handling.png',
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Nunito',
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
                      fontFamily: 'Nunito',
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
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.blue),
                  const SizedBox(width: 5),
                  Text(
                    'Jarak: ${distanceInKm.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  final PolylinePoints polylinePoints = PolylinePoints();

  Future<void> _drawRoute(
    LatLng destination,
    LatLng origin,
    Function(double) onDistanceCalculated,
  ) async {
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _apiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      debugPrint('Status: ${result.status}');
      debugPrint('Error: ${result.errorMessage}');
      debugPrint('Jumlah titik rute: ${result.points.length}');

      if (result.points.isNotEmpty) {
        // decode polyline
        final route = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        // hitung jarak total
        double totalDistance = 0;
        for (int i = 0; i < route.length - 1; i++) {
          totalDistance += Geolocator.distanceBetween(
            route[i].latitude,
            route[i].longitude,
            route[i + 1].latitude,
            route[i + 1].longitude,
          );
        }

        onDistanceCalculated(totalDistance / 1000);

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: route,
              color: Colors.redAccent,
              width: 5,
            ),
          };
        });
      } else {
        // fallback ke garis lurus kalau rute gagal
        double fallbackDistance = Geolocator.distanceBetween(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        );
        debugPrint('Fallback distance dipakai: $fallbackDistance m');
        onDistanceCalculated(fallbackDistance / 1000);

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('fallback'),
              points: [origin, destination],
              color: Colors.blueGrey,
              width: 3,
            ),
          };
        });
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      onDistanceCalculated(0);
    }
  }

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
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Layer 1: Google Map, yang akan menempati seluruh ruang
                GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                ),

                // Layer 2: Search bar, yang akan melayang di atas peta
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
                      // Teks inputan user
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: AppColors.fernGreen,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi',
                        // Teke placeholder
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
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 8,
                          ), // geser ke dalam
                          child: Icon(Icons.search, color: AppColors.fernGreen),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        // tambahin kalau nanti ada suffixIcon
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      onSubmitted: (value) {
                        final marker = _markers.firstWhere(
                          (m) => (m.infoWindow.title ?? '')
                              .toLowerCase()
                              .contains(value.toLowerCase()),
                          orElse: () => const Marker(
                            markerId: MarkerId('null'),
                            position: LatLng(0, 0),
                          ),
                        );
                        if (marker.markerId.value != 'null') {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(marker.position),
                          );
                          _drawRoute(marker.position, _currentPosition!, (
                            distanceKm,
                          ) {
                            setState(() {
                              _distanceInKm = distanceKm;
                              _destinationName = marker.infoWindow.title;
                            });
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lokasi tidak ditemukan'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),

                // Layer 3: Kotak info jarak, yang juga melayang di atas peta
                if (_distanceInKm != null && _destinationName != null)
                  Positioned(
                    bottom: 20,
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
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Jarak ke $_destinationName: ${_distanceInKm!.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _polylines.clear();
                                _distanceInKm = null;
                                _destinationName = null;
                              });
                            },
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

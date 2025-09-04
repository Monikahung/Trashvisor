import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<LatLng> _routePoints = [];
  double? _distanceInKm;
  String? _destinationName;

  final List<Map<String, dynamic>> trashLocations = [
    {
      'name': 'TPA Parit Enam, Pangkal Pinang',
      'coordinates': const LatLng(-2.1234520467333087, 106.14289369216657),
      'type': 'TPA',
      'rating': 3.7,
      'reviews': 19,
      'imageUrl': 'https://placehold.co/600x400/2ecc71/ffffff?text=TPA',
    },
    {
      'name': 'TPA Kenanga, Bangka',
      'coordinates': const LatLng(-1.9359066298344438, 106.09228684232795),
      'type': 'TPA',
      'rating': 4.5,
      'reviews': 2,
      'imageUrl': 'https://placehold.co/600x400/c0392b/ffffff?text=TPA',
    },
    {
      'name': 'TPA Simpang Tiga, Belinyu, Bangka',
      'coordinates': const LatLng(-1.5712620008436808, 105.78217352700443),
      'type': 'TPA',
      'rating': 3.7,
      'reviews': 3,
      'imageUrl': 'https://placehold.co/600x400/9b59b6/ffffff?text=TPA',
    },
    {
      'name': 'TPS 3R KSM. Kawa Begawe, Selindung, Gabek, Bangka',
      'coordinates': const LatLng(-2.0591132074953196, 106.13406335509498),
      'type': 'TPS',
      'rating': 5.0,
      'reviews': 3,
      'imageUrl': 'https://placehold.co/600x400/3498db/ffffff?text=TPS',
    },
    {
      'name': 'Bank Sampah PangkalPinang',
      'coordinates': const LatLng(-2.120870189632584, 106.10659753486853),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 1,
      'imageUrl': 'https://placehold.co/600x400/f1c40f/000000?text=Bank+Sampah',
    },
    {
      'name': 'Bank Sampah Desa Karya Makmur, Pemali, Bangka',
      'coordinates': const LatLng(-1.8142061411797634, 106.09560997303396),
      'type': 'Bank Sampah',
      'rating': 0.0,
      'reviews': 0,
      'imageUrl': 'https://placehold.co/600x400/e67e22/ffffff?text=Bank+Sampah',
    },
    {
      'name': 'Bank sampah pelawan, Koba, PangkalPinang',
      'coordinates': const LatLng(-2.2937790697102307, 106.18114676295912),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 2,
      'imageUrl': 'https://placehold.co/600x400/2980b9/ffffff?text=Bank+Sampah',
    },
    {
      'name': 'Bank Sampah Sepakat Desa Air Limau, Muntok',
      'coordinates': const LatLng(-1.9523199095692418, 105.24653808093647),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 2,
      'imageUrl': 'https://placehold.co/600x400/2c3e50/ffffff?text=Bank+Sampah',
    },
    {
      'name': 'PDUS PABRIK DAUR ULANG SAMPAH PEMALI',
      'coordinates': const LatLng(-1.8343182051314526, 106.0727548640453),
      'type': 'Daur Ulang',
      'rating': 1.0,
      'reviews': 1,
      'imageUrl': 'https://placehold.co/600x400/7f8c8d/ffffff?text=Daur+Ulang',
    },
    {
      'name': 'Tempat Pembuangan Sampah (TPS) AIK Cemang, Belitung',
      'coordinates': const LatLng(-2.918810335999189, 108.18281498431779),
      'type': 'TPS',
      'rating': 4.8,
      'reviews': 4,
      'imageUrl': 'https://placehold.co/600x400/d35400/ffffff?text=TPS',
    },
    {
      'name': 'TPA PILANG, Tanjung Pandan, Belitung',
      'coordinates': const LatLng(-2.7357451934770998, 107.66404564051427),
      'type': 'TPA',
      'rating': 0.0,
      'reviews': 0,
      'imageUrl': 'https://placehold.co/600x400/8e44ad/ffffff?text=TPA',
    },
    {
      'name': 'Bank Sampah Induk Manggar Belitung Timur',
      'coordinates': const LatLng(-2.78749946687104, 108.27651503156396),
      'type': 'Bank Sampah',
      'rating': 4.7,
      'reviews': 3,
      'imageUrl': 'https://placehold.co/600x400/27ae60/ffffff?text=Bank+Sampah',
    },
    {
      'name': 'BANK SAMPAH SIJUK, Belitung',
      'coordinates': const LatLng(-2.5501377847133226, 107.68107859664937),
      'type': 'Bank Sampah',
      'rating': 5.0,
      'reviews': 1,
      'imageUrl': 'https://placehold.co/600x400/f39c12/ffffff?text=Bank+Sampah',
    },
    {
      'name': 'CV Trijaya - Parit Lalang, Pangkal Pinang',
      'coordinates': const LatLng(-2.0697120128678166, 106.11539336412203),
      'type': 'Daur Ulang',
      'rating': 5.0,
      'reviews': 1,
      'imageUrl': 'https://placehold.co/600x400/1abc9c/ffffff?text=Daur+Ulang',
    },
    {
      'name': 'Bangka Recycle - Pangkal Balam, PangkalPinang',
      'coordinates': const LatLng(-2.0311130959553245, 106.14384019213588),
      'type': 'Daur Ulang',
      'rating': 4.8,
      'reviews': 6,
      'imageUrl': 'https://placehold.co/600x400/95a5a6/ffffff?text=Daur+Ulang',
    },
    {
      'name': 'GreenVibe Tote - Merawang, Bangka',
      'coordinates': const LatLng(-2.055204832796862, 106.0828241084341),
      'type': 'Daur Ulang',
      'rating': 0.0,
      'reviews': 0,
      'imageUrl': 'https://placehold.co/600x400/bdc3c7/000000?text=Daur+Ulang',
    },
    {
      'name': 'Ahau Kardus - Tanjung Pandan, Belitung',
      'coordinates': const LatLng(-2.6957192547471416, 107.6708454483477),
      'type': 'Daur Ulang',
      'rating': 5.0,
      'reviews': 1,
      'imageUrl': 'https://placehold.co/600x400/f39c12/000000?text=Daur+Ulang',
    },
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _searchLocation(String query) {
    if (query.isEmpty) return;

    final normalizedQuery = query.toLowerCase();

    final foundLocation = trashLocations.firstWhere(
      (location) => (location['name'] as String).toLowerCase().contains(normalizedQuery),
      orElse: () => {},
    );

    if (foundLocation.isNotEmpty) {
      final foundCoordinates = foundLocation['coordinates'] as LatLng;

      if (_currentPosition != null) {
        final distance = const Distance();
        final double meters = distance(_currentPosition!, foundCoordinates);

        setState(() {
          _routePoints = [_currentPosition!, foundCoordinates];
          _distanceInKm = meters / 1000;
          _destinationName = foundLocation['name'] as String;
        });
      }

      _mapController.move(foundCoordinates, 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak ditemukan.'),
        ),
      );
    }
  }

  Icon getIconForLocation(String type) {
    if (type == 'Bank Sampah' || type == 'Daur Ulang') {
      return const Icon(
        Icons.recycling,
        color: Colors.green,
        size: 40.0,
      );
    } else {
      return const Icon(
        Icons.location_on,
        color: Colors.lightBlue,
        size: 40.0,
      );
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
    final List<Marker> markers = trashLocations.map((location) {
      return Marker(
        point: location['coordinates'] as LatLng,
        child: InkWell(
          onTap: () {
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
                          location['imageUrl'] as String,
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        location['name'] as String,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _buildRatingStars(location['rating'] as double),
                          const SizedBox(width: 10),
                          Text(
                            '${location['rating']} (${location['reviews']} Ulasan)',
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
                        'Jenis: ${location['type']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: getIconForLocation(location['type'] as String),
        ),
      );
    }).toList();

    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          child: const Icon(
            Icons.my_location,
            color: Colors.blueAccent,
            size: 40.0,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF678E35),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: const Icon(Icons.location_on, color: Color(0xFF678E35)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
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
                    color: Colors.white70,
                    fontFamily: 'Nunito',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(-2.1234520467333087, 106.14289369216657),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trashvisor.trash_location',
              ),
              MarkerLayer(markers: markers),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((255 * 0.5).round()),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari lokasi di sini',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey[600]),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),
          if (_distanceInKm != null && _destinationName != null)
            Positioned(
              bottom: 120,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha((255 * 0.5).round()),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jarak ke $_destinationName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_distanceInKm!.toStringAsFixed(2)} km (estimasi)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _routePoints = [];
                          _distanceInKm = null;
                          _destinationName = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in_btn',
                  mini: true,
                  backgroundColor: const Color(0xFF678E35),
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoom_out_btn',
                  mini: true,
                  backgroundColor: const Color(0xFF678E35),
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                  },
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
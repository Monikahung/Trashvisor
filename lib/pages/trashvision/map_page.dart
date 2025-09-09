import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:trashvisor/core/colors.dart';

class MapPage extends StatefulWidget {
  final String locationName;
  final LatLng destination;
  final String type;

  const MapPage({
    super.key,
    required this.locationName,
    required this.destination,
    required this.type,
  });

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final String apiKey = dotenv.env["GOOGLE_MAPS_API_KEY"] ?? '';
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Position? _currentPosition;
  String? _distance;
  String? _duration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  // Mendapatkan lokasi saat ini dan menggambar rute
  Future<void> _loadRoute() async {
    try {
      Position currentPosition = await _getCurrentLocation();
      setState(() {
        _currentPosition = currentPosition;
      });

      _addMarkers();
      await _getRouteAndInfo();
      _fitMapToRoute();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading route: $e");
      setState(() {
        _isLoading = false;
        // Optionally, show an error message
      });
    }
  }

  // Mendapatkan lokasi pengguna
  Future<Position> _getCurrentLocation() async {
    // Implementasi geolocator yang sama seperti di TrashLocationState
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Menambahkan marker ke peta
  void _addMarkers() {
    _markers.clear();
    
    // Marker lokasi Anda
    _markers.add(
      Marker(
        markerId: const MarkerId("current_location"),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: "Lokasi Anda"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Marker lokasi tujuan
    double hue;
    switch (widget.type) {
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

    _markers.add(
      Marker(
        markerId: MarkerId(widget.locationName),
        position: widget.destination,
        infoWindow: InfoWindow(title: widget.locationName, snippet: widget.type),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ),
    );
  }

  // Mendapatkan rute dan informasi jarak/waktu
  Future<void> _getRouteAndInfo() async {
    final origin = "${_currentPosition!.latitude},${_currentPosition!.longitude}";
    final destination = "${widget.destination.latitude},${widget.destination.longitude}";
    final url = "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$apiKey";
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "OK") {
        final route = data["routes"][0];
        final legs = route["legs"][0];
        
        setState(() {
          _distance = legs["distance"]["text"];
          _duration = legs["duration"]["text"];

          // Menggambar polyline
          final points = route["overview_polyline"]["points"];
          
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route_polyline"),
              points: _decodePolyline(points),
              color: AppColors.fernGreen,
              width: 5,
            ),
          );
        });
      } else {
        debugPrint("Directions API error: ${data["status"]}");
      }
    } else {
      debugPrint("Failed to get directions: ${response.statusCode}");
    }
  }

  // Metode untuk decode polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Menyesuaikan zoom peta agar rute terlihat
  void _fitMapToRoute() async {
    final controller = await _controller.future;
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        _currentPosition!.latitude < widget.destination.latitude
            ? _currentPosition!.latitude
            : widget.destination.latitude,
        _currentPosition!.longitude < widget.destination.longitude
            ? _currentPosition!.longitude
            : widget.destination.longitude,
      ),
      northeast: LatLng(
        _currentPosition!.latitude > widget.destination.latitude
            ? _currentPosition!.latitude
            : widget.destination.latitude,
        _currentPosition!.longitude > widget.destination.longitude
            ? _currentPosition!.longitude
            : widget.destination.longitude,
      ),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.fernGreen),
            )
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: widget.destination,
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  markers: _markers,
                  polylines: _polylines,
                ),

                // Tombol Back
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.fernGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.whiteSmoke,
                      ),
                    ),
                  ),
                ),

                // Info card di bawah
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Rute ke ${widget.locationName}",
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkMossGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.directions_car, color: AppColors.fernGreen),
                            const SizedBox(width: 8),
                            Text(
                              _distance ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 24),
                            const Icon(Icons.access_time, color: AppColors.fernGreen),
                            const SizedBox(width: 8),
                            Text(
                              _duration ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                color: Colors.black,
                              ),
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
import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  // �a��ran dosya (emergency_screen) hata vermesin diye bu parametreleri tutuyoruz,
  // ama �izim yaparken kullanmayaca��z.
  final LatLng selectedLocation;
  final LatLng? userLocation;
  final String? locationName;
  final String? noteInfo;

  const MapScreen({
    super.key,
    required this.selectedLocation,
    this.userLocation,
    this.locationName,
    this.noteInfo,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _foundLocation;
  bool _isLoadingLocation = false;

  // YEDEK KONUM (GPS yoksa otel merkezi)
  final LatLng _backupLocation = const LatLng(37.216097, 28.351872);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userLocation == null) {
        _findLocation();
      } else {
        _centerOnUser();
      }
    });
  }

  Future<void> _findLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.debug('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.debug('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _foundLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_foundLocation!, 18.0);
        });
      }
    } catch (e) {
      Logger.debug("Error getting location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Sadece kullan�c�ya odaklanan fonksiyon
  void _centerOnUser() {
    final LatLng displayUserLocation =
        _foundLocation ?? widget.userLocation ?? _backupLocation;
    _mapController.move(displayUserLocation, 18.0);
  }

  @override
  Widget build(BuildContext context) {
    // Hangi konumu g�sterece�iz?
    final LatLng displayUserLocation =
        _foundLocation ?? widget.userLocation ?? _backupLocation;
    final bool isSimulationMode =
        _foundLocation == null && widget.userLocation == null;

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. HAR�TA ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: displayUserLocation,
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.oteluygulamasi.app',
              ),

              // NOT: PolylineLayer (K�rm�z� �izgi) buradan kald�r�ld�.
              MarkerLayer(
                markers: [
                  // NOT: Hedef (Ye�il Kap�) ikonu kald�r�ld�.

                  // Sadece Kullan�c� (Mavi �nsan)
                  Marker(
                    point: displayUserLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- 2. GER� D�N BUTONU ---
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              radius: 25,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // --- 3. KONUMUMA G�T BUTONU ---
          Positioned(
            right: 20,
            bottom: 80,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _centerOnUser,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // --- 4. S�M�LASYON UYARISI ---
          if (isSimulationMode || _isLoadingLocation)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isLoadingLocation ? Colors.blue : Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      const BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    _isLoadingLocation
                        ? "Calculating Location..."
                        : "Simulation Mode (GPS Off)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  // Çağıran dosya (emergency_screen) hata vermesin diye bu parametreleri tutuyoruz,
  // ama çizim yaparken kullanmayacağız.
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
        print('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
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
      print("Error getting location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Sadece kullanıcıya odaklanan fonksiyon
  void _centerOnUser() {
    final LatLng displayUserLocation =
        _foundLocation ?? widget.userLocation ?? _backupLocation;
    _mapController.move(displayUserLocation, 18.0);
  }

  @override
  Widget build(BuildContext context) {
    // Hangi konumu göstereceğiz?
    final LatLng displayUserLocation =
        _foundLocation ?? widget.userLocation ?? _backupLocation;
    final bool isSimulationMode =
        _foundLocation == null && widget.userLocation == null;

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. HARİTA ---
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

              // NOT: PolylineLayer (Kırmızı Çizgi) buradan kaldırıldı.
              MarkerLayer(
                markers: [
                  // NOT: Hedef (Yeşil Kapı) ikonu kaldırıldı.

                  // Sadece Kullanıcı (Mavi İnsan)
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

          // --- 2. GERİ DÖN BUTONU ---
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.6),
              radius: 25,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // --- 3. KONUMUMA GİT BUTONU ---
          Positioned(
            right: 20,
            bottom: 150,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black87),
              onPressed: _centerOnUser,
            ),
          ),

          // --- 4. SİMÜLASYON UYARISI ---
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
                        ? "Konum Hesaplanıyor..."
                        : "Simülasyon Modu (GPS Kapalı)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // --- 5. BİLGİ KARTI (Sadeleştirilmiş) ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.map, color: Colors.blueAccent, size: 32),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Anlık Konumunuz",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              widget.locationName ?? "Bilinmeyen Bölge",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Eğer bir not varsa göster
                  if (widget.noteInfo != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white24),
                    ),
                    Text(
                      widget.noteInfo!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

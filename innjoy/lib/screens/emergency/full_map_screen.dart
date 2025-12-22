import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Acil ��k�� Kap�s� Modeli
class _EmergencyExit {
  final String id;
  final String name;
  final LatLng location;
  final String description;

  const _EmergencyExit({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
  });
}

class FullScreenMapPage extends StatefulWidget {
  final LatLng selectedLocation; // Hedef (En Yak�n ��k�� Kap�s�)
  final LatLng? userLocation; // Kullan�c�n�n o anki konumu

  // �sim bilgisini d��ar�dan alabiliriz ama mesafeyi art�k kendimiz hesaplayaca��z
  final String? locationName;
  final String? noteInfo;

  const FullScreenMapPage({
    super.key,
    required this.selectedLocation,
    this.userLocation,
    this.locationName,
    this.noteInfo,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance(); // Mesafe �l�er
  LatLng? _foundLocation;

  // YEDEK KONUM - MU�LA SITKI KO�MAN �N�V. M�HEND�SL�K FAK�LTES�
  final LatLng _backupLocation = const LatLng(37.1614, 28.3758);

  // M�HEND�SL�K FAK�LTES� T�M AC�L �IKI� KAPILARI
  final List<_EmergencyExit> _allEmergencyExits = const [
    // Main Entrance (North direction)
    _EmergencyExit(
      id: 'exit_1',
      name: 'Main Entrance',
      location: LatLng(37.16141430718726, 28.37590816078527),
      description: 'Faculty main entrance - North direction',
    ),
    // South Exit
    _EmergencyExit(
      id: 'exit_2',
      name: 'South Exit',
      location: LatLng(37.16152202185226, 28.375945340536738),
      description: 'Faculty south exit',
    ),
    // West Side Door
    _EmergencyExit(
      id: 'exit_3',
      name: 'West Side Door',
      location: LatLng(37.161113984268624, 28.37484855454888),
      description: 'Faculty west side exit - Parking lot direction',
    ),
    // East Side Door (Energy Materials Lab. side)
    _EmergencyExit(
      id: 'exit_4',
      name: 'East Side Door',
      location: LatLng(37.16120, 28.37680),
      description: 'Faculty east side exit - Energy Lab. direction',
    ),
    // Emergency Staircase Exit (Geology Eng. side)
    _EmergencyExit(
      id: 'exit_5',
      name: 'Emergency Staircase Exit',
      location: LatLng(37.16100, 28.37520),
      description: 'Fire staircase exit - Geology Eng. direction',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Harita render problemini �nlemek i�in gecikme eklendi
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Haritan�n tam olarak render edilmesini bekle
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (widget.userLocation == null) {
        _findLocation();
      } else {
        _fitBounds();
      }
    });
  }

  Future<void> _findLocation() async {
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
          _fitBounds();
        });
      }
    } catch (e) {
      Logger.debug("Error getting location: $e");
    }
  }

  void _fitBounds() {
    try {
      final LatLng displayUserLocation =
          _foundLocation ?? widget.userLocation ?? _backupLocation;
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [displayUserLocation, widget.selectedLocation],
          padding: const EdgeInsets.all(80),
        ),
      );
      // Haritay� yeniden render etmesi i�in k���k bir animasyon tetikle
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {}); // Yeniden build tetikle
        }
      });
    } catch (e) {
      Logger.debug("Error fitting bounds: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hangi konumu kullanaca��z?
    final LatLng displayUserLocation =
        _foundLocation ?? widget.userLocation ?? _backupLocation;

    // Mesafeyi ve Y�nergeyi Hesapla
    final double distanceVal = _distanceCalculator.as(
      LengthUnit.Meter,
      displayUserLocation,
      widget.selectedLocation,
    );
    final String distanceText = "${distanceVal.toInt()} meters";

    // Dinamik Y�nerge Rengi ve Metni
    String instructionText;
    Color instructionColor;

    if (distanceVal < 10) {
      instructionText = "YOU ARE SAFE! DESTINATION REACHED.";
      instructionColor = Colors.greenAccent;
    } else if (distanceVal < 50) {
      instructionText = "Almost there, head to the exit.";
      instructionColor = Colors.amber;
    } else {
      instructionText = "Follow the red route and move quickly.";
      instructionColor = Colors.white70;
    }

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. HAR�TA ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: displayUserLocation,
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.oteluygulamasi.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [displayUserLocation, widget.selectedLocation],
                    color: Colors.redAccent,
                    strokeWidth: 6.0,
                  ),
                ],
              ),
              // T�M �IKI� KAPILARI ��ARET��LER�
              MarkerLayer(
                markers: [
                  // Kullan�c� konumu (Mavi)
                  Marker(
                    point: displayUserLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 55,
                    ),
                  ),
                  // T�m acil ��k�� kap�lar�
                  ..._allEmergencyExits.map((exit) {
                    // Bu ��k�� en yak�n se�ili ��k�� m�?
                    final bool isNearest =
                        exit.location.latitude ==
                            widget.selectedLocation.latitude &&
                        exit.location.longitude ==
                            widget.selectedLocation.longitude;
                    return Marker(
                      point: exit.location,
                      width: isNearest ? 80 : 60,
                      height: isNearest ? 80 : 60,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: isNearest ? Colors.green : Colors.orange,
                            size: isNearest ? 50 : 40,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isNearest ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isNearest ? 'NEAREST' : exit.name.split(' ')[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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

          // --- 3. HAR�TAYI ORTALA ---
          Positioned(
            right: 20,
            bottom: 240,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _fitBounds,
              child: const Icon(
                Icons.center_focus_strong,
                color: Colors.black87,
              ),
            ),
          ),

          // --- 5. B�LG� VE Y�NERGE KARTI (D�NAM�K) ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
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
                  // Konum Ad� ve Mesafe
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_run,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.locationName ?? "Emergency Exit Point",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Distance: $distanceText", // CALCULATED DISTANCE HERE
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white24),
                  ),

                  // D�NAM�K Y�NERGE METN�
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: instructionColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      instructionText, // HESAPLANAN Y�NERGE BURADA
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: instructionColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  // Ek Not (Varsa)
                  if (widget.noteInfo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        widget.noteInfo!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
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

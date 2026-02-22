import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; // Harita paketi
import 'package:latlong2/latlong.dart'; // Koordinat paketi
import 'package:geolocator/geolocator.dart'; // Konum paketi

// Kendi proje yollar�n� kontrol et:
import 'package:login_page/services/database_service.dart';
import 'package:login_page/location/location_model.dart';
import 'package:login_page/screens/emergency/full_map_screen.dart';
import '../../utils/responsive_utils.dart';

// Acil ��k�� Kap�s� Modeli
class EmergencyExit {
  final String id;
  final String name;
  final LatLng location;
  final String description;

  const EmergencyExit({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
  });
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Stream<DocumentSnapshot> _roomStream;
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();

  // --- MU�LA SITKI KO�MAN �N�VERS�TES� M�HEND�SL�K FAK�LTES� ---
  // Ana Koordinatlar: 37.1614, 28.3758 (Haritadaki bina merkezi)

  // GPS �ekmezse kullan�lacak YEDEK KONUM (M�hendislik Fak�ltesi Merkezi)
  final LatLng _backupLocation = const LatLng(37.1614, 28.3758);

  // M�HEND�SL�K FAK�LTES� AC�L �IKI� KAPILARI
  final List<EmergencyExit> _emergencyExits = const [
    // Main Entrance (North - Moonlight Square direction)
    EmergencyExit(
      id: 'exit_1',
      name: 'Main Entrance',
      location: LatLng(37.16141430718726, 28.37590816078527),
      description: 'Faculty main entrance - North direction (Moonlight Square)',
    ),
    // South Exit
    EmergencyExit(
      id: 'exit_2',
      name: 'South Exit',
      location: LatLng(37.16152202185226, 28.375945340536738),
      description: 'Faculty south exit',
    ),
    // West Side Door
    EmergencyExit(
      id: 'exit_3',
      name: 'West Side Door',
      location: LatLng(37.161113984268624, 28.37484855454888),
      description: 'Faculty west side exit - Parking lot direction',
    ),
    // East Side Door (Energy Materials Lab. side)
    EmergencyExit(
      id: 'exit_4',
      name: 'East Side Door',
      location: LatLng(37.16120, 28.37680),
      description: 'Faculty east side exit - Energy Lab. direction',
    ),
    // Emergency Staircase Exit (Geology Eng. side)
    EmergencyExit(
      id: 'exit_5',
      name: 'Emergency Staircase Exit',
      location: LatLng(37.16100, 28.37520),
      description: 'Fire staircase exit - Geology Eng. direction',
    ),
  ];

  // En yak�n ��k�� bilgisi
  EmergencyExit? _nearestExit;
  double? _nearestExitDistance;

  // Kullan�c� Konumu ve Oda Bilgileri
  LatLng? _userLocation;
  String? userActualRoomNumber;
  String selectedLocationKey = 'my_room';
  bool isLoadingUser = true;

  // Dropdown Se�enekleri
  final Map<String, String> locationOptions = {
    'my_room': 'My Room',
    'restaurant': 'Restaurant',
    'fitness': 'Fitness Center',
    'spa': 'Spa Center',
    'reception': 'Reception',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startLocationTracking();
    _updateStream();
  }

  // En yak�n ��k��� hesapla
  void _calculateNearestExit(LatLng userPos) {
    EmergencyExit? nearest;
    double minDistance = double.infinity;

    for (final exit in _emergencyExits) {
      final distance = _distanceCalculator.as(
        LengthUnit.Meter,
        userPos,
        exit.location,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = exit;
      }
    }

    if (mounted) {
      setState(() {
        _nearestExit = nearest;
        _nearestExitDistance = minDistance;
      });
    }
  }

  void _updateStream() {
    _roomStream = _dbService.getRoomStream(documentIdToQuery);
  }

  // --- 1. KONUM TAK�B� VE YEDEK KONUM MANTI�I ---
  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Servis a��k m�?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Logger.debug('Konum servisleri kapal�. Yedek konum kullan�l�yor.');
      _useBackupLocation(); // Servis kapal�ysa yede�e ge�
      return;
    }

    // �zin kontrol�
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Logger.debug('Konum izni reddedildi. Yedek konum kullan�l�yor.');
        _useBackupLocation(); // �zin yoksa yede�e ge�
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Logger.debug('Konum izni kal�c� reddedildi. Yedek konum kullan�l�yor.');
      _useBackupLocation();
      return;
    }

    // �zin al�nd�ysa �nce mevcut konumu al, sonra takibi ba�lat
    try {
      // �lk konum al�m� - daha h�zl� sonu� i�in
      final Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        final initialLocation = LatLng(
          initialPosition.latitude,
          initialPosition.longitude,
        );
        setState(() {
          _userLocation = initialLocation;
        });
        _calculateNearestExit(initialLocation);
        debugPrint(
          'Anl�k konum al�nd�: $initialPosition.latitude}, $initialPosition.longitude}',
        );
      }
    } catch (e) {
      Logger.debug('�lk konum al�namad�: $e - Yedek konum kullan�l�yor');
      _useBackupLocation();
    }

    // S�rekli konum takibi
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen(
      (Position position) {
        if (mounted) {
          final newLocation = LatLng(position.latitude, position.longitude);
          setState(() {
            _userLocation = newLocation;
          });
          // Her konum g�ncellemesinde en yak�n ��k��� yeniden hesapla
          _calculateNearestExit(newLocation);
        }
      },
      onError: (e) {
        // Stream hatas� durumunda da yede�e d�n
        Logger.debug('Konum stream hatas�: $e');
        _useBackupLocation();
      },
    );
  }

  // GPS �al��mazsa devreye girecek fonksiyon
  void _useBackupLocation() {
    if (mounted) {
      setState(() {
        _userLocation = _backupLocation;
      });
      // Yedek konum i�in de en yak�n ��k��� hesapla
      _calculateNearestExit(_backupLocation);
    }
  }

  // --- 2. KULLANICI ODA B�LG�S� ---
  Future<void> _loadUserData() async {
    try {
      String room = await _dbService.getUserRoomNumber();
      if (mounted) {
        setState(() {
          userActualRoomNumber = room;
          isLoadingUser = false;
        });
      }
    } catch (e) {
      Logger.debug("Hata: $e");
      if (mounted) setState(() => isLoadingUser = false);
    }
  }

  // --- 3. AC�L DURUM B�LD�R�M� ---
  Future<void> _handleSendAlert(String emergencyType) async {
    String roomToSend = userActualRoomNumber ?? "Unknown";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Sending $emergencyType alert...",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await _dbService.sendEmergencyAlert(
        emergencyType: emergencyType,
        roomNumber: roomToSend,
        locationContext: selectedLocationKey,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "HELP REQUEST SENT! ($emergencyType)",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- YARDIMCI FONKS�YONLAR ---
  String get documentIdToQuery {
    if (selectedLocationKey == 'my_room') {
      return userActualRoomNumber ?? "1";
    } else {
      return selectedLocationKey;
    }
  }

  String getDropdownText(String key) {
    if (key == 'my_room') {
      return "Location: My Room (${userActualRoomNumber ?? '...'})";
    }
    return "Location: ${locationOptions[key]}";
  }

  @override
  Widget build(BuildContext context) {
    // Tasar�m Renkleri
    const Color backgroundColor = Color(0xFF000000);
    const Color containerColor = Color(0xFF1E1E1E);
    const Color textColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;
    const Color iconBgColor = Color(0xFF2C2C2E);

    if (isLoadingUser) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Emergency",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 16.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: containerColor,
                value: selectedLocationKey,
                icon: const Icon(Icons.settings, color: textColor),
                items: locationOptions.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(
                      getDropdownText(key),
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedLocationKey = value;
                      _updateStream();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 16.0)),
          child: Column(
            children: [
              // �ST BUTONLAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopButton(
                    Icons.local_fire_department,
                    "Fire",
                    Colors.redAccent,
                    containerColor,
                    () => _handleSendAlert("Fire"),
                  ),
                  _buildTopButton(
                    Icons.broken_image_outlined,
                    "Earthquake",
                    Colors.redAccent,
                    containerColor,
                    () => _handleSendAlert("Earthquake"),
                  ),
                  _buildTopButton(
                    Icons.warning_amber_rounded,
                    "Other\nEmergencies",
                    Colors.redAccent,
                    containerColor,
                    () => _handleSendAlert("Other Emergency"),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),

              // STREAM BUILDER
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _roomStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                        ),
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return _buildErrorState(
                        "No data found for room $documentIdToQuery.",
                        secondaryTextColor,
                      );
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>;

                    // Not: Firebase verileri gelecekte kullan�labilir
                    // ignore: unused_local_variable
                    final _ = LocationModel.fromFirestore(
                      data,
                      documentIdToQuery,
                    );

                    // Kullan�c� Noktas� (GPS veya Yedek)
                    final LatLng currentUserPoint =
                        _userLocation ?? _backupLocation;

                    // En yak�n ��k�� noktas�
                    final LatLng targetExitPoint =
                        _nearestExit?.location ??
                        _emergencyExits.first.location;

                    // Mesafe hesaplama
                    final String distanceText = _nearestExitDistance != null
                        ? "${_nearestExitDistance!.toInt()} meters"
                        : "Calculating...";

                    return Column(
                      children: [
                        // --- CANLI M�N� HAR�TA ---
                        Expanded(
                          flex: 5,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F26),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                              child: Stack(
                                children: [
                                  // 1. Katman: Harita
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      // Harita a��ld���nda kullan�c�y� merkez al
                                      initialCenter: currentUserPoint,
                                      initialZoom: 18.0,
                                      interactionOptions:
                                          const InteractionOptions(
                                            flags: InteractiveFlag.all,
                                          ),
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                        subdomains: const ['a', 'b', 'c', 'd'],
                                      ),
                                      // ROTA ��ZG�S� - En yak�n ��k��a
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: [
                                              currentUserPoint,
                                              targetExitPoint,
                                            ],
                                            color: Colors.redAccent,
                                            strokeWidth: 5.0,
                                          ),
                                        ],
                                      ),
                                      // T�M �IKI� KAPILARI ��ARETLEY�C�LER�
                                      MarkerLayer(
                                        markers: [
                                      // Kullan�c� (Mavi �nsan)
                                          Marker(
                                            point: currentUserPoint,
                                            width: ResponsiveUtils.wp(context, 50 / 375),
                                            height: ResponsiveUtils.hp(context, 50 / 844),
                                            child: Icon(
                                              Icons.person_pin_circle,
                                              color: Colors.blue,
                                              size: ResponsiveUtils.iconSize(context) * (50 / 24),
                                            ),
                                          ),
                                          // T�m acil ��k�� kap�lar�
                                          ..._emergencyExits.map((exit) {
                                            final bool isNearest =
                                                _nearestExit?.id == exit.id;
                                            return Marker(
                                              point: exit.location,
                                              width: isNearest ? 55 : 40,
                                              height: isNearest ? 55 : 40,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.exit_to_app,
                                                      color: isNearest
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      size: isNearest ? 40 : 30,
                                                    ),
                                                    if (isNearest)
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 1,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'NEAREST',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // 2. Katman: B�y�t Butonu
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenMapPage(
                                                  selectedLocation:
                                                      targetExitPoint,
                                                  userLocation: _userLocation,
                                                  locationName:
                                                      _nearestExit?.name ??
                                                      "Nearest Exit",
                                                  noteInfo:
                                                      _nearestExit?.description,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(top: 10),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveUtils.spacing(context, 12),
                                          vertical: ResponsiveUtils.spacing(context, 6),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.open_in_full,
                                              color: Colors.white,
                                              size: ResponsiveUtils.iconSize(context) * (16 / 24),
                                            ),
                                            SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                                            Text(
                                              "Expand",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: ResponsiveUtils.sp(context, 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                        // --- TAL�MATLAR KARTI ---
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 26)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_run,
                                    color: Colors.redAccent,
                                    size: ResponsiveUtils.iconSize(context) * (28 / 24),
                                  ),
                                  SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                                  Expanded(
                                    child: Text(
                                      _nearestExit?.name ?? "Nearest Exit",
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.sp(context, 20),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.spacing(context, 12),
                                      vertical: ResponsiveUtils.spacing(context, 6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                                    ),
                                    child: Text(
                                      distanceText,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveUtils.sp(context, 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                              _buildInstructionItem(
                                Icons.info_outline,
                                _nearestExit?.description ??
                                    "Calculating nearest emergency exit...",
                                secondaryTextColor,
                                iconBgColor,
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                              _buildInstructionItem(
                                Icons.warning_amber_rounded,
                                "Follow the red route to reach the nearest exit!",
                                secondaryTextColor,
                                iconBgColor,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 10)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET TASARIMLARI ---
  Widget _buildErrorState(String message, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: ResponsiveUtils.iconSize(context) * (40 / 24)),
          SizedBox(height: ResponsiveUtils.spacing(context, 10)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton(
    IconData icon,
    String label,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
      child: Container(
        width: ResponsiveUtils.wp(context, 100 / 375),
        height: ResponsiveUtils.hp(context, 100 / 844),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: ResponsiveUtils.iconSize(context) * (32 / 24)),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveUtils.sp(context, 13),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(
    IconData icon,
    String text,
    Color textColor,
    Color iconBgColor,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 6)),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
          ),
          child: Icon(icon, size: ResponsiveUtils.iconSize(context) * (20 / 24), color: textColor),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 16)),
        Expanded(
          child: Text(text, style: TextStyle(color: textColor, fontSize: ResponsiveUtils.sp(context, 14))),
        ),
      ],
    );
  }
}



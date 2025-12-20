import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart'; // Harita paketi
import 'package:latlong2/latlong.dart'; // Koordinat paketi
import 'package:geolocator/geolocator.dart'; // Konum paketi

// Kendi proje yollarını kontrol et:
import 'package:login_page/map/map_screen.dart';
import 'package:login_page/service/database_service.dart';
import 'package:login_page/location/location_model.dart';
import 'package:login_page/screens/emergency/fullMapscreen.dart';

// Acil Çıkış Kapısı Modeli
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

  // --- MUĞLA SITKI KOÇMAN ÜNİVERSİTESİ MÜHENDİSLİK FAKÜLTESİ ---
  // Ana Koordinatlar: 37.1614, 28.3758 (Haritadaki bina merkezi)

  // GPS çekmezse kullanılacak YEDEK KONUM (Mühendislik Fakültesi Merkezi)
  final LatLng _backupLocation = const LatLng(37.1614, 28.3758);

  // MÜHENDİSLİK FAKÜLTESİ ACİL ÇIKIŞ KAPILARI
  final List<EmergencyExit> _emergencyExits = const [
    // Ana Giriş Kapısı (Kuzey - Ay Işığı Meydanı yönü)
    EmergencyExit(
      id: 'exit_1',
      name: 'Ana Giriş Kapısı',
      location: LatLng(37.16141430718726, 28.37590816078527),
      description: 'Fakülte ana giriş kapısı - Kuzey yönü (Ay Işığı Meydanı)',
    ),
    // Güney Çıkış Kapısı
    EmergencyExit(
      id: 'exit_2',
      name: 'Güney Çıkış Kapısı',
      location: LatLng(37.16152202185226, 28.375945340536738),
      description: 'Fakülte güney çıkış kapısı',
    ),
    // Batı Yan Kapısı
    EmergencyExit(
      id: 'exit_3',
      name: 'Batı Yan Kapısı',
      location: LatLng(37.161113984268624, 28.37484855454888),
      description: 'Fakülte batı yan çıkışı - Otopark yönü',
    ),
    // Doğu Yan Kapısı (Enerji Malzemeleri Lab. tarafı)
    EmergencyExit(
      id: 'exit_4',
      name: 'Doğu Yan Kapısı',
      location: LatLng(37.16120, 28.37680),
      description: 'Fakülte doğu yan çıkışı - Enerji Lab. yönü',
    ),
    // Acil Merdiven Çıkışı (Jeoloji Müh. tarafı)
    EmergencyExit(
      id: 'exit_5',
      name: 'Acil Merdiven Çıkışı',
      location: LatLng(37.16100, 28.37520),
      description: 'Yangın merdiveni çıkışı - Jeoloji Müh. yönü',
    ),
  ];

  // En yakın çıkış bilgisi
  EmergencyExit? _nearestExit;
  double? _nearestExitDistance;

  // Kullanıcı Konumu ve Oda Bilgileri
  LatLng? _userLocation;
  String? userActualRoomNumber;
  String selectedLocationKey = 'my_room';
  bool isLoadingUser = true;

  // Dropdown Seçenekleri
  final Map<String, String> locationOptions = {
    'my_room': 'Odam',
    'restaurant': 'Restoran',
    'fitness': 'Spor Salonu',
    'spa': 'Spa Merkezi',
    'reception': 'Resepsiyon',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startLocationTracking();
    _updateStream();
  }

  // En yakın çıkışı hesapla
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

  // --- 1. KONUM TAKİBİ VE YEDEK KONUM MANTIĞI ---
  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Servis açık mı?
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Konum servisleri kapalı. Yedek konum kullanılıyor.');
      _useBackupLocation(); // Servis kapalıysa yedeğe geç
      return;
    }

    // İzin kontrolü
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Konum izni reddedildi. Yedek konum kullanılıyor.');
        _useBackupLocation(); // İzin yoksa yedeğe geç
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Konum izni kalıcı reddedildi. Yedek konum kullanılıyor.');
      _useBackupLocation();
      return;
    }

    // İzin alındıysa önce mevcut konumu al, sonra takibi başlat
    try {
      // İlk konum alımı - daha hızlı sonuç için
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
          'Anlık konum alındı: ${initialPosition.latitude}, ${initialPosition.longitude}',
        );
      }
    } catch (e) {
      debugPrint('İlk konum alınamadı: $e - Yedek konum kullanılıyor');
      _useBackupLocation();
    }

    // Sürekli konum takibi
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen(
      (Position position) {
        if (mounted) {
          final newLocation = LatLng(position.latitude, position.longitude);
          setState(() {
            _userLocation = newLocation;
          });
          // Her konum güncellemesinde en yakın çıkışı yeniden hesapla
          _calculateNearestExit(newLocation);
        }
      },
      onError: (e) {
        // Stream hatası durumunda da yedeğe dön
        debugPrint('Konum stream hatası: $e');
        _useBackupLocation();
      },
    );
  }

  // GPS Çalışmazsa devreye girecek fonksiyon
  void _useBackupLocation() {
    if (mounted) {
      setState(() {
        _userLocation = _backupLocation;
      });
      // Yedek konum için de en yakın çıkışı hesapla
      _calculateNearestExit(_backupLocation);
    }
  }

  // --- 2. KULLANICI ODA BİLGİSİ ---
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
      debugPrint("Hata: $e");
      if (mounted) setState(() => isLoadingUser = false);
    }
  }

  // --- 3. ACİL DURUM BİLDİRİMİ ---
  Future<void> _handleSendAlert(String emergencyType) async {
    String roomToSend = userActualRoomNumber ?? "Bilinmiyor";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$emergencyType bildirimi gönderiliyor...",
          style: const TextStyle(color: Colors.white),
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
              "YARDIM ÇAĞRISI GÖNDERİLDİ! ($emergencyType)",
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
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- YARDIMCI FONKSİYONLAR ---
  String get documentIdToQuery {
    if (selectedLocationKey == 'my_room') {
      return userActualRoomNumber ?? "1";
    } else {
      return selectedLocationKey;
    }
  }

  String getDropdownText(String key) {
    if (key == 'my_room') {
      return "Konum: Odam (${userActualRoomNumber ?? '...'})";
    }
    return "Konum: ${locationOptions[key]}";
  }

  @override
  Widget build(BuildContext context) {
    // Tasarım Renkleri
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
          "Acil Durum",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // ÜST BUTONLAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopButton(
                    Icons.local_fire_department,
                    "Yangın",
                    Colors.redAccent,
                    containerColor,
                    () => _handleSendAlert("Yangın"),
                  ),
                  _buildTopButton(
                    Icons.broken_image_outlined,
                    "Deprem",
                    Colors.redAccent,
                    containerColor,
                    () => _handleSendAlert("Deprem"),
                  ),
                  _buildTopButton(
                    Icons.warning_amber_rounded,
                    "Diğer Acil\nDurumlar",
                    Colors.redAccent,
                    containerColor,
                    () => _handleSendAlert("Diğer Acil Durum"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                        "Oda $documentIdToQuery için veri bulunamadı.",
                        secondaryTextColor,
                      );
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>;

                    // Not: Firebase verileri gelecekte kullanılabilir
                    // ignore: unused_local_variable
                    final _ = LocationModel.fromFirestore(
                      data,
                      documentIdToQuery,
                    );

                    // Kullanıcı Noktası (GPS veya Yedek)
                    final LatLng currentUserPoint =
                        _userLocation ?? _backupLocation;

                    // En yakın çıkış noktası
                    final LatLng targetExitPoint =
                        _nearestExit?.location ??
                        _emergencyExits.first.location;

                    // Mesafe hesaplama
                    final String distanceText = _nearestExitDistance != null
                        ? "${_nearestExitDistance!.toInt()} metre"
                        : "Hesaplanıyor...";

                    return Column(
                      children: [
                        // --- CANLI MİNİ HARİTA ---
                        Expanded(
                          flex: 5,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F26),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // 1. Katman: Harita
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      // Harita açıldığında kullanıcıyı merkez al
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
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      ),
                                      // ROTA ÇİZGİSİ - En yakın çıkışa
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
                                      // TÜM ÇIKIŞ KAPILARI İŞARETLEYİCİLERİ
                                      MarkerLayer(
                                        markers: [
                                          // Kullanıcı (Mavi İnsan)
                                          Marker(
                                            point: currentUserPoint,
                                            width: 50,
                                            height: 50,
                                            child: const Icon(
                                              Icons.person_pin_circle,
                                              color: Colors.blue,
                                              size: 50,
                                            ),
                                          ),
                                          // Tüm acil çıkış kapıları
                                          ..._emergencyExits.map((exit) {
                                            final bool isNearest =
                                                _nearestExit?.id == exit.id;
                                            return Marker(
                                              point: exit.location,
                                              width: isNearest ? 55 : 40,
                                              height: isNearest ? 55 : 40,
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
                                                          const EdgeInsets.symmetric(
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
                                                      child: const Text(
                                                        'EN YAKIN',
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
                                            );
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // 2. Katman: Büyüt Butonu
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
                                                      "En Yakın Çıkış",
                                                  noteInfo:
                                                      _nearestExit?.description,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 10),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.open_in_full,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Büyüt",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
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

                        const SizedBox(height: 20),

                        // --- TALİMATLAR KARTI ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: containerColor,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.directions_run,
                                    color: Colors.redAccent,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _nearestExit?.name ?? "En Yakın Çıkış",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      distanceText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildInstructionItem(
                                Icons.info_outline,
                                _nearestExit?.description ??
                                    "En yakın acil çıkış kapısı hesaplanıyor...",
                                secondaryTextColor,
                                iconBgColor,
                              ),
                              const SizedBox(height: 12),
                              _buildInstructionItem(
                                Icons.warning_amber_rounded,
                                "Kırmızı rotayı takip ederek en yakın çıkışa ilerleyin!",
                                secondaryTextColor,
                                iconBgColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
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
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: textColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
        ),
      ],
    );
  }
}

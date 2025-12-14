
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_page/screens/emergency/fullMapscreen.dart';
import 'package:login_page/service/database_service.dart'; 

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  // Servis sınıfımızı çağırıyoruz
  final DatabaseService _dbService = DatabaseService();

  String? userActualRoomNumber;
  String selectedLocationKey = 'my_room';
  bool isLoadingUser = true;

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
  }

  // Artık sadece servisten veriyi istiyoruz, logic burada değil
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

  // Servis üzerinden bildirim gönderme
  Future<void> _handleSendAlert(String emergencyType) async {
    String roomToSend = userActualRoomNumber ?? "Bilinmiyor";

    // 1. Bilgi mesajı
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$emergencyType bildirimi gönderiliyor...", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      // 2. Servisi kullan
      await _dbService.sendEmergencyAlert(
        emergencyType: emergencyType,
        roomNumber: roomToSend,
        locationContext: selectedLocationKey,
      );

      // 3. Başarılı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("YARDIM ÇAĞRISI GÖNDERİLDİ! ($emergencyType - Oda: $roomToSend)",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    // Renkler
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
        title: const Text("Acil Durum", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
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
                      style: const TextStyle(color: textColor, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedLocationKey = value;
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
                  _buildTopButton(Icons.local_fire_department, "Yangın", Colors.redAccent, containerColor,
                      () => _handleSendAlert("Yangın")),
                  _buildTopButton(Icons.broken_image_outlined, "Deprem", Colors.redAccent, containerColor,
                      () => _handleSendAlert("Deprem")),
                  _buildTopButton(Icons.warning_amber_rounded, "Diğer Acil\nDurumlar", Colors.redAccent, containerColor,
                      () => _handleSendAlert("Diğer Acil Durum")),
                ],
              ),
              const SizedBox(height: 20),

              // STREAM BUILDER (Artık servisten stream alıyor)
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _dbService.getRoomStream(documentIdToQuery), // Servisten çağırdık
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                    }
                    if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                      return _buildErrorState("Oda $documentIdToQuery için veri bulunamadı.", secondaryTextColor);
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    String imageName = data['image_url'] ?? '';
                    print("FİRESTORE'DAN GELEN: $imageName");
                    String distance = data['distance'] ?? 'Bilinmiyor';
                    String instr1 = data['instruction_1'] ?? '';
                    String instr2 = data['instruction_2'] ?? '';

                    return Column(
                      children: [
                        // HARİTA
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
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(0),
                                      child: imageName.isNotEmpty
                                          ? InteractiveViewer(
                                            panEnabled: true,
                                            minScale: 1.0,
                                            maxScale: 5.0,
                                            child: Image.asset('assets/images/$imageName', fit: BoxFit.cover))
                                          : const Center(
                                              child: Text("Görsel Yok", style: TextStyle(color: Colors.white))),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (imageName.isNotEmpty) {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) => FullScreenMapPage(imageName: imageName)));
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 10),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(20)),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.keyboard_arrow_down, color: textColor, size: 16),
                                            SizedBox(width: 4),
                                            Text("Haritayı Büyüt", style: TextStyle(color: textColor, fontSize: 12)),
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
                        // TALİMATLAR
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
                              Text("En Yakın Çıkış: $distance",
                                  style: const TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 16),
                              _buildInstructionItem(Icons.arrow_upward, instr1, secondaryTextColor, iconBgColor),
                              const SizedBox(height: 12),
                              _buildInstructionItem(Icons.turn_right, instr2, secondaryTextColor, iconBgColor),
                              const SizedBox(height: 12),
                              _buildInstructionItem(Icons.door_back_door, "Acil çıkış kapısına ulaşın",
                                  secondaryTextColor, iconBgColor),
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

  // YARDIMCI WIDGETLAR AYNI KALDI
  Widget _buildErrorState(String message, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  Widget _buildTopButton(IconData icon, String label, Color iconColor, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text, Color textColor, Color iconBgColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(8)),
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
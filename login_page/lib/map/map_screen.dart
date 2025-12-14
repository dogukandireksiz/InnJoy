import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Görseldeki gibi temiz beyaz arka plan
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Gölgeyi kaldırdık, düz görünüm
        centerTitle: true,
        title: const Text(
          "Hotel Map",
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          // Resimdeki gibi sol üstte geri butonu
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(); // Bir önceki sayfaya döner
          },
        ),
      ),
      // InteractiveViewer: Kullanıcının haritayı parmaklarıyla büyütüp küçültmesini sağlar
      body: InteractiveViewer(
        panEnabled: true, // Sağa sola kaydırma açık
        minScale: 0.5,    // Minimum küçültme oranı
        maxScale: 4.0,    // Maksimum büyütme oranı (4 kat)
        child: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 5.0,
            child: Image.asset(
              'assets/images/emergency-optimized_floor_plan.png', // Kırpılmış harita görselinin yolu
              fit: BoxFit.contain, // Görseli ekrana sığdırır
            ),
          ),
        ),
      ),
    );
  }
}
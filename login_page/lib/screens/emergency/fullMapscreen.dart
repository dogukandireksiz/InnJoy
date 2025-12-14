import 'package:flutter/material.dart';

class FullScreenMapPage extends StatelessWidget {
  final String imageName;

  const FullScreenMapPage({super.key, required this.imageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Arka plan siyah
      // Kapatma butonu (X) sol üstte
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context), // Sayfayı kapat
        ),
      ),
      // InteractiveViewer: Resmi parmakla büyütüp gezmeyi sağlar
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Sağa sola kaydırma açık
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5, // En fazla ne kadar küçülsün
          maxScale: 4.0, // En fazla ne kadar büyüsün (4 kat)
          child: Image.asset(
            'assets/images/$imageName', // Ana sayfadaki aynı yolu kullanıyoruz
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
               return const Center(child: Text("Resim Yüklenemedi", style: TextStyle(color: Colors.white)));
            },
          ),
        ),
      ),
    );
  }
}
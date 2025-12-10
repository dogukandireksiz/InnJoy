import 'dart:ui';
import 'package:flutter/material.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String titleTr;
  final String contentTr;
  final String titleEn;
  final String contentEn;

  const LegalDocumentScreen({
    Key? key,
    required this.titleTr,
    required this.contentTr,
    required this.titleEn,
    required this.contentEn,
  }) : super(key: key);

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  bool isTurkish = true; // Varsayılan dil Türkçe

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(
          isTurkish ? widget.titleTr : widget.titleEn, 
          style: const TextStyle(
            fontSize: 16, // Uzun başlıklar için biraz küçülttük
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Dil Değiştirme Butonu
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  isTurkish = !isTurkish;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                isTurkish ? "EN" : "TR",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Arkaplan Resmi
          Image.asset(
            "assets/images/arkaplan.png",
            fit: BoxFit.cover,
          ),

          // 2. Blur ve Karartma Efekti
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // 3. İçerik Kartı
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      isTurkish ? widget.contentTr : widget.contentEn,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                    ),
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

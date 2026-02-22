import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String titleTr;
  final String contentTr;
  final String titleEn;
  final String contentEn;

  const LegalDocumentScreen({
    super.key,
    required this.titleTr,
    required this.contentTr,
    required this.titleEn,
    required this.contentEn,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  bool isTurkish = true; // Varsayılan dil TürkÇe

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(
          isTurkish ? widget.titleTr : widget.titleEn, 
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(context, 16), // Uzun başlıklar iÇin biraz küÇülttük
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
          // Dil Değiştirme Butonu
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  isTurkish = !isTurkish;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 12), vertical: ResponsiveUtils.spacing(context, 4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20))),
              ),
              child: Text(
                isTurkish ? "EN" : "TR",
                style: TextStyle(
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
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),

          // 3. İÇerik Kartı
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16.0)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 20)),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24.0)),
                    child: Text(
                      isTurkish ? widget.contentTr : widget.contentEn,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 14),
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











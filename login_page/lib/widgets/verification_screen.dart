// lib/widgets/verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/widgets/auth_wrapper.dart';
import '../utils/custom_snackbar.dart';

class VerificationScreen extends StatefulWidget {
  final User user;
  const VerificationScreen({super.key, required this.user});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // 3 saniyede bir e-posta doğrulama durumunu kontrol eden zamanlayıcıyı başlat.
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    // Ekran kapatılırken veya çıkılırken zamanlayıcıyı durdur.
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // 1. Firebase'den en güncel kullanıcı bilgisini çek (Bu, KRİTİK adımdır!)
    await widget.user.reload();

    // 2. Güncel bilgiyi tekrar al
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // 3. Doğrulama kontrolü yap
    if (refreshedUser != null && refreshedUser.emailVerified) {
      timer?.cancel();
      if(mounted){
         Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const AuthWrapper()));
      }
    }
  }

  // Yeniden doğrulama maili gönderme fonksiyonu
  Future<void> sendVerificationEmail() async {
    try {
      await widget.user.sendEmailVerification();
      if (mounted) {
        CustomSnackBar.show(context, message: 'New verification email sent.', type: SnackBarType.info);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: 'Failed to send email: $e', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, size: 80, color: Colors.blue),
              const SizedBox(height: 30),
              Text(
                'Please check your email (${widget.user.email}) and click on the verification link to activate your account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              // Yeniden gönder butonu
              ElevatedButton(
                onPressed: sendVerificationEmail,
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 10),
              // Oturumu kapatıp çıkış yapma seçeneği
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Şifremi Unuttum Ekranı (ForgotPasswordScreen)
///
/// Kullanıcının kayıtlı e-posta adresini girerek Firebase üzerinden
/// şifre sıfırlama bağlantısı almasını sağlar.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Kullanıcının girdiği e-posta verisini tutan kontrolcü
  final TextEditingController _emailController = TextEditingController();

  /// Firebase kullanarak şifre sıfırlama e-postası gönderir.
  ///
  /// E-posta alanı boşsa uyarı verir. Başarılı olursa dialog gösterir,
  /// hata durumunda SnackBar ile bilgi verir.
  Future<void> passwordReset() async {
    // 1. Validasyon: E-posta alanı boş mu?
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email address.")),
      );
      return;
    }

    try {
      // 2. Firebase isteği
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      // 3. Başarılı işlem bildirimi
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Success"),
              content: const Text(
                "Password reset link sent! Please check your email inbox.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      // 4. Hata yönetimi (Kullanıcı bulunamadı vb.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "An error occurred. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Bellek sızıntısını önlemek için controller serbest bırakılır
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema renkleri (Tasarım sistemine göre sabitler)
    final Color primaryColor = const Color(0xFF38bdf8); // Gökyüzü mavisi
    final Color backgroundColor = const Color(0xFFf3f4f6); // Açık gri zemin
    final Color inputFillColor = const Color(0xFFffffff); // Beyaz input alanı
    final Color textDark = const Color(0xFF111827); // Koyu metin
    final Color textSubtle = const Color(0xFF6b7280); // Silik metin

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Klavye açıldığında taşma olmaması için ScrollView kullanıldı
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ------------------------------------------
                // Header Bölümü: Geri Dön Butonu
                // ------------------------------------------
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: textDark),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // ------------------------------------------
                // Ana Form Bölümü: Başlık, Açıklama, Input
                // ------------------------------------------
                Column(
                  children: [
                    Text(
                      "Forgot Password",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Enter your email to receive a password reset link.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textSubtle,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // E-posta Input Alanı
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "E-mail Address",
                        hintStyle: GoogleFonts.poppins(color: textSubtle),
                        filled: true,
                        fillColor: inputFillColor,
                        prefixIcon: Icon(Icons.mail_outline, color: textSubtle),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Gönder Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: passwordReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Send Reset Link",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100),

                // ------------------------------------------
                // Footer Bölümü: Giriş Yap Linki
                // ------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Remember your password? ",
                      style: GoogleFonts.poppins(
                        color: textSubtle,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Giriş ekranına geri yönlendirme
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.poppins(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

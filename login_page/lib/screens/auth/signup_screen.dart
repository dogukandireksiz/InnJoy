import 'package:flutter/material.dart';
import '../../model/user_model.dart';
import '../../service/auth.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/user_service.dart';

class SignUpScreen extends StatefulWidget {
  // Kullanıcıdan alınacak bilgileri tutan controller'lar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPasswordHidden2 = true;
  bool _isPasswordHidden3 = true;
  UserService userService = UserService(); // Firestore servisi instance
  String? errorMessage;

  // Firebase Authentication ile yeni kullanıcı oluşturma fonksiyonu
  Future<void> createUser() async {
    // Şifrelerin aynı olup olmadığını kontrol eder
    if (widget._passwordController.text !=
        widget._confirmPasswordController.text) {
      setState(() {
        errorMessage = "Passwords don't match.";
      });
      return;
    }
    try {
      // Firebase Auth → Yeni kullanıcı oluşturur (e-mail & şifre)
      final userCred = await Auth().createUser(
        email: widget._emailController.text,
        password: widget._passwordController.text,
      );

      if (userCred == null || userCred.user == null) {
        return;
      }

      await userCred.user!.updateDisplayName(widget._nameController.text);
      await userCred.user!.reload();

      // Firebase Authentication'da oluşan UID ile Firestore'a kullanıcı kaydı yazılır
      UserModel newUser = UserModel(
        uid: userCred.user!.uid, // Firestore belge ID olarak kullanılacak UID
        nameSurname: widget._nameController.text, // Kullanıcı adı-soyadı
        mailAddress: userCred.user!.email, // Firebase'in kayıt ettiği email
        password: widget
            ._passwordController
            .text, // (Tavsiye edilmez) Firestore'a şifre gönderme
      );

      // Firestore → "users" koleksiyonuna kullanıcı kaydı eklenir
      userService.createDbUser(newUser);

      if (mounted) {
        Navigator.of(context).pop(); // Hesap oluşursa geri döner
      }
    } on FirebaseAuthException catch (e) {
      // Firebase Authentication'dan dönen hatayı kullanıcıya gösterir
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/arkaplan.png", fit: BoxFit.cover),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Color.fromRGBO(0, 0, 0, 0.1)),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 150,
                      width: 150,
                      color: Colors.transparent,
                      child: Image.asset("assets/images/arkaplanyok1.png"),
                    ),

                    const Text(
                      "InnJoy",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Create New Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Kullanıcı adı
                    TextField(
                      controller: widget._nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(255, 255, 255, 0.15),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.amber,
                        ),
                        hintText: "Name and Surname",
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // E-mail girişi
                    TextField(
                      controller: widget._emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(255, 255, 255, 0.15),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.amber,
                        ),
                        hintText: "E-mail Address",
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Şifre
                    TextField(
                      controller: widget._passwordController,
                      obscureText: _isPasswordHidden2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(255, 255, 255, 0.15),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.amber,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden2
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordHidden2 = !_isPasswordHidden2;
                            });
                          },
                        ),
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Şifre tekrar
                    TextField(
                      controller: widget._confirmPasswordController,
                      obscureText: _isPasswordHidden3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(255, 255, 255, 0.15),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.amber,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden3
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordHidden3 = !_isPasswordHidden3;
                            });
                          },
                        ),
                        hintText: "Confirm Password",
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Kayıt ol butonu → Firebase.createUser tetikler
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed:
                            createUser, // Firebase + Firestore işlemini çalıştırır
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account ?",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Giriş ekranına döner
                          },
                          child: const Text(
                            "Sign In Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

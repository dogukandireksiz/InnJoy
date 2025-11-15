import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart'; // HomeScreen için eklendi

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isPasswordHidden2 = true;

  bool _isPasswordHidden3 = true;

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _signUp() {
    final String password = _passwordController.text;

    final String confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreler eşleşmiyor. Lütfen tekrar deneyin.'),

            backgroundColor: Colors.red,
          ),
        );
      }

      return;
    }

    // Kayıt başarılı olduğunda kullanılacak kullanıcı adı alınır
    final String userName = _nameController.text.trim();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt başarılı! Hoşgeldin $userName.'),
          backgroundColor: Colors.green,
        ),
      );

      // İstenen İyileştirme: Başarılı kayıttan sonra doğrudan HomeScreen'e yönlendirildi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userName: userName)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    super.dispose();
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

            // ❌ Hatalı Satır: Flutter'da withValues metodu yoktur.
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
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

                    TextField(
                      controller: _nameController,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        filled: true,

                        // ❌ Hatalı Satır: Flutter'da withValues metodu yoktur.
                        fillColor: Colors.white.withValues(alpha: 0.15),

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

                    //Email Text Field
                    TextField(
                      controller: _emailController,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        filled: true,

                        // ❌ Hatalı Satır: Flutter'da withValues metodu yoktur.
                        fillColor: Colors.white.withValues(alpha: 0.15),

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

                    //Password
                    TextField(
                      controller: _passwordController,

                      obscureText: _isPasswordHidden2,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        filled: true,

                        // ❌ Hatalı Satır: Flutter'da withValues metodu yoktur.
                        fillColor: Colors.white.withValues(alpha: 0.15),

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

                    // Password kontrol
                    TextField(
                      controller: _confirmPasswordController,

                      obscureText: _isPasswordHidden3,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(
                        filled: true,

                        // ❌ Hatalı Satır: Flutter'da withValues metodu yoktur.
                        fillColor: Colors.white.withValues(alpha: 0.15),

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

                    //Sign in button
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

                        onPressed: _signUp,

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

                    SizedBox(height: 10),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Text(
                          "Already have an account ?",

                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
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

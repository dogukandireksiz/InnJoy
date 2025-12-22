import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'signup_screen.dart';
import '../../services/auth.dart';
import 'forget_password.dart';
import '../../utils/dialogs/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool isLogin = true;

  String? errorMessage;

  Future<void> createUser() async {
    try {
      await Auth().createUser(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
        if (e.message != null) {
          CustomSnackBar.show(context, message: e.message!);
        }
      });
    }
  }

  Future<void> signIn() async {
    try {
      await Auth().signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // 2. Self-Healing: Check if Firestore doc exists, if not create it
      // This is handled inside Auth().signIn() already, but we can double check or just rely on it.
      // Auth class signIn method already has the logic to create the user doc if missing.
    } on FirebaseAuthException catch (e) {
      setState(() {
        String msg = "An error occurred during login.";
        if (e.code == 'user-not-found') {
          msg = "No account found with this email.";
        } else if (e.code == 'wrong-password') {
          msg = "Incorrect email or password.";
        } else if (e.code == 'invalid-email') {
          msg = "The email address is invalid.";
        } else if (e.code == 'invalid-credential') {
          msg = "Incorrect email or password.";
        }

        errorMessage = msg;

        CustomSnackBar.show(context, message: msg);
      });
    } catch (e) {
      setState(() {
        errorMessage = "Login Error: $e";
        CustomSnackBar.show(context, message: "Login error: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arkaplan Resmi
          Image.asset("assets/images/arkaplan.png", fit: BoxFit.cover),

          // Blur Efekti
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      // child: Image.asset("assets/images/arkaplanyok1.png"),
                      child: Image.asset(
                        "assets/images/kalitelilogoarkaplanyok.png",
                      ),
                    ),

                    const Text(
                      "InnJoy",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    const Text(
                      "Your seamless hotel experience",
                      style: TextStyle(color: Colors.white60, fontSize: 18),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Welcome!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- E-mail Input ---
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
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

                    // --- Password Input ---
                    TextField(
                      controller: _passwordController,
                      obscureText: _isPasswordHidden,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.amber,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordHidden = !_isPasswordHidden;
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

                    const SizedBox(height: 10),

                    // --- Sign In Button ---
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
                        onPressed: () {
                          if (isLogin) {
                            signIn();
                          } else {
                            createUser();
                          }
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // --- Forgot Password Link ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          // Yönlendirme Kodu:
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Dosya adı 'forget_password.dart' olsa bile
                              // iÇindeki class adı 'ForgotPasswordScreen' olduğu iÇin bunu Çağırıyoruz.
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password ?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Divider ---
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Colors.white,
                            thickness: 3,
                            endIndent: 10,
                          ),
                        ),
                        const Text(
                          "Or Sign In With",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: Colors.white,
                            thickness: 3,
                            indent: 10,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // --- Social Media Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Google
                        SizedBox(
                          width: 90,
                          height: 30,
                          child: IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.google,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () async {
                              final authservice = Auth();
                              await authservice.signInWithGoogle();
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Twitter
                        SizedBox(
                          width: 90,
                          height: 30,
                          child: IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.xTwitter,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () async {
                              final authService2 = Auth();
                              await authService2.signInWithTwitter();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Facebook
                        SizedBox(
                          width: 90,
                          height: 30,
                          child: IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.facebook,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () async {
                              final authService3 = Auth();
                              await authService3.signInWithFacebook();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Sign Up Link ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account ?",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
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

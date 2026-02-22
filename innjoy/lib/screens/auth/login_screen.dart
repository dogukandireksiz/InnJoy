import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'signup_screen.dart';
import '../../services/auth.dart';
import 'forget_password.dart';
import '../../utils/dialogs/custom_snackbar.dart';
import '../../utils/responsive_utils.dart';

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
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: ResponsiveUtils.hp(context, 0.18),
                      width: ResponsiveUtils.hp(context, 0.18),
                      // child: Image.asset("assets/images/arkaplanyok1.png"),
                      child: Image.asset(
                        "assets/images/kalitelilogoarkaplanyok.png",
                      ),
                    ),

                    Text(
                      "InnJoy",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.sp(context, 35),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    Text(
                      "Your seamless hotel experience",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: ResponsiveUtils.sp(context, 18),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                    Text(
                      "Welcome!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.sp(context, 50),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // --- E-mail Input ---
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.white),
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
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.borderRadiusLarge(context) * 1.5,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

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
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.borderRadiusLarge(context) * 1.5,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 10)),

                    // --- Sign In Button ---
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.buttonHeight(context),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.borderRadiusLarge(context) * 1.5,
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (isLogin) {
                            signIn();
                          } else {
                            createUser();
                          }
                        },
                        child: Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 25),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 5)),

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
                                  ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Forgot Password ?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sp(context, 17),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // --- Divider ---
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white,
                            thickness: 3,
                            endIndent: 10,
                          ),
                        ),
                        Text(
                          "Or Sign In With",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sp(context, 20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white,
                            thickness: 3,
                            indent: 10,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 10)),

                    // --- Social Media Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Google
                        Expanded(
                          child: SizedBox(
                            height: ResponsiveUtils.spacing(context, 30),
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.google,
                                color: Colors.white,
                                size: ResponsiveUtils.iconSize(context) * 1.2,
                              ),
                              onPressed: () async {
                                final authservice = Auth();
                                await authservice.signInWithGoogle();
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                        // Twitter
                        Expanded(
                          child: SizedBox(
                            height: ResponsiveUtils.spacing(context, 30),
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.xTwitter,
                                color: Colors.white,
                                size: ResponsiveUtils.iconSize(context) * 1.2,
                              ),
                              onPressed: () async {
                                final authService2 = Auth();
                                await authService2.signInWithTwitter();
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                        // Facebook
                        Expanded(
                          child: SizedBox(
                            height: ResponsiveUtils.spacing(context, 30),
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.facebook,
                                color: Colors.white,
                                size: ResponsiveUtils.iconSize(context) * 1.2,
                              ),
                              onPressed: () async {
                                final authService3 = Auth();
                                await authService3.signInWithFacebook();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // --- Sign Up Link ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Don't have an account ?",
                            style: TextStyle(
                              fontSize: ResponsiveUtils.sp(context, 16),
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign Up Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sp(context, 14),
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


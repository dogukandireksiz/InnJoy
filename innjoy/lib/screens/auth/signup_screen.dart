import 'package:flutter/material.dart';
import 'package:login_page/services/logger_service.dart';
import '../../models/user_model.dart';
import '../../services/auth.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../utils/dialogs/custom_snackbar.dart';
import '../legal/legal_constants.dart';
import '../legal/legal_document_screen.dart';
import 'package:flutter/gestures.dart';
import '../../utils/responsive_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers - State sınıfında tanımlanmalı (memory leak önleme)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordHidden2 = true;
  bool _isPasswordHidden3 = true;
  UserService userService = UserService(); // Firestore servisi instance
  String? errorMessage;
  
  bool _isMandatoryAccepted = false;
  bool _isOptionalAccepted = false;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    // Controller'ları temizle - memory leak önleme
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Şifre güçlülük kontrolü
  void _validatePassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  // Şifrenin tüm kriterleri karşılayıp karşılamadığını kontrol eder
  bool _isPasswordValid() {
    return _hasMinLength && _hasUppercase && _hasLowercase && _hasDigit && _hasSpecialChar;
  }

  // Firebase Authentication ile yeni kullanıcı oluşturma fonksiyonu
  Future<void> createUser() async{
    // Onay kontrolü
    if (!_isMandatoryAccepted) {
      setState(() {
         errorMessage = "Please accept the User Agreement and Privacy Policy.";
      });
      CustomSnackBar.show(context, message: "Please accept the User Agreement and Privacy Policy.");
      return;
    }

    // Şifre güvenlik kriterlerini kontrol et
    if (!_isPasswordValid()) {
      setState(() {
        errorMessage = "Password does not meet security requirements.";
      });
      CustomSnackBar.show(context, message: "Please ensure your password meets all security requirements.");
      return;
    }

    // şifrelerin aynı olup olmadığını kontrol eder
    if(_passwordController.text != _confirmPasswordController.text){
      setState(() {
        errorMessage = "Passwords don't match.";
      });
      return;
    }
    try {
      // Firebase Auth -> Yeni kullanıcı oluşturur (e-mail & şifre)
      final userCred = await Auth().createUser(
        email: _emailController.text, 
        password: _passwordController.text
      );

      if(userCred == null || userCred.user == null){
        return;
      }

      await userCred.user!.updateDisplayName(_nameController.text);
      await userCred.user!.reload();

      // Firebase Authentication'da oluşan UID ile Firestore'a kullanıcı kaydı yazılır
      UserModel newUser = UserModel(
        uid: userCred.user!.uid,                        // Firestore belge ID olarak kullanılacak UID
        nameSurname: _nameController.text,              // Kullanıcı adı-soyadı
        email: userCred.user!.email,                    // Firebase'in kayıt ettiği email (auth.dart ile tutarlı)
        password: _passwordController.text              // (Tavsiye edilmez) Firestore'a şifre gönderme
      );

      // Firestore -> "users" koleksiyonuna kullanıcı kaydı eklenir
      await userService.createDbUser(newUser);

      if(mounted){
        Navigator.of(context).pop(); // Hesap oluşursa geri döner
      }
    } on FirebaseAuthException catch(e){
      // Firebase Authentication'dan dönen hatayı kullanıcıya gösterir
      setState(() {
        errorMessage = e.message;
      });
      if (mounted) {
        CustomSnackBar.show(context, message: e.message ?? "Authentication Error");
      }
    } catch (e) {
      // Diğer hatalar (Firestore vb.)
      setState(() {
        errorMessage = "An error occurred: $e";
      });
      Logger.debug("SignUp Error: $e");
      if (mounted) {
        CustomSnackBar.show(context, message: "Error creating account: $e");
      }
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
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 32)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: ResponsiveUtils.hp(context, 150 / 844),
                      width: ResponsiveUtils.wp(context, 150 / 375),
                      color: Colors.transparent,
                      child: Image.asset("assets/images/arkaplanyok1.png"),
                    ),

                    Text(
                      "InnJoy",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.sp(context, 40),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 10)),

                    Text(
                      "Create New Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.sp(context, 25),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // Kullanıcı adı
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        prefixIcon: const Icon(Icons.person, color: Colors.amber),
                        hintText: "Name and Surname",
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 30)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // E-mail girişi
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.amber),
                        hintText: "E-mail Address",
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 30)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // şifre
                    TextField(
                      controller: _passwordController,
                      obscureText: _isPasswordHidden2,
                      onChanged: _validatePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.amber),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden2 ? Icons.visibility : Icons.visibility_off,
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
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 30)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    // Password strength indicators
                    if (_passwordController.text.isNotEmpty) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 15)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: ResponsiveUtils.wp(context, 1 / 375),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password Requirements:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveUtils.sp(context, 13),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            _buildPasswordCriterion(
                              "At least 8 characters",
                              _hasMinLength,
                            ),
                            _buildPasswordCriterion(
                              "One uppercase letter (A-Z)",
                              _hasUppercase,
                            ),
                            _buildPasswordCriterion(
                              "One lowercase letter (a-z)",
                              _hasLowercase,
                            ),
                            _buildPasswordCriterion(
                              "One number (0-9)",
                              _hasDigit,
                            ),
                            _buildPasswordCriterion(
                              "One special character (!@#\$%^&*)",
                              _hasSpecialChar,
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // şifre tekrar
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _isPasswordHidden3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.amber),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden3 ? Icons.visibility : Icons.visibility_off,
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
                          borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 30)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 10)),

                    // --- Legal Consents ---
                    // 1. Mandatory Checkbox (User Agreement + Privacy Policy)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: ResponsiveUtils.wp(context, 24 / 375),
                          height: ResponsiveUtils.hp(context, 24 / 844),
                          child: Checkbox(
                          value: _isMandatoryAccepted,
                          activeColor: Colors.lightBlueAccent,
                          side: const BorderSide(color: Colors.white, width: 2),
                          onChanged: (val) {
                            setState(() {
                              _isMandatoryAccepted = val ?? false;
                            });
                          },
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: "InnJoy ",
                              style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.sp(context, 13)),
                              children: [
                                TextSpan(
                                  text: "User Agreement",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LegalDocumentScreen(
                                            titleTr: LegalConstants.userAgreementTitle,
                                            contentTr: LegalConstants.userAgreementText,
                                            titleEn: LegalConstants.userAgreementTitleEn,
                                            contentEn: LegalConstants.userAgreementTextEn,
                                          ),
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LegalDocumentScreen(
                                            titleTr: LegalConstants.privacyPolicyTitle,
                                            contentTr: LegalConstants.privacyPolicyText,
                                            titleEn: LegalConstants.privacyPolicyTitleEn,
                                            contentEn: LegalConstants.privacyPolicyTextEn,
                                          ),
                                        ),
                                      );
                                    },
                                ),
                                TextSpan(text: ", I have read and accept."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 15)),

                    // 2. Optional Checkbox (Open Consent / Marketing)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: ResponsiveUtils.wp(context, 24 / 375),
                          height: ResponsiveUtils.hp(context, 24 / 844),
                          child: Checkbox(
                          value: _isOptionalAccepted,
                          activeColor: Colors.lightBlueAccent,
                          side: const BorderSide(color: Colors.white, width: 2),
                          onChanged: (val) {
                            setState(() {
                              _isOptionalAccepted = val ?? false;
                            });
                          },
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: "I consent to the processing of my marketing notifications, location and usage data for personalization purposes ",
                              style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.sp(context, 13)),
                              children: [
                                TextSpan(
                                  text: "(explicit consent)",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LegalDocumentScreen(
                                            titleTr: LegalConstants.openConsentTitle,
                                            contentTr: LegalConstants.openConsentText,
                                            titleEn: LegalConstants.openConsentTitleEn,
                                            contentEn: LegalConstants.openConsentTextEn,
                                          ),
                                        ),
                                      );
                                    },
                                ),
                                TextSpan(text: "."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 10)),

                    // KVKK Link
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 34.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LegalDocumentScreen(
                                  titleTr: LegalConstants.kvkkTitle,
                                  contentTr: LegalConstants.kvkkText,
                                  titleEn: LegalConstants.kvkkTitleEn,
                                  contentEn: LegalConstants.kvkkTextEn,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "KVKK Information Notice",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: ResponsiveUtils.sp(context, 13),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 20)),

                    // Kayıt ol butonu -> Firebase.createUser tetikler
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.hp(context, 50 / 844),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 30)),
                          ),
                        ),
                        onPressed: createUser, // Firebase + Firestore işlemini Çalıştırır
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 25),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 15)),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Already have an account ? ",
                          style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), color: Colors.white),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Giriş ekranına döner
                          },
                          child: Text(
                            "Sign In Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sp(context, 16),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 30)),
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to show password criterion with check/x mark
  Widget _buildPasswordCriterion(String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? Colors.lightGreenAccent : Colors.redAccent,
            size: ResponsiveUtils.iconSize(context) * (16 / 24),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.white : Colors.white60,
                fontSize: ResponsiveUtils.sp(context, 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}












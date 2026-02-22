import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth.dart';
import '../../utils/dialogs/custom_snackbar.dart';
import '../../utils/responsive_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  
  // Visibility Toggles
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
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

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    // Şifre güvenlik kriterlerini kontrol et
    if (!_isPasswordValid()) {
      CustomSnackBar.show(context, message: "Please ensure your new password meets all security requirements.");
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      await Auth().reauthenticateAndUpdatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        CustomSnackBar.show(context, message: 'Password changed successfully.', title: 'Success', isError: false);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred.';
        if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect current password.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak.';
        } else if (e.code == 'requires-recent-login') {
             errorMessage = 'For security reasons, please log in again.';
        }
        
        CustomSnackBar.show(context, message: errorMessage);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, message: 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF137fec)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.sp(context, 20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              // Current Password
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                hint: 'Enter current password',
                obscureText: _obscureCurrent,
                onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current password';
                  }
                  return null;
                },
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              
              // New Password
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Enter new password',
                obscureText: _obscureNew,
                onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                onChanged: _validatePassword,
              ),

              // Password strength indicators
              if (_newPasswordController.text.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: ResponsiveUtils.wp(context, 1 / 375),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Password Requirements:",
                        style: TextStyle(
                          color: Colors.grey[700],
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

              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                hint: 'Re-enter new password',
                obscureText: _obscureConfirm,
                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 48)),

              // Save Button
              SizedBox(
                height: ResponsiveUtils.hp(context, 56 / 844),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137fec),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? SizedBox(height: ResponsiveUtils.hp(context, 24 / 844), width: ResponsiveUtils.wp(context, 24 / 375), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Save Changes',
                        style: TextStyle(fontSize: ResponsiveUtils.sp(context, 18), fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(context, 14),
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey[400],
              ),
              onPressed: onToggleVisibility,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 16),
              horizontal: ResponsiveUtils.spacing(context, 16),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 12)),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
          ),
        ),
      ],
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
            color: isMet ? Colors.green : Colors.red,
            size: ResponsiveUtils.iconSize(context) * (16 / 24),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.grey[800] : Colors.grey[600],
              fontSize: ResponsiveUtils.sp(context, 12),
            ),
          ),
        ],
      ),
    );
  }
}










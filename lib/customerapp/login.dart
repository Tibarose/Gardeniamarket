import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Mobile number validation: Matches RegisterPage (starts with 010/011/012/015, 11 digits)
  bool _isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^(010|011|012|015)\d{8}$');
    return mobileRegex.hasMatch(mobile);
  }

  // Login method
  Future<void> _login(BuildContext context) async {
    final mobile = mobileController.text.trim();
    final password = passwordController.text.trim();

    // Validate inputs
    if (mobile.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى إدخال رقم الهاتف وكلمة المرور');
      return;
    }

    if (!_isValidMobile(mobile)) {
      _showSnackBar('رقم الهاتف يجب أن يبدأ بـ 010, 011, 012, أو 015 ويكون 11 رقمًا');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        mobileNumber: mobile,
        password: password,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل الدخول بنجاح!',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        Navigator.pushReplacementNamed(context, '/market');
      }
    } catch (e) {
      _showSnackBar('خطأ في تسجيل الدخول: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show SnackBar (matches RegisterPage styling)
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Input decoration (matches RegisterPage)
  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 16),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppConstants.awesomeColor, width: 2),
      ),
      errorStyle: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 12),
      prefixIcon: Icon(icon, color: AppConstants.awesomeColor),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress bar (matches RegisterPage step 1)
                Container(
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.awesomeColor.withOpacity(0.2),
                        AppConstants.awesomeColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.25, // 25% to match first step
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [AppConstants.gradientStart, AppConstants.gradientEnd],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade50],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              offset: const Offset(-4, -4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'جاردينيا ماركت',
                              style: GoogleFonts.cairo(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.awesomeColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Icon(Icons.login, size: 60, color: AppConstants.awesomeColor),
                            const SizedBox(height: 16),
                            Text(
                              'تسجيل الدخول',
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل بياناتك للوصول إلى حسابك',
                              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: mobileController,
                              decoration: _buildInputDecoration('رقم الهاتف (مثال: 01012345678)', Icons.phone),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.cairo(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: passwordController,
                              decoration: _buildInputDecoration(
                                'كلمة المرور',
                                Icons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              style: GoogleFonts.cairo(fontSize: 16),
                              onFieldSubmitted: (_) => _login(context),
                            ),
                            const SizedBox(height: 32),
                            _isLoading
                                ? CircularProgressIndicator(color: AppConstants.awesomeColor)
                                : GestureDetector(
                              onTapDown: (_) => setState(() {}),
                              child: AnimatedScale(
                                scale: 1.0,
                                duration: const Duration(milliseconds: 100),
                                child: ElevatedButton(
                                  onPressed: () => _login(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppConstants.gradientStart, AppConstants.gradientEnd],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppConstants.awesomeColor.withOpacity(0.4),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                                    child: Text(
                                      'تسجيل الدخول',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              child: Text(
                                'ليس لديك حساب؟ سجل الآن',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: AppConstants.awesomeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
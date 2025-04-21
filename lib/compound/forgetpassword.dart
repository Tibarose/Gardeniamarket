import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../customerapp/auth_provider.dart';
import '../customerapp/hypersender_utils.dart';
import 'homescreen/thememanager.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  // Validation method for mobile number
  bool _isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^(010|011|012|015)\d{8}$');
    return mobileRegex.hasMatch(mobile);
  }

  // Generate OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Show SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    final theme = ThemeManager().currentTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? Colors.red : theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Proceed to OTP verification
  Future<void> _proceedToOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);
    try {
      final mobile = mobileController.text.trim();
      final formattedMobile = '+2$mobile';

      // Check if user exists
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('mobile_number', mobile)
          .maybeSingle();

      if (existingUser == null) {
        _showSnackBar('رقم الهاتف غير مسجل. يرجى التسجيل أولاً.', isError: true);
        return;
      }

      final generatedOtp = _generateOtp();
      await WhatsAppUtils.sendOtpViaWhatsApp(formattedMobile, generatedOtp);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordOtpVerificationPage(
            mobile: mobile,
            generatedOtp: generatedOtp,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('خطأ في إرسال كود التحقق: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Input decoration with Font Awesome icons
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final theme = ThemeManager().currentTheme;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(
        color: theme.secondaryTextColor,
        fontSize: 16,
      ),
      filled: true,
      fillColor: theme.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.secondaryTextColor.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorStyle: GoogleFonts.cairo(
        color: Colors.redAccent,
        fontSize: 12,
      ),
      prefixIcon: FaIcon(
        icon,
        color: theme.primaryColor,
        size: 18,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  FaIcon(
                    FontAwesomeIcons.phone,
                    size: isMobile ? 50 : 60,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نسيت كلمة المرور',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 20 : 22,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أدخل رقم هاتفك المسجل على واتساب لإعادة تعيين كلمة المرور',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14 : 16,
                      color: theme.secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: mobileController,
                          decoration: _buildInputDecoration('رقم الهاتف (مثال: 01012345678)', FontAwesomeIcons.phone),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'رقم الهاتف مطلوب';
                            if (!_isValidMobile(value)) return 'رقم الهاتف يجب أن يبدأ بـ 010, 011, 012, أو 015 ويكون 11 رقمًا';
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: theme.textColor,
                          ),
                          onFieldSubmitted: (_) => _proceedToOtp(),
                        ),
                        const SizedBox(height: 24),
                        isLoading
                            ? CircularProgressIndicator(color: theme.primaryColor)
                            : ElevatedButton(
                          onPressed: _proceedToOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: theme.appBarGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                            child: Text(
                              'إرسال كود التحقق',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/home'),
                          child: Text(
                            'العودة إلى تسجيل الدخول',
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 14 : 16,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordOtpVerificationPage extends StatefulWidget {
  final String mobile;
  final String generatedOtp;

  const ResetPasswordOtpVerificationPage({
    super.key,
    required this.mobile,
    required this.generatedOtp,
  });

  @override
  _ResetPasswordOtpVerificationPageState createState() => _ResetPasswordOtpVerificationPageState();
}

class _ResetPasswordOtpVerificationPageState extends State<ResetPasswordOtpVerificationPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _isLocked = false;
  int _otpAttempts = 0;
  bool _resendCooldown = false;
  int _countdownSeconds = 30;
  Timer? _countdownTimer;
  late String _generatedOtp;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  bool _hasError = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpVerified = false; // Tracks if OTP is verified
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _generatedOtp = widget.generatedOtp;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Generate new OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    setState(() {
      isLoading = true;
      _resendCooldown = true;
      _countdownSeconds = 30;
      _otpAttempts = 0;
      _isLocked = false;
      _hasError = false;
      for (var controller in _otpControllers) {
        controller.clear();
      }
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _resendCooldown = false;
          timer.cancel();
        }
      });
    });

    try {
      final formattedMobile = '+2${widget.mobile}';
      _generatedOtp = _generateOtp();
      await WhatsAppUtils.sendOtpViaWhatsApp(formattedMobile, _generatedOtp);

      if (context.mounted) {
        final theme = ThemeManager().currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال كود تحقق جديد!',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            backgroundColor: theme.accentColor ?? Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('خطأ في إعادة إرسال الكود: $e', isError: true);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Show SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    final theme = ThemeManager().currentTheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? Colors.red : theme.accentColor ?? Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Save credentials to SharedPreferences
  Future<void> _saveCredentials(String mobile, String hashedPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mobile', mobile);
    await prefs.setString('user_password', hashedPassword);
  }

  // Verify OTP
  Future<void> _verifyOtp() async {
    if (!_isOtpComplete() || _isLocked) {
      setState(() => _hasError = true);
      _animationController.forward().then((_) => _animationController.reverse());
      _showSnackBar('يرجى إدخال كود تحقق مكون من 6 أرقام', isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final enteredOtp = _otpControllers.map((controller) => controller.text).join();

      if (enteredOtp != _generatedOtp) {
        setState(() {
          _otpAttempts++;
          _hasError = true;
        });
        _animationController.forward().then((_) => _animationController.reverse());
        if (_otpAttempts >= 3) {
          setState(() => _isLocked = true);
          _showSnackBar('لقد وصلت إلى الحد الأقصى للمحاولات. يرجى طلب كود جديد.', isError: true);
        } else {
          _showSnackBar('كود التحقق غير صحيح. تبقى ${3 - _otpAttempts} محاولات.', isError: true);
        }
        return;
      }

      setState(() {
        _otpAttempts = 0;
        _hasError = false;
        _otpVerified = true; // OTP verified, show password fields
      });

      _showSnackBar('تم التحقق من الكود بنجاح!');
    } catch (e) {
      setState(() => _hasError = true);
      _animationController.forward().then((_) => _animationController.reverse());
      _showSnackBar(
        e.toString().contains('Network') ? 'تحقق من الاتصال بالإنترنت' : 'خطأ في التحقق: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Reset password after OTP verification
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('يرجى إدخال كلمة مرور صالحة وتأكيدها', isError: true);
      return;
    }

    setState(() => isLoading = true);
    try {
      final password = _passwordController.text.trim();
      final hashedPassword = _hashPassword(password);

      // Update password in Supabase
      await supabase
          .from('users')
          .update({'password': hashedPassword})
          .eq('mobile_number', widget.mobile);

      // Save updated credentials to SharedPreferences
      await _saveCredentials(widget.mobile, hashedPassword);

      // Sign in the user using AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        mobileNumber: widget.mobile,
        password: password,
      );

      if (context.mounted) {
        _showSnackBar('تم إعادة تعيين كلمة المرور بنجاح!');
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PasswordResetSuccessPage()),
        );
      }
    } catch (e) {
      _showSnackBar(
        e.toString().contains('Network') ? 'تحقق من الاتصال بالإنترنت' : 'خطأ في إعادة تعيين كلمة المرور: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Input decoration for OTP boxes
  InputDecoration _buildBoxDecoration(bool isFocused) {
    final theme = ThemeManager().currentTheme;
    return InputDecoration(
      filled: true,
      fillColor: isFocused
          ? theme.cardBackground
          : _hasError
          ? theme.primaryColor.withOpacity(0.1)
          : theme.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _hasError ? theme.primaryColor : theme.secondaryTextColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.primaryColor,
          width: 2.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.secondaryTextColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.primaryColor,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      isDense: true,
    );
  }

  // Input decoration for password fields
  InputDecoration _buildPasswordDecoration(String label, {required bool obscureText, required VoidCallback onToggle}) {
    final theme = ThemeManager().currentTheme;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(
        color: theme.secondaryTextColor,
        fontSize: 16,
      ),
      filled: true,
      fillColor: theme.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.secondaryTextColor.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorStyle: GoogleFonts.cairo(
        color: Colors.redAccent,
        fontSize: 12,
      ),
      prefixIcon: FaIcon(
        FontAwesomeIcons.lock,
        color: theme.primaryColor,
        size: 18,
      ),
      suffixIcon: IconButton(
        icon: FaIcon(
          obscureText ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
          color: theme.secondaryTextColor,
          size: 18,
        ),
        onPressed: onToggle,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      isDense: true,
    );
  }

  // Check if all OTP fields are filled
  bool _isOtpComplete() {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  // Build step content with conditional UI
  Widget _buildStepContent() {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            _otpVerified ? FontAwesomeIcons.lock : FontAwesomeIcons.checkCircle,
            size: isMobile ? 50 : 60,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            _otpVerified ? 'إعادة تعيين كلمة المرور' : 'تحقق من رقم الهاتف',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 20 : 22,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor, width: 1),
            ),
            child: Text(
              _otpVerified
                  ? 'أدخل كلمة المرور الجديدة وتأكيدها'
                  : 'تحقق من واتساب على الرقم: ${widget.mobile}\nلم يصل الكود؟ اضغط "إعادة إرسال"',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14 : 16,
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          if (!_otpVerified) ...[
            // OTP Boxes
            Directionality(
              textDirection: TextDirection.ltr,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return Semantics(
                          label: 'OTP digit ${index + 1}',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            transform: Matrix4.identity()
                              ..scale(_focusNodes[index].hasFocus ? 1.05 : 1.0),
                            width: isMobile ? 45 : 50,
                            height: isMobile ? 45 : 50,
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              decoration: _buildBoxDecoration(_focusNodes[index].hasFocus),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              enabled: !_isLocked,
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 20 : 22,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                if (!RegExp(r'^\d$').hasMatch(value)) {
                                  return '';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                setState(() => _hasError = false);
                                if (value.isNotEmpty && index < 5) {
                                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                                }
                                if (value.isEmpty && index > 0) {
                                  FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                                }
                              },
                              textInputAction: index == 5 ? TextInputAction.next : TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              buildCounter: (context,
                                  {required currentLength, required isFocused, maxLength}) => null,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_otpVerified) ...[
            // Password Fields
            AnimatedOpacity(
              opacity: _otpVerified ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    decoration: _buildPasswordDecoration(
                      'كلمة المرور الجديدة',
                      obscureText: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'كلمة المرور مطلوبة';
                      if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: _buildPasswordDecoration(
                      'تأكيد كلمة المرور',
                      obscureText: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'تأكيد كلمة المرور مطلوب';
                      if (value != _passwordController.text.trim()) return 'كلمة المرور غير متطابقة';
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.textColor,
                    ),
                    onFieldSubmitted: (_) => _resetPassword(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Resend OTP Button (only shown if OTP not verified)
          if (!_otpVerified)
            _resendCooldown
                ? Text(
              'إعادة الإرسال متاح بعد $_countdownSeconds ثانية',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14 : 16,
                color: theme.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            )
                : ElevatedButton(
              onPressed: isLoading ? null : _resendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: theme.appBarGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  'إعادة إرسال الكود',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'رجوع',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 16,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              isLoading
                  ? CircularProgressIndicator(color: theme.primaryColor)
                  : ElevatedButton(
                onPressed: _otpVerified
                    ? _resetPassword
                    : (_isLocked || !_isOtpComplete() ? null : _verifyOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: theme.appBarGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  child: Text(
                    _otpVerified ? 'تأكيد كلمة المرور' : 'تأكيد الكود',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Progress bar (50% for OTP, 100% for password)
                  Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: theme.primaryColor.withOpacity(0.2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _otpVerified ? 1.0 : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: theme.appBarGradient,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 400),
                      child: SingleChildScrollView(
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordResetSuccessPage extends StatelessWidget {
  const PasswordResetSuccessPage({super.key});

  // Show confirmation dialog for closing the app
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'إغلاق التطبيق',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد إغلاق التطبيق؟',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14 : 16,
            color: theme.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14 : 16,
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: theme.appBarGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                'إغلاق',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: () => _showExitConfirmationDialog(context),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: theme.backgroundColor,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.checkCircle,
                      size: isMobile ? 80 : 100,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'تم إعادة تعيين كلمة المرور بنجاح!',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لقد تم تحديث كلمة المرور الخاصة بك. يمكنك الآن استخدام التطبيق بأمان.',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16 : 18,
                        color: theme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to main app screen
                        Navigator.pushReplacementNamed(context, '/GardeniaTodayApp');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: theme.appBarGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                        child: Text(
                          'المتابعة إلى التطبيق',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
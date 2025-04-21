import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'package:gardeniamarket/otp.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../compound/homescreen/thememanager.dart';
import 'hypersender_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController buildingNumberController = TextEditingController();
  final TextEditingController apartmentNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;
  String? _selectedCompoundId;
  List<Map<String, dynamic>> compounds = [];
  String? _generatedOtp;
  int _currentStep = 0; // 0: Mobile, 1: Password, 2: Name, 3: Address
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCompounds();
  }

  @override
  void dispose() {
    mobileController.dispose();
    nameController.dispose();
    passwordController.dispose();
    buildingNumberController.dispose();
    apartmentNumberController.dispose();
    super.dispose();
  }

  // Validation methods
  bool _isValidMobile(String mobile) {
    final mobileRegex = RegExp(r'^(010|011|012|015)\d{8}$');
    return mobileRegex.hasMatch(mobile);
  }

  bool _isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$');
    return nameRegex.hasMatch(name);
  }

  // OTP generation
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Fetch compounds
  Future<void> _fetchCompounds() async {
    try {
      final response = await supabase.from('compounds').select('id, name, delivery_fee');
      setState(() {
        compounds = (response as List).map((compound) => Map<String, dynamic>.from(compound)).toList();
        _selectedCompoundId = compounds.isNotEmpty ? compounds[0]['id'].toString() : null;
      });
    } catch (e) {
      _showSnackBar('خطأ في جلب الكمبوندات: ${e.toString()}');
    }
  }

  // Proceed to OTP
  Future<void> _proceedToOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);
    try {
      final mobile = mobileController.text.trim();
      print('Raw mobile input: $mobile');
      final formattedMobile = '+2$mobile';
      print('Formatted mobile: $formattedMobile');

      _generatedOtp = _generateOtp();
      print('Generated OTP: $_generatedOtp');
      await WhatsAppUtils.sendOtpViaWhatsApp(formattedMobile, _generatedOtp!);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(
            mobile: mobile,
            password: passwordController.text.trim(),
            name: nameController.text.trim(),
            buildingNumber: buildingNumberController.text.trim(),
            apartmentNumber: apartmentNumberController.text.trim(),
            compoundId: _selectedCompoundId!,
            generatedOtp: _generatedOtp!,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('خطأ في إرسال كود التحقق: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Show SnackBar
  void _showSnackBar(String message) {
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
        backgroundColor: theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Proceed to next step
  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      if (_currentStep == 0) {
        // Mobile number: Check existing user
        final mobile = mobileController.text.trim();
        final existingUser = await supabase
            .from('users')
            .select()
            .eq('mobile_number', mobile)
            .maybeSingle();

        if (existingUser != null) {
          showDialog(
            context: context,
            builder: (context) {
              final theme = ThemeManager().currentTheme;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: theme.cardBackground,
                title: Text(
                  'رقم الهاتف مسجل',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: theme.textColor,
                  ),
                ),
                content: Text(
                  'يرجى استخدام هاتف آخر أو تسجيل الدخول.',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: theme.secondaryTextColor,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'حاول مرة أخرى',
                      style: GoogleFonts.cairo(
                        color: theme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'تسجيل الدخول',
                      style: GoogleFonts.cairo(
                        color: theme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          return;
        }
        setState(() => _currentStep = 1); // Move to Password
      } else if (_currentStep == 1) {
        setState(() => _currentStep = 2); // Move to Name
      } else if (_currentStep == 2) {
        setState(() => _currentStep = 3); // Move to Address
      } else if (_currentStep == 3) {
        await _proceedToOtp(); // Move to OTP
      }
    } catch (e) {
      _showSnackBar(
        e.toString().contains('Network')
            ? 'تحقق من الاتصال بالإنترنت'
            : e.toString().contains('duplicate')
            ? 'رقم الهاتف مسجل مسبقًا'
            : 'خطأ: ${e.toString()}',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Go back
  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  // Input decoration with Font Awesome icons
  InputDecoration _buildInputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
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
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      isDense: true,
    );
  }

  // Build step content with Font Awesome icons and buttons
  Widget _buildStepContent() {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (_currentStep) {
            0 => Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.phone,
                  size: isMobile ? 50 : 60,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'رقم الهاتف',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20 : 22,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل رقم هاتفك المسجل على واتساب للتسجيل',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 16,
                    color: theme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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
                  onFieldSubmitted: (_) => _proceed(),
                ),
              ],
            ),
            1 => Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.lock,
                  size: isMobile ? 50 : 60,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'كلمة المرور',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20 : 22,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل كلمة مرور آمنة لاستخدامها في تسجيل الدخول',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 16,
                    color: theme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: passwordController,
                  decoration: _buildInputDecoration(
                    'كلمة المرور',
                    FontAwesomeIcons.lock,
                    suffixIcon: IconButton(
                      icon: FaIcon(
                        _obscurePassword ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                        color: theme.secondaryTextColor,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'كلمة المرور مطلوبة';
                    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                  onFieldSubmitted: (_) => _proceed(),
                ),
              ],
            ),
            2 => Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.user,
                  size: isMobile ? 50 : 60,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'الاسم',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20 : 22,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل اسمك الشخصي',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 16,
                    color: theme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: _buildInputDecoration('الاسم', FontAwesomeIcons.user),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'الاسم مطلوب';
                    if (!_isValidName(value)) return 'الاسم يجب أن يحتوي على حروف فقط';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                  onFieldSubmitted: (_) => _proceed(),
                ),
              ],
            ),
            3 => Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.mapLocationDot,
                  size: isMobile ? 50 : 60,
                  color: theme.primaryColor,
                ),
                const SizedBox(height: 10),
                Text(
                  'تفاصيل التوصيل',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20 : 22,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل تفاصيل التوصيل',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 16,
                    color: theme.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedCompoundId,
                  decoration: _buildInputDecoration('الكمبوند', FontAwesomeIcons.mapLocationDot),
                  items: compounds.map((compound) {
                    return DropdownMenuItem<String>(
                      value: compound['id'].toString(),
                      child: Text(
                        compound['name'],
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: theme.textColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCompoundId = value),
                  validator: (value) => value == null ? 'الكمبوند مطلوب' : null,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: buildingNumberController,
                  decoration: _buildInputDecoration('رقم العمارة', FontAwesomeIcons.building),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'رقم المبنى مطلوب';
                    if (value.length > 3) return 'رقم المبنى يجب ألا يتجاوز 3 أرقام';
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
                  controller: apartmentNumberController,
                  decoration: _buildInputDecoration('رقم الشقة', FontAwesomeIcons.doorOpen),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'رقم الشقة مطلوب';
                    if (value.length > 2) return 'رقم الشقة يجب ألا يتجاوز رقمين';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                  onFieldSubmitted: (_) => _proceed(),
                ),
              ],
            ),
            _ => Container(),
          },
          // Buttons
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _goBack,
                child: Text(
                  _currentStep == 0 ? 'إلغاء' : 'رجوع',
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
                onPressed: _proceed,
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
                    'التالي',
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
          // Login link for step 0
          if (_currentStep == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  child: Text(
                    'لديك حساب؟ تسجيل الدخول',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14 : 16,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
                  // Progress bar
                  Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: theme.primaryColor.withOpacity(0.2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: (_currentStep + 1) / 4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: theme.appBarGradient,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.5, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey<int>(_currentStep),
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
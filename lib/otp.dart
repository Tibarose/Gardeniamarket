import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'compound/homescreen/thememanager.dart';
import 'customerapp/auth_provider.dart';
import 'customerapp/hypersender_utils.dart';

class OtpVerificationPage extends StatefulWidget {
  final String mobile;
  final String password;
  final String name;
  final String buildingNumber;
  final String apartmentNumber;
  final String compoundId;
  final String generatedOtp;

  const OtpVerificationPage({
    super.key,
    required this.mobile,
    required this.password,
    required this.name,
    required this.buildingNumber,
    required this.apartmentNumber,
    required this.compoundId,
    required this.generatedOtp,
  });

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool isLoading = false;
  bool _isLocked = false;
  int _otpAttempts = 0;
  bool _resendCooldown = false;
  int _countdownSeconds = 30;
  Timer? _countdownTimer;
  late String _generatedOtp;
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  bool _hasError = false;

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
      print('Resending OTP: $_generatedOtp');
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
        final theme = ThemeManager().currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في إعادة إرسال الكود: $e',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Save credentials to SharedPreferences
  Future<void> _saveCredentials(String mobile, String hashedPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mobile', mobile);
    await prefs.setString('user_password', hashedPassword);
  }

  // Verify OTP and register
  Future<void> _verifyOtpAndRegister() async {
    if (!_formKey.currentState!.validate() || _isLocked) {
      setState(() => _hasError = true);
      _animationController.forward().then((_) => _animationController.reverse());
      final theme = ThemeManager().currentTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال كود تحقق مكون من 6 أرقام',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
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
        final theme = ThemeManager().currentTheme;
        if (_otpAttempts >= 3) {
          setState(() => _isLocked = true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'لقد وصلت إلى الحد الأقصى للمحاولات. يرجى طلب كود جديد.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'كود التحقق غير صحيح. تبقى ${3 - _otpAttempts} محاولات.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            );
          }
        }
        return;
      }

      setState(() {
        _otpAttempts = 0;
        _hasError = false;
      });

      final hashedPassword = _hashPassword(widget.password);
      final userId = const Uuid().v4();

      final userData = {
        'id': userId,
        'mobile_number': widget.mobile,
        'password': hashedPassword,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'building_number': widget.buildingNumber,
        'apartment_number': widget.apartmentNumber,
        'compound_id': widget.compoundId,
        'is_delivery_guy': false,
        'is_available': true,
        'name': widget.name,
      };

      await supabase.from('users').insert(userData);

      // Save credentials to SharedPreferences
      await _saveCredentials(widget.mobile, hashedPassword);

      // Sign in the user using AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        mobileNumber: widget.mobile,
        password: widget.password,
      );

      if (context.mounted) {
        final theme = ThemeManager().currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم التسجيل بنجاح!',
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

        // Navigate to MarketPage
        Navigator.pushReplacementNamed(context, '/GardeniaTodayApp');
      }
    } catch (e) {
      setState(() => _hasError = true);
      _animationController.forward().then((_) => _animationController.reverse());
      if (context.mounted) {
        final theme = ThemeManager().currentTheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Network')
                  ? 'تحقق من الاتصال بالإنترنت'
                  : e.toString().contains('duplicate')
                  ? 'رقم الهاتف مسجل مسبقًا'
                  : 'خطأ في التحقق: ${e.toString()}',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
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

  // Check if all OTP fields are filled
  bool _isOtpComplete() {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  // Build step content with buttons under the card
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
            FontAwesomeIcons.checkCircle,
            size: isMobile ? 50 : 60,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'تحقق من رقم الهاتف',
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
              'تحقق من واتساب على الرقم: ${widget.mobile}\nلم يصل الكود؟ اضغط "إعادة إرسال"',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14 : 16,
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
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
                              if (index == 5 && value.isNotEmpty && _isOtpComplete()) {
                                _verifyOtpAndRegister();
                              }
                            },
                            textInputAction: index == 5 ? TextInputAction.done : TextInputAction.next,
                            onFieldSubmitted: (_) {
                              if (index == 5 && _isOtpComplete()) {
                                _verifyOtpAndRegister();
                              }
                            },
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
          const SizedBox(height: 16),
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
          // Buttons under the card
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
              isLoading || _isLocked || !_isOtpComplete()
                  ? isLoading
                  ? CircularProgressIndicator(color: theme.primaryColor)
                  : const SizedBox()
                  : ElevatedButton(
                onPressed: _verifyOtpAndRegister,
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
                    'تأكيد',
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
                  // Progress bar at 100%
                  Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: theme.primaryColor.withOpacity(0.2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1.0,
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
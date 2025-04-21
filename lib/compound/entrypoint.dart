import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:gardeniamarket/customerapp/register.dart';
import '../customerapp/auth_provider.dart';
import 'home_screen.dart';
import 'homescreen/thememanager.dart';
import 'core/config/supabase_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Conditional imports for web-specific functionality
import 'web_stubs.dart' if (dart.library.js) 'dart:js' as js;

class EntryScreen extends StatefulWidget {
  final SupabaseConfig supabaseConfig;

  const EntryScreen({super.key, required this.supabaseConfig});

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isPWAInstalled = false;
  bool _isInstallPromptSupported = false;
  bool _hasRequestedPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPWAInstalled();
    _checkInstallPromptSupport();
  }

  // Check if the app is running as a standalone PWA
  void _checkPWAInstalled() {
    if (kIsWeb) {
      try {
        final mediaQuery = js.context.callMethod('matchMedia', [
          '(display-mode: standalone)',
        ]);
        final isStandalone = mediaQuery['matches'] as bool;
        setState(() {
          _isPWAInstalled = isStandalone;
        });
        debugPrint('PWA Installed: $isStandalone');
      } catch (e) {
        debugPrint('Error checking PWA installation status: $e');
        setState(() {
          _isPWAInstalled = false;
        });
      }
    }
  }

  // Check if beforeinstallprompt is supported
  Future<void> _checkInstallPromptSupport() async {
    if (kIsWeb) {
      try {
        final isSupported = await js.context.callMethod('isInstallPromptSupported') as bool;
        setState(() {
          _isInstallPromptSupported = isSupported;
        });
        debugPrint('Install Prompt Supported: $isSupported');
      } catch (e) {
        debugPrint('Error checking install prompt support: $e');
        setState(() {
          _isInstallPromptSupported = false;
        });
      }
    }
  }

  // Trigger PWA installation prompt
  void _triggerPWAInstall() {
    if (kIsWeb) {
      final userAgent = kIsWeb ? js.context['navigator']['userAgent'].toString().toLowerCase() : '';
      final isIOS = userAgent.contains('iphone') || userAgent.contains('ipad');
      final isSafari = userAgent.contains('safari') && !userAgent.contains('chrome');
      final isFirefox = userAgent.contains('firefox');

      if (isIOS && isSafari) {
        _showSafariInstallInstructions();
      } else if (isFirefox) {
        _showFirefoxInstallInstructions();
      } else {
        try {
          final result = js.context.callMethod('triggerInstallPrompt');
          if (result == 'unsupported') {
            _showGenericInstallInstructions();
          } else {
            debugPrint('Called triggerInstallPrompt');
            Future.delayed(const Duration(seconds: 2), _checkPWAInstalled);
          }
        } catch (e) {
          debugPrint('Error triggering PWA install prompt: $e');
          _showGenericInstallInstructions();
        }
      }
    } else {
      debugPrint('Install feature only available on web');
      _showSnackBar('ميزة التثبيت متاحة فقط على الويب.');
    }
  }

  // Request notification permission and save FCM token to Supabase via Edge Function
  Future<void> _requestNotificationPermission() async {
    if (_hasRequestedPermission) {
      _showSnackBar('تم طلب الإشعارات بالفعل.');
      return;
    }

    setState(() {
      _hasRequestedPermission = true;
    });

    final messaging = FirebaseMessaging.instance;
    NotificationSettings? settings;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        print('DEBUG: Notification permission status (attempt $attempt): ${settings.authorizationStatus}');
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.denied) {
          break;
        }
      } catch (e) {
        print('DEBUG: Error requesting permission (attempt $attempt): $e');
        if (attempt == 3) {
          _showSnackBar('فشل طلب إذن الإشعارات: $e');
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (settings?.authorizationStatus == AuthorizationStatus.authorized) {
      try {
        String? fcmToken;
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            fcmToken = await messaging.getToken(
              vapidKey: "BOX59MKvsok_QHYmSkD06klzNhJ6KPBAuf5nN0SZLjCfxQWcuwyEc08p4dkdhNUXrdXP3eZTtuON1sMBifgWgVk",
            );
            print('DEBUG: FCM token retrieved (attempt $attempt): $fcmToken');
            break;
          } catch (e) {
            print('DEBUG: Error retrieving FCM token (attempt $attempt): $e');
            if (attempt == 3) {
              _showSnackBar('فشل استرجاع رمز FCM: $e');
              return;
            }
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        if (fcmToken != null) {
          try {
            // Use the secondary client to call the Edge Function
            final response = await widget.supabaseConfig.secondaryClient.functions.invoke(
              'save-fcm-token',
              body: {
                'device_token': fcmToken,
                'device_type': 'web',
              },
            );

            // Parse the response data
            final responseData = response.data as Map<String, dynamic>?;

            if (responseData == null) {
              print('DEBUG: Error saving FCM token via Edge Function: Response data is null');
              _showSnackBar('فشل حفظ رمز الإشعارات: البيانات غير متاحة');
              return;
            }

            if (responseData.containsKey('error')) {
              print('DEBUG: Error saving FCM token via Edge Function: ${responseData['error']}');
              _showSnackBar('فشل حفظ رمز الإشعارات: ${responseData['error']}');
            } else if (responseData.containsKey('message')) {
              print('DEBUG: FCM token saved via Edge Function: $fcmToken');
              _showSnackBar('تم حفظ رمز الإشعارات بنجاح!');
            } else {
              print('DEBUG: Unexpected response from Edge Function: $responseData');
              _showSnackBar('فشل حفظ رمز الإشعارات: استجابة غير متوقعة');
            }
          } catch (e) {
            print('DEBUG: Error saving FCM token via Edge Function: $e');
            _showSnackBar('فشل حفظ رمز الإشعارات: $e');
          }
        } else {
          print('DEBUG: Failed to retrieve FCM token after retries');
          _showSnackBar('فشل استرجاع رمز الإشعارات بعد المحاولات.');
        }
      } catch (e) {
        print('DEBUG: Error retrieving FCM token: $e');
        _showSnackBar('خطأ أثناء استرجاع رمز الإشعارات: $e');
      }
    } else {
      print('DEBUG: Notification permission denied or not granted');
      _showSnackBar('تم رفض إذن الإشعارات أو لم يتم منحه.');
    }
  }  // Show installation instructions for iOS Safari
  void _showInstructionDialog({
    required BuildContext context,
    required String title,
    required List<Map<String, String>> instructions, // List of {arabic, english} pairs
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeManager().currentTheme.cardBackground,
                ThemeManager().currentTheme.cardBackground.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ThemeManager().currentTheme.primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              FaIcon(
                icon,
                size: 40,
                color: ThemeManager().currentTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ThemeManager().currentTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              // Instructions
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: instructions.length,
                  itemBuilder: (context, index) {
                    final instruction = instructions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            instruction['arabic']!,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager().currentTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            instruction['english']!,
                            textDirection: TextDirection.ltr,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: ThemeManager()
                                  .currentTheme
                                  .secondaryTextColor
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // OK Button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: ThemeManager().currentTheme.appBarGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                        ThemeManager().currentTheme.primaryColor.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Text(
                    'حسناً',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show installation instructions for iOS Safari
  void _showSafariInstallInstructions() {
    _showInstructionDialog(
      context: context,
      title: 'تثبيت التطبيق',
      instructions: [
        {
          'arabic': '١. اضغط على زر المشاركة (مربع مع سهم) في شريط المتصفح.',
          'english': '1. Tap the Share button (square with arrow) in the browser toolbar.',
        },
        {
          'arabic': '٢. اختر "إضافة إلى الشاشة الرئيسية".',
          'english': '2. Select "Add to Home Screen".',
        },
        {
          'arabic': '٣. اضغط على "إضافة" في الزاوية العلوية.',
          'english': '3. Tap "Add" in the top corner.',
        },
      ],
      icon: FontAwesomeIcons.apple,
    );
  }

  // Show installation instructions for Firefox on Android
  void _showFirefoxInstallInstructions() {
    _showInstructionDialog(
      context: context,
      title: 'تثبيت التطبيق',
      instructions: [
        {
          'arabic': '١. اضغط على القائمة (ثلاث نقاط) في شريط المتصفح.',
          'english': '1. Tap the menu (three dots) in the browser toolbar.',
        },
        {
          'arabic': '٢. اختر "إضافة إلى الشاشة الرئيسية".',
          'english': '2. Select "Add to Home Screen".',
        },
        {
          'arabic': '٣. أكد التثبيت عند الطلب.',
          'english': '3. Confirm the installation when prompted.',
        },
      ],
      icon: FontAwesomeIcons.firefox,
    );
  }

  // Show generic installation instructions for other browsers
  void _showGenericInstallInstructions() {
    _showInstructionDialog(
      context: context,
      title: 'تثبيت التطبيق',
      instructions: [
        {
          'arabic': '١. افتح قائمة المتصفح (عادةً ثلاث نقاط أو رمز القائمة).',
          'english': '1. Open the browser menu (usually three dots or a menu icon).',
        },
        {
          'arabic': '٢. ابحث عن خيار مثل "إضافة إلى الشاشة الرئيسية" أو "تثبيت التطبيق".',
          'english': '2. Look for an option like "Add to Home Screen" or "Install App".',
        },
        {
          'arabic': '٣. اتبع التعليمات لإضافته إلى شاشتك الرئيسية.',
          'english': '3. Follow the instructions to add it to your home screen.',
        },
        {
          'arabic':
          'ملاحظة: إذا لم تجد الخيار، تأكد من استخدام متصفح متوافق مثل Chrome أو Samsung Internet.',
          'english':
          'Note: If you don’t see the option, ensure you’re using a compatible browser like Chrome or Samsung Internet.',
        },
      ],
      icon: FontAwesomeIcons.globe,
    );
  }

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
      _showSnackBar(
        'رقم الهاتف يجب أن يبدأ بـ 010, 011, 012, أو 015 ويكون 11 رقمًا',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(mobileNumber: mobile, password: password);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل الدخول بنجاح!',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: ThemeManager().currentTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GardeniaTodayApp(supabaseConfig: widget.supabaseConfig),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('اسم المستخدم أو كلمة المرور غير صحيحة');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _hasRequestedPermission && message.contains('نجاح') ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Input decoration
  InputDecoration _buildInputDecoration(
      String label,
      IconData icon, {
        Widget? suffixIcon,
      }) {
    final theme = ThemeManager().currentTheme;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(
        color: theme.secondaryTextColor,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.secondaryTextColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorStyle: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 12),
      prefixIcon: FaIcon(icon, color: theme.primaryColor),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(gradient: theme.appBarGradient),
            ),
            // Shimmering wave effect
            const Positioned.fill(child: ShimmeringWave()),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // App Logo/Name
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          'جاردينيا توداي',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 36 : 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInDown(
                        duration: const Duration(milliseconds: 700),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'كل خدماتك في مكان واحد',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Login Card
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.2),
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
                                'تسجيل الدخول',
                                style: GoogleFonts.cairo(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'أدخل بياناتك للوصول إلى حسابك',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: theme.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: mobileController,
                                decoration: _buildInputDecoration(
                                  'رقم الهاتف (مثال: 01012345678)',
                                  FontAwesomeIcons.phone,
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: passwordController,
                                decoration: _buildInputDecoration(
                                  'كلمة المرور',
                                  FontAwesomeIcons.lock,
                                  suffixIcon: IconButton(
                                    icon: FaIcon(
                                      _obscurePassword
                                          ? FontAwesomeIcons.eye
                                          : FontAwesomeIcons.eyeSlash,
                                      color: theme.secondaryTextColor,
                                    ),
                                    onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: theme.textColor,
                                ),
                                onFieldSubmitted: (_) => _login(context),
                              ),
                              const SizedBox(height: 16),
                              // Forget Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/forget_password',
                                    );
                                  },
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: GoogleFonts.cairo(
                                      fontSize: isMobile ? 14 : 16,
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _isLoading
                                  ? CircularProgressIndicator(
                                color: theme.primaryColor,
                              )
                                  : GestureDetector(
                                onTapDown: (_) => setState(() {}),
                                child: AnimatedScale(
                                  scale: 1.0,
                                  duration: const Duration(
                                    milliseconds: 100,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _login(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: theme.appBarGradient,
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor
                                                .withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 32,
                                      ),
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Guest and Register Buttons in a Row
                      FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: const Duration(milliseconds: 600),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildGradientButton(
                                context: context,
                                text: 'الدخول كضيف',
                                icon: FontAwesomeIcons.arrowRightToBracket,
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GardeniaTodayApp(
                                        supabaseConfig: widget.supabaseConfig,
                                      ),
                                    ),
                                  );
                                },
                                theme: theme,
                                isMobile: isMobile,
                                isProminent: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildGradientButton(
                                context: context,
                                text: 'التسجيل',
                                icon: FontAwesomeIcons.userPlus,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterPage(),
                                    ),
                                  );
                                },
                                theme: theme,
                                isMobile: isMobile,
                                isProminent: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Add to Home Screen Button (PWA Install)
                      if (!_isPWAInstalled && kIsWeb)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 800),
                          child: Pulse(
                            duration: const Duration(milliseconds: 1200),
                            child: _buildGradientButton(
                              context: context,
                              text: 'تثبيت التطبيق',
                              icon: FontAwesomeIcons.download,
                              onPressed: _triggerPWAInstall,
                              theme: theme,
                              isMobile: isMobile,
                              isProminent: true,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Enable Notifications Button
                      if (!_hasRequestedPermission && kIsWeb)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 1000),
                          child: Pulse(
                            duration: const Duration(milliseconds: 1200),
                            child: _buildGradientButton(
                              context: context,
                              text: 'تفعيل الإشعارات',
                              icon: FontAwesomeIcons.bell,
                              onPressed: _requestNotificationPermission,
                              theme: theme,
                              isMobile: isMobile,
                              isProminent: true,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required AppTheme theme,
    required bool isMobile,
    required bool isProminent,
  }) {
    // Adjust width for row layout
    final buttonWidth = isMobile
        ? (MediaQuery.of(context).size.width - 32 - 10) / 2 // Account for padding and gap
        : 150;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.appBarGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(isProminent ? 0.5 : 0.3),
              spreadRadius: isProminent ? 2 : 1,
              blurRadius: isProminent ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: Colors.white,
              size: isMobile ? (isProminent ? 24 : 18) : (isProminent ? 26 : 20),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: isMobile ? (isProminent ? 16 : 14) : (isProminent ? 18 : 16),
                fontWeight: isProminent ? FontWeight.w800 : FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder ShimmeringWave widget
class ShimmeringWave extends StatelessWidget {
  const ShimmeringWave({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

// Stub for web-specific imports when not running on web
class WebStubs {
  static void stub() {}
}
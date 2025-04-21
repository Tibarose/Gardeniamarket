import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../customerapp/auth_provider.dart';
import 'core/config/supabase_config.dart';
import 'entrypoint.dart';
import 'homescreen/thememanager.dart';
import 'homescreen/contactus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for web-specific functionality
import 'web_stubs.dart' if (dart.library.js) 'dart:js' as js;

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = true;
  bool _isPWAInstalled = false;
  bool _isInstallPromptSupported = false;
  bool _isNotificationLoading = false;
  String? _notificationStatusMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _checkPWAInstalled();
    _checkInstallPromptSupport();

    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() => _isLoading = false);
      _controller.forward();
    });
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

  // Request notification permission and save FCM token
  Future<void> _requestNotificationPermission() async {
    if (!kIsWeb) {
      print('DEBUG: Not running on web, skipping notification permission request');
      setState(() {
        _notificationStatusMessage = 'الإشعارات غير مدعومة على هذا الجهاز';
      });
      _showSnackBar('الإشعارات غير مدعومة على هذا الجهاز');
      return;
    }

    setState(() {
      _isNotificationLoading = true;
      _notificationStatusMessage = null;
    });

    final messaging = FirebaseMessaging.instance;
    print('DEBUG: Starting notification permission request');

    try {
      // Check current permission status
      final settings = await messaging.getNotificationSettings();
      print('DEBUG: Current notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('DEBUG: Notifications already authorized');
        setState(() {
          _notificationStatusMessage = 'تم منح إذن الإشعارات مسبقًا';
        });
        await _saveFCMToken();
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('DEBUG: Notifications denied by user');
        setState(() {
          _notificationStatusMessage =
          'تم رفض إذن الإشعارات. يرجى تفعيل الإشعارات من إعدادات المتصفح.';
        });
        _showSnackBar(
            'تم رفض إذن الإشعارات. يرجى تفعيل الإشعارات من إعدادات المتصفح.');
      } else {
        print('DEBUG: Requesting notification permission');
        final newSettings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        print('DEBUG: Notification permission status: ${newSettings.authorizationStatus}');

        if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
          print('DEBUG: Notification permission granted');
          setState(() {
            _notificationStatusMessage = 'تم منح إذن الإشعارات';
          });
          await _saveFCMToken();
        } else {
          print('DEBUG: Notification permission denied or not granted');
          setState(() {
            _notificationStatusMessage = 'لم يتم منح إذن الإشعارات';
          });
          _showSnackBar('لم يتم منح إذن الإشعارات');
        }
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error requesting notification permission: $e');
      print('DEBUG: Stack trace: $stackTrace');
      setState(() {
        _notificationStatusMessage = 'خطأ أثناء طلب الإذن: $e';
      });
      _showSnackBar('خطأ أثناء طلب الإذن');
    } finally {
      setState(() {
        _isNotificationLoading = false;
      });
    }
  }

  // Save FCM token to secondary Supabase client
  Future<void> _saveFCMToken() async {
    print('DEBUG: Attempting to save FCM token');
    final messaging = FirebaseMessaging.instance;
    try {
      String? fcmToken = await messaging.getToken(
        vapidKey:
        "BOX59MKvsok_QHYmSkD06klzNhJ6KPBAuf5nN0SZLjCfxQWcuwyEc08p4dkdhNUXrdXP3eZTtuON1sMBifgWgVk",
      );
      print('DEBUG: FCM token retrieved: $fcmToken');

      if (fcmToken != null) {
        try {
          final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
          print('DEBUG: Saving FCM token to Supabase: $fcmToken');
          await supabaseConfig.secondaryClient.from('registered_devices').upsert({
            'device_token': fcmToken,
            'device_type': 'web',
          }, onConflict: 'device_token');
          print('DEBUG: FCM token saved successfully: $fcmToken');
          _showSnackBar('تم حفظ رمز الإشعارات بنجاح');
        } catch (e, stackTrace) {
          print('DEBUG: Error saving FCM token to Supabase: $e');
          print('DEBUG: Stack trace: $stackTrace');
          setState(() {
            _notificationStatusMessage = 'خطأ أثناء حفظ رمز الإشعارات: $e';
          });
          _showSnackBar('خطأ أثناء حفظ رمز الإشعارات');
        }
      } else {
        print('DEBUG: FCM token is null');
        setState(() {
          _notificationStatusMessage = 'لم يتم استرداد رمز الإشعارات';
        });
        _showSnackBar('لم يتم استرداد رمز الإشعارات');
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error retrieving FCM token: $e');
      print('DEBUG: Stack trace: $stackTrace');
      setState(() {
        _notificationStatusMessage = 'خطأ أثناء استرداد رمز الإشعارات: $e';
      });
      _showSnackBar('خطأ أثناء استرداد رمز الإشعارات');
    }
  }

  // Custom widget for instruction dialogs
  void _showInstructionDialog({
    required BuildContext context,
    required String title,
    required List<Map<String, String>> instructions,
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
              FaIcon(
                icon,
                size: 40,
                color: ThemeManager().currentTheme.primaryColor,
              ),
              const SizedBox(height: 12),
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
                        color: ThemeManager().currentTheme.primaryColor.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 16.0 : 24.0;
    final cardRadius = isMobile ? 16.0 : 20.0;

    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final theme = themeManager.currentTheme;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: theme.backgroundColor,
            appBar: AppBar(
              title: Text(
                'المزيد',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.right,
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: theme.appBarGradient,
                ),
              ),
              elevation: 0,
              centerTitle: true,
              actions: const [],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 1000));
                setState(() => _isLoading = false);
              },
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: _isLoading
                    ? _buildSkeletonLoader(isMobile)
                    : isMobile
                    ? _buildListView(theme, cardRadius, isMobile)
                    : _buildGridView(theme, cardRadius, isMobile),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader(bool isMobile) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6, // Increased to account for new notification item
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(AppTheme theme, double cardRadius, bool isMobile) {
    final items = _getMenuItems(theme, isMobile);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildMenuCard(
              icon: items[index]['icon'] as IconData,
              title: items[index]['title'] as String,
              onTap: items[index]['onTap'] as VoidCallback,
              theme: theme,
              cardRadius: cardRadius,
              isMobile: isMobile,
              semanticLabel: items[index]['semanticLabel'] as String,
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridView(AppTheme theme, double cardRadius, bool isMobile) {
    final items = _getMenuItems(theme, isMobile);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 1.5 : 1.7,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildMenuCard(
              icon: items[index]['icon'] as IconData,
              title: items[index]['title'] as String,
              onTap: items[index]['onTap'] as VoidCallback,
              theme: theme,
              cardRadius: cardRadius,
              isMobile: isMobile,
              semanticLabel: items[index]['semanticLabel'] as String,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required AppTheme theme,
    required double cardRadius,
    required bool isMobile,
    required String semanticLabel,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'معاينة: $title',
              style: GoogleFonts.cairo(
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
            backgroundColor: theme.primaryColor,
          ),
        );
      },
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: Hero(
          tag: title,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: [
                BoxShadow(
                  color: theme.secondaryTextColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cardRadius),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withOpacity(0.1),
                            theme.accentColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: theme.secondaryTextColor,
                          size: isMobile ? 16 : 18,
                          semanticLabel: 'الانتقال إلى $title',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        FaIcon(
                          icon,
                          color: theme.primaryColor,
                          size: isMobile ? 24 : 28,
                          semanticLabel: 'أيقونة $title',
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

  List<Map<String, dynamic>> _getMenuItems(AppTheme theme, bool isMobile) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;

    final items = [
      {
        'icon': FontAwesomeIcons.envelope,
        'title': 'تواصل معنا',
        'onTap': () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              final controller = AnimationController(
                vsync: Navigator.of(context),
                duration: ThemeManager.animationDuration,
              );
              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeIn),
              );
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              );
              controller.forward();
              return ContactUsBottomSheet(
                onClose: () {
                  controller.reverse().then((_) {
                    controller.dispose();
                    Navigator.pop(context);
                  });
                },
                slideAnimation: slideAnimation,
                fadeAnimation: fadeAnimation,
              );
            },
          );
        },
        'semanticLabel': 'فتح نموذج التواصل لإرسال استفسارات أو اقتراحات',
      },
      {
        'icon': FontAwesomeIcons.share,
        'title': 'مشاركة التطبيق',
        'onTap': () async {
          await Share.share(
            '''
📱 تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
'''.trim(),
            subject: 'جاردينيا توداي',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تمت المشاركة بنجاح!',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: isMobile ? 14 : 16,
                ),
                textAlign: TextAlign.right,
              ),
              backgroundColor: theme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(isMobile ? 16 : 24),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMobile ? 12 : 14,
              ),
            ),
          );
        },
        'semanticLabel': 'مشاركة رابط تطبيق جاردينيا توداي مع الآخرين',
      },
      {
        'icon': FontAwesomeIcons.star,
        'title': 'تقييم التطبيق',
        'onTap': () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              final controller = AnimationController(
                vsync: Navigator.of(context),
                duration: ThemeManager.animationDuration,
              );
              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeIn),
              );
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              );
              controller.forward();
              return RateAppBottomSheet(
                onClose: () {
                  controller.reverse().then((_) {
                    controller.dispose();
                    Navigator.pop(context);
                  });
                },
                slideAnimation: slideAnimation,
                fadeAnimation: fadeAnimation,
                theme: theme,
                isMobile: isMobile,
              );
            },
          );
        },
        'semanticLabel': 'فتح نافذة تقييم تطبيق جاردينيا توداي',
      },
      {
        'icon': FontAwesomeIcons.lightbulb,
        'title': 'الاقتراحات',
        'onTap': () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              final controller = AnimationController(
                vsync: Navigator.of(context),
                duration: ThemeManager.animationDuration,
              );
              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeIn),
              );
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              );
              controller.forward();
              return SuggestionsBottomSheet(
                onClose: () {
                  controller.reverse().then((_) {
                    controller.dispose();
                    Navigator.pop(context);
                  });
                },
                slideAnimation: slideAnimation,
                fadeAnimation: fadeAnimation,
                theme: theme,
                isMobile: isMobile,
              );
            },
          );
        },
        'semanticLabel': 'فتح نموذج إرسال اقتراحات لتحسين تطبيق جاردينيا توداي',
      },
      {
        'icon': FontAwesomeIcons.infoCircle,
        'title': 'عن التطبيق',
        'onTap': () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              final controller = AnimationController(
                vsync: Navigator.of(context),
                duration: ThemeManager.animationDuration,
              );
              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeIn),
              );
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
              );
              controller.forward();
              return AboutAppBottomSheet(
                onClose: () {
                  controller.reverse().then((_) {
                    controller.dispose();
                    Navigator.pop(context);
                  });
                },
                slideAnimation: slideAnimation,
                fadeAnimation: fadeAnimation,
                theme: theme,
                isMobile: isMobile,
              );
            },
          );
        },
        'semanticLabel': 'عرض معلومات حول تطبيق جاردينيا توداي وإصداره',
      },
      // Add Enable Notifications option
      if (kIsWeb)
        {
          'icon': FontAwesomeIcons.bell,
          'title': 'تفعيل الإشعارات',
          'onTap': () {
            print('DEBUG: User clicked Enable Notifications');
            _requestNotificationPermission();
          },
          'semanticLabel': 'تفعيل إشعارات تطبيق جاردينيا توداي',
        },
      // Add Install App option if running on web and not installed as PWA
      if (kIsWeb && !_isPWAInstalled)
        {
          'icon': FontAwesomeIcons.download,
          'title': 'تثبيت التطبيق',
          'onTap': () {
            _triggerPWAInstall();
          },
          'semanticLabel': 'تثبيت تطبيق جاردينيا توداي على الشاشة الرئيسية',
        },
    ];

    if (isAuthenticated) {
      items.add({
        'icon': FontAwesomeIcons.signOutAlt,
        'title': 'تسجيل الخروج',
        'onTap': () async {
          try {
            await authProvider.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم تسجيل الخروج بنجاح!',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  textAlign: TextAlign.right,
                ),
                backgroundColor: theme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(isMobile ? 16 : 24),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isMobile ? 12 : 14,
                ),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EntryScreen(supabaseConfig: supabaseConfig),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'فشل تسجيل الخروج، حاول مرة أخرى',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  textAlign: TextAlign.right,
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(isMobile ? 16 : 24),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isMobile ? 12 : 14,
                ),
              ),
            );
          }
        },
        'semanticLabel': 'تسجيل الخروج من حساب المستخدم والعودة إلى شاشة الدخول',
      });
    }

    return items;
  }
}

class AboutAppBottomSheet extends StatelessWidget {
  final VoidCallback onClose;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final AppTheme theme;
  final bool isMobile;

  const AboutAppBottomSheet({
    super.key,
    required this.onClose,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.theme,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: theme.secondaryTextColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.secondaryTextColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      color: theme.secondaryTextColor,
                      onPressed: onClose,
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'جاردينيا توداي',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الإصدار: 1.0.0',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w500,
                        color: theme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاردينيا توداي هو تطبيق شامل لتلبية جميع احتياجاتك اليومية داخل الكمبوند.',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w400,
                        color: theme.textColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '© 2025 Gardenia Today',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w400,
                        color: theme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class RateAppBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final AppTheme theme;
  final bool isMobile;

  const RateAppBottomSheet({
    super.key,
    required this.onClose,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.theme,
    required this.isMobile,
  });

  @override
  _RateAppBottomSheetState createState() => _RateAppBottomSheetState();
}

class _RateAppBottomSheetState extends State<RateAppBottomSheet> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار تقييم من 1 إلى 5 نجوم',
            style: GoogleFonts.cairo(
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final feedback = _rating <= 4 ? _feedbackController.text.trim() : null;

      await supabaseConfig.secondaryClient.from('app_ratings').insert({
        'rating': _rating,
        'feedback': feedback,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال التقييم بنجاح!',
            style: GoogleFonts.cairo(
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
          backgroundColor: widget.theme.primaryColor,
        ),
      );
      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل إرسال التقييم، حاول مرة أخرى',
            style: GoogleFonts.cairo(
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.slideAnimation,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: widget.theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: widget.theme.secondaryTextColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.theme.secondaryTextColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        color: widget.theme.secondaryTextColor,
                        onPressed: widget.onClose,
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'تقييم تطبيق جاردينيا توداي',
                        style: GoogleFonts.cairo(
                          fontSize: widget.isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: widget.theme.textColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          return IconButton(
                            icon: Icon(
                              _rating >= starValue ? Icons.star : Icons.star_border,
                              color: widget.theme.primaryColor,
                              size: widget.isMobile ? 32 : 36,
                            ),
                            onPressed: () {
                              setState(() => _rating = starValue);
                            },
                            tooltip: 'تقييم $starValue نجمة',
                          );
                        }).reversed.toList(),
                      ),
                      if (_rating > 0 && _rating <= 4) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _feedbackController,
                          maxLines: 3,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: widget.isMobile ? 14 : 16,
                            color: widget.theme.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ما الذي يمكن تحسينه؟',
                            hintStyle: GoogleFonts.cairo(
                              color: widget.theme.secondaryTextColor,
                            ),
                            filled: true,
                            fillColor: widget.theme.cardBackground.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isMobile ? 32 : 48,
                            vertical: widget.isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'إرسال التقييم',
                          style: GoogleFonts.cairo(
                            fontSize: widget.isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SuggestionsBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final AppTheme theme;
  final bool isMobile;

  const SuggestionsBottomSheet({
    super.key,
    required this.onClose,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.theme,
    required this.isMobile,
  });

  @override
  _SuggestionsBottomSheetState createState() => _SuggestionsBottomSheetState();
}

class _SuggestionsBottomSheetState extends State<SuggestionsBottomSheet> {
  final _suggestionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _submitSuggestion() async {
    final suggestion = _suggestionController.text.trim();
    if (suggestion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال اقتراح',
            style: GoogleFonts.cairo(
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient.from('suggestions').insert({
        'suggestion': suggestion,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال الاقتراح بنجاح!',
            style: GoogleFonts.cairo(
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
          backgroundColor: widget.theme.primaryColor,
        ),
      );
      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل إرسال الاقتراح، حاول مرة أخرى',
            style: GoogleFonts.cairo(
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.slideAnimation,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: widget.theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: widget.theme.secondaryTextColor.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: widget.theme.secondaryTextColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        color: widget.theme.secondaryTextColor,
                        onPressed: widget.onClose,
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'إرسال اقتراح',
                        style: GoogleFonts.cairo(
                          fontSize: widget.isMobile ? 20 : 24,
                          fontWeight: FontWeight.w700,
                          color: widget.theme.textColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _suggestionController,
                        maxLines: 4,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontSize: widget.isMobile ? 14 : 16,
                          color: widget.theme.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'شاركنا اقتراحك لتحسين التطبيق',
                          hintStyle: GoogleFonts.cairo(
                            color: widget.theme.secondaryTextColor,
                          ),
                          filled: true,
                          fillColor: widget.theme.cardBackground.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitSuggestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isMobile ? 32 : 48,
                            vertical: widget.isMobile ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'إرسال الاقتراح',
                          style: GoogleFonts.cairo(
                            fontSize: widget.isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for web_stubs.dart
class WebStubs {
  static void stub() {}
}
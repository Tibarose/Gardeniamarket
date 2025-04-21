import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/compound/searchpage.dart';
import 'package:gardeniamarket/compound/supermarketonline.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';
import 'core/config/supabase_config.dart';
import 'homescreen/allservice.dart';
import 'homescreen/carousal.dart';
import 'favouritescreen.dart';
import 'homescreen/compoundnws.dart';
import 'homescreen/contactus.dart';
import 'homescreen/emergency_screen.dart';
import 'homescreen/favouritenotify.dart';
import 'homescreen/flying.dart';
import 'homescreen/online_services.dart';
import 'homescreen/thememanager.dart';
import 'homescreen/themeselector.dart';
import 'morescreen.dart';
import 'package:gardeniamarket/customerapp/register.dart';

class GardeniaTodayApp extends StatefulWidget {
  final SupabaseConfig supabaseConfig;
  const GardeniaTodayApp({super.key, required this.supabaseConfig});

  @override
  _GardeniaTodayAppState createState() => _GardeniaTodayAppState();
}

class _GardeniaTodayAppState extends State<GardeniaTodayApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      initUniLinks();
      _setStatusBarStyle();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _setStatusBarStyle() {
    final theme = ThemeManager().currentTheme;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: theme.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(Uri.parse(initialLink));
      }

      _sub = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          print('Deep link error: $err');
        },
      );
    } catch (e) {
      print('Error initializing deep links: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      final path = uri.pathSegments[0];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed('/$path');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building GardeniaTodayApp');
    _setStatusBarStyle();
    return Builder(
      builder: (BuildContext innerContext) {
        print('DEBUG: Inside GardeniaTodayApp Builder');
        return HomeScreen(supabaseConfig: widget.supabaseConfig);
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          backgroundColor: ThemeManager().currentTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            'قيد التطوير: $title',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: ThemeManager().currentTheme.textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomePopup extends StatefulWidget {
  final bool isMobile;
  final String imageUrl;
  final String message;
  final String page;
  final String offerLink;
  final VoidCallback onClose;

  const WelcomePopup({
    super.key,
    required this.isMobile,
    required this.imageUrl,
    required this.message,
    required this.page,
    required this.offerLink,
    required this.onClose,
  });

  @override
  _WelcomePopupState createState() => _WelcomePopupState();
}

class _WelcomePopupState extends State<WelcomePopup>
    with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _showFullScreenImage(String imageUrl) {
    final theme = ThemeManager().currentTheme;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => Container(
                            color: theme.cardBackground.withOpacity(0.5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.exclamationCircle,
                                  color: theme.primaryColor,
                                  size: 50,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'فشل في تحميل الصورة',
                                  style: GoogleFonts.cairo(
                                    color: theme.textColor,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: theme.accentColor,
                    mini: true,
                    child: const FaIcon(
                      FontAwesomeIcons.xmark,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'إغلاق',
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required AppTheme theme,
    required bool isMobile,
  }) {
    return GestureDetector(
      onTapDown: (_) => _buttonAnimationController.forward(),
      onTapUp: (_) {
        _buttonAnimationController.reverse();
        onPressed();
      },
      onTapCancel: () => _buttonAnimationController.reverse(),
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, color: Colors.white, size: isMobile ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.appBarGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Card(
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              gradient: theme.appBarGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.star,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'عرض خاص',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      label: 'صورة ترويجية',
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(widget.imageUrl),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: InteractiveViewer(
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: ZoomIn(
                                duration: const Duration(milliseconds: 500),
                                child: CachedNetworkImage(
                                  imageUrl: widget.imageUrl,
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  fit: BoxFit.contain,
                                  placeholder:
                                      (context, url) => Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.8,
                                        height: 120,
                                        color: theme.cardBackground.withOpacity(
                                          0.5,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.8,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              theme.cardBackground,
                                              theme.cardBackground.withOpacity(
                                                0.8,
                                              ),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FaIcon(
                                              FontAwesomeIcons
                                                  .exclamationCircle,
                                              color: theme.primaryColor,
                                              size: 30,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'فشل في تحميل الصورة',
                                              style: GoogleFonts.cairo(
                                                color: theme.textColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardBackground.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.message,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGradientButton(
                          text:
                              widget.page == 'market'
                                  ? 'سجل الآن'
                                  : 'تعرف على المزيد',
                          icon: FontAwesomeIcons.infoCircle,
                          onPressed: () async {
                            if (widget.page == 'market') {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            } else if (widget.offerLink.isNotEmpty) {
                              final uri = Uri.parse(widget.offerLink);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'لا يمكن فتح الرابط',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          theme: theme,
                          isMobile: widget.isMobile,
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTapDown:
                              (_) => _buttonAnimationController.forward(),
                          onTapUp: (_) {
                            _buttonAnimationController.reverse();
                            widget.onClose();
                          },
                          onTapCancel:
                              () => _buttonAnimationController.reverse(),
                          child: ScaleTransition(
                            scale: _buttonScaleAnimation,
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
                              padding: const EdgeInsets.all(10),
                              child: FaIcon(
                                FontAwesomeIcons.xmark,
                                color: Colors.white,
                                size: widget.isMobile ? 18 : 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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

class HomeScreen extends StatefulWidget {
  final SupabaseConfig supabaseConfig;
  const HomeScreen({super.key, required this.supabaseConfig});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'الكل';
  int _currentNavIndex = 0;
  late AnimationController _drawerController;
  bool _showContactDrawer = false;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late ScrollController _scrollController;
  bool _hasShownScrollPopup = false;
  String? _lastPopupId;
  late Future<List<Map<String, dynamic>>> _newsFuture;
  bool _isLoading = true;

  final String secondarySupabaseUrl =
      'https://bzqzwkpnskkkiuabrjvh.supabase.co';

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: ThemeManager.animationDuration,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _drawerController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _drawerController, curve: Curves.easeOutCubic),
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _checkPopupShownStatus();
    _newsFuture = Future.value([]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPopupShownStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownScrollPopup = prefs.getBool('hasShownScrollPopup') ?? false;
    _lastPopupId = prefs.getString('lastPopupId');
  }

  void _onScroll() {
    if (_scrollController.offset > 50 &&
        !_hasShownScrollPopup &&
        _currentNavIndex == 0) {
      _hasShownScrollPopup = true;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('hasShownScrollPopup', true);
      });
    }
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _newsFuture = _fetchNews();
      await _showWelcomePopup();
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showWelcomePopup() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      try {
        final response =
            await widget.supabaseConfig.secondaryClient
                .from('popups')
                .select()
                .eq('is_active', true)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

        if (response != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withOpacity(0.5),
            builder:
                (context) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                      maxWidth:
                          MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width * 0.9
                              : 400,
                    ),
                    child: WelcomePopup(
                      isMobile: MediaQuery.of(context).size.width < 600,
                      imageUrl: response['image_url'] ?? '',
                      message: response['message'] ?? 'عرض خاص',
                      page: response['page'] ?? '',
                      offerLink: response['offer_link'] ?? '',
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                ),
          );
        }
      } catch (e) {
        print('Error fetching popup: $e');
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withOpacity(0.5),
          builder:
              (context) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                    maxWidth:
                        MediaQuery.of(context).size.width < 600
                            ? MediaQuery.of(context).size.width * 0.9
                            : 400,
                  ),
                  child: OnlineSupermarketSection(
                    isMobile: MediaQuery.of(context).size.width < 600,
                  ),
                ),
              ),
        );
      }
    }
  }

  void _showFabMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        final theme = ThemeManager().currentTheme;
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.secondaryTextColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomSheetOption(
                    icon: FontAwesomeIcons.envelope,
                    label: 'التواصل معنا',
                    gradient: theme.appBarGradient,
                    onTap: () {
                      Navigator.pop(context);
                      _toggleContactDrawer();
                    },
                  ),
                  _buildBottomSheetOption(
                    icon: FontAwesomeIcons.exclamationTriangle,
                    label: 'الطوارئ',
                    gradient: LinearGradient(
                      colors: [Colors.redAccent, Colors.red.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openEmergencyScreen();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    final theme = ThemeManager().currentTheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: FaIcon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleContactDrawer() {
    setState(() {
      _showContactDrawer = !_showContactDrawer;
      if (_showContactDrawer) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  void _openEmergencyScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyScreen()),
    );
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchBottomSheet(),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchNews() async {
    final restUrl = '$secondarySupabaseUrl/rest/v1';
    print('DEBUG: Fetching news using secondaryClient with URL: $restUrl');
    try {
      final response = await widget.supabaseConfig.secondaryClient
          .from('news')
          .select()
          .order('date', ascending: false);
      print('DEBUG: Fetched news response from secondaryClient: $response');
      return response as List<Map<String, dynamic>>;
    } catch (e, stackTrace) {
      print('DEBUG: Error fetching news from secondaryClient: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في جلب الأخبار: ${e.toString()}',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;

    print('DEBUG: Building HomeScreen');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (_isLoading) {
            return Scaffold(
              backgroundColor: theme.backgroundColor,
              body: Center(
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                  strokeWidth: 4,
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: theme.backgroundColor,
            body: Stack(
              children: [
                IndexedStack(
                  index: _currentNavIndex,
                  children: [
                    SafeArea(
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            expandedHeight: isMobile ? 230 : 260,
                            floating: true,
                            pinned: false,
                            snap: true,
                            flexibleSpace: FlexibleSpaceBar(
                              collapseMode: CollapseMode.parallax,
                              background: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: theme.appBarGradient,
                                    ),
                                  ),
                                  const ShimmeringWave(),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      40,
                                      16,
                                      16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'جاردينيا توداي',
                                              style: GoogleFonts.cairo(
                                                fontSize: isMobile ? 24 : 28,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Stack(
                                                children: [
                                                  FaIcon(
                                                    FontAwesomeIcons.bell,
                                                    color: Colors.white,
                                                    size: isMobile ? 24 : 28,
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    left: 0,
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const CompoundNewsPage(),
                                                  ),
                                                );
                                              },
                                              tooltip: 'الإشعارات',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'كل خدماتك في مكان واحد',
                                          style: GoogleFonts.cairo(
                                            fontSize: isMobile ? 15 : 17,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: _showSearchBottomSheet,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: TextField(
                                              enabled: false,
                                              style: GoogleFonts.cairo(
                                                fontSize: 15,
                                                color: theme.textColor,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'ابحث عن خدمة...',
                                                hintStyle: GoogleFonts.cairo(
                                                  color: theme
                                                      .secondaryTextColor
                                                      .withOpacity(0.7),
                                                  fontSize: 15,
                                                ),
                                                prefixIcon: FaIcon(
                                                  FontAwesomeIcons
                                                      .magnifyingGlass,
                                                  color: theme.primaryColor,
                                                  size: 18,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      height: 40,
                                      color: Colors.black.withOpacity(0.5),
                                      child: FutureBuilder<
                                        List<Map<String, dynamic>>
                                      >(
                                        future: _newsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                            );
                                          }
                                          if (snapshot.hasError ||
                                              !snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return Center(
                                              child: Text(
                                                'لا توجد أخبار متاحة',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            );
                                          }

                                          final newsText = snapshot.data!
                                              .map((news) {
                                                final title =
                                                    news['title']?.toString() ??
                                                    'غير معروف';
                                                final description =
                                                    news['description']
                                                        ?.toString() ??
                                                    'غير متوفر';
                                                final truncatedDescription =
                                                    description.length > 50
                                                        ? '${description.substring(0, 50)}...'
                                                        : description;
                                                return '$title: $truncatedDescription';
                                              })
                                              .join('  •  ');

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const CompoundNewsPage(),
                                                ),
                                              );
                                            },
                                            child: Marquee(
                                              text: newsText,
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              scrollAxis: Axis.horizontal,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              blankSpace: 20.0,
                                              velocity: 50.0,
                                              pauseAfterRound: const Duration(
                                                seconds: 1,
                                              ),
                                              startPadding: 10.0,
                                              accelerationDuration:
                                                  const Duration(seconds: 1),
                                              accelerationCurve: Curves.linear,
                                              decelerationDuration:
                                                  const Duration(
                                                    milliseconds: 500,
                                                  ),
                                              decelerationCurve: Curves.easeOut,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CarouselSection(isMobile: isMobile),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'خدمات الكمبوند',
                                            style: GoogleFonts.cairo(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: theme.textColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => AllServicesScreen(
                                                        favorites:
                                                            favoritesProvider
                                                                .favorites,
                                                        onFavoriteToggle:
                                                            favoritesProvider
                                                                .toggleFavorite,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                Text(
                                                  'عرض الكل',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                FaIcon(
                                                  FontAwesomeIcons.arrowLeft,
                                                  size: 14,
                                                  color: theme.primaryColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ServicesGrid(
                                        searchQuery: '',
                                        selectedCategory: _selectedCategory,
                                        favorites: favoritesProvider.favorites,
                                        onFavoriteToggle:
                                            favoritesProvider.toggleFavorite,
                                        limit: 6,
                                      ),
                                      const SizedBox(height: 16),
                                      OnlineServicesSection(isMobile: isMobile),
                                      const SizedBox(height: 16),
                                      OnlineSupermarketSection(
                                        isMobile: isMobile,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        ],
                      ),
                    ),
                    FavoritesScreen(
                      favorites: favoritesProvider.favorites,
                      onFavoriteToggle: favoritesProvider.toggleFavorite,
                      onBackToHome: () => setState(() => _currentNavIndex = 0),
                    ),
                    Container(),
                    const MoreScreen(),
                  ],
                ),
                if (_showContactDrawer)
                  ContactUsBottomSheet(
                    onClose: _toggleContactDrawer,
                    slideAnimation: _slideAnimation,
                    fadeAnimation: _fadeAnimation,
                  ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: theme.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentNavIndex,
                onTap: (index) {
                  if (index == 2) {
                    _showSearchBottomSheet();
                  } else {
                    setState(() => _currentNavIndex = index);
                  }
                },
                selectedItemColor: theme.primaryColor,
                unselectedItemColor: theme.secondaryTextColor,
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
                items: [
                  const BottomNavigationBarItem(
                    icon: FaIcon(FontAwesomeIcons.house, size: 22),
                    label: 'الرئيسية',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        const FaIcon(FontAwesomeIcons.heart, size: 22),
                        if (favoritesProvider.favorites.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                favoritesProvider.favorites.length.toString(),
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'المفضلة',
                  ),
                  const BottomNavigationBarItem(
                    icon: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 22),
                    label: 'البحث',
                  ),
                  const BottomNavigationBarItem(
                    icon: FaIcon(FontAwesomeIcons.ellipsis, size: 22),
                    label: 'المزيد',
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _showFabMenuBottomSheet,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: theme.appBarGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.plus,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              tooltip: 'فتح القائمة',
            ),
          );
        },
      ),
    );
  }
}

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  _SearchBottomSheetState createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  String _searchQuery = '';
  List<String> _recentSearches = [];
  List<String> _lastVisitedServices = [];
  String _selectedCategory = 'الكل';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadLastVisitedServices();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutSine),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.bounceOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      if (mounted) {
        setState(() {
          _recentSearches = searches;
        });
      }
    } catch (e) {
      print('Error loading recent searches: $e');
      _showErrorSnackBar('خطأ في تحميل عمليات البحث الأخيرة');
    }
  }

  Future<void> _loadLastVisitedServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final services = prefs.getStringList('last_visited_services') ?? [];
      if (mounted) {
        setState(() {
          _lastVisitedServices = services;
        });
      }
    } catch (e) {
      print('Error loading last visited services: $e');
      _showErrorSnackBar('خطأ في تحميل الخدمات التي تم زيارتها');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _recentSearches.remove(query);
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) _recentSearches.removeLast();
          prefs.setStringList('recent_searches', _recentSearches);
        });
      }
    } catch (e) {
      print('Error saving recent search: $e');
      _showErrorSnackBar('خطأ في حفظ عملية البحث');
    }
  }

  Future<void> _saveLastVisitedService(String serviceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _lastVisitedServices.remove(serviceName);
          _lastVisitedServices.insert(0, serviceName);
          if (_lastVisitedServices.length > 5)
            _lastVisitedServices.removeLast();
          prefs.setStringList('last_visited_services', _lastVisitedServices);
        });
      }
    } catch (e) {
      print('Error saving last visited service: $e');
      _showErrorSnackBar('خطأ في حفظ الخدمة التي تم زيارتها');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _recentSearches.clear();
          prefs.setStringList('recent_searches', _recentSearches);
        });
      }
    } catch (e) {
      print('Error clearing recent searches: $e');
      _showErrorSnackBar('خطأ في مسح عمليات البحث الأخيرة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Text(
                                  'البحث',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 24 : 28,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.xmark,
                                    color: theme.textColor,
                                    size: isMobile ? 22 : 24,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  tooltip: 'إغلاق',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            ThemeManager.cardPadding,
                          ),
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade100],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                key: _textFieldKey,
                                controller: _searchController,
                                focusNode: _focusNode,
                                autofocus: true,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن خدمة...',
                                  hintStyle: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: FadeTransition(
                                    opacity: Tween<double>(
                                      begin: 0.0,
                                      end: 1.0,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: const Interval(
                                          0.4,
                                          0.8,
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                    ),
                                    child: FaIcon(
                                      FontAwesomeIcons.magnifyingGlass,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon:
                                      _searchQuery.isNotEmpty
                                          ? ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.0,
                                              end: 1.0,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: _animationController,
                                                curve: const Interval(
                                                  0.6,
                                                  0.9,
                                                  curve: Curves.bounceOut,
                                                ),
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: FaIcon(
                                                FontAwesomeIcons.xmark,
                                                color: Colors.black,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                if (mounted) {
                                                  setState(
                                                    () => _searchQuery = '',
                                                  );
                                                }
                                              },
                                            ),
                                          )
                                          : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                onChanged: (value) {
                                  _debounce?.cancel();
                                  _debounce = Timer(
                                    const Duration(milliseconds: 300),
                                    () {
                                      if (mounted) {
                                        setState(() => _searchQuery = value);
                                      }
                                    },
                                  );
                                },
                                onSubmitted:
                                    (value) => _saveRecentSearch(value),
                                cursorColor: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              ThemeManager.cardPadding,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_recentSearches.isNotEmpty) ...[
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: const Interval(
                                            0.3,
                                            0.7,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'عمليات البحث الأخيرة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: theme.textColor,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _clearRecentSearches,
                                            child: Text(
                                              'مسح الكل',
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          _recentSearches.asMap().entries.map((
                                            entry,
                                          ) {
                                            final index = entry.key;
                                            final search = entry.value;
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(0, 0.2),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: _animationController,
                                                  curve: Interval(
                                                    0.4 + (index * 0.05),
                                                    0.8 + (index * 0.05),
                                                    curve: Curves.easeOutCubic,
                                                  ),
                                                ),
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  _searchController.text =
                                                      search;
                                                  if (mounted) {
                                                    setState(
                                                      () =>
                                                          _searchQuery = search,
                                                    );
                                                  }
                                                  _saveRecentSearch(search);
                                                },
                                                child: Chip(
                                                  label: Text(
                                                    search,
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 14,
                                                      color: theme.textColor,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      theme.cardBackground,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    side: BorderSide(
                                                      color: theme.primaryColor
                                                          .withOpacity(0.2),
                                                    ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  elevation: 2,
                                                  shadowColor: Colors.black
                                                      .withOpacity(0.1),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ] else ...[
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: const Interval(
                                            0.3,
                                            0.7,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'لا توجد عمليات بحث سابقة',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          color: theme.secondaryTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                if (_lastVisitedServices.isNotEmpty) ...[
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: const Interval(
                                            0.4,
                                            0.8,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'الخدمات التي تم زيارتها مسبقًا',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_lastVisitedServices.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ThemeManager.cardPadding,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.70,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final serviceName = _lastVisitedServices[index];
                                final service = ServicesGrid.services
                                    .firstWhere(
                                      (s) => s['name'] == serviceName,
                                      orElse: () => {},
                                    );
                                if (service.isEmpty)
                                  return const SizedBox.shrink();
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        0.5 + (index * 0.05),
                                        0.9 + (index * 0.05),
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: ServiceCard(
                                      name: service['name'],
                                      icon: service['icon'],
                                      description: service['description'],
                                      category: service['category'],
                                      route: service['route'],
                                      cardColor:
                                          theme.cardColors[index %
                                              theme.cardColors.length],
                                      isFavorite:
                                          Provider.of<FavoritesProvider>(
                                            context,
                                          ).favorites.contains(service['name']),
                                      onFavoriteToggle: () {
                                        Provider.of<FavoritesProvider>(
                                          context,
                                          listen: false,
                                        ).toggleFavorite(service['name']);
                                      },
                                      onTap:
                                          () => _saveLastVisitedService(
                                            service['name'],
                                          ),
                                    ),
                                  ),
                                );
                              }, childCount: _lastVisitedServices.length),
                            ),
                          ),
                      ],
                      if (_searchQuery.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.all(
                            ThemeManager.cardPadding,
                          ),
                          sliver: ServicesGrid(
                            searchQuery: _searchQuery,
                            selectedCategory: _selectedCategory,
                            favorites:
                                Provider.of<FavoritesProvider>(
                                  context,
                                ).favorites,
                            onFavoriteToggle: (name) {
                              Provider.of<FavoritesProvider>(
                                context,
                                listen: false,
                              ).toggleFavorite(name);
                            },
                            onServiceTap: _saveLastVisitedService,
                            useSliver: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ServicesGrid extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final Set<String> favorites;
  final Function(String) onFavoriteToggle;
  final Function(String)? onServiceTap;
  final int? limit;
  final bool useSliver;

  const ServicesGrid({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.favorites,
    required this.onFavoriteToggle,
    this.onServiceTap,
    this.limit,
    this.useSliver = false,
  });

  static const List<Map<String, dynamic>> services = [
    {
      'name': 'السوبر ماركت',
      'description': 'التسوق',
      'category': 'التسوق',
      'route': '/supermarkets',
      'keywords': ['تسوق', 'بقالة', 'مواد غذائية', 'سوبر ماركت'],
      'icon': FontAwesomeIcons.cartShopping,
    },
    {
      'name': 'الصيدليات',
      'description': 'الصيدلية',
      'category': 'الصحة',
      'route': '/pharmacies',
      'keywords': ['أدوية', 'صيدلية', 'طب', 'مستلزمات طبية'],
      'icon': FontAwesomeIcons.prescriptionBottleMedical,
    },
    {
      'name': 'الحضانات',
      'description': 'الحضانات',
      'category': 'الصحة',
      'route': '/Nursury',
      'keywords': ['أطفال', 'حضانة', 'رعاية', 'تعليم مبكر'],
      'icon': FontAwesomeIcons.child,
    },
    {
      'name': 'المساجد',
      'description': 'المساجد',
      'category': 'الخدمات',
      'route': '/mosque',
      'keywords': ['مسجد', 'صلاة', 'أذان', 'عبادة'],
      'icon': FontAwesomeIcons.mosque,
    },
    {
      'name': 'العمائر',
      'description': 'العمائر',
      'category': 'الخدمات',
      'route': '/building',
      'keywords': ['عمارة', 'مباني', 'سكن', 'إقامة'],
      'icon': FontAwesomeIcons.building,
    },
    {
      'name': 'ماكينة الصراف',
      'description': 'ماكينة الصراف',
      'category': 'الخدمات',
      'route': '/atm',
      'keywords': ['صراف', 'ماكينة', 'نقود', 'سحب'],
      'icon': FontAwesomeIcons.moneyCheckDollar,
    },
    {
      'name': 'البنوك',
      'description': 'البنك',
      'category': 'الخدمات',
      'route': '/bank',
      'keywords': ['بنك', 'مصرف', 'خدمات مالية', 'حساب'],
      'icon': FontAwesomeIcons.buildingColumns,
    },
    {
      'name': 'البوابات',
      'description': 'البوابات',
      'category': 'الخدمات',
      'route': '/gates',
      'keywords': ['بوابة', 'مدخل', 'خروج', 'أمن'],
      'icon': FontAwesomeIcons.doorOpen,
    },
    {
      'name': 'شركة الإدارة',
      'description': 'شركة الإدارة',
      'category': 'الخدمات',
      'route': '/Edara',
      'keywords': ['إدارة', 'شركة', 'تنظيم', 'صيانة'],
      'icon': FontAwesomeIcons.buildingUser,
    },
    {
      'name': 'الكهرباء',
      'description': 'الكهرباء',
      'category': 'الخدمات',
      'route': '/Electricity',
      'keywords': ['كهرباء', 'عداد', 'طاقة', 'فاتورة'],
      'icon': FontAwesomeIcons.bolt,
    },
    {
      'name': 'المياه',
      'description': 'المياه',
      'category': 'الخدمات',
      'route': '/water',
      'keywords': ['مياه', 'ماء', 'عداد', 'فاتورة'],
      'icon': FontAwesomeIcons.droplet,
    },
    {
      'name': 'الغاز',
      'description': 'الغاز',
      'category': 'الخدمات',
      'route': '/gaz',
      'keywords': ['غاز', 'عداد', 'فاتورة', 'توصيل'],
      'icon': FontAwesomeIcons.fire,
    },
    {
      'name': 'المخبوزات',
      'description': 'المخبوزات',
      'category': 'التسوق',
      'route': '/BakeriesScreen',
      'keywords': ['مخبوزات', 'خبز', 'معجنات', 'فرن'],
      'icon': FontAwesomeIcons.breadSlice,
    },
    {
      'name': 'الخضروات والفواكه',
      'description': 'الخضروات والفواكه',
      'category': 'التسوق',
      'route': '/VegetablesFruitsScreen',
      'keywords': ['خضروات', 'فواكه', 'طازج', 'عضوي'],
      'icon': FontAwesomeIcons.carrot,
    },
    {
      'name': 'المطاعم والكافيهات',
      'description': 'المطاعم والكافيهات',
      'category': 'التسوق',
      'route': '/RestaurantsScreen',
      'keywords': [
        'أكل',
        'فطور',
        'غداء',
        'عشاء',
        'ساندويتشات',
        'مطعم',
        'كافيه',
        'طعام',
      ],
      'icon': FontAwesomeIcons.bowlFood,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;
    final filteredServices =
        services.where((service) {
          final query = searchQuery.toLowerCase();
          final matchesSearch =
              service['name'].toString().toLowerCase().contains(query) ||
              (service['keywords'] as List<String>).any(
                (keyword) => keyword.toLowerCase().contains(query),
              );
          final matchesCategory =
              selectedCategory == 'الكل' ||
              service['category'] == selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

    if (filteredServices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            'لا توجد خدمات مطابقة',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final displayServices =
        limit != null
            ? filteredServices.take(limit!).toList()
            : filteredServices;

    if (useSliver) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeManager.cardPadding,
          vertical: ThemeManager.cardPadding,
        ),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.70,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final service = displayServices[index];
            return FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: ServiceCard(
                name: service['name'],
                icon: service['icon'],
                description: service['description'],
                category: service['category'],
                route: service['route'],
                cardColor: theme.cardColors[index % theme.cardColors.length],
                isFavorite: favorites.contains(service['name']),
                onFavoriteToggle: () => onFavoriteToggle(service['name']),
                onTap: () => onServiceTap?.call(service['name']),
              ),
            );
          }, childCount: displayServices.length),
        ),
      );
    }

    const int itemsPerPage = 6;
    final pages = (displayServices.length / itemsPerPage).ceil();
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemCount: pages,
        itemBuilder: (context, pageIndex) {
          final startIndex = pageIndex * itemsPerPage;
          final endIndex =
              (startIndex + itemsPerPage) > displayServices.length
                  ? displayServices.length
                  : (startIndex + itemsPerPage);
          final pageServices = displayServices.sublist(startIndex, endIndex);

          return FadeInRight(
            duration: Duration(milliseconds: 300 + (pageIndex * 100)),
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.65,
                ),
                itemCount: pageServices.length,
                itemBuilder: (context, index) {
                  final service = pageServices[index];
                  return ServiceCard(
                    name: service['name'],
                    icon: service['icon'],
                    description: service['description'],
                    category: service['category'],
                    route: service['route'],
                    cardColor:
                        theme.cardColors[(startIndex + index) %
                            theme.cardColors.length],
                    isFavorite: favorites.contains(service['name']),
                    onFavoriteToggle: () => onFavoriteToggle(service['name']),
                    onTap: () => onServiceTap?.call(service['name']),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final String description;
  final String category;
  final String route;
  final Color cardColor;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.route,
    required this.cardColor,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;

    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: FaIcon(icon, size: 22, color: theme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: theme.secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: FaIcon(
                  isFavorite
                      ? FontAwesomeIcons.solidHeart
                      : FontAwesomeIcons.heart,
                  color:
                      isFavorite ? Colors.redAccent : theme.secondaryTextColor,
                  size: 18,
                ),
                onPressed: onFavoriteToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const ContactOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: FaIcon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              FaIcon(
                FontAwesomeIcons.arrowLeft,
                size: 18,
                color: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

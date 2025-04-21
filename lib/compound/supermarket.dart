import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

import '../main.dart';
import 'core/config/supabase_config.dart';
import 'homescreen/thememanager.dart';

class SupermarketsScreen extends StatefulWidget {
  const SupermarketsScreen({super.key});

  @override
  _SupermarketsScreenState createState() => _SupermarketsScreenState();
}

class _SupermarketsScreenState extends State<SupermarketsScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  bool _showDeliveryOnly = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndShowPopup();
    });

    _preloadPopupImage();

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
    _searchController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _preloadPopupImage() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('popups')
          .select('image_url')
          .eq('is_active', true)
          .eq('page', 'market');

      if (response.isNotEmpty) {
        final imageUrl = response[0]['image_url'] as String;
        await precacheImage(CachedNetworkImageProvider(imageUrl), context);
      }
    } catch (e) {
      print('DEBUG: Error preloading image: $e');
    }
  }

  Future<void> _fetchAndShowPopup() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('popups')
          .select('image_url, message, offer_link')
          .eq('is_active', true)
          .eq('page', 'market');

      if (response.isNotEmpty) {
        final popup = response[0];
        final imageUrl = popup['image_url'] as String;
        final message = popup['message'] as String;
        final offerLink = popup['offer_link'] as String?;
        print('DEBUG: SupermarketsScreen fetched popup - imageUrl: $imageUrl, message: $message, offerLink: $offerLink');

        if (mounted) {
          _showPopupDialog(imageUrl, message, offerLink);
        }
      } else {
        print('DEBUG: SupermarketsScreen - No active popups found for page: market');
      }
    } catch (e) {
      if (mounted) {
        print('DEBUG: SupermarketsScreen error fetching popup: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching popup: $e')),
        );
      }
    }
  }

  void _showFullScreenImage(String imageUrl) {
    final theme = ThemeManager().currentTheme;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
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
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
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

  void _showPopupDialog(String imageUrl, String message, String? offerLink) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              FadeIn(
                duration: const Duration(milliseconds: 300),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: theme.appBarGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? 300 : 400,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: SingleChildScrollView(
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
                              onTap: () => _showFullScreenImage(imageUrl),
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
                                        imageUrl: imageUrl,
                                        width: MediaQuery.of(context).size.width * 0.6,
                                        fit: BoxFit.contain,
                                        placeholder: (context, url) => Container(
                                          width: MediaQuery.of(context).size.width * 0.6,
                                          height: 120,
                                          color: theme.cardBackground.withOpacity(0.5),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: MediaQuery.of(context).size.width * 0.6,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                theme.cardBackground,
                                                theme.cardBackground.withOpacity(0.8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.exclamationCircle,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.cardBackground.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message,
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
                                text: 'تعرف على المزيد',
                                icon: FontAwesomeIcons.infoCircle,
                                onPressed: () async {
                                  if (offerLink != null && await canLaunchUrl(Uri.parse(offerLink))) {
                                    await launchUrl(Uri.parse(offerLink));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'لا يمكن فتح الرابط.',
                                          style: GoogleFonts.cairo(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                theme: theme,
                                isMobile: isMobile,
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTapDown: (_) {
                                  _buttonAnimationController.forward();
                                },
                                onTapUp: (_) {
                                  _buttonAnimationController.reverse();
                                  Navigator.of(context).pop();
                                },
                                onTapCancel: () {
                                  _buttonAnimationController.reverse();
                                },
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
                                      size: isMobile ? 18 : 20,
                                    ),
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
              ),
            ],
          ),
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
      onTapDown: (_) {
        _buttonAnimationController.forward();
      },
      onTapUp: (_) {
        _buttonAnimationController.reverse();
        onPressed();
      },
      onTapCancel: () {
        _buttonAnimationController.reverse();
      },
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
              FaIcon(
                icon,
                color: Colors.white,
                size: isMobile ? 18 : 20,
              ),
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

  Future<List<Map<String, dynamic>>> _fetchSupermarkets(BuildContext context) async {
    final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
    try {
      final response = await supabaseConfig.secondaryClient.from('supermarkets').select();
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في جلب البيانات. تحقق من الاتصال بالإنترنت.',
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
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isMobile ? 200 : 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: theme.appBarGradient,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElasticIn(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              'السوبرماركت',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 28 : 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInDown(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              'تسوق بذكاء، ابحث عن أقرب السوبرماركت',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 16 : 18,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.cardBackground.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                                decoration: InputDecoration(
                                  hintText: 'ابحث بالاسم أو المنطقة...',
                                  hintStyle: GoogleFonts.cairo(color: theme.secondaryTextColor),
                                  prefixIcon: FaIcon(
                                    FontAwesomeIcons.magnifyingGlass,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons.xmark,
                                      color: theme.secondaryTextColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: FadeInLeft(
                  duration: ThemeManager.animationDuration,
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'رجوع',
                  ),
                ),
                actions: [
                  FadeInRight(
                    duration: ThemeManager.animationDuration,
                    child: IconButton(
                      icon: FaIcon(
                        _showDeliveryOnly ? FontAwesomeIcons.truck : FontAwesomeIcons.store,
                        color: Colors.white,
                        size: 24,
                      ),
                      tooltip: _showDeliveryOnly ? 'إظهار الكل' : 'إظهار التوصيل فقط',
                      onPressed: () {
                        setState(() => _showDeliveryOnly = !_showDeliveryOnly);
                      },
                    ),
                  ),
                ],
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(ThemeManager.cardPadding),
                sliver: SliverFillRemaining(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchSupermarkets(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            snapshot.hasError ? 'خطأ في جلب البيانات' : 'لا توجد سوبرماركت متاحة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final filteredSupermarkets = snapshot.data!.where((supermarket) {
                        final name = supermarket['name'].toString().toLowerCase();
                        final zone = supermarket['zone'].toString().toLowerCase();
                        final query = _searchQuery.toLowerCase();
                        final matchesQuery = name.contains(query) || zone.contains(query);
                        final matchesDelivery = !_showDeliveryOnly || supermarket['delivery'] == true;
                        return matchesQuery && matchesDelivery;
                      }).toList();

                      if (filteredSupermarkets.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد سوبرماركت مطابقة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isMobile ? 400 : 380,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: isMobile ? 1.4 : 0.85,
                        ),
                        itemCount: filteredSupermarkets.length,
                        itemBuilder: (context, index) {
                          final supermarket = filteredSupermarkets[index];
                          return FadeInUp(
                            duration: Duration(milliseconds: 400 + (index * 150)),
                            child: SupermarketCard(
                              supermarket: supermarket,
                              cardColor: theme.cardColors[index % theme.cardColors.length],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SupermarketCard extends StatefulWidget {
  final Map<String, dynamic> supermarket;
  final Color cardColor;

  const SupermarketCard({
    super.key,
    required this.supermarket,
    required this.cardColor,
  });

  @override
  _SupermarketCardState createState() => _SupermarketCardState();
}

class _SupermarketCardState extends State<SupermarketCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parseContacts(dynamic contacts) {
    try {
      if (contacts is List<dynamic>) {
        return contacts.cast<String>();
      } else if (contacts is String) {
        final decoded = jsonDecode(contacts);
        if (decoded is List<dynamic>) {
          return decoded.cast<String>();
        }
      }
    } catch (e) {
      print('Error parsing contacts: $e');
    }
    return [];
  }

  void _showContactBottomSheet(BuildContext context, List<String> contacts, String type) {
    final theme = ThemeManager().currentTheme;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius)),
      ),
      backgroundColor: theme.cardBackground,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AnimatedPadding(
            duration: ThemeManager.animationDuration,
            padding: const EdgeInsets.all(ThemeManager.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اختر ${type == 'phone' ? 'رقم الهاتف' : 'رقم واتساب'}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor,
                      ),
                    ),
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        color: theme.secondaryTextColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: theme.primaryColor.withOpacity(0.1),
                              child: FaIcon(
                                type == 'phone' ? FontAwesomeIcons.phone : FontAwesomeIcons.whatsapp,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              contact,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                              ),
                            ),
                            onTap: () => _launchContact(context, contact, type),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchContact(BuildContext context, String contact, String type, {String? name}) async {
    String url;
    if (type == 'phone') {
      url = 'tel:$contact';
    } else {
      final message = Uri.encodeComponent(
        'مرحبا من تطبيق جاردينيا توداي اود الاستفسار عن خدمات سوبر ماركت ${name ?? widget.supermarket['name'] ?? 'غير معروف'} 😊\n📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/',
      );
      url = 'https://wa.me/$contact?text=$message';
    }

    bool isLoading = true;
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا يمكن فتح $type.',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _launchMap(BuildContext context, String url) async {
    bool isLoading = true;
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا يمكن فتح الخريطة.',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _shareSupermarketDetails() {
    final name = widget.supermarket['name']?.toString() ?? 'غير معروف';
    final zone = widget.supermarket['zone']?.toString() ?? 'غير محدد';
    final phones = _parseContacts(widget.supermarket['phone']);
    final whatsapps = _parseContacts(widget.supermarket['whatsapp']);
    final location = widget.supermarket['location']?.toString() ?? 'غير متوفر';
    final delivery = widget.supermarket['delivery'] == true ? 'متاح' : 'غير متاح';

    final phonesText = phones.isNotEmpty ? '📞 ${phones.join(", ")}' : '📞 غير متوفر';
    final whatsappsText = whatsapps.isNotEmpty ? '💬 ${whatsapps.join(", ")}' : '💬 غير متوفر';

    final shareText = '''
🌟 تفاصيل السوبرماركت من جاردينيا توداي 🌟
🏪 $name
📍 $zone
$phonesText
$whatsappsText
🗺️ $location
🚚 دليفري: $delivery
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

    Share.share(shareText.trim(), subject: 'تفاصيل سوبرماركت: $name');
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius)),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DetailsBottomSheet(
          supermarket: widget.supermarket,
          phones: _parseContacts(widget.supermarket['phone']),
          whatsapps: _parseContacts(widget.supermarket['whatsapp']),
          onPhone: (contact) => _launchContact(context, contact, 'phone'),
          onWhatsApp: (contact) => _launchContact(context, contact, 'whatsapp'),
          onMap: () => _launchMap(context, widget.supermarket['location']?.toString() ?? ''),
          onShare: _shareSupermarketDetails,
          showContactBottomSheet: (contacts, type) => _showContactBottomSheet(context, contacts, type),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hasDelivery = widget.supermarket['delivery'] == true;

    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          _showDetailsBottomSheet(context);
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  widget.cardColor,
                  widget.cardColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  left: -30,
                  child: Opacity(
                    opacity: 0.06,
                    child: FaIcon(
                      FontAwesomeIcons.cartShopping,
                      size: 120,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(ThemeManager.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElasticIn(
                              duration: ThemeManager.animationDuration,
                              child: Text(
                                widget.supermarket['name']?.toString() ?? 'غير معروف',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 22 : 24,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textColor,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          ZoomIn(
                            duration: ThemeManager.animationDuration,
                            child: CircleAvatar(
                              radius: isMobile ? 24 : 28,
                              backgroundColor: theme.primaryColor.withOpacity(0.1),
                              child: FaIcon(
                                FontAwesomeIcons.cartShopping,
                                size: isMobile ? 22 : 26,
                                color: theme.primaryColor,
                                semanticLabel: 'أيقونة السوبرماركت',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.mapMarkerAlt,
                              size: isMobile ? 18 : 20,
                              color: theme.primaryColor,
                              semanticLabel: 'موقع',
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.supermarket['zone']?.toString() ?? 'غير محدد',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 15 : 16,
                                  color: theme.secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.truck,
                              size: isMobile ? 18 : 20,
                              color: theme.primaryColor,
                              semanticLabel: 'توصيل',
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'دليفري: ${hasDelivery ? 'متاح' : 'غير متاح'}',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 15 : 16,
                                color: hasDelivery ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: theme.appBarGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.infoCircle,
                                size: isMobile ? 18 : 20,
                                color: Colors.white,
                                semanticLabel: 'التفاصيل',
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'التفاصيل',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
    );
  }
}

class DetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> supermarket;
  final List<String> phones;
  final List<String> whatsapps;
  final Function(String) onPhone;
  final Function(String) onWhatsApp;
  final VoidCallback onMap;
  final VoidCallback onShare;
  final Function(List<String>, String) showContactBottomSheet;

  const DetailsBottomSheet({
    super.key,
    required this.supermarket,
    required this.phones,
    required this.whatsapps,
    required this.onPhone,
    required this.onWhatsApp,
    required this.onMap,
    required this.onShare,
    required this.showContactBottomSheet,
  });

  @override
  _DetailsBottomSheetState createState() => _DetailsBottomSheetState();
}

class _DetailsBottomSheetState extends State<DetailsBottomSheet> with TickerProviderStateMixin {
  late AnimationController _sheetController;
  late Animation<Offset> _sheetAnimation;
  late List<AnimationController> _buttonControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _translateAnimations;

  @override
  void initState() {
    super.initState();

    _sheetController = AnimationController(
      vsync: this,
      duration: ThemeManager.animationDuration,
    );
    _sheetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.decelerate),
    );

    _buttonControllers = List.generate(
      4,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _scaleAnimations = _buttonControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();
    _fadeAnimations = _buttonControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();
    _translateAnimations = _buttonControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 20),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    _sheetController.forward();
    for (int i = 0; i < _buttonControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 + (i * 50)), () {
        if (mounted) {
          _buttonControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    for (var controller in _buttonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _closeSheet() {
    for (var controller in _buttonControllers.reversed) {
      controller.reverse();
    }
    _sheetController.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _sheetController,
        builder: (context, child) {
          return SlideTransition(
            position: _sheetAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.cardBackground,
                    theme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius)),
              ),
              child: AnimatedPadding(
                duration: ThemeManager.animationDuration,
                padding: const EdgeInsets.all(ThemeManager.cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElasticIn(
                            duration: ThemeManager.animationDuration,
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: theme.primaryColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.supermarket['name']?.toString() ?? 'غير معروف',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 22 : 24,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        Spin(
                          duration: ThemeManager.animationDuration,
                          child: FloatingActionButton(
                            onPressed: _closeSheet,
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
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.phones.isNotEmpty)
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: _buttonControllers[0],
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: _translateAnimations[0].value,
                                      child: FadeTransition(
                                        opacity: _fadeAnimations[0],
                                        child: ScaleTransition(
                                          scale: _scaleAnimations[0],
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              FloatingActionButton(
                                                onPressed: () {
                                                  if (widget.phones.length > 1) {
                                                    widget.showContactBottomSheet(widget.phones, 'phone');
                                                  } else {
                                                    widget.onPhone(widget.phones.first);
                                                  }
                                                },
                                                backgroundColor: theme.primaryColor,
                                                elevation: 2,
                                                child: FaIcon(
                                                  FontAwesomeIcons.phone,
                                                  size: isMobile ? 24 : 28,
                                                  color: Colors.white,
                                                  semanticLabel: 'التواصل تليفون',
                                                ),
                                                tooltip: 'التواصل تليفون',
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'التواصل تليفون',
                                                style: GoogleFonts.cairo(
                                                  fontSize: isMobile ? 12 : 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.textColor,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (widget.whatsapps.isNotEmpty)
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: _buttonControllers[1],
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: _translateAnimations[1].value,
                                      child: FadeTransition(
                                        opacity: _fadeAnimations[1],
                                        child: ScaleTransition(
                                          scale: _scaleAnimations[1],
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              FloatingActionButton(
                                                onPressed: () {
                                                  if (widget.whatsapps.length > 1) {
                                                    widget.showContactBottomSheet(widget.whatsapps, 'whatsapp');
                                                  } else {
                                                    widget.onWhatsApp(widget.whatsapps.first);
                                                  }
                                                },
                                                backgroundColor: theme.accentColor,
                                                elevation: 2,
                                                child: FaIcon(
                                                  FontAwesomeIcons.whatsapp,
                                                  size: isMobile ? 24 : 28,
                                                  color: Colors.white,
                                                  semanticLabel: 'التواصل واتساب',
                                                ),
                                                tooltip: 'التواصل واتساب',
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'التواصل واتساب',
                                                style: GoogleFonts.cairo(
                                                  fontSize: isMobile ? 12 : 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.textColor,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _buttonControllers[2],
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: _translateAnimations[2].value,
                                    child: FadeTransition(
                                      opacity: _fadeAnimations[2],
                                      child: ScaleTransition(
                                        scale: _scaleAnimations[2],
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            FloatingActionButton(
                                              onPressed: widget.onMap,
                                              backgroundColor: theme.primaryColor,
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.map,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
                                                semanticLabel: 'موقع الماركت على الخريطه',
                                              ),
                                              tooltip: 'موقع الماركت على الخريطه',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'موقع الماركت على الخريطه',
                                              style: GoogleFonts.cairo(
                                                fontSize: isMobile ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _buttonControllers[3],
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: _translateAnimations[3].value,
                                    child: FadeTransition(
                                      opacity: _fadeAnimations[3],
                                      child: ScaleTransition(
                                        scale: _scaleAnimations[3],
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            FloatingActionButton(
                                              onPressed: widget.onShare,
                                              backgroundColor: theme.accentColor,
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.share,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
                                                semanticLabel: 'مشاركة',
                                              ),
                                              tooltip: 'مشاركة',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'مشاركة',
                                              style: GoogleFonts.cairo(
                                                fontSize: isMobile ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
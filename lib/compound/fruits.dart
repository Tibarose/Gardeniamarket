import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'homescreen/thememanager.dart';

class Market {
  final String photo;
  final String name;
  final String zone;
  final String location;
  final List<String> phone;
  final List<String> whatsapp;
  final bool delivery;

  Market({
    required this.photo,
    required this.name,
    required this.zone,
    required this.location,
    required this.phone,
    required this.whatsapp,
    required this.delivery,
  });

  Map<String, dynamic> toMap() {
    return {
      'photo': photo,
      'name': name,
      'zone': zone,
      'location': location,
      'phone': phone,
      'whatsapp': whatsapp,
      'delivery': delivery,
    };
  }
}

class VegetablesFruitsScreen extends StatefulWidget {
  const VegetablesFruitsScreen({super.key});

  @override
  _VegetablesFruitsScreenState createState() => _VegetablesFruitsScreenState();
}

class _VegetablesFruitsScreenState extends State<VegetablesFruitsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Market> markets = [
    Market(
      photo: 'https://i.imghippo.com/files/ialA9437NIg.png',
      name: 'جمله ماركت',
      zone: 'زوون 1',
      location: 'https://maps.app.goo.gl/ukrXP24GFrni45SW6',
      phone: ['01111955349', '01111955238'],
      whatsapp: [],
      delivery: true,
    ),
    Market(
      photo: 'https://i.imghippo.com/files/ialA9437NIg.png',
      name: 'حياه جاردينيا',
      zone: 'زوون 2',
      location: 'https://maps.app.goo.gl/AZZv73ofhhBkLGUX8',
      phone: ['01122270102', '01122270104'],
      whatsapp: ['201122270102', '201122270104'],
      delivery: true,
    ),
    Market(
      photo: 'https://i.imghippo.com/files/ialA9437NIg.png',
      name: 'الطيب',
      zone: 'زوون 4',
      location: 'https://maps.app.goo.gl/7W8VUBsLXBX7vYm26',
      phone: ['01126770032', '01126770034', '01126770036'],
      whatsapp: ['201126770032', '201126770034', '201126770036'],
      delivery: true,
    ),
    Market(
      photo: 'https://i.imghippo.com/files/ialA9437NIg.png',
      name: 'مزارع ندى',
      zone: 'زوون 5',
      location: 'https://maps.app.goo.gl/HmYxmuAKBvYfNuMw6',
      phone: ['01126489961', '01070291000', '01070293000'],
      whatsapp: [],
      delivery: true,
    ),
    Market(
      photo: 'https://i.imghippo.com/files/ialA9437NIg.png',
      name: 'اسواق الجمله',
      zone: 'زوون 8',
      location: 'https://maps.app.goo.gl/kFhY5Cx652Q1LS529',
      phone: ['01080071425', '01154903132', '01154904115'],
      whatsapp: ['201080071425', '201154903132'],
      delivery: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final filteredMarkets = markets.where((market) {
      final name = market.name.toLowerCase();
      final zone = market.zone.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || zone.contains(query);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                              'الخضروات والفواكه',
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
                              'تسوق أفضل المنتجات الطازجة بسهولة',
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
                                borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 12),
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
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(ThemeManager.cardPadding),
                sliver: SliverToBoxAdapter(
                  child: filteredMarkets.isEmpty
                      ? Center(
                    child: Text(
                      'لا توجد أسواق مطابقة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: theme.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                      : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isMobile ? 400 : 380,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: isMobile ? 1.4 : 0.85,
                    ),
                    itemCount: filteredMarkets.length,
                    itemBuilder: (context, index) {
                      final market = filteredMarkets[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        child: MarketCard(
                          market: market.toMap(),
                          cardColor: theme.cardColors[index % theme.cardColors.length],
                        ),
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

class MarketCard extends StatefulWidget {
  final Map<String, dynamic> market;
  final Color cardColor;

  const MarketCard({
    super.key,
    required this.market,
    required this.cardColor,
  });

  @override
  _MarketCardState createState() => _MarketCardState();
}

class _MarketCardState extends State<MarketCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Previously AppConstants.scaleAnimationDuration
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

  void _launchUrl(BuildContext context, String? url, String errorMessage) async {
    final theme = ThemeManager().currentTheme;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح الرابط',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ: $e',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _shareMarketDetails() {
    final name = widget.market['name']?.toString() ?? 'غير معروف';
    final zone = widget.market['zone']?.toString() ?? 'غير محدد';
    final location = widget.market['location']?.toString() ?? 'غير متوفر';
    final phone = (widget.market['phone'] as List<dynamic>?)?.join(', ') ?? 'غير متوفر';
    final delivery = widget.market['delivery'] == true ? 'متوفر' : 'غير متوفر';

    final shareText = '''
🌿 تسوق الخضروات والفواكه من جاردينيا توداي 🌿
🏪 $name
📍 $zone
🗺️ $location
📞 $phone
🚚 التوصيل: $delivery
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

    Share.share(shareText.trim(), subject: 'تفاصيل السوق: $name');
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
          market: widget.market,
          onMap: () => _launchUrl(context, widget.market['location']?.toString(), 'لا يوجد رابط موقع متاح'),
          onCall: (phone) => _launchUrl(context, 'tel:$phone', 'رقم الهاتف غير متاح'),
          onWhatsApp: (number) => _launchUrl(context, 'https://wa.me/$number', 'رقم واتساب غير متاح'),
          onShare: _shareMarketDetails,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                  widget.cardColor.withOpacity(0.85),
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
                      FontAwesomeIcons.carrot,
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
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.market['photo']?.toString() ?? '',
                                      height: isMobile ? 40 : 48,
                                      width: isMobile ? 40 : 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => FaIcon(
                                        FontAwesomeIcons.carrot,
                                        size: isMobile ? 40 : 48,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.market['name']?.toString() ?? 'غير معروف',
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
                                ],
                              ),
                            ),
                          ),
                          ZoomIn(
                            duration: ThemeManager.animationDuration,
                            child: CircleAvatar(
                              radius: isMobile ? 24 : 28,
                              backgroundColor: theme.primaryColor.withOpacity(0.1),
                              child: FaIcon(
                                FontAwesomeIcons.carrot,
                                size: isMobile ? 22 : 26,
                                color: theme.primaryColor,
                                semanticLabel: 'أيقونة السوق',
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
                              semanticLabel: 'المنطقة',
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.market['zone']?.toString() ?? 'غير محدد',
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
  final Map<String, dynamic> market;
  final VoidCallback onMap;
  final Function(String) onCall;
  final Function(String) onWhatsApp;
  final VoidCallback onShare;

  const DetailsBottomSheet({
    super.key,
    required this.market,
    required this.onMap,
    required this.onCall,
    required this.onWhatsApp,
    required this.onShare,
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

    final phoneNumbers = (widget.market['phone'] as List<dynamic>?) ?? [];
    final whatsappNumbers = (widget.market['whatsapp'] as List<dynamic>?) ?? [];
    final buttonCount = 2 + (phoneNumbers.isNotEmpty ? 1 : 0) + (whatsappNumbers.isNotEmpty ? 1 : 0);

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
      buttonCount,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500), // Previously AppConstants.buttonAnimationDuration
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
    final phoneNumbers = (widget.market['phone'] as List<dynamic>?) ?? [];
    final whatsappNumbers = (widget.market['whatsapp'] as List<dynamic>?) ?? [];

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
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.market['photo']?.toString() ?? '',
                                      height: isMobile ? 40 : 48,
                                      width: isMobile ? 40 : 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => FaIcon(
                                        FontAwesomeIcons.carrot,
                                        size: isMobile ? 40 : 48,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.market['name']?.toString() ?? 'غير معروف',
                                      style: GoogleFonts.cairo(
                                        fontSize: isMobile ? 22 : 24,
                                        fontWeight: FontWeight.w700,
                                        color: theme.textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                    FadeInUp(
                      duration: ThemeManager.animationDuration,
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.mapMarkerAlt,
                            size: isMobile ? 18 : 20,
                            color: theme.primaryColor,
                            semanticLabel: 'المنطقة',
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.market['zone']?.toString() ?? 'غير محدد',
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
                    const SizedBox(height: 16),
                    FadeInUp(
                      duration: ThemeManager.animationDuration,
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.truck,
                            size: isMobile ? 18 : 20,
                            color: theme.primaryColor,
                            semanticLabel: 'التوصيل',
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.market['delivery'] == true ? 'متوفر' : 'غير متوفر',
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 15 : 16,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: theme.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            AnimatedBuilder(
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
                                        children: [
                                          FloatingActionButton(
                                            onPressed: widget.onMap,
                                            backgroundColor: theme.primaryColor,
                                            elevation: 2,
                                            child: FaIcon(
                                              FontAwesomeIcons.map,
                                              size: isMobile ? 24 : 28,
                                              color: Colors.white,
                                              semanticLabel: 'الموقع',
                                            ),
                                            tooltip: 'الموقع',
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'الموقع',
                                            style: GoogleFonts.cairo(
                                              fontSize: isMobile ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: theme.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (phoneNumbers.isNotEmpty)
                              AnimatedBuilder(
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
                                          children: [
                                            FloatingActionButton(
                                              onPressed: () {
                                                if (phoneNumbers.length == 1) {
                                                  widget.onCall(phoneNumbers[0]);
                                                } else {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius)),
                                                    ),
                                                    builder: (context) => Directionality(
                                                      textDirection: TextDirection.rtl,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(16),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              'اختر رقم الهاتف',
                                                              style: GoogleFonts.cairo(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.w700,
                                                                color: theme.textColor,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            ...phoneNumbers.map((phone) => ListTile(
                                                              leading: FaIcon(
                                                                FontAwesomeIcons.phone,
                                                                color: theme.primaryColor,
                                                                size: 20,
                                                              ),
                                                              title: Text(
                                                                phone,
                                                                style: GoogleFonts.cairo(
                                                                  fontSize: 16,
                                                                  color: theme.textColor,
                                                                ),
                                                              ),
                                                              onTap: () {
                                                                Navigator.pop(context);
                                                                widget.onCall(phone);
                                                              },
                                                            )),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              backgroundColor: theme.accentColor,
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.phone,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
                                                semanticLabel: 'الاتصال',
                                              ),
                                              tooltip: 'الاتصال',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'الاتصال',
                                              style: GoogleFonts.cairo(
                                                fontSize: isMobile ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (whatsappNumbers.isNotEmpty)
                              AnimatedBuilder(
                                animation: _buttonControllers[phoneNumbers.isNotEmpty ? 2 : 1],
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: _translateAnimations[phoneNumbers.isNotEmpty ? 2 : 1].value,
                                    child: FadeTransition(
                                      opacity: _fadeAnimations[phoneNumbers.isNotEmpty ? 2 : 1],
                                      child: ScaleTransition(
                                        scale: _scaleAnimations[phoneNumbers.isNotEmpty ? 2 : 1],
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FloatingActionButton(
                                              onPressed: () {
                                                if (whatsappNumbers.length == 1) {
                                                  widget.onWhatsApp(whatsappNumbers[0]);
                                                } else {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius)),
                                                    ),
                                                    builder: (context) => Directionality(
                                                      textDirection: TextDirection.rtl,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(16),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              'اختر رقم واتساب',
                                                              style: GoogleFonts.cairo(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.w700,
                                                                color: theme.textColor,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            ...whatsappNumbers.map((number) => ListTile(
                                                              leading: FaIcon(
                                                                FontAwesomeIcons.whatsapp,
                                                                color: const Color(0xFF25D366),
                                                                size: 20,
                                                              ),
                                                              title: Text(
                                                                number,
                                                                style: GoogleFonts.cairo(
                                                                  fontSize: 16,
                                                                  color: theme.textColor,
                                                                ),
                                                              ),
                                                              onTap: () {
                                                                Navigator.pop(context);
                                                                widget.onWhatsApp(number);
                                                              },
                                                            )),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              backgroundColor: const Color(0xFF25D366),
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.whatsapp,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
                                                semanticLabel: 'واتساب',
                                              ),
                                              tooltip: 'واتساب',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'واتساب',
                                              style: GoogleFonts.cairo(
                                                fontSize: isMobile ? 12 : 14,
                                                fontWeight: FontWeight.w600,
                                                color: theme.textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            AnimatedBuilder(
                              animation: _buttonControllers[phoneNumbers.isNotEmpty ? (whatsappNumbers.isNotEmpty ? 3 : 2) : (whatsappNumbers.isNotEmpty ? 2 : 1)],
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: _translateAnimations[phoneNumbers.isNotEmpty ? (whatsappNumbers.isNotEmpty ? 3 : 2) : (whatsappNumbers.isNotEmpty ? 2 : 1)].value,
                                  child: FadeTransition(
                                    opacity: _fadeAnimations[phoneNumbers.isNotEmpty ? (whatsappNumbers.isNotEmpty ? 3 : 2) : (whatsappNumbers.isNotEmpty ? 2 : 1)],
                                    child: ScaleTransition(
                                      scale: _scaleAnimations[phoneNumbers.isNotEmpty ? (whatsappNumbers.isNotEmpty ? 3 : 2) : (whatsappNumbers.isNotEmpty ? 2 : 1)],
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FloatingActionButton(
                                            onPressed: widget.onShare,
                                            backgroundColor: theme.primaryColor,
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
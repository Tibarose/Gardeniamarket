import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'homescreen/thememanager.dart';

class ATMsScreen extends StatefulWidget {
  const ATMsScreen({super.key});

  @override
  _ATMsScreenState createState() => _ATMsScreenState();
}

class _ATMsScreenState extends State<ATMsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> atms = [
    {
      "photo": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Banque_Misr.svg/1200px-Banque_Misr.svg.png",
      "name": "بنك مصر 1",
      "zone": "فرع بنك مصر ( المول )",
      "location": "https://maps.app.goo.gl/hLnjhvy54GV2Rcvr9",
    },
    {
      "photo": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Banque_Misr.svg/1200px-Banque_Misr.svg.png",
      "name": "بنك مصر 2",
      "zone": "فرع بنك مصر ( المول )",
      "location": "https://maps.app.goo.gl/hLnjhvy54GV2Rcvr9",
    },
    {
      "photo": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Banque_Misr.svg/1200px-Banque_Misr.svg.png",
      "name": "بنك مصر 3",
      "zone": "ATM Center ( المول )",
      "location": "https://maps.app.goo.gl/R7jLaRyhCvVenj856",
    },
    {
      "photo": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Banque_Misr.svg/1200px-Banque_Misr.svg.png",
      "name": "بنك مصر 4",
      "zone": "( الفندق )",
      "location": "https://maps.app.goo.gl/tKRLVQwFTpe1VLkc7",
    },
    {
      "photo": "https://i.imghippo.com/files/KadW9304tY.jpeg",
      "name": "البنك الأهلي المصري 1",
      "zone": "فرع البنك الأهلي ( المول )",
      "location": "https://maps.app.goo.gl/zRwMqT89z9sr41gM7",
    },
    {
      "photo": "https://i.imghippo.com/files/KadW9304tY.jpeg",
      "name": "البنك الأهلي المصري 2",
      "zone": "فرع البنك الأهلي ( المول )",
      "location": "https://maps.app.goo.gl/zRwMqT89z9sr41gM7",
    },
    {
      "photo": "https://i.imghippo.com/files/KadW9304tY.jpeg",
      "name": "البنك الأهلي المصري 3",
      "zone": "فرع البنك الأهلي ( المول )",
      "location": "https://maps.app.goo.gl/zRwMqT89z9sr41gM7",
    },
    {
      "photo": "https://i.imghippo.com/files/KadW9304tY.jpeg",
      "name": "البنك الأهلي المصري 4",
      "zone": "ATM Center ( المول )",
      "location": "https://maps.app.goo.gl/z9EJC35iDdzaHfDr5",
    },
    {
      "photo": "https://i.imghippo.com/files/KadW9304tY.jpeg",
      "name": "البنك الأهلي المصري 5",
      "zone": "( النادي Gate2 )",
      "location": "https://maps.app.goo.gl/w5rcSnU8tjhFpa9Y9",
    },
    {
      "photo": "https://i.imghippo.com/files/vzWE6649bw.png",
      "name": "CIB",
      "zone": "ATM Center ( المول )",
      "location": "https://maps.app.goo.gl/z9EJC35iDdzaHfDr5",
    },
    {
      "photo": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvpPKY7u2jCH5omMl-R6I5ypG1H7xkzTIdTw&s",
      "name": "بنك القاهرة",
      "zone": "ATM Center ( المول )",
      "location": "https://maps.app.goo.gl/z9EJC35iDdzaHfDr5",
    },
    {
      "photo": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRvpPKY7u2jCH5omMl-R6I5ypG1H7xkzTIdTw&s",
      "name": "بنك القاهرة",
      "zone": "أمام مدرسة Imperial",
      "location": "https://maps.app.goo.gl/KnN95tGfWaMzT7aKA",
    },
    {
      "photo": "https://i.imghippo.com/files/UNon9372Bo.png",
      "name": "Emirates NBD",
      "zone": "ATM Center ( المول )",
      "location": "https://maps.app.goo.gl/z9EJC35iDdzaHfDr5",
    },
    {
      "photo": "https://i.imghippo.com/files/REx3250E.png",
      "name": "التجاري وفا",
      "zone": "ATM Center ( المول )",
      "location": "https://maps.app.goo.gl/z9EJC35iDdzaHfDr5",
    },
    {
      "photo": "https://upload.wikimedia.org/wikipedia/commons/c/c1/QNB-logo.jpg",
      "name": "QNB الفندق",
      "zone": "الفندق",
      "location": "https://maps.app.goo.gl/wW786DwU1uXgX6mUA",
    },
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
    final filteredATMs = atms.where((atm) {
      final name = atm['name'].toString().toLowerCase();
      final zone = atm['zone'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || zone.contains(query);
    }).toList();

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
                              'أجهزة الصراف الآلي',
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
                              'ابحث عن أقرب أجهزة الصراف الآلي بسهولة',
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
                  child: filteredATMs.isEmpty
                      ? Center(
                    child: Text(
                      'لا توجد أجهزة صراف مطابقة',
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
                    itemCount: filteredATMs.length,
                    itemBuilder: (context, index) {
                      final atm = filteredATMs[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        child: ATMCard(
                          atm: atm,
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

class ATMCard extends StatefulWidget {
  final Map<String, dynamic> atm;
  final Color cardColor;

  const ATMCard({
    super.key,
    required this.atm,
    required this.cardColor,
  });

  @override
  _ATMCardState createState() => _ATMCardState();
}

class _ATMCardState extends State<ATMCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

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

  void _launchMap(BuildContext context, String? url) async {
    final theme = ThemeManager().currentTheme;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رابط موقع متاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء فتح الخريطة.',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareATMDetails() {
    final name = widget.atm['name']?.toString() ?? 'غير معروف';
    final zone = widget.atm['zone']?.toString() ?? 'غير محدد';
    final location = widget.atm['location']?.toString() ?? 'غير متوفر';

    final shareText = '''
🌟 تفاصيل جهاز الصراف الآلي من جاردينيا توداي 🌟
🏧 $name
📍 $zone
🗺️ $location
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

    Share.share(shareText.trim(), subject: 'تفاصيل جهاز الصراف: $name');
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
          atm: widget.atm,
          onMap: () => _launchMap(context, widget.atm['location']?.toString()),
          onShare: _shareATMDetails,
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
                      FontAwesomeIcons.moneyCheckAlt,
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
                                    child: _isLoading
                                        ? SizedBox(
                                      height: isMobile ? 40 : 48,
                                      width: isMobile ? 40 : 48,
                                      child: CircularProgressIndicator(
                                        color: theme.primaryColor,
                                      ),
                                    )
                                        : Image.network(
                                      widget.atm['photo']?.toString() ?? '',
                                      height: isMobile ? 40 : 48,
                                      width: isMobile ? 40 : 48,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => FaIcon(
                                        FontAwesomeIcons.moneyCheckAlt,
                                        size: isMobile ? 40 : 48,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.atm['name']?.toString() ?? 'غير معروف',
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
                                FontAwesomeIcons.moneyCheckAlt,
                                size: isMobile ? 22 : 26,
                                color: theme.primaryColor,
                                semanticLabel: 'أيقونة جهاز الصراف',
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
                                widget.atm['zone']?.toString() ?? 'غير محدد',
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
  final Map<String, dynamic> atm;
  final VoidCallback onMap;
  final VoidCallback onShare;

  const DetailsBottomSheet({
    super.key,
    required this.atm,
    required this.onMap,
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
      2,
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
                                      widget.atm['photo']?.toString() ?? '',
                                      height: isMobile ? 40 : 48,
                                      width: isMobile ? 40 : 48,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => FaIcon(
                                        FontAwesomeIcons.moneyCheckAlt,
                                        size: isMobile ? 40 : 48,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.atm['name']?.toString() ?? 'غير معروف',
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
                            _buildActionButton(
                              index: 0,
                              icon: FontAwesomeIcons.map,
                              label: 'الموقع',
                              onPressed: widget.onMap,
                            ),
                            _buildActionButton(
                              index: 1,
                              icon: FontAwesomeIcons.share,
                              label: 'مشاركة',
                              onPressed: widget.onShare,
                              backgroundColor: theme.accentColor,
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

  Widget _buildActionButton({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return AnimatedBuilder(
      animation: _buttonControllers[index],
      builder: (context, child) {
        return Transform.translate(
          offset: _translateAnimations[index].value,
          child: FadeTransition(
            opacity: _fadeAnimations[index],
            child: ScaleTransition(
              scale: _scaleAnimations[index],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: onPressed,
                    backgroundColor: backgroundColor ?? theme.primaryColor,
                    elevation: 2,
                    child: FaIcon(
                      icon,
                      size: isMobile ? 24 : 28,
                      color: Colors.white,
                      semanticLabel: label,
                    ),
                    tooltip: label,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
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
    );
  }
}
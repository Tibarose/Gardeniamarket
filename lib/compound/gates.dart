import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'homescreen/thememanager.dart';

class GatesScreen extends StatefulWidget {
  const GatesScreen({super.key});

  @override
  _GatesScreenState createState() => _GatesScreenState();
}

class _GatesScreenState extends State<GatesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> gates = [
    {
      "name": "الزهراء (1)",
      "imageUrl": "https://i.imghippo.com/files/wpSW9751hCA.jpg",
      "accessType": "للملاك والزوار",
      "residentPasses": 2,
      "visitorPasses": 2,
      "locationUrl": "https://maps.app.goo.gl/pKXKAZwmt33REcdY7",
      "note": "يمكن دخول الأثاث والمون والدليفري من هذه البوابة فقط",
    },
    {
      "name": "الفندق (2)",
      "imageUrl": "https://i.imghippo.com/files/wpSW9751hCA.jpg",
      "accessType": "للملاك والزوار",
      "residentPasses": 2,
      "visitorPasses": 2,
      "locationUrl": "https://maps.app.goo.gl/2tNgxqAEoqy8WJhZ7",
    },
    {
      "name": "السويس (3)",
      "imageUrl": "https://i.imghippo.com/files/hVx1520CKI.jpg",
      "accessType": "للملاك فقط",
      "residentPasses": 3,
      "visitorPasses": 3,
      "locationUrl": "https://maps.app.goo.gl/RPk1cagi4vKVwpfKA",
      "note": "الدخول بواسطة الأكسيس كارد أو الملصق الإلكتروني فقط",
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
    final filteredGates = gates.where((gate) {
      final name = gate['name'].toString().toLowerCase();
      final accessType = gate['accessType'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || accessType.contains(query);
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
                              'البوابات',
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
                              'ابحث عن البوابات بسهولة',
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
                                  hintText: 'ابحث بالاسم أو نوع الوصول...',
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
                  child: filteredGates.isEmpty
                      ? Center(
                    child: Text(
                      'لا توجد بوابات مطابقة',
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
                    itemCount: filteredGates.length,
                    itemBuilder: (context, index) {
                      final gate = filteredGates[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        child: GateCard(
                          gate: gate,
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

class GateCard extends StatefulWidget {
  final Map<String, dynamic> gate;
  final Color cardColor;

  const GateCard({
    super.key,
    required this.gate,
    required this.cardColor,
  });

  @override
  _GateCardState createState() => _GateCardState();
}

class _GateCardState extends State<GateCard> with SingleTickerProviderStateMixin {
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

  void _shareGateDetails() {
    final name = widget.gate['name']?.toString() ?? 'غير معروف';
    final accessType = widget.gate['accessType']?.toString() ?? 'غير محدد';
    final residentPasses = widget.gate['residentPasses']?.toString() ?? 'غير متوفر';
    final visitorPasses = widget.gate['visitorPasses']?.toString() ?? 'غير متوفر';
    final locationUrl = widget.gate['locationUrl']?.toString() ?? 'غير متوفر';
    final note = widget.gate['note']?.toString() ?? 'لا توجد ملاحظات';

    final shareText = '''
🌟 تفاصيل البوابة من جاردينيا توداي 🌟
🚪 $name
🔑 نوع الوصول: $accessType
👨‍👩‍👧 عدد ممرات الدخول: $residentPasses
👤 عدد ممرات الخروج: $visitorPasses
🗺️ $locationUrl
📝 ملاحظات: $note
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

    Share.share(shareText.trim(), subject: 'تفاصيل البوابة: $name');
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
          gate: widget.gate,
          onMap: () => _launchMap(context, widget.gate['locationUrl']?.toString()),
          onShare: _shareGateDetails,
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
                      FontAwesomeIcons.doorOpen,
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
                                      widget.gate['imageUrl']?.toString() ?? '',
                                      height: isMobile ? 40 : 48,
                                      width: isMobile ? 40 : 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => FaIcon(
                                        FontAwesomeIcons.doorOpen,
                                        size: isMobile ? 40 : 48,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.gate['name']?.toString() ?? 'غير معروف',
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
                                FontAwesomeIcons.doorOpen,
                                size: isMobile ? 22 : 26,
                                color: theme.primaryColor,
                                semanticLabel: 'أيقونة البوابة',
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
                              FontAwesomeIcons.key,
                              size: isMobile ? 18 : 20,
                              color: theme.primaryColor,
                              semanticLabel: 'نوع الوصول',
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.gate['accessType']?.toString() ?? 'غير محدد',
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
  final Map<String, dynamic> gate;
  final VoidCallback onMap;
  final VoidCallback onShare;

  const DetailsBottomSheet({
    super.key,
    required this.gate,
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
                                      widget.gate['imageUrl']?.toString() ?? '',
                                      height: isMobile ? 40 : 48,
                                      width: isMobile ? 40 : 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => FaIcon(
                                        FontAwesomeIcons.doorOpen,
                                        size: isMobile ? 40 : 48,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.gate['name']?.toString() ?? 'غير معروف',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInUp(
                              duration: ThemeManager.animationDuration,
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.key,
                                    size: isMobile ? 18 : 20,
                                    color: theme.primaryColor,
                                    semanticLabel: 'نوع الوصول',
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.gate['accessType']?.toString() ?? 'غير محدد',
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
                            const SizedBox(height: 12),
                            FadeInUp(
                              duration: ThemeManager.animationDuration,
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.idCard,
                                    size: isMobile ? 18 : 20,
                                    color: theme.primaryColor,
                                    semanticLabel: 'عدد ممرات الدخول',
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'عدد ممرات الدخول: ${widget.gate['residentPasses']?.toString() ?? 'غير متوفر'}',
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
                            const SizedBox(height: 12),
                            FadeInUp(
                              duration: ThemeManager.animationDuration,
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.idCard,
                                    size: isMobile ? 18 : 20,
                                    color: theme.primaryColor,
                                    semanticLabel: 'عدد ممرات الخروج',
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'عدد ممرات الخروج: ${widget.gate['visitorPasses']?.toString() ?? 'غير متوفر'}',
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
                            if (widget.gate['note'] != null) ...[
                              const SizedBox(height: 12),
                              FadeInUp(
                                duration: ThemeManager.animationDuration,
                                child: Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.noteSticky,
                                      size: isMobile ? 18 : 20,
                                      color: theme.primaryColor,
                                      semanticLabel: 'ملاحظات',
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.gate['note']?.toString() ?? 'لا توجد ملاحظات',
                                        style: GoogleFonts.cairo(
                                          fontSize: isMobile ? 15 : 16,
                                          color: theme.secondaryTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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
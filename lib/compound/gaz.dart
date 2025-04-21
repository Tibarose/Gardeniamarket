import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'homescreen/thememanager.dart';

class GasMeterScreen extends StatefulWidget {
  const GasMeterScreen({super.key});

  @override
  _GasMeterScreenState createState() => _GasMeterScreenState();
}

class _GasMeterScreenState extends State<GasMeterScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> gasDetails = [
    {
      'title': 'شركة تاون جاس',
      'subtitle': 'إمتداد حسن المأمون، مدينة نصر خلف الوفاء والأمل',
      'icon': FontAwesomeIcons.building,
      'mapUrl': 'https://maps.app.goo.gl/m2PZX48SjqxzQhkD7',
      'shareText': 'شركة تاون جاس\nإمتداد حسن المأمون، مدينة نصر خلف الوفاء والأمل\nhttps://maps.app.goo.gl/m2PZX48SjqxzQhkD7',
      'actionType': 'map',
    },
    {
      'title': 'طلب عداد',
      'subtitle': 'التعاقد مع شركة تاون جاس',
      'icon': FontAwesomeIcons.plus,
      'actionType': 'meterRequest',
    },
    {
      'title': 'أرقام خدمة العملاء',
      'subtitle': 'تواصلوا معنا',
      'icon': FontAwesomeIcons.phone,
      'phoneNumbers': ['0224700257', '0224714735', '0224715607'],
      'actionType': 'phone',
    },
    {
      'title': 'تطبيقات الشحن NFC',
      'subtitle': 'بترو شحن وفوري',
      'icon': FontAwesomeIcons.mobileScreen,
      'apps': [
        {
          'name': 'بترو شحن',
          'googlePlayUrl': 'https://play.google.com/store/apps/details?id=com.sewedy.electrometer.ecash.petrotrade',
          'appStoreUrl': 'https://apps.apple.com/eg/app/petrometer/id1568943521',
        },
        {
          'name': 'فوري',
          'googlePlayUrl': 'https://play.google.com/store/apps/details?id=com.fawry.myfawry',
          'appStoreUrl': 'https://apps.apple.com/qa/app/myfawry/id1462911630',
        },
      ],
      'actionType': 'apps',
    },
    {
      'title': 'طرق الشحن',
      'subtitle': 'السوبرماركت أو NFC',
      'icon': FontAwesomeIcons.creditCard,
      'rechargeDetails': {
        'supermarkets': [
          {
            'name': 'سوبر ماركت لافندر',
            'zone': 'زوون 11',
            'mapUrl': 'https://maps.app.goo.gl/zLsC4jiDFswqwY8K8',
          },
          {
            'name': 'سوبر ماركت جملة ماركت',
            'zone': 'زوون 1',
            'mapUrl': 'https://maps.app.goo.gl/ukrXP24GFrni45SW6',
          },
          {
            'name': 'سوبر ماركت حياة',
            'zone': 'زوون 2',
            'mapUrl': 'https://maps.app.goo.gl/KntUWuXibt1PpFNF9',
          },
          {
            'name': 'سوبر ماركت البرنس',
            'zone': 'زوون 4',
            'mapUrl': 'https://maps.app.goo.gl/HKTNYjiRWHReYzbD7',
          },
          {
            'name': 'سوبر ماركت جاردينيا',
            'zone': 'زوون 5',
            'mapUrl': 'https://maps.app.goo.gl/XgmFyxD13xDdtW2k7',
          },
          {
            'name': 'سوبر ماركت أسواق الجملة',
            'zone': 'زوون 8',
            'mapUrl': 'https://maps.app.goo.gl/kFhY5Cx652Q1LS529',
          },
          {
            'name': 'سوبر ماركت بيور',
            'zone': 'زوون 11',
            'mapUrl': 'https://maps.app.goo.gl/LyzWoJuUrXc27dF49',
          },
          {
            'name': 'شركة بتروتريد',
            'zone': 'خلف ضرائب المبيعات – الحي العاشر – مدينة نصر',
            'mapUrl': 'https://maps.app.goo.gl/a6ncv9ZBmSjWMDe79',
          },
        ],
        'nfcVideos': [
          {
            'title': 'طريقة شحن العداد بخاصية NFC بتطبيق Pertocharge',
            'videoId': 'bBhPPiyYM_8',
          },
          {
            'title': 'طريقة شحن العداد بخاصية NFC بتطبيق فوري',
            'videoId': 'lPpsOzOa030',
          },
        ],
      },
      'actionType': 'recharge',
    },
    {
      'title': 'رقم طوارئ الغاز',
      'subtitle': 'للطوارئ فقط',
      'icon': FontAwesomeIcons.exclamationTriangle,
      'phoneNumbers': ['0224704649'],
      'actionType': 'emergency',
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
    final filteredDetails = gasDetails.where((detail) {
      final title = detail['title'].toString().toLowerCase();
      final subtitle = detail['subtitle'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || subtitle.contains(query);
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
                            child: Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.fire,
                                  size: isMobile ? 28 : 32,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'عداد الغاز',
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInDown(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              'تفاصيل وخدمات عداد الغاز',
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
                                  hintText: 'ابحث بالعنوان أو التفاصيل...',
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
                  child: filteredDetails.isEmpty
                      ? Center(
                    child: Text(
                      'لا توجد تفاصيل مطابقة',
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
                    itemCount: filteredDetails.length,
                    itemBuilder: (context, index) {
                      final detail = filteredDetails[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        child: ContactCard(
                          detail: detail,
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

class ContactCard extends StatefulWidget {
  final Map<String, dynamic> detail;
  final Color cardColor;

  const ContactCard({
    super.key,
    required this.detail,
    required this.cardColor,
  });

  @override
  _ContactCardState createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard> with SingleTickerProviderStateMixin {
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
    }
  }

  void _launchPhone(BuildContext context, String? phone) async {
    final theme = ThemeManager().currentTheme;
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رقم هاتف متاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'tel:$phone';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن إجراء المكالمة.',
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
            'حدث خطأ أثناء إجراء المكالمة.',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _launchUrl(BuildContext context, String? url) async {
    final theme = ThemeManager().currentTheme;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رابط متاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء فتح الرابط.',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareDetail() {
    final title = widget.detail['title']?.toString() ?? 'غير معروف';
    final subtitle = widget.detail['subtitle']?.toString() ?? 'غير محدد';
    final actionType = widget.detail['actionType']?.toString() ?? '';
    String shareText = '''
🌟 تفاصيل عداد الغاز من جاردينيا توداي 🌟
📋 $title
ℹ️ $subtitle
''';

    if (actionType == 'map') {
      final shareTextCustom = widget.detail['shareText']?.toString() ?? 'غير متوفر';
      shareText = '''
$shareTextCustom
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';
    } else if (actionType == 'phone' || actionType == 'emergency') {
      final phones = widget.detail['phoneNumbers'] as List<dynamic>? ?? [];
      shareText += '📞 الأرقام:\n${phones.join('\n')}\n';
    } else if (actionType == 'apps') {
      final apps = widget.detail['apps'] as List<dynamic>? ?? [];
      shareText += '📱 التطبيقات:\n';
      for (var app in apps) {
        final name = app['name']?.toString() ?? 'تطبيق';
        final googlePlay = app['googlePlayUrl']?.toString() ?? 'غير متوفر';
        final appStore = app['appStoreUrl']?.toString() ?? 'غير متوفر';
        shareText += '- $name:\n  Google Play: $googlePlay\n  App Store: $appStore\n';
      }
    } else if (actionType == 'recharge') {
      final supermarkets = widget.detail['rechargeDetails']['supermarkets'] as List<dynamic>? ?? [];
      shareText += '📍 أماكن الشحن:\n';
      for (var market in supermarkets) {
        final name = market['name']?.toString() ?? 'غير معروف';
        final zone = market['zone']?.toString() ?? 'غير محدد';
        shareText += '- $name ($zone)\n';
      }
    }

    if (actionType != 'map') {
      shareText += '''
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';
    }

    Share.share(shareText.trim(), subject: 'تفاصيل: $title');
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
          detail: widget.detail,
          onMap: widget.detail['mapUrl'] != null ? () => _launchMap(context, widget.detail['mapUrl']) : null,
          onPhone: widget.detail['phoneNumbers'] != null && (widget.detail['phoneNumbers'] as List).isNotEmpty
              ? (widget.detail['phoneNumbers'] as List).map((phone) => () => _launchPhone(context, phone)).toList()
              : [],
          onApps: widget.detail['apps'] != null
              ? (widget.detail['apps'] as List<dynamic>).asMap().entries.map((entry) {
            final app = entry.value;
            return {
              'googlePlay': () => _launchUrl(context, app['googlePlayUrl']),
              'appStore': () => _launchUrl(context, app['appStoreUrl']),
            };
          }).toList()
              : [],
          onRecharge: widget.detail['actionType'] == 'recharge'
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => RechargeScreen(detail: widget.detail)))
              : null,
          onMeterRequest: widget.detail['actionType'] == 'meterRequest'
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => TownGasContractScreen(detail: widget.detail)))
              : null,
          onShare: _shareDetail,
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
    widget.detail['icon'] as IconData,
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
    FaIcon(
    widget.detail['icon'] as IconData,
    size: isMobile ? 40 : 48,
    color: theme.primaryColor,
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Text(
    widget.detail['title']?.toString() ?? 'غير معروف',
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
    widget.detail['icon'] as IconData,
    size: isMobile ? 22 : 26,
    color: theme.primaryColor,
    semanticLabel: 'أيقونة التفاصيل',
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
    FontAwesomeIcons.infoCircle,
    size: isMobile ? 18 : 20,
    color: theme.primaryColor,
    semanticLabel: 'تفاصيل',
    ),
    const SizedBox(width: 10),
    Expanded(
    child: Text(
    widget.detail['subtitle']?.toString() ?? 'غير محدد',
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
    ));
    }
}

class DetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> detail;
  final VoidCallback? onMap;
  final List<VoidCallback> onPhone;
  final List<Map<String, VoidCallback>> onApps;
  final VoidCallback? onRecharge;
  final VoidCallback? onMeterRequest;
  final VoidCallback onShare;

  const DetailsBottomSheet({
    super.key,
    required this.detail,
    this.onMap,
    required this.onPhone,
    required this.onApps,
    this.onRecharge,
    this.onMeterRequest,
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

    final buttonCount = _getButtonCount();
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

  int _getButtonCount() {
    int count = 1; // Share button
    if (widget.onMap != null) count++;
    count += widget.onPhone.length;
    count += widget.onApps.length * 2; // Google Play + App Store per app
    if (widget.onRecharge != null) count++;
    if (widget.onMeterRequest != null) count++;
    return count;
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
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
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
                                        FaIcon(
                                          widget.detail['icon'] as IconData,
                                          size: isMobile ? 40 : 48,
                                          color: theme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.detail['title']?.toString() ?? 'غير معروف',
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
                                          FontAwesomeIcons.infoCircle,
                                          size: isMobile ? 18 : 20,
                                          color: theme.primaryColor,
                                          semanticLabel: 'تفاصيل',
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            widget.detail['subtitle']?.toString() ?? 'غير محدد',
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
                                  if (widget.detail['actionType'] == 'map') ...[
                                    const SizedBox(height: 12),
                                    FadeInUp(
                                      duration: ThemeManager.animationDuration,
                                      child: Text(
                                        'إمتداد حسن المأمون، مدينة نصر خلف الوفاء والأمل، مدينة نصر',
                                        style: GoogleFonts.cairo(
                                          fontSize: isMobile ? 14 : 15,
                                          color: theme.textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (widget.detail['actionType'] == 'phone' || widget.detail['actionType'] == 'emergency') ...[
                                    const SizedBox(height: 12),
                                    ...((widget.detail['phoneNumbers'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final phone = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: FadeInUp(
                                          duration: ThemeManager.animationDuration,
                                          delay: Duration(milliseconds: 100 * index),
                                          child: Row(
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.phone,
                                                size: isMobile ? 16 : 18,
                                                color: theme.primaryColor,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                phone,
                                                style: GoogleFonts.cairo(
                                                  fontSize: isMobile ? 14 : 15,
                                                  color: theme.textColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList()),
                                  ],
                                  if (widget.detail['actionType'] == 'apps') ...[
                                    const SizedBox(height: 12),
                                    ...((widget.detail['apps'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final app = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: FadeInUp(
                                          duration: ThemeManager.animationDuration,
                                          delay: Duration(milliseconds: 100 * index),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                app['name']?.toString() ?? 'غير معروف',
                                                style: GoogleFonts.cairo(
                                                  fontSize: isMobile ? 16 : 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'متوفر على Google Play و App Store',
                                                style: GoogleFonts.cairo(
                                                  fontSize: isMobile ? 14 : 15,
                                                  color: theme.secondaryTextColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList()),
                                  ],
                                  if (widget.detail['actionType'] == 'recharge') ...[
                                    const SizedBox(height: 12),
                                    FadeInUp(
                                      duration: ThemeManager.animationDuration,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'يمكنك الشحن من خلال أي منفذ فوري أو بزيارة أحد السوبرماركت الموجودة بالكمبوند (برجاء تمرير الكارت على العداد قبل الشحن)',
                                            style: GoogleFonts.cairo(
                                              fontSize: isMobile ? 14 : 15,
                                              color: theme.textColor,
                                              fontWeight: FontWeight.w500,
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
                                  if (widget.onMap != null)
                                    _buildActionButton(
                                      index: 0,
                                      icon: FontAwesomeIcons.map,
                                      label: 'الموقع',
                                      onPressed: widget.onMap!,
                                      backgroundColor: theme.primaryColor,
                                    ),
                                  ...widget.onPhone.asMap().entries.map((entry) {
                                    final index = (widget.onMap != null ? 1 : 0) + entry.key;
                                    return _buildActionButton(
                                      index: index,
                                      icon: FontAwesomeIcons.phone,
                                      label: widget.detail['phoneNumbers'][entry.key],
                                      onPressed: entry.value,
                                      backgroundColor: theme.primaryColor,
                                    );
                                  }).toList(),
                                  ...widget.onApps.asMap().entries.expand((entry) {
                                    final appIndex = entry.key;
                                    final app = entry.value;
                                    final baseIndex = (widget.onMap != null ? 1 : 0) + widget.onPhone.length + (appIndex * 2);
                                    return [
                                      _buildActionButton(
                                        index: baseIndex,
                                        icon: FontAwesomeIcons.googlePlay,
                                        label: 'Google Play (${widget.detail['apps'][appIndex]['name']})',
                                        onPressed: app['googlePlay']!,
                                        backgroundColor: theme.primaryColor,
                                      ),
                                      _buildActionButton(
                                        index: baseIndex + 1,
                                        icon: FontAwesomeIcons.apple,
                                        label: 'App Store (${widget.detail['apps'][appIndex]['name']})',
                                        onPressed: app['appStore']!,
                                        backgroundColor: theme.primaryColor,
                                      ),
                                    ];
                                  }).toList(),
                                  if (widget.onRecharge != null)
                                    _buildActionButton(
                                      index: (widget.onMap != null ? 1 : 0) + widget.onPhone.length + (widget.onApps.length * 2),
                                      icon: FontAwesomeIcons.creditCard,
                                      label: 'طرق الشحن',
                                      onPressed: widget.onRecharge!,
                                      backgroundColor: theme.primaryColor,
                                    ),
                                  if (widget.onMeterRequest != null)
                                    _buildActionButton(
                                      index: (widget.onMap != null ? 1 : 0) + widget.onPhone.length + (widget.onApps.length * 2) + (widget.onRecharge != null ? 1 : 0),
                                      icon: FontAwesomeIcons.plus,
                                      label: 'طلب عداد',
                                      onPressed: widget.onMeterRequest!,
                                      backgroundColor: theme.primaryColor,
                                    ),
                                  _buildActionButton(
                                    index: _buttonControllers.length - 1,
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
                  );
                },
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
    required Color backgroundColor,
  }) {
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
                    backgroundColor: backgroundColor,
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
                    label.length > 15 ? '${label.substring(0, 12)}...' : label,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: ThemeManager().currentTheme.textColor,
                    ),
                    textAlign: TextAlign.center,
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

class TownGasContractScreen extends StatelessWidget {
  final Map<String, dynamic> detail;

  const TownGasContractScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'التعاقد مع شركة تاون جاس',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: theme.appBarGradient,
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(ThemeManager.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(
                duration: ThemeManager.animationDuration,
                child: Text(
                  'تفاصيل التعاقد:',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: ThemeManager.animationDuration,
                delay: const Duration(milliseconds: 100),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.locationDot,
                              size: isMobile ? 24 : 28,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'مقر الشركة: تقاطع امتداد حسن المأمون مع محور شينزو آبي',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 15 : 16,
                                  color: theme.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.building,
                              size: isMobile ? 24 : 28,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'خدمة العملاء الدور الأرضي',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 15 : 16,
                                color: theme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            const url = 'https://maps.app.goo.gl/m2PZX48SjqxzQhkD7';
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.map,
                                size: isMobile ? 24 : 28,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'لوكيشن الشركة: Town Gas Company',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 15 : 16,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.phone,
                              size: isMobile ? 24 : 28,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'رقم الهاتف: 0247142570',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 15 : 16,
                                color: theme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: ThemeManager.animationDuration,
                delay: const Duration(milliseconds: 200),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الأوراق المطلوبة:',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1- صورة ضوئية من عقد الوحدة',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '2- صورة البطاقة الشخصية للمالك',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '3- خطاب المرافق',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: ThemeManager.animationDuration,
                delay: const Duration(milliseconds: 300),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تركيب العداد:',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1- يتم تحديد موعد للمعاينة وتركيب مواسير الغاز والعداد أثناء التعاقد',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '2- بعد تركيب العداد يتم الاتصال بخدمة العملاء لتحديد موعد تشغيل العداد',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: ThemeManager.animationDuration,
                delay: const Duration(milliseconds: 400),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أرقام خدمة العملاء (أرضي):',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '0224715607',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '0224714735',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
}

class RechargeScreen extends StatelessWidget {
  final Map<String, dynamic> detail;

  const RechargeScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'طرق الشحن',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 20 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: theme.appBarGradient,
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
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              FadeInUp(
                duration: ThemeManager.animationDuration,
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'يمكنك الشحن من خلال أي منفذ فوري أو بزيارة أحد السوبرماركت الموجودة بالكمبوند (برجاء تمرير الكارت على العداد قبل الشحن)',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              TabBar(
                labelStyle: GoogleFonts.cairo(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.cairo(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.secondaryTextColor,
                indicatorColor: theme.accentColor,
                tabs: const [
                  Tab(text: 'السوبرماركت'),
                  Tab(text: 'الموابيل NFC'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _SupermarketTab(supermarkets: detail['rechargeDetails']['supermarkets']),
                    _MobileNFCTab(videos: detail['rechargeDetails']['nfcVideos']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupermarketTab extends StatelessWidget {
  final List<dynamic> supermarkets;

  const _SupermarketTab({required this.supermarkets});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: ThemeManager.animationDuration,
            child: Text(
              'السوبرماركت المتاحة',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...supermarkets.asMap().entries.map((entry) {
            final index = entry.key;
            final market = entry.value;
            return FadeInUp(
              duration: ThemeManager.animationDuration,
              delay: Duration(milliseconds: 100 * index),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                market['name'],
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.locationDot,
                                color: theme.primaryColor,
                                size: isMobile ? 24 : 28,
                              ),
                              onPressed: () async {
                                final url = market['mapUrl'];
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'لا يمكن فتح الخريطة',
                                        style: GoogleFonts.cairo(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المنطقة: ${market['zone']}',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 15 : 16,
                            color: theme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _MobileNFCTab extends StatelessWidget {
  final List<dynamic> videos;

  const _MobileNFCTab({required this.videos});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: ThemeManager.animationDuration,
            child: Text(
              'شحن عداد الغاز باستخدام NFC',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...videos.asMap().entries.map((entry) {
            final index = entry.key;
            final video = entry.value;
            final controller = YoutubePlayerController.fromVideoId(
              videoId: video['videoId'],
              autoPlay: false,
              params: const YoutubePlayerParams(
                showControls: true,
                showFullscreenButton: true,
              ),
            );
            return FadeInUp(
              duration: ThemeManager.animationDuration,
              delay: Duration(milliseconds: 100 * index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'],
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: isMobile ? 200 : 250,
                      child: YoutubePlayer(
                        controller: controller,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
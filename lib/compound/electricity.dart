import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'homescreen/thememanager.dart';

class ElectricityMeterScreen extends StatefulWidget {
  const ElectricityMeterScreen({super.key});

  @override
  _ElectricityMeterScreenState createState() => _ElectricityMeterScreenState();
}

class _ElectricityMeterScreenState extends State<ElectricityMeterScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> electricityDetails = [
    {
      'title': 'شركة مدكور',
      'subtitle': 'زون 1 عمارة 63',
      'icon': FontAwesomeIcons.building,
      'mapUrl': 'https://maps.app.goo.gl/vXRdKi1pDVhv6PaA9',
      'shareText': 'شركة مدكور\nزون 1 عمارة 63\nhttps://goo.gl/maps/8iTY8sLzy4HwBu2q6',
      'actionType': 'map',
    },
    {
      'title': 'طلب عداد',
      'subtitle': 'إجراءات الحصول على عداد كهرباء',
      'icon': FontAwesomeIcons.plus,
      'imageUrl': 'https://i.imghippo.com/files/lDP9833aIM.jpg',
      'actionType': 'meterRequest',
    },
    {
      'title': 'أرقام خدمة العملاء',
      'subtitle': 'تواصلوا معنا',
      'icon': FontAwesomeIcons.phone,
      'phoneNumbers': ['01201322220', '01121023975', '01093738495'],
      'actionType': 'phone',
    },
    {
      'title': 'تطبيق الشركة',
      'subtitle': 'IO Meter و Madkour Utilities',
      'icon': FontAwesomeIcons.mobileScreen,
      'apps': [
        {
          'name': 'IO Meter Community',
          'googlePlayUrl': 'https://play.google.com/store/apps/details?id=com.thed.iometer',
          'appStoreUrl': 'https://apps.apple.com/bs/app/iometer-community/id1588429456',
        },
        {
          'name': 'Madkour Utilities',
          'googlePlayUrl': 'https://play.google.com/store/apps/details?id=org.SOfCO.Madkour.Utilities',
          'appStoreUrl': 'https://madkourutilities.com/Authentication/Login?ReturnUrl=%2F',
        },
      ],
      'actionType': 'apps',
    },
    {
      'title': 'قناة تليجرام',
      'subtitle': 'للحصول على التحديثات',
      'icon': FontAwesomeIcons.telegram,
      'url': 'https://t.me/+bLygdZiZgtMyYTg0',
      'actionType': 'url',
    },
    {
      'title': 'طرق الشحن',
      'subtitle': 'شحن الرصيد نقدًا أو إلكترونيًا',
      'icon': FontAwesomeIcons.creditCard,
      'rechargeDetails': {
        'location': 'زون 1 عمارة 63',
        'method1': {
          'name': 'IO Meter',
          'steps': [
            {'description': 'قم بإدخال اسم المستخدم وكلمة المرور', 'image': 'https://i.imghippo.com/files/vYpH4429Ws.webp'},
            {'description': 'قم بالضغط على + لإضافة رصيد', 'image': 'https://i.imghippo.com/files/xc2124pA.jpg'},
            {'description': 'قم بإدخال المبلغ', 'image': 'https://i.imghippo.com/files/Aqfc2014Zk.jpg'},
            {'description': 'قم باختيار طريقة الدفع', 'image': 'https://i.imghippo.com/files/JF8981e.jpg'},
            {'description': 'قم بإدخال بيانات بطاقة الدفع يتم توجيهك لصفحة البنك لكتابة otp الذي يصل في رسالة لإتمام عملية الدفع', 'image': 'https://i.imghippo.com/files/iBP9577Q.jpg'},
            {'description': 'بعد إتمام عملية الدفع بدقائق سوف يضاف الرصيد إلى my Balance ويظهر إيصال الدفع في الإيصالات بالأسفل أنها عملية مكتملة', 'image': 'https://i.imghippo.com/files/TRea2152fxs.jpg'},
          ],
        },
        'method2': {
          'name': 'Madkour Utilities',
          'steps': [
            {'description': 'قم بإدخال اسم المستخدم وكلمة المرور', 'image': 'https://i.imghippo.com/files/ZUcx3549Ijk.jpg'},
            {'description': 'قم بالضغط على + لإضافة رصيد', 'image': 'https://i.imghippo.com/files/kxC2535eaM.jpg'},
            {'description': 'قم بإدخال المبلغ', 'image': 'https://i.imghippo.com/files/lBoJ8063mjk.jpg'},
            {'description': 'قم باختيار طريقة الدفع', 'image': 'https://i.imghippo.com/files/fh4031BlE.jpg'},
            {'description': 'قم بإدخال بيانات بطاقة الدفع يتم توجيهك لصفحة البنك لكتابة otp الذي يصل في رسالة لإتمام عملية الدفع', 'image': 'https://i.imghippo.com/files/DVsA6785Ui.jpg'},
            {'description': 'بعد إتمام عملية الدفع بدقائق سوف يضاف الرصيد إلى my Balance ويظهر إيصال الدفع في الإيصالات بالأسفل أنها عملية مكتملة', 'image': 'https://i.imghippo.com/files/Uqjq4824cD.jpg'},
          ],
        },
        'whatsappNumbers': ['01121023975', '01093738495'],
      },
      'actionType': 'recharge',
    },
    {
      'title': 'التواصل واتساب',
      'subtitle': 'للتواصل المباشر',
      'icon': FontAwesomeIcons.whatsapp,
      'whatsappNumbers': ['201093738495', '201121023975'],
      'actionType': 'whatsapp',
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
    final filteredDetails = electricityDetails.where((detail) {
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
                            child: Text(
                              'عداد الكهرباء',
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
                              'تفاصيل وخدمات عداد الكهرباء',
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

  void _launchWhatsApp(BuildContext context, String? number) async {
    final theme = ThemeManager().currentTheme;
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رقم واتساب متاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'https://wa.me/$number';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح واتساب.',
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
            'حدث خطأ أثناء فتح واتساب.',
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
🌟 تفاصيل عداد الكهرباء من جاردينيا توداي 🌟
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
    } else if (actionType == 'phone') {
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
    } else if (actionType == 'url') {
      final url = widget.detail['url']?.toString() ?? 'غير متوفر';
      shareText += '🔗 $url\n';
    } else if (actionType == 'whatsapp') {
      final numbers = widget.detail['whatsappNumbers'] as List<dynamic>? ?? [];
      shareText += '📲 أرقام واتساب:\n${numbers.join('\n')}\n';
    } else if (actionType == 'recharge') {
      final location = widget.detail['rechargeDetails']['location']?.toString() ?? 'غير متوفر';
      shareText += '📍 الموقع: $location\n';
      shareText += '📱 للحصول على بيانات الدخول تواصلوا عبر واتساب: ${widget.detail['rechargeDetails']['whatsappNumbers'].join(', ')}\n';
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
          onWhatsApp: widget.detail['whatsappNumbers'] != null && (widget.detail['whatsappNumbers'] as List).isNotEmpty
              ? (widget.detail['whatsappNumbers'] as List).map((number) => () => _launchWhatsApp(context, number)).toList()
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
          onUrl: widget.detail['url'] != null ? () => _launchUrl(context, widget.detail['url']) : null,
          onRecharge: widget.detail['actionType'] == 'recharge'
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => RechargeScreen(detail: widget.detail)))
              : null,
          onMeterRequest: widget.detail['actionType'] == 'meterRequest'
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeterRequestScreen(detail: widget.detail)))
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
      ),
    );
  }
}

class DetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> detail;
  final VoidCallback? onMap;
  final List<VoidCallback> onPhone;
  final List<VoidCallback> onWhatsApp;
  final List<Map<String, VoidCallback>> onApps;
  final VoidCallback? onUrl;
  final VoidCallback? onRecharge;
  final VoidCallback? onMeterRequest;
  final VoidCallback onShare;

  const DetailsBottomSheet({
    super.key,
    required this.detail,
    this.onMap,
    required this.onPhone,
    required this.onWhatsApp,
    required this.onApps,
    this.onUrl,
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
    count += widget.onWhatsApp.length;
    count += widget.onApps.length * 2; // Google Play + App Store per app
    if (widget.onUrl != null) count++;
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
                                  if (widget.detail['actionType'] == 'phone') ...[
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
                                  if (widget.detail['actionType'] == 'whatsapp') ...[
                                    const SizedBox(height: 12),
                                    ...((widget.detail['whatsappNumbers'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final number = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: FadeInUp(
                                          duration: ThemeManager.animationDuration,
                                          delay: Duration(milliseconds: 100 * index),
                                          child: Row(
                                            children: [
                                              FaIcon(
                                                FontAwesomeIcons.whatsapp,
                                                size: isMobile ? 16 : 18,
                                                color: const Color(0xFF25D366),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                number,
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
                                            'الموقع: ${widget.detail['rechargeDetails']['location']}',
                                            style: GoogleFonts.cairo(
                                              fontSize: isMobile ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'شحن نقدي أو ببطاقة دفع إلكترونية',
                                            style: GoogleFonts.cairo(
                                              fontSize: isMobile ? 14 : 15,
                                              color: theme.secondaryTextColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'التطبيقات: IO Meter و Madkour Utilities',
                                            style: GoogleFonts.cairo(
                                              fontSize: isMobile ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'للحصول على بيانات الدخول تواصلوا عبر واتساب: ${widget.detail['rechargeDetails']['whatsappNumbers'].join(', ')}',
                                            style: GoogleFonts.cairo(
                                              fontSize: isMobile ? 14 : 15,
                                              color: theme.secondaryTextColor,
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
                                    ),
                                  ...widget.onPhone.asMap().entries.map((entry) {
                                    final index = (widget.onMap != null ? 1 : 0) + entry.key;
                                    return _buildActionButton(
                                      index: index,
                                      icon: FontAwesomeIcons.phone,
                                      label: widget.detail['phoneNumbers'][entry.key],
                                      onPressed: entry.value,
                                    );
                                  }).toList(),
                                  ...widget.onWhatsApp.asMap().entries.map((entry) {
                                    final index = (widget.onMap != null ? 1 : 0) + widget.onPhone.length + entry.key;
                                    return _buildActionButton(
                                      index: index,
                                      icon: FontAwesomeIcons.whatsapp,
                                      label: widget.detail['whatsappNumbers'][entry.key],
                                      onPressed: entry.value,
                                      backgroundColor: const Color(0xFF25D366),
                                    );
                                  }).toList(),
                                  ...widget.onApps.asMap().entries.expand((entry) {
                                    final appIndex = entry.key;
                                    final app = entry.value;
                                    final baseIndex = (widget.onMap != null ? 1 : 0) + widget.onPhone.length + widget.onWhatsApp.length + (appIndex * 2);
                                    return [
                                      _buildActionButton(
                                        index: baseIndex,
                                        icon: FontAwesomeIcons.googlePlay,
                                        label: 'Google Play (${widget.detail['apps'][appIndex]['name']})',
                                        onPressed: app['googlePlay']!,
                                      ),
                                      _buildActionButton(
                                        index: baseIndex + 1,
                                        icon: FontAwesomeIcons.apple,
                                        label: 'App Store (${widget.detail['apps'][appIndex]['name']})',
                                        onPressed: app['appStore']!,
                                      ),
                                    ];
                                  }).toList(),
                                  if (widget.onUrl != null)
                                    _buildActionButton(
                                      index: (widget.onMap != null ? 1 : 0) + widget.onPhone.length + widget.onWhatsApp.length + (widget.onApps.length * 2),
                                      icon: FontAwesomeIcons.link,
                                      label: 'زيارة',
                                      onPressed: widget.onUrl!,
                                    ),
                                  if (widget.onRecharge != null)
                                    _buildActionButton(
                                      index: (widget.onMap != null ? 1 : 0) + widget.onPhone.length + widget.onWhatsApp.length + (widget.onApps.length * 2) + (widget.onUrl != null ? 1 : 0),
                                      icon: FontAwesomeIcons.creditCard,
                                      label: 'طرق الشحن',
                                      onPressed: widget.onRecharge!,
                                    ),
                                  if (widget.onMeterRequest != null)
                                    _buildActionButton(
                                      index: (widget.onMap != null ? 1 : 0) + widget.onPhone.length + widget.onWhatsApp.length + (widget.onApps.length * 2) + (widget.onUrl != null ? 1 : 0) + (widget.onRecharge != null ? 1 : 0),
                                      icon: FontAwesomeIcons.plus,
                                      label: 'طلب عداد',
                                      onPressed: widget.onMeterRequest!,
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
    Color backgroundColor = Colors.blue, // Default color, will be overridden by theme.primaryColor
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
                    backgroundColor: backgroundColor == Colors.blue ? theme.primaryColor : backgroundColor,
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
                      color: theme.textColor,
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

class MeterRequestScreen extends StatelessWidget {
  final Map<String, dynamic> detail;

  const MeterRequestScreen({super.key, required this.detail});

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
            'طلب عداد كهرباء',
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
                  'إجراءات الحصول على عداد الكهرباء:',
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
                child: Center(
                  child: Image.network(
                    detail['imageUrl'] ?? 'https://i.imghippo.com/files/lDP9833aIM.jpg',
                    height: isMobile ? 400 : 500,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'فشل تحميل الصورة',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.red,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const CircularProgressIndicator();
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(ThemeManager.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(
                duration: ThemeManager.animationDuration,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.cardBackground,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: isMobile ? 36 : 40,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'يمكنك الذهاب إلى مقر الشركة زون 1 عمارة 63 وشحن الرصيد إما نقدًا أو بواسطة بطاقة الدفع الإلكتروني',
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
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
                              FontAwesomeIcons.mobileScreen,
                              size: isMobile ? 36 : 40,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'أو عن طريق استخدام التطبيق الخاص بالشركة وذلك باتباع الخطوات التالية',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: theme.primaryColor.withOpacity(0.1),
                          child: Text(
                            'للحصول على اسم المستخدم وكلمة المرور التواصل مع شركة مدكور على الواتساب (${detail['rechargeDetails']['whatsappNumbers'].join(', ')}) من الرقم المسجل بالشركة',
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        Tab(text: 'IO Meter'),
                        Tab(text: 'Madkour Utilities'),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: TabBarView(
                        children: [
                          _buildRechargeSteps(
                            detail['rechargeDetails']['method1']['steps'],
                            'طريقة الشحن باستخدام IO Meter',
                            isMobile,
                          ),
                          _buildRechargeSteps(
                            detail['rechargeDetails']['method2']['steps'],
                            'طريقة الشحن باستخدام Madkour Utilities',
                            isMobile,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRechargeSteps(List<dynamic> steps, String title, bool isMobile) {
    final theme = ThemeManager().currentTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: ThemeManager.animationDuration,
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FadeInUp(
                duration: ThemeManager.animationDuration,
                delay: Duration(milliseconds: 100 * index),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.checkCircle,
                          size: isMobile ? 20 : 24,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step['description'],
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      step['image'],
                      height: isMobile ? 350 : 400,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'فشل تحميل الصورة',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.red,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
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
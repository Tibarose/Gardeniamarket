import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'homescreen/thememanager.dart';

class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({super.key});

  @override
  _CompanyDetailsScreenState createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> companyDetails = [
    {
      'title': 'مكتب إدارة خدمة العملاء',
      'subtitle': 'بمقر الشركة بعمارة 63 بالكمبوند',
      'icon': FontAwesomeIcons.locationDot,
      'mapUrl': 'https://maps.app.goo.gl/Z8Y3Q6uV4UrBphu77',
      'actionType': 'map',
    },
    {
      'title': 'الخط الساخن 24 ساعة',
      'subtitle': '15739',
      'icon': FontAwesomeIcons.phone,
      'phone': '15739',
      'actionType': 'phone',
    },
    {
      'title': 'موبايل الطوارئ فقط',
      'subtitle': '01098100113',
      'icon': FontAwesomeIcons.mobileAlt,
      'phone': '01098100113',
      'actionType': 'phone',
    },
    {
      'title': 'الموبايل أبلكيشن (Edara Egypt App)',
      'subtitle': 'Google Play و App Store',
      'icon': FontAwesomeIcons.appStore,
      'urls': [
        {'name': 'Google Play', 'url': 'https://rb.gy/cgzwhz'},
        {'name': 'App Store', 'url': 'https://rb.gy/idgai4'},
      ],
      'actionType': 'urls',
    },
    {
      'title': 'قناة التليجرام (لمعرفة التحديثات)',
      'subtitle': 'Telegram Channel',
      'icon': FontAwesomeIcons.telegram,
      'url': 'https://t.me/+OWq_GvW5IkFlZjRk',
      'actionType': 'url',
    },
    {
      'title': 'البريد الإلكتروني الخاص بالكمبوند',
      'subtitle': 'Complaint-Gardenia@edaraegypt.com',
      'icon': FontAwesomeIcons.envelope,
      'email': 'Complaint-Gardenia@edaraegypt.com',
      'actionType': 'email',
    },
    {
      'title': 'البريد الإلكتروني الخاص بإدارة خدمة العملاء',
      'subtitle': 'customerservice@edaraegypt.com',
      'icon': FontAwesomeIcons.headset,
      'email': 'customerservice@edaraegypt.com',
      'actionType': 'email',
    },
    {
      'title': 'البريد الخاص بمكتب السيد الرئيس التنفيذي للشركة',
      'subtitle': 'ceo@edaraegypt.com',
      'icon': FontAwesomeIcons.briefcase,
      'email': 'ceo@edaraegypt.com',
      'actionType': 'email',
    },
    {
      'title': 'مواعيد العمل',
      'subtitle': '',
      'icon': FontAwesomeIcons.clock,
      'workingHours': [
        {
          'department': 'إدارة خدمة العملاء',
          'hours': 'طوال أيام الأسبوع من الساعة 9 صباحاً وحتى الساعة 8 مساءً.\nالجمعة من الساعة 12 ظهراً إلى الساعة 8 مساءً.',
        },
        {
          'department': 'الملصق الإلكتروني وأكسيس',
          'hours': 'طوال أيام الأسبوع من الساعة 9 صباحاً وحتى الساعة 7 مساءً.\nالجمعة من الساعة 12 ظهراً إلى الساعة 8 مساءً.',
        },
        {
          'department': 'الإدارة الهندسية',
          'hours': 'من السبت إلى الخميس من الساعة 8 صباحاً وحتى الساعة 5 مساءً للتصاريح واسترداد المبالغ المالية.\nلمعرفة المخالفات حتى الساعة 8 مساءً.',
        },
        {
          'department': 'الإدارة المالية',
          'hours': 'طوال أيام الأسبوع من الساعة 9 صباحاً وحتى الساعة 8 مساءً.\nالجمعة من الساعة 12 ظهراً إلى الساعة 8 مساءً.',
        },
      ],
      'actionType': 'workingHours',
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
    final filteredDetails = companyDetails.where((detail) {
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
                              'شركة الإدارة',
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
                              'تفاصيل التواصل مع شركة الإدارة',
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

  void _launchEmail(BuildContext context, String? email) async {
    final theme = ThemeManager().currentTheme;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد بريد إلكتروني متاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'mailto:$email';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح البريد الإلكتروني.',
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
            'حدث خطأ أثناء فتح البريد الإلكتروني.',
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
🌟 تفاصيل شركة الإدارة من جاردينيا توداي 🌟
📋 $title
ℹ️ $subtitle
''';

    if (actionType == 'map') {
      final mapUrl = widget.detail['mapUrl']?.toString() ?? 'غير متوفر';
      shareText += '🗺️ $mapUrl\n';
    } else if (actionType == 'phone') {
      final phone = widget.detail['phone']?.toString() ?? 'غير متوفر';
      shareText += '📞 $phone\n';
    } else if (actionType == 'email') {
      final email = widget.detail['email']?.toString() ?? 'غير متوفر';
      shareText += '📧 $email\n';
    } else if (actionType == 'url') {
      final url = widget.detail['url']?.toString() ?? 'غير متوفر';
      shareText += '🔗 $url\n';
    } else if (actionType == 'urls') {
      final urls = widget.detail['urls'] as List<dynamic>? ?? [];
      for (var urlItem in urls) {
        final name = urlItem['name']?.toString() ?? 'رابط';
        final url = urlItem['url']?.toString() ?? 'غير متوفر';
        shareText += '🔗 $name: $url\n';
      }
    } else if (actionType == 'workingHours') {
      final workingHours = widget.detail['workingHours'] as List<dynamic>? ?? [];
      shareText += '⏰ مواعيد العمل:\n';
      for (var dept in workingHours) {
        final department = dept['department']?.toString() ?? 'غير معروف';
        final hours = dept['hours']?.toString() ?? 'غير متوفر';
        shareText += '- $department:\n$hours\n';
      }
    }

    shareText += '''
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

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
          onPhone: widget.detail['phone'] != null ? () => _launchPhone(context, widget.detail['phone']) : null,
          onEmail: widget.detail['email'] != null ? () => _launchEmail(context, widget.detail['email']) : null,
          onUrl: widget.detail['url'] != null ? () => _launchUrl(context, widget.detail['url']) : null,
          onUrls: widget.detail['urls'] != null ? (widget.detail['urls'] as List<dynamic>).map((urlItem) => () => _launchUrl(context, urlItem['url'])).toList() : [],
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
  final VoidCallback? onPhone;
  final VoidCallback? onEmail;
  final VoidCallback? onUrl;
  final List<VoidCallback> onUrls;
  final VoidCallback onShare;

  const DetailsBottomSheet({
    super.key,
    required this.detail,
    this.onMap,
    this.onPhone,
    this.onEmail,
    this.onUrl,
    required this.onUrls,
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
    int count = 1; // Share button is always present
    if (widget.onMap != null) count++;
    if (widget.onPhone != null) count++;
    if (widget.onEmail != null) count++;
    if (widget.onUrl != null) count++;
    if (widget.onUrls.isNotEmpty) count += widget.onUrls.length;
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
                                  if (widget.detail['actionType'] == 'workingHours') ...[
                                    const SizedBox(height: 12),
                                    ...((widget.detail['workingHours'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final dept = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: FadeInUp(
                                          duration: ThemeManager.animationDuration,
                                          delay: Duration(milliseconds: 100 * index),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                dept['department']?.toString() ?? 'غير معروف',
                                                style: GoogleFonts.cairo(
                                                  fontSize: isMobile ? 16 : 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dept['hours']?.toString() ?? 'غير متوفر',
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
                                  if (widget.onPhone != null)
                                    _buildActionButton(
                                      index: widget.onMap != null ? 1 : 0,
                                      icon: FontAwesomeIcons.phone,
                                      label: 'اتصال',
                                      onPressed: widget.onPhone!,
                                    ),
                                  if (widget.onEmail != null)
                                    _buildActionButton(
                                      index: (widget.onMap != null ? 1 : 0) + (widget.onPhone != null ? 1 : 0),
                                      icon: FontAwesomeIcons.envelope,
                                      label: 'إرسال بريد',
                                      onPressed: widget.onEmail!,
                                    ),
                                  if (widget.onUrl != null)
                                    _buildActionButton(
                                      index: (widget.onMap != null ? 1 : 0) + (widget.onPhone != null ? 1 : 0) + (widget.onEmail != null ? 1 : 0),
                                      icon: FontAwesomeIcons.link,
                                      label: 'زيارة',
                                      onPressed: widget.onUrl!,
                                    ),
                                  if (widget.onUrls.isNotEmpty)
                                    ...widget.onUrls.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final onUrl = entry.value;
                                      return _buildActionButton(
                                        index: (widget.onMap != null ? 1 : 0) + (widget.onPhone != null ? 1 : 0) + (widget.onEmail != null ? 1 : 0) + (widget.onUrl != null ? 1 : 0) + index,
                                        icon: FontAwesomeIcons.link,
                                        label: widget.detail['urls'][index]['name'],
                                        onPressed: onUrl,
                                      );
                                    }).toList(),
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
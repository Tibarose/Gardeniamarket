import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

import 'homescreen/thememanager.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  _PharmaciesScreenState createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  String _searchQuery = '';
  bool _showDeliveryOnly = false;
  final TextEditingController _searchController = TextEditingController();

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

  List<Map<String, dynamic>> _getPharmacies() {
    return [
      {
        'id': '089e22be-d79f-4695-93f9-6722f9234626',
        'name': 'صيدليه د/ بيتر كميل',
        'zone': 'زوون 5',
        'location': 'https://maps.app.goo.gl/iKp8btxRFxndGxqV6',
        'phone': ['01277332444', '01117743045'],
        'whatsapp': ['201013501717'],
        'delivery': true,
        'created_at': '2025-04-15 01:18:24.181957+00',
      },
      {
        'id': '0f64da62-2a48-42b2-8308-acbf7dcd5c5e',
        'name': 'صيدليه دواء',
        'zone': 'زوون 4',
        'location': 'https://maps.app.goo.gl/CMRcgfd9TqpTxm1w5',
        'phone': ['01155996753', '01555645450', '01021963140', '24485702'],
        'whatsapp': ['201155996753', '201555645450', '201021963140'],
        'delivery': true,
        'created_at': '2025-04-15 01:18:24.181957+00',
      },
      {
        'id': '114a84a3-e084-48b1-8c2c-c0eb509c0b4d',
        'name': 'صيدلية أحمد مختار',
        'zone': 'زوون 6',
        'location': 'https://maps.app.goo.gl/XjfGj8FPw4wGr34M6',
        'phone': ['01101240944', '01070094470', '0224090944'],
        'whatsapp': ['201101240944'],
        'delivery': true,
        'created_at': '2025-04-15 01:18:24.181957+00',
      },
      {
        'id': 'b80a904e-2b62-4c44-918d-9b0ea8819617',
        'name': 'صيدلية فارماسيا',
        'zone': 'مول جاردينيا سيتي',
        'location': 'https://maps.app.goo.gl/a1m7vjCVntn2meSG8',
        'phone': ['01050505677', '01120162015', '01211117206'],
        'whatsapp': ['201120162015'],
        'delivery': true,
        'created_at': '2025-04-15 01:18:24.181957+00',
      },
    ];
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
                              'الصيدليات',
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
                              'ابحث عن أقرب الصيدليات بسهولة',
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
                actions: [
                  FadeInRight(
                    duration: ThemeManager.animationDuration,
                    child: IconButton(
                      icon: FaIcon(
                        _showDeliveryOnly ? FontAwesomeIcons.truckMedical : FontAwesomeIcons.prescriptionBottleMedical,
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
                  child: Builder(
                    builder: (context) {
                      final pharmacies = _getPharmacies();
                      final filteredPharmacies = pharmacies.where((pharmacy) {
                        final name = pharmacy['name'].toString().toLowerCase();
                        final zone = pharmacy['zone'].toString().toLowerCase();
                        final query = _searchQuery.toLowerCase();
                        final matchesQuery = name.contains(query) || zone.contains(query);
                        final matchesDelivery = !_showDeliveryOnly || pharmacy['delivery'] == true;
                        return matchesQuery && matchesDelivery;
                      }).toList();

                      if (filteredPharmacies.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد صيدليات مطابقة',
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
                        itemCount: filteredPharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacy = filteredPharmacies[index];
                          return FadeInUp(
                            duration: Duration(milliseconds: 400 + (index * 150)),
                            child: PharmacyCard(
                              pharmacy: pharmacy,
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

class PharmacyCard extends StatefulWidget {
  final Map<String, dynamic> pharmacy;
  final Color cardColor;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.cardColor,
  });

  @override
  _PharmacyCardState createState() => _PharmacyCardState();
}

class _PharmacyCardState extends State<PharmacyCard> with SingleTickerProviderStateMixin {
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
        'مرحبًا من جاردينيا توداي! أود الاستفسار عن خدمات صيدلية ${name ?? widget.pharmacy['name'] ?? 'غير معروف'} 😊\n📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/',
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

  void _sharePharmacyDetails() {
    final name = widget.pharmacy['name']?.toString() ?? 'غير معروف';
    final zone = widget.pharmacy['zone']?.toString() ?? 'غير محدد';
    final phones = _parseContacts(widget.pharmacy['phone']);
    final whatsapps = _parseContacts(widget.pharmacy['whatsapp']);
    final location = widget.pharmacy['location']?.toString() ?? 'غير متوفر';
    final delivery = widget.pharmacy['delivery'] == true ? 'متاح' : 'غير متاح';

    final phonesText = phones.isNotEmpty ? '📞 ${phones.join(", ")}' : '📞 غير متوفر';
    final whatsappsText = whatsapps.isNotEmpty ? '💬 ${whatsapps.join(", ")}' : '💬 غير متوفر';

    final shareText = '''
🌟 تفاصيل الصيدلية من جاردينيا توداي 🌟
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

    Share.share(shareText.trim(), subject: 'تفاصيل صيدلية: $name');
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
          pharmacy: widget.pharmacy,
          phones: _parseContacts(widget.pharmacy['phone']),
          whatsapps: _parseContacts(widget.pharmacy['whatsapp']),
          onPhone: (contact) => _launchContact(context, contact, 'phone'),
          onWhatsApp: (contact) => _launchContact(context, contact, 'whatsapp'),
          onMap: () => _launchMap(context, widget.pharmacy['location']?.toString() ?? ''),
          onShare: _sharePharmacyDetails,
          showContactBottomSheet: (contacts, type) => _showContactBottomSheet(context, contacts, type),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hasDelivery = widget.pharmacy['delivery'] == true;

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
                      FontAwesomeIcons.prescriptionBottleMedical,
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
                                widget.pharmacy['name']?.toString() ?? 'غير معروف',
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
                                FontAwesomeIcons.prescriptionBottleMedical,
                                size: isMobile ? 22 : 26,
                                color: theme.primaryColor,
                                semanticLabel: 'أيقونة الصيدلية',
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
                                widget.pharmacy['zone']?.toString() ?? 'غير محدد',
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
                              FontAwesomeIcons.truckMedical,
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
  final Map<String, dynamic> pharmacy;
  final List<String> phones;
  final List<String> whatsapps;
  final Function(String) onPhone;
  final Function(String) onWhatsApp;
  final VoidCallback onMap;
  final VoidCallback onShare;
  final Function(List<String>, String) showContactBottomSheet;

  const DetailsBottomSheet({
    super.key,
    required this.pharmacy,
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
                                widget.pharmacy['name']?.toString() ?? 'غير معروف',
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
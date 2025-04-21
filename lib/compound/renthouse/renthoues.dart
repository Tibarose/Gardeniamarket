import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../main.dart';
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';
import 'addhouse.dart';

class RentHousesPage extends StatefulWidget {
  const RentHousesPage({super.key});

  @override
  _RentHousesPageState createState() => _RentHousesPageState();
}

class _RentHousesPageState extends State<RentHousesPage> {
  List<Map<String, dynamic>> houses = [];
  String _sortOption = 'الاقل الى الاعلى';
  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHousesData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHousesData() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('houses')
          .select()
          .eq('status', 'Active'); // Only fetch Active houses

      final List<Map<String, dynamic>> fetchedHouses = [];
      final currentDate = DateTime.now();

      for (var house in response) {
        final expiryDate = house['expiry_date'] as String?;
        if (expiryDate != null) {
          try {
            final expiryDateParsed = intl.DateFormat('d/M/yyyy').parse(expiryDate);
            if (expiryDateParsed.isAfter(currentDate)) {
              fetchedHouses.add(Map<String, dynamic>.from(house));
            }
          } catch (e) {
            print('Error parsing expiryDate: $e');
          }
        }
      }

      setState(() {
        houses = fetchedHouses;
        _sortHouses();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء جلب البيانات',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _sortHouses() {
    if (_sortOption == 'الاقل الى الاعلى') {
      houses.sort((a, b) =>
          int.parse(a['rent_price'].toString().replaceAll(',', '')).compareTo(
              int.parse(b['rent_price'].toString().replaceAll(',', ''))));
    } else if (_sortOption == 'الاعلى الى الاقل') {
      houses.sort((a, b) =>
          int.parse(b['rent_price'].toString().replaceAll(',', '')).compareTo(
              int.parse(a['rent_price'].toString().replaceAll(',', ''))));
    }
  }

  List<Map<String, dynamic>> _filterHouses() {
    if (_searchQuery.isEmpty) return houses;
    return houses.where((house) {
      final zone = house['zone']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return zone.contains(query);
    }).toList();
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
                              'تأجير الشقق',
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
                              'ابحث عن شقة الأحلام بسهولة',
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
                                  hintText: 'ابحث بالزوون...',
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddHousePageArabic()),
                          );
                        },
                        icon: FaIcon(
                          FontAwesomeIcons.plusCircle,
                          color: Colors.white,
                          size: isMobile ? 20 : 22,
                        ),
                        label: Text(
                          'إضافة شقة',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(ThemeManager.cardPadding),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ترتيب سعر الإيجار:',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                        ),
                        child: DropdownButton<String>(
                          value: _sortOption,
                          icon: FaIcon(
                            FontAwesomeIcons.arrowDown,
                            color: theme.primaryColor,
                            size: 16,
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          underline: const SizedBox(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _sortOption = newValue!;
                              _sortHouses();
                            });
                          },
                          items: <String>['الاقل الى الاعلى', 'الاعلى الى الاقل']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: GoogleFonts.cairo()),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(ThemeManager.cardPadding),
                sliver: _isLoading
                    ? SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
                  ),
                )
                    : _filterHouses().isEmpty
                    ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لا يوجد شقق متاحة حاليًا',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: theme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddHousePageArabic(),
                              ),
                            );
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.plusCircle,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            'اعرض شقة للإيجار',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isMobile ? 400 : 380,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isMobile ? 0.85 : 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final house = _filterHouses()[index];
                      return FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        child: HouseCard(
                          house: house,
                          cardColor: theme.cardColors[index % theme.cardColors.length],
                        ),
                      );
                    },
                    childCount: _filterHouses().length,
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

class HouseCard extends StatefulWidget {
  final Map<String, dynamic> house;
  final Color cardColor;

  const HouseCard({
    super.key,
    required this.house,
    required this.cardColor,
  });

  @override
  _HouseCardState createState() => _HouseCardState();
}

class _HouseCardState extends State<HouseCard> with SingleTickerProviderStateMixin {
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
          house: widget.house,
          onPhone: (phone) => _launchPhone(context, phone),
          onWhatsApp: (phone) => _launchWhatsApp(context, phone),
          onMap: () => _launchMap(context, widget.house['location']?.toString() ?? ''),
          onShare: _shareHouseDetails,
        );
      },
    );
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن إجراء المكالمة',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    final message = Uri.encodeComponent(
      'مرحبًا، أود الاستفسار عن الشقة المعروضة للإيجار في تطبيق جاردينيا توداي في ${widget.house['zone'] ?? 'غير معروف'} 😊',
    );
    final url = 'https://wa.me/2$phone?text=$message';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن فتح WhatsApp',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareHouseDetails() {
    final zone = widget.house['zone']?.toString() ?? 'غير معروف';
    final rentPrice = widget.house['rent_price']?.toString() ?? 'غير محدد';
    final period = widget.house['selected_period']?.toString() ?? 'غير محدد';
    final phone = widget.house['phone']?.toString() ?? 'غير متوفر';

    final shareText = '''
🏡 شقة للإيجار من جاردينيا توداي 🏡
📍 زون: $zone
💰 $rentPrice جم / $period
📞 $phone
🏡 تم العثور على تفاصيل الشقة عبر تطبيق جاردينيا توداي
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

    Share.share(shareText.trim(), subject: 'شقة للإيجار: $zone');
  }

  Future<void> _launchMap(BuildContext context, String mapUrl) async {
    if (await canLaunchUrl(Uri.parse(mapUrl))) {
      await launchUrl(Uri.parse(mapUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن فتح الخريطة',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(ThemeManager.cardBorderRadius),
                  ),
                  child: Container(
                    height: isMobile ? 150 : 180,
                    width: double.infinity,
                    child: widget.house['images'] != null &&
                        widget.house['images'] is List &&
                        (widget.house['images'] as List).isNotEmpty
                        ? Image.network(
                      (widget.house['images'] as List).first,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                            strokeWidth: 3,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(ThemeManager.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElasticIn(
                        duration: ThemeManager.animationDuration,
                        child: Text(
                          '${widget.house['rent_price']?.toString() ?? 'غير محدد'} جم / ${widget.house['selected_period']?.toString() ?? ''}',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 20 : 22,
                            fontWeight: FontWeight.w800,
                            color: theme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Text(
                          'فترة الإيجار: ${widget.house['period']?.toString() ?? 'غير محدد'}',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Text(
                          'زون: ${widget.house['zone']?.toString() ?? 'غير معروف'}',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.bed,
                                  size: isMobile ? 16 : 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.house['room']?.toString() ?? 'غير محدد',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 14 : 15,
                                    color: theme.secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.bath,
                                  size: isMobile ? 16 : 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.house['bathroom']?.toString() ?? 'غير محدد',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 14 : 15,
                                    color: theme.secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.rulerCombined,
                                  size: isMobile ? 16 : 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.house['space'] != null
                                      ? '${widget.house['space']} م²'
                                      : 'غير محدد',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 14 : 15,
                                    color: theme.secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
  final Map<String, dynamic> house;
  final Function(String) onPhone;
  final Function(String) onWhatsApp;
  final VoidCallback onMap;
  final VoidCallback onShare;

  const DetailsBottomSheet({
    super.key,
    required this.house,
    required this.onPhone,
    required this.onWhatsApp,
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
                child: SingleChildScrollView(
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
                                  widget.house['zone']?.toString() ?? 'غير معروف',
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
                      const SizedBox(height: 16),
                      if (widget.house['images'] != null && widget.house['images'] is List)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: isMobile ? 200 : 250,
                              enlargeCenterPage: true,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 3),
                              viewportFraction: 1.0,
                            ),
                            items: (widget.house['images'] as List).map<Widget>((imageUrl) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: theme.primaryColor,
                                          strokeWidth: 3,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.image,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفاصيل الشقة',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (widget.house['rent_price'] != null)
                                _buildDetailRow(
                                  label: 'الإيجار',
                                  value: '${widget.house['rent_price']} جم / ${widget.house['selected_period'] ?? ''}',
                                  theme: theme,
                                ),
                              if (widget.house['space'] != null)
                                _buildDetailRow(
                                  label: 'المساحة',
                                  value: '${widget.house['space']} م²',
                                  theme: theme,
                                ),
                              if (widget.house['room'] != null)
                                _buildDetailRow(
                                  label: 'الغرف',
                                  value: widget.house['room'].toString(),
                                  theme: theme,
                                ),
                              if (widget.house['bathroom'] != null)
                                _buildDetailRow(
                                  label: 'الحمامات',
                                  value: widget.house['bathroom'].toString(),
                                  theme: theme,
                                ),
                              if (widget.house['floor'] != null)
                                _buildDetailRow(
                                  label: 'الطابق',
                                  value: widget.house['floor'],
                                  theme: theme,
                                ),
                              if (widget.house['furnished'] != null)
                                _buildDetailRow(
                                  label: 'مفروشة',
                                  value: widget.house['furnished'],
                                  theme: theme,
                                ),
                              if (widget.house['insurance'] != null)
                                _buildDetailRow(
                                  label: 'التأمين',
                                  value: '${widget.house['insurance']} جم',
                                  theme: theme,
                                ),
                              if (widget.house['period'] != null)
                                _buildDetailRow(
                                  label: 'فترة الإيجار',
                                  value: widget.house['period'],
                                  theme: theme,
                                ),
                              if (widget.house['amenities'] != null && widget.house['amenities'] is List)
                                _buildDetailRow(
                                  label: 'المرافق',
                                  value: (widget.house['amenities'] as List).join(', '),
                                  theme: theme,
                                ),
                              if (widget.house['notes'] != null)
                                _buildDetailRow(
                                  label: 'الملاحظات',
                                  value: widget.house['notes'],
                                  theme: theme,
                                ),
                              if (widget.house['presenter'] != null)
                                _buildDetailRow(
                                  label: 'المعلن',
                                  value: widget.house['presenter'],
                                  theme: theme,
                                ),
                              if (widget.house['contact'] != null)
                                _buildDetailRow(
                                  label: 'التواصل',
                                  value: widget.house['contact'],
                                  theme: theme,
                                  textColor: widget.house['contact'] == 'المستأجر مباشره فقط'
                                      ? Colors.red
                                      : theme.textColor,
                                  fontWeight: widget.house['contact'] == 'المستأجر مباشره فقط'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                                              onPressed: () {
                                                final phone = widget.house['phone']?.toString();
                                                if (phone != null && phone.isNotEmpty) {
                                                  widget.onPhone(phone);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'رقم الهاتف غير متوفر',
                                                        style: GoogleFonts.cairo(
                                                            color: Colors.white, fontSize: 14),
                                                      ),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              backgroundColor: theme.primaryColor,
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.phone,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
                                              ),
                                              tooltip: 'اتصال',
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
                                                final phone = widget.house['phone']?.toString();
                                                if (phone != null && phone.isNotEmpty) {
                                                  widget.onWhatsApp(phone);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'رقم الهاتف غير متوفر',
                                                        style: GoogleFonts.cairo(
                                                            color: Colors.white, fontSize: 14),
                                                      ),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                              backgroundColor: theme.accentColor,
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.whatsapp,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
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
                                          children: [
                                            FloatingActionButton(
                                              onPressed: widget.onMap,
                                              backgroundColor: theme.primaryColor,
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.map,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
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
                                          children: [
                                            FloatingActionButton(
                                              onPressed: widget.onShare,
                                              backgroundColor: theme.accentColor,
                                              elevation: 2,
                                              child: FaIcon(
                                                FontAwesomeIcons.share,
                                                size: isMobile ? 24 : 28,
                                                color: Colors.white,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required dynamic theme,
    Color? textColor,
    FontWeight? fontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: fontWeight ?? FontWeight.w500,
                color: textColor ?? theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
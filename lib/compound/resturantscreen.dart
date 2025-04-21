import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import 'core/config/supabase_config.dart';
import 'homescreen/thememanager.dart';

class Restaurant {
  final String name;
  final String category;
  final String cuisineType;
  final String id;
  final String location;
  final String locationUrl;
  final String phoneNumber;
  final String? whatsappNumber;
  final String? menuLink;
  final String imageUrl;
  final bool isInCompound;

  Restaurant({
    required this.name,
    required this.category,
    required this.cuisineType,
    required this.id,
    required this.location,
    required this.locationUrl,
    required this.phoneNumber,
    this.whatsappNumber,
    this.menuLink,
    required this.imageUrl,
    required this.isInCompound,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      cuisineType: json['cuisine_type'],
      location: json['location'],
      locationUrl: json['location_url'],
      phoneNumber: json['phone_number'],
      whatsappNumber: json['whatsapp_number'],
      menuLink: json['menu_link'],
      imageUrl: json['image_url'],
      isInCompound: json['is_in_compound'] ?? false,
    );
  }
}

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  _RestaurantsScreenState createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _showDeliveryOnly = false;
  String _selectedCuisine = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  final List<String> _cuisineTypes = [
    'الكل',
    'مأكولات شرقية',
    'إفطار',
    'شاورما',
    'وجبات سريعة',
    'مأكولات سورية',
    'كافيه',
    'ذره بالجبنه',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchRestaurants(BuildContext context) async {
    final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
    try {
      final response = await supabaseConfig.secondaryClient.from('restaurants').select();
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

  Widget _buildRestaurantList(BuildContext context, bool? isInCompound) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRestaurants(context),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.utensils,
                  size: 60,
                  color: theme.secondaryTextColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  snapshot.hasError ? 'خطأ في جلب البيانات' : 'لا توجد مطاعم متاحة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: theme.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final filteredRestaurants = snapshot.data!.where((restaurant) {
          final name = restaurant['name'].toString().toLowerCase();
          final location = restaurant['location'].toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          final matchesQuery = name.contains(query) || location.contains(query);
          final matchesDelivery = !_showDeliveryOnly || restaurant['phone_number'] != 'Not available';
          final matchesCuisine = _selectedCuisine == 'الكل' || restaurant['cuisine_type'] == _selectedCuisine;
          final matchesCompound = isInCompound == null ||
              (isInCompound == true && restaurant['is_in_compound'] == true) ||
              (isInCompound == false && restaurant['is_in_compound'] == false);
          return matchesQuery && matchesDelivery && matchesCuisine && matchesCompound;
        }).toList();

        if (filteredRestaurants.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.utensils,
                  size: 60,
                  color: theme.secondaryTextColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مطاعم مطابقة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: theme.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = filteredRestaurants[index];
            return FadeInUp(
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RestaurantCard(
                  restaurant: restaurant,
                  cardColor: theme.cardColors[index % theme.cardColors.length],
                ),
              ),
            );
          },
        );
      },
    );
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
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: isMobile ? 300 : 320,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: theme.appBarGradient,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElasticIn(
                                duration: ThemeManager.animationDuration,
                                child: Text(
                                  'المطاعم والكافيهات',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 30 : 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              FadeInRight(
                                duration: ThemeManager.animationDuration,
                                child: IconButton(
                                  icon: FaIcon(
                                    _showDeliveryOnly ? FontAwesomeIcons.truck : FontAwesomeIcons.utensils,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  tooltip: _showDeliveryOnly ? 'إظهار الكل' : 'إظهار التوصيل فقط',
                                  onPressed: () {
                                    setState(() => _showDeliveryOnly = !_showDeliveryOnly);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FadeInDown(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              'اكتشف أشهى المأكولات داخل وخارج الكمبوند',
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن مطعم أو نوع مأكولات...',
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
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _cuisineTypes.length,
                              itemBuilder: (context, index) {
                                final cuisine = _cuisineTypes[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: ChoiceChip(
                                    label: Text(
                                      cuisine,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedCuisine == cuisine ? Colors.white : theme.textColor,
                                      ),
                                    ),
                                    selected: _selectedCuisine == cuisine,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCuisine = selected ? cuisine : 'الكل';
                                      });
                                    },
                                    selectedColor: theme.primaryColor,
                                    backgroundColor: theme.cardBackground.withOpacity(0.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: _selectedCuisine == cuisine ? 4 : 0,
                                  ),
                                );
                              },
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
                      size: 26,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'رجوع',
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                bottom: TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.cairo(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.cairo(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  indicatorColor: theme.accentColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'داخل الكمبوند'),
                    Tab(text: 'خارج الكمبوند'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildRestaurantList(context, true), // Inside compound
                _buildRestaurantList(context, false), // Outside compound
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestaurantCard extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final Color cardColor;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.cardColor,
  });

  @override
  _RestaurantCardState createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parsePhoneNumbers(String phoneNumber) {
    if (phoneNumber == 'Not available') {
      return [];
    }
    return phoneNumber.split(',').map((number) => number.trim()).toList();
  }

  void _showContactBottomSheet(BuildContext context, List<String> contacts, String type) {
    final theme = ThemeManager().currentTheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.cardBackground,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        duration: Duration(milliseconds: 200 + (index * 100)),
                        child: Card(
                          elevation: 3,
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

  void _launchContact(BuildContext context, String contact, String type) async {
    String url;
    if (type == 'phone') {
      url = 'tel:$contact';
    } else {
      final message = Uri.encodeComponent(
        'مرحبًا من جاردينيا توداي! أود الاستفسار عن مطعم ${widget.restaurant['name'] ?? 'غير معروف'} 😊',
      );
      url = 'https://wa.me/$contact?text=$message';
    }

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: type == 'whatsapp' ? LaunchMode.externalApplication : LaunchMode.platformDefault);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: $e',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _launchMap(BuildContext context, String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: $e',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _launchMenu(BuildContext context, String? menuLink) async {
    if (menuLink == null || menuLink.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'رابط القائمة غير متوفر.',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      if (await canLaunchUrl(Uri.parse(menuLink))) {
        await launchUrl(Uri.parse(menuLink), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا يمكن فتح رابط القائمة.',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: $e',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareRestaurantDetails() {
    final name = widget.restaurant['name']?.toString() ?? 'غير معروف';
    final category = widget.restaurant['category']?.toString() ?? 'غير محدد';
    final cuisine = widget.restaurant['cuisine_type']?.toString() ?? 'غير محدد';
    final location = widget.restaurant['location']?.toString() ?? 'غير محدد';
    final phone = widget.restaurant['phone_number']?.toString() ?? '';
    final whatsapp = widget.restaurant['whatsapp_number']?.toString();
    final menuLink = widget.restaurant['menu_link']?.toString();
    final locationUrl = widget.restaurant['location_url']?.toString() ?? '';
    final delivery = widget.restaurant['phone_number'] != 'Not available' ? 'متاح' : 'غير متاح';
    final compoundStatus = widget.restaurant['is_in_compound'] == true ? 'داخل الكمبوند' : 'خارج الكمبوند';

    final List<String> shareLines = [
      '🌟 تفاصيل المطعم من جاردينيا توداي 🌟',
      '🍽️ $name',
      '📖 $category',
      '🍴 نوع المأكولات: $cuisine',
      '📍 $location',
      '🏠 الموقع: $compoundStatus',
    ];

    if (phone.isNotEmpty && phone != 'Not available') {
      shareLines.add('📞 التليفون: $phone');
    }
    if (whatsapp != null && whatsapp.isNotEmpty) {
      shareLines.add('💬 واتساب: $whatsapp');
    }
    if (menuLink != null && menuLink.isNotEmpty) {
      shareLines.add('📋 قائمة الطعام: $menuLink');
    }
    if (locationUrl.isNotEmpty && locationUrl != 'غير متوفر') {
      shareLines.add('🗺️ الموقع: $locationUrl');
    }

    shareLines.add('🚚 دليفري: $delivery');
    shareLines.addAll([
      '📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/',
      '📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152',
      '📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday',
    ]);

    final shareText = shareLines.join('\n');

    Share.share(shareText.trim(), subject: 'تفاصيل مطعم: $name');
  }  void _showDetailsBottomSheet(BuildContext context) {
    final phones = _parsePhoneNumbers(widget.restaurant['phone_number'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DetailsBottomSheet(
          restaurant: widget.restaurant,
          phones: phones,
          whatsapps: widget.restaurant['whatsapp_number'] != null ? [widget.restaurant['whatsapp_number']] : [],
          onPhone: (contact) => _launchContact(context, contact, 'phone'),
          onWhatsApp: (contact) => _launchContact(context, contact, 'whatsapp'),
          onMap: () => _launchMap(context, widget.restaurant['location_url']?.toString() ?? ''),
          onMenu: () => _launchMenu(context, widget.restaurant['menu_link']?.toString()),
          onShare: _shareRestaurantDetails,
          showContactBottomSheet: (contacts, type) => _showContactBottomSheet(context, contacts, type),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hasDelivery = widget.restaurant['phone_number'] != 'Not available';
    final isInCompound = widget.restaurant['is_in_compound'] == true;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          _showDetailsBottomSheet(context);
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                  offset: const Offset(0, 6),
                  blurRadius: _isHovered ? 16 : 12,
                  spreadRadius: _isHovered ? 2 : 1,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  widget.cardColor,
                  widget.cardColor.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  left: -20,
                  child: Opacity(
                    opacity: 0.05,
                    child: FaIcon(
                      FontAwesomeIcons.utensils,
                      size: 100,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: widget.restaurant['image_url']?.toString() ?? '',
                        height: isMobile ? 120 : 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.primaryColor.withOpacity(0.1),
                          child: FaIcon(
                            FontAwesomeIcons.store,
                            color: theme.primaryColor,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElasticIn(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              widget.restaurant['name']?.toString() ?? 'غير معروف',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 20 : 22,
                                fontWeight: FontWeight.w800,
                                color: theme.textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              widget.restaurant['cuisine_type']?.toString() ?? 'غير محدد',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 14 : 15,
                                color: theme.secondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            child: Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.mapMarkerAlt,
                                  size: isMobile ? 16 : 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.restaurant['location']?.toString() ?? 'غير محدد',
                                    style: GoogleFonts.cairo(
                                      fontSize: isMobile ? 14 : 15,
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
                                  size: isMobile ? 16 : 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'دليفري: ${hasDelivery ? 'متاح' : 'غير متاح'}',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 14 : 15,
                                    color: hasDelivery ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
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
                                  FontAwesomeIcons.home,
                                  size: isMobile ? 16 : 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isInCompound ? 'داخل الكمبوند' : 'خارج الكمبوند',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 14 : 15,
                                    color: isInCompound ? Colors.blue : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
  final Map<String, dynamic> restaurant;
  final List<String> phones;
  final List<String> whatsapps;
  final Function(String) onPhone;
  final Function(String) onWhatsApp;
  final VoidCallback onMap;
  final Function() onMenu;
  final VoidCallback onShare;
  final Function(List<String>, String) showContactBottomSheet;

  const DetailsBottomSheet({
    super.key,
    required this.restaurant,
    required this.phones,
    required this.whatsapps,
    required this.onPhone,
    required this.onWhatsApp,
    required this.onMap,
    required this.onMenu,
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
  late int buttonCount;

  @override
  void initState() {
    super.initState();

    // Determine number of buttons based on available actions
    buttonCount = 3; // Phone, Map, Share
    if (widget.whatsapps.isNotEmpty) buttonCount++;
    if (widget.restaurant['menu_link'] != null && widget.restaurant['menu_link'].isNotEmpty) buttonCount++;

    // Sheet slide animation
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

    // Button animations
    _buttonControllers = List.generate(
      buttonCount,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _scaleAnimations = _buttonControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    ))
        .toList();
    _fadeAnimations = _buttonControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    ))
        .toList();
    _translateAnimations = _buttonControllers
        .map((controller) => Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    ))
        .toList();

    // Start animations
    _sheetController.forward();
    for (int i = 0; i < _buttonControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + (i * 50)), () {
        if (mounted) _buttonControllers[i].forward();
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
    final isInCompound = widget.restaurant['is_in_compound'] == true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _sheetController,
        builder: (context, child) {
          return SlideTransition(
            position: _sheetAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height, // Full screen height
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full-width image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: CachedNetworkImage(
                            imageUrl: widget.restaurant['image_url']?.toString() ?? '',
                            height: isMobile ? 250 : 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.primaryColor.withOpacity(0.1),
                              child: FaIcon(
                                FontAwesomeIcons.store,
                                color: theme.primaryColor,
                                size: 100,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Spin(
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
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElasticIn(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              widget.restaurant['name']?.toString() ?? 'غير معروف',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 24 : 28,
                                fontWeight: FontWeight.w800,
                                color: theme.textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.restaurant['cuisine_type']?.toString() ?? 'غير محدد',
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: theme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              isInCompound ? 'داخل الكمبوند' : 'خارج الكمبوند',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: isInCompound ? Colors.blue : Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: List.generate(buttonCount, (index) {
                                  final buttonIndex = index;
                                  if (index == 0 && widget.phones.isNotEmpty) {
                                    return _buildAnimatedButton(
                                      context,
                                      buttonIndex,
                                      icon: FontAwesomeIcons.phone,
                                      label: 'الاتصال',
                                      color: theme.primaryColor,
                                      onPressed: () {
                                        if (widget.phones.length > 1) {
                                          widget.showContactBottomSheet(widget.phones, 'phone');
                                        } else {
                                          widget.onPhone(widget.phones.first);
                                        }
                                      },
                                    );
                                  }
                                  if (index == (widget.phones.isNotEmpty ? 1 : 0) && widget.whatsapps.isNotEmpty) {
                                    return _buildAnimatedButton(
                                      context,
                                      buttonIndex,
                                      icon: FontAwesomeIcons.whatsapp,
                                      label: 'واتساب',
                                      color: theme.accentColor,
                                      onPressed: () {
                                        if (widget.whatsapps.length > 1) {
                                          widget.showContactBottomSheet(widget.whatsapps, 'whatsapp');
                                        } else {
                                          widget.onWhatsApp(widget.whatsapps.first);
                                        }
                                      },
                                    );
                                  }
                                  if (index == (widget.phones.isNotEmpty ? (widget.whatsapps.isNotEmpty ? 2 : 1) : (widget.whatsapps.isNotEmpty ? 1 : 0))) {
                                    return _buildAnimatedButton(
                                      context,
                                      buttonIndex,
                                      icon: FontAwesomeIcons.map,
                                      label: 'الموقع',
                                      color: theme.primaryColor,
                                      onPressed: widget.onMap,
                                    );
                                  }
                                  if (index == (widget.phones.isNotEmpty ? (widget.whatsapps.isNotEmpty ? 3 : 2) : (widget.whatsapps.isNotEmpty ? 2 : 1)) &&
                                      widget.restaurant['menu_link'] != null &&
                                      widget.restaurant['menu_link'].isNotEmpty) {
                                    return _buildAnimatedButton(
                                      context,
                                      buttonIndex,
                                      icon: FontAwesomeIcons.utensils,
                                      label: 'القائمة',
                                      color: theme.primaryColor,
                                      onPressed: widget.onMenu,
                                    );
                                  }
                                  return _buildAnimatedButton(
                                    context,
                                    buttonIndex,
                                    icon: FontAwesomeIcons.share,
                                    label: 'مشاركة',
                                    color: theme.accentColor,
                                    onPressed: widget.onShare,
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedButton(
      BuildContext context,
      int index, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onPressed,
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
                    backgroundColor: color,
                    elevation: 2,
                    child: FaIcon(
                      icon,
                      size: isMobile ? 24 : 28,
                      color: Colors.white,
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
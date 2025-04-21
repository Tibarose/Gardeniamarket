import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/compound/renthouse/SellApartmentsPage.dart';
import 'package:gardeniamarket/compound/renthouse/renthoues.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'adminpane/adminpanel.dart';
import 'homescreen/favouritenotify.dart';
import 'homescreen/online_services.dart';
import 'homescreen/thememanager.dart';
import 'home_screen.dart';

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  _SearchBottomSheetState createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();
  String _searchQuery = '';
  List<String> _recentSearches = [];
  List<String> _lastVisitedServices = [];
  String _selectedCategory = 'الكل';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadLastVisitedServices();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOutSine),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.bounceOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    // Unfocus the TextField to stop any ongoing editing
    _focusNode.unfocus();
    // Cancel any scheduled callbacks
    _debounce?.cancel();
    // Dispose of controllers
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      if (mounted) {
        setState(() {
          _recentSearches = searches;
        });
      }
    } catch (e) {
      print('Error loading recent searches: $e');
      _showErrorSnackBar('خطأ في تحميل عمليات البحث الأخيرة');
    }
  }

  Future<void> _loadLastVisitedServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final services = prefs.getStringList('last_visited_services') ?? [];
      if (mounted) {
        setState(() {
          _lastVisitedServices = services;
        });
      }
    } catch (e) {
      print('Error loading last visited services: $e');
      _showErrorSnackBar('خطأ في تحميل الخدمات التي تم زيارتها');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _recentSearches.remove(query);
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) _recentSearches.removeLast();
          prefs.setStringList('recent_searches', _recentSearches);
        });
      }
    } catch (e) {
      print('Error saving recent search: $e');
      _showErrorSnackBar('خطأ في حفظ عملية البحث');
    }
  }

  Future<void> _saveLastVisitedService(String serviceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _lastVisitedServices.remove(serviceName);
          _lastVisitedServices.insert(0, serviceName);
          if (_lastVisitedServices.length > 5) _lastVisitedServices.removeLast();
          prefs.setStringList('last_visited_services', _lastVisitedServices);
        });
      }
    } catch (e) {
      print('Error saving last visited service: $e');
      _showErrorSnackBar('خطأ في حفظ الخدمة التي تم زيارتها');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _recentSearches.clear();
          prefs.setStringList('recent_searches', _recentSearches);
        });
      }
    } catch (e) {
      print('Error clearing recent searches: $e');
      _showErrorSnackBar('خطأ في مسح عمليات البحث الأخيرة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Text(
                                  'البحث',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 24 : 28,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.xmark,
                                    color: theme.textColor,
                                    size: isMobile ? 22 : 24,
                                  ),
                                  onPressed: () {
                                    // Unfocus the TextField before closing the bottom sheet
                                    _focusNode.unfocus();
                                    Navigator.pop(context);
                                  },
                                  tooltip: 'إغلاق',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(ThemeManager.cardPadding),
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade100,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                key: _textFieldKey,
                                controller: _searchController,
                                focusNode: _focusNode,
                                autofocus: true,
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن خدمة...',
                                  hintStyle: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: FadeTransition(
                                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
                                      ),
                                    ),
                                    child: FaIcon(
                                      FontAwesomeIcons.magnifyingGlass,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? ScaleTransition(
                                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: const Interval(0.6, 0.9, curve: Curves.bounceOut),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: FaIcon(
                                        FontAwesomeIcons.xmark,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        if (mounted) {
                                          setState(() => _searchQuery = '');
                                        }
                                      },
                                    ),
                                  )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                onChanged: (value) {
                                  _debounce?.cancel();
                                  _debounce = Timer(const Duration(milliseconds: 300), () {
                                    if (mounted) {
                                      setState(() => _searchQuery = value);
                                    }
                                  });
                                },
                                onSubmitted: (value) => _saveRecentSearch(value),
                                cursorColor: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(ThemeManager.cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_recentSearches.isNotEmpty) ...[
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'عمليات البحث الأخيرة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: theme.textColor,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _clearRecentSearches,
                                            child: Text(
                                              'مسح الكل',
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _recentSearches.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final search = entry.value;
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.2),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: _animationController,
                                              curve: Interval(
                                                0.4 + (index * 0.05),
                                                0.8 + (index * 0.05),
                                                curve: Curves.easeOutCubic,
                                              ),
                                            ),
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              _searchController.text = search;
                                              if (mounted) {
                                                setState(() => _searchQuery = search);
                                              }
                                              _saveRecentSearch(search);
                                            },
                                            child: Chip(
                                              label: Text(
                                                search,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  color: theme.textColor,
                                                ),
                                              ),
                                              backgroundColor: theme.cardBackground,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              elevation: 2,
                                              shadowColor: Colors.black.withOpacity(0.1),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ] else ...[
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
                                        ),
                                      ),
                                      child: Text(
                                        'لا توجد عمليات بحث سابقة',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          color: theme.secondaryTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                if (_lastVisitedServices.isNotEmpty) ...[
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
                                        ),
                                      ),
                                      child: Text(
                                        'الخدمات التي تم زيارتها مسبقًا',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_lastVisitedServices.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: ThemeManager.cardPadding),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.70,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  final serviceName = _lastVisitedServices[index];
                                  final service = ServicesGrid.services.firstWhere(
                                        (s) => s['name'] == serviceName,
                                    orElse: () => {},
                                  );
                                  final onlineService = OnlineServicesSection.onlineServices.firstWhere(
                                        (s) => s['title'] == serviceName,
                                    orElse: () => {},
                                  );
                                  if (service.isNotEmpty) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.2),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(
                                            0.5 + (index * 0.05),
                                            0.9 + (index * 0.05),
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      ),
                                      child: FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: ServiceCard(
                                          name: service['name'],
                                          icon: service['icon'],
                                          description: service['description'],
                                          category: service['category'],
                                          route: service['route'],
                                          cardColor: theme.cardColors[index % theme.cardColors.length],
                                          isFavorite: Provider.of<FavoritesProvider>(context).favorites.contains(service['name']),
                                          onFavoriteToggle: () {
                                            Provider.of<FavoritesProvider>(context, listen: false).toggleFavorite(service['name']);
                                          },
                                          onTap: () => _saveLastVisitedService(service['name']),
                                        ),
                                      ),
                                    );
                                  } else if (onlineService.isNotEmpty) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.2),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: _animationController,
                                          curve: Interval(
                                            0.5 + (index * 0.05),
                                            0.9 + (index * 0.05),
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                      ),
                                      child: FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: ServiceCard(
                                          name: onlineService['title'],
                                          icon: FontAwesomeIcons.building,
                                          description: onlineService['subtitle'],
                                          category: 'أونلاين',
                                          route: '',
                                          cardColor: theme.cardColors[index % theme.cardColors.length],
                                          isFavorite: Provider.of<FavoritesProvider>(context).favorites.contains(onlineService['title']),
                                          onFavoriteToggle: () {
                                            Provider.of<FavoritesProvider>(context, listen: false).toggleFavorite(onlineService['title']);
                                          },
                                          onTap: () {
                                            _saveLastVisitedService(onlineService['title']);
                                            if (onlineService['title'] == 'ايجار الشقق') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const RentHousesPage()),
                                              );
                                            } else if (onlineService['title'] == 'بيع الشقق') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const SellApartmentsPage()),
                                              );
                                            } else if (onlineService['title'] == 'العقارات') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const AdminPanelPage()),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                childCount: _lastVisitedServices.length,
                              ),
                            ),
                          ),
                      ],
                      if (_searchQuery.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.all(ThemeManager.cardPadding),
                          sliver: ServicesGrid(
                            searchQuery: _searchQuery,
                            selectedCategory: _selectedCategory,
                            favorites: Provider.of<FavoritesProvider>(context).favorites,
                            onFavoriteToggle: (name) {
                              Provider.of<FavoritesProvider>(context, listen: false).toggleFavorite(name);
                            },
                            onServiceTap: _saveLastVisitedService,
                            useSliver: true,
                          ),
                        ),
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
}
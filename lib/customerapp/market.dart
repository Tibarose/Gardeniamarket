import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardeniamarket/compound/homescreen/thememanager.dart'; // Import ThemeManager
import 'auth_provider.dart';
import 'deliverybottomsheet.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _carouselItems = [];
  Map<String, int> _cartQuantities = {};

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  int _currentCarouselIndex = 0;
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  Map<String, dynamic> _deliveryDetails = {
    'compound_id': null,
    'compound_name': null,
    'building': null,
    'apartment': null,
  };

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _initializeData();
  }

  void _setupListeners() {
    _searchController.addListener(_debouncedSearch);
    _scrollController.addListener(_infiniteScrollListener);
  }

  void _debouncedSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() {}));
  }

  void _infiniteScrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _fetchMoreProducts);
    }
  }

  Future<void> _initializeData() async {
    await _loadCachedData();
    _subscribeToRealtimeUpdates();
    await _fetchData();
    await _fetchDeliveryDetails();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _castList(List<dynamic>? input) {
    if (input == null) return [];
    return input.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _loadCachedData() async {
    final box = Hive.box('marketData');
    final cachedProducts = box.get('products');
    final cachedCategories = box.get('categories');
    final cachedCarousel = box.get('carouselItems');
    final cacheTimestamp = box.get('cacheTimestamp', defaultValue: 0);

    if (DateTime.now().millisecondsSinceEpoch - cacheTimestamp > 3600000) {
      await box.clear();
      return;
    }

    if (cachedProducts != null &&
        cachedCategories != null &&
        cachedCarousel != null) {
      setState(() {
        _products = _castList(cachedProducts);
        _categories = _castList(cachedCategories);
        _carouselItems = _castList(cachedCarousel);
      });
    }
  }

  Future<void> _fetchData({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) setState(() => _isLoading = true);
    final box = Hive.box('marketData');
    const maxRetries = 3;

    for (int retryCount = 0; retryCount < maxRetries && mounted; retryCount++) {
      try {
        final supabase = Provider.of<AuthProvider>(context, listen: false).supabase;

        final productsResponse = await supabase
            .from('products')
            .select(
            'id, name, price, image, offer_price, stock_quantity, thumbnail, category_id, market_categories(name)')
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .range((page - 1) * _pageSize, page * _pageSize - 1);

        final categoriesResponse = await supabase
            .from('market_categories')
            .select('id, name, image')
            .order('name');

        final carouselResponse = page == 1
            ? await supabase
            .from('carousel_items')
            .select('title, image_url, category_name')
            .limit(5)
            : _carouselItems;

        setState(() {
          if (page == 1) {
            _products = productsResponse.map((product) {
              return {
                'id': product['id'],
                'name': product['name'],
                'price': product['price'],
                'image': product['image'],
                'offer_price': product['offer_price'],
                'stock_quantity': product['stock_quantity'],
                'thumbnail': product['thumbnail'],
                'category_id': product['category_id'],
                'category_name':
                product['market_categories']?['name'] ?? 'غير مصنف',
              };
            }).toList();
            _categories = _castList(categoriesResponse);
            _carouselItems = _castList(carouselResponse);
          } else {
            final newProducts = productsResponse.map((product) {
              return {
                'id': product['id'],
                'name': product['name'],
                'price': product['price'],
                'image': product['image'],
                'offer_price': product['offer_price'],
                'stock_quantity': product['stock_quantity'],
                'thumbnail': product['thumbnail'],
                'category_id': product['category_id'],
                'category_name':
                product['market_categories']?['name'] ?? 'غير مصنف',
              };
            }).toList();
            if (newProducts.isNotEmpty) {
              _products.addAll(newProducts
                  .where((p) => !_products.any((existing) => existing['id'] == p['id'])));
            }
            _hasMoreData = newProducts.length == _pageSize;
          }
          _currentPage = page;
          _isLoading = false;
        });

        await box.putAll({
          'products': _products,
          'categories': _categories,
          'carouselItems': _carouselItems,
          'cacheTimestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return;
      } catch (e) {
        if (retryCount == maxRetries - 1) {
          setState(() => _isLoading = false);
          _showSnackBar('خطأ في تحميل البيانات: $e', Colors.redAccent);
        }
        await Future.delayed(Duration(seconds: 1 << retryCount));
      }
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (!_hasMoreData || _isFetchingMore) return;
    setState(() => _isFetchingMore = true);
    await _fetchData(page: _currentPage + 1);
    setState(() => _isFetchingMore = false);
  }

  void _subscribeToRealtimeUpdates() {
    final supabase = Provider.of<AuthProvider>(context, listen: false).supabase;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final box = Hive.box('marketData');

    authProvider.getUserDetails().then((userDetails) {
      if (userDetails != null) {
        final userMobile = userDetails['mobile_number'] as String;
        supabase
            .from('carts')
            .stream(primaryKey: ['id'])
            .eq('mobile_number', userMobile)
            .listen((data) {
          if (data.isNotEmpty && mounted) {
            final cartData = jsonDecode(data.first['products'] as String) as List<dynamic>;
            setState(() {
              _cartQuantities = {
                for (var item in cartData) item['id'].toString(): item['quantity'] as int
              };
            });
          } else if (mounted) {
            setState(() => _cartQuantities = {});
          }
        });
      }
    });

    supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .listen((data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          _products = data.map((product) {
            final category = _categories.firstWhere(
                  (cat) => cat['id'] == product['category_id'],
              orElse: () => {'name': 'غير مصنف'},
            );
            return {
              'id': product['id'],
              'name': product['name'],
              'price': product['price'],
              'image': product['image'],
              'offer_price': product['offer_price'],
              'stock_quantity': product['stock_quantity'],
              'thumbnail': product['thumbnail'],
              'category_id': product['category_id'],
              'category_name': category['name'],
            };
          }).toList();
        });
        box.put('products', _products);
      }
    });

    supabase.from('market_categories').stream(primaryKey: ['id']).listen((data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          _categories = _castList(data);
        });
        box.put('categories', _categories);
      }
    });

    supabase.from('carousel_items').stream(primaryKey: ['id']).listen((data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          _carouselItems = _castList(data);
        });
        box.put('carouselItems', _carouselItems);
      }
    });
  }

  Future<void> _fetchDeliveryDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUserId;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userDetails = await authProvider.getUserDetails();
    final mobileNumber = userDetails?['mobile_number'] as String?;
    final addressKey = mobileNumber != null ? 'delivery_address_$mobileNumber' : null;

    if (addressKey != null && prefs.containsKey(addressKey)) {
      final addressString = prefs.getString(addressKey);
      if (addressString != null) {
        final parts = addressString.split(', ');
        String? compoundName, building, apartment;
        for (var part in parts) {
          if (part.startsWith('كمبوند: ')) {
            compoundName = part.replaceFirst('كمبوند: ', '');
          } else if (part.startsWith('عمارة: ')) {
            building = part.replaceFirst('عمارة: ', '');
          } else if (part.startsWith('شقة: ')) {
            apartment = part.replaceFirst('شقة: ', '');
          }
        }
        if (compoundName != null) {
          setState(() {
            _deliveryDetails = {
              'compound_id': _deliveryDetails['compound_id'],
              'compound_name': compoundName,
              'building': building,
              'apartment': apartment,
            };
          });
          final box = Hive.box('userData');
          await box.put('deliveryDetails', _deliveryDetails);
          return;
        }
      }
    }

    final box = Hive.box('userData');
    final cachedDetails = box.get('deliveryDetails');
    if (cachedDetails != null) {
      setState(() => _deliveryDetails = Map<String, dynamic>.from(cachedDetails));
      return;
    }

    try {
      final response = await authProvider.supabase
          .from('users')
          .select('compound_id, building_number, apartment_number, compounds(name)')
          .eq('id', userId)
          .single();

      setState(() {
        _deliveryDetails = {
          'compound_id': response['compound_id'] as int?,
          'compound_name': response['compounds']?['name'] as String?,
          'building': response['building_number'] as String?,
          'apartment': response['apartment_number'] as String?,
        };
      });
      await box.put('deliveryDetails', _deliveryDetails);

      if (mobileNumber != null && _deliveryDetails['compound_name'] != null) {
        final addressString =
            'كمبوند: ${_deliveryDetails['compound_name']}, عمارة: ${_deliveryDetails['building'] ?? ''}, شقة: ${_deliveryDetails['apartment'] ?? ''}';
        await prefs.setString(addressKey!, addressString);
      }
    } catch (e) {
      _showSnackBar('خطأ في جلب تفاصيل التوصيل: $e', Colors.redAccent);
    }
  }

  Future<void> _saveDeliveryDetails(Map<String, dynamic> details) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUserId;
    if (userId == null) return;

    try {
      await authProvider.supabase.from('users').update({
        'compound_id': details['compound_id'],
        'building_number': details['building'],
        'apartment_number': details['apartment'],
      }).eq('id', userId);

      final box = Hive.box('userData');
      await box.put('deliveryDetails', details);

      final userDetails = await authProvider.getUserDetails();
      final mobileNumber = userDetails?['mobile_number'] as String?;
      if (mobileNumber != null) {
        final addressString =
            'كمبوند: ${details['compound_name']}, عمارة: ${details['building'] ?? ''}, شقة: ${details['apartment'] ?? ''}';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('delivery_address_$mobileNumber', addressString);
      }

      setState(() => _deliveryDetails = details);
      _showSnackBar('تم حفظ تفاصيل التوصيل بنجاح', ThemeManager().currentTheme.primaryColor);
    } catch (e) {
      _showSnackBar('خطأ في حفظ تفاصيل التوصيل: $e', Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius)),
        elevation: 6,
      ),
    );
  }

  List<Map<String, dynamic>> _getOfferProducts() {
    return _products.where((product) {
      final offerPrice = product['offer_price'];
      final price = product['price'];

      if (offerPrice == null || price == null) return false;

      final offerValue = double.tryParse(offerPrice.toString());
      final priceValue = double.tryParse(price.toString());

      return offerValue != null && priceValue != null && offerValue < priceValue;
    }).toList();
  }

  void _showRegisterDialog() {
    final theme = ThemeManager().currentTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius)),
        title: Text('تسجيل مطلوب',
            style: GoogleFonts.cairo(
                fontSize: 20, fontWeight: FontWeight.bold, color: theme.textColor)),
        content: Text('يرجى التسجيل لتتمكن من تصفح الفئات وإتمام الطلبات.',
            style: GoogleFonts.cairo(fontSize: 16, color: theme.secondaryTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    fontSize: 16, color: theme.secondaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 4,
            ),
            child: Text('تسجيل الآن',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: theme.backgroundColor,
          body: RefreshIndicator(
            onRefresh: () => _fetchData(isRefresh: true),
            color: theme.primaryColor,
            backgroundColor: theme.cardBackground,
            displacement: 40,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      backgroundColor: theme.cardBackground,
                      elevation: 4,
                      pinned: true,
                      expandedHeight: isDesktop ? 100.0 : 80.0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Column(
                            children: [_buildAppBar(authProvider, isDesktop)]),
                      ),
                    ),
                    if (!authProvider.isAuthenticated)
                      SliverToBoxAdapter(child: _buildRegisterCard(isDesktop)),
                    SliverToBoxAdapter(child: _buildDeliverySection(isDesktop)),
                    SliverToBoxAdapter(child: _buildCarousel(isDesktop)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 16, vertical: 16),
                        child: Text(
                          'اكتشف الماركت',
                          style: GoogleFonts.cairo(
                            fontSize: isDesktop ? 32 : 24,
                            fontWeight: FontWeight.w900,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                    ),
                    if (_getOfferProducts().isNotEmpty)
                      SliverToBoxAdapter(child: _buildOffersBanner(isDesktop)),
                    _isLoading
                        ? const SliverToBoxAdapter(child: ShimmerLoading())
                        : SliverToBoxAdapter(child: _buildCategoryGrid(isDesktop)),
                    if (_isFetchingMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: theme.primaryColor)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard(bool isDesktop) {
    final theme = ThemeManager().currentTheme;

    return FadeInUp(
      duration: ThemeManager.animationDuration,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 12),
        padding: const EdgeInsets.all(ThemeManager.cardPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(0.9),
              theme.accentColor.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.person_add,
                color: Colors.white, size: isDesktop ? 36 : 32),
            SizedBox(width: isDesktop ? 24 : 16),
            Expanded(
              child: Text(
                'سجل الآن لتتمكن من الطلب!',
                style: GoogleFonts.cairo(
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.cardBackground,
                foregroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(ThemeManager.cardBorderRadius)),
                padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 12 : 10),
                elevation: 4,
              ),
              child: Text(
                'تسجيل الآن',
                style: GoogleFonts.cairo(
                  fontSize: isDesktop ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider authProvider, bool isDesktop) {
    final theme = ThemeManager().currentTheme;

    return Container(
      color: theme.cardBackground,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ماركت جاردينيا',
              style: GoogleFonts.cairoPlay(
                fontSize: isDesktop ? 34 : 26,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
            Row(
              children: [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.shopping_cart,
                          color: theme.primaryColor,
                          size: isDesktop ? 34 : 28),
                      onPressed: () => Navigator.pushNamed(context, '/market',
                          arguments: {'tab': 2}),
                    ),
                    if (_cartQuantities.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: BounceInDown(
                          key: ValueKey(_cartQuantities.length),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              '${_cartQuantities.length}',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: isDesktop ? 14 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection(bool isDesktop) {
    final theme = ThemeManager().currentTheme;

    return FadeInUp(
      duration: ThemeManager.animationDuration,
      child: GestureDetector(
        onTap: _showDeliveryBottomSheet,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16, vertical: isDesktop ? 20 : 17),
          margin: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.location_on,
                  color: theme.primaryColor, size: isDesktop ? 30 : 26),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Text(
                  _deliveryDetails['compound_name'] != null
                      ? 'التوصيل إلى ${_deliveryDetails['compound_name']} -\n عمارة ${_deliveryDetails['building'] ?? ''} - شقة ${_deliveryDetails['apartment'] ?? ''}'
                      : 'حدد عنوان التوصيل',
                  style: GoogleFonts.cairo(
                    fontSize: isDesktop ? 18 : 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.edit,
                  size: isDesktop ? 26 : 22, color: theme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(bool isDesktop) {
    final theme = ThemeManager().currentTheme;
    final carouselHeight = isDesktop ? 320.0 : 200.0;

    if (_carouselItems.isEmpty && _isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: isDesktop ? 24 : 12),
        child: Shimmer.fromColors(
          baseColor: theme.secondaryTextColor.withOpacity(0.3),
          highlightColor: theme.secondaryTextColor.withOpacity(0.1),
          child: Container(
            height: carouselHeight,
            margin: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 24 : 16),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: _carouselItems.length,
            itemBuilder: (context, index, realIndex) {
              final item = _carouselItems[index];
              return GestureDetector(
                onTap: () => _navigateToCategory(item['category_name']),
                child: ElasticIn(
                  duration: ThemeManager.animationDuration,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 2),
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(ThemeManager.cardBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(ThemeManager.cardBorderRadius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                            item['image_url'] ?? 'https://via.placeholder.com/150',
                            fit: BoxFit.fill,
                            maxHeightDiskCache: isDesktop ? 400 : 200,
                            maxWidthDiskCache: isDesktop ? 400 : 200,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: theme.secondaryTextColor.withOpacity(0.3),
                              highlightColor:
                              theme.secondaryTextColor.withOpacity(0.1),
                              child: Container(color: theme.cardBackground),
                            ),
                            errorWidget: (context, url, error) => Icon(
                                Icons.error,
                                size: 50,
                                color: theme.accentColor),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                          if (item['title']?.isNotEmpty ?? false)
                            Positioned(
                              bottom: 20,
                              left: 16,
                              right: 16,
                              child: SlideInUp(
                                child: Text(
                                  item['title'],
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: isDesktop ? 26 : 20,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black.withOpacity(0.54),
                                          blurRadius: 6)
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: carouselHeight,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              enlargeCenterPage: true,
              viewportFraction: isDesktop ? 0.5 : 0.85,
              onPageChanged: (index, _) =>
                  setState(() => _currentCarouselIndex = index),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _carouselItems.map((item) {
              final index = _carouselItems.indexOf(item);
              return AnimatedContainer(
                duration: ThemeManager.animationDuration,
                width: _currentCarouselIndex == index
                    ? (isDesktop ? 36 : 28)
                    : (isDesktop ? 12 : 10),
                height: isDesktop ? 12 : 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.primaryColor
                      .withOpacity(_currentCarouselIndex == index ? 1 : 0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersBanner(bool isDesktop) {
    final theme = ThemeManager().currentTheme;

    return FadeInUp(
      duration: ThemeManager.animationDuration,
      child: GestureDetector(
        onTap: _navigateToOffers,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 12),
          padding: const EdgeInsets.all(ThemeManager.cardPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.local_offer,
                  color: Colors.white, size: isDesktop ? 44 : 36),
              SizedBox(width: isDesktop ? 24 : 16),
              Expanded(
                child: Text(
                  'العروض الحصرية - تسوق الآن ووفر المزيد!',
                  style: GoogleFonts.cairo(
                    fontSize: isDesktop ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: isDesktop ? 28 : 24),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOffers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showRegisterDialog();
      return;
    }

    final offerProducts = _getOfferProducts();
    if (offerProducts.isEmpty) {
      _showSnackBar('لا توجد عروض متاحة حاليًا', Colors.orangeAccent);
      return;
    }

    Navigator.pushNamed(
      context,
      '/categoryProducts',
      arguments: {
        'categoryName': 'العروض',
        'initialProducts': offerProducts,
        'cartQuantities': _cartQuantities,
        'categories': _categories,
      },
    ).then((updatedCart) {
      if (updatedCart != null && mounted) {
        setState(() {
          _cartQuantities = Map<String, int>.from(updatedCart as Map);
        });
      }
    });
  }

  Widget _buildCategoryGrid(bool isDesktop) {
    final theme = ThemeManager().currentTheme;
    final filtered = _categories
        .where((cat) => _products.any((prod) => prod['category_id'] == cat['id']))
        .where((cat) =>
        cat['name'].toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList();

    final List<Color> lightColors = [
      theme.cardBackground.withOpacity(0.8),
      theme.backgroundColor.withOpacity(0.9),
      theme.cardBackground.withOpacity(0.7),
      theme.backgroundColor.withOpacity(0.85),
      theme.cardBackground.withOpacity(0.9),
    ];

    if (filtered.isEmpty && _getOfferProducts().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ElasticIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront,
                    size: isDesktop ? 120 : 100,
                    color: theme.primaryColor.withOpacity(0.7)),
                const SizedBox(height: 20),
                Text(
                  'لا توجد فئات أو عروض متاحة',
                  style: GoogleFonts.cairo(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'اضغط على زر التحديث للمحاولة مجددًا',
                  style: GoogleFonts.cairo(
                    fontSize: isDesktop ? 18 : 16,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 3,
        childAspectRatio: isDesktop ? 0.9 : 0.8,
        crossAxisSpacing: isDesktop ? 20 : 10,
        mainAxisSpacing: isDesktop ? 20 : 14,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final category = filtered[index];
        final cardColor = lightColors[index % lightColors.length];
        return ZoomIn(
          delay: Duration(milliseconds: index * 150),
          duration: ThemeManager.animationDuration,
          child: CategoryCard(
            label: category['name'],
            imageUrl: category['image'] ?? 'https://via.placeholder.com/150',
            backgroundColor: cardColor,
            onTap: () => _navigateToCategory(category['name']),
          ),
        );
      },
    );
  }

  void _navigateToCategory(String? categoryName) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showRegisterDialog();
      return;
    }

    Navigator.pushNamed(
      context,
      '/categoryProducts',
      arguments: {
        'categoryName': categoryName,
        'initialProducts': _products,
        'cartQuantities': _cartQuantities,
        'categories': _categories,
      },
    ).then((updatedCart) {
      if (updatedCart != null && mounted) {
        setState(() {
          _cartQuantities = Map<String, int>.from(updatedCart as Map);
        });
      }
    });
  }

  void _showDeliveryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius))),
      builder: (context) => DeliveryBottomSheet(
          initialDetails: _deliveryDetails, onSave: _saveDeliveryDetails),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final String label;
  final String imageUrl;
  final Color backgroundColor;
  final VoidCallback onTap;

  const CategoryCard({
    required this.label,
    required this.imageUrl,
    required this.backgroundColor,
    required this.onTap,
    super.key,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  double scale = 1.0;
  late AnimationController _controller;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ThemeManager.animationDuration,
      vsync: this,
    );
    _shadowAnimation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => scale = 1.08);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => scale = 1.0);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => scale = 1.0);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_shadowAnimation.value),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.backgroundColor,
                    widget.backgroundColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(ThemeManager.cardBorderRadius),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        maxHeightDiskCache: 200,
                        maxWidthDiskCache: 200,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: theme.secondaryTextColor.withOpacity(0.3),
                          highlightColor: theme.secondaryTextColor.withOpacity(0.1),
                          child: Container(color: theme.cardBackground),
                        ),
                        errorWidget: (context, url, error) => Icon(
                            Icons.error,
                            size: 30,
                            color: theme.accentColor),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.25),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      widget.label,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: isDesktop ? 14 : 12,
                        color: theme.textColor,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 40 : 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 3,
        childAspectRatio: isDesktop ? 0.9 : 0.8,
        crossAxisSpacing: isDesktop ? 20 : 16,
        mainAxisSpacing: isDesktop ? 20 : 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: theme.secondaryTextColor.withOpacity(0.3),
        highlightColor: theme.secondaryTextColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
          ),
          child: Column(
            children: [
              Expanded(child: Container(color: theme.secondaryTextColor)),
              Container(
                height: 48,
                color: theme.secondaryTextColor,
                margin: const EdgeInsets.all(12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
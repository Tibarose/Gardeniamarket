import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/auth_provider.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'package:gardeniamarket/customerapp/productlst/ProductService.dart';
import 'package:gardeniamarket/customerapp/cartlist/cartprovider.dart';
import 'package:gardeniamarket/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quantity_controls.dart';
import 'shimmer_loading.dart';
import 'package:gardeniamarket/customerapp/bottombar.dart'; // Import BottomNavigation

class CategoryProductsPage extends StatefulWidget {
  final String? categoryName;
  final List<Map<String, dynamic>> initialProducts;
  final Map<String, int> cartQuantities;
  final List<Map<String, dynamic>> categories;

  const CategoryProductsPage({
    super.key,
    this.categoryName,
    required this.initialProducts,
    required this.cartQuantities,
    required this.categories,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  late final ProductService _productService;
  late Map<String, int> _cartQuantities;
  late List<Map<String, dynamic>> _products;
  late List<Map<String, dynamic>> _allProducts; // New list for all products
  late String? _selectedCategory;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _mobileNumber;
  bool _debugMode = true; // Set to false in production
  Map<String, bool> _favorites = {};
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = true;
  int _page = 1;
  Timer? _debounce;
  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _cartQuantities = Map.from(widget.cartQuantities);
    _products = widget.initialProducts;
    _allProducts = []; // Initialize the full product list
    _selectedCategory = widget.categoryName;

    _initialize();
    _scrollController.addListener(_onScroll);
  }
  Future<void> _fetchAllProducts() async {
    try {
      final allProducts = await _productService.fetchProducts(
        1, // Fetch first page; adjust if pagination is needed
        categoryName: null, // No category filter to get all products
        categories: widget.categories,
      );
      setState(() {
        _allProducts = allProducts;
      });
      if (_debugMode) {
        print('Fetched ${_allProducts.length} products for _allProducts');
        print('Categories in _allProducts: ${_allProducts.map((p) => p['category_name']).toSet()}');
      }
      await _productService.cacheProducts(_allProducts);
    } catch (e) {
      _showSnackBar('خطأ في جلب جميع المنتجات: $e', Colors.redAccent);
    }
  }
  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUserId;

    if (userId == null) {
      _showSnackBar('يرجى تسجيل الدخول', Colors.redAccent);
      setState(() => _isInitialLoading = false);
      return;
    }

    try {
      // Load cached products as a fallback
      _allProducts = await _productService.loadCachedProducts();
      if (_debugMode) {
        print('Loaded ${_allProducts.length} products from cache');
        print('Categories in _allProducts: ${_allProducts.map((p) => p['category_name']).toSet()}');
      }

      // Fetch all products for _allProducts
      await _fetchAllProducts();

      // Set _products based on the selected category
      if (_selectedCategory != 'العروض') {
        _products = _allProducts
            .where((p) => _selectedCategory == null || p['category_name'] == _selectedCategory)
            .toList();
      } else {
        _products = _allProducts.where(_isOfferProduct).toList();
      }
      setState(() {});

      _mobileNumber = await _productService.fetchMobileNumber(userId);
      if (_mobileNumber != null) {
        _setupRealtimeCart();
        _setupRealtimeProducts();
        _favorites = await _productService.fetchFavorites(_mobileNumber!);
      }

      if (await _productService.shouldRefreshCache()) {
        await _refreshProducts();
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء التحميل: $e', Colors.redAccent);
    } finally {
      setState(() => _isInitialLoading = false);
    }
  }
  void _setupRealtimeCart() {
    if (_mobileNumber == null) return;
    _productService.subscribeToCart(_mobileNumber!).listen((cart) {
      if (mounted) setState(() => _cartQuantities = cart);
    });
  }

  void _setupRealtimeProducts() {
    _productsSubscription = _productService.subscribeToProducts().listen((updatedProducts) {
      if (mounted) {
        setState(() {
          _allProducts = updatedProducts; // Update the full product list
          _products = _selectedCategory == 'العروض'
              ? updatedProducts.where(_isOfferProduct).toList()
              : updatedProducts
              .where((p) => _selectedCategory == null || p['category_name'] == _selectedCategory)
              .toList();
          _hasMoreData = true;
          _page = 1;
        });
        if (_debugMode) {
          print('Real-time update: ${_allProducts.length} products in _allProducts');
          print('Categories in _allProducts: ${_allProducts.map((p) => p['category_name']).toSet()}');
        }
        _productService.cacheProducts(_allProducts);
      }
    });
  }
  bool _isOfferProduct(Map<String, dynamic> product) {
    final offerPrice = product['offer_price'];
    final price = product['price'];
    final offerValue = double.tryParse(offerPrice?.toString() ?? '');
    final priceValue = double.tryParse(price?.toString() ?? '');
    return offerValue != null && priceValue != null && offerValue < priceValue;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _fetchMoreProducts);
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (!_hasMoreData || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final newProducts = await _productService.fetchProducts(
        _page,
        categoryName: _selectedCategory,
        categories: widget.categories,
      );
      setState(() {
        final filteredNewProducts = _selectedCategory == 'العروض'
            ? newProducts.where(_isOfferProduct).toList()
            : newProducts;
        _products.addAll(filteredNewProducts.where((p) => !_products.any((existing) => existing['id'] == p['id'])));
        _allProducts.addAll(newProducts.where((p) => !_allProducts.any((existing) => existing['id'] == p['id']))); // Update full list
        _page++;
        _hasMoreData = newProducts.length == AppConstants.pageSize;
      });
      await _productService.cacheProducts(_allProducts);
    } catch (e) {
      _showSnackBar('خطأ في تحميل المزيد: $e', Colors.redAccent);
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _page = 1;
      _hasMoreData = true;
      _products.clear();
      _isInitialLoading = true;
    });

    try {
      // Fetch all products for _allProducts
      await _fetchAllProducts();

      // Fetch filtered products for _products
      final newProducts = await _productService.fetchProducts(
        _page,
        categoryName: _selectedCategory,
        categories: widget.categories,
      );
      setState(() {
        final filteredNewProducts = _selectedCategory == 'العروض'
            ? newProducts.where(_isOfferProduct).toList()
            : newProducts;
        _products = filteredNewProducts;
        _page++;
        _hasMoreData = newProducts.length == AppConstants.pageSize;
      });
    } catch (e) {
      _showSnackBar('خطأ في التحديث: $e', Colors.redAccent);
    } finally {
      setState(() => _isInitialLoading = false);
    }
  }
  Future<void> _addToCart(Map<String, dynamic> product, {int quantity = 1}) async {
    if (_mobileNumber == null) {
      _showSnackBar('يرجى تسجيل الدخول', Colors.redAccent);
      return;
    }

    final productId = product['id'].toString();
    final currentQuantity = _cartQuantities[productId] ?? 0;
    final maxQuantity = product['max_quantity'] ?? product['stock_quantity'] ?? 10;
    final newQuantity = currentQuantity + quantity;

    if (newQuantity > maxQuantity) {
      _showSnackBar('الكمية المطلوبة تتجاوز الحد الأقصى المتاح', Colors.redAccent);
      return;
    }

    setState(() {
      if (newQuantity <= 0) {
        _cartQuantities.remove(productId);
      } else {
        _cartQuantities[productId] = newQuantity;
      }
    });

    try {
      await _productService.syncCart(_mobileNumber!, _cartQuantities);
      _showSnackBar(
        quantity > 0 ? 'تم إضافة ${product['name']}' : 'تم إزالة ${product['name']}',
        quantity > 0 ? AppConstants.awesomeColor : Colors.red,
      );
    } catch (e) {
      _showSnackBar('خطأ في مزامنة السلة: $e', Colors.redAccent);
      setState(() {
        _cartQuantities[productId] = currentQuantity;
        if (_cartQuantities[productId] == 0) _cartQuantities.remove(productId);
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = List<Map<String, dynamic>>.from(_products);
    if (_selectedCategory != null && _selectedCategory != 'العروض') {
      filtered = filtered.where((p) => p['category_name'] == _selectedCategory).toList();
    }
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((p) => p['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  List<Map<String, dynamic>> get _filteredCategories {
    return widget.categories.where((category) {
      return _allProducts.any((product) => product['category_name'] == category['name']);
    }).toList();
  }

  void _showCategoriesBottomSheet() {
    final categoriesWithItems = _filteredCategories;
    if (categoriesWithItems.isEmpty) {
      _showSnackBar(AppConstants.noCategoriesMessage, Colors.red);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.grey[100],
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height,
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الفئات',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: categoriesWithItems.length,
                      itemBuilder: (context, index) {
                        final category = categoriesWithItems[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category['name']);
                            Navigator.pop(context);
                            // Optionally refresh products for the selected category
                            _refreshProducts();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  offset: const Offset(4, 4),
                                  blurRadius: 8,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  offset: const Offset(-4, -4),
                                  blurRadius: 8,
                                ),
                              ],
                              border: _selectedCategory == category['name']
                                  ? Border.all(color: AppConstants.awesomeColor, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: category['image'] ?? '',
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category['name'],
                                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
        ),
      ),
    );
  }

  void _showProductBottomSheet(Map<String, dynamic> product) {
    int quantity = _cartQuantities[product['id'].toString()] ?? 0;
    bool isFavorite = _favorites[product['id'].toString()] ?? false;
    bool showQuantityControls = quantity > 0;
    final hasOffer = product['offer_price'] != null && product['offer_price'] != product['price'];
    double unitPrice = double.parse(hasOffer ? product['offer_price'].toString() : product['price'].toString());
    double totalPrice = quantity * unitPrice;
    bool isOutOfStock = (product['stock_quantity'] ?? 0) == 0;
    final maxQuantity = product['max_quantity'] ?? product['stock_quantity'] ?? 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[700], size: 24),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: product['image'] ?? '',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.error, color: Colors.grey[600], size: 50),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          if (hasOffer)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'عرض',
                                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product['name'],
                    style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasOffer)
                        Text(
                          '${product['price']} ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        '${hasOffer ? product['offer_price'] : product['price']} ج.م',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.awesomeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppConstants.gradientStart, AppConstants.gradientEnd]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product['category_name'] ?? 'غير مصنف',
                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'الوصف',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'] ?? 'لا يوجد وصف متاح',
                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  if (isOutOfStock)
                    Center(
                      child: Text(
                        'نفدت الكمية',
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    )
                  else if (showQuantityControls)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QuantityControlss(
                          quantity: quantity,
                          onQuantityChanged: (newQuantity) {
                            if (_mobileNumber == null) {
                              Navigator.pop(context);
                              _showSnackBar('يرجى تسجيل الدخول', Colors.redAccent);
                              return;
                            }
                            if (newQuantity > quantity) {
                              _addToCart(product, quantity: 1);
                              setModalState(() {
                                quantity = newQuantity;
                                totalPrice = quantity * unitPrice;
                              });
                            } else if (newQuantity < quantity) {
                              if (newQuantity > 0) {
                                _addToCart(product, quantity: -1);
                                setModalState(() {
                                  quantity = newQuantity;
                                  totalPrice = quantity * unitPrice;
                                });
                              } else {
                                _addToCart(product, quantity: -quantity);
                                setModalState(() {
                                  quantity = newQuantity;
                                  totalPrice = quantity * unitPrice;
                                  showQuantityControls = false;
                                });
                              }
                            }
                          },
                          maxQuantity: maxQuantity,
                          awesomeColor: AppConstants.awesomeColor,
                        ),
                        Text(
                          '${totalPrice.toStringAsFixed(2)} ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.awesomeColor,
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_mobileNumber == null) {
                            Navigator.pop(context);
                            _showSnackBar('يرجى تسجيل الدخول', Colors.redAccent);
                            return;
                          }
                          _addToCart(product, quantity: 1);
                          setModalState(() {
                            quantity = 1;
                            totalPrice = quantity * unitPrice;
                            showQuantityControls = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppConstants.gradientStart, AppConstants.gradientEnd]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.awesomeColor.withOpacity(0.4),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'أضف إلى السلة',
                              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          title: GestureDetector(
            onTap: _showCategoriesBottomSheet,
            child: Tooltip(
              message: 'اضغط لاختيار فئة أخرى',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCategory ?? 'جميع المنتجات',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.awesomeColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: AppConstants.awesomeColor,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: AppConstants.awesomeColor, size: 28),
                  onPressed: () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final cartProvider = Provider.of<CartProvider>(context, listen: false);
                    final supabase = Supabase.instance.client;

                    await cartProvider.fetchCartData(authProvider.currentUserId, supabase);

                    final navigator = MyApp.navigatorKey.currentState!;
                    bool isOnMarket = false;

                    navigator.popUntil((route) {
                      if (route.settings.name == '/market') {
                        isOnMarket = true;
                        return true;
                      }
                      return route.isFirst;
                    });

                    if (isOnMarket) {
                      navigator.pushReplacementNamed('/market', arguments: {'tab': 2});
                    } else {
                      navigator.pushReplacementNamed('/market', arguments: {'tab': 2});
                    }
                  },
                ),
                if (_cartQuantities.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        _cartQuantities.length.toString(),
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshProducts,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppConstants.searchHint,
                      hintStyle: GoogleFonts.cairo(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: AppConstants.awesomeColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              if (_isInitialLoading)
                const SliverFillRemaining(
                  child: Center(child: ShimmerLoading()),
                )
              else
                _filteredProducts.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.noProductsMessage,
                          style: GoogleFonts.cairo(fontSize: 20, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                )
                    : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.5,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        if (index == _filteredProducts.length && _isLoadingMore) {
                          return const ShimmerLoading(isGridItem: true);
                        }
                        final product = _filteredProducts[index];
                        final quantity = _cartQuantities[product['id'].toString()] ?? 0;
                        return GestureDetector(
                          onTap: () => _showProductBottomSheet(product),
                          child: ProductCard(
                            product: product,
                            quantity: quantity,
                            onAddToCart: (q) => _addToCart(product, quantity: q - quantity),
                          ),
                        );
                      },
                      childCount: _filteredProducts.length + (_isLoadingMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _productsSubscription?.cancel();
    super.dispose();
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final ValueChanged<int> onAddToCart;

  const ProductCard({
    required this.product,
    required this.quantity,
    required this.onAddToCart,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasOffer = product['offer_price'] != null && product['offer_price'] != product['price'];
    final originalPrice = product['price'];
    final displayPrice = product['offer_price'] ?? originalPrice;
    final maxQuantity = product['max_quantity'] ?? product['stock_quantity'] ?? 10;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.2), offset: const Offset(4, 4), blurRadius: 8),
          BoxShadow(color: Colors.white.withOpacity(0.8), offset: const Offset(-4, -4), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: product['thumbnail'] ?? product['image'] ?? '',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                if (hasOffer)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'عرض',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  product['name'],
                  style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Column(
                  children: [
                    if (hasOffer)
                      Text(
                        '$originalPrice ج.م',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '$displayPrice ج.م',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.awesomeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                QuantityControlss(
                  quantity: quantity,
                  onQuantityChanged: onAddToCart,
                  maxQuantity: maxQuantity,
                  awesomeColor: AppConstants.awesomeColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
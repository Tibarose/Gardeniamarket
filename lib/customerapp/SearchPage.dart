import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/productlst/quantity_controls.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class SearchPage extends StatefulWidget {
  final VoidCallback? onNavigateToCart;

  const SearchPage({super.key, this.onNavigateToCart});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentlyViewed = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  OverlayEntry? _overlayEntry;
  bool _isLoading = false;
  bool _hasSearched = false;
  Map<String, int> cartQuantities = {};
  Map<String, bool> favorites = {};
  String? mobileNumber;
  Timer? _cartSyncDebounce;
  Timer? _searchDebounce;
  List<Map<String, dynamic>> pendingCartUpdates = [];
  bool _isLoggedIn = false; // New flag to track login status

  static const Color awesomeColor = Color(0xFF6A1B9A);
  static const Color categoryColor = Color(0xFF28A745);
  static const Color gradientStart = Color(0xFF6A1B9A);
  static const Color gradientEnd = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _fetchMobileNumber();
    _initializeCartAndFavorites();
    _loadSearchHistory();
    _loadRecentlyViewed();
  }

  Future<void> _fetchMobileNumber() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.currentUserId != null) {
      try {
        final response = await supabase
            .from('users')
            .select('mobile_number')
            .eq('id', authProvider.currentUserId!)
            .single();
        setState(() {
          mobileNumber = response['mobile_number'] as String;
          _isLoggedIn = true; // User is logged in if mobile number is fetched
        });
        _setupRealtimeSubscriptions();
      } catch (e) {
        setState(() {
          _isLoggedIn = false; // User is not logged in if fetching fails
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في جلب رقم الهاتف',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      setState(() {
        _isLoggedIn = false; // User is not logged in if not authenticated
      });
    }
  }

  Future<void> _initializeCartAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCart = prefs.getString('cart_quantities');
    if (cachedCart != null) {
      setState(() {
        cartQuantities = Map<String, int>.from(jsonDecode(cachedCart));
      });
    }
    await fetchFavorites();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = (prefs.getStringList('search_history') ?? []).toList();
    if (!history.contains(query)) {
      history.insert(0, query);
      if (history.length > 5) history = history.sublist(0, 5);
      await prefs.setStringList('search_history', history);
      setState(() => _searchHistory = history);
    }
  }

  Future<void> _loadRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final recentlyViewedIds = prefs.getStringList('recently_viewed') ?? [];
    print('DEBUG: Loading recently viewed IDs: $recentlyViewedIds');
    if (recentlyViewedIds.isNotEmpty) {
      try {
        final response = await supabase
            .from('products')
            .select('id, name, price, offer_price, image, stock_quantity, max_quantity, description, category_id')
            .inFilter('id', recentlyViewedIds)
            .eq('status', 'active');

        print('DEBUG: Recently viewed response: $response');
        setState(() {
          _recentlyViewed = List<Map<String, dynamic>>.from(response).map((item) {
            final map = Map<String, dynamic>.from(item);
            map['category'] = map['category_id'] != null ? 'فئة ${map['category_id']}' : 'غير محدد';
            print('DEBUG: Processed recently viewed item: ${map['name']}');
            return map;
          }).toList();
          _recentlyViewed.sort((a, b) =>
              recentlyViewedIds.indexOf(a['id'].toString()).compareTo(recentlyViewedIds.indexOf(b['id'].toString())));
        });
      } catch (e) {
        print('DEBUG: Error loading recently viewed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تحميل المنتجات المعروضة مؤخرًا',
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
  }

  Future<void> _saveRecentlyViewed(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentlyViewed = (prefs.getStringList('recently_viewed') ?? []).toList();
    if (!recentlyViewed.contains(productId)) {
      recentlyViewed.insert(0, productId);
      if (recentlyViewed.length > 10) recentlyViewed = recentlyViewed.sublist(0, 10);
      await prefs.setStringList('recently_viewed', recentlyViewed);
      await _loadRecentlyViewed();
    }
  }

  void _setupRealtimeSubscriptions() {
    if (mobileNumber == null) return;
    supabase
        .from('carts')
        .stream(primaryKey: ['id'])
        .eq('mobile_number', mobileNumber!)
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty && pendingCartUpdates.isEmpty) {
        final products = jsonDecode(data.first['products'] as String);
        setState(() {
          cartQuantities = {
            for (var item in products as List) item['id'].toString(): item['quantity'] as int
          };
        });
      }
    });
  }

  Future<void> fetchFavorites() async {
    if (mobileNumber == null) return;
    try {
      final response = await supabase.from('favorites').select('product_id').eq('mobile_number', mobileNumber!);
      setState(() {
        favorites = {for (var item in response) item['product_id'].toString(): true};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في جلب المفضلة',
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

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تسجيل مطلوب',
          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'يرجى التسجيل لتتمكن من إضافة المنتجات إلى السلة أو المفضلة.',
          style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'تسجيل الآن',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addToCart(Map<String, dynamic> product, {int quantity = 1}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || mobileNumber == null) {
      _showRegisterDialog();
      return;
    }

    final productId = product['id'].toString();
    final currentQuantity = cartQuantities[productId] ?? 0;
    final maxQuantity = product['max_quantity'] ?? product['stock_quantity'] ?? 10;
    final newQuantity = currentQuantity + quantity;

    if (newQuantity > maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الكمية المطلوبة تتجاوز الحد الأقصى المتاح',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      cartQuantities[productId] = newQuantity;
      if (cartQuantities[productId]! <= 0) cartQuantities.remove(productId);
    });

    pendingCartUpdates.add({'id': productId, 'quantity': newQuantity});
    _debounceCartSync();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_quantities', jsonEncode(cartQuantities));

    await Haptics.vibrate(HapticsType.light);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quantity > 0 ? 'تم إضافة ${product['name']}' : 'تم إزالة ${product['name']}',
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                if (widget.onNavigateToCart != null) {
                  widget.onNavigateToCart!();
                }
              },
              child: Text(
                'عرض السلة',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: quantity > 0 ? awesomeColor : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _debounceCartSync() {
    _cartSyncDebounce?.cancel();
    _cartSyncDebounce = Timer(Duration(seconds: 2), syncCartToSupabase);
  }

  Future<void> syncCartToSupabase() async {
    if (pendingCartUpdates.isEmpty || mobileNumber == null) return;
    try {
      final cartData = cartQuantities.entries.map((e) => {'id': e.key, 'quantity': e.value}).toList();

      final existingCart = await supabase.from('carts').select('id').eq('mobile_number', mobileNumber!).maybeSingle();

      if (existingCart != null) {
        await supabase.from('carts').update({'products': jsonEncode(cartData)}).eq('id', existingCart['id']);
      } else {
        await supabase.from('carts').insert({
          'mobile_number': mobileNumber!,
          'products': jsonEncode(cartData),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      pendingCartUpdates.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في مزامنة السلة',
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

  Future<List<String>> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      print('DEBUG: Empty suggestion query');
      return [];
    }

    // Normalize and sanitize
    final normalizedQuery = query.trim().replaceAll('ى', 'ي').replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
    final sanitizedQuery = normalizedQuery
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\d+'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' & ');
    print('DEBUG: Fetching suggestions for query: $query, normalized: $normalizedQuery, sanitized: $sanitizedQuery');

    try {
      List<dynamic> response;
      if (sanitizedQuery.isNotEmpty) {
        response = await supabase
            .from('products')
            .select('name')
            .textSearch('name', sanitizedQuery, config: 'arabic')
            .eq('status', 'active')
            .limit(5);
        print('DEBUG: Suggestions text search response: $response');
      } else {
        print('DEBUG: Sanitized suggestion query empty, using ilike');
        response = await supabase
            .from('products')
            .select('name')
            .ilike('name', '%$normalizedQuery%')
            .eq('status', 'active')
            .limit(5);
        print('DEBUG: Suggestions ilike response: $response');
      }

      return response.map((item) => item['name'] as String).toList();
    } catch (e) {
      print('DEBUG: Suggestions error: $e');
      // Fallback to ilike
      try {
        final fallbackResponse = await supabase
            .from('products')
            .select('name')
            .ilike('name', '%$normalizedQuery%')
            .eq('status', 'active')
            .limit(5);
        print('DEBUG: Suggestions fallback response: $fallbackResponse');
        return fallbackResponse.map((item) => item['name'] as String).toList();
      } catch (fallbackError) {
        print('DEBUG: Suggestions fallback error: $fallbackError');
        return [];
      }
    }
  }

  void _showSuggestions(List<String> suggestions) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 120,
        left: 16,
        right: 16,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    suggestions[index],
                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
                    textDirection: TextDirection.rtl,
                  ),
                  onTap: () {
                    _searchController.text = suggestions[index];
                    _searchProducts(suggestions[index]);
                    _hideSuggestions();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      print('DEBUG: Empty query, clearing results');
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    // Normalize Arabic text and sanitize
    final normalizedQuery = query.trim().replaceAll('ى', 'ي').replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
    final sanitizedQuery = normalizedQuery
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation (e.g., -, .)
        .replaceAll(RegExp(r'\d+'), '') // Remove numbers
        .trim()
        .replaceAll(RegExp(r'\s+'), ' & '); // Replace spaces with AND operator
    print('DEBUG: Starting search for query: $query, normalized: $normalizedQuery, sanitized: $sanitizedQuery');

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    const maxRetries = 2;
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        // Try full-text search
        dynamic response;
        if (sanitizedQuery.isNotEmpty) {
          response = await supabase
              .from('products')
              .select('id, name, price, offer_price, image, stock_quantity, max_quantity, description, category_id')
              .textSearch('name', sanitizedQuery, config: 'arabic')
              .eq('status', 'active')
              .timeout(const Duration(seconds: 10));
          print('DEBUG: Text search response type: ${response.runtimeType}, content: $response');
        } else {
          print('DEBUG: Sanitized query empty, skipping text search');
          throw Exception('Query too complex');
        }

        // Validate response
        if (response is List) {
          setState(() {
            _searchResults = response.map((item) {
              final map = Map<String, dynamic>.from(item);
              map['category'] = map['category_id'] != null ? 'فئة ${map['category_id']}' : 'غير محدد';
              print('DEBUG: Processed item: ${map['name']}, category: ${map['category']}');
              return map;
            }).toList();
            _isLoading = false;
          });

          print('DEBUG: Search successful, results count: ${_searchResults.length}');
          await _saveSearchQuery(query);
          return;
        } else {
          throw Exception('استجابة غير متوقعة من السيرفر');
        }
      } catch (e) {
        print('DEBUG: Search error on attempt ${retryCount + 1}: $e');
        retryCount++;
        if (retryCount > maxRetries) {
          // Fallback to ilike
          print('DEBUG: Falling back to ilike for query: $normalizedQuery');
          try {
            final fallbackResponse = await supabase
                .from('products')
                .select('id, name, price, offer_price, image, stock_quantity, max_quantity, description, category_id')
                .ilike('name', '%$normalizedQuery%')
                .eq('status', 'active')
                .timeout(const Duration(seconds: 10));

            print('DEBUG: Fallback response: $fallbackResponse');
            setState(() {
              _searchResults = fallbackResponse.map((item) {
                final map = Map<String, dynamic>.from(item);
                map['category'] = map['category_id'] != null ? 'فئة ${map['category_id']}' : 'غير محدد';
                print('DEBUG: Processed fallback item: ${map['name']}');
                return map;
              }).toList();
              _isLoading = false;
            });

            print('DEBUG: Fallback search successful, results count: ${_searchResults.length}');
            await _saveSearchQuery(query);
            return;
          } catch (fallbackError) {
            print('DEBUG: Fallback error: $fallbackError');
            setState(() {
              _isLoading = false;
              _searchResults.clear();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFriendlyErrorMessage(fallbackError),
                        style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
                        textDirection: TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _searchProducts(query),
                      child: Text(
                        'إعادة المحاولة',
                        style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 5),
              ),
            );
            print('DEBUG: Max retries reached, search failed');
            return;
          }
        }

        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    print('DEBUG: Error details: $error');
    if (error is TimeoutException) {
      return 'تأخر الاتصال بالسيرفر، تحقق من الإنترنت';
    } else if (error.toString().contains('Network')) {
      return 'فشل الاتصال بالإنترنت';
    } else if (error is FormatException) {
      return 'خطأ في البيانات المستلمة';
    } else if (error.toString().contains('column')) {
      return 'خطأ في قاعدة البيانات، الرجاء التواصل مع الدعم';
    } else {
      return 'حدث خطأ أثناء البحث، حاول مجددًا';
    }
  }

  void showProductBottomSheet(BuildContext context, Map<String, dynamic> product, int initialQuantity) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _saveRecentlyViewed(product['id'].toString());

    int quantity = initialQuantity;
    bool showQuantityControls = initialQuantity > 0;
    final hasOffer = product['offer_price'] != null && product['offer_price'] != product['price'];
    double unitPrice = double.parse(hasOffer ? product['offer_price'].toString() : product['price'].toString());
    double totalPrice = quantity * unitPrice;
    bool isFavorite = favorites[product['id'].toString()] ?? false;
    bool isOutOfStock = (product['stock_quantity'] ?? 0) == 0;
    final maxQuantity = product['max_quantity'] ?? product['stock_quantity'] ?? 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        child: ZoomIn(
                          duration: Duration(milliseconds: 300),
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
                                    child: Center(child: SpinKitFadingCircle(color: awesomeColor)),
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
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      ),
                      SizedBox(height: 16),
                      Text(
                        product['name'],
                        style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 8),
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
                            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: awesomeColor),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product['category'] ?? 'غير محدد',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'الوصف',
                        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text(
                        product['description']?.isNotEmpty == true ? product['description'] : 'لا يوجد وصف متاح',
                        style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[700]),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 16),
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
                                if (!authProvider.isAuthenticated || mobileNumber == null) {
                                  Navigator.pop(context);
                                  _showRegisterDialog();
                                  return;
                                }
                                if (newQuantity > quantity) {
                                  addToCart(product, quantity: 1);
                                  setModalState(() {
                                    quantity = newQuantity;
                                    totalPrice = quantity * unitPrice;
                                  });
                                } else if (newQuantity < quantity) {
                                  if (newQuantity > 0) {
                                    addToCart(product, quantity: -1);
                                    setModalState(() {
                                      quantity = newQuantity;
                                      totalPrice = quantity * unitPrice;
                                    });
                                  } else {
                                    addToCart(product, quantity: -quantity);
                                    setModalState(() {
                                      quantity = newQuantity;
                                      totalPrice = quantity * unitPrice;
                                      showQuantityControls = false;
                                    });
                                  }
                                }
                              },
                              maxQuantity: maxQuantity,
                              awesomeColor: awesomeColor,
                            ),
                            Text(
                              '${totalPrice.toStringAsFixed(2)} ج.م',
                              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: awesomeColor),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!authProvider.isAuthenticated || mobileNumber == null) {
                                Navigator.pop(context);
                                _showRegisterDialog();
                                return;
                              }
                              addToCart(product, quantity: 1);
                              setModalState(() {
                                quantity = 1;
                                totalPrice = quantity * unitPrice;
                                showQuantityControls = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: awesomeColor.withOpacity(0.4),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: Text(
                                  'أضف إلى السلة',
                                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotLoggedInScreen() {
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'يرجى التسجيل',
              style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'تحتاج إلى تسجيل الدخول للوصول إلى صفحة البحث',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to the registration/login page
                Navigator.pushNamed(context, '/login'); // Adjust the route name as per your app
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: awesomeColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'تسجيل الدخول',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'البحث عن منتج',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: awesomeColor,
              ),
            ),
            centerTitle: true,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart, color: awesomeColor, size: 28),
                    onPressed: () {
                      if (!authProvider.isAuthenticated || mobileNumber == null) {
                        _showRegisterDialog();
                        return;
                      }
                      if (widget.onNavigateToCart != null) {
                        widget.onNavigateToCart!();
                      }
                    },
                    tooltip: 'عرض السلة',
                  ),
                  if (cartQuantities.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.red, Colors.redAccent]),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cartQuantities.length.toString(),
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: !_isLoggedIn
                ? _buildNotLoggedInScreen() // Show "Please register" UI if not logged in
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'ابحث عن منتج...',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? ZoomIn(
                                child: IconButton(
                                  icon: Icon(Icons.clear, color: awesomeColor),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults.clear();
                                      _hasSearched = false;
                                    });
                                    _hideSuggestions();
                                  },
                                  tooltip: 'مسح البحث',
                                ),
                              )
                                  : null,
                            ),
                            style: GoogleFonts.cairo(fontSize: 16),
                            textInputAction: TextInputAction.search,
                            onChanged: (value) async {
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(Duration(milliseconds: 300), () async {
                                final suggestions = await _fetchSuggestions(value);
                                print('DEBUG: Suggestions received: $suggestions');
                                setState(() => _suggestions = suggestions);
                                if (suggestions.isNotEmpty && value.trim().isNotEmpty) {
                                  _showSuggestions(suggestions);
                                } else {
                                  _hideSuggestions();
                                }
                              });
                            },
                            onSubmitted: (value) {
                              _searchProducts(value);
                              _hideSuggestions();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElasticIn(
                        child: ElevatedButton(
                          onPressed: () {
                            _searchProducts(_searchController.text);
                            _hideSuggestions();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            elevation: 0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: awesomeColor.withOpacity(0.4),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(10),
                            child: Semantics(
                              label: 'بحث',
                              child: Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_hasSearched && _searchHistory.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'عمليات البحث الأخيرة',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _searchHistory.asMap().entries.map((entry) {
                            final index = entry.key;
                            final query = entry.value;
                            return BounceInDown(
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              child: ActionChip(
                                label: Text(
                                  query,
                                  style: GoogleFonts.cairo(color: Colors.black),
                                ),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                side: BorderSide.none,
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                labelPadding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onPressed: () {
                                  _searchController.text = query;
                                  _searchProducts(query);
                                },
                                avatar: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.history, size: 16, color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  if (!_hasSearched && _recentlyViewed.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'المنتجات التي تم عرضها مؤخرًا',
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recentlyViewed.length,
                            itemBuilder: (context, index) {
                              final product = _recentlyViewed[index];
                              final productId = product['id'].toString();
                              final quantity = cartQuantities[productId] ?? 0;
                              final hasOffer = product['offer_price'] != null && product['offer_price'] != product['price'];
                              return FadeInRight(
                                duration: Duration(milliseconds: 300 + (index * 100)),
                                child: Container(
                                  width: 150,
                                  margin: EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () => showProductBottomSheet(context, product, quantity),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Stack(
                                            children: [
                                              CachedNetworkImage(
                                                imageUrl: product['image'] ?? '',
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.contain,
                                                placeholder: (context, url) => Container(
                                                  color: Colors.grey[200],
                                                  child: Center(child: SpinKitFadingCircle(color: awesomeColor)),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(Icons.error, color: Colors.grey[600], size: 40),
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
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          product['name'],
                                          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (hasOffer)
                                              Text(
                                                '${product['price']} ج.م',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            Text(
                                              '${hasOffer ? product['offer_price'] : product['price']} ج.م',
                                              style: GoogleFonts.cairo(fontSize: 14, color: awesomeColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  Expanded(
                    child: _isLoading
                        ? Center(child: SpinKitFadingCircle(color: awesomeColor))
                        : !_hasSearched
                        ? _recentlyViewed.isEmpty && _searchHistory.isEmpty
                        ? Center(
                      child: Text(
                        'أدخل اسم المنتج واضغط على البحث',
                        style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
                      ),
                    )
                        : const SizedBox()
                        : _searchResults.isEmpty
                        ? Center(
                      child: Text(
                        'لا توجد نتائج مطابقة',
                        style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
                      ),
                    )
                        : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.5,
                      ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        final productId = product['id'].toString();
                        final quantity = cartQuantities[productId] ?? 0;
                        final hasOffer = product['offer_price'] != null && product['offer_price'] != product['price'];
                        final maxQuantity = product['max_quantity'] ?? product['stock_quantity'] ?? 10;

                        return FadeInUp(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          child: GestureDetector(
                            onTap: () => showProductBottomSheet(context, product, quantity),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              transform: Matrix4.identity()..scale(1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                            child: Stack(
                                              children: [
                                                CachedNetworkImage(
                                                  imageUrl: product['image'] ?? '',
                                                  height: double.infinity,
                                                  width: double.infinity,
                                                  fit: BoxFit.contain,
                                                  placeholder: (context, url) => Container(
                                                    color: Colors.grey[200],
                                                    child: Center(child: SpinKitFadingCircle(color: awesomeColor)),
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    color: Colors.grey[200],
                                                    child: Icon(Icons.error, color: Colors.grey[600], size: 40),
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
                                              ],
                                            ),
                                          ),
                                          if (hasOffer)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: [Colors.red, Colors.redAccent]),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'عرض',
                                                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            product['name'],
                                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Column(
                                            children: [
                                              if (hasOffer)
                                                Text(
                                                  '${product['price']} ج.م',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                              Text(
                                                '${hasOffer ? product['offer_price'] : product['price']} ج.م',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: awesomeColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          QuantityControlss(
                                            quantity: quantity,
                                            onQuantityChanged: (newQuantity) {
                                              if (!authProvider.isAuthenticated || mobileNumber == null) {
                                                _showRegisterDialog();
                                                return;
                                              }
                                              if (newQuantity > quantity) {
                                                addToCart(product, quantity: 1);
                                              } else if (newQuantity < quantity) {
                                                if (newQuantity > 0) {
                                                  addToCart(product, quantity: -1);
                                                } else {
                                                  setState(() => cartQuantities.remove(productId));
                                                  addToCart(product, quantity: -quantity);
                                                }
                                              }
                                            },
                                            maxQuantity: maxQuantity,
                                            awesomeColor: awesomeColor,
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

  @override
  void dispose() {
    _searchController.dispose();
    _cartSyncDebounce?.cancel();
    _searchDebounce?.cancel();
    _hideSuggestions();
    syncCartToSupabase();
    super.dispose();
  }
}
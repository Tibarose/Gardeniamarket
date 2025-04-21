import 'dart:convert';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch products with pagination and optional category filter
  Future<List<Map<String, dynamic>>> fetchProducts(int page, {String? categoryName, List<Map<String, dynamic>>? categories}) async {
    try {
      var query = _supabase
          .from(AppConstants.productsTable)
          .select('id, name, price, offer_price, image, thumbnail, category_id, stock_quantity, max_quantity, description, market_categories(name)');

      // Apply filters
      query = query.eq('status', 'active');

      // Filter by category_id if categoryName is provided
      if (categoryName != null && categoryName != 'العروض' && categories != null) {
        final category = categories.firstWhere(
              (cat) => cat['name'] == categoryName,
          orElse: () => {'id': null},
        );
        final categoryId = category['id'];
        if (categoryId != null) {
          query = query.eq('category_id', categoryId);
        }
      }

      // Execute with pagination
      final response = await query.range((page - 1) * AppConstants.pageSize, page * AppConstants.pageSize - 1);

      return (response as List).map((item) {
        return {
          'id': item['id'],
          'name': item['name'],
          'price': item['price'],
          'offer_price': item['offer_price'],
          'image': item['image'],
          'thumbnail': item['thumbnail'],
          'category_id': item['category_id'],
          'category_name': item['market_categories']?['name'] ?? 'غير مصنف',
          'stock_quantity': item['stock_quantity'],
          'max_quantity': item['max_quantity'],
          'description': item['description'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Fetch user mobile number
  Future<String?> fetchMobileNumber(String userId) async {
    try {
      final response = await _supabase
          .from(AppConstants.usersTable)
          .select('mobile_number')
          .eq('id', userId)
          .single();
      return response['mobile_number'] as String?;
    } catch (e) {
      throw Exception('Failed to fetch mobile number: $e');
    }
  }

  // Fetch favorites
  Future<Map<String, bool>> fetchFavorites(String mobileNumber) async {
    try {
      final response = await _supabase
          .from(AppConstants.favoritesTable)
          .select('product_id')
          .eq('mobile_number', mobileNumber);
      return {
        for (var item in response as List) item['product_id'].toString(): true
      };
    } catch (e) {
      throw Exception('Failed to fetch favorites: $e');
    }
  }

  // Sync cart to Supabase
  Future<void> syncCart(String mobileNumber, Map<String, int> cartQuantities) async {
    try {
      final cartData = cartQuantities.entries.map((e) => {'id': e.key, 'quantity': e.value}).toList();
      final existingCart = await _supabase
          .from(AppConstants.cartsTable)
          .select('id')
          .eq('mobile_number', mobileNumber)
          .maybeSingle();

      if (existingCart != null) {
        await _supabase
            .from(AppConstants.cartsTable)
            .update({'products': jsonEncode(cartData)})
            .eq('id', existingCart['id']);
      } else {
        await _supabase.from(AppConstants.cartsTable).insert({
          'mobile_number': mobileNumber,
          'products': jsonEncode(cartData),
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to sync cart: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String mobileNumber, String productId, bool isFavorite) async {
    try {
      if (isFavorite) {
        await _supabase.from(AppConstants.favoritesTable).insert({
          'mobile_number': mobileNumber,
          'product_id': productId,
        });
      } else {
        await _supabase
            .from(AppConstants.favoritesTable)
            .delete()
            .eq('mobile_number', mobileNumber)
            .eq('product_id', productId);
      }
    } catch (e) {
      throw Exception('Failed to update favorite: $e');
    }
  }

  // Real-time cart subscription
  Stream<Map<String, int>> subscribeToCart(String mobileNumber) {
    return _supabase
        .from(AppConstants.cartsTable)
        .stream(primaryKey: ['id'])
        .eq('mobile_number', mobileNumber)
        .map((data) {
      if (data.isEmpty) return {};
      final products = jsonDecode(data.first['products'] as String) as List;
      return {for (var item in products) item['id'].toString(): item['quantity'] as int};
    });
  }

  // Real-time products subscription
  Stream<List<Map<String, dynamic>>> subscribeToProducts() {
    return _supabase
        .from(AppConstants.productsTable)
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((data) => (data as List).map((item) {
      return {
        'id': item['id'],
        'name': item['name'],
        'price': item['price'],
        'offer_price': item['offer_price'],
        'image': item['image'],
        'thumbnail': item['thumbnail'],
        'category_id': item['category_id'],
        'category_name': 'غير مصنف', // Fallback since streams don't support joins
        'stock_quantity': item['stock_quantity'],
        'max_quantity': item['max_quantity'],
        'description': item['description'],
      };
    }).toList());
  }

  // Cache products locally
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_products', jsonEncode(products));
    await prefs.setString('last_updated', DateTime.now().toIso8601String());
  }

  // Load cached products
  Future<List<Map<String, dynamic>>> loadCachedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_products');
    if (cachedData == null) return [];
    return (jsonDecode(cachedData) as List).map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // Check if cache needs refresh
  Future<bool> shouldRefreshCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdated = prefs.getString('last_updated');
    if (lastUpdated == null) return true;

    final serverLastUpdated = await _supabase.from(AppConstants.metadataTable).select('last_updated').single();
    return lastUpdated != serverLastUpdated['last_updated'];
  }
}
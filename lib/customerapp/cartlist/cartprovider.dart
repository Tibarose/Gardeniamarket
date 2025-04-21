import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _totalPriceBeforeOffer = 0.0;
  double _totalPrice = 0.0;
  double _discount = 0.0;
  double _offerDiscount = 0.0;
  int _potentialLoyaltyPoints = 0;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  double get totalPriceBeforeOffer => _totalPriceBeforeOffer;
  double get totalPrice => _totalPrice;
  double get discount => _discount;
  double get offerDiscount => _offerDiscount;
  int get potentialLoyaltyPoints => _potentialLoyaltyPoints;
  bool get hasUnavailableItems =>
      _cartItems.any((item) => item['status'] == 'inactive' || item['status'] == 'deleted');

  Future<void> fetchCartData(String? mobileNumber, SupabaseClient supabase) async {
    if (mobileNumber == null) {
      _clearCartState();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final cachedCart = prefs.getString('cart_$mobileNumber');

    if (cachedCart != null) {
      _cartItems = List<Map<String, dynamic>>.from(jsonDecode(cachedCart));
      _calculateTotals();
    }

    try {
      final cartResponse = await supabase
          .from(AppConstants.supabaseCartsTable)
          .select('id, products')
          .eq('mobile_number', mobileNumber)
          .maybeSingle();

      if (cartResponse == null) {
        _clearCartState();
      } else {
        final List<dynamic> cartProducts = jsonDecode(cartResponse['products'] as String);
        final cartId = cartResponse['id'] as String;
        final productIds = cartProducts.map((item) => item['id'].toString()).toList();

        final productsResponse = await supabase
            .from(AppConstants.supabaseProductsTable)
            .select('id, name, price, offer_price, image, barcode, stock_quantity, max_quantity, status')
            .inFilter('id', productIds);

        final List<Map<String, dynamic>> detailedCartItems = [];
        for (var cartItem in cartProducts) {
          final product = productsResponse.firstWhere(
                (p) => p['id'].toString() == cartItem['id'].toString(),
            orElse: () => {},
          );
          if (product.isNotEmpty) {
            final price = double.tryParse(product['price'].toString()) ?? 0.0;
            final offerPrice = double.tryParse(product['offer_price']?.toString() ?? '') ?? price;
            final effectivePrice = offerPrice < price ? offerPrice : price;
            final quantity = cartItem['quantity'] as int;

            detailedCartItems.add({
              'id': product['id'].toString(),
              'name': product['name'],
              'price': price,
              'offer_price': offerPrice < price ? offerPrice : null,
              'image': product['image'],
              'barcode': product['barcode'],
              'quantity': quantity,
              'stock_quantity': product['stock_quantity'] ?? 10,
              'max_quantity': product['max_quantity'] ?? product['stock_quantity'] ?? 10,
              'status': product['status'] ?? 'active',
              'subtotal': effectivePrice * quantity,
              'cart_id': cartId,
            });
          }
        }

        _cartItems = detailedCartItems;
        _calculateTotals();
        await prefs.setString('cart_$mobileNumber', jsonEncode(detailedCartItems));
      }
    } catch (e) {
      debugPrint('Error fetching cart data: $e');
      if (_cartItems.isEmpty && cachedCart != null) {
        _cartItems = List<Map<String, dynamic>>.from(jsonDecode(cachedCart));
        _calculateTotals();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCartQuantity(String productId, int newQuantity, SupabaseClient supabase, String mobileNumber) async {
    if (newQuantity < 0) return;

    final cartItem = _cartItems.firstWhere((item) => item['id'] == productId);
    final maxQuantity = cartItem['max_quantity'] ?? cartItem['stock_quantity'] ?? 10;

    if (newQuantity > maxQuantity) {
      // Notify user instead of throwing an exception
      debugPrint('Quantity exceeds max limit: $maxQuantity');
      return;
    }

    final updatedCartItems = _cartItems.map((item) {
      if (item['id'] == productId) {
        final effectivePrice = item['offer_price'] ?? item['price'];
        return {...item, 'quantity': newQuantity, 'subtotal': effectivePrice * newQuantity};
      }
      return item;
    }).toList();

    final filteredCartItems = updatedCartItems.where((item) => item['quantity'] > 0).toList();
    final cartData = filteredCartItems.map((item) => {'id': item['id'], 'quantity': item['quantity']}).toList();

    try {
      await supabase
          .from(AppConstants.supabaseCartsTable)
          .update({'products': jsonEncode(cartData)})
          .eq('id', cartItem['cart_id']);
      _cartItems = filteredCartItems;
      _calculateTotals();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart_$mobileNumber', jsonEncode(filteredCartItems));
    } catch (e) {
      debugPrint('Error updating cart: $e');
      await fetchCartData(mobileNumber, supabase);
    }
    notifyListeners();
  }

  Future<void> applyPromoCode(String code, SupabaseClient supabase) async {
    if (code.isEmpty) return;
    try {
      final response = await supabase
          .from(AppConstants.supabasePromoCodesTable)
          .select()
          .eq('code', code)
          .maybeSingle();
      if (response != null) {
        _discount = (response['discount_percentage'] as num) / 100 * _totalPrice;
        _calculateTotals();
      } else {
        _discount = 0.0;
      }
    } catch (e) {
      debugPrint('Error applying promo code: $e');
    }
    notifyListeners();
  }

  Future<void> clearCart(String mobileNumber, SupabaseClient supabase) async {
    try {
      await supabase
          .from(AppConstants.supabaseCartsTable)
          .update({'products': jsonEncode([])})
          .eq('mobile_number', mobileNumber);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_$mobileNumber');
      _clearCartState();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
    notifyListeners();
  }

  void _clearCartState() {
    _cartItems = [];
    _totalPriceBeforeOffer = 0.0;
    _totalPrice = 0.0;
    _discount = 0.0;
    _offerDiscount = 0.0;
    _potentialLoyaltyPoints = 0;
    notifyListeners();
  }

  void _calculateTotals() {
    double tempTotalBeforeOffer = 0.0;
    double tempTotal = 0.0;
    double tempOfferDiscount = 0.0;
    for (var item in _cartItems) {
      final price = item['price'] as double;
      final offerPrice = item['offer_price'] as double? ?? price;
      final quantity = item['quantity'] as int;
      tempTotalBeforeOffer += price * quantity;
      tempTotal += offerPrice * quantity;
      tempOfferDiscount += (price - offerPrice) * quantity;
    }
    _totalPriceBeforeOffer = tempTotalBeforeOffer;
    _totalPrice = tempTotal;
    _offerDiscount = tempOfferDiscount;

    final effectiveTotal = _totalPrice - _discount;
    _potentialLoyaltyPoints = (effectiveTotal ~/ 10).toInt();
  }
}
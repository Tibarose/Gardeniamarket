import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gardeniamarket/customerapp/auth_provider.dart';
import 'package:gardeniamarket/customerapp/cartlist/cartprovider.dart';
import 'package:gardeniamarket/customerapp/deliverybottomsheet.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'package:gardeniamarket/customerapp/successscreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_widgets.dart'; // Import new widgets file

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  double deliveryFee = 0.0;
  double tipAmount = 0.0;
  String? selectedTip;
  String? deliveryAddress;
  String? estimatedDeliveryTime;
  DateTime? scheduledDeliveryTime;
  String? selectedPaymentMethod = 'cash';
  final TextEditingController promoController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  bool _hasShownSwipeHint = false;
  bool _isInitializing = true;
  bool _isLoggedIn = false; // New flag to track login status

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final mobileNumber = await _getUserMobileNumber(authProvider);

    if (mobileNumber == null) {
      setState(() {
        _isLoggedIn = false; // User is not logged in
        _isInitializing = false;
      });
      return; // Don't show snackbar here; we'll show the "Please register" UI
    }

    setState(() {
      _isLoggedIn = true; // User is logged in
    });

    try {
      await cartProvider.fetchCartData(mobileNumber, authProvider.supabase);
      await _fetchDeliveryDetails(authProvider);
    } catch (e) {
      _showSnackBar('خطأ في تحميل السلة: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<String?> _getUserMobileNumber(AuthProvider authProvider) async {
    final userId = authProvider.currentUserId;
    if (userId == null) return null;
    try {
      final response = await authProvider.supabase
          .from(AppConstants.supabaseUsersTable)
          .select('mobile_number')
          .eq('id', userId)
          .single();
      return response['mobile_number'] as String?;
    } catch (e) {
      debugPrint('Error fetching mobile number: $e');
      return null;
    }
  }

  Future<void> _fetchDeliveryDetails(AuthProvider authProvider, {bool showBottomSheet = false}) async {
    final mobileNumber = await _getUserMobileNumber(authProvider);
    if (mobileNumber == null) {
      _showSnackBar('لم يتم تسجيل الدخول', Colors.red);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (!showBottomSheet) {
      final cachedAddress = prefs.getString('delivery_address_$mobileNumber');
      final cachedDeliveryFee = prefs.getDouble('delivery_fee_$mobileNumber');

      if (cachedAddress != null && cachedDeliveryFee != null) {
        setState(() {
          deliveryAddress = cachedAddress;
          deliveryFee = cachedDeliveryFee;
          estimatedDeliveryTime = _calculateEstimatedDeliveryTime(deliveryFee);
        });
        return;
      }

      try {
        final userResponse = await authProvider.supabase
            .from(AppConstants.supabaseUsersTable)
            .select('building_number, apartment_number, compound_id')
            .eq('mobile_number', mobileNumber)
            .maybeSingle();

        if (userResponse == null) return;

        final compoundId = userResponse['compound_id']?.toString();
        String? compoundName;
        if (compoundId != null) {
          final compoundResponse = await authProvider.supabase
              .from(AppConstants.supabaseCompoundsTable)
              .select('name, delivery_fee')
              .eq('id', compoundId)
              .maybeSingle();
          if (compoundResponse != null) {
            compoundName = compoundResponse['name'] as String?;
            deliveryFee = (compoundResponse['delivery_fee'] as num?)?.toDouble() ?? 0.0;
          }
        }

        setState(() {
          deliveryAddress = compoundName != null
              ? ' $compoundName, عمارة: ${userResponse['building_number']}, شقة: ${userResponse['apartment_number']}'
              : 'يرجى تحديث عنوان التوصيل';
          estimatedDeliveryTime = _calculateEstimatedDeliveryTime(deliveryFee);
        });

        await prefs.setString('delivery_address_$mobileNumber', deliveryAddress!);
        await prefs.setDouble('delivery_fee_$mobileNumber', deliveryFee);
      } catch (e) {
        _showSnackBar('خطأ في جلب تفاصيل التوصيل: $e', Colors.red);
      }
    } else {
      final initialDetails = {
        'building': prefs.getString('delivery_address_$mobileNumber')?.split(', عمارة: ')[1]?.split(', شقة: ')[0] ?? '',
        'apartment': prefs.getString('delivery_address_$mobileNumber')?.split(', شقة: ')[1] ?? '',
        'compound_id': null,
      };

      try {
        final userResponse = await authProvider.supabase
            .from(AppConstants.supabaseUsersTable)
            .select('compound_id')
            .eq('mobile_number', mobileNumber)
            .maybeSingle();
        if (userResponse != null) {
          initialDetails['compound_id'] = userResponse['compound_id'] as String?;
        }
      } catch (e) {
        _showSnackBar('خطأ في جلب معرف الكمبوند: $e', Colors.red);
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DeliveryBottomSheet(
            initialDetails: initialDetails,
            onSave: (updatedDetails) async {
              try {
                await authProvider.supabase.from(AppConstants.supabaseUsersTable).update({
                  'compound_id': updatedDetails['compound_id'],
                  'building_number': updatedDetails['building'],
                  'apartment_number': updatedDetails['apartment'],
                }).eq('mobile_number', mobileNumber);

                setState(() {
                  deliveryAddress =
                  ' ${updatedDetails['compound_name']}, عمارة: ${updatedDetails['building']}, شقة: ${updatedDetails['apartment']}';
                  estimatedDeliveryTime = _calculateEstimatedDeliveryTime(deliveryFee);
                });

                await prefs.setString('delivery_address_$mobileNumber', deliveryAddress!);
                _showSnackBar('تم تحديث تفاصيل التوصيل بنجاح', AppConstants.awesomeColor);
              } catch (e) {
                _showSnackBar('خطأ في تحديث تفاصيل التوصيل: $e', Colors.red);
              }
            },
          ),
        );
      }
    }
  }

  String _calculateEstimatedDeliveryTime(double fee) {
    if (fee > 20) return '20-30 دقيقة';
    if (fee > 10) return '30-45 دقيقة';
    return '45-60 دقيقة';
  }

  Future<void> _scheduleDelivery() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          scheduledDeliveryTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final mobileNumber = await _getUserMobileNumber(authProvider);

    if (mobileNumber == null || cartProvider.cartItems.isEmpty) {
      _showSnackBar('السلة فارغة أو لم يتم تسجيل الدخول', Colors.red);
      return;
    }

    if (deliveryAddress == null || deliveryAddress!.isEmpty) {
      _showSnackBar('يرجى تحديد عنوان التوصيل', Colors.red);
      return;
    }

    if (cartProvider.hasUnavailableItems) {
      _showSnackBar('يرجى إزالة المنتجات غير المتاحة قبل التنفيذ', Colors.red);
      return;
    }

    if (!await _confirmAction('هل تريد إتمام الطلب؟')) return;

    try {
      final orderProducts = cartProvider.cartItems.map<Map<String, dynamic>>((item) {
        return {
          'id': item['id'],
          'name': item['name'],
          'price': item['price'],
          'offer_price': item['offer_price'],
          'barcode': item['barcode'],
          'quantity': item['quantity'],
          'subtotal': item['subtotal'],
          'image': item['image'],
        };
      }).toList();

      final checkoutSubtotal = cartProvider.totalPrice;
      final checkoutDiscount = cartProvider.discount;
      final checkoutFinalTotal = checkoutSubtotal - checkoutDiscount + deliveryFee + tipAmount;
      final loyaltyPoints = (checkoutFinalTotal ~/ 10).toInt();

      final initialStatusHistory = [
        {
          'status': 'submitted',
          'timestamp': DateTime.now().toUtc().toIso8601String()
        }
      ];

      final response = await authProvider.supabase.from(AppConstants.supabaseOrdersTable).insert({
        'mobile_number': mobileNumber,
        'products': jsonEncode(orderProducts),
        'total_price': checkoutFinalTotal,
        'delivery_fee': deliveryFee,
        'delivery_address': deliveryAddress,
        'delivery_instructions': instructionsController.text.isNotEmpty ? instructionsController.text : null,
        'tip_amount': tipAmount,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().add(const Duration(hours: 2)).toIso8601String(),
        'scheduled_at': scheduledDeliveryTime?.toIso8601String(),
        'payment_method': selectedPaymentMethod,
        'status_history': jsonEncode(initialStatusHistory),
      }).select('id').single();

      await authProvider.supabase.from('loyalty_points').insert({
        'mobile_number': mobileNumber,
        'points': loyaltyPoints,
        'order_id': response['id'],
        'created_at': DateTime.now().toIso8601String(),
      });

      await cartProvider.clearCart(mobileNumber, authProvider.supabase);

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderConfirmationPage(
              orderItems: orderProducts,
              subtotal: checkoutSubtotal,
              deliveryFee: deliveryFee,
              tipAmount: tipAmount,
              discount: checkoutDiscount,
              finalTotal: checkoutFinalTotal,
              awesomeColor: AppConstants.awesomeColor,
              loyaltyPoints: loyaltyPoints,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('خطأ في إتمام الطلب: $e', Colors.red);
    }
  }

  Future<bool> _confirmAction(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تأكيد',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: GoogleFonts.cairo(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.awesomeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'تأكيد',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ) ??
        false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: AppConstants.snackBarDuration,
      ),
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
              'تحتاج إلى تسجيل الدخول لعرض السلة',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to the registration/login page
                Navigator.pushNamed(context, '/login'); // Adjust the route name as per your app
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.awesomeColor,
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
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              automaticallyImplyLeading: false,

              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'سلة التسوق',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.awesomeColor,
                ),
              ),
              centerTitle: true,
              actions: [
                if (_isLoggedIn && cartProvider.cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppConstants.awesomeColor),
                    onPressed: () async {
                      if (await _confirmAction('هل تريد مسح السلة؟')) {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final mobileNumber = await _getUserMobileNumber(authProvider);
                        if (mobileNumber != null) {
                          await cartProvider.clearCart(mobileNumber, authProvider.supabase);
                          _showSnackBar('تم مسح السلة بنجاح', AppConstants.awesomeColor);
                        }
                      }
                    },
                    tooltip: 'مسح السلة',
                  ),
              ],
            ),
            body: _isInitializing
                ? const Center(child: CircularProgressIndicator(color: AppConstants.awesomeColor))
                : !_isLoggedIn
                ? _buildNotLoggedInScreen() // Show "Please register" UI if not logged in
                : cartProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.awesomeColor))
                : cartProvider.cartItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartContent(cartProvider),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('سلتك فارغة',
                style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text('أضف منتجات الآن لتبدأ التسوق',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/market', arguments: {'tab': 0}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.awesomeColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('تسوق الآن',
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(CartProvider cartProvider) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE7F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.money,
                    color: AppConstants.awesomeColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'اكسب ${cartProvider.potentialLoyaltyPoints} نقطة مع هذا الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.awesomeColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildCartItemsSection(cartProvider),
                        const SizedBox(height: 16),
                        _buildDeliverySection(),
                        const SizedBox(height: 16),
                        _buildInstructionsSection(),
                        const SizedBox(height: 16),
                        _buildTipSection(),
                        const SizedBox(height: 16),
                        _buildPromoSection(cartProvider),
                        const SizedBox(height: 16),
                        PaymentSection(
                          selectedPaymentMethod: selectedPaymentMethod,
                          onPaymentChanged: (value) => setState(() => selectedPaymentMethod = value),
                        ),
                        const SizedBox(height: 16),
                        _buildPriceSummary(cartProvider),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildCheckoutFooter(cartProvider),
        ),
      ],
    );
  }

  Widget _buildCartItemsSection(CartProvider cartProvider) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المنتجات (${cartProvider.cartItems.length})',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartProvider.cartItems.length,
              itemBuilder: (context, index) {
                final item = cartProvider.cartItems[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Slidable(
                    key: Key(item['id']),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            if (!_hasShownSwipeHint) {
                              _showSnackBar('اسحب لليسار لحذف المنتج', AppConstants.awesomeColor);
                              setState(() => _hasShownSwipeHint = true);
                            }
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            _getUserMobileNumber(authProvider).then((mobileNumber) {
                              if (mobileNumber != null) {
                                cartProvider.updateCartQuantity(
                                    item['id'], 0, authProvider.supabase, mobileNumber);
                              }
                            });
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'حذف',
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                    child: _buildCartItem(item, cartProvider),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, CartProvider cartProvider) {
    final isAvailable = item['status'] != 'inactive' && item['status'] != 'deleted';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item['image'],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(width: 70, height: 70, color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item['name'],
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isAvailable)
                      Text(
                        'غير متاح',
                        style: GoogleFonts.cairo(fontSize: 14, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item['offer_price'] != null) ...[
                      Text(
                        '${item['price']} ج.م',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: Colors.grey[500], decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '${item['offer_price'] ?? item['price']} ج.م',
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: AppConstants.awesomeColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                QuantityControls(
                  quantity: item['quantity'],
                  onQuantityChanged: isAvailable
                      ? (newQty) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    _getUserMobileNumber(authProvider).then((mobileNumber) {
                      if (mobileNumber != null) {
                        cartProvider.updateCartQuantity(
                            item['id'], newQty, authProvider.supabase, mobileNumber);
                      }
                    });
                  }
                      : null,
                  maxQuantity: item['max_quantity'] ?? item['stock_quantity'] ?? 10,
                  awesomeColor: AppConstants.awesomeColor,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item['subtotal'].toStringAsFixed(2)} ج.م',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return DeliverySection(
      deliveryAddress: deliveryAddress,
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعليمات التوصيل',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            const SizedBox(height: 8),
            TextField(
              controller: instructionsController,
              decoration: InputDecoration(
                hintText: 'أدخل تعليمات (اختياري)',
                hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.note, color: AppConstants.awesomeColor),
              ),
              style: GoogleFonts.cairo(fontSize: 16),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipSection() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إكرامية المندوب',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TipOptionButton(
                  value: '5',
                  label: '5 ج.م',
                  isSelected: selectedTip == '5',
                  onTap: () => setState(() {
                    selectedTip = selectedTip == '5' ? null : '5';
                    tipAmount =
                    selectedTip == 'custom' ? 0.0 : (selectedTip != null ? double.parse(selectedTip!) : 0.0);
                  }),
                  awesomeColor: AppConstants.awesomeColor,
                ),
                TipOptionButton(
                  value: '10',
                  label: '10 ج.م',
                  isSelected: selectedTip == '10',
                  onTap: () => setState(() {
                    selectedTip = selectedTip == '10' ? null : '10';
                    tipAmount =
                    selectedTip == 'custom' ? 0.0 : (selectedTip != null ? double.parse(selectedTip!) : 0.0);
                  }),
                  awesomeColor: AppConstants.awesomeColor,
                ),
                TipOptionButton(
                  value: '20',
                  label: '20 ج.م',
                  isSelected: selectedTip == '20',
                  onTap: () => setState(() {
                    selectedTip = selectedTip == '20' ? null : '20';
                    tipAmount =
                    selectedTip == 'custom' ? 0.0 : (selectedTip != null ? double.parse(selectedTip!) : 0.0);
                  }),
                  awesomeColor: AppConstants.awesomeColor,
                ),
                TipOptionButton(
                  value: 'custom',
                  label: 'مبلغ اخر',
                  isSelected: selectedTip == 'custom',
                  onTap: () => setState(() {
                    selectedTip = selectedTip == 'custom' ? null : 'custom';
                    tipAmount =
                    selectedTip == 'custom' ? 0.0 : (selectedTip != null ? double.parse(selectedTip!) : 0.0);
                  }),
                  awesomeColor: AppConstants.awesomeColor,
                ),
              ],
            ),
            if (selectedTip == 'custom') ...[
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'أدخل المبلغ',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.money, color: AppConstants.awesomeColor),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.cairo(fontSize: 16),
                onChanged: (value) => setState(() => tipAmount = double.tryParse(value) ?? 0.0),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPromoSection(CartProvider cartProvider) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('كود الخصم',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoController,
                    decoration: InputDecoration(
                      hintText: 'أدخل الكود',
                      hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.local_offer, color: AppConstants.awesomeColor),
                    ),
                    style: GoogleFonts.cairo(fontSize: 16),
                    onSubmitted: (code) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      cartProvider.applyPromoCode(code, authProvider.supabase).then((_) {
                        if (cartProvider.discount > 0) {
                          _showSnackBar('تم تطبيق الخصم بنجاح!', AppConstants.awesomeColor);
                        } else {
                          _showSnackBar('كود غير صالح', Colors.red);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    cartProvider.applyPromoCode(promoController.text, authProvider.supabase).then((_) {
                      if (cartProvider.discount > 0) {
                        _showSnackBar('تم تطبيق الخصم بنجاح!', AppConstants.awesomeColor);
                      } else {
                        _showSnackBar('كود غير صالح', Colors.red);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.awesomeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('تطبيق',
                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(CartProvider cartProvider) {
    final finalTotal = cartProvider.totalPrice - cartProvider.discount + deliveryFee + tipAmount;
    final loyaltyPoints = (finalTotal ~/ 10).toInt();
    return PriceSummary(
      cartProvider: cartProvider,
      deliveryFee: deliveryFee,
      tipAmount: tipAmount,
      finalTotal: finalTotal,
    );
  }

  Widget _buildCheckoutFooter(CartProvider cartProvider) {
    final finalTotal = cartProvider.totalPrice - cartProvider.discount + deliveryFee + tipAmount;
    return CheckoutFooter(
      finalTotal: finalTotal,
      onCheckout: cartProvider.hasUnavailableItems ? null : _checkout,
      hasUnavailableItems: cartProvider.hasUnavailableItems,
    );
  }

  @override
  void dispose() {
    promoController.dispose();
    instructionsController.dispose();
    super.dispose();
  }
}

class TipOptionButton extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color awesomeColor;

  const TipOptionButton({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.awesomeColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? awesomeColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: awesomeColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class QuantityControls extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int>? onQuantityChanged;
  final Color awesomeColor;

  const QuantityControls({
    required this.quantity,
    required this.onQuantityChanged,
    required this.awesomeColor,
    this.maxQuantity = 10,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: awesomeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(quantity == 1 ? Icons.delete : Icons.remove, size: 20),
            color: quantity == 1 ? Colors.red : awesomeColor,
            onPressed: onQuantityChanged != null && quantity > 0 ? () => onQuantityChanged!(quantity - 1) : null,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            color: awesomeColor,
            onPressed: onQuantityChanged != null && quantity < maxQuantity
                ? () => onQuantityChanged!(quantity + 1)
                : null,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
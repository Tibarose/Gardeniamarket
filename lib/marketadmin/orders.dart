import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';

// Assuming 'main.dart' has a `supabase` client instance
final supabase = Supabase.instance.client;

// Enums
enum OrderStatus {
  pending,
  accepted,
  outForDelivery,
  delivered,
  paid,
  rejected,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'مطلوب';
      case OrderStatus.accepted:
        return 'مقبول';
      case OrderStatus.outForDelivery:
        return 'خرج للتوصيل';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.paid:
        return 'مدفوع';
      case OrderStatus.rejected:
        return 'مرفوض';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.paid:
        return Icons.payment;
      case OrderStatus.rejected:
        return Icons.cancel;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.amber.shade600;
      case OrderStatus.accepted:
        return Colors.blue.shade600;
      case OrderStatus.outForDelivery:
        return Colors.orange.shade600;
      case OrderStatus.delivered:
        return Colors.green.shade600;
      case OrderStatus.paid:
        return Colors.purple.shade600;
      case OrderStatus.rejected:
        return Colors.red.shade600;
    }
  }
}

// Models
class Order {
  final int id;
  final String mobileNumber;
  final List<Product> products;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final double deliveryFee;
  final double tipAmount;
  final String? assignedDeliveryGuy;
  final List<StatusHistory> statusHistory;

  Order({
    required this.id,
    required this.mobileNumber,
    required this.products,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
    this.deliveryInstructions,
    required this.deliveryFee,
    required this.tipAmount,
    this.assignedDeliveryGuy,
    required this.statusHistory,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int? ?? 0,
      mobileNumber: json['mobile_number'] as String? ?? 'غير معروف',
      products: () {
        try {
          final rawProducts = json['products'];
          List<dynamic> productList;

          if (rawProducts is String) {
            final decoded = jsonDecode(rawProducts);
            productList = decoded is List ? decoded : [];
          } else if (rawProducts is List) {
            productList = rawProducts;
          } else {
            productList = [];
          }

          return productList
              .where((p) => p is Map<String, dynamic>)
              .map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error parsing products for order ${json['id']}: $e');
          return <Product>[];
        }
      }(),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == (json['status'] as String? ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      deliveryAddress: json['delivery_address'] as String?,
      deliveryInstructions: json['delivery_instructions'] as String?,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (json['tip_amount'] as num?)?.toDouble() ?? 0.0,
      assignedDeliveryGuy: json['assigned_delivery_guy'] as String?,
      statusHistory: () {
        try {
          final rawHistory = json['status_history'];
          List<dynamic> historyList;

          if (rawHistory is String) {
            final decoded = jsonDecode(rawHistory);
            historyList = decoded is List ? decoded : [];
          } else if (rawHistory is List) {
            historyList = rawHistory;
          } else {
            historyList = [];
          }

          return historyList
              .where((s) => s is Map<String, dynamic>)
              .map((s) => StatusHistory.fromJson(s as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error parsing status_history for order ${json['id']}: $e');
          return <StatusHistory>[];
        }
      }(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mobile_number': mobileNumber,
    'products': jsonEncode(products.map((p) => p.toJson()).toList()),
    'total_price': totalPrice,
    'status': status.toString().split('.').last,
    'created_at': createdAt.toIso8601String(),
    'delivery_address': deliveryAddress,
    'delivery_instructions': deliveryInstructions,
    'delivery_fee': deliveryFee,
    'tip_amount': tipAmount,
    'assigned_delivery_guy': assignedDeliveryGuy,
    'status_history': jsonEncode(statusHistory.map((s) => s.toJson()).toList()),
  };
}

class Product {
  final String id;
  final String name;
  final double price;
  final double? offerPrice;
  final int quantity;
  final String? barcode;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    required this.quantity,
    this.barcode,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id']?.toString() ?? '0',
    name: json['name'] as String? ?? 'غير معروف',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    offerPrice: json['offer_price'] != null ? (json['offer_price'] as num).toDouble() : null,
    quantity: json['quantity'] as int? ?? 1,
    barcode: json['barcode'] as String?,
    imageUrl: json['image'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'offer_price': offerPrice,
    'quantity': quantity,
    'barcode': barcode,
    'image_url': imageUrl,
  };
}

class StatusHistory {
  final OrderStatus status;
  final DateTime timestamp;

  StatusHistory({required this.status, required this.timestamp});

  factory StatusHistory.fromJson(Map<String, dynamic> json) => StatusHistory(
    status: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (json['status'] as String? ?? 'pending'),
      orElse: () => OrderStatus.pending,
    ),
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'status': status.toString().split('.').last,
    'timestamp': timestamp.toIso8601String(),
  };
}

class DeliveryGuy {
  final String id;
  final String name;
  final bool isAvailable;

  DeliveryGuy({required this.id, required this.name, required this.isAvailable});

  factory DeliveryGuy.fromJson(Map<String, dynamic> json) => DeliveryGuy(
    id: json['id'] as String? ?? '0',
    name: json['name'] as String? ?? 'غير معروف',
    isAvailable: json['is_available'] as bool? ?? false,
  );
}

// Config
class AppConfig {
  static const String notificationSoundUrl = 'https://files.catbox.moe/az15yr.wav';
  static const int ordersPerPage = 20;
}

// Main Page
class MarketOrdersPage extends StatefulWidget {
  const MarketOrdersPage({super.key});

  @override
  _MarketOrdersPageState createState() => _MarketOrdersPageState();
}

class _MarketOrdersPageState extends State<MarketOrdersPage> with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  late TabController _tabController;
  List<DeliveryGuy> _deliveryGuys = [];
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  RealtimeChannel? _subscription;
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  int? _highlightedOrderId;
  int? _selectedOrderId;
  bool _isSidebarExpanded = true;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_filterOrders);
    _searchController.addListener(_filterOrders);
    initializeDateFormatting('ar', null).then((_) {
      _fetchOrders(refresh: true);
      _fetchDeliveryGuys();
      _setupRealtimeSubscription();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 500 && _hasMore && !_isLoading) {
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _subscription?.unsubscribe();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMore)) return;
    setState(() => _isLoading = true);
    try {
      if (refresh) {
        _page = 0;
        _hasMore = true;
        _orders.clear();
      }
      final response = await supabase
          .from('orders')
          .select()
          .order('created_at', ascending: true)
          .range(_page * AppConfig.ordersPerPage, (_page + 1) * AppConfig.ordersPerPage - 1);

      final newOrders = (response as List<dynamic>)
          .map((json) {
        if (json is Map<String, dynamic>) {
          return Order.fromJson(json);
        } else {
          debugPrint('Invalid order data: $json');
          return null;
        }
      })
          .where((order) => order != null)
          .cast<Order>()
          .toList();

      setState(() {
        _orders.addAll(newOrders);
        _hasMore = newOrders.length == AppConfig.ordersPerPage;
        _page++;
        _filterOrders();
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ في جلب الطلبات: $e');
    }
  }

  Future<void> _fetchDeliveryGuys() async {
    try {
      final response = await supabase.from('users').select().eq('is_delivery_guy', true);
      setState(() => _deliveryGuys = (response as List<dynamic>).map((json) => DeliveryGuy.fromJson(json)).toList());
    } catch (e) {
      _showError('خطأ في جلب المندوبين: $e');
    }
  }

  void _setupRealtimeSubscription() {
    _subscription = supabase.channel('public:orders').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (payload) {
        setState(() {
          switch (payload.eventType) {
            case PostgresChangeEvent.insert:
              if (payload.newRecord != null) {
                final order = Order.fromJson(payload.newRecord!);
                _orders.insert(0, order);
                _showNewOrderPopup(order.id);
                _playNotificationSound();
                _highlightedOrderId = order.id;
                Future.delayed(const Duration(seconds: 5), () => setState(() => _highlightedOrderId = null));
              }
              break;
            case PostgresChangeEvent.update:
              if (payload.newRecord != null) {
                final order = Order.fromJson(payload.newRecord!);
                final index = _orders.indexWhere((o) => o.id == order.id);
                if (index != -1) _orders[index] = order;
              }
              break;
            case PostgresChangeEvent.delete:
              if (payload.oldRecord != null) {
                _orders.removeWhere((o) => o.id == payload.oldRecord!['id']);
              }
              break;
            case PostgresChangeEvent.all:
              break;
          }
          _filterOrders();
        });
      },
    ).subscribe();
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    final confirm = await _showConfirmDialog('هل تريد تحديث الحالة إلى "${newStatus.displayName}"؟');
    if (!confirm) return;

    try {
      final updatedHistory = [
        ...order.statusHistory,
        StatusHistory(status: newStatus, timestamp: DateTime.now().toUtc()),
      ];
      await supabase.from('orders').update({
        'status': newStatus.toString().split('.').last,
        'status_history': jsonEncode(updatedHistory.map((h) => h.toJson()).toList()),
      }).eq('id', order.id);
      _showSuccess('تم التحديث بنجاح');
    } catch (e) {
      _showError('خطأ في تحديث الحالة: $e');
    }
  }

  Future<void> _assignDeliveryGuy(Order order, String deliveryGuyId) async {
    final confirm = await _showConfirmDialog('هل تريد تعيين هذا المندوب؟');
    if (!confirm) return;

    try {
      final updatedHistory = [
        ...order.statusHistory,
        StatusHistory(status: OrderStatus.outForDelivery, timestamp: DateTime.now().toUtc()),
      ];
      await supabase.from('orders').update({
        'assigned_delivery_guy': deliveryGuyId,
        'status': OrderStatus.outForDelivery.toString().split('.').last,
        'status_history': jsonEncode(updatedHistory.map((h) => h.toJson()).toList()),
      }).eq('id', order.id);
      await supabase.from('users').update({'is_available': false}).eq('id', deliveryGuyId);
      if (order.assignedDeliveryGuy != null) {
        await supabase.from('users').update({'is_available': true}).eq('id', order.assignedDeliveryGuy!);
      }
      _showSuccess('تم التعيين بنجاح');
      _fetchDeliveryGuys();
    } catch (e) {
      _showError('خطأ في تعيين المندوب: $e');
    }
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      final currentTabStatus = _getCurrentTabStatus();
      _filteredOrders = _orders.where((order) {
        final matchesSearch = query.isEmpty ||
            order.id.toString().contains(query) ||
            order.mobileNumber.contains(query);
        final matchesTab = currentTabStatus == null || order.status == currentTabStatus;
        return matchesSearch && matchesTab;
      }).toList();
    });
  }

  OrderStatus? _getCurrentTabStatus() {
    switch (_tabController.index) {
      case 0:
        return OrderStatus.pending;
      case 1:
        return OrderStatus.accepted;
      case 2:
        return OrderStatus.outForDelivery;
      case 3:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  int _getStatusCount(OrderStatus status) => _orders.where((o) => o.status == status).length;

  void _showNewOrderPopup(int orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('طلب جديد!', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.teal[800])),
        content: Text('تم استلام طلب جديد رقم #$orderId', style: GoogleFonts.cairo(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.cairo(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToOrder(orderId);
            },
            child: Text('عرض', style: GoogleFonts.cairo(color: Colors.teal[700])),
          ),
        ],
      ),
    );
  }

  void _navigateToOrder(int orderId) {
    _tabController.animateTo(0);
    _filterOrders();
    setState(() {
      _highlightedOrderId = orderId;
      _selectedOrderId = orderId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _filteredOrders.indexWhere((order) => order.id == orderId);
      if (index != -1 && _scrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 600;
        if (isDesktop) {
          final crossAxisCount = screenWidth > 1600 ? 4 : screenWidth > 1200 ? 3 : 2;
          final rowIndex = index ~/ crossAxisCount;
          final scrollPosition = rowIndex * 300.0;
          _scrollController.animateTo(scrollPosition, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        } else {
          final scrollPosition = index * 280.0;
          _scrollController.animateTo(scrollPosition, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }
    });
    Future.delayed(const Duration(seconds: 5), () => setState(() => _highlightedOrderId = null));
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.setUrl(AppConfig.notificationSoundUrl);
      await _audioPlayer.play();
    } catch (e) {
      _showError('خطأ في الصوت: $e');
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تأكيد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.teal[800])),
        content: Text(message, style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.teal[700])),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        drawer: _selectedOrderId != null && MediaQuery.of(context).size.width < 600
            ? Drawer(
          child: _buildOrderDetailsDrawer(
            _orders.firstWhere((o) => o.id == _selectedOrderId),
          ),
        )
            : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 1200;
            return Stack(
              children: [
                Row(
                  children: [
                    if (!isMobile) _buildSidebar(),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: isMobile ? 180.0 : 120.0,
                            floating: false,
                            pinned: true,
                            flexibleSpace: FlexibleSpaceBar(
                              background: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.teal[700]!, Colors.teal[500]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: isMobile
                                        ? Column(
                                      children: [
                                        Text(
                                          'إدارة الطلبات',
                                          style: GoogleFonts.cairo(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'ابحث برقم الطلب أو الهاتف...',
                                            hintStyle: GoogleFonts.cairo(color: Colors.white70),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.15),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                                            suffixIcon: _searchController.text.isNotEmpty
                                                ? IconButton(
                                              icon: const Icon(Icons.clear, color: Colors.white70),
                                              onPressed: () => _searchController.clear(),
                                            )
                                                : null,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          ),
                                          style: GoogleFonts.cairo(color: Colors.white),
                                        ),
                                        const SizedBox(height: 12),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _buildStatusChip(OrderStatus.pending),
                                              const SizedBox(width: 8),
                                              _buildStatusChip(OrderStatus.accepted),
                                              const SizedBox(width: 8),
                                              _buildStatusChip(OrderStatus.outForDelivery),
                                              const SizedBox(width: 8),
                                              _buildStatusChip(OrderStatus.delivered),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'إدارة الطلبات',
                                          style: GoogleFonts.cairo(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            _buildStatusChip(OrderStatus.pending),
                                            const SizedBox(width: 12),
                                            _buildStatusChip(OrderStatus.accepted),
                                            const SizedBox(width: 12),
                                            _buildStatusChip(OrderStatus.outForDelivery),
                                            const SizedBox(width: 12),
                                            _buildStatusChip(OrderStatus.delivered),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            bottom: isMobile
                                ? PreferredSize(
                              preferredSize: const Size.fromHeight(60.0),
                              child: TabBar(
                                controller: _tabController,
                                labelStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 14),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white70,
                                indicatorColor: Colors.white,
                                indicatorWeight: 3,
                                tabs: [
                                  Tab(text: 'مطلوب (${_getStatusCount(OrderStatus.pending)})'),
                                  Tab(text: 'مقبول (${_getStatusCount(OrderStatus.accepted)})'),
                                  Tab(text: 'خرج (${_getStatusCount(OrderStatus.outForDelivery)})'),
                                  Tab(text: 'تم (${_getStatusCount(OrderStatus.delivered)})'),
                                ],
                              ),
                            )
                                : null,
                          ),
                          SliverFillRemaining(
                            child: _isLoading && _orders.isEmpty
                                ? _buildShimmerLoading(isMobile: isMobile, isTablet: isTablet)
                                : isMobile
                                ? TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMobileContent(OrderStatus.pending),
                                _buildMobileContent(OrderStatus.accepted),
                                _buildMobileContent(OrderStatus.outForDelivery),
                                _buildMobileContent(OrderStatus.delivered),
                              ],
                            )
                                : _buildDesktopContent(constraints),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isMobile && _selectedOrderId != null) _buildDetailsPanel(constraints),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 250 : 80,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSidebarExpanded)
                  Text(
                    'لوحة التحكم',
                    style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                  ),
                IconButton(
                  icon: Icon(
                    _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.teal[800],
                  ),
                  onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                ),
              ],
            ),
          ),
          if (_isSidebarExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الطلب أو الهاتف...',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.teal),
                    onPressed: () => _searchController.clear(),
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.cairo(),
              ),
            ),
          ],
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(0, OrderStatus.pending),
                _buildSidebarItem(1, OrderStatus.accepted),
                _buildSidebarItem(2, OrderStatus.outForDelivery),
                _buildSidebarItem(3, OrderStatus.delivered),

              ],
            ),
          ),
          if (_isSidebarExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isRefreshing = true);
                      _fetchOrders(refresh: true);
                    },
                    icon: _isRefreshing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : const Icon(Icons.refresh),
                    label: Text('تحديث', style: GoogleFonts.cairo()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _playNotificationSound,
                    icon: const Icon(Icons.volume_up),
                    label: Text('اختبار الصوت', style: GoogleFonts.cairo()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, OrderStatus status) {
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      hoverColor: Colors.teal.withOpacity(0.1),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _tabController.index == index ? Colors.teal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(status.icon, color: _tabController.index == index ? Colors.teal : Colors.teal[800]),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${status.displayName} (${_getStatusCount(status)})',
                  style: GoogleFonts.cairo(
                    color: _tabController.index == index ? Colors.teal : Colors.teal[800],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    return Chip(
      label: Text(
        '${status.displayName}: ${_getStatusCount(status)}',
        style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: status.color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildShimmerLoading({required bool isMobile, required bool isTablet}) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : MediaQuery.of(context).size.width > 1600 ? 4 : 3);
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: isMobile ? 2.5 : 1.2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 100, height: 20, color: Colors.white),
                    Container(width: 50, height: 20, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Container(width: 150, height: 16, color: Colors.white),
                const SizedBox(height: 12),
                Container(width: 200, height: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopContent(BoxConstraints constraints) {
    final statusFilter = [OrderStatus.pending, OrderStatus.accepted, OrderStatus.outForDelivery, OrderStatus.delivered][_tabController.index];
    final filteredOrders = _filteredOrders.where((order) => order.status == statusFilter).toList();
    final crossAxisCount = constraints.maxWidth > 1600 ? 4 : constraints.maxWidth > 1200 ? 3 : 2;

    return Container(
      color: Colors.grey.shade50,
      child: filteredOrders.isEmpty
          ? Center(
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'لا توجد طلبات ${statusFilter.displayName}',
                style: GoogleFonts.cairo(fontSize: 24, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      )
          : GridView.builder(
        controller: statusFilter == OrderStatus.pending ? _scrollController : null,
        padding: const EdgeInsets.all(24.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2,
        ),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: _buildOrderCard(order, isMobile: false),
          );
        },
      ),
    );
  }

  Widget _buildMobileContent(OrderStatus statusFilter) {
    final filteredOrders = _filteredOrders.where((order) => order.status == statusFilter).toList();
    return Container(
      color: Colors.grey.shade50,
      child: filteredOrders.isEmpty
          ? Center(
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'لا توجد طلبات ${statusFilter.displayName}',
                style: GoogleFonts.cairo(fontSize: 20, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: () => _fetchOrders(refresh: true),
        color: Colors.teal,
        child: ListView.builder(
          controller: statusFilter == OrderStatus.pending ? _scrollController : null,
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: _buildOrderCard(order, isMobile: true),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, {required bool isMobile}) {
    final isHovered = ValueNotifier<bool>(false);
    return ValueListenableBuilder<bool>(
      valueListenable: isHovered,
      builder: (context, hovered, child) {
        return MouseRegion(
          onEnter: (_) => isHovered.value = true,
          onExit: (_) => isHovered.value = false,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedOrderId = order.id);
              if (isMobile) {
                Scaffold.of(context).openDrawer();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(hovered ? 0.5 : 0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: _highlightedOrderId == order.id
                    ? Border.all(color: Colors.white, width: 2)
                    : Border.all(color: Colors.transparent),
              ),
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(order.status.icon, size: 18, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  Text(
                                    order.status.displayName,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: Colors.teal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'طلب #${order.id}',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(
                        '${order.totalPrice} ج.م',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'الهاتف: ${order.mobileNumber}',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.teal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'التاريخ: ${_formatDate(order.createdAt)}',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.teal),
                        ),
                      ],
                    ),
                    if (order.status == OrderStatus.accepted || order.status == OrderStatus.outForDelivery) ...[
                      const SizedBox(height: 12),
                      if (order.assignedDeliveryGuy != null)
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Text(
                              'المندوب الحالى: ${_deliveryGuys.firstWhere((guy) => guy.id == order.assignedDeliveryGuy, orElse: () => DeliveryGuy(id: '', name: 'غير معروف', isAvailable: false)).name}',
                              style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      if (_deliveryGuys.isNotEmpty)
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: order.assignedDeliveryGuy == null ? 'اختر مندوب' : 'تغيير مندوب',
                            labelStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          value: order.assignedDeliveryGuy,
                          items: _deliveryGuys
                              .map((guy) => DropdownMenuItem<String>(
                            value: guy.id,
                            child: Text(guy.name, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
                          ))
                              .toList(),
                          onChanged: (value) => value != null ? _assignDeliveryGuy(order, value) : null,
                          dropdownColor: Colors.white,
                        )
                      else
                        Text(
                          'لا يوجد مندوبين',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.redAccent),
                        ),
                    ],
                    const SizedBox(height: 12),
                    _buildActionButtons(order),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsPanel(BoxConstraints constraints) {
    final order = _orders.firstWhere((o) => o.id == _selectedOrderId);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      right: 0,
      top: 0,
      bottom: 0,
      width: constraints.maxWidth > 1200 ? constraints.maxWidth * 0.35 : constraints.maxWidth * 0.4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: _buildOrderDetailsDrawer(order),
      ),
    );
  }

  Widget _buildOrderDetailsDrawer(Order order) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تفاصيل الطلب #${order.id}',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedOrderId = null),
                icon: const Icon(Icons.close, color: Colors.grey),
                tooltip: 'إغلاق',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('العنوان', order.deliveryAddress ?? 'غير متوفر', Icons.location_on),
                  if (order.deliveryInstructions != null) _buildInfoRow('التعليمات', order.deliveryInstructions!, Icons.note),
                  _buildInfoRow('رسوم التوصيل', '${order.deliveryFee} ج.م', Icons.delivery_dining),
                  _buildInfoRow('اكراميه مندوب التوصيل', '${order.tipAmount} ج.م', Icons.monetization_on),
                  const SizedBox(height: 20),
                  Text(
                    'المنتجات:',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProductsTable(order.products),
                  const SizedBox(height: 20),
                  _buildPriceSummary(order),
                  const SizedBox(height: 20),
                  Text(
                    'تاريخ الحالة:',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusTimeline(order.statusHistory),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal[700]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.teal[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTable(List<Product> products) {
    if (products.isEmpty) {
      return Text(
        'لا توجد منتجات',
        style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = MediaQuery.of(context).size.width > 600;
        final availableWidth = constraints.maxWidth;
        final imageWidth = isDesktop ? 60.0 : 50.0;
        final quantityWidth = isDesktop ? 80.0 : 60.0;
        final priceWidth = isDesktop ? 160.0 : availableWidth * 0.35;
        final nameWidth = availableWidth - imageWidth - quantityWidth - priceWidth;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey),
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey),
              verticalInside: BorderSide(color: Colors.grey),
            ),
            columnWidths: {
              0: FixedColumnWidth(imageWidth),
              1: FixedColumnWidth(nameWidth),
              2: FixedColumnWidth(quantityWidth),
              3: FixedColumnWidth(priceWidth),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                children: [
                  _buildTableCell('صورة', isHeader: true, align: TextAlign.center),
                  _buildTableCell('الصنف', isHeader: true, align: TextAlign.right),
                  _buildTableCell('الكمية', isHeader: true, align: TextAlign.center),
                  _buildTableCell('السعر', isHeader: true, align: TextAlign.center),
                ],
              ),
              ...products.map((product) {
                final price = product.offerPrice ?? product.price;
                final totalPrice = product.quantity * price;
                return TableRow(
                  children: [
                    _buildTableCell(
                      '',
                      align: TextAlign.center,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: product.imageUrl != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            width: isDesktop ? 40 : 30,
                            height: isDesktop ? 40 : 30,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey,
                              highlightColor: Colors.grey,
                              child: Container(
                                width: isDesktop ? 40 : 30,
                                height: isDesktop ? 40 : 30,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: isDesktop ? 40 : 30,
                              height: isDesktop ? 40 : 30,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        )
                            : Container(
                          width: isDesktop ? 40 : 30,
                          height: isDesktop ? 40 : 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                    _buildTableCell(
                      product.name,
                      align: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildTableCell(
                      product.quantity.toString(),
                      align: TextAlign.center,
                    ),
                    _buildTableCell(
                      '$totalPrice ج.م',
                      align: TextAlign.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$totalPrice ج.م',
                            style: GoogleFonts.cairo(fontSize: 14, color: Colors.teal[700]),
                          ),
                          if (product.barcode != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.qr_code, size: 16, color: Colors.teal),
                              onPressed: () => _showBarcodeDialog(product.barcode!, product.name),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'عرض الباركود',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Widget? child, TextAlign align = TextAlign.left, TextOverflow? overflow}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: child ??
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
              color: isHeader ? Colors.teal[800] : Colors.grey[800],
            ),
            textAlign: align,
            overflow: overflow,
            maxLines: 3,
          ),
    );
  }

  void _showBarcodeDialog(String barcode, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'باركود: $productName',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 16),
            BarcodeWidget(
              barcode: Barcode.code128(),
              data: barcode,
              width: 200,
              height: 80,
              drawText: true,
              style: GoogleFonts.cairo(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.cairo(color: Colors.teal[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Order order) {
    final subtotal = order.products.fold<double>(0, (sum, p) => sum + (p.quantity * (p.offerPrice ?? p.price)));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السعر:',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('المجموع الفرعي', '$subtotal ج.م', Icons.account_balance_wallet),
          _buildInfoRow('رسوم التوصيل', '${order.deliveryFee} ج.م', Icons.delivery_dining),
          _buildInfoRow('اكراميه المندوب', '${order.tipAmount} ج.م', Icons.monetization_on),
          const Divider(height: 16, color: Colors.grey),
          _buildInfoRow('الإجمالي', '${order.totalPrice} ج.م', Icons.attach_money),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(List<StatusHistory> statusHistory) {
    if (statusHistory.isEmpty) {
      return Text(
        'لا يوجد تاريخ',
        style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statusHistory.length,
      itemBuilder: (context, index) {
        final statusEntry = statusHistory[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: statusEntry.status.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: statusEntry.status.color),
                    ),
                    child: Center(
                      child: Icon(statusEntry.status.icon, size: 16, color: statusEntry.status.color),
                    ),
                  ),
                  if (index < statusHistory.length - 1)
                    Container(width: 2, height: 40, color: Colors.grey[300]),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusEntry.status.displayName,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusEntry.status.color,
                      ),
                    ),
                    Text(
                      _formatDate(statusEntry.timestamp),
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Order order) {
    final actions = <Map<String, dynamic>>[];
    if (order.status == OrderStatus.pending) {
      actions.addAll([
        {'label': 'قبول', 'color': Colors.teal[600], 'action': () => _updateOrderStatus(order, OrderStatus.accepted)},
        {'label': 'رفض', 'color': Colors.redAccent, 'action': () => _updateOrderStatus(order, OrderStatus.rejected)},
      ]);
    }
    if (order.status == OrderStatus.delivered && order.status != OrderStatus.paid) {
      actions.add({
        'label': 'تم الدفع',
        'color': Colors.purple[600],
        'action': () => _updateOrderStatus(order, OrderStatus.paid),
      });
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        return ElevatedButton(
          onPressed: action['action'],
          style: ElevatedButton.styleFrom(
            backgroundColor: action['color'],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            elevation: 4,
            shadowColor: action['color']!.withOpacity(0.3),
          ),
          child: Text(
            action['label'],
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) => intl.DateFormat('yyyy-MM-dd hh:mm a', 'ar').format(date.toLocal());
}
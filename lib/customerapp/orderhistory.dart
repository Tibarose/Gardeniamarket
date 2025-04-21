import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/auth_provider.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' as intl;

class OrderHistoryPage extends StatefulWidget {
  final VoidCallback? onNavigateToMarket;
  const OrderHistoryPage({super.key, this.onNavigateToMarket});

  static const Color awesomeColor = Color(0xFF6A1B9A);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  bool hasError = false;
  String? mobileNumber;
  DateTime? lastCacheTime;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  Timer? _debounce;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isLoggedIn = false; // New flag to track login status

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _cacheMobileNumber();
    if (mobileNumber == null) {
      setState(() {
        _isLoggedIn = false;
        isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoggedIn = true;
    });

    _setupRealtimeSubscriptions();
    await _loadOrders(forceRefresh: true);
  }

  Future<void> _cacheMobileNumber() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUserId;
    if (userId == null) return;

    try {
      final response = await authProvider.supabase
          .from('users')
          .select('mobile_number')
          .eq('id', userId)
          .single();
      mobileNumber = response['mobile_number'] as String?;
    } catch (e) {
      print('Error fetching mobile number: $e');
    }
  }

  Future<void> _loadOrders({bool forceRefresh = false}) async {
    if (mobileNumber == null) {
      setState(() {
        orders = [];
        isLoading = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedOrders = prefs.getString('order_history_$mobileNumber');
    final cachedTime = prefs.getInt('order_history_time_$mobileNumber');
    lastCacheTime = cachedTime != null
        ? DateTime.fromMillisecondsSinceEpoch(cachedTime)
        : null;

    if (cachedOrders != null) {
      setState(() {
        orders = List<Map<String, dynamic>>.from(jsonDecode(cachedOrders));
        isLoading = false;
      });
    }

    if (forceRefresh ||
        cachedOrders == null ||
        (lastCacheTime != null &&
            DateTime.now().difference(lastCacheTime!).inMinutes >= 5)) {
      await _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabase;
      final response = await supabase
          .from('orders')
          .select('id, total_price, status, created_at')
          .eq('mobile_number', mobileNumber!)
          .order('created_at', ascending: false)
          .limit(5);

      final fetchedOrders = (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        orders = fetchedOrders;
        isLoading = false;
        _retryCount = 0;
      });

      _updateCache(fetchedOrders);
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تحميل السجل: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );

      if (_retryCount < _maxRetries && mounted) {
        _retryCount++;
        print('Retrying fetch attempt $_retryCount of $_maxRetries...');
        await Future.delayed(const Duration(seconds: 5));
        await _fetchOrders();
      }
    }
  }

  void _setupRealtimeSubscriptions() {
    if (mobileNumber == null) return;

    final supabase = Provider.of<AuthProvider>(context, listen: false).supabase;
    _subscription = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('mobile_number', mobileNumber!)
        .order('created_at', ascending: false)
        .limit(5)
        .listen((List<Map<String, dynamic>> updatedOrders) {
      setState(() {
        orders = updatedOrders;
        isLoading = false;
      });
      _debounce?.cancel();
      _debounce =
          Timer(const Duration(milliseconds: 500), () => _updateCache(updatedOrders));
    });
  }

  Future<void> _updateCache(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('order_history_$mobileNumber', jsonEncode(data)),
      prefs.setInt('order_history_time_$mobileNumber',
          DateTime.now().millisecondsSinceEpoch),
    ]);
    lastCacheTime = DateTime.now();
  }

  Future<void> _refreshOrders() async {
    if (mobileNumber != null) {
      _retryCount = 0;
      await _fetchOrders();
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final order = orders.firstWhere((o) => o['id'] == orderId);
    if (order['status'] != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن إلغاء الطلب بعد تغيير حالته',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (await _confirmAction('هل تريد إلغاء الطلب؟')) {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabase;
      try {
        await supabase.from('orders').delete().eq('id', orderId);
        setState(() {
          orders.removeWhere((order) => order['id'] == orderId);
        });
        _updateCache(orders);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إلغاء الطلب',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: OrderHistoryPage.awesomeColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في الإلغاء: $e',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _confirmAction(String message) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تأكيد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'لا',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'نعم',
              style: GoogleFonts.cairo(color: OrderHistoryPage.awesomeColor),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _buildOrderProgressIndicator(String status) {
    const List<String> steps = ['pending', 'accepted', 'outForDelivery', 'delivered'];
    const List<String> stepLabels = [
      'تم الطلب',
      'جارى تحضير طلبك',
      'فى الطريق اليك',
      'تم التوصيل'
    ];
    int currentStepIndex = steps.indexOf(status);
    int nextStepIndex = currentStepIndex + 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connecting line
              bool isLineCompleted = (index ~/ 2) < currentStepIndex;
              bool isLineInProgress = (index ~/ 2) == currentStepIndex;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isLineCompleted
                        ? Colors.green
                        : isLineInProgress
                        ? Colors.orange
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            } else {
              // Step circle
              int stepIndex = index ~/ 2;
              bool isCompleted = stepIndex <= currentStepIndex;
              bool isInProgress = stepIndex == nextStepIndex && stepIndex < steps.length;
              bool isCurrent = stepIndex == currentStepIndex;

              Color circleColor = isCompleted
                  ? Colors.green
                  : isInProgress
                  ? Colors.orange
                  : Colors.grey[200]!;
              Color iconColor = isCompleted || isInProgress ? Colors.white : Colors.grey[400]!;

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  border: isCurrent && !isInProgress
                      ? Border.all(color: Colors.green, width: 2)
                      : isInProgress
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                  boxShadow: [
                    if (isCurrent || isInProgress)
                      BoxShadow(
                        color: (isInProgress ? Colors.orange : Colors.green).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check : isInProgress ? Icons.hourglass_top : Icons.circle,
                    size: isCompleted ? 20 : isInProgress ? 18 : 10,
                    color: iconColor,
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            bool isCompleted = index <= currentStepIndex;
            bool isInProgress = index == nextStepIndex && index < steps.length;
            return SizedBox(
              width: 80,
              child: Text(
                stepLabels[index],
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: isCompleted || isInProgress ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? Colors.green
                      : isInProgress
                      ? Colors.orange
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
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
              'تحتاج إلى تسجيل الدخول لعرض سجل الطلبات',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to the registration/login page
                Navigator.pushNamed(context, '/login'); // Adjust the route name as per your app
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OrderHistoryPage.awesomeColor,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'سجل الطلبات',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppConstants.awesomeColor,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF5F5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: OrderHistoryPage.awesomeColor,
          ),
        )
            : !_isLoggedIn
            ? _buildNotLoggedInScreen() // Show "Please register" UI if not logged in
            : hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ أثناء تحميل الطلبات${_retryCount < _maxRetries ? ' (جاري المحاولة...)' : ''}',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OrderHistoryPage.awesomeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        )
            : orders.isEmpty
            ? Center(
          child: FadeInUp(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 120,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد طلبات بعد!',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ابدأ التسوق الآن لتجربة تسوق رائعة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (widget.onNavigateToMarket != null) {
                      widget.onNavigateToMarket!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OrderHistoryPage.awesomeColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'ابدأ التسوق الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _refreshOrders,
          color: OrderHistoryPage.awesomeColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final createdAt = DateTime.parse(order['created_at']);
              final formattedTime =
              intl.DateFormat('hh:mm a').format(createdAt);
              final formattedDate =
              intl.DateFormat('yyyy-MM-dd').format(createdAt);

              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'طلب #${order['id']}',
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: order['status'] == 'delivered'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Text(
                                order['status'] == 'pending'
                                    ? 'قيد الانتظار'
                                    : order['status'] == 'accepted'
                                    ? 'تم القبول'
                                    : order['status'] ==
                                    'outForDelivery'
                                    ? 'في الطريق'
                                    : 'مكتمل',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: order['status'] ==
                                      'completed'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildOrderProgressIndicator(order['status']),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'التاريخ: $formattedDate',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'الوقت: $formattedTime',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'المجموع:\n ${order['total_price']} ج.م',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                OrderHistoryPage.awesomeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailsPage(
                                    orderId: order['id'],
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                OrderHistoryPage.awesomeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                'تفاصيل الطلب',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (order['status'] == 'pending')
                              TextButton(
                                onPressed: () =>
                                    _cancelOrder(order['id']),
                                child: Text(
                                  'إلغاء',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.redAccent,
                                  ),
                                ),
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
      ),
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  final int orderId;

  const OrderDetailsPage({required this.orderId, super.key});

  Widget _buildOrderProgressIndicator(String status) {
    const List<String> steps = ['pending', 'accepted', 'outForDelivery', 'delivered'];
    const List<String> stepLabels = [
      'تم الطلب',
      'جارى تحضير طلبك',
      'فى الطريق اليك',
      'تم التوصيل'
    ];
    int currentStepIndex = steps.indexOf(status);
    int nextStepIndex = currentStepIndex + 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connecting line
              bool isLineCompleted = (index ~/ 2) < currentStepIndex;
              bool isLineInProgress = (index ~/ 2) == currentStepIndex;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isLineCompleted
                        ? Colors.green
                        : isLineInProgress
                        ? Colors.orange
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            } else {
              // Step circle
              int stepIndex = index ~/ 2;
              bool isCompleted = stepIndex <= currentStepIndex;
              bool isInProgress = stepIndex == nextStepIndex && stepIndex < steps.length;
              bool isCurrent = stepIndex == currentStepIndex;

              Color circleColor = isCompleted
                  ? Colors.green
                  : isInProgress
                  ? Colors.orange
                  : Colors.grey[200]!;
              Color iconColor = isCompleted || isInProgress ? Colors.white : Colors.grey[400]!;

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor,
                  border: isCurrent && !isInProgress
                      ? Border.all(color: Colors.green, width: 2)
                      : isInProgress
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
                  boxShadow: [
                    if (isCurrent || isInProgress)
                      BoxShadow(
                        color: (isInProgress ? Colors.orange : Colors.green).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check : isInProgress ? Icons.hourglass_top : Icons.circle,
                    size: isCompleted ? 20 : isInProgress ? 18 : 10,
                    color: iconColor,
                  ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            bool isCompleted = index <= currentStepIndex;
            bool isInProgress = index == nextStepIndex && index < steps.length;
            return SizedBox(
              width: 80,
              child: Text(
                stepLabels[index],
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: isCompleted || isInProgress ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? Colors.green
                      : isInProgress
                      ? Colors.orange
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تفاصيل الطلب #$orderId',
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFF5F5F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: FutureBuilder(
          future: Provider.of<AuthProvider>(context, listen: false)
              .supabase
              .from('orders')
              .select(
              'id, total_price, status, created_at, delivery_address, tip_amount, delivery_fee, products, delivery_instructions')
              .eq('id', orderId)
              .single(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: OrderHistoryPage.awesomeColor,
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'خطأ: ${snapshot.error}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OrderHistoryPage.awesomeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'رجوع',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final order = snapshot.data as Map<String, dynamic>;
            final products =
            List<Map<String, dynamic>>.from(jsonDecode(order['products'] as String));
            final createdAt = DateTime.parse(order['created_at']);
            final formattedTime = intl.DateFormat('hh:mm a').format(createdAt);
            final formattedDate = intl.DateFormat('yyyy-MM-dd').format(createdAt);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة الطلب',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildOrderProgressIndicator(order['status']),
                      const SizedBox(height: 20),
                      Text(
                        'التاريخ: $formattedDate',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'الوقت: $formattedTime',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'العنوان: ${order['delivery_address']}',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      if (order['delivery_instructions'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'تعليمات التوصيل: ${order['delivery_instructions']}',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'المنتجات',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...products.map(
                            (product) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'الكمية: ${product['quantity']}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (product['offer_price'] != null &&
                                      product['offer_price'] !=
                                          product['price']) ...[
                                    Text(
                                      '${product['price']} ج.م',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      '${product['offer_price']} ج.م',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: OrderHistoryPage.awesomeColor,
                                      ),
                                    ),
                                  ] else
                                    Text(
                                      '${product['price']} ج.م',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: OrderHistoryPage.awesomeColor,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المجموع الفرعي',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${(double.parse(order['total_price'].toString()) - order['delivery_fee'] - (order['tip_amount'] ?? 0)).toStringAsFixed(2)} ج.م',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'رسوم التوصيل',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${order['delivery_fee']} ج.م',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (order['tip_amount'] != null &&
                          order['tip_amount'] > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'إكرامية المندوب',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${order['tip_amount']} ج.م',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المجموع الكلي',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${order['total_price']} ج.م',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: OrderHistoryPage.awesomeColor,
                            ),
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
    );
  }
}
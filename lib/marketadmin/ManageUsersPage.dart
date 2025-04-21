import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class ManageUsersPages extends StatefulWidget {
  const ManageUsersPages({super.key});

  @override
  State<ManageUsersPages> createState() => _ManageUsersPagesState();
}

class _ManageUsersPagesState extends State<ManageUsersPages> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _compounds = [];
  bool _isLoading = true;
  bool _isActionLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch users
      final usersResponse = await supabase.from('users').select();
      setState(() {
        _users = usersResponse as List<Map<String, dynamic>>;
        _filteredUsers = List.from(_users); // Initialize filtered list
      });

      // Fetch compounds for display
      final compoundsResponse = await supabase.from('compounds').select('id, name');
      _compounds = compoundsResponse as List<Map<String, dynamic>>;
    } catch (e) {
      _showSnackBar('خطأ في جلب البيانات: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user['mobile_number'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _toggleBlockStatus(String userId, bool currentBlockStatus) async {
    setState(() => _isActionLoading = true);
    try {
      await supabase.from('users').update({'block': !currentBlockStatus}).eq('id', userId);
      _showSnackBar(currentBlockStatus ? 'تم إلغاء حظر المستخدم' : 'تم حظر المستخدم', Colors.teal);
      await _fetchData(); // Refresh the list
    } catch (e) {
      _showSnackBar('خطأ في تحديث حالة المستخدم: $e', Colors.red);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isActionLoading = true);
    try {
      await supabase.from('users').delete().eq('id', userId);
      _showSnackBar('تم حذف المستخدم بنجاح', Colors.teal);
      await _fetchData(); // Refresh the list
    } catch (e) {
      _showSnackBar('خطأ في حذف المستخدم: $e', Colors.red);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    bool isDeliveryGuy = user['is_delivery_guy'] ?? false;
    bool isBlocked = user['block'] ?? false;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تعديل حالة المستخدم',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isDeliveryGuy,
                          onChanged: (value) {
                            setDialogState(() {
                              isDeliveryGuy = value ?? false;
                            });
                          },
                          activeColor: Colors.teal[600],
                        ),
                        Text('مندوب توصيل', style: GoogleFonts.cairo()),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: !isBlocked, // Inverse because "متاح" means not blocked
                          onChanged: (value) {
                            setDialogState(() {
                              isBlocked = !(value ?? false);
                            });
                          },
                          activeColor: Colors.teal[600],
                        ),
                        Text('متاح', style: GoogleFonts.cairo()),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase.from('users').update({
                    'is_delivery_guy': isDeliveryGuy,
                    'block': isBlocked,
                  }).eq('id', user['id']);
                  _showSnackBar('تم تحديث حالة المستخدم بنجاح', Colors.teal);
                  Navigator.pop(context);
                  await _fetchData(); // Refresh the list
                } catch (e) {
                  _showSnackBar('خطأ في تحديث المستخدم: $e', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: Colors.teal.withOpacity(0.3),
              ),
              child: Text(
                'حفظ التعديلات',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة المستخدمين',
            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[700]!, Colors.teal[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchData,
              tooltip: 'تحديث',
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
          child: Row(
            children: [
              // Sidebar (Hidden on mobile)
              if (!isMobile)
                Container(
                  width: 250,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          'لوحة التحكم',
                          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.teal),
                        title: Text('المستخدمين', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
                        onTap: () {},
                        selected: true,
                        selectedTileColor: Colors.teal.withOpacity(0.1),
                      ),
                      ListTile(
                        leading: const Icon(Icons.inventory_2, color: Colors.teal),
                        title: Text('المنتجات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
                        onTap: () => Navigator.pushNamed(context, '/products'),
                        selected: false,
                      ),
                      ListTile(
                        leading: const Icon(Icons.category, color: Colors.teal),
                        title: Text('الفئات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
                        onTap: () => Navigator.pushNamed(context, '/categories'),
                        selected: false,
                      ),
                      ListTile(
                        leading: const Icon(Icons.slideshow, color: Colors.teal),
                        title: Text('الكاروسيل', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
                        onTap: () => Navigator.pushNamed(context, '/carousel'),
                        selected: false,
                      ),
                    ],
                  ),
                ),
              // Main Content
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Top Bar with Search
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'ابحث برقم الموبايل...',
                              hintStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                              prefixIcon: const Icon(Icons.search, color: Colors.teal),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            style: GoogleFonts.cairo(),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        // Main Content
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                              : _filteredUsers.isEmpty
                              ? Center(
                            child: FadeInUp(
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                'لا يوجد مستخدمين',
                                style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
                              ),
                            ),
                          )
                              : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isMobile ? 2.5 : (isTablet ? 2 : 1.8),
                            ),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final compound = _compounds.firstWhere(
                                    (c) => c['id'].toString() == user['compound_id'].toString(),
                                orElse: () => {'name': 'غير محدد'},
                              );
                              final isHovered = ValueNotifier<bool>(false);

                              return ValueListenableBuilder<bool>(
                                valueListenable: isHovered,
                                builder: (context, hovered, child) {
                                  return MouseRegion(
                                    onEnter: (_) => isHovered.value = true,
                                    onExit: (_) => isHovered.value = false,
                                    child: FadeInUp(
                                      duration: const Duration(milliseconds: 600),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.teal[600]!, Colors.teal[400]!],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(hovered ? 0.5 : 0.3),
                                              spreadRadius: 2,
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user['name'],
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'رقم الموبايل: ${user['mobile_number']}',
                                                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                                                    ),
                                                    Text(
                                                      'الكمبوند: ${compound['name']}',
                                                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                                                    ),
                                                    Text(
                                                      'رقم العمارة: ${user['building_number']}',
                                                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                                                    ),
                                                    Text(
                                                      'رقم الشقة: ${user['apartment_number']}',
                                                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                                                    ),
                                                    Text(
                                                      'مندوب توصيل: ${user['is_delivery_guy'] ? 'نعم' : 'لا'}',
                                                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                                                    ),
                                                    Text(
                                                      'محظور: ${user['block'] ? 'نعم' : 'لا'}',
                                                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                                                    ),
                                                    Text(
                                                      'تاريخ الإنشاء: ${user['created_at'].toString().split('.')[0]}',
                                                      style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                                                    onPressed: () => _showEditUserDialog(user),
                                                    tooltip: 'تعديل الحالة',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: Text(
                                                            'تأكيد الحذف',
                                                            style: GoogleFonts.cairo(
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.teal[800],
                                                            ),
                                                          ),
                                                          content: Text(
                                                            'هل أنت متأكد من حذف ${user['name']}؟',
                                                            style: GoogleFonts.cairo(),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              child: Text(
                                                                'إلغاء',
                                                                style: GoogleFonts.cairo(color: Colors.grey[600]),
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () async {
                                                                Navigator.pop(context);
                                                                await _deleteUser(user['id']);
                                                              },
                                                              child: Text(
                                                                'حذف',
                                                                style: GoogleFonts.cairo(color: Colors.red),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    tooltip: 'حذف',
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      user['block'] ? Icons.lock : Icons.lock_open,
                                                      color: user['block'] ? Colors.redAccent : Colors.white,
                                                      size: 24,
                                                    ),
                                                    onPressed: () => _toggleBlockStatus(
                                                      user['id'],
                                                      user['block'],
                                                    ),
                                                    tooltip: user['block'] ? 'إلغاء الحظر' : 'حظر',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_isActionLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        ),
                      ),
                  ],
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
    _searchController.dispose();
    super.dispose();
  }
}
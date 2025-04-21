import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart';
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';

class RestaurantsManagementPage extends StatefulWidget {
  const RestaurantsManagementPage({super.key});

  @override
  _RestaurantsManagementPageState createState() => _RestaurantsManagementPageState();
}

class _RestaurantsManagementPageState extends State<RestaurantsManagementPage> {
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];
  bool _isLoading = true;
  String? _error;
  String _compoundFilter = 'الكل';
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedRestaurantIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
    _searchController.addListener(_filterRestaurants);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('restaurants')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _restaurants = List<Map<String, dynamic>>.from(response);
        _filterRestaurants();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل المطاعم: $e';
        _isLoading = false;
      });
    }
  }

  void _filterRestaurants() {
    final searchQuery = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        bool matchesCompound = _compoundFilter == 'الكل' ||
            (_compoundFilter == 'داخل الكمبوند' && restaurant['is_in_compound'] == true) ||
            (_compoundFilter == 'خارج الكمبوند' && restaurant['is_in_compound'] != true);
        bool matchesSearch = searchQuery.isEmpty ||
            (restaurant['name']?.toLowerCase().contains(searchQuery) ?? false) ||
            (restaurant['location']?.toLowerCase().contains(searchQuery) ?? false);
        return matchesCompound && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deleteRestaurant(String id) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient
          .from('restaurants')
          .delete()
          .eq('id', id);

      await _fetchRestaurants();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم الحذف بنجاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: ThemeManager().currentTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في الحذف: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedRestaurantIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: ThemeManager().currentTheme.cardBackground,
          title: Text(
            'تأكيد الحذف الجماعي',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: ThemeManager().currentTheme.textColor,
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف ${_selectedRestaurantIds.length} مطاعم؟',
            style: GoogleFonts.cairo(
              color: ThemeManager().currentTheme.textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: ThemeManager().currentTheme.secondaryTextColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                for (var id in _selectedRestaurantIds) {
                  await _deleteRestaurant(id);
                }
                setState(() {
                  _selectedRestaurantIds.clear();
                  _isSelectionMode = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'حذف',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final formattedNumber = '+2$phoneNumber';
    final url = 'https://wa.me/$formattedNumber';
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح واتساب: $phoneNumber',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchLocation(String locationUrl) async {
    final Uri uri = Uri.parse(locationUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح الموقع: $locationUrl',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchMenu(String menuUrl) async {
    final Uri uri = Uri.parse(menuUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح القائمة: $menuUrl',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? restaurant}) {
    showDialog(
      context: context,
      builder: (context) => AddEditRestaurantDialog(
        restaurant: restaurant,
        onSave: () async {
          await _fetchRestaurants();
        },
      ),
    );
  }

  void _showRestaurantDetails(Map<String, dynamic> restaurant) {
    final theme = ThemeManager().currentTheme;
    final createdAt = DateTime.parse(restaurant['created_at']).toLocal();
    final formattedDate = intl.DateFormat('d/M/yyyy HH:mm').format(createdAt);

    List<String> phoneNumbers = [];
    if (restaurant['phone_number'] != null && restaurant['phone_number'] != 'Not available') {
      if (restaurant['phone_number'] is String) {
        phoneNumbers = (restaurant['phone_number'] as String).split(',').map((e) => e.trim()).toList();
      } else if (restaurant['phone_number'] is List) {
        phoneNumbers = (restaurant['phone_number'] as List<dynamic>).map((e) => e.toString().trim()).toList();
      }
    }

    List<String> whatsappNumbers = [];
    if (restaurant['whatsapp_number'] != null) {
      if (restaurant['whatsapp_number'] is String) {
        whatsappNumbers = (restaurant['whatsapp_number'] as String).split(',').map((e) => e.trim()).toList();
      } else if (restaurant['whatsapp_number'] is List) {
        whatsappNumbers = (restaurant['whatsapp_number'] as List<dynamic>).map((e) => e.toString().trim()).toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant['name']?.trim() ?? 'بدون اسم',
                                  style: GoogleFonts.cairo(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildIconButton(
                                    icon: FontAwesomeIcons.edit,
                                    color: theme.primaryColor,
                                    tooltip: 'تعديل',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showAddEditDialog(restaurant: restaurant);
                                    },
                                  ),
                                  _buildIconButton(
                                    icon: FontAwesomeIcons.trash,
                                    color: Colors.red,
                                    tooltip: 'حذف',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            backgroundColor: theme.cardBackground,
                                            title: Text(
                                              'تأكيد الحذف',
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.w700,
                                                color: theme.textColor,
                                              ),
                                            ),
                                            content: Text(
                                              'هل أنت متأكد من حذف "${restaurant['name']?.trim() ?? 'هذا المطعم'}"؟',
                                              style: GoogleFonts.cairo(
                                                color: theme.textColor,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(
                                                  'إلغاء',
                                                  style: GoogleFonts.cairo(
                                                    color: theme.secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteRestaurant(restaurant['id']);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Text(
                                                  'حذف',
                                                  style: GoogleFonts.cairo(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.end,
                            children: [
                              if (whatsappNumbers.isNotEmpty)
                                _buildActionButton(
                                  icon: FontAwesomeIcons.whatsapp,
                                  label: 'واتساب',
                                  color: Colors.green,
                                  onPressed: () => _launchWhatsApp(whatsappNumbers.first),
                                ),
                              if (restaurant['location_url']?.isNotEmpty ?? false)
                                _buildActionButton(
                                  icon: Icons.map,
                                  label: 'الموقع',
                                  color: Colors.blue,
                                  onPressed: () => _launchLocation(restaurant['location_url']),
                                ),
                              if (restaurant['menu_link']?.isNotEmpty ?? false)
                                _buildActionButton(
                                  icon: Icons.menu_book,
                                  label: 'القائمة',
                                  color: Colors.orange,
                                  onPressed: () => _launchMenu(restaurant['menu_link']),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          if (restaurant['image_url'] != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  restaurant['image_url'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.category,
                            label: 'الفئة',
                            value: restaurant['category'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.restaurant_menu,
                            label: 'نوع المطبخ',
                            value: restaurant['cuisine_type'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.location_city,
                            label: 'الموقع',
                            value: restaurant['location'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.map,
                            label: 'رابط الموقع',
                            value: restaurant['location_url'] ?? 'غير متوفر',
                            theme: theme,
                            isLink: true,
                            onTap: () => _launchLocation(restaurant['location_url']),
                          ),
                          _buildInfoRow(
                            icon: Icons.phone,
                            label: 'رقم الهاتف',
                            value: phoneNumbers.isEmpty ? 'غير متوفر' : phoneNumbers.join(', '),
                            theme: theme,
                          ),
                          if (whatsappNumbers.isNotEmpty)
                            _buildInfoRow(
                              icon: FontAwesomeIcons.whatsapp,
                              label: 'واتساب',
                              value: whatsappNumbers.join(', '),
                              theme: theme,
                            ),
                          if (restaurant['menu_link'] != null)
                            _buildInfoRow(
                              icon: Icons.menu_book,
                              label: 'رابط القائمة',
                              value: restaurant['menu_link'],
                              theme: theme,
                              isLink: true,
                              onTap: () => _launchMenu(restaurant['menu_link']),
                            ),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'تاريخ الإضافة',
                            value: formattedDate,
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            label: 'داخل الكمبوند',
                            value: restaurant['is_in_compound'] == true ? 'نعم' : 'لا',
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو الموقع',
                        hintStyle: GoogleFonts.cairo(
                          color: theme.secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.secondaryTextColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _filterRestaurants();
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      style: GoogleFonts.cairo(
                        color: theme.textColor,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.red,
                          size: 28,
                        ),
                        onPressed: _bulkDelete,
                        tooltip: 'حذف المحدد',
                      ),
                    ),
                ],
              ),
            ),
            // Compound Filter
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildFilterChip('الكل', theme, isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('داخل الكمبوند', theme, isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('خارج الكمبوند', theme, isMobile),
                ],
              ),
            ),
            // Restaurants List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchRestaurants,
                color: theme.primaryColor,
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                )
                    : _error != null
                    ? Center(
                  child: Text(
                    _error!,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                )
                    : _filteredRestaurants.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 60,
                        color: theme.secondaryTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد مطاعم',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
                    : AnimationLimiter(
                  child: ListView.builder(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    itemCount: _filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = _filteredRestaurants[index];
                      final isSelected = _selectedRestaurantIds.contains(restaurant['id']);
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildRestaurantCard(
                              restaurant,
                              theme,
                              isMobile,
                              isSelected,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _fetchRestaurants,
              backgroundColor: theme.primaryColor,
              heroTag: 'refresh',
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث القائمة',
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () => _showAddEditDialog(),
              backgroundColor: theme.primaryColor,
              heroTag: 'add',
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'إضافة مطعم جديد',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AppTheme theme, bool isMobile) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: isMobile ? 14 : 16,
          color: _compoundFilter == label ? Colors.white : theme.secondaryTextColor,
        ),
      ),
      selected: _compoundFilter == label,
      selectedColor: theme.primaryColor,
      backgroundColor: Colors.grey.shade200,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _compoundFilter = label;
            _filterRestaurants();
          });
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildRestaurantCard(
      Map<String, dynamic> restaurant,
      AppTheme theme,
      bool isMobile,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedRestaurantIds.remove(restaurant['id']);
            } else {
              _selectedRestaurantIds.add(restaurant['id']);
            }
            if (_selectedRestaurantIds.isEmpty) {
              _isSelectionMode = false;
            }
          });
        } else {
          _showRestaurantDetails(restaurant);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedRestaurantIds.add(restaurant['id']);
        });
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.cardBackground,
                theme.cardBackground.withOpacity(0.8),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 12,
            ),
            leading: restaurant['image_url'] != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                restaurant['image_url'],
                width: isMobile ? 50 : 60,
                height: isMobile ? 50 : 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.restaurant,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            )
                : CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.restaurant,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              restaurant['name']?.trim() ?? 'بدون اسم',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              textAlign: TextAlign.right,
            ),
            subtitle: Text(
              restaurant['location'] ?? 'غير متوفر',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14 : 16,
                color: theme.secondaryTextColor,
              ),
              textAlign: TextAlign.right,
            ),
            trailing: _isSelectionMode
                ? Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? theme.primaryColor : theme.secondaryTextColor,
              size: 24,
            )
                : Icon(
              Icons.arrow_left,
              color: theme.secondaryTextColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required AppTheme theme,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.secondaryTextColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: isLink ? onTap : null,
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: theme.secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: isLink ? theme.primaryColor : theme.secondaryTextColor,
                        decoration: isLink ? TextDecoration.underline : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FaIcon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class AddEditRestaurantDialog extends StatefulWidget {
  final Map<String, dynamic>? restaurant;
  final VoidCallback onSave;

  const AddEditRestaurantDialog({super.key, this.restaurant, required this.onSave});

  @override
  _AddEditRestaurantDialogState createState() => _AddEditRestaurantDialogState();
}

class _AddEditRestaurantDialogState extends State<AddEditRestaurantDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _cuisineTypeController;
  late TextEditingController _locationController;
  late TextEditingController _locationUrlController;
  late List<TextEditingController> _phoneNumberControllers;
  late List<TextEditingController> _whatsappNumberControllers;
  late TextEditingController _menuLinkController;
  bool _isInCompound = false;
  bool _isLoading = false;
  bool _isLayoutReady = false;
  bool _isImageUploading = false;

  // Image data
  Uint8List? _imageBytes;
  String _imageUrl = '';
  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant?['name']?.trim() ?? '');
    _categoryController = TextEditingController(text: widget.restaurant?['category']?.trim() ?? '');
    _cuisineTypeController = TextEditingController(text: widget.restaurant?['cuisine_type']?.trim() ?? '');
    _locationController = TextEditingController(text: widget.restaurant?['location']?.trim() ?? '');
    _locationUrlController = TextEditingController(text: widget.restaurant?['location_url']?.trim() ?? '');

    _phoneNumberControllers = [];
    if (widget.restaurant?['phone_number'] != null && widget.restaurant?['phone_number'] != 'Not available') {
      List<String> phoneNumbers = [];
      if (widget.restaurant!['phone_number'] is String) {
        phoneNumbers = (widget.restaurant!['phone_number'] as String).split(',').map((e) => e.trim()).toList();
      } else if (widget.restaurant!['phone_number'] is List) {
        phoneNumbers = (widget.restaurant!['phone_number'] as List<dynamic>).map((e) => e.toString().trim()).toList();
      }
      for (var number in phoneNumbers) {
        _phoneNumberControllers.add(TextEditingController(text: number));
      }
    }
    if (_phoneNumberControllers.isEmpty) {
      _phoneNumberControllers.add(TextEditingController());
    }

    _whatsappNumberControllers = [];
    if (widget.restaurant?['whatsapp_number'] != null) {
      List<String> whatsappNumbers = [];
      if (widget.restaurant!['whatsapp_number'] is String) {
        whatsappNumbers = (widget.restaurant!['whatsapp_number'] as String).split(',').map((e) => e.trim()).toList();
      } else if (widget.restaurant!['whatsapp_number'] is List) {
        whatsappNumbers = (widget.restaurant!['whatsapp_number'] as List<dynamic>).map((e) => e.toString().trim()).toList();
      }
      for (var number in whatsappNumbers) {
        _whatsappNumberControllers.add(TextEditingController(text: number));
      }
    }
    if (_whatsappNumberControllers.isEmpty) {
      _whatsappNumberControllers.add(TextEditingController());
    }

    _menuLinkController = TextEditingController(text: widget.restaurant?['menu_link']?.trim() ?? '');
    _isInCompound = widget.restaurant?['is_in_compound'] ?? false;
    _imageUrl = widget.restaurant?['image_url']?.trim() ?? '';

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLayoutReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _cuisineTypeController.dispose();
    _locationController.dispose();
    _locationUrlController.dispose();
    for (var controller in _phoneNumberControllers) {
      controller.dispose();
    }
    for (var controller in _whatsappNumberControllers) {
      controller.dispose();
    }
    _menuLinkController.dispose();
    super.dispose();
  }

  void _addPhoneNumberField() {
    setState(() {
      _phoneNumberControllers.add(TextEditingController());
    });
  }

  void _removePhoneNumberField(int index) {
    if (_phoneNumberControllers.length > 1) {
      setState(() {
        _phoneNumberControllers[index].dispose();
        _phoneNumberControllers.removeAt(index);
      });
    }
  }

  void _addWhatsappNumberField() {
    setState(() {
      _whatsappNumberControllers.add(TextEditingController());
    });
  }

  void _removeWhatsappNumberField(int index) {
    if (_whatsappNumberControllers.length > 1) {
      setState(() {
        _whatsappNumberControllers[index].dispose();
        _whatsappNumberControllers.removeAt(index);
      });
    }
  }

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        setState(() => _isImageUploading = true);
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
        var request = http.MultipartRequest('POST', uri)
          ..fields['name'] = fileName
          ..files.add(http.MultipartFile.fromBytes('image', fileBytes, filename: fileName));
        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        if (jsonData['success']) {
          setState(() {
            _imageUrl = jsonData['data']['url'];
            _imageBytes = fileBytes;
          });
        }
        setState(() => _isImageUploading = false);
      }
    } catch (e) {
      setState(() => _isImageUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في رفع الصورة: $e',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveRestaurant() async {
    if (!_isLayoutReady || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);

      final phoneNumbers = _phoneNumberControllers
          .map((controller) => controller.text.trim())
          .where((number) => number.isNotEmpty)
          .toList();
      final whatsappNumbers = _whatsappNumberControllers
          .map((controller) => controller.text.trim())
          .where((number) => number.isNotEmpty)
          .toList();

      final data = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'cuisine_type': _cuisineTypeController.text.trim(),
        'location': _locationController.text.trim(),
        'location_url': _locationUrlController.text.trim(),
        'phone_number': phoneNumbers.isEmpty ? 'Not available' : phoneNumbers.join(','),
        'whatsapp_number': whatsappNumbers.isEmpty ? null : whatsappNumbers.join(','),
        'menu_link': _menuLinkController.text.trim().isEmpty ? null : _menuLinkController.text.trim(),
        'image_url': _imageUrl.isEmpty ? null : _imageUrl,
        'is_in_compound': _isInCompound,
      };

      if (widget.restaurant == null) {
        await supabaseConfig.secondaryClient.from('restaurants').insert(data);
      } else {
        await supabaseConfig.secondaryClient
            .from('restaurants')
            .update(data)
            .eq('id', widget.restaurant!['id']);
      }

      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.restaurant == null ? 'تم الإضافة بنجاح' : 'تم التعديل بنجاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: ThemeManager().currentTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في الحفظ: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: theme.cardBackground,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.restaurant == null ? 'إضافة مطعم' : 'تعديل مطعم',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  fontSize: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: screenWidth * 0.9,
            height: screenHeight * 0.7,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'اسم المطعم',
                      icon: Icons.restaurant,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم المطعم';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _categoryController,
                      label: 'الفئة',
                      icon: Icons.category,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الفئة';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cuisineTypeController,
                      label: 'نوع المطبخ',
                      icon: Icons.restaurant_menu,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال نوع المطبخ';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: 'الموقع',
                      icon: Icons.location_city,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الموقع';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationUrlController,
                      label: 'رابط الموقع',
                      icon: Icons.map,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!Uri.parse(value.trim()).isAbsolute) {
                            return 'يرجى إدخال رابط صالح';
                          }
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'أرقام الهاتف',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._phoneNumberControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: controller,
                                label: 'رقم الهاتف ${index + 1}',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null && value.trim().isNotEmpty) {
                                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                                      return 'يرجى إدخال رقم هاتف صالح';
                                    }
                                  }
                                  return null;
                                },
                                theme: theme,
                              ),
                            ),
                            if (_phoneNumberControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removePhoneNumberField(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addPhoneNumberField,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        'إضافة رقم هاتف آخر',
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        foregroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'أرقام واتساب (اختياري)',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._whatsappNumberControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: controller,
                                label: 'رقم واتساب ${index + 1}',
                                icon: FontAwesomeIcons.whatsapp,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null && value.trim().isNotEmpty) {
                                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                                      return 'يرجى إدخال رقم واتساب صالح';
                                    }
                                  }
                                  return null;
                                },
                                theme: theme,
                              ),
                            ),
                            if (_whatsappNumberControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeWhatsappNumberField(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addWhatsappNumberField,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        'إضافة رقم واتساب آخر',
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        foregroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _menuLinkController,
                      label: 'رابط القائمة (اختياري)',
                      icon: Icons.menu_book,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!Uri.parse(value.trim()).isAbsolute) {
                            return 'يرجى إدخال رابط صالح';
                          }
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploadSection(isMobile, theme),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isInCompound,
                          onChanged: _isLayoutReady
                              ? (value) {
                            setState(() {
                              _isInCompound = value ?? false;
                            });
                          }
                              : null,
                          activeColor: theme.primaryColor,
                        ),
                        Text(
                          'داخل الكمبوند',
                          style: GoogleFonts.cairo(
                            color: theme.textColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading || !_isLayoutReady ? null : () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: theme.secondaryTextColor,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading || !_isLayoutReady ? null : _saveRestaurant,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'حفظ',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required AppTheme theme,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: theme.secondaryTextColor) : null,
        labelText: label,
        labelStyle: GoogleFonts.cairo(
          color: theme.secondaryTextColor,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        errorStyle: GoogleFonts.cairo(
          color: Colors.red,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      style: GoogleFonts.cairo(
        color: theme.textColor,
        fontSize: 16,
      ),
      keyboardType: keyboardType,
      validator: validator,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }

  Widget _buildImageUploadSection(bool isMobile, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صورة المطعم (اختياري)',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _isImageUploading ? null : _uploadImage,
          child: Container(
            width: isMobile ? 120 : 150,
            height: isMobile ? 80 : 100,
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  theme.cardBackground,
                  theme.cardBackground.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _imageUrl.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isImageUploading
                    ? CircularProgressIndicator(
                  color: theme.primaryColor,
                  strokeWidth: 2,
                )
                    : FaIcon(
                  FontAwesomeIcons.camera,
                  color: theme.primaryColor,
                  size: isMobile ? 20 : 24,
                ),
                const SizedBox(height: 6),
                Text(
                  'إضافة صورة',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 10 : 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                width: isMobile ? 120 : 150,
                height: isMobile ? 80 : 100,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../main.dart';
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';

class SupermarketsManagementPage extends StatefulWidget {
  const SupermarketsManagementPage({super.key});

  @override
  _SupermarketsManagementPageState createState() => _SupermarketsManagementPageState();
}

class _SupermarketsManagementPageState extends State<SupermarketsManagementPage> {
  List<Map<String, dynamic>> _supermarkets = [];
  List<Map<String, dynamic>> _filteredSupermarkets = [];
  bool _isLoading = true;
  String? _error;
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedSupermarketIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchSupermarkets();
    _searchController.addListener(_filterSupermarkets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSupermarkets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('supermarkets')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _supermarkets = List<Map<String, dynamic>>.from(response);
        _filteredSupermarkets = _supermarkets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل السوبر ماركت: $e';
        _isLoading = false;
      });
    }
  }

  void _filterSupermarkets() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSupermarkets = _supermarkets;
      } else {
        _filteredSupermarkets = _supermarkets.where((supermarket) {
          final name = supermarket['name']?.toLowerCase() ?? '';
          final zone = supermarket['zone']?.toLowerCase() ?? '';
          return name.contains(query) || zone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteSupermarket(String id) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient
          .from('supermarkets')
          .delete()
          .eq('id', id);

      await _fetchSupermarkets();
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
    if (_selectedSupermarketIds.isEmpty) return;

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
            'هل أنت متأكد من حذف ${_selectedSupermarketIds.length} سوبر ماركت؟',
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
                for (var id in _selectedSupermarketIds) {
                  await _deleteSupermarket(id);
                }
                setState(() {
                  _selectedSupermarketIds.clear();
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

  Future<void> _launchPhone(String phoneNumber) async {
    final url = 'tel:+2$phoneNumber';
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن إجراء مكالمة: $phoneNumber',
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

  List<String> _parseField(dynamic field) {
    if (field == null || (field is String && (field.isEmpty || field == '{]}'))) {
      return [];
    }
    try {
      if (field is List) {
        return field.map((item) => item.toString().replaceAll('"', '').trim()).toList();
      } else if (field is String) {
        String cleanedJson = field
            .replaceAll('\\"', '"')
            .replaceAll('{', '[')
            .replaceAll('}', ']')
            .replaceAll('"[', '[')
            .replaceAll(']"', ']');
        return List<String>.from(jsonDecode(cleanedJson));
      } else {
        return ['غير متوفر'];
      }
    } catch (e) {
      return ['غير متوفر'];
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? supermarket}) {
    showDialog(
      context: context,
      builder: (context) => AddEditSupermarketDialog(
        supermarket: supermarket,
        onSave: () async {
          await _fetchSupermarkets();
        },
      ),
    );
  }

  void _showSupermarketDetails(Map<String, dynamic> supermarket) {
    final theme = ThemeManager().currentTheme;
    final createdAt = DateTime.parse(supermarket['created_at']).toLocal();
    final formattedDate = intl.DateFormat('d/M/yyyy HH:mm').format(createdAt);
    final phoneNumbers = _parseField(supermarket['phone']);
    final whatsappNumbers = _parseField(supermarket['whatsapp']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Allow closing by tapping outside
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
                // Header with drag handle and close button
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
                      const SizedBox(width: 40), // Spacer for alignment
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
                                  supermarket['name']?.trim() ?? 'بدون اسم',
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
                                      Navigator.pop(context); // Close bottom sheet
                                      _showAddEditDialog(supermarket: supermarket);
                                    },
                                  ),
                                  _buildIconButton(
                                    icon: FontAwesomeIcons.trash,
                                    color: Colors.red,
                                    tooltip: 'حذف',
                                    onPressed: () {
                                      Navigator.pop(context); // Close bottom sheet
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
                                              'هل أنت متأكد من حذف "${supermarket['name']?.trim() ?? 'هذا السوبر ماركت'}"؟',
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
                                                  _deleteSupermarket(supermarket['id']);
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
                          // Quick Actions
                          if (phoneNumbers.isNotEmpty || whatsappNumbers.isNotEmpty || (supermarket['location']?.isNotEmpty ?? false))
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.end,
                              children: [
                                if (phoneNumbers.isNotEmpty)
                                  _buildActionButton(
                                    icon: Icons.phone,
                                    label: 'اتصال',
                                    color: Colors.green,
                                    onPressed: () => _launchPhone(phoneNumbers.first),
                                  ),
                                if (whatsappNumbers.isNotEmpty)
                                  _buildActionButton(
                                    icon: FontAwesomeIcons.whatsapp,
                                    label: 'واتساب',
                                    color: Colors.green,
                                    onPressed: () => _launchWhatsApp(whatsappNumbers.first),
                                  ),
                                if (supermarket['location']?.isNotEmpty ?? false)
                                  _buildActionButton(
                                    icon: Icons.map,
                                    label: 'الموقع',
                                    color: Colors.blue,
                                    onPressed: () => _launchLocation(supermarket['location']),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.location_city,
                            label: 'المنطقة',
                            value: supermarket['zone'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.map,
                            label: 'الموقع',
                            value: supermarket['location'] ?? 'غير متوفر',
                            theme: theme,
                            isLink: true,
                            onTap: () => _launchLocation(supermarket['location']),
                          ),
                          _buildInfoRow(
                            icon: Icons.phone,
                            label: 'أرقام الهاتف',
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
                          _buildInfoRow(
                            icon: Icons.delivery_dining,
                            label: 'التوصيل',
                            value: supermarket['delivery'] == true ? 'متوفر' : 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            label: 'رسوم التوصيل',
                            value: supermarket['delivery_fee'] ?? 'غير محدد',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'تاريخ الإضافة',
                            value: formattedDate,
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
                        hintText: 'ابحث بالاسم أو المنطقة',
                        hintStyle: GoogleFonts.cairo(
                          color: theme.secondaryTextColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: theme.secondaryTextColor,
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
                        fillColor: Colors.grey.shade100,
                      ),
                      style: GoogleFonts.cairo(
                        color: theme.textColor,
                      ),
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchSupermarkets,
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
                    : _filteredSupermarkets.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 60,
                        color: theme.secondaryTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد سوبر ماركت',
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
                    itemCount: _filteredSupermarkets.length,
                    itemBuilder: (context, index) {
                      final supermarket = _filteredSupermarkets[index];
                      final isSelected = _selectedSupermarketIds.contains(supermarket['id']);
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildSupermarketCard(
                              supermarket,
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
              onPressed: _fetchSupermarkets,
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
              tooltip: 'إضافة سوبر ماركت جديد',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupermarketCard(
      Map<String, dynamic> supermarket,
      AppTheme theme,
      bool isMobile,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedSupermarketIds.remove(supermarket['id']);
            } else {
              _selectedSupermarketIds.add(supermarket['id']);
            }
            if (_selectedSupermarketIds.isEmpty) {
              _isSelectionMode = false;
            }
          });
        } else {
          _showSupermarketDetails(supermarket);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedSupermarketIds.add(supermarket['id']);
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
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.store,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              supermarket['name']?.trim() ?? 'بدون اسم',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              textAlign: TextAlign.right,
            ),
            subtitle: Text(
              supermarket['zone'] ?? 'غير متوفر',
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
    final theme = ThemeManager().currentTheme;
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

class AddEditSupermarketDialog extends StatefulWidget {
  final Map<String, dynamic>? supermarket;
  final VoidCallback onSave;

  const AddEditSupermarketDialog({super.key, this.supermarket, required this.onSave});

  @override
  _AddEditSupermarketDialogState createState() => _AddEditSupermarketDialogState();
}

class _AddEditSupermarketDialogState extends State<AddEditSupermarketDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _zoneController;
  late TextEditingController _locationController;
  late TextEditingController _deliveryFeeController;
  List<TextEditingController> _phoneControllers = [];
  List<TextEditingController> _whatsappControllers = [];
  bool _deliveryAvailable = false;
  bool _isLoading = false;
  bool _isLayoutReady = false;

  List<String> _parseField(dynamic field) {
    if (field == null || (field is String && (field.isEmpty || field == '{]}'))) {
      return [];
    }
    try {
      if (field is List) {
        return field.map((item) => item.toString().replaceAll('"', '').trim()).toList();
      } else if (field is String) {
        String cleanedJson = field
            .replaceAll('\\"', '"')
            .replaceAll('{', '[')
            .replaceAll('}', ']')
            .replaceAll('"[', '[')
            .replaceAll(']"', ']');
        return List<String>.from(jsonDecode(cleanedJson));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supermarket?['name']?.trim() ?? '');
    _zoneController = TextEditingController(text: widget.supermarket?['zone']?.trim() ?? '');
    _locationController = TextEditingController(text: widget.supermarket?['location']?.trim() ?? '');
    _deliveryFeeController = TextEditingController(text: widget.supermarket?['delivery_fee']?.trim() ?? '');

    List<String> phoneNumbers = _parseField(widget.supermarket?['phone']);
    List<String> whatsappNumbers = _parseField(widget.supermarket?['whatsapp']);

    _phoneControllers = phoneNumbers.isEmpty
        ? [TextEditingController()]
        : phoneNumbers.map((number) => TextEditingController(text: number)).toList();
    _whatsappControllers = whatsappNumbers.isEmpty
        ? [TextEditingController()]
        : whatsappNumbers.map((number) => TextEditingController(text: number)).toList();
    _deliveryAvailable = widget.supermarket?['delivery'] ?? false;

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
    _zoneController.dispose();
    _locationController.dispose();
    _deliveryFeeController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var controller in _whatsappControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPhoneField() {
    if (!_isLayoutReady || _phoneControllers.length >= 5) return;
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    if (!_isLayoutReady) return;
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  void _addWhatsappField() {
    if (!_isLayoutReady || _whatsappControllers.length >= 5) return;
    setState(() {
      _whatsappControllers.add(TextEditingController());
    });
  }

  void _removeWhatsappField(int index) {
    if (!_isLayoutReady) return;
    setState(() {
      _whatsappControllers[index].dispose();
      _whatsappControllers.removeAt(index);
    });
  }

  Future<void> _saveSupermarket() async {
    if (!_isLayoutReady || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);

      final phoneNumbers = _phoneControllers
          .map((controller) => controller.text.trim())
          .where((number) => number.isNotEmpty)
          .toList();
      final whatsappNumbers = _whatsappControllers
          .map((controller) => controller.text.trim())
          .where((number) => number.isNotEmpty)
          .toList();

      final data = {
        'name': _nameController.text.trim(),
        'zone': _zoneController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': phoneNumbers,
        'whatsapp': whatsappNumbers,
        'delivery': _deliveryAvailable,
        'delivery_fee': _deliveryFeeController.text.trim().isEmpty ? 'غير محدد' : _deliveryFeeController.text.trim(),
      };

      if (widget.supermarket == null) {
        await supabaseConfig.secondaryClient.from('supermarkets').insert(data);
      } else {
        await supabaseConfig.secondaryClient
            .from('supermarkets')
            .update(data)
            .eq('id', widget.supermarket!['id']);
      }

      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.supermarket == null ? 'تم الإضافة بنجاح' : 'تم التعديل بنجاح',
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
          title: Text(
            widget.supermarket == null ? 'إضافة سوبر ماركت' : 'تعديل سوبر ماركت',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          content: SizedBox(
            width: screenWidth * 0.9,
            height: screenHeight * 0.6,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'اسم السوبر ماركت',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم السوبر ماركت';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _zoneController,
                      label: 'المنطقة',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال المنطقة';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _locationController,
                      label: 'رابط الموقع',
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
                    const SizedBox(height: 12),
                    Text(
                      'أرقام الهاتف',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int index = 0; index < _phoneControllers.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _phoneControllers[index],
                                label: 'رقم الهاتف ${index + 1}',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null && value.trim().isNotEmpty) {
                                    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                                      return 'يرجى إدخال رقم هاتف صالح';
                                    }
                                    final currentNumber = value.trim();
                                    final otherNumbers = _phoneControllers
                                        .asMap()
                                        .entries
                                        .where((entry) => entry.key != index)
                                        .map((entry) => entry.value.text.trim())
                                        .toList();
                                    if (otherNumbers.contains(currentNumber)) {
                                      return 'هذا الرقم موجود بالفعل';
                                    }
                                  }
                                  return null;
                                },
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_phoneControllers.length > 1)
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.trash,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: _isLayoutReady ? () => _removePhoneField(index) : null,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    _buildAddButton(
                      label: 'إضافة رقم هاتف',
                      onPressed: _addPhoneField,
                      theme: theme,
                      isEnabled: _isLayoutReady && _phoneControllers.length < 5,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'أرقام واتساب',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int index = 0; index < _whatsappControllers.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _whatsappControllers[index],
                                label: 'رقم واتساب ${index + 1}',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value != null && value.trim().isNotEmpty) {
                                    if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                                      return 'يرجى إدخال رقم واتساب صالح';
                                    }
                                    final currentNumber = value.trim();
                                    final otherNumbers = _whatsappControllers
                                        .asMap()
                                        .entries
                                        .where((entry) => entry.key != index)
                                        .map((entry) => entry.value.text.trim())
                                        .toList();
                                    if (otherNumbers.contains(currentNumber)) {
                                      return 'هذا الرقم موجود بالفعل';
                                    }
                                  }
                                  return null;
                                },
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_whatsappControllers.length > 1)
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.trash,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: _isLayoutReady ? () => _removeWhatsappField(index) : null,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    _buildAddButton(
                      label: 'إضافة رقم واتساب',
                      onPressed: _addWhatsappField,
                      theme: theme,
                      isEnabled: _isLayoutReady && _whatsappControllers.length < 5,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _deliveryAvailable,
                          onChanged: _isLayoutReady
                              ? (value) {
                            setState(() {
                              _deliveryAvailable = value ?? false;
                            });
                          }
                              : null,
                          activeColor: theme.primaryColor,
                        ),
                        Text(
                          'متوفر التوصيل',
                          style: GoogleFonts.cairo(
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _deliveryFeeController,
                      label: 'رسوم التوصيل (اختياري)',
                      theme: theme,
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
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading || !_isLayoutReady ? null : _saveSupermarket,
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
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(
          color: theme.secondaryTextColor,
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
        fillColor: Colors.grey.shade100,
        errorStyle: GoogleFonts.cairo(
          color: Colors.red,
        ),
      ),
      style: GoogleFonts.cairo(
        color: theme.textColor,
      ),
      keyboardType: keyboardType,
      validator: validator,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }

  Widget _buildAddButton({
    required String label,
    required VoidCallback onPressed,
    required AppTheme theme,
    required bool isEnabled,
  }) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: const FaIcon(
        FontAwesomeIcons.plus,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: GoogleFonts.cairo(
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';

class PopupsManagementPage extends StatefulWidget {
  const PopupsManagementPage({super.key});

  @override
  _PopupsManagementPageState createState() => _PopupsManagementPageState();
}

class _PopupsManagementPageState extends State<PopupsManagementPage> {
  List<Map<String, dynamic>> _popups = [];
  List<Map<String, dynamic>> _filteredPopups = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'الكل';
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedPopupIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchPopups();
    _searchController.addListener(_filterPopups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPopups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('popups')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _popups = List<Map<String, dynamic>>.from(response);
        _filterPopups();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل النوافذ المنبثقة: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPopups() {
    final searchQuery = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredPopups = _popups.where((popup) {
        bool matchesStatus = _statusFilter == 'الكل' ||
            (_statusFilter == 'نشط' && popup['is_active'] == true) ||
            (_statusFilter == 'غير نشط' && popup['is_active'] != true);
        bool matchesSearch = searchQuery.isEmpty ||
            (popup['message']?.toLowerCase().contains(searchQuery) ?? false) ||
            (popup['page']?.toLowerCase().contains(searchQuery) ?? false);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deletePopup(String id) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient
          .from('popups')
          .delete()
          .eq('id', id);

      await _fetchPopups();
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
    if (_selectedPopupIds.isEmpty) return;

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
            'هل أنت متأكد من حذف ${_selectedPopupIds.length} نوافذ منبثقة؟',
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
                for (var id in _selectedPopupIds) {
                  await _deletePopup(id);
                }
                setState(() {
                  _selectedPopupIds.clear();
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

  void _showAddEditDialog({Map<String, dynamic>? popup}) {
    showDialog(
      context: context,
      builder: (context) => AddEditPopupDialog(
        popup: popup,
        onSave: () async {
          await _fetchPopups();
        },
      ),
    );
  }

  void _showPopupDetails(Map<String, dynamic> popup) {
    final theme = ThemeManager().currentTheme;
    final createdAt = DateTime.parse(popup['created_at']).toLocal();
    final formattedDate = intl.DateFormat('d/M/yyyy HH:mm').format(createdAt);

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
                                  popup['message']?.trim() ?? 'بدون رسالة',
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
                                      _showAddEditDialog(popup: popup);
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
                                              'هل أنت متأكد من حذف "${popup['message']?.trim() ?? 'هذه النافذة المنبثقة'}"؟',
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
                                                  _deletePopup(popup['id']);
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
                              if (popup['offer_link']?.isNotEmpty ?? false)
                                _buildActionButton(
                                  icon: Icons.link,
                                  label: 'رابط العرض',
                                  color: Colors.blue,
                                  onPressed: () async {
                                    final Uri uri = Uri.parse(popup['offer_link']);
                                    if (!await launchUrl(uri,
                                        mode: LaunchMode.externalApplication)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'لا يمكن فتح الرابط: ${popup['offer_link']}',
                                            style: GoogleFonts.cairo(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          if (popup['image_url'] != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  popup['image_url'],
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
                            icon: Icons.web,
                            label: 'الصفحة',
                            value: popup['page'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.link,
                            label: 'رابط العرض',
                            value: popup['offer_link'] ?? 'غير متوفر',
                            theme: theme,
                            isLink: true,
                            onTap: () async {
                              if (popup['offer_link'] != null) {
                                final Uri uri = Uri.parse(popup['offer_link']);
                                if (!await launchUrl(uri,
                                    mode: LaunchMode.externalApplication)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'لا يمكن فتح الرابط: ${popup['offer_link']}',
                                        style: GoogleFonts.cairo(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          _buildInfoRow(
                            icon: Icons.toggle_on,
                            label: 'الحالة',
                            value: popup['is_active'] == true ? 'نشط' : 'غير نشط',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'تاريخ الإنشاء',
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
                        hintText: 'ابحث بالرسالة أو الصفحة',
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
                            _filterPopups();
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
            // Status Filter
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
                  _buildFilterChip('نشط', theme, isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('غير نشط', theme, isMobile),
                ],
              ),
            ),
            // Popups List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPopups,
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
                    : _filteredPopups.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notification_important_outlined,
                        size: 60,
                        color: theme.secondaryTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد نوافذ منبثقة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  itemCount: _filteredPopups.length,
                  itemBuilder: (context, index) {
                    final popup = _filteredPopups[index];
                    final isSelected = _selectedPopupIds.contains(popup['id']);
                    return _buildPopupCard(
                      popup,
                      theme,
                      isMobile,
                      isSelected,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _fetchPopups,
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
              tooltip: 'إضافة نافذة منبثقة جديدة',
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
          color: _statusFilter == label ? Colors.white : theme.secondaryTextColor,
        ),
      ),
      selected: _statusFilter == label,
      selectedColor: theme.primaryColor,
      backgroundColor: Colors.grey.shade200,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = label;
            _filterPopups();
          });
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildPopupCard(
      Map<String, dynamic> popup,
      AppTheme theme,
      bool isMobile,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedPopupIds.remove(popup['id']);
            } else {
              _selectedPopupIds.add(popup['id']);
            }
            if (_selectedPopupIds.isEmpty) {
              _isSelectionMode = false;
            }
          });
        } else {
          _showPopupDetails(popup);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedPopupIds.add(popup['id']);
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
            leading: popup['image_url'] != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                popup['image_url'],
                width: isMobile ? 50 : 60,
                height: isMobile ? 50 : 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.notification_important,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            )
                : CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.notification_important,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              popup['message']?.trim() ?? 'بدون رسالة',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              textAlign: TextAlign.right,
            ),
            subtitle: Text(
              popup['page'] ?? 'غير متوفر',
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

class AddEditPopupDialog extends StatefulWidget {
  final Map<String, dynamic>? popup;
  final VoidCallback onSave;

  const AddEditPopupDialog({super.key, this.popup, required this.onSave});

  @override
  _AddEditPopupDialogState createState() => _AddEditPopupDialogState();
}

class _AddEditPopupDialogState extends State<AddEditPopupDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _messageController;
  late TextEditingController _pageController;
  late TextEditingController _offerLinkController;
  bool _isActive = false;
  bool _isLoading = false;
  bool _isImageUploading = false;
  bool _isLayoutReady = false;

  // Image data
  Uint8List? _imageBytes;
  String _imageUrl = '';
  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.popup?['message']?.trim() ?? '');
    _pageController = TextEditingController(text: widget.popup?['page']?.trim() ?? '');
    _offerLinkController = TextEditingController(text: widget.popup?['offer_link']?.trim() ?? '');
    _isActive = widget.popup?['is_active'] ?? false;
    _imageUrl = widget.popup?['image_url']?.trim() ?? '';

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
    _messageController.dispose();
    _pageController.dispose();
    _offerLinkController.dispose();
    super.dispose();
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

  Future<void> _savePopup() async {
    if (!_isLayoutReady || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);

      final data = {
        'message': _messageController.text.trim(),
        'page': _pageController.text.trim(),
        'offer_link': _offerLinkController.text.trim().isEmpty ? null : _offerLinkController.text.trim(),
        'is_active': _isActive,
        'image_url': _imageUrl.isEmpty ? null : _imageUrl,
      };

      if (widget.popup == null) {
        await supabaseConfig.secondaryClient.from('popups').insert(data);
      } else {
        await supabaseConfig.secondaryClient
            .from('popups')
            .update(data)
            .eq('id', widget.popup!['id']);
      }

      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.popup == null ? 'تم الإضافة بنجاح' : 'تم التعديل بنجاح',
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
                widget.popup == null ? 'إضافة نافذة منبثقة' : 'تعديل نافذة منبثقة',
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
            height: screenHeight * 0.6,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _messageController,
                      label: 'الرسالة',
                      icon: Icons.message,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الرسالة';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _pageController,
                      label: 'الصفحة',
                      icon: Icons.web,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الصفحة';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _offerLinkController,
                      label: 'رابط العرض (اختياري)',
                      icon: Icons.link,
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
                          value: _isActive,
                          onChanged: _isLayoutReady
                              ? (value) {
                            setState(() {
                              _isActive = value ?? false;
                            });
                          }
                              : null,
                          activeColor: theme.primaryColor,
                        ),
                        Text(
                          'نشط',
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
              onPressed: _isLoading || !_isLayoutReady ? null : _savePopup,
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
          'صورة النافذة المنبثقة',
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
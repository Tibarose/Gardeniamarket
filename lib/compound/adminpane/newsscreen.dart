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

class NewsManagementPage extends StatefulWidget {
  const NewsManagementPage({super.key});

  @override
  _NewsManagementPageState createState() => _NewsManagementPageState();
}

class _NewsManagementPageState extends State<NewsManagementPage> {
  List<Map<String, dynamic>> _newsItems = [];
  List<Map<String, dynamic>> _filteredNewsItems = [];
  bool _isLoading = true;
  String? _error;
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedNewsItemIds = {};
  bool _isSelectionMode = false;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchNewsItems();
    _searchController.addListener(_filterNewsItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNewsItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('news')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _newsItems = List<Map<String, dynamic>>.from(response);
        _filterNewsItems();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل الأخبار: $e';
        _isLoading = false;
      });
    }
  }

  void _filterNewsItems() {
    final searchQuery = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredNewsItems = _newsItems.where((newsItem) {
        bool matchesSearch = searchQuery.isEmpty ||
            (newsItem['title']?.toLowerCase().contains(searchQuery) ?? false) ||
            (newsItem['description']?.toLowerCase().contains(searchQuery) ?? false);
        bool matchesDateRange = _selectedDateRange == null ||
            (newsItem['date'] != null &&
                DateTime.parse(newsItem['date']).isAfter(
                    _selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                DateTime.parse(newsItem['date'])
                    .isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
        return matchesSearch && matchesDateRange;
      }).toList();
    });
  }

  Future<void> _deleteNewsItem(String id) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient.from('news').delete().eq('id', id);

      await _fetchNewsItems();
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
    if (_selectedNewsItemIds.isEmpty) return;

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
            'هل أنت متأكد من حذف ${_selectedNewsItemIds.length} أخبار؟',
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
                for (var id in _selectedNewsItemIds) {
                  await _deleteNewsItem(id);
                }
                setState(() {
                  _selectedNewsItemIds.clear();
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

  void _showAddEditDialog({Map<String, dynamic>? newsItem}) {
    showDialog(
      context: context,
      builder: (context) => AddEditNewsDialog(
        newsItem: newsItem,
        onSave: () async {
          await _fetchNewsItems();
        },
      ),
    );
  }

  void _showNewsDetails(Map<String, dynamic> newsItem) {
    final theme = ThemeManager().currentTheme;
    final createdAt = DateTime.parse(newsItem['created_at']).toLocal();
    final formattedCreatedAt = intl.DateFormat('d/M/yyyy HH:mm').format(createdAt);
    final updatedAt = DateTime.parse(newsItem['updated_at']).toLocal();
    final formattedUpdatedAt = intl.DateFormat('d/M/yyyy HH:mm').format(updatedAt);

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
                                  newsItem['title']?.trim() ?? 'بدون عنوان',
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
                                      _showAddEditDialog(newsItem: newsItem);
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
                                              borderRadius:
                                              BorderRadius.circular(20),
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
                                              'هل أنت متأكد من حذف "${newsItem['title']?.trim() ?? 'هذا الخبر'}"؟',
                                              style: GoogleFonts.cairo(
                                                color: theme.textColor,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  'إلغاء',
                                                  style: GoogleFonts.cairo(
                                                    color:
                                                    theme.secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteNewsItem(newsItem['id']);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(12),
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
                              if (newsItem['facebook_url']?.isNotEmpty ?? false)
                                _buildActionButton(
                                  icon: FontAwesomeIcons.facebook,
                                  label: 'رابط فيسبوك',
                                  color: Colors.blue,
                                  onPressed: () async {
                                    final Uri uri =
                                    Uri.parse(newsItem['facebook_url']);
                                    if (!await launchUrl(uri,
                                        mode: LaunchMode.externalApplication)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'لا يمكن فتح الرابط: ${newsItem['facebook_url']}',
                                            style: GoogleFonts.cairo(
                                                color: Colors.white),
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
                          if (newsItem['image_url'] != null &&
                              newsItem['image_url'].isNotEmpty)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  newsItem['image_url'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.description,
                            label: 'الوصف',
                            value: newsItem['description'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'التاريخ',
                            value: newsItem['date'] != null
                                ? intl.DateFormat('d/M/yyyy')
                                .format(DateTime.parse(newsItem['date']))
                                : 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: FontAwesomeIcons.facebook,
                            label: 'رابط فيسبوك',
                            value: newsItem['facebook_url'] ?? 'غير متوفر',
                            theme: theme,
                            isLink: newsItem['facebook_url'] != null,
                            onTap: () async {
                              if (newsItem['facebook_url'] != null) {
                                final Uri uri = Uri.parse(newsItem['facebook_url']);
                                if (!await launchUrl(uri,
                                    mode: LaunchMode.externalApplication)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'لا يمكن فتح الرابط: ${newsItem['facebook_url']}',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          _buildInfoRow(
                            icon: Icons.create,
                            label: 'تاريخ الإنشاء',
                            value: formattedCreatedAt,
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.update,
                            label: 'تاريخ التحديث',
                            value: formattedUpdatedAt,
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeManager().currentTheme.primaryColor,
              onPrimary: Colors.white,
              surface: ThemeManager().currentTheme.cardBackground,
              onSurface: ThemeManager().currentTheme.textColor,
            ),
            dialogBackgroundColor: ThemeManager().currentTheme.cardBackground,
            textTheme: GoogleFonts.cairoTextTheme(),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterNewsItems();
      });
    }
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
                        hintText: 'ابحث بالعنوان أو الوصف',
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
                            _filterNewsItems();
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
            // Date Range Filter
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      _selectedDateRange == null
                          ? 'تصفية حسب التاريخ'
                          : '${intl.DateFormat('d/M/yyyy').format(_selectedDateRange!.start)} - ${intl.DateFormat('d/M/yyyy').format(_selectedDateRange!.end)}',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.red,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                            _filterNewsItems();
                          });
                        },
                        tooltip: 'إلغاء التصفية',
                      ),
                    ),
                ],
              ),
            ),
            // News List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchNewsItems,
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
                    : _filteredNewsItems.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 60,
                        color: theme.secondaryTextColor
                            .withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد أخبار',
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
                  itemCount: _filteredNewsItems.length,
                  itemBuilder: (context, index) {
                    final newsItem = _filteredNewsItems[index];
                    final isSelected =
                    _selectedNewsItemIds.contains(newsItem['id']);
                    return _buildNewsCard(
                      newsItem,
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
              onPressed: _fetchNewsItems,
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
              tooltip: 'إضافة خبر جديد',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(
      Map<String, dynamic> newsItem,
      AppTheme theme,
      bool isMobile,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedNewsItemIds.remove(newsItem['id']);
            } else {
              _selectedNewsItemIds.add(newsItem['id']);
            }
            if (_selectedNewsItemIds.isEmpty) {
              _isSelectionMode = false;
            }
          });
        } else {
          _showNewsDetails(newsItem);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedNewsItemIds.add(newsItem['id']);
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
            leading: newsItem['image_url'] != null && newsItem['image_url'].isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                newsItem['image_url'],
                width: isMobile ? 50 : 60,
                height: isMobile ? 50 : 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => CircleAvatar(
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.article,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            )
                : CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.article,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              newsItem['title']?.trim() ?? 'بدون عنوان',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              textAlign: TextAlign.right,
            ),
            subtitle: Text(
              newsItem['date'] != null
                  ? intl.DateFormat('d/M/yyyy').format(DateTime.parse(newsItem['date']))
                  : 'غير متوفر',
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

class AddEditNewsDialog extends StatefulWidget {
  final Map<String, dynamic>? newsItem;
  final VoidCallback onSave;

  const AddEditNewsDialog({super.key, this.newsItem, required this.onSave});

  @override
  _AddEditNewsDialogState createState() => _AddEditNewsDialogState();
}

class _AddEditNewsDialogState extends State<AddEditNewsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _facebookUrlController;
  DateTime? _selectedDate;
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
    _titleController = TextEditingController(text: widget.newsItem?['title']?.trim() ?? '');
    _descriptionController =
        TextEditingController(text: widget.newsItem?['description']?.trim() ?? '');
    _facebookUrlController =
        TextEditingController(text: widget.newsItem?['facebook_url']?.trim() ?? '');
    _selectedDate =
    widget.newsItem?['date'] != null ? DateTime.parse(widget.newsItem!['date']) : null;
    _imageUrl = widget.newsItem?['image_url']?.trim() ?? '';

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
    _titleController.dispose();
    _descriptionController.dispose();
    _facebookUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeManager().currentTheme.primaryColor,
              onPrimary: Colors.white,
              surface: ThemeManager().currentTheme.cardBackground,
              onSurface: ThemeManager().currentTheme.textColor,
            ),
            dialogBackgroundColor: ThemeManager().currentTheme.cardBackground,
            textTheme: GoogleFonts.cairoTextTheme(),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
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

  Future<void> _saveNewsItem() async {
    if (!_isLayoutReady || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDate?.toIso8601String(),
        'facebook_url': _facebookUrlController.text.trim().isEmpty
            ? null
            : _facebookUrlController.text.trim(),
        'image_url': _imageUrl.isEmpty ? null : _imageUrl,
      };

      if (widget.newsItem == null) {
        await supabaseConfig.secondaryClient.from('news').insert(data);
      } else {
        await supabaseConfig.secondaryClient
            .from('news')
            .update(data)
            .eq('id', widget.newsItem!['id']);
      }

      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.newsItem == null ? 'تم الإضافة بنجاح' : 'تم التعديل بنجاح',
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
                widget.newsItem == null ? 'إضافة خبر' : 'تعديل خبر',
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
                      controller: _titleController,
                      label: 'العنوان',
                      icon: Icons.title,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال العنوان';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'الوصف',
                      icon: Icons.description,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال الوصف';
                        }
                        return null;
                      },
                      theme: theme,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          controller: TextEditingController(
                            text: _selectedDate != null
                                ? intl.DateFormat('d/M/yyyy').format(_selectedDate!)
                                : '',
                          ),
                          label: 'التاريخ',
                          icon: Icons.calendar_today,
                          validator: (value) {
                            if (_selectedDate == null) {
                              return 'يرجى اختيار التاريخ';
                            }
                            return null;
                          },
                          theme: theme,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _facebookUrlController,
                      label: 'رابط فيسبوك (اختياري)',
                      icon: FontAwesomeIcons.facebook,
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
              onPressed: _isLoading || !_isLayoutReady ? null : _saveNewsItem,
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
    int maxLines = 1,
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
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
    );
  }

  Widget _buildImageUploadSection(bool isMobile, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صورة الخبر (اختياري)',
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
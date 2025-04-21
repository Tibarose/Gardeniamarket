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

class BusinessSubmissionsPage extends StatefulWidget {
  const BusinessSubmissionsPage({super.key});

  @override
  _BusinessSubmissionsPageState createState() => _BusinessSubmissionsPageState();
}

class _BusinessSubmissionsPageState extends State<BusinessSubmissionsPage> {
  List<Map<String, dynamic>> _businessSubmissions = [];
  List<Map<String, dynamic>> _filteredSubmissions = [];
  bool _isLoading = true;
  String? _error;
  String _locationFilter = 'الكل';
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedSubmissionIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchBusinessSubmissions();
    _searchController.addListener(_filterSubmissions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBusinessSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('business_submissions')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _businessSubmissions = List<Map<String, dynamic>>.from(response);
        _filterSubmissions();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل الطلبات: $e';
        _isLoading = false;
      });
    }
  }

  void _filterSubmissions() {
    final searchQuery = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredSubmissions = _businessSubmissions.where((submission) {
        bool matchesLocation = _locationFilter == 'الكل' ||
            submission['location'] == _locationFilter;
        bool matchesSearch = searchQuery.isEmpty ||
            (submission['business_name']?.toLowerCase().contains(searchQuery) ?? false) ||
            (submission['whatsapp']?.toLowerCase().contains(searchQuery) ?? false);
        return matchesLocation && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deleteSubmission(String id) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient
          .from('business_submissions')
          .delete()
          .eq('id', id);

      await _fetchBusinessSubmissions();
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
    if (_selectedSubmissionIds.isEmpty) return;

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
            'هل أنت متأكد من حذف ${_selectedSubmissionIds.length} طلبات؟',
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
                for (var id in _selectedSubmissionIds) {
                  await _deleteSubmission(id);
                }
                setState(() {
                  _selectedSubmissionIds.clear();
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

  Future<void> _updateNotes(String id, String notes) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient
          .from('business_submissions')
          .update({'notes': notes})
          .eq('id', id);

      await _fetchBusinessSubmissions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث الملاحظات بنجاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: ThemeManager().currentTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في تحديث الملاحظات: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showAddNotesDialog(String id, String? existingNotes) {
    final TextEditingController notesController = TextEditingController(text: existingNotes ?? '');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: ThemeManager().currentTheme.cardBackground,
              title: Text(
                existingNotes == null ? 'إضافة ملاحظات' : 'تعديل الملاحظات',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: ThemeManager().currentTheme.textColor,
                ),
              ),
              content: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'الملاحظات',
                          labelStyle: GoogleFonts.cairo(
                            color: ThemeManager().currentTheme.secondaryTextColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: ThemeManager().currentTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        style: GoogleFonts.cairo(
                          color: ThemeManager().currentTheme.textColor,
                        ),
                        maxLines: 3,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  );
                },
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
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() {
                      isLoading = true;
                    });
                    await _updateNotes(id, notesController.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeManager().currentTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: isLoading
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
      },
    );
  }

  void _showSubmissionDetails(Map<String, dynamic> submission) {
    final theme = ThemeManager().currentTheme;
    final createdAt = DateTime.parse(submission['created_at']).toLocal();
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
                                  submission['business_name'] ?? 'بدون اسم',
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
                                    icon: FontAwesomeIcons.stickyNote,
                                    color: submission['notes'] != null &&
                                        submission['notes'].isNotEmpty
                                        ? theme.primaryColor
                                        : theme.secondaryTextColor,
                                    tooltip: 'إضافة/تعديل ملاحظات',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showAddNotesDialog(
                                          submission['id'], submission['notes']);
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
                                              'هل أنت متأكد من حذف طلب "${submission['business_name'] ?? 'هذا الطلب'}"؟',
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
                                                    color: theme
                                                        .secondaryTextColor,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteSubmission(
                                                      submission['id']);
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
                          // Quick Actions
                          if (submission['whatsapp']?.isNotEmpty ?? false)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.end,
                              children: [
                                _buildActionButton(
                                  icon: FontAwesomeIcons.whatsapp,
                                  label: 'واتساب',
                                  color: Colors.green,
                                  onPressed: () =>
                                      _launchWhatsApp(submission['whatsapp']),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.store,
                            label: 'اسم النشاط',
                            value: submission['business_name'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.description,
                            label: 'وصف النشاط',
                            value: submission['description'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'اسم العميل',
                            value: submission['contact_name'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.phone,
                            label: 'رقم التليفون',
                            value: submission['whatsapp'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            label: 'الموقع',
                            value: submission['location'] ?? 'غير متوفر',
                            theme: theme,
                          ),
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'تاريخ الإضافة',
                            value: formattedDate,
                            theme: theme,
                          ),
                          if (submission['notes'] != null &&
                              submission['notes'].isNotEmpty)
                            _buildInfoRow(
                              icon: Icons.note,
                              label: 'الملاحظات',
                              value: submission['notes'],
                              theme: theme,
                              valueColor: theme.primaryColor,
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
                        hintText: 'ابحث بالاسم أو رقم التليفون',
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
                            _filterSubmissions();
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
                          borderSide: BorderSide(
                              color: theme.primaryColor, width: 2),
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
            // Location Filter
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
            // Submissions List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchBusinessSubmissions,
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
                    : _filteredSubmissions.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center_outlined,
                        size: 60,
                        color:
                        theme.secondaryTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد طلبات أعمال مقدمة',
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
                    itemCount: _filteredSubmissions.length,
                    itemBuilder: (context, index) {
                      final submission = _filteredSubmissions[index];
                      final isSelected = _selectedSubmissionIds
                          .contains(submission['id']);
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildSubmissionCard(
                              submission,
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
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchBusinessSubmissions,
          backgroundColor: theme.primaryColor,
          child: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'تحديث القائمة',
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
          color: _locationFilter == label
              ? Colors.white
              : theme.secondaryTextColor,
        ),
      ),
      selected: _locationFilter == label,
      selectedColor: theme.primaryColor,
      backgroundColor: Colors.grey.shade200,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _locationFilter = label;
            _filterSubmissions();
          });
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildSubmissionCard(
      Map<String, dynamic> submission,
      AppTheme theme,
      bool isMobile,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedSubmissionIds.remove(submission['id']);
            } else {
              _selectedSubmissionIds.add(submission['id']);
            }
            if (_selectedSubmissionIds.isEmpty) {
              _isSelectionMode = false;
            }
          });
        } else {
          _showSubmissionDetails(submission);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedSubmissionIds.add(submission['id']);
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
                Icons.business,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              submission['business_name'] ?? 'بدون اسم',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              textAlign: TextAlign.right,
            ),
            subtitle: Text(
              submission['location'] ?? 'غير متوفر',
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
    Color? valueColor,
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
                      color: valueColor ?? theme.secondaryTextColor,
                    ),
                  ),
                ],
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
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../main.dart'; // Import for SupabaseConfig
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';

class CarouselAdminScreen extends StatefulWidget {
  const CarouselAdminScreen({super.key});

  @override
  _CarouselAdminScreenState createState() => _CarouselAdminScreenState();
}

class _CarouselAdminScreenState extends State<CarouselAdminScreen> {
  List<Map<String, dynamic>> _carouselItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCarouselItems();
  }

  Future<void> _fetchCarouselItems() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('carousel_items')
          .select('id, image, title, subtitle, route, link');

      setState(() {
        _carouselItems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load carousel items: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCarouselItem(String id) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient
          .from('carousel_items')
          .delete()
          .eq('id', id);

      await _fetchCarouselItems(); // Refresh the list
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

  void _showAddEditDialog({Map<String, dynamic>? item}) {
    showDialog(
      context: context,
      builder: (context) => AddEditCarouselDialog(
        item: item,
        onSave: () async {
          await _fetchCarouselItems(); // Refresh after add/edit
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة عناصر الكاروسيل',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plus),
              onPressed: () => _showAddEditDialog(),
              tooltip: 'إضافة عنصر جديد',
            ),
          ],
        ),
        body: _isLoading
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
            : _carouselItems.isEmpty
            ? Center(
          child: Text(
            'لا توجد عناصر كاروسيل',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: theme.secondaryTextColor,
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _carouselItems.length,
          itemBuilder: (context, index) {
            final item = _carouselItems[index];
            return Card(
              color: theme.cardBackground,
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: item['image'] != null && item['image'].isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => FaIcon(
                      FontAwesomeIcons.image,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                )
                    : FaIcon(
                  FontAwesomeIcons.image,
                  color: theme.secondaryTextColor,
                ),
                title: Text(
                  item['title'] ?? 'بدون عنوان',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['subtitle'] ?? 'بدون وصف',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                    if (item['link'] != null && item['link'].isNotEmpty)
                      Text(
                        'رابط: ${item['link']}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: FaIcon(
                        FontAwesomeIcons.edit,
                        color: theme.primaryColor,
                      ),
                      onPressed: () => _showAddEditDialog(item: item),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.trash,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              'تأكيد الحذف',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: Text(
                              'هل أنت متأكد من حذف "${item['title'] ?? 'هذا العنصر'}"؟',
                              style: GoogleFonts.cairo(),
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
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteCarouselItem(item['id'].toString());
                                },
                                child: Text(
                                  'حذف',
                                  style: GoogleFonts.cairo(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddEditCarouselDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSave;

  const AddEditCarouselDialog({super.key, this.item, required this.onSave});

  @override
  _AddEditCarouselDialogState createState() => _AddEditCarouselDialogState();
}

class _AddEditCarouselDialogState extends State<AddEditCarouselDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _routeController;
  late TextEditingController _linkController;
  bool _isLoading = false;
  bool _isImageUploading = false;

  // Image data
  Uint8List? _imageBytes;
  String _imageUrl = '';
  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?['title'] ?? '');
    _subtitleController = TextEditingController(text: widget.item?['subtitle'] ?? '');
    _routeController = TextEditingController(text: widget.item?['route'] ?? '');
    _linkController = TextEditingController(text: widget.item?['link'] ?? '');
    _imageUrl = widget.item?['image'] ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _routeController.dispose();
    _linkController.dispose();
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

  Future<void> _saveCarouselItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final data = {
        if (_imageUrl.isNotEmpty) 'image': _imageUrl,
        if (_titleController.text.trim().isNotEmpty) 'title': _titleController.text.trim(),
        if (_subtitleController.text.trim().isNotEmpty) 'subtitle': _subtitleController.text.trim(),
        if (_routeController.text.trim().isNotEmpty) 'route': _routeController.text.trim(),
        if (_linkController.text.trim().isNotEmpty) 'link': _linkController.text.trim(),
      };

      if (widget.item == null) {
        // Add new item
        await supabaseConfig.secondaryClient.from('carousel_items').insert(data);
      } else {
        // Update existing item
        await supabaseConfig.secondaryClient
            .from('carousel_items')
            .update(data)
            .eq('id', widget.item!['id']);
      }

      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.item == null ? 'تم الإضافة بنجاح' : 'تم التعديل بنجاح',
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.item == null ? 'إضافة عنصر كاروسيل' : 'تعديل عنصر كاروسيل',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageUploadSection(isMobile, theme),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'العنوان',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subtitleController,
                  decoration: InputDecoration(
                    labelText: 'الوصف',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _routeController,
                  decoration: InputDecoration(
                    labelText: 'مسار التوجيه',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.cairo(),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!value.trim().startsWith('/')) {
                        return 'المسار يجب أن يبدأ بـ /';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    labelText: 'الرابط',
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.cairo(),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (!Uri.parse(value.trim()).isAbsolute) {
                        return 'يرجى إدخال رابط صالح';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: theme.secondaryTextColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveCarouselItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
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
    );
  }

  Widget _buildImageUploadSection(bool isMobile, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صورة الكاروسيل',
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
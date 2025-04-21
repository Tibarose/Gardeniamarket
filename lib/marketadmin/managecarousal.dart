import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';

import '../main.dart';

class CarouselItemsPage extends StatefulWidget {
  const CarouselItemsPage({super.key});

  @override
  _CarouselItemsPageState createState() => _CarouselItemsPageState();
}

class _CarouselItemsPageState extends State<CarouselItemsPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  List<Map<String, dynamic>> categories = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController imageController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  String? selectedCategoryId;

  bool isLoading = false;
  bool isActionLoading = false;

  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchItems();
      _fetchCategories();
      searchController.addListener(_filterItems);
    });
  }

  Future<void> _fetchItems() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('carousel_items')
          .select('id, title, image_url, category_name, created_at');

      setState(() {
        items = response.map<Map<String, dynamic>>((item) => {
          'id': item['id'],
          'title': item['title'] ?? '',
          'image_url': item['image_url'] ?? '',
          'category_name': item['category_name'] ?? '',
          'created_at': item['created_at'],
        }).toList();
        filteredItems = List.from(items);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('خطأ في جلب العناصر: $e', Colors.red);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await supabase
          .from('market_categories')
          .select('id, name')
          .order('name', ascending: true);

      setState(() {
        categories = response.map<Map<String, dynamic>>((cat) => {
          'id': cat['id'].toString(),
          'name': cat['name'],
        }).toList();
      });
    } catch (e) {
      _showSnackBar('خطأ في جلب الفئات: $e', Colors.red);
    }
  }

  void _filterItems() {
    setState(() {
      filteredItems = items.where((item) {
        return item['title'].toLowerCase().contains(searchController.text.toLowerCase()) ||
            item['category_name'].toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null) return;
      setState(() => isActionLoading = true);
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
        imageController.text = jsonData['data']['url'];
      }
      setState(() => isActionLoading = false);
    } catch (e) {
      setState(() => isActionLoading = false);
      _showSnackBar('خطأ في رفع الصورة: $e', Colors.red);
    }
  }

  void _showAddEditForm([Map<String, dynamic>? item]) {
    if (item != null) {
      titleController.text = item['title'];
      imageController.text = item['image_url'];
      selectedCategoryId = categories
          .firstWhere(
            (cat) => cat['name'] == item['category_name'],
        orElse: () => {'id': null},
      )['id'];
    } else {
      titleController.clear();
      imageController.clear();
      selectedCategoryId = null;
    }

    final isDesktop = MediaQuery.of(context).size.width > 1200;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: _buildAddEditForm(item),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        backgroundColor: Colors.white,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: _buildAddEditForm(item, scrollController: controller),
          ),
        ),
      );
    }
  }

  Widget _buildAddEditForm(Map<String, dynamic>? item, {ScrollController? scrollController}) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ListView(
      controller: scrollController,
      children: [
        Text(
          item == null ? 'إضافة عنصر' : 'تعديل عنصر',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 20 : 22,
            fontWeight: FontWeight.w700,
            color: Colors.teal[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: 'العنوان (اختياري)',
            labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: GoogleFonts.cairo(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'الفئة',
            labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category['id'],
              child: Text(category['name'], style: GoogleFonts.cairo()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategoryId = value;
            });
          },
          hint: Text('اختر الفئة', style: GoogleFonts.cairo()),
          validator: (value) => value == null ? 'الفئة مطلوبة' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: imageController,
                decoration: InputDecoration(
                  labelText: 'رابط الصورة',
                  labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.cairo(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: isActionLoading ? null : _uploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                elevation: 4,
                shadowColor: Colors.teal.withOpacity(0.3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('رفع', style: GoogleFonts.cairo(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        if (imageController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageController.text,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: isActionLoading
                  ? null
                  : () {
                if (imageController.text.isEmpty || selectedCategoryId == null) {
                  _showSnackBar('رابط الصورة والفئة مطلوبان', Colors.red);
                  return;
                }
                if (item == null) {
                  _addItem();
                } else {
                  _editItem(item);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 4,
                shadowColor: Colors.teal.withOpacity(0.3),
              ),
              child: Text(
                item == null ? 'إضافة' : 'حفظ',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _addItem() async {
    setState(() => isActionLoading = true);
    try {
      final categoryName = categories.firstWhere((cat) => cat['id'] == selectedCategoryId)['name'];
      final newItem = await supabase.from('carousel_items').insert({
        "title": titleController.text.isEmpty ? null : titleController.text,
        "image_url": imageController.text,
        "category_name": categoryName,
      }).select().single();
      setState(() {
        items.add({
          "id": newItem['id'],
          "title": newItem['title'] ?? '',
          "image_url": newItem['image_url'],
          "category_name": newItem['category_name'],
          "created_at": newItem['created_at'],
        });
        filteredItems = List.from(items);
        isActionLoading = false;
      });
      _showSnackBar('تمت الإضافة بنجاح', Colors.teal);
    } catch (e) {
      setState(() => isActionLoading = false);
      _showSnackBar('خطأ في الإضافة: $e', Colors.red);
    }
  }

  void _editItem(Map<String, dynamic> item) async {
    setState(() => isActionLoading = true);
    try {
      final categoryName = categories.firstWhere((cat) => cat['id'] == selectedCategoryId)['name'];
      await supabase.from('carousel_items').update({
        "title": titleController.text.isEmpty ? null : titleController.text,
        "image_url": imageController.text,
        "category_name": categoryName,
      }).eq('id', item['id']);

      setState(() {
        final index = items.indexWhere((i) => i['id'] == item['id']);
        if (index != -1) {
          items[index] = {
            'id': item['id'],
            'title': titleController.text,
            'image_url': imageController.text,
            'category_name': categoryName,
            'created_at': item['created_at'],
          };
          filteredItems = List.from(items);
        }
        isActionLoading = false;
      });
      _showSnackBar('تم التعديل بنجاح', Colors.teal);
    } catch (e) {
      setState(() => isActionLoading = false);
      _showSnackBar('خطأ في التعديل: $e', Colors.red);
    }
  }

  void _deleteItem(Map<String, dynamic> item) async {
    final deletedItem = Map<String, dynamic>.from(item);
    setState(() => isActionLoading = true);
    try {
      await supabase.from('carousel_items').delete().eq('id', deletedItem['id']);
      setState(() {
        items.removeWhere((i) => i['id'] == deletedItem['id']);
        filteredItems = List.from(items);
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الحذف', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'تراجع',
            textColor: Colors.yellow,
            onPressed: () async {
              setState(() => isActionLoading = true);
              await supabase.from('carousel_items').insert(deletedItem);
              setState(() {
                items.add(deletedItem);
                filteredItems = List.from(items);
                isActionLoading = false;
              });
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      _showSnackBar('خطأ في الحذف: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            'إدارة عناصر الاعلانات',
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
                        leading: const Icon(Icons.slideshow, color: Colors.teal),
                        title: Text('الاعلانات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
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
                    ],
                  ),
                ),
              // Main Content
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Top Bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: isMobile
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن عنوان أو فئة...',
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
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => _showAddEditForm(),
                                icon: const Icon(Icons.add),
                                label: Text('إضافة عنصر', style: GoogleFonts.cairo(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: Colors.teal[600],
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: Colors.teal.withOpacity(0.3),
                                ),
                              ),
                            ],
                          )
                              : Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'ابحث عن عنوان أو فئة...',
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
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showAddEditForm(),
                                icon: const Icon(Icons.add),
                                label: Text('إضافة عنصر', style: GoogleFonts.cairo(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: Colors.teal[600],
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: Colors.teal.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Main Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                                : filteredItems.isEmpty
                                ? Center(
                              child: FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                child: Text(
                                  'لا توجد عناصر',
                                  style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
                                ),
                              ),
                            )
                                : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isMobile ? 2.5 : (isTablet ? 2 : 1.8),
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
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
                                          child: InkWell(
                                            onTap: () => _showAddEditForm(item),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      item['image_url'],
                                                      width: isMobile ? 60 : 80,
                                                      height: isMobile ? 60 : 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Icon(
                                                        Icons.broken_image,
                                                        size: isMobile ? 60 : 80,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          item['title'].isEmpty ? 'بدون عنوان' : item['title'],
                                                          style: GoogleFonts.cairo(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'الفئة: ${item['category_name']}',
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
                                                        onPressed: () => _showAddEditForm(item),
                                                        tooltip: 'تعديل',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
                                                        onPressed: () => _deleteItem(item),
                                                        tooltip: 'حذف',
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
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
                        ),
                      ],
                    ),
                    if (isActionLoading)
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
    titleController.dispose();
    imageController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
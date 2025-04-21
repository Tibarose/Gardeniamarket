import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import '../main.dart';

class MarketCategoriesPage extends StatefulWidget {
  @override
  _MarketCategoriesPageState createState() => _MarketCategoriesPageState();
}

class _MarketCategoriesPageState extends State<MarketCategoriesPage> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController imageController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  bool isActionLoading = false;

  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCategories();
      searchController.addListener(_filterCategories);
    });
  }

  Future<void> _fetchCategories() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final categoryResponse = await supabase.from('market_categories').select('id, name, image, created_at');
      final productResponse = await supabase.from('products').select('category_id');

      final productCounts = <int, int>{};
      for (var product in productResponse) {
        final categoryId = product['category_id'] as int?;
        if (categoryId != null) {
          productCounts[categoryId] = (productCounts[categoryId] ?? 0) + 1;
        }
      }

      setState(() {
        categories = categoryResponse.map((cat) {
          return {
            'id': cat['id'],
            'name': cat['name'],
            'image': cat['image'] ?? '',
            'created_at': cat['created_at'],
            'productCount': productCounts[cat['id']] ?? 0,
          };
        }).toList();
        filteredCategories = List.from(categories);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في جلب الفئات: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterCategories() {
    setState(() {
      filteredCategories = categories.where((category) {
        return category['name'].toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
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
      }
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع الصورة: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? category]) {
    if (category != null) {
      nameController.text = category['name'];
      imageController.text = category['image'];
    } else {
      nameController.clear();
      imageController.clear();
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: isMobile ? double.infinity : 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category == null ? 'إضافة فئة' : 'تعديل فئة',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الفئة',
                    labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                    ),
                  ),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageController,
                        decoration: InputDecoration(
                          labelText: 'رابط الصورة (اختياري)',
                          labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isActionLoading ? null : _uploadImage,
                      icon: const Icon(Icons.upload, size: 20),
                      label: Text('رفع', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.teal.withOpacity(0.3),
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isActionLoading
                          ? null
                          : () {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('اسم الفئة مطلوب', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (category == null) {
                          _addCategory();
                        } else {
                          _editCategory(category);
                        }
                        Navigator.pop(context);
                      },
                      child: Text(
                        category == null ? ' إضافة' : 'حفظ',
                        style: GoogleFonts.cairo(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.teal[600],
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.teal.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addCategory() async {
    setState(() => isActionLoading = true);
    try {
      final newCategory = await supabase.from('market_categories').insert({
        "name": nameController.text,
        "image": imageController.text.isEmpty ? null : imageController.text,
      }).select().single();
      setState(() {
        categories.add({
          "id": newCategory['id'],
          "name": newCategory['name'],
          "image": newCategory['image'] ?? '',
          "created_at": newCategory['created_at'],
          "productCount": 0,
        });
        filteredCategories = List.from(categories);
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت الإضافة بنجاح', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الإضافة: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editCategory(Map<String, dynamic> category) async {
    setState(() => isActionLoading = true);
    try {
      await supabase.from('market_categories').update({
        "name": nameController.text,
        "image": imageController.text.isEmpty ? null : imageController.text,
      }).eq('id', category['id']);

      setState(() {
        final index = categories.indexWhere((cat) => cat['id'] == category['id']);
        if (index != -1) {
          categories[index]['name'] = nameController.text;
          categories[index]['image'] = imageController.text;
          filteredCategories = List.from(categories);
        }
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التعديل بنجاح', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التعديل: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteCategory(Map<String, dynamic> category) async {
    final deletedCategory = Map<String, dynamic>.from(category);
    setState(() => isActionLoading = true);
    try {
      await supabase.from('market_categories').delete().eq('id', deletedCategory['id']);
      setState(() {
        categories.removeWhere((cat) => cat['id'] == deletedCategory['id']);
        filteredCategories = List.from(categories);
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الحذف', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
          action: SnackBarAction(
            label: 'تراجع',
            textColor: Colors.yellow,
            onPressed: () async {
              setState(() => isActionLoading = true);
              await supabase.from('market_categories').insert(deletedCategory);
              setState(() {
                categories.add(deletedCategory);
                filteredCategories = List.from(categories);
                isActionLoading = false;
              });
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحذف: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة الفئات',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
              // Inside MarketCategoriesPage's build method
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
                        leading: const Icon(Icons.category, color: Colors.teal),
                        title: Text('الفئات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
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
                        leading: const Icon(Icons.slideshow, color: Colors.teal),
                        title: Text('الاعلانات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
                        onTap: () => Navigator.pushNamed(context, '/CarouselItemsPage'),
                        selected: false,
                      ),
                    ],
                  ),
                ),
              // Main Content
              Expanded(
                child: Column(
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
                              hintText: 'ابحث عن فئة...',
                              hintStyle: GoogleFonts.cairo(),
                              prefixIcon: const Icon(Icons.search, color: Colors.teal),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add),
                            label: Text('إضافة فئة', style: GoogleFonts.cairo(fontSize: 16)),
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
                                hintText: 'ابحث عن فئة...',
                                hintStyle: GoogleFonts.cairo(),
                                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add),
                            label: Text('إضافة فئة', style: GoogleFonts.cairo(fontSize: 16)),
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
                            : filteredCategories.isEmpty
                            ? Center(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              'لا توجد فئات',
                              style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ),
                        )
                            : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              child: category['image'].isNotEmpty
                                                  ? Image.network(
                                                category['image'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.teal[200],
                                                  child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white),
                                                ),
                                              )
                                                  : Container(
                                                color: Colors.teal[200],
                                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category['name'],
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
                                                    'المنتجات: ${category['productCount']}',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 14,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit, color: Colors.white),
                                                        onPressed: () => _showAddEditDialog(category),
                                                        tooltip: 'تعديل',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                        onPressed: () => _deleteCategory(category),
                                                        tooltip: 'حذف',
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    imageController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
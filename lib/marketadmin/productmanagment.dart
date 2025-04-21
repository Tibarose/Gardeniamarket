import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' as intl;
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:animate_do/animate_do.dart';

// Conditional import for download
import 'download_stub.dart' if (dart.library.html) 'web_download.dart';
import 'mobile_download.dart';

import '../main.dart'; // Assuming supabase is initialized here

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  _ProductManagementPageState createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController imageController = TextEditingController();
  TextEditingController offerPriceController = TextEditingController();
  TextEditingController barcodeController = TextEditingController();
  TextEditingController stockQuantityController = TextEditingController();
  TextEditingController maxQuantityController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  TextEditingController minStockController = TextEditingController();
  TextEditingController maxStockController = TextEditingController();

  String? selectedCategoryName;
  int? selectedCategoryId;
  String? selectedFilterCategory;
  String? selectedFilterStatus;
  String? selectedOfferFilter;
  List<Map<String, dynamic>> categories = [];
  List<String> statuses = ['all', 'active', 'inactive'];
  List<String> offerFilters = ['all', 'with_offers', 'without_offers'];

  bool isLoading = false;
  bool isActionLoading = false;
  String sortBy = 'name';
  bool sortAscending = true;
  int limit = 20;
  int offset = 0;
  bool hasMore = true;
  double uploadProgress = 0.0;
  double downloadProgress = 0.0;
  final ScrollController _scrollController = ScrollController();

  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCategories();
      _fetchAllProducts();
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && hasMore) {
          _fetchAllProducts();
        }
      });
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await supabase.from('market_categories').select('id, name');
      if (mounted) {
        setState(() {
          categories = response.map((cat) => {'id': cat['id'], 'name': cat['name'] as String}).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في جلب الفئات: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchAllProducts() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('products')
          .select('id, name, price, image, offer_price, barcode, category_id, status, stock_quantity, max_quantity, description, market_categories!inner(name)')
          .range(offset, offset + limit - 1);

      List<Map<String, dynamic>> newProducts = response.map((product) {
        return {
          'id': product['id'],
          'name': product['name'],
          'price': product['price'].toString(),
          'image': product['image'] ?? '',
          'offerPrice': product['offer_price']?.toString(),
          'barcode': product['barcode'] ?? '',
          'category_id': product['category_id'],
          'category_name': product['market_categories']?['name'] ?? 'غير مصنف',
          'status': product['status'] ?? 'active',
          'stockQuantity': product['stock_quantity'] ?? 0,
          'maxQuantity': product['max_quantity'] ?? 0,
          'description': product['description'] ?? '',
        };
      }).toList();

      setState(() {
        products.addAll(newProducts);
        offset += limit;
        hasMore = newProducts.length == limit;
        isLoading = false;
        _filterProducts();
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في جلب المنتجات: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts() {
    String searchTerm = searchController.text.toLowerCase();
    String? categoryFilter = selectedFilterCategory;
    String? statusFilter = selectedFilterStatus == 'all' ? null : selectedFilterStatus;
    String? offerFilter = selectedOfferFilter;
    double? minPrice = double.tryParse(minPriceController.text);
    double? maxPrice = double.tryParse(maxPriceController.text);
    int? minStock = int.tryParse(minStockController.text);
    int? maxStock = int.tryParse(maxStockController.text);

    setState(() {
      filteredProducts = products.where((product) {
        bool matchesSearch = searchTerm.isEmpty ||
            product['name'].toLowerCase().contains(searchTerm) ||
            product['barcode'].toLowerCase().contains(searchTerm);
        bool matchesCategory = categoryFilter == null || product['category_name'] == categoryFilter;
        bool matchesStatus = statusFilter == null || product['status'] == statusFilter;
        bool matchesOffer = offerFilter == null || offerFilter == 'all'
            ? true
            : offerFilter == 'with_offers'
            ? product['offerPrice'] != null
            : product['offerPrice'] == null;
        bool matchesPrice = (minPrice == null || double.parse(product['price']) >= minPrice) &&
            (maxPrice == null || double.parse(product['price']) <= maxPrice);
        bool matchesStock = (minStock == null || product['stockQuantity'] >= minStock) &&
            (maxStock == null || product['stockQuantity'] <= maxStock);
        return matchesSearch && matchesCategory && matchesStatus && matchesOffer && matchesPrice && matchesStock;
      }).toList();
      _sortProducts();
    });
  }

  void _sortProducts() {
    filteredProducts.sort((a, b) {
      if (sortBy == 'price') {
        return sortAscending
            ? double.parse(a['price']).compareTo(double.parse(b['price']))
            : double.parse(b['price']).compareTo(double.parse(a['price']));
      } else if (sortBy == 'stock') {
        return sortAscending
            ? a['stockQuantity'].compareTo(b['stockQuantity'])
            : b['stockQuantity'].compareTo(a['stockQuantity']);
      }
      return sortAscending ? a['name'].compareTo(b['name']) : b['name'].compareTo(a['name']);
    });
  }

  void showAddEditSheet([int? index]) {
    final product = index != null ? filteredProducts[index] : null;

    if (product != null) {
      nameController.text = product['name'];
      priceController.text = product['price'];
      imageController.text = product['image'];
      offerPriceController.text = product['offerPrice'] ?? '';
      barcodeController.text = product['barcode'] ?? '';
      stockQuantityController.text = product['stockQuantity'].toString();
      maxQuantityController.text = product['maxQuantity'].toString();
      descriptionController.text = product['description'] ?? '';
      selectedCategoryName = product['category_name'];
      selectedCategoryId = product['category_id'];
    } else {
      nameController.clear();
      priceController.clear();
      imageController.clear();
      offerPriceController.clear();
      barcodeController.clear();
      stockQuantityController.clear();
      maxQuantityController.clear();
      descriptionController.clear();
      selectedCategoryName = null;
      selectedCategoryId = null;
    }

    final isDesktop = MediaQuery.of(context).size.width > 1200;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(20),
            child: _buildAddEditForm(index),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: _buildAddEditForm(index),
        ),
      );
    }
  }

  Widget _buildAddEditForm(int? index) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index == null ? 'إضافة منتج جديد' : 'تعديل المنتج',
            style: GoogleFonts.cairo(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: Colors.teal[800]),
          ),
          const SizedBox(height: 20),
          _buildTextField(nameController, 'اسم المنتج', required: true),
          const SizedBox(height: 16),
          _buildTextField(priceController, 'السعر', keyboardType: TextInputType.numberWithOptions(decimal: true), required: true, englishNumbersOnly: true),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTextField(imageController, 'رابط الصورة')),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    setState(() => isActionLoading = true);
                    final result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null) {
                      final fileBytes = result.files.single.bytes;
                      final fileName = result.files.single.name;
                      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
                      var request = http.MultipartRequest('POST', uri)
                        ..fields['name'] = fileName
                        ..files.add(http.MultipartFile.fromBytes('image', fileBytes!, filename: fileName));
                      final response = await request.send();
                      final responseData = await response.stream.bytesToString();
                      final jsonData = jsonDecode(responseData);
                      if (jsonData['success']) {
                        imageController.text = jsonData['data']['url'];
                      }
                    }
                    setState(() => isActionLoading = false);
                  } catch (e) {
                    setState(() => isActionLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في رفع الصورة: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: _buttonStyle(),
                child: Text('رفع صورة', style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(offerPriceController, 'سعر العرض (اختياري)', keyboardType: TextInputType.numberWithOptions(decimal: true), englishNumbersOnly: true),
          const SizedBox(height: 16),
          _buildTextField(barcodeController, 'باركود المنتج', keyboardType: TextInputType.number, required: true, englishNumbersOnly: true),
          const SizedBox(height: 16),
          _buildTextField(stockQuantityController, 'كمية المخزون', keyboardType: TextInputType.number, englishNumbersOnly: true),
          const SizedBox(height: 16),
          _buildTextField(maxQuantityController, 'الحد الأقصى', keyboardType: TextInputType.number, required: true, englishNumbersOnly: true),
          const SizedBox(height: 16),
          _buildTextField(descriptionController, 'الوصف', maxLines: 3),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCategoryName,
            items: categories.map((category) {
              return DropdownMenuItem<String>(
                value: category['name'] as String,
                child: Text(category['name'] as String, style: GoogleFonts.cairo()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategoryName = value;
                selectedCategoryId = categories.firstWhere((cat) => cat['name'] == value)['id'] as int;
              });
            },
            decoration: _inputDecoration('الفئة'),
            style: GoogleFonts.cairo(),
            validator: (value) => value == null ? 'الفئة مطلوبة' : null,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isActionLoading
                    ? null
                    : () {
                  if (_validateForm()) {
                    if (index == null) {
                      _addItem();
                    } else {
                      _editItem(index);
                    }
                    Navigator.pop(context);
                  }
                },
                style: _buttonStyle(),
                child: isActionLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(index == null ? 'إضافة' : 'حفظ', style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('اسم المنتج مطلوب', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (priceController.text.isEmpty || !_isEnglishNumberWithDecimal(priceController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('السعر مطلوب ويجب أن يكون أرقامًا إنجليزية (مثل 10.50)', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (offerPriceController.text.isNotEmpty && !_isEnglishNumberWithDecimal(offerPriceController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سعر العرض يجب أن يكون أرقامًا إنجليزية (مثل 5.99)', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (barcodeController.text.isEmpty || !_isEnglishNumber(barcodeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('باركود المنتج مطلوب ويجب أن يكون أرقامًا إنجليزية فقط', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (stockQuantityController.text.isNotEmpty && !_isEnglishNumber(stockQuantityController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('كمية المخزون يجب أن تكون أرقامًا إنجليزية فقط', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (maxQuantityController.text.isEmpty || !_isEnglishNumber(maxQuantityController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الحد الأقصى مطلوب ويجب أن يكون أرقامًا إنجليزية فقط', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الفئة مطلوبة', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  bool _isEnglishNumber(String text) {
    return RegExp(r'^[0-9]+$').hasMatch(text);
  }

  bool _isEnglishNumberWithDecimal(String text) {
    return RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(text);
  }

  void _addItem() async {
    setState(() => isActionLoading = true);
    try {
      final newProduct = await supabase.from('products').insert({
        "name": nameController.text,
        "price": double.parse(priceController.text),
        "image": imageController.text,
        "offer_price": offerPriceController.text.isEmpty ? null : double.parse(offerPriceController.text),
        "barcode": barcodeController.text,
        "category_id": selectedCategoryId,
        "status": 'active',
        "stock_quantity": stockQuantityController.text.isEmpty ? 0 : int.parse(stockQuantityController.text),
        "max_quantity": int.parse(maxQuantityController.text),
        "description": descriptionController.text,
      }).select('*, market_categories!inner(name)').single();

      setState(() {
        products.add({
          "id": newProduct['id'],
          "name": nameController.text,
          "price": priceController.text,
          "image": imageController.text,
          "offerPrice": offerPriceController.text.isEmpty ? null : offerPriceController.text,
          "barcode": barcodeController.text,
          "category_id": selectedCategoryId,
          "category_name": newProduct['market_categories']['name'],
          "status": 'active',
          "stockQuantity": stockQuantityController.text.isEmpty ? 0 : int.parse(stockQuantityController.text),
          "maxQuantity": int.parse(maxQuantityController.text),
          "description": descriptionController.text,
        });
        _filterProducts();
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة المنتج بنجاح', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إضافة المنتج: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editItem(int index) async {
    setState(() => isActionLoading = true);
    try {
      await supabase.from('products').update({
        "name": nameController.text,
        "price": double.parse(priceController.text),
        "image": imageController.text,
        "offer_price": offerPriceController.text.isEmpty ? null : double.parse(offerPriceController.text),
        "barcode": barcodeController.text,
        "category_id": selectedCategoryId,
        "stock_quantity": stockQuantityController.text.isEmpty ? 0 : int.parse(stockQuantityController.text),
        "max_quantity": int.parse(maxQuantityController.text),
        "description": descriptionController.text,
      }).eq('id', filteredProducts[index]['id']);

      setState(() {
        final productId = filteredProducts[index]['id'];
        final productIndexInProducts = products.indexWhere((p) => p['id'] == productId);
        if (productIndexInProducts != -1) {
          products[productIndexInProducts] = {
            "id": productId,
            "name": nameController.text,
            "price": priceController.text,
            "image": imageController.text,
            "offerPrice": offerPriceController.text.isEmpty ? null : offerPriceController.text,
            "barcode": barcodeController.text,
            "category_id": selectedCategoryId,
            "category_name": selectedCategoryName,
            "status": products[productIndexInProducts]['status'],
            "stockQuantity": stockQuantityController.text.isEmpty ? 0 : int.parse(stockQuantityController.text),
            "maxQuantity": int.parse(maxQuantityController.text),
            "description": descriptionController.text,
          };
          _filterProducts();
        }
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث المنتج بنجاح', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث المنتج: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteItem(int index) async {
    setState(() => isActionLoading = true);
    try {
      await supabase.from('products').delete().eq('id', filteredProducts[index]['id']);
      setState(() {
        products.removeWhere((p) => p['id'] == filteredProducts[index]['id']);
        _filterProducts();
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف المنتج بنجاح', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف المنتج: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleStatus(int index) async {
    setState(() => isActionLoading = true);
    String newStatus = filteredProducts[index]['status'] == 'active' ? 'inactive' : 'active';
    try {
      await supabase.from('products').update({"status": newStatus}).eq('id', filteredProducts[index]['id']);
      setState(() {
        final productId = filteredProducts[index]['id'];
        final productIndexInProducts = products.indexWhere((p) => p['id'] == productId);
        if (productIndexInProducts != -1) {
          products[productIndexInProducts]['status'] = newStatus;
          _filterProducts();
        }
        isActionLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث الحالة إلى $newStatus', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() => isActionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الحالة: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> uploadBulkProducts() async {
    try {
      setState(() => uploadProgress = 0.0);
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (result == null) return;

      var fileBytes = result.files.single.bytes;
      var file = Excel.decodeBytes(fileBytes!);
      final existingProducts = await supabase.from('products').select();
      setState(() => isActionLoading = true);

      int totalRows = file.tables.values.first.rows.length - 1;
      int processedRows = 0;

      for (var table in file.tables.keys) {
        for (int rowIndex = 0; rowIndex < file.tables[table]!.rows.length; rowIndex++) {
          if (rowIndex == 0) continue;
          var row = file.tables[table]!.rows[rowIndex];

          processedRows++;
          setState(() => uploadProgress = processedRows / totalRows);

          if (row.isNotEmpty) {
            String? name = row[0]?.value?.toString();
            String? price = row[1]?.value?.toString();
            String? image = row[2]?.value?.toString();
            String? offerPrice = row[3]?.value?.toString();
            String? barcode = row[4]?.value?.toString();
            String? categoryName = row[5]?.value?.toString();
            String? status = row[6]?.value?.toString();
            String? stockQuantity = row[7]?.value?.toString();
            String? maxQuantity = row[8]?.value?.toString();
            String? description = row[9]?.value?.toString();

            if (name != null && price != null && image != null && categoryName != null && barcode != null && maxQuantity != null) {
              if (!_isEnglishNumberWithDecimal(price) ||
                  !_isEnglishNumber(barcode) ||
                  !_isEnglishNumber(maxQuantity) ||
                  (offerPrice != null && !_isEnglishNumberWithDecimal(offerPrice)) ||
                  (stockQuantity != null && !_isEnglishNumber(stockQuantity))) {
                continue;
              }

              final category = categories.firstWhere(
                    (cat) => cat['name'] == categoryName,
                orElse: () => <String, dynamic>{},
              );
              if (category.isEmpty) continue;
              int categoryId = category['id'];

              final existingProduct = existingProducts.firstWhere(
                    (p) => p['barcode'] == barcode,
                orElse: () => <String, dynamic>{},
              );

              if (existingProduct.isNotEmpty) {
                await supabase.from('products').update({
                  "name": name,
                  "price": double.parse(price),
                  "image": image,
                  "offer_price": offerPrice != null ? double.parse(offerPrice) : null,
                  "category_id": categoryId,
                  "status": status ?? 'active',
                  "stock_quantity": stockQuantity != null ? int.parse(stockQuantity) : 0,
                  "max_quantity": int.parse(maxQuantity),
                  "description": description ?? '',
                }).eq('id', existingProduct['id']);
              } else {
                await supabase.from('products').insert({
                  "name": name,
                  "price": double.parse(price),
                  "image": image,
                  "offer_price": offerPrice != null ? double.parse(offerPrice) : null,
                  "barcode": barcode,
                  "category_id": categoryId,
                  "status": status ?? 'active',
                  "stock_quantity": stockQuantity != null ? int.parse(stockQuantity) : 0,
                  "max_quantity": int.parse(maxQuantity),
                  "description": description ?? '',
                });
              }
            }
          }
        }
      }

      setState(() {
        isActionLoading = false;
        uploadProgress = 0.0;
      });
      products.clear();
      offset = 0;
      hasMore = true;
      await _fetchAllProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفع المنتجات بنجاح', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      setState(() {
        isActionLoading = false;
        uploadProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع المنتجات: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> downloadAllProducts() async {
    try {
      setState(() {
        isActionLoading = true;
        downloadProgress = 0.0;
      });
      var excel = Excel.createExcel();
      var sheet = excel['Products'];

      sheet.appendRow([
        TextCellValue('الاسم'),
        TextCellValue('السعر'),
        TextCellValue('رابط الصورة'),
        TextCellValue('سعر العرض'),
        TextCellValue('الباركود'),
        TextCellValue('الفئة'),
        TextCellValue('الحالة'),
        TextCellValue('كمية المخزون'),
        TextCellValue('الحد الأقصى'),
        TextCellValue('الوصف'),
      ]);

      for (var i = 0; i < products.length; i++) {
        var product = products[i];
        sheet.appendRow([
          TextCellValue(product['name']),
          TextCellValue(double.parse(product['price']).toStringAsFixed(2)),
          TextCellValue(product['image']),
          TextCellValue(product['offerPrice'] != null ? double.parse(product['offerPrice']).toStringAsFixed(2) : 'غير متوفر'),
          TextCellValue(product['barcode'] ?? 'غير متوفر'),
          TextCellValue(product['category_name']),
          TextCellValue(product['status']),
          TextCellValue(product['stockQuantity'].toString()),
          TextCellValue(product['maxQuantity'].toString()),
          TextCellValue(product['description'] ?? ''),
        ]);
        setState(() => downloadProgress = (i + 1) / products.length);
      }

      var excelBytes = excel.encode();
      if (excelBytes != null) {
        if (kIsWeb) {
          downloadExcelWeb(excelBytes);
        } else {
          await downloadExcelMobile(excelBytes);
        }
        setState(() {
          isActionLoading = false;
          downloadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحميل المنتجات بنجاح', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isActionLoading = false;
        downloadProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل المنتجات: $e', style: GoogleFonts.cairo(fontSize: 14, color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة المنتجات',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
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
              // Inside ProductManagementPage's build method
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
                        leading: const Icon(Icons.inventory_2, color: Colors.teal),
                        title: Text('المنتجات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
                        onTap: () {},
                        selected: true,
                        selectedTileColor: Colors.teal.withOpacity(0.1),
                      ),
                      ListTile(
                        leading: const Icon(Icons.category, color: Colors.teal),
                        title: Text('الفئات', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[800])),
                        onTap: () => Navigator.pushNamed(context, '/categories'),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: searchController,
                            decoration: _inputDecoration('ابحث عن منتج...').copyWith(
                              prefixIcon: const Icon(Icons.search, color: Colors.teal),
                            ),
                            onChanged: (_) => _filterProducts(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFilterDropdown(
                                hint: 'الفئة',
                                value: selectedFilterCategory,
                                items: categories.map((cat) => cat['name'] as String).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedFilterCategory = value;
                                    _filterProducts();
                                  });
                                },
                                width: 100,
                              ),
                              _buildFilterDropdown(
                                hint: 'الحالة',
                                value: selectedFilterStatus,
                                items: statuses,
                                onChanged: (value) {
                                  setState(() {
                                    selectedFilterStatus = value;
                                    _filterProducts();
                                  });
                                },
                                width: 100,
                                itemBuilder: (item) => Text(
                                  item == 'all' ? 'الكل' : item == 'active' ? 'نشط' : 'غير نشط',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                              _buildFilterDropdown(
                                hint: 'العروض',
                                value: selectedOfferFilter,
                                items: offerFilters,
                                onChanged: (value) {
                                  setState(() {
                                    selectedOfferFilter = value;
                                    _filterProducts();
                                  });
                                },
                                width: 100,
                                itemBuilder: (item) => Text(
                                  item == 'all' ? 'الكل' : item == 'with_offers' ? 'مع عروض' : 'بدون عروض',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: Text('بحث متقدم', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[800])),
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(minPriceController, 'السعر الأدنى', keyboardType: TextInputType.numberWithOptions(decimal: true))),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildTextField(maxPriceController, 'السعر الأعلى', keyboardType: TextInputType.numberWithOptions(decimal: true))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(minStockController, 'المخزون الأدنى', keyboardType: TextInputType.number)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildTextField(maxStockController, 'المخزون الأعلى', keyboardType: TextInputType.number)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _filterProducts,
                                style: _buttonStyle(),
                                child: Text('تطبيق البحث', style: GoogleFonts.cairo(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: _inputDecoration('ابحث عن منتج...').copyWith(
                                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                                  ),
                                  onChanged: (_) => _filterProducts(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildFilterDropdown(
                                hint: 'الفئة',
                                value: selectedFilterCategory,
                                items: categories.map((cat) => cat['name'] as String).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedFilterCategory = value;
                                    _filterProducts();
                                  });
                                },
                                width: 200,
                              ),
                              const SizedBox(width: 16),
                              _buildFilterDropdown(
                                hint: 'الحالة',
                                value: selectedFilterStatus,
                                items: statuses,
                                onChanged: (value) {
                                  setState(() {
                                    selectedFilterStatus = value;
                                    _filterProducts();
                                  });
                                },
                                width: 200,
                                itemBuilder: (item) => Text(
                                  item == 'all' ? 'الكل' : item == 'active' ? 'نشط' : 'غير نشط',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildFilterDropdown(
                                hint: 'العروض',
                                value: selectedOfferFilter,
                                items: offerFilters,
                                onChanged: (value) {
                                  setState(() {
                                    selectedOfferFilter = value;
                                    _filterProducts();
                                  });
                                },
                                width: 200,
                                itemBuilder: (item) => Text(
                                  item == 'all' ? 'الكل' : item == 'with_offers' ? 'مع عروض' : 'بدون عروض',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: Text('بحث متقدم', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[800])),
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(minPriceController, 'السعر الأدنى', keyboardType: TextInputType.numberWithOptions(decimal: true))),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildTextField(maxPriceController, 'السعر الأعلى', keyboardType: TextInputType.numberWithOptions(decimal: true))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: _buildTextField(minStockController, 'المخزون الأدنى', keyboardType: TextInputType.number)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildTextField(maxStockController, 'المخزون الأعلى', keyboardType: TextInputType.number)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _filterProducts,
                                style: _buttonStyle(),
                                child: Text('تطبيق البحث', style: GoogleFonts.cairo(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: isMobile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => showAddEditSheet(),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text('إضافة منتج', style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
                                style: _buttonStyle(),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: uploadBulkProducts,
                                icon: const Icon(Icons.upload, color: Colors.white),
                                label: Text('رفع دفعة', style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
                                style: _buttonStyle(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                onPressed: downloadAllProducts,
                                icon: const Icon(Icons.download, color: Colors.teal),
                                label: Text('تحميل الكل', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[600])),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.teal[600]!),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildSortButton('السعر', 'price'),
                                  const SizedBox(width: 10),
                                  _buildSortButton('المخزون', 'stock'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => showAddEditSheet(),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text('إضافة منتج', style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
                                style: _buttonStyle(),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: uploadBulkProducts,
                                icon: const Icon(Icons.upload, color: Colors.white),
                                label: Text('رفع دفعة', style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
                                style: _buttonStyle(),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: downloadAllProducts,
                                icon: const Icon(Icons.download, color: Colors.teal),
                                label: Text('تحميل الكل', style: GoogleFonts.cairo(fontSize: 16, color: Colors.teal[600])),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.teal[600]!),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildSortButton('السعر', 'price'),
                              const SizedBox(width: 10),
                              _buildSortButton('المخزون', 'stock'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (uploadProgress > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: uploadProgress, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation(Colors.teal[600])),
                            const SizedBox(height: 8),
                            Text('جاري الرفع: ${(uploadProgress * 100).toStringAsFixed(0)}%', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                    if (downloadProgress > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: downloadProgress, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation(Colors.teal[600])),
                            const SizedBox(height: 8),
                            Text('جاري التحميل: ${(downloadProgress * 100).toStringAsFixed(0)}%', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                    Expanded(
                      child: isLoading && products.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                          : filteredProducts.isEmpty
                          ? Center(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          child: Text('لا توجد منتجات', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600])),
                        ),
                      )
                          : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : isTablet ? 2 : 1,
                          childAspectRatio: isDesktop ? 1.5 : isTablet ? 1.8 : 2.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredProducts.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredProducts.length) {
                            return const Center(child: CircularProgressIndicator(color: Colors.teal));
                          }
                          return _buildProductCard(index, isMobile);
                        },
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

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double width,
    Widget Function(String)? itemBuilder,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          hint: Text(hint, style: GoogleFonts.cairo()),
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: itemBuilder != null ? itemBuilder(item) : Text(item, style: GoogleFonts.cairo()),
          ))
              .toList(),
          onChanged: onChanged,
          buttonStyleData: ButtonStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
          dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))),
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String sortKey) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          sortBy = sortKey;
          sortAscending = !sortAscending;
          _sortProducts();
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.teal[600]!),
      ),
      child: Text(label, style: GoogleFonts.cairo(fontSize: 14, color: Colors.teal[600])),
    );
  }

  Widget _buildProductCard(int index, bool isMobile) {
    final product = filteredProducts[index];
    final numberFormat = intl.NumberFormat.decimalPattern('ar');
    final isHovered = ValueNotifier<bool>(false);

    return ValueListenableBuilder<bool>(
      valueListenable: isHovered,
      builder: (context, hovered, child) {
        return MouseRegion(
          onEnter: (_) => isHovered.value = true,
          onExit: (_) => isHovered.value = false,
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Slidable(
              key: ValueKey(product['id']),
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => showAddEditSheet(index),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'تعديل',
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => _deleteItem(index),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'حذف',
                  ),
                ],
              ),
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
                  onTap: () => showAddEditSheet(index),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            product['image'],
                            width: isMobile ? 60 : 80,
                            height: isMobile ? 60 : 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: isMobile ? 60 : 80, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'السعر: ${numberFormat.format(double.parse(product['price']))}',
                                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                              ),
                              Text(
                                'سعر العرض: ${product['offerPrice'] != null ? numberFormat.format(double.parse(product['offerPrice'])) : 'غير متوفر'}',
                                style: GoogleFonts.cairo(fontSize: 14, color: product['offerPrice'] != null ? Colors.white : Colors.white70),
                              ),
                              Text(
                                'المخزون: ${product['stockQuantity']}',
                                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                              ),
                              Text(
                                'الحد الأقصى: ${product['maxQuantity']}',
                                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                              ),
                              Text(
                                'الفئة: ${product['category_name']}',
                                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => showAddEditSheet(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteItem(index),
                            ),
                            IconButton(
                              icon: Icon(
                                product['status'] == 'active' ? Icons.check_circle : Icons.remove_circle,
                                color: product['status'] == 'active' ? Colors.white : Colors.redAccent,
                              ),
                              onPressed: () => _toggleStatus(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType? keyboardType,
        int maxLines = 1,
        bool required = false,
        bool englishNumbersOnly = false,
      }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label).copyWith(
        hintText: required ? '$label (مطلوب)' : label,
      ),
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(),
      maxLines: maxLines,
      inputFormatters: englishNumbersOnly
          ? keyboardType == TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))]
          : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.teal[600],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.teal.withOpacity(0.3),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    nameController.dispose();
    priceController.dispose();
    imageController.dispose();
    offerPriceController.dispose();
    barcodeController.dispose();
    stockQuantityController.dispose();
    maxQuantityController.dispose();
    descriptionController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    minStockController.dispose();
    maxStockController.dispose();
    super.dispose();
  }
}
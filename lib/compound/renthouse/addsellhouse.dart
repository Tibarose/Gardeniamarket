import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

import '../../main.dart';
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';
import 'SellApartmentsPage.dart';

class AddHouseForSalePageArabic extends StatefulWidget {
  const AddHouseForSalePageArabic({super.key});

  @override
  _AddHouseForSalePageArabicState createState() => _AddHouseForSalePageArabicState();
}

class _AddHouseForSalePageArabicState extends State<AddHouseForSalePageArabic> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isImageUploading = false;

  final List<String> _amenitiesOptions = [
    'حديقة خاصة',
    'عداد كهرباء',
    'عداد مياه',
    'غاز طبيعي',
    'تليفون أرضي',
    'اسانسير',
    'انترنت منزلي',
  ];

  final List<String> _selectedAmenities = [];

  // Text editing controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _spaceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _installmentAmountController = TextEditingController();
  final TextEditingController _installmentPeriodController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown selections
  String? _selectedZone;
  String? _selectedRoom;
  String? _bathroom;
  String? _floor;
  String? _furnished;
  String? _installmentFrequency;
  String? _presenter;
  String? _contact;

  // Image data
  List<Uint8List?> _imageBytes = [null, null, null, null];
  List<String> _imageUrls = ['', '', '', ''];

  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  // Image picker and upload
  Future<void> _uploadImage(int index) async {
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
            _imageUrls[index] = jsonData['data']['url'];
            _imageBytes[index] = fileBytes;
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

  // Show success dialog
  void _showSuccessDialog(Function callback) {
    showDialog(
      context: context,
      builder: (context) => FadeIn(
        duration: ThemeManager.animationDuration,
        child: AlertDialog(
          backgroundColor: ThemeManager().currentTheme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'تم تقديم الطلب',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ThemeManager().currentTheme.textColor,
              ),
            ),
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'تم تقديم الطلب بنجاح وجاري مراجعة الطلب والتواصل معكم لإتمام الإجراءات',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: ThemeManager().currentTheme.secondaryTextColor,
              ),
            ),
          ),
          actions: <Widget>[
            Directionality(
              textDirection: TextDirection.rtl,
              child: TextButton(
                child: Text(
                  'موافق',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager().currentTheme.primaryColor,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  callback();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show snackbar
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: isError ? Colors.redAccent : ThemeManager().currentTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_isSubmitting) return;

      // Check if at least one image is uploaded
      if (!_imageUrls.any((url) => url.isNotEmpty)) {
        _showSnackBar('يرجى رفع صورة واحدة على الأقل');
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      // Filter out empty URLs
      final filteredImageUrls = _imageUrls.where((url) => url.isNotEmpty).toList();

      // Collecting house data
      Map<String, dynamic> houseData = {
        'phone': _phoneController.text,
        'space': _spaceController.text.isNotEmpty ? int.parse(_spaceController.text) : null,
        'price': int.parse(_priceController.text.replaceAll(',', '')),
        'down_payment': _downPaymentController.text.isNotEmpty
            ? int.parse(_downPaymentController.text.replaceAll(',', ''))
            : null,
        'installment_amount': _installmentAmountController.text.isNotEmpty
            ? int.parse(_installmentAmountController.text.replaceAll(',', ''))
            : null,
        'installment_period': _installmentPeriodController.text.isNotEmpty
            ? _installmentPeriodController.text
            : null,
        'installment_frequency': _installmentFrequency,
        'zone': _selectedZone,
        'room': _selectedRoom != null ? int.parse(_selectedRoom!) : null,
        'bathroom': _bathroom != null ? int.parse(_bathroom!) : null,
        'floor': _floor,
        'furnished': _furnished,
        'amenities': _selectedAmenities,
        'images': filteredImageUrls,
        'presenter': _presenter,
        'contact': _contact,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'status': 'Pending',
        'expiry_date': intl.DateFormat('d/M/yyyy').format(DateTime.now().add(const Duration(days: 30))),
      };

      try {
        final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
        await supabaseConfig.secondaryClient.from('apartments_for_sale').insert(houseData);

        _showSuccessDialog(() {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SellApartmentsPage()),
          );
        });

        // Clear form after submission
        _formKey.currentState!.reset();
        setState(() {
          _imageBytes = [null, null, null, null];
          _imageUrls = ['', '', '', ''];
          _selectedAmenities.clear();
          _isSubmitting = false;
          _selectedZone = null;
          _selectedRoom = null;
          _bathroom = null;
          _floor = null;
          _furnished = null;
          _installmentFrequency = null;
          _presenter = null;
          _contact = null;
          _phoneController.clear();
          _spaceController.clear();
          _priceController.clear();
          _downPaymentController.clear();
          _installmentAmountController.clear();
          _installmentPeriodController.clear();
          _notesController.clear();
        });
      } catch (e) {
        _showSnackBar('فشل إضافة الشقة: $e');
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: isMobile ? 150 : 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: theme.appBarGradient,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElasticIn(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              'إضافة شقة للبيع',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 28 : 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInDown(
                            duration: ThemeManager.animationDuration,
                            child: Text(
                              'قم بإدخال تفاصيل الشقة بدقة',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 16 : 18,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: FadeInLeft(
                  duration: ThemeManager.animationDuration,
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'رجوع',
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(ThemeManager.cardPadding),
                sliver: SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          child: Text(
                            'تفاصيل الشقة',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: theme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Image Upload Section
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 100),
                          child: _buildImageUploadSection(isMobile, theme),
                        ),
                        const SizedBox(height: 20),
                        // Basic Details
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 200),
                          child: _buildTextInputField(
                            controller: _spaceController,
                            label: 'المساحة (م²) *',
                            hint: 'أدخل المساحة (متر مربع)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 300),
                          child: _buildTextInputField(
                            controller: _phoneController,
                            label: 'رقم الهاتف *',
                            hint: 'أدخل رقم الهاتف',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 400),
                          child: _buildDropdownField(
                            label: 'الزوون *',
                            value: _selectedZone,
                            items: List.generate(11, (index) => (index + 1).toString()),
                            onChanged: (value) => setState(() => _selectedZone = value),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 500),
                          child: _buildDropdownField(
                            label: 'غرف النوم',
                            value: _selectedRoom,
                            items: List.generate(3, (index) => (index + 1).toString()),
                            onChanged: (value) => setState(() => _selectedRoom = value),
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 600),
                          child: _buildDropdownField(
                            label: 'عدد الحمامات',
                            value: _bathroom,
                            items: List.generate(2, (index) => (index + 1).toString()),
                            onChanged: (value) => setState(() => _bathroom = value),
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 700),
                          child: _buildDropdownField(
                            label: 'الدور',
                            value: _floor,
                            items: ['الأرضي', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس'],
                            onChanged: (value) => setState(() => _floor = value),
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 800),
                          child: _buildDropdownField(
                            label: 'مفروشة؟',
                            value: _furnished,
                            items: ['نعم', 'لا'],
                            onChanged: (value) => setState(() => _furnished = value),
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Amenities
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 900),
                          child: _buildMultiSelectionField(theme),
                        ),
                        const SizedBox(height: 20),
                        // Pricing Details
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1000),
                          child: _buildTextInputField(
                            controller: _priceController,
                            label: 'سعر الشقة *',
                            hint: 'أدخل سعر الشقة (جم)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1100),
                          child: _buildTextInputField(
                            controller: _downPaymentController,
                            label: 'المقدم',
                            hint: 'أدخل مبلغ المقدم (جم)',
                            keyboardType: TextInputType.number,
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1200),
                          child: _buildTextInputField(
                            controller: _installmentAmountController,
                            label: 'مبلغ القسط',
                            hint: 'أدخل مبلغ القسط (جم)',
                            keyboardType: TextInputType.number,
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1300),
                          child: _buildTextInputField(
                            controller: _installmentPeriodController,
                            label: 'مدة التقسيط',
                            hint: 'أدخل مدة التقسيط (مثال: سنة، سنتين)',
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1400),
                          child: _buildDropdownField(
                            label: 'تكرار دفع القسط',
                            value: _installmentFrequency,
                            items: ['شهريًا', 'ربع سنويًا', 'نصف سنويًا', 'سنويًا', 'لا يوجد تقسيط'],
                            onChanged: (value) => setState(() => _installmentFrequency = value),
                            isMandatory: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1500),
                          child: _buildDropdownField(
                            label: 'المعلن *',
                            value: _presenter,
                            items: ['مالك الشقة', 'شركة عقارية'],
                            onChanged: (value) => setState(() => _presenter = value),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1600),
                          child: _buildDropdownField(
                            label: 'تفضل التواصل من خلال *',
                            value: _contact,
                            items: ['المشتري مباشرة فقط', 'المشتري أو سماسرة'],
                            onChanged: (value) => setState(() => _contact = value),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Notes
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1700),
                          child: _buildTextInputField(
                            controller: _notesController,
                            label: 'ملاحظات',
                            hint: 'أدخل ملاحظات إضافية',
                            isMandatory: false,
                            minLines: 3,
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Submit Button
                        FadeInUp(
                          duration: ThemeManager.animationDuration,
                          delay: const Duration(milliseconds: 1800),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _isSubmitting
                                  ? CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              )
                                  : Text(
                                'إضافة الشقة',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build image upload section
  Widget _buildImageUploadSection(bool isMobile, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صور الشقة (اختر صورة واحدة على الأقل) *',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_imageBytes.length, (index) {
            return GestureDetector(
              onTap: _isImageUploading ? null : () => _uploadImage(index),
              child: Container(
                width: isMobile ? 80 : 100,
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
                child: _imageUrls[index].isEmpty
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
                      'إضافة',
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
                    _imageUrls[index],
                    fit: BoxFit.cover,
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Build text input field
  Widget _buildTextInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isMandatory = true,
    int minLines = 1,
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = ThemeManager().currentTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
          hintStyle: GoogleFonts.cairo(
            fontSize: 14,
            color: theme.secondaryTextColor.withOpacity(0.6),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: theme.cardBackground,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: theme.textColor,
        ),
        validator: (value) {
          if (isMandatory && (value == null || value.isEmpty)) {
            return '$label مطلوب';
          }
          if (keyboardType == TextInputType.number && value != null && value.isNotEmpty) {
            if (int.tryParse(value.replaceAll(',', '')) == null) {
              return 'يرجى إدخال رقم صحيح';
            }
          }
          return null;
        },
      ),
    );
  }

  // Build dropdown field
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isMandatory = true,
  }) {
    final theme = ThemeManager().currentTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: theme.cardBackground,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textColor,
            ),
          ),
        ))
            .toList(),
        onChanged: onChanged,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: theme.textColor,
        ),
        icon: FaIcon(
          FontAwesomeIcons.arrowDown,
          color: theme.primaryColor,
          size: 16,
        ),
        validator: (value) {
          if (isMandatory && value == null) {
            return '$label مطلوب';
          }
          return null;
        },
      ),
    );
  }

  // Build multi-selection field
  Widget _buildMultiSelectionField(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الملحقات والمرافق',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _amenitiesOptions.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return ChoiceChip(
              label: Text(
                amenity,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : theme.textColor,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.primaryColor,
              backgroundColor: theme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
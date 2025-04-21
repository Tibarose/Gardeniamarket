import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _buildingController;
  late TextEditingController _apartmentController;
  int? _selectedCompoundId;
  String? _mobileNumber;
  bool _isLoading = true;
  bool _isFetchingCompounds = true;
  Map<String, dynamic>? _userDetails;
  List<Map<String, dynamic>> _compounds = [];

  static const Color awesomeColor = Color(0xFF6A1B9A);
  static const Color gradientStart = Color(0xFF6A1B9A);
  static const Color gradientEnd = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _buildingController = TextEditingController();
    _apartmentController = TextEditingController();
    _loadUserData();
    _fetchCompounds();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تسجيل الدخول أولاً',
            style: GoogleFonts.cairo(),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDetails = await authProvider.getUserDetails();
      if (userDetails != null) {
        setState(() {
          _userDetails = userDetails;
          _mobileNumber = userDetails['mobile_number'] as String?;
          _nameController.text = userDetails['name'] as String? ?? '';
          _buildingController.text = userDetails['building_number'] as String? ?? '';
          _apartmentController.text = userDetails['apartment_number'] as String? ?? '';
          _selectedCompoundId = userDetails['compound_id'] as int?;
          _isLoading = false;
        });
      } else {
        throw Exception('فشل تحميل بيانات المستخدم');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل البيانات: $e',
            style: GoogleFonts.cairo(),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _fetchCompounds() async {
    setState(() => _isFetchingCompounds = true);
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabase;
      final response = await supabase.from('compounds').select('id, name');
      setState(() {
        _compounds = (response as List).cast<Map<String, dynamic>>();
        _isFetchingCompounds = false;
        if (_selectedCompoundId != null &&
            !_compounds.any((c) => c['id'] == _selectedCompoundId)) {
          _selectedCompoundId = null;
        }
      });
    } catch (e) {
      setState(() => _isFetchingCompounds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تحميل الكمبوندات: $e',
            style: GoogleFonts.cairo(),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Update Supabase
      await authProvider.supabase.from('users').update({
        'name': _nameController.text.trim(),
        'building_number': _buildingController.text.trim(),
        'apartment_number': _apartmentController.text.trim(),
        'compound_id': _selectedCompoundId,
      }).eq('id', authProvider.currentUserId!);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final compoundName = _compounds.firstWhere(
            (c) => c['id'] == _selectedCompoundId,
        orElse: () => {'name': 'غير محدد'},
      )['name'] as String;
      final addressString =
          'كمبوند: $compoundName, عمارة: ${_buildingController.text.trim()}, شقة: ${_apartmentController.text.trim()}';
      if (_mobileNumber != null) {
        await prefs.setString('delivery_address_$_mobileNumber', addressString);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'تم حفظ التغييرات بنجاح',
                style: GoogleFonts.cairo(),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          backgroundColor: awesomeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء حفظ البيانات: $e',
            style: GoogleFonts.cairo(),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.text = _userDetails?['name'] as String? ?? '';
      _buildingController.text = _userDetails?['building_number'] as String? ?? '';
      _apartmentController.text = _userDetails?['apartment_number'] as String? ?? '';
      _selectedCompoundId = _userDetails?['compound_id'] as int?;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'الملف الشخصي',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: awesomeColor,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: awesomeColor),
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
          child: _isLoading || _isFetchingCompounds
              ? Center(
            child: CircularProgressIndicator(
              color: awesomeColor,
              backgroundColor: Colors.grey.shade200,
            ),
          )
              : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [gradientStart, gradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0]
                                    : '؟',
                                style: GoogleFonts.cairo(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: awesomeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text
                                        : 'مستخدم',
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _mobileNumber ?? 'غير متوفر',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Personal Info Section
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        'المعلومات الشخصية',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: awesomeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: _buildTextField(
                        controller: _nameController,
                        label: 'الاسم',
                        icon: Icons.person,
                        validator: (value) => value!.trim().isEmpty
                            ? 'يرجى إدخال الاسم'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Delivery Details Section
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'تفاصيل التوصيل',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: awesomeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [awesomeColor.withOpacity(0.1), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: awesomeColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<int>(
                          value: _selectedCompoundId,
                          decoration: InputDecoration(
                            labelText: 'اختر الكمبوند',
                            labelStyle: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 16),
                            floatingLabelStyle: GoogleFonts.cairo(fontSize: 16, color: awesomeColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            prefixIcon: const Icon(Icons.location_city, color: awesomeColor),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          dropdownColor: Colors.white,
                          style: GoogleFonts.cairo(color: Colors.black87, fontSize: 16),
                          items: _compounds.map((compound) {
                            return DropdownMenuItem<int>(
                              value: compound['id'] as int,
                              child: Text(compound['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCompoundId = value);
                          },
                          validator: (value) =>
                          value == null ? 'يرجى اختيار كمبوند' : null,
                          hint: Text('اختر كمبوند', style: GoogleFonts.cairo(color: Colors.grey)),
                        ),
                      ),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: _buildTextField(
                        controller: _buildingController,
                        label: 'رقم العمارة',
                        icon: Icons.apartment,
                        validator: (value) => value!.trim().isEmpty
                            ? 'يرجى إدخال رقم العمارة'
                            : null,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    FadeInUp(
                      duration: const Duration(milliseconds: 900),
                      child: _buildTextField(
                        controller: _apartmentController,
                        label: 'رقم الشقة',
                        icon: Icons.home,
                        validator: (value) => value!.trim().isEmpty
                            ? 'يرجى إدخال رقم الشقة'
                            : null,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [gradientStart, gradientEnd]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: awesomeColor.withOpacity(0.4),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Center(
                                  child: Text(
                                    'حفظ التغييرات',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    semanticsLabel: 'حفظ التغييرات',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _resetForm,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: awesomeColor, width: 2),
                              ),
                              child: Text(
                                'إلغاء',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: awesomeColor,
                                ),
                                semanticsLabel: 'إلغاء',
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(fontSize: 16, color: Colors.black54),
          floatingLabelStyle: GoogleFonts.cairo(fontSize: 16, color: awesomeColor),
          prefixIcon: Icon(icon, color: awesomeColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: awesomeColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: GoogleFonts.cairo(fontSize: 18),
        cursorColor: awesomeColor,
      ),
    );
  }
}
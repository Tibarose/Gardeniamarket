import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

class DeliveryBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialDetails;
  final Function(Map<String, dynamic>) onSave;

  const DeliveryBottomSheet({required this.initialDetails, required this.onSave, super.key});

  @override
  State<DeliveryBottomSheet> createState() => _DeliveryBottomSheetState();
}

class _DeliveryBottomSheetState extends State<DeliveryBottomSheet> {
  late TextEditingController buildingController;
  late TextEditingController apartmentController;
  int? selectedCompoundId;
  List<Map<String, dynamic>> compounds = [];
  bool isLoading = true;
  bool isFetchingUserDetails = true;

  static const Color awesomeColor = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    buildingController = TextEditingController(text: widget.initialDetails['building']?.toString() ?? '');
    apartmentController = TextEditingController(text: widget.initialDetails['apartment']?.toString() ?? '');
    selectedCompoundId = widget.initialDetails['compound_id'] as int?;
    fetchUserDeliveryDetails();
    fetchCompounds();
  }

  Future<void> fetchUserDeliveryDetails() async {
    setState(() => isFetchingUserDetails = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUserId;
      if (userId == null) {
        setState(() => isFetchingUserDetails = false);
        return;
      }

      final supabase = authProvider.supabase;
      final response = await supabase
          .from('users')
          .select('compound_id, building_number, apartment_number')
          .eq('id', userId)
          .single();

      setState(() {
        selectedCompoundId = response['compound_id'] as int?;
        buildingController.text = response['building_number']?.toString() ?? '';
        apartmentController.text = response['apartment_number']?.toString() ?? '';
        isFetchingUserDetails = false;
      });
    } catch (e) {
      _showSnackBar('خطأ في جلب تفاصيل التوصيل: $e', Colors.redAccent);
      setState(() => isFetchingUserDetails = false);
    }
  }

  Future<void> fetchCompounds() async {
    setState(() => isLoading = true);
    try {
      final supabase = Provider.of<AuthProvider>(context, listen: false).supabase;
      final response = await supabase.from('compounds').select('id, name');
      setState(() {
        compounds = (response as List).cast<Map<String, dynamic>>();
        isLoading = false;
        if (selectedCompoundId != null && !compounds.any((c) => c['id'] == selectedCompoundId)) {
          selectedCompoundId = null;
        }
      });
    } catch (e) {
      _showSnackBar('خطأ في تحميل الكمبوندات: $e', Colors.redAccent);
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        'تعديل تفاصيل التوصيل',
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: awesomeColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                isFetchingUserDetails || isLoading
                    ? const Center(child: CircularProgressIndicator(color: awesomeColor))
                    : Column(
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
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
                          value: selectedCompoundId,
                          decoration: InputDecoration(
                            labelText: 'اختر الكمبوند',
                            labelStyle: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 16),
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
                          items: compounds.map((compound) {
                            return DropdownMenuItem<int>(
                              value: compound['id'] as int,
                              child: Text(compound['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedCompoundId = value);
                          },
                          hint: Text('اختر كمبوند', style: GoogleFonts.cairo(color: Colors.grey)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: TextField(
                        controller: buildingController,
                        decoration: InputDecoration(
                          labelText: 'رقم العمارة',
                          labelStyle: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: awesomeColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: awesomeColor, width: 2),
                          ),
                          filled: true,
                          fillColor: awesomeColor.withOpacity(0.05),
                          prefixIcon: const Icon(Icons.apartment, color: awesomeColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: GoogleFonts.cairo(color: Colors.black87, fontSize: 16),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: TextField(
                        controller: apartmentController,
                        decoration: InputDecoration(
                          labelText: 'رقم الشقة',
                          labelStyle: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: awesomeColor.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: awesomeColor, width: 2),
                          ),
                          filled: true,
                          fillColor: awesomeColor.withOpacity(0.05),
                          prefixIcon: const Icon(Icons.home, color: awesomeColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: GoogleFonts.cairo(color: Colors.black87, fontSize: 16),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 700),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedCompoundId == null ||
                              buildingController.text.isEmpty ||
                              apartmentController.text.isEmpty) {
                            _showSnackBar('يرجى ملء جميع الحقول', Colors.redAccent);
                            return;
                          }
                          final updatedDetails = {
                            'compound_id': selectedCompoundId,
                            'compound_name': compounds.firstWhere(
                                  (c) => c['id'] == selectedCompoundId,
                              orElse: () => {'name': null},
                            )['name'] as String?,
                            'building': buildingController.text,
                            'apartment': apartmentController.text,
                          };

                          // Save the updated address to SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final userDetails = await authProvider.getUserDetails();
                          final mobileNumber = userDetails?['mobile_number'] as String?;
                          if (mobileNumber != null) {
                            final addressString =
                                'كمبوند: ${updatedDetails['compound_name']}, عمارة: ${updatedDetails['building']}, شقة: ${updatedDetails['apartment']}';
                            await prefs.setString('delivery_address_$mobileNumber', addressString);
                          }

                          widget.onSave(updatedDetails);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: awesomeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 6,
                          shadowColor: awesomeColor.withOpacity(0.5),
                        ),
                        child: Text(
                          'حفظ التفاصيل',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    buildingController.dispose();
    apartmentController.dispose();
    super.dispose();
  }
}
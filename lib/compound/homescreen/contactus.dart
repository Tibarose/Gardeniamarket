import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/compound/homescreen/thememanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../core/config/supabase_config.dart';

class ContactUsBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const ContactUsBottomSheet({
    super.key,
    required this.onClose,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  _ContactUsBottomSheetState createState() => _ContactUsBottomSheetState();
}

class _ContactUsBottomSheetState extends State<ContactUsBottomSheet> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _launchUrl(BuildContext context, String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح الرابط',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ: $e',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showBusinessForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusinessFormBottomSheet(
        fadeAnimation: widget.fadeAnimation,
        slideAnimation: widget.slideAnimation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          FadeTransition(
            opacity: widget.fadeAnimation,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: widget.slideAnimation,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                constraints: BoxConstraints(
                  maxWidth: isMobile ? 400 : 500,
                ),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with gradient background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(ThemeManager.cardPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primaryColor.withOpacity(0.9),
                              theme.primaryColor.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(ThemeManager.cardBorderRadius),
                            topRight: Radius.circular(ThemeManager.cardBorderRadius),
                          ),
                        ),
                        child: FadeInDown(
                          duration: ThemeManager.animationDuration,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'تواصل معنا',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 20 : 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(1, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: IconButton(
                                  icon: FaIcon(
                                    FontAwesomeIcons.xmark,
                                    size: isMobile ? 20 : 22,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _scaleController.forward().then((_) => _scaleController.reverse());
                                    widget.onClose();
                                  },
                                  tooltip: 'إغلاق',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Content with padding
                      Padding(
                        padding: const EdgeInsets.all(ThemeManager.cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // About the App Section
                            FadeInUp(
                              duration: ThemeManager.animationDuration,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // App Icon Placeholder (you can replace with your app's icon)
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      FontAwesomeIcons.solidHeart, // Placeholder icon
                                      color: theme.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'عن التطبيق',
                                          style: GoogleFonts.cairo(
                                            fontSize: isMobile ? 18 : 20,
                                            fontWeight: FontWeight.w700,
                                            color: theme.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'التطبيق خدمي لخدمة أهل الكمبوند',
                                          style: GoogleFonts.cairo(
                                            fontSize: isMobile ? 14 : 16,
                                            color: theme.secondaryTextColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Divider
                            Divider(
                              color: theme.secondaryTextColor.withOpacity(0.2),
                              thickness: 1,
                            ),
                            const SizedBox(height: 24),
                            // Contact Buttons
                            FadeInUp(
                              duration: ThemeManager.animationDuration,
                              delay: const Duration(milliseconds: 200),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildContactButton(
                                    context: context,
                                    icon: FontAwesomeIcons.whatsapp,
                                    label: 'واتساب',
                                    color: const Color(0xFF25D366),
                                    tooltip: 'واتساب',
                                    onPressed: () => _launchUrl(context, 'https://wa.me/+201289477080'),
                                    isMobile: isMobile,
                                  ),
                                  _buildContactButton(
                                    context: context,
                                    icon: FontAwesomeIcons.facebook,
                                    label: 'فيسبوك',
                                    color: const Color(0xFF3B5998),
                                    tooltip: 'فيسبوك',
                                    onPressed: () => _launchUrl(context, 'https://www.facebook.com/groups/1357143922331152'),
                                    isMobile: isMobile,
                                  ),
                                  _buildContactButton(
                                    context: context,
                                    icon: FontAwesomeIcons.phone,
                                    label: 'اتصال',
                                    color: theme.primaryColor,
                                    tooltip: 'اتصال',
                                    onPressed: () => _launchUrl(context, 'tel:+201289477080'),
                                    isMobile: isMobile,
                                  ),

                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Divider
                            Divider(
                              color: theme.secondaryTextColor.withOpacity(0.2),
                              thickness: 1,
                            ),
                            const SizedBox(height: 24),
                            // Add Business Button
                            FadeInUp(
                              duration: ThemeManager.animationDuration,
                              delay: const Duration(milliseconds: 400),
                              child: _buildAddBusinessButton(
                                context: context,
                                isMobile: isMobile,
                                theme: theme,
                                onPressed: () => _showBusinessForm(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        onEnter: (_) => _scaleController.forward(),
        onExit: (_) => _scaleController.reverse(),
        child: GestureDetector(
          onTap: onPressed,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: isMobile ? 24 : 28,
                    backgroundColor: color,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.8),
                            color,
                          ],
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          icon,
                          size: isMobile ? 24 : 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager().currentTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddBusinessButton({
    required BuildContext context,
    required bool isMobile,
    required AppTheme theme,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: 'إضافة نشاطك التجاري',
      child: MouseRegion(
        onEnter: (_) => _scaleController.forward(),
        onExit: (_) => _scaleController.reverse(),
        child: GestureDetector(
          onTap: onPressed,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6A1B9A),
                    Color(0xFFD81B60),
                    Color(0xFF9C27B0),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.store,
                    size: isMobile ? 22 : 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إضافة نشاطك التجاري',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The BusinessFormBottomSheet remains unchanged for brevity, but can be styled similarly if needed.

class BusinessFormBottomSheet extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const BusinessFormBottomSheet({
    super.key,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  _BusinessFormBottomSheetState createState() => _BusinessFormBottomSheetState();
}

class _BusinessFormBottomSheetState extends State<BusinessFormBottomSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  String _location = 'داخل الكمبوند';
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _whatsappController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        print('DEBUG: Starting form submission to secondary Supabase account...');

        // Access the secondary Supabase client via SupabaseConfig
        final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
        final supabase = supabaseConfig.secondaryClient;
        if (supabase == null) {
          throw Exception('Secondary Supabase client not initialized');
        }
        print('DEBUG: Secondary Supabase client accessed successfully');

        // Prepare form data
        final formData = {
          'business_name': _businessNameController.text,
          'description': _descriptionController.text,
          'contact_name': _contactNameController.text,
          'whatsapp': _whatsappController.text,
          'location': _location,
        };
        print('DEBUG: Form data: $formData');

        // Perform the insert
        final response = await supabase.from('business_submissions').insert(formData);
        print('DEBUG: Insert response: $response');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال طلبك بنجاح!',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.pop(context);
      } catch (error, stackTrace) {
        print('DEBUG: Submission error: $error');
        print('DEBUG: Stack trace: $stackTrace');

        String errorMessage;
        if (error.toString().contains('Network')) {
          errorMessage = 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
        } else if (error.toString().contains('Permission denied')) {
          errorMessage = 'خطأ: الإذن مرفوض. تحقق من إعدادات RLS.';
        } else if (error.toString().contains('not found')) {
          errorMessage = 'خطأ: الجدول غير موجود. تحقق من إعدادات Supabase.';
        } else {
          errorMessage = 'خطأ: فشل في إرسال الطلب. ($error)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
        print('DEBUG: Form submission completed');
      }
    } else {
      print('DEBUG: Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          FadeTransition(
            opacity: widget.fadeAnimation,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: widget.slideAnimation,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                constraints: BoxConstraints(
                  maxWidth: isMobile ? 400 : 500,
                ),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(ThemeManager.cardPadding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInDown(
                            duration: ThemeManager.animationDuration,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'إضافة نشاطك التجاري',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.w800,
                                    color: theme.textColor,
                                  ),
                                ),
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: IconButton(
                                    icon: FaIcon(
                                      FontAwesomeIcons.xmark,
                                      size: isMobile ? 20 : 22,
                                      color: theme.secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      _scaleController.forward().then((_) => _scaleController.reverse());
                                      Navigator.pop(context);
                                    },
                                    tooltip: 'إغلاق',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              'قم بإضافة نشاطك التجاري ليتم عرضه ضمن خدمات جاردينيا توداي',
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 14 : 16,
                                color: theme.secondaryTextColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            delay: const Duration(milliseconds: 400),
                            child: TextFormField(
                              controller: _businessNameController,
                              decoration: InputDecoration(
                                labelText: 'اسم النشاط',
                                labelStyle: GoogleFonts.cairo(color: theme.secondaryTextColor),
                                filled: true,
                                fillColor: theme.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال اسم النشاط';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            delay: const Duration(milliseconds: 600),
                            child: TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'وصف النشاط',
                                labelStyle: GoogleFonts.cairo(color: theme.secondaryTextColor),
                                filled: true,
                                fillColor: theme.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال وصف النشاط';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            delay: const Duration(milliseconds: 800),
                            child: TextFormField(
                              controller: _contactNameController,
                              decoration: InputDecoration(
                                labelText: 'اسم التواصل',
                                labelStyle: GoogleFonts.cairo(color: theme.secondaryTextColor),
                                filled: true,
                                fillColor: theme.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال اسم التواصل';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            delay: const Duration(milliseconds: 1000),
                            child: TextFormField(
                              controller: _whatsappController,
                              decoration: InputDecoration(
                                labelText: 'رقم تليفون التواصل (واتساب)',
                                labelStyle: GoogleFonts.cairo(color: theme.secondaryTextColor),
                                filled: true,
                                fillColor: theme.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              textDirection: TextDirection.ltr,
                              style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly, // Allow only digits
                                LengthLimitingTextInputFormatter(11), // Limit to 11 characters
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال رقم التواصل';
                                }
                                if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                                  return 'يرجى إدخال رقم هاتف مكون من 11 رقمًا';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 16),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            delay: const Duration(milliseconds: 1200),
                            child: DropdownButtonFormField<String>(
                              value: _location,
                              decoration: InputDecoration(
                                labelText: 'الموقع',
                                labelStyle: GoogleFonts.cairo(color: theme.secondaryTextColor),
                                filled: true,
                                fillColor: theme.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: ['داخل الكمبوند', 'خارج الكمبوند'].map((location) => DropdownMenuItem(
                                value: location,
                                child: Text(
                                  location,
                                  style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                                  textDirection: TextDirection.rtl,
                                ),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _location = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeInUp(
                            duration: ThemeManager.animationDuration,
                            delay: const Duration(milliseconds: 1400),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                  child: Text(
                                    'إلغاء',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      color: theme.secondaryTextColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                MouseRegion(
                                  onEnter: (_) => _scaleController.forward(),
                                  onExit: (_) => _scaleController.reverse(),
                                  child: GestureDetector(
                                    onTap: _isSubmitting ? null : () => _submitForm(context),
                                    child: ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF6A1B9A),
                                              Color(0xFFD81B60),
                                              Color(0xFF9C27B0),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.primaryColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: _isSubmitting
                                            ? CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        )
                                            : Text(
                                          'إرسال',
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
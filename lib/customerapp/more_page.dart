import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/profilepage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  static const Color awesomeColor = Color(0xFF6A1B9A);
  static const Color gradientStart = Color(0xFF6A1B9A);
  static const Color gradientEnd = Color(0xFF9C27B0);
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || authProvider.currentUserId == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final details = await authProvider.getUserDetails();
      setState(() {
        _userDetails = details;
        _isLoggedIn = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تحميل البيانات: $e',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white,
            ),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildNotLoggedInScreen() {
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'يرجى التسجيل',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحتاج إلى تسجيل الدخول لعرض صفحة المزيد',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: awesomeColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'تسجيل الدخول',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'المزيد',
            style: GoogleFonts.cairo(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: awesomeColor,
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
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: awesomeColor,
              backgroundColor: Colors.grey.shade200,
            ),
          )
              : !_isLoggedIn
              ? _buildNotLoggedInScreen()
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDesktop)),
              SliverToBoxAdapter(child: _buildSectionTitle('الحساب', isDesktop)),
              SliverToBoxAdapter(child: _buildMenuItems(context, isDesktop)),
              SliverToBoxAdapter(child: _buildSectionTitle('معلومات', isDesktop)),
              SliverToBoxAdapter(child: _buildInfoItems(context, isDesktop)),
              SliverToBoxAdapter(child: _buildFooter(isDesktop)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    final name = _userDetails?['name'] as String? ?? 'مستخدم';
    final mobile = _userDetails?['mobile_number'] as String? ?? 'غير متوفر';

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 16),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: isDesktop ? 50 : 40,
              backgroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0] : '؟',
                style: GoogleFonts.cairo(
                  fontSize: isDesktop ? 40 : 36,
                  fontWeight: FontWeight.bold,
                  color: awesomeColor,
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 24 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: isDesktop ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    mobile,
                    style: GoogleFonts.cairo(
                      fontSize: isDesktop ? 18 : 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDesktop) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 12),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: awesomeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, bool isDesktop) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.person,
            title: 'الملف الشخصي',
            subtitle: 'عرض وتعديل بياناتك الشخصية',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            isDesktop: isDesktop,
            gradientColors: [gradientStart.withOpacity(0.1), gradientEnd.withOpacity(0.1)],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItems(BuildContext context, bool isDesktop) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: _buildMenuItem(
              context,
              icon: Icons.info,
              title: 'عن التطبيق',
              subtitle: 'معلومات عن ماركت جاردينيا',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'ماركت جاردينيا',
                  applicationVersion: '1.0.0',
                  children: [
                    Text(
                      'تطبيق ماركت جاردينيا يوفر لك تجربة تسوق سهلة ومريحة داخل الكمبوند. اطلب منتجاتك بضغطة زر!',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                );
              },
              isDesktop: isDesktop,
              gradientColors: [gradientStart.withOpacity(0.1), gradientEnd.withOpacity(0.1)],
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildMenuItem(
              context,
              icon: Icons.support,
              title: 'الدعم',
              subtitle: 'تواصل مع فريق الدعم',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.support_agent, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'اتصل بنا على 01011937796',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    backgroundColor: awesomeColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              isDesktop: isDesktop,
              gradientColors: [gradientStart.withOpacity(0.1), gradientEnd.withOpacity(0.1)],
            ),
          ),
          const SizedBox(height: 12),
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            child: _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              subtitle: 'الخروج من حسابك',
              onTap: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                setState(() {
                  _isLoggedIn = false;
                  _userDetails = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'تم تسجيل الخروج بنجاح',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    backgroundColor: awesomeColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              isDesktop: isDesktop,
              gradientColors: [Colors.redAccent.withOpacity(0.1), Colors.white.withOpacity(0.1)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required bool isDesktop,
        List<Color>? gradientColors,
      }) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) {
        onTap();
        setState(() {});
      },
      onTapCancel: () => setState(() {}),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 4),
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ?? [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 12 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isDesktop ? 30 : 28,
                semanticLabel: title,
              ),
            ),
            SizedBox(width: isDesktop ? 20 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: isDesktop ? 20 : 18,
                      fontWeight: FontWeight.w600,
                      color: awesomeColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: isDesktop ? 16 : 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: awesomeColor,
              size: isDesktop ? 20 : 16,
              semanticLabel: 'انتقل إلى $title',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDesktop) {
    if (!_isLoggedIn) return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        decoration: BoxDecoration(
          color: awesomeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              'ماركت جاردينيا',
              style: GoogleFonts.cairo(
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: awesomeColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تسوق بسهولة وسرعة داخل الكمبوند',
              style: GoogleFonts.cairo(
                fontSize: isDesktop ? 16 : 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.facebook, color: awesomeColor),
                  onPressed: () {},
                  tooltip: 'فيسبوك',
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: awesomeColor),
                  onPressed: () {},
                  tooltip: 'اتصال',
                ),
                IconButton(
                  icon: const Icon(Icons.email, color: awesomeColor),
                  onPressed: () {},
                  tooltip: 'بريد إلكتروني',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Widget _buildFeatureCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required String route,
        required Color gradientStart,
        required Color gradientEnd,
      }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isHovered = ValueNotifier<bool>(false); // For hover effect on web/desktop

    return ValueListenableBuilder<bool>(
      valueListenable: isHovered,
      builder: (context, hovered, child) {
        return MouseRegion(
          onEnter: (_) => isHovered.value = true,
          onExit: (_) => isHovered.value = false,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, route),
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientEnd],
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isMobile ? 32 : 40,
                        semanticLabel: title,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'هل أنت متأكد أنك تريد تسجيل الخروج؟',
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 900;
    final authProvider = Provider.of<AuthProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'لوحة التحكم',
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
                colors: [Colors.green[700]!, Colors.green[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            if (authProvider.isAuthenticated)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  final confirmed = await _confirmLogout(context);
                  if (confirmed) {
                    await authProvider.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                tooltip: 'تسجيل الخروج',
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      'مرحبًا بك في إدارة السوق',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'اختر إحدى الخيارات أدناه للبدء',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16 : 20,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildFeatureCard(
                          context,
                          title: 'إدارة المنتجات',
                          icon: Icons.inventory_2,
                          route: '/products',
                          gradientStart: Colors.green[600]!,
                          gradientEnd: Colors.green[400]!,
                        ),
                        _buildFeatureCard(
                          context,
                          title: 'إدارة الفئات',
                          icon: Icons.category,
                          route: '/categories',
                          gradientStart: Colors.blue[600]!,
                          gradientEnd: Colors.blue[400]!,
                        ),
                        _buildFeatureCard(
                          context,
                          title: 'الطلبات',
                          icon: Icons.shopping_cart,
                          route: '/orders',
                          gradientStart: Colors.orange[600]!,
                          gradientEnd: Colors.orange[400]!,
                        ),
                        _buildFeatureCard(
                          context,
                          title: 'صفحات السوبرماركت',
                          icon: Icons.store,
                          route: '/market',
                          gradientStart: Colors.purple[600]!,
                          gradientEnd: Colors.purple[400]!,
                        ),
                        _buildFeatureCard(
                          context,
                          title: 'الإعلانات',
                          icon: Icons.slideshow,
                          route: '/CarouselItemsPage',
                          gradientStart: Colors.teal[600]!,
                          gradientEnd: Colors.teal[400]!,
                        ), _buildFeatureCard(
                          context,
                          title: 'manage',
                          icon: Icons.slideshow,
                          route: '/manage',
                          gradientStart: Colors.teal[600]!,
                          gradientEnd: Colors.teal[400]!,
                        ),
                        _buildFeatureCard(
                          context,
                          title: 'طلبات التوصيل',
                          icon: Icons.delivery_dining,
                          route: '/DeliveryGuyOrdersPage',
                          gradientStart: Colors.red[600]!,
                          gradientEnd: Colors.red[400]!,
                        ),
                        _buildFeatureCard(
                          context,
                          title: 'إدارة المستخدمين',
                          icon: Icons.people,
                          route: '/ManageUsersPages',
                          gradientStart: Colors.indigo[600]!,
                          gradientEnd: Colors.indigo[400]!,
                        ),    _buildFeatureCard(
                          context,
                          title: ' GardeniaTodayApp',
                          icon: Icons.people,
                          route: '/GardeniaTodayApp',
                          gradientStart: Colors.indigo[600]!,
                          gradientEnd: Colors.indigo[400]!,
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
    );
  }
}
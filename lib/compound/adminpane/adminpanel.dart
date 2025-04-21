import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';
import 'RestaurantsManagementPage.dart';
import 'addbusinessrequests.dart';
import 'managecatousal.dart';
import 'managesupermarket.dart';
import 'newsscreen.dart';
import 'popups.dart';
import 'rentedhouses.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  _AdminPanelPageState createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  int _selectedIndex = 1; // Start with MainPage (index 1)
  bool _isLoading = true;

  // List of pages for navigation
  final List<Widget> _pages = [
    const WelcomePage(),
    const MainPage(),
    const SupermarketsManagementPage(),
    const CarouselAdminScreen(),
    const BusinessSubmissionsPage(),
    const RestaurantsManagementPage(),
    const PopupsManagementPage(),
    const NewsManagementPage(),
    const HousesManagementPage(),
  ];

  // List of titles, icons, and colors for navigation items
  final List<Map<String, dynamic>> _services = [
    {
      'title': 'الصفحة الرئيسية',
      'icon': FontAwesomeIcons.home,
      'color': Colors.cyan,
      'index': 1,
    },
    {
      'title': 'إدارة السوبر ماركت',
      'icon': FontAwesomeIcons.store,
      'color': Colors.blue,
      'index': 2,
    },
    {
      'title': 'إدارة الإعلانات الدائرية',
      'icon': FontAwesomeIcons.images,
      'color': Colors.green,
      'index': 3,
    },
    {
      'title': 'إدارة إعلانات الأعمال',
      'icon': FontAwesomeIcons.ad,
      'color': Colors.orange,
      'index': 4,
    },
    {
      'title': 'إدارة المطاعم',
      'icon': FontAwesomeIcons.utensils,
      'color': Colors.red,
      'index': 5,
    },
    {
      'title': 'إدارة النوافذ المنبثقة',
      'icon': FontAwesomeIcons.windowMaximize,
      'color': Colors.purple,
      'index': 6,
    },
    {
      'title': 'إدارة الأخبار',
      'icon': FontAwesomeIcons.newspaper,
      'color': Colors.teal,
      'index': 7,
    },
    {
      'title': 'إدارة الشقق',
      'icon': FontAwesomeIcons.home,
      'color': Colors.indigo,
      'index': 8,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fetch data when the page loads
    _prefetchData();
  }

  Future<void> _prefetchData() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await Future.wait([
        // Fetch Supermarkets
        supabaseConfig.secondaryClient.from('supermarkets').select().limit(1),
        // Fetch Carousel
        supabaseConfig.secondaryClient.from('carousel').select().limit(1),
        // Fetch Business Submissions
        supabaseConfig.secondaryClient.from('business_submissions').select().limit(1),
        // Fetch Restaurants
        supabaseConfig.secondaryClient.from('restaurants').select().limit(1),
        // Fetch Popups
        supabaseConfig.secondaryClient.from('popups').select().limit(1),
        // Fetch News
        supabaseConfig.secondaryClient.from('news').select().limit(1),
        // Fetch Houses
        supabaseConfig.secondaryClient.from('houses').select().limit(1),
      ]);
      setState(() {
        _isLoading = false;
        // No need to change _selectedIndex; default is already MainPage
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في تحميل البيانات: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth >= 1024;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                _selectedIndex == -1 || _selectedIndex == 0
                    ? 'مرحبًا بك في لوحة الإدارة'
                    : _services[_selectedIndex - 1]['title'],
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 4,
              leading: isDesktop
                  ? (_selectedIndex != 1 // Show back button if not on MainPage
                  ? IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowRight),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1; // Navigate back to MainPage
                  });
                },
              )
                  : null)
                  : Builder(
                builder: (context) => IconButton(
                  icon: const FaIcon(FontAwesomeIcons.bars),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                if (!isDesktop && _selectedIndex != 1) // Back button for mobile
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.arrowRight),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Navigate back to MainPage
                      });
                    },
                  ),
              ],
            ),
            drawer: !isDesktop
                ? Drawer(
              child: _buildDrawerContent(theme),
            )
                : null,
            body: Row(
              children: [
                if (isDesktop)
                  Container(
                    width: 250,
                    color: theme.cardBackground,
                    child: _buildDrawerContent(theme),
                  ),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerContent(AppTheme theme) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            color: theme.primaryColor,
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.userShield,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Text(
                  'لوحة الإدارة',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ..._services.map((service) => _buildDrawerItem(
                  icon: service['icon'],
                  title: service['title'],
                  index: service['index'],
                  theme: theme,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required AppTheme theme,
  }) {
    bool isSelected = _selectedIndex == index;

    return ListTile(
      leading: FaIcon(
        icon,
        color: isSelected ? theme.primaryColor : theme.secondaryTextColor,
        size: 24,
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isSelected ? theme.primaryColor : theme.secondaryTextColor,
        ),
      ),
      tileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (MediaQuery.of(context).size.width < 1024) {
          Navigator.pop(context); // Close drawer on mobile/tablet
        }
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final state = context.findAncestorStateOfType<_AdminPanelPageState>()!;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.cardBackground,
            theme.cardBackground.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          if (!isDesktop) const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'اختر الخدمة التي تريد إدارتها',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
          ),
          Expanded(
            child: state._isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل البيانات...',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: theme.textColor,
                    ),
                  ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: state._services.length,
              itemBuilder: (context, index) {
                final service = state._services[index];
                return _buildServiceCard(
                  context: context,
                  icon: service['icon'],
                  title: service['title'],
                  color: service['color'],
                  index: service['index'],
                  theme: theme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required int index,
    required AppTheme theme,
  }) {
    return GestureDetector(
      onTap: () {
        final state = context.findAncestorStateOfType<_AdminPanelPageState>()!;
        state.setState(() {
          state._selectedIndex = index;
        });
      },
      child: Hero(
        tag: 'service-$index',
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  icon,
                  size: 40,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final state = context.findAncestorStateOfType<_AdminPanelPageState>()!;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.cardBackground,
            theme.cardBackground.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          if (!isDesktop) const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'الخدمات المتاحة',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: state._services.length,
              itemBuilder: (context, index) {
                final service = state._services[index];
                return _buildServiceCard(
                  context: context,
                  icon: service['icon'],
                  title: service['title'],
                  color: service['color'],
                  index: service['index'],
                  theme: theme,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required int index,
    required AppTheme theme,
  }) {
    return GestureDetector(
      onTap: () {
        final state = context.findAncestorStateOfType<_AdminPanelPageState>()!;
        state.setState(() {
          state._selectedIndex = index;
        });
      },
      child: Hero(
        tag: 'service-$index',
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  icon,
                  size: 40,
                  color: color,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
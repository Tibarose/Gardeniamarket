import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/cartlist/cart_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'market.dart';
import 'searchpage.dart';
import 'orderhistory.dart';
import 'more_page.dart'; // Import the new MorePage

class BottomNavigation extends StatefulWidget {
  final int initialTab;

  const BottomNavigation({super.key, this.initialTab = 0});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void switchTab(int index) {
    _onTabTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MarketPage(),
      SearchPage(
        onNavigateToCart: () => _onTabTapped(2),
      ),
      const CartPage(),
      const OrderHistoryPage(),
      const MorePage(), // Add the MorePage
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: const Color(0xFF6A1B9A),
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
          elevation: 8,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المتجر'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'البحث'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'السلة'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الطلبات'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'المزيد'), // New "More" tab
          ],
        ),
      ),
    );
  }
}
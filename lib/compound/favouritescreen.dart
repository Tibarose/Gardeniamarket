
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import '../compound/home_screen.dart'; // Import for ServicesGrid
import 'homescreen/favouritenotify.dart';
import 'homescreen/thememanager.dart'; // Import for ThemeManager
import 'package:provider/provider.dart'; // Import for Provider

class FavoritesScreen extends StatelessWidget {
final Set<String> favorites;
final Function(String) onFavoriteToggle;
final VoidCallback onBackToHome;

const FavoritesScreen({
super.key,
required this.favorites,
required this.onFavoriteToggle,
required this.onBackToHome,
});

@override
Widget build(BuildContext context) {
final isMobile = MediaQuery.of(context).size.width < 600;
final theme = ThemeManager().currentTheme;

return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: theme.backgroundColor,
body: SafeArea(
child: RefreshIndicator(
color: theme.primaryColor,
onRefresh: () async {
await Future.delayed(const Duration(seconds: 1));
},
child: CustomScrollView(
physics: const AlwaysScrollableScrollPhysics(),
slivers: [
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.1),
blurRadius: 10,
offset: const Offset(0, 2),
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
child: BackdropFilter(
filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.1),
borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
border: Border.all(
color: Colors.white.withOpacity(0.2),
width: 1,
),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
if (favorites.isNotEmpty)
ElasticIn(
duration: ThemeManager.animationDuration,
child: _ClearAllButton(
onPressed: () {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: Text(
'مسح المفضلة',
style: GoogleFonts.cairo(
fontSize: isMobile ? 18 : 20,
fontWeight: FontWeight.w700,
color: theme.textColor,
),
),
content: Text(
'هل أنت متأكد من مسح جميع الخدمات المفضلة؟',
style: GoogleFonts.cairo(
fontSize: isMobile ? 15 : 16,
color: theme.textColor,
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text(
'إلغاء',
style: GoogleFonts.cairo(
fontSize: isMobile ? 14 : 15,
color: theme.secondaryTextColor,
),
),
),
TextButton(
onPressed: () {
Provider.of<FavoritesProvider>(context, listen: false).clearFavorites();
Navigator.pop(context);
},
child: Text(
'مسح',
style: GoogleFonts.cairo(
fontSize: isMobile ? 14 : 15,
color: Colors.red,
),
),
),
],
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
backgroundColor: theme.cardBackground,
),
);
},
),
)
else
const SizedBox(width: 40), // Placeholder for alignment
Expanded(
child: Padding(
padding: const EdgeInsets.only(right: 8),
child: Text(
'المفضلة',
style: GoogleFonts.cairo(
fontSize: isMobile ? 22 : 24,
fontWeight: FontWeight.w700,
color: theme.textColor,
),
),
),
),
Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: theme.primaryColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Text(
'${favorites.length} خدمة',
style: GoogleFonts.cairo(
fontSize: isMobile ? 14 : 15,
color: theme.primaryColor,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
),
),
),
),
),
if (favorites.isEmpty)
SliverFillRemaining(
child: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Pulse(
duration: const Duration(seconds: 2),
child: FaIcon(
FontAwesomeIcons.heart,
size: isMobile ? 80 : 100,
color: theme.secondaryTextColor.withOpacity(0.3),
),
),
const SizedBox(height: 16),
FadeInUp(
child: Text(
'لا توجد خدمات مفضلة بعد',
style: GoogleFonts.cairo(
fontSize: isMobile ? 18 : 20,
fontWeight: FontWeight.w600,
color: theme.secondaryTextColor,
),
),
),
const SizedBox(height: 12),
ZoomIn(
child: ElevatedButton(
onPressed: onBackToHome,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.transparent,
shadowColor: Colors.transparent,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
padding: EdgeInsets.zero,
),
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(12),
boxShadow: [
BoxShadow(
color: theme.primaryColor.withOpacity(0.2),
spreadRadius: 1,
blurRadius: 6,
offset: const Offset(0, 2),
),
],
),
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
child: Text(
'تصفح الخدمات الآن',
style: GoogleFonts.cairo(
fontSize: isMobile ? 15 : 16,
fontWeight: FontWeight.w700,
color: Colors.white,
),
),
),
),
),
],
),
),
)
else
FavoritesGrid(
favorites: favorites,
onFavoriteToggle: onFavoriteToggle,
),
],
),
),
),
),
);
}
}

class _ClearAllButton extends StatefulWidget {
final VoidCallback onPressed;

const _ClearAllButton({required this.onPressed});

@override
__ClearAllButtonState createState() => __ClearAllButtonState();
}

class __ClearAllButtonState extends State<_ClearAllButton> with SingleTickerProviderStateMixin {
late AnimationController _controller;
late Animation<double> _scaleAnimation;

@override
void initState() {
super.initState();
_controller = AnimationController(
vsync: this,
duration: ThemeManager.animationDuration,
);
_scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final isMobile = MediaQuery.of(context).size.width < 600;
final theme = ThemeManager().currentTheme;

return Semantics(
label: 'مسح جميع الخدمات المفضلة',
child: MouseRegion(
cursor: SystemMouseCursors.click,
child: GestureDetector(
onTapDown: (_) => _controller.forward(),
onTapUp: (_) {
_controller.reverse();
widget.onPressed();
},
onTapCancel: () => _controller.reverse(),
child: ScaleTransition(
scale: _scaleAnimation,
child: Tooltip(
message: 'مسح الكل',
child: Material(
color: Colors.transparent,
child: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [Colors.redAccent, Colors.red],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: Colors.redAccent.withOpacity(0.3),
spreadRadius: 1,
blurRadius: 6,
offset: const Offset(0, 2),
),
],
),
child: FaIcon(
FontAwesomeIcons.trash,
size: isMobile ? 18 : 20,
color: Colors.white,
),
),
),
),
),
),
),
);
}
}

class FavoritesGrid extends StatelessWidget {
final Set<String> favorites;
final Function(String) onFavoriteToggle;

const FavoritesGrid({
super.key,
required this.favorites,
required this.onFavoriteToggle,
});

@override
Widget build(BuildContext context) {
final isMobile = MediaQuery.of(context).size.width < 600;
final theme = ThemeManager().currentTheme;
final favoriteServices = ServicesGrid.services.where((service) {
return favorites.contains(service['name']);
}).toList();

return SliverPadding(
padding: EdgeInsets.symmetric(
horizontal: ThemeManager.cardPadding,
vertical: ThemeManager.cardPadding,
),
sliver: SliverGrid(
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 3,
crossAxisSpacing: 8,
mainAxisSpacing: 8,
childAspectRatio: 0.6,
),
delegate: SliverChildBuilderDelegate(
(context, index) {
final service = favoriteServices[index];
return ElasticIn(
duration: ThemeManager.animationDuration,
child: ServiceCard(
name: service['name'],
icon: service['icon'],
description: service['description'],
category: service['category'],
route: service['route'],
cardColor: theme.cardColors[index % theme.cardColors.length],
isFavorite: true,
onFavoriteToggle: () => onFavoriteToggle(service['name']),
),
);
},
childCount: favoriteServices.length,
),
),
);
}
}

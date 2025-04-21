import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/compound/homescreen/thememanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gardeniamarket/compound/home_screen.dart';

class AllServicesScreen extends StatefulWidget {
  final Set<String> favorites;
  final Function(String) onFavoriteToggle;

  const AllServicesScreen({
    super.key,
    required this.favorites,
    required this.onFavoriteToggle,
  });

  @override
  _AllServicesScreenState createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  String _selectedCategory = 'الكل';

  Widget _buildCategoryChip(String label, String imageUrl, bool isMobile) {
    bool isSelected = _selectedCategory == label;
    final theme = ThemeManager().currentTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 15 : 16,
                  color: isSelected ? Colors.white : theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: isSelected,
        selectedColor: theme.primaryColor,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
        ),
        elevation: isSelected ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = label);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: theme.appBarGradient,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'جميع الخدمات',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 24 : 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.arrowRight,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'رجوع',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(ThemeManager.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفئات',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: isMobile ? 40 : 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildCategoryChip('الكل', 'https://images.unsplash.com/photo-1481349518771-20055b2a7b24', isMobile),
                            _buildCategoryChip('التسوق', 'https://images.unsplash.com/photo-1513185041617-8ab03f83d6c5', isMobile),
                            _buildCategoryChip('الصحة', 'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7', isMobile),
                            _buildCategoryChip('الترفيه', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819', isMobile),
                            _buildCategoryChip('الخدمات', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40', isMobile),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              ServicesGrid(
                searchQuery: '',
                selectedCategory: _selectedCategory,
                favorites: widget.favorites,
                onFavoriteToggle: widget.onFavoriteToggle,
                useSliver: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
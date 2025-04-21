import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../compound/homescreen/thememanager.dart';
import '../../main.dart'; // Import for SupabaseConfig
import 'package:animate_do/animate_do.dart';

import '../core/config/supabase_config.dart'; // For animations

class CarouselSection extends StatefulWidget {
  final bool isMobile;

  const CarouselSection({super.key, required this.isMobile});

  @override
  _CarouselSectionState createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<CarouselSection> {
  int _currentCarouselIndex = 0;
  List<Map<String, dynamic>> _carouselItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCarouselItems();
  }

  Future<void> _fetchCarouselItems() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('carousel_items')
          .select('image, title, subtitle, route, link');

      setState(() {
        _carouselItems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load carousel items: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا يمكن فتح الرابط: $url',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleTap(String? link, String? route) {
    if (link != null && link.isNotEmpty) {
      _launchUrl(link);
    } else if (route != null && route.isNotEmpty) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
          strokeWidth: 3,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_carouselItems.isEmpty) {
      return Center(
        child: Text(
          'No carousel items available',
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: theme.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: screenWidth, // Full screen width
          height: widget.isMobile ? 200 : 300,
          child: CarouselSlider(
            options: CarouselOptions(
              height: widget.isMobile ? 200 : 300, // Adjusted to match SizedBox height
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 1.0, // Full-width slides
              enlargeCenterPage: false, // Disable enlarging to ensure full width
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              padEnds: false, // Remove any default padding on ends
            ),
            items: _carouselItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Builder(
                builder: (BuildContext context) {
                  return FadeIn(
                    duration: const Duration(milliseconds: 600),
                    child: GestureDetector(
                      onTap: (item['link'] != null && item['link'].isNotEmpty) ||
                          (item['route'] != null && item['route'].isNotEmpty)
                          ? () => _handleTap(item['link'], item['route'])
                          : null,
                      child: AnimatedScale(
                        scale: (item['link'] != null && item['link'].isNotEmpty) ||
                            (item['route'] != null && item['route'].isNotEmpty)
                            ? 1.0
                            : 0.98,
                        duration: const Duration(milliseconds: 200),
                        child: Stack(
                          fit: StackFit.expand, // Ensure Stack takes full width and height
                          children: [
                            // Background Image - Full Width
                            CachedNetworkImage(
                              imageUrl: item['image'] ?? '',
                              fit: BoxFit.cover, // Use cover to maintain aspect ratio
                              width: screenWidth, // Full screen width
                              height: widget.isMobile ? 200 : 300,
                              placeholder: (context, url) => Container(
                                color: theme.cardBackground.withOpacity(0.8),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: theme.primaryColor,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.cardBackground,
                                child: FaIcon(
                                  FontAwesomeIcons.image,
                                  color: theme.secondaryTextColor,
                                  size: 40,
                                ),
                              ),
                            ),
                            // Gradient Overlay with Theme Colors - Full Width
                            Container(
                              width: screenWidth, // Full screen width
                              height: widget.isMobile ? 200 : 300,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryColor.withOpacity(0.7), // Theme-based overlay
                                    theme.primaryColor.withOpacity(0.1), // Lighter for gradient
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  stops: const [0.0, 0.7],
                                ),
                              ),
                            ),
                            // Content - Apply padding only to content
                            Padding(
                              padding: const EdgeInsets.all(16.0), // Padding for content only
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title with Animation
                                  SlideInLeft(
                                    duration: const Duration(milliseconds: 500),
                                    child: Text(
                                      item['title'] ?? '',
                                      style: GoogleFonts.cairo(
                                        fontSize: widget.isMobile ? 20 : 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            offset: const Offset(1, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Subtitle
                                  SlideInLeft(
                                    duration: const Duration(milliseconds: 600),
                                    child: Text(
                                      item['subtitle'] ?? '',
                                      style: GoogleFonts.cairo(
                                        fontSize: widget.isMobile ? 14 : 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Action Button
                                  SlideInLeft(
                                    duration: const Duration(milliseconds: 700),
                                    child: GestureDetector(
                                      onTap: (item['link'] != null && item['link'].isNotEmpty) ||
                                          (item['route'] != null && item['route'].isNotEmpty)
                                          ? () => _handleTap(item['link'], item['route'])
                                          : null,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: (item['link'] != null && item['link'].isNotEmpty) ||
                                              (item['route'] != null && item['route'].isNotEmpty)
                                              ? theme.primaryColor
                                              : theme.primaryColor.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.primaryColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'المزيد',
                                              style: GoogleFonts.cairo(
                                                fontSize: widget.isMobile ? 14 : 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FaIcon(
                                              FontAwesomeIcons.arrowRight,
                                              size: widget.isMobile ? 14 : 16,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
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
                  );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_carouselItems.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentCarouselIndex == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentCarouselIndex == index
                    ? theme.primaryColor
                    : theme.secondaryTextColor.withOpacity(0.4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
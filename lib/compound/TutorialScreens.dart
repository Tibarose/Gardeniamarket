import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homescreen/thememanager.dart';

class TutorialScreens extends StatefulWidget {
  final String nextRoute;
  const TutorialScreens({super.key, required this.nextRoute});

  @override
  _TutorialScreensState createState() => _TutorialScreensState();
}

class _TutorialScreensState extends State<TutorialScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Save tutorial completion status and navigate with parallax zoom animation
  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    Navigator.pushReplacement(
      context,
      ParallaxZoomPageRoute(routeName: widget.nextRoute),
    );
  }

  // Tutorial content
  final List<Map<String, dynamic>> tutorialContent = [
    {
      'title': 'استكشف الخدمات',
      'description': 'ابحث عن كل ما تحتاجه من تسوق، صحة، وخدمات يومية في مكان واحد.',
      'icon': FontAwesomeIcons.magnifyingGlass,
      'image': 'https://i.ibb.co/Qj16SBgP/wmremove-transformed-removebg-preview.png',
    },
    {
      'title': 'المفضلة',
      'description': 'أضف خدماتك المفضلة للوصول إليها بسرعة وسهولة في أي وقت.',
      'icon': FontAwesomeIcons.heart,
      'image': 'https://i.ibb.co/jZPc7q2c/wmremove-transformed-1-removebg-preview.png',
    },
    {
      'title': 'تواصل معنا',
      'description': 'نحن هنا لدعمك! اضف نشاطك التجاري بسهولة عبر التطبيق.',
      'icon': FontAwesomeIcons.envelope,
      'image': 'https://i.ibb.co/CK0xM9ZZ/De-Watermark-ai-1745038904391-removebg-preview.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = ThemeManager().currentTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _isLastPage = index == tutorialContent.length - 1;
                  });
                },
                itemCount: tutorialContent.length,
                itemBuilder: (context, index) {
                  final content = tutorialContent[index];
                  return FadeIn(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            content['image'],
                            height: isMobile ? 250 : 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: isMobile ? 250 : 300,
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 3)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: isMobile ? 250 : 300,
                              color: Colors.grey[200],
                              child: const FaIcon(FontAwesomeIcons.image, color: Colors.grey, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        CircleAvatar(
                          radius: isMobile ? 40 : 48,
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: FaIcon(
                            content['icon'],
                            size: isMobile ? 36 : 42,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            content['title'],
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 24 : 28,
                              fontWeight: FontWeight.w800,
                              color: theme.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            content['description'],
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 16 : 18,
                              color: theme.secondaryTextColor,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                child: TextButton(
                  onPressed: _completeTutorial,
                  child: Text(
                    'تخطي',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 16 : 18,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        tutorialContent.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? theme.primaryColor : theme.secondaryTextColor.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLastPage) {
                            _completeTutorial();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: theme.appBarGradient,
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
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isLastPage ? 'ابدأ الآن' : 'التالي',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FaIcon(
                                _isLastPage ? FontAwesomeIcons.check : FontAwesomeIcons.arrowLeft,
                                size: isMobile ? 18 : 20,
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
  }
}

// Custom PageRoute for Parallax Zoom Transition Animation
class ParallaxZoomPageRoute extends PageRouteBuilder {
  final String routeName;

  ParallaxZoomPageRoute({required this.routeName})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) {
      // Use the existing onGenerateRoute from MaterialApp
      final route = Navigator.of(context).widget.onGenerateRoute!(RouteSettings(name: routeName));
      // Extract the widget from the MaterialPageRoute's builder
      final builder = (route as MaterialPageRoute).builder;
      return builder(context);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final scale = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
            ),
          ).value;
          final opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
            ),
          ).value;
          final parallaxOffset = Tween<double>(begin: 50.0, end: 0.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
            ),
          ).value;

          return Stack(
            children: [
              // Parallax background with compound image
              Transform.translate(
                offset: Offset(parallaxOffset, parallaxOffset * 0.5),
                child: Transform.scale(
                  scale: scale * 1.2, // Slightly larger scale for background
                  child: Opacity(
                    opacity: opacity * 0.3, // Faded background
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage('https://i.ibb.co/Qj16SBg/wmremove-transformed-removebg-preview.png'),
                          fit: BoxFit.cover,
                          opacity: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Foreground content
              Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              ),
            ],
          );
        },
      );
    },
    transitionDuration: const Duration(milliseconds: 1000),
  );
}
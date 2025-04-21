import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/compound/homescreen/thememanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../core/config/supabase_config.dart';

class CompoundNewsPage extends StatefulWidget {
  const CompoundNewsPage({super.key});

  @override
  _CompoundNewsPageState createState() => _CompoundNewsPageState();
}

class _CompoundNewsPageState extends State<CompoundNewsPage> with TickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchNews(BuildContext context) async {
    final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
    try {
      final response = await supabaseConfig.secondaryClient
          .from('news')
          .select()
          .order('date', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل في جلب الأخبار. تحقق من الاتصال بالإنترنت.',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: isMobile ? 220 : 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: theme.appBarGradient,
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.newspaper,
                            size: isMobile ? 100 : 120,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ElasticIn(
                              duration: ThemeManager.animationDuration,
                              child: Text(
                                'أخبار الكمبوند',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 28 : 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeInDown(
                              duration: ThemeManager.animationDuration,
                              child: Text(
                                'تابع آخر أخبار وإعلانات الكمبوند',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 16 : 18,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeInUp(
                              duration: ThemeManager.animationDuration,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.cardBackground.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.cairo(fontSize: 16, color: theme.textColor),
                                  decoration: InputDecoration(
                                    hintText: 'ابحث في الأخبار...',
                                    hintStyle: GoogleFonts.cairo(color: theme.secondaryTextColor),
                                    prefixIcon: FaIcon(
                                      FontAwesomeIcons.magnifyingGlass,
                                      color: theme.primaryColor,
                                      size: 20,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                      icon: FaIcon(
                                        FontAwesomeIcons.xmark,
                                        color: theme.secondaryTextColor,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                leading: FadeInLeft(
                  duration: ThemeManager.animationDuration,
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRight,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'رجوع',
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(ThemeManager.cardPadding),
                sliver: SliverFillRemaining(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchNews(context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            snapshot.hasError ? 'خطأ في جلب الأخبار' : 'لا توجد أخبار متاحة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final filteredNews = snapshot.data!.where((news) {
                        final title = news['title']?.toString().toLowerCase() ?? '';
                        final description = news['description']?.toString().toLowerCase() ?? '';
                        final query = _searchQuery.toLowerCase();
                        return title.contains(query) || description.contains(query);
                      }).toList();

                      if (filteredNews.isEmpty) {
                        return Center(
                          child: Text(
                            'لا توجد أخبار مطابقة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isMobile ? 400 : 380,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: isMobile ? 0.9 : 0.85,
                        ),
                        itemCount: filteredNews.length,
                        itemBuilder: (context, index) {
                          final news = filteredNews[index];
                          return FadeInUp(
                            duration: Duration(milliseconds: 400 + (index * 150)),
                            child: NewsCard(
                              news: news,
                              cardColor: theme.cardColors[index % theme.cardColors.length],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsCard extends StatefulWidget {
  final Map<String, dynamic> news;
  final Color cardColor;

  const NewsCard({
    super.key,
    required this.news,
    required this.cardColor,
  });

  @override
  _NewsCardState createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius)),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return NewsDetailsBottomSheet(
          news: widget.news,
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context) {
    final imageUrl = widget.news['image_url']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final imageUrl = widget.news['image_url']?.toString();

    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          _showDetailsBottomSheet(context);
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: BorderRadius.circular(ThemeManager.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  widget.cardColor,
                  widget.cardColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  left: -30,
                  child: Opacity(
                    opacity: 0.06,
                    child: FaIcon(
                      FontAwesomeIcons.newspaper,
                      size: 120,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(ThemeManager.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              height: isMobile ? 100 : 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: isMobile ? 100 : 120,
                                color: theme.secondaryTextColor.withOpacity(0.2),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElasticIn(
                              duration: ThemeManager.animationDuration,
                              child: Text(
                                widget.news['title']?.toString() ?? 'غير معروف',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 22 : 24,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textColor,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          ZoomIn(
                            duration: ThemeManager.animationDuration,
                            child: CircleAvatar(
                              radius: isMobile ? 24 : 28,
                              backgroundColor: theme.primaryColor.withOpacity(0.1),
                              child: FaIcon(
                                FontAwesomeIcons.newspaper,
                                size: isMobile ? 22 : 26,
                                color: theme.primaryColor,
                                semanticLabel: 'أيقونة الأخبار',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.calendarAlt,
                              size: isMobile ? 18 : 20,
                              color: theme.primaryColor,
                              semanticLabel: 'تاريخ',
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.news['date']?.toString() ?? 'غير محدد',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 15 : 16,
                                  color: theme.secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Text(
                          widget.news['description']?.toString() ?? 'غير متوفر',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14 : 15,
                            color: theme.secondaryTextColor,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      FadeInUp(
                        duration: ThemeManager.animationDuration,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: theme.appBarGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(
                                FontAwesomeIcons.infoCircle,
                                size: isMobile ? 18 : 20,
                                color: Colors.white,
                                semanticLabel: 'التفاصيل',
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'التفاصيل',
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class NewsDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> news;

  const NewsDetailsBottomSheet({
    super.key,
    required this.news,
  });

  @override
  _NewsDetailsBottomSheetState createState() => _NewsDetailsBottomSheetState();
}

class _NewsDetailsBottomSheetState extends State<NewsDetailsBottomSheet> with TickerProviderStateMixin {
  late AnimationController _sheetController;
  late Animation<Offset> _sheetAnimation;
  late List<AnimationController> _buttonControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _translateAnimations;

  @override
  void initState() {
    super.initState();

    _sheetController = AnimationController(
      vsync: this,
      duration: ThemeManager.animationDuration,
    );
    _sheetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.decelerate),
    );

    _buttonControllers = List.generate(
      2,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _scaleAnimations = _buttonControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();
    _fadeAnimations = _buttonControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();
    _translateAnimations = _buttonControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 20),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    _sheetController.forward();
    for (int i = 0; i < _buttonControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 + (i * 50)), () {
        if (mounted) {
          _buttonControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    for (var controller in _buttonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _closeSheet() {
    for (var controller in _buttonControllers.reversed) {
      controller.reverse();
    }
    _sheetController.reverse().then((_) {
      Navigator.pop(context);
    });
  }

  Future<void> _shareNewsDetails() async {
    final title = widget.news['title']?.toString() ?? 'غير معروف';
    final description = widget.news['description']?.toString() ?? 'غير متوفر';
    final facebookUrl = widget.news['facebook_url']?.toString() ?? '';

    final shareText = '''
📰 خبر من جاردينيا توداي 📰
📢 $title
💬 $description
${facebookUrl.isNotEmpty ? 'لمزيد من التفاصيل: $facebookUrl' : ''}
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

    await Share.share(
      shareText.trim(),
      subject: 'خبر: $title',
    );
  }

  void _launchFacebookUrl() async {
    final facebookUrl = widget.news['facebook_url']?.toString();
    if (facebookUrl == null || facebookUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رابط فيسبوك متاح.',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse(facebookUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن فتح رابط الفيسبوك.',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFullScreenImage(BuildContext context) {
    final imageUrl = widget.news['image_url']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final imageUrl = widget.news['image_url']?.toString();

    return Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedBuilder(
        animation: _sheetController,
        builder: (context, child) {
      return SlideTransition(
        position: _sheetAnimation,
        child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.cardBackground,
                  theme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(ThemeManager.cardBorderRadius)),
            ),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: SingleChildScrollView(
                    child: AnimatedPadding(
                      duration: ThemeManager.animationDuration,
                      padding: EdgeInsets.only(
                        left: ThemeManager.cardPadding,
                        right: ThemeManager.cardPadding,
                        top: ThemeManager.cardPadding,
                        bottom: ThemeManager.cardPadding + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElasticIn(
                              duration: ThemeManager.animationDuration,
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: theme.primaryColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  widget.news['title']?.toString() ?? 'غير معروف',
                                  style: GoogleFonts.cairo(
                                    fontSize: isMobile ? 22 : 24,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          Spin(
                            duration: ThemeManager.animationDuration,
                            child: FloatingActionButton(
                              onPressed: _closeSheet,
                              backgroundColor: theme.accentColor,
                              mini: true,
                              child: const FaIcon(
                                FontAwesomeIcons.xmark,
                                color: Colors.white,
                                size: 20,
                              ),
                              tooltip: 'إغلاق',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                              if (imageUrl != null && imageUrl.isNotEmpty)
                              GestureDetector(
                              onTap: () => _showFullScreenImage(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: isMobile ? 150 : 200,
                            color: theme.secondaryTextColor.withOpacity(0.2),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 16),
            Text(
              widget.news['description']?.toString() ?? 'غير متوفر',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16 : 18,
                color: theme.secondaryTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.calendarAlt,
                  size: isMobile ? 18 : 20,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.news['date']?.toString() ?? 'غير محدد',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 15 : 16,
                    color: theme.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
              AnimatedBuilder(
              animation: _buttonControllers[0],
              builder: (context, child) {
                return Transform.translate(
                  offset: _translateAnimations[0].value,
                  child: FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: ScaleTransition(
                      scale: _scaleAnimations[0],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton(
                            onPressed: _shareNewsDetails,
                            backgroundColor: theme.accentColor,
                            elevation: 2,
                            child: FaIcon(
                              FontAwesomeIcons.share,
                              size: isMobile ? 24 : 28,
                              color: Colors.white,
                              semanticLabel: 'مشاركة الخبر',
                            ),
                            tooltip: 'مشاركة الخبر',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'مشاركة الخبر',
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (widget.news['facebook_url'] != null && widget.news['facebook_url'].isNotEmpty)
        AnimatedBuilder(
        animation: _buttonControllers[1],
        builder: (context, child) {
          return Transform.translate(
            offset: _translateAnimations[1].value,
            child: FadeTransition(
              opacity: _fadeAnimations[1],
              child: ScaleTransition(
                scale: _scaleAnimations[1],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      onPressed: _launchFacebookUrl,
                      backgroundColor: theme.primaryColor,
                      elevation: 2,
                      child: FaIcon(
                        FontAwesomeIcons.facebook,
                        size: isMobile ? 24 : 28,
                        color: Colors.white,
                        semanticLabel: 'الخبر على فيسبوك',
                      ),
                      tooltip: 'الخبر على فيسبوك',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الخبر على فيسبوك',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          ;

        }),
          ],
          ),
          ],
          ),
          ),
          ),
          const SizedBox(height: 16),
          ],
          ),
          ),
          ),
          ),
          ),
          );
        },
      ),
    );
  }
  }

  class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
  final theme = ThemeManager().currentTheme;

  return Scaffold(
  backgroundColor: Colors.black,
  body: SafeArea(
  child: Stack(
  children: [
  Center(
  child: InteractiveViewer(
  panEnabled: true,
  minScale: 0.5,
  maxScale: 4.0,
  child: Image.network(
  imageUrl,
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) => Center(
  child: FaIcon(
  FontAwesomeIcons.image,
  color: theme.secondaryTextColor,
  size: 60,
  ),
  ),
  loadingBuilder: (context, child, loadingProgress) {
  if (loadingProgress == null) return child;
  return Center(
  child: CircularProgressIndicator(
  color: theme.primaryColor,
  value: loadingProgress.expectedTotalBytes != null
  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
      : null,
  ),
  );
  },
  ),
  ),
  ),
  Positioned(
  top: 16,
  right: 16,
  child: FloatingActionButton(
  onPressed: () => Navigator.pop(context),
  backgroundColor: theme.accentColor,
  mini: true,
  child: const FaIcon(
  FontAwesomeIcons.xmark,
  color: Colors.white,
  size: 20,
  ),
  tooltip: 'إغلاق',
  ),
  ),
  ],
  ),
  ),
  );
  }
  }
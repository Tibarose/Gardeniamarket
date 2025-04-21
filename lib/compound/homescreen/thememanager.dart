import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import '../core/config/supabase_config.dart'; // For SupabaseConfig

class AppTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardBackground;
  final Color textColor;
  final Color secondaryTextColor;
  final List<Color> cardColors;
  final LinearGradient appBarGradient;

  AppTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardBackground,
    required this.textColor,
    required this.secondaryTextColor,
    required this.cardColors,
    required this.appBarGradient,
  });
}

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  AppTheme? _currentTheme;
  final ValueNotifier<ThemeData> themeNotifier = ValueNotifier<ThemeData>(ThemeData.light());
  RealtimeChannel? _subscription;

  // Default Theme (Sleek & Futuristic)
  final AppTheme defaultTheme = AppTheme(
    id: 'default',
    name: 'Default Theme',
    primaryColor: const Color(0xFF1E40AF),
    accentColor: const Color(0xFF22D3EE),
    backgroundColor: const Color(0xFFF9FAFB),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF111827),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFEFF6FF),
      Color(0xFFE6F4FF),
      Color(0xFFF3F4F6),
      Color(0xFFE6E8FF),
      Color(0xFFF0FDFA),
      Color(0xFFE5E7EB),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF1E40AF), Color(0xFF22D3EE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Ramadan Theme (Warm & Spiritual)
  final AppTheme ramadanTheme = AppTheme(
    id: 'ramadan',
    name: 'Ramadan Theme',
    primaryColor: const Color(0xFF065F46),
    accentColor: const Color(0xFFF59E0B),
    backgroundColor: const Color(0xFFFEFCE8),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1F2937),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFE6FFF4),
      Color(0xFFFFF7E6),
      Color(0xFFF5F5F5),
      Color(0xFFE6F0E6),
      Color(0xFFFFF0E6),
      Color(0xFFECE7E6),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF065F46), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Eid Theme (Festive & Radiant)
  final AppTheme eidTheme = AppTheme(
    id: 'eid',
    name: 'Eid Theme',
    primaryColor: const Color(0xFF14B8A6),
    accentColor: const Color(0xFFF87171),
    backgroundColor: const Color(0xFFECFDF5),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1E1E1E),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFE6FFFA),
      Color(0xFFFFE6E6),
      Color(0xFFF3F4F6),
      Color(0xFFE6F0FA),
      Color(0xFFF0FFF4),
      Color(0xFFE5E7EB),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF14B8A6), Color(0xFFF87171)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
// Banque Misr Theme (Red, White, Black with Gold Accents)
// Banque Misr Theme (Red, White, Black with Gold Accents)
  final AppTheme banquemisrTheme = AppTheme(
    id: 'banquemisr',
    name: 'Banque Misr Theme',
    primaryColor: const Color(0xFFBF3447), // Deep red (#bf3447)
    accentColor: const Color(0xFFDEA74A), // Gold (#dea74a)
    backgroundColor: const Color(0xFFEFEFEF), // Light grey (#efefef)
    cardBackground: const Color(0xFFFFFFFF), // White card background (consistent with screenshot)
    textColor: const Color(0xFF1F2937), // Dark text color (unchanged, matches screenshot)
    secondaryTextColor: const Color(0xFF6B7280), // Lighter grey for secondary text (unchanged)
    cardColors: const [
      Color(0xFFFFFFFF), // White for cards
      Color(0xFFFFFFFF), // Black for card backgrounds (like credit card)
      Color(0xFFFFFFFF), // Light grey (#efefef)
      Color(0xFFFFFFFF), // Gold (#dea74a)
      Color(0xFFFFFFFF), // Deep red (#bf3447)
      Color(0xFFFFFFFF), // Soft grey (kept for variety)
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFBF3447), Color(0xFFBE3447)], // Gradient from #bf3447 to #be3447
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );


  // Insurely Theme (Modern Purple & Pink Insurance Theme)
  final AppTheme insurelyTheme = AppTheme(
    id: 'insurely',
    name: 'Insurely Theme',
    primaryColor: const Color(0xFF6B5CF6), // Deep purple from cards and buttons
    accentColor: const Color(0xFFF06292), // Pinkish-purple for icons and highlights
    backgroundColor: const Color(0xFFF9FAFB), // Light grey/white background
    cardBackground: const Color(0xFFFFFFFF), // White card background
    textColor: const Color(0xFF1F2937), // Dark text color
    secondaryTextColor: const Color(0xFF6B7280), // Lighter grey for secondary text
    cardColors: const [
      Color(0xFFFFFFFF), // White for cards
      Color(0xFF6B5CF6), // Deep purple
      Color(0xFFF06292), // Pinkish-purple
      Color(0xFFF59E0B), // Orange for variety (from icons)
      Color(0xFFF3E8FF), // Light purple tint
      Color(0xFFECEFF1), // Soft grey for variety
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF6B5CF6), Color(0xFFF06292)], // Gradient from deep purple to pinkish-purple
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );// Mother's Day Theme (Soft & Romantic)
  final AppTheme mothersDayTheme = AppTheme(
    id: 'mothers_day',
    name: "Mother's Day Theme",
    primaryColor: const Color(0xFFF9A8D4),
    accentColor: const Color(0xFFA78BFA),
    backgroundColor: const Color(0xFFF5F3FF),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1F2937),
    secondaryTextColor: const Color(0xFF7C3AED),
    cardColors: const [
      Color(0xFFFDE6F2),
      Color(0xFFF3E8FF),
      Color(0xFFE6F4FF),
      Color(0xFFFFF0E6),
      Color(0xFFF5E8FF),
      Color(0xFFE6F0FA),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFF9A8D4), Color(0xFFA78BFA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Gardenia Theme (Updated: More Dark Green Colors)
  final AppTheme gardeniaTheme = AppTheme(
    id: 'gardenia',
    name: 'Gardenia City Theme',
    primaryColor: const Color(0xFF1A3C34), // Dark green from logo
    accentColor: const Color(0xFFA3E4D7), // Lighter green from logo
    backgroundColor: const Color(0xFF2E5A50), // Darker green background
    cardBackground: const Color(0xFF3A6B61), // Slightly lighter dark green for cards
    textColor: const Color(0xFFFFFFFF), // White text for contrast
    secondaryTextColor: const Color(0xFFA3E4D7), // Lighter green for secondary text
    cardColors: const [
      Color(0xFF1A3C34), // Dark green
      Color(0xFF2E5A50), // Slightly lighter dark green
      Color(0xFF3A6B61), // Another dark green shade
      Color(0xFF4A7C72), // Medium green shade
      Color(0xFFA3E4D7), // Lighter green from logo
      Color(0xFFE6F0FA), // Soft white-blue for variety
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF1A3C34), Color(0xFF2E5A50)], // Gradient with more dark green
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Vibrant Theme (Modern & Premium)
  final AppTheme vibrantTheme = AppTheme(
    id: 'vibrant',
    name: 'Vibrant Theme',
    primaryColor: const Color(0xFF4A00E0),
    accentColor: const Color(0xFF8E2DE2),
    backgroundColor: const Color(0xFFF8FAFC),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1A1A1A),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFF5F3FF),
      Color(0xFFF0FDFA),
      Color(0xFFFFF7F5),
      Color(0xFFF0FDF4),
      Color(0xFFFFFBEB),
      Color(0xFFEFF6FF),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Cosmic Theme (Mystical & Galactic)
  final AppTheme cosmicTheme = AppTheme(
    id: 'cosmic',
    name: 'Cosmic Theme',
    primaryColor: const Color(0xFF8B5CF6),
    accentColor: const Color(0xFF22D3EE),
    backgroundColor: const Color(0xFF0B0F19),
    cardBackground: const Color(0xFF1E293B),
    textColor: const Color(0xFFF9FAFB),
    secondaryTextColor: const Color(0xFFC4B5FD),
    cardColors: const [
      Color(0xFF2E1065),
      Color(0xFF0E7490),
      Color(0xFF1E1B4B),
      Color(0xFF4C1D95),
      Color(0xFF164E63),
      Color(0xFF312E81),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Modern & Minimal Theme
  final AppTheme modernMinimalTheme = AppTheme(
    id: 'modern_minimal',
    name: 'Modern & Minimal Theme',
    primaryColor: const Color(0xFF1A237E),
    accentColor: const Color(0xFF00BCD4),
    backgroundColor: const Color(0xFFFFFFFF),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF212121),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFE6E8FF),
      Color(0xFFF0FDFA),
      Color(0xFFF5F5F5),
      Color(0xFFE6F4FF),
      Color(0xFFF3F4F6),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Energetic & Youthful Theme
  final AppTheme energeticYouthfulTheme = AppTheme(
    id: 'energetic_youthful',
    name: 'Energetic & Youthful Theme',
    primaryColor: const Color(0xFFFF6F61),
    accentColor: const Color(0xFFFFEB3B),
    backgroundColor: const Color(0xFFFAFAFA),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF333333),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFFFF7F5),
      Color(0xFFFFFDEB),
      Color(0xFFF5F5F5),
      Color(0xFFFFE6E6),
      Color(0xFFF0FDFA),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFFF6F61), Color(0xFFFFEB3B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Eco & Wellness Theme
  final AppTheme ecoWellnessTheme = AppTheme(
    id: 'eco_wellness',
    name: 'Eco & Wellness Theme',
    primaryColor: const Color(0xFF388E3C),
    accentColor: const Color(0xFFA5D6A7),
    backgroundColor: const Color(0xFFF1F8E9),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF33691E),
    secondaryTextColor: const Color(0xFF78909C),
    cardColors: const [
      Color(0xFFF0FDF4),
      Color(0xFFF5F6E9),
      Color(0xFFE6FFF4),
      Color(0xFFF5F5F5),
      Color(0xFFE6F0E6),
      Color(0xFFF0FDFA),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF388E3C), Color(0xFFA5D6A7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Luxury & Elegance Theme
  final AppTheme luxuryEleganceTheme = AppTheme(
    id: 'luxury_elegance',
    name: 'Luxury & Elegance Theme',
    primaryColor: const Color(0xFF4A148C),
    accentColor: const Color(0xFFFFD700),
    backgroundColor: const Color(0xFF121212),
    cardBackground: const Color(0xFF1E1E1E),
    textColor: const Color(0xFFE0E0E0),
    secondaryTextColor: const Color(0xFFB0BEC5),
    cardColors: const [
      Color(0xFF2E1B4B),
      Color(0xFFFFF8E1),
      Color(0xFF2D2D2D),
      Color(0xFF4C1D95),
      Color(0xFF3B2E5A),
      Color(0xFF263238),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF4A148C), Color(0xFFFFD700)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Tech & Innovation Theme
  final AppTheme techInnovationTheme = AppTheme(
    id: 'tech_innovation',
    name: 'Tech & Innovation Theme',
    primaryColor: const Color(0xFF2962FF),
    accentColor: const Color(0xFF00E676),
    backgroundColor: const Color(0xFFFFFFFF),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF263238),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFE6F4FF),
      Color(0xFFE6FFF4),
      Color(0xFFF5F5F5),
      Color(0xFFF0FDFA),
      Color(0xFFECEFF1),
      Color(0xFFE6E8FF),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF2962FF), Color(0xFF00E676)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Celestial Glow Theme
  final AppTheme celestialGlowTheme = AppTheme(
    id: 'celestial_glow',
    name: 'Celestial Glow Theme',
    primaryColor: const Color(0xFF2C3E50),
    accentColor: const Color(0xFFF06292),
    backgroundColor: const Color(0xFF0D1B2A),
    cardBackground: const Color(0xFF1B263B),
    textColor: const Color(0xFFE0E0E0),
    secondaryTextColor: const Color(0xFFB39DDB),
    cardColors: const [
      Color(0xFFF3E8FF),
      Color(0xFFE6FFF4),
      Color(0xFFFFF0E6),
      Color(0xFFE6F4FF),
      Color(0xFFFFF7F5),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF2C3E50), Color(0xFFF06292)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Acacia Theme (Bright Yellow & Green)
  final AppTheme acaciaTheme = AppTheme(
    id: 'acacia',
    name: 'Acacia Theme',
    primaryColor: const Color(0xFFF4D03F),
    accentColor: const Color(0xFF27AE60),
    backgroundColor: const Color(0xFFFFF8E7),
    cardBackground: const Color(0xFFFDFCFA),
    textColor: const Color(0xFF2D3436),
    secondaryTextColor: const Color(0xFF636E72),
    cardColors: const [
      Color(0xFFFFF7E6),
      Color(0xFFE6FFF4),
      Color(0xFFF3F4F6),
      Color(0xFFFFF0E6),
      Color(0xFFE6F0E6),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFF4D03F), Color(0xFF27AE60)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Carnation Theme (Soft Pink & Coral)
  final AppTheme carnationTheme = AppTheme(
    id: 'carnation',
    name: 'Carnation Theme',
    primaryColor: const Color(0xFFF06292),
    accentColor: const Color(0xFFE57373),
    backgroundColor: const Color(0xFFFFF0F5),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF2D3436),
    secondaryTextColor: const Color(0xFFB2BEC3),
    cardColors: const [
      Color(0xFFFFE6E6),
      Color(0xFFF3E8FF),
      Color(0xFFF5F5F5),
      Color(0xFFFFF7F5),
      Color(0xFFE6F4FF),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFF06292), Color(0xFFE57373)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Violet Theme (Deep Purple & Lilac)
  final AppTheme violetTheme = AppTheme(
    id: 'violet',
    name: 'Violet Theme',
    primaryColor: const Color(0xFF8E44AD),
    accentColor: const Color(0xFFD7BDE2),
    backgroundColor: const Color(0xFFF3E8FF),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1F2937),
    secondaryTextColor: const Color(0xFFA29BFE),
    cardColors: const [
      Color(0xFFF5F3FF),
      Color(0xFFE6F4FF),
      Color(0xFFF3F4F6),
      Color(0xFFFFF0E6),
      Color(0xFFE6FFF4),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF8E44AD), Color(0xFFD7BDE2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Orchid Theme (Orchid Purple & Hot Pink)
  final AppTheme orchidTheme = AppTheme(
    id: 'orchid',
    name: 'Orchid Theme',
    primaryColor: const Color(0xFFDA70D6),
    accentColor: const Color(0xFFFF69B4),
    backgroundColor: const Color(0xFFFDFCFA),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF2D3436),
    secondaryTextColor: const Color(0xFFB2BEC3),
    cardColors: const [
      Color(0xFFF3E8FF),
      Color(0xFFFFE6E6),
      Color(0xFFF5F5F5),
      Color(0xFFE6F4FF),
      Color(0xFFFFF7F5),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFDA70D6), Color(0xFFFF69B4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Juliet Rose Theme (Peach & Gold)
  final AppTheme julietRoseTheme = AppTheme(
    id: 'juliet_rose',
    name: 'Juliet Rose Theme',
    primaryColor: const Color(0xFFFFB6A4),
    accentColor: const Color(0xFFFAD7A0),
    backgroundColor: const Color(0xFFFFF8E7),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1F2937),
    secondaryTextColor: const Color(0xFF636E72),
    cardColors: const [
      Color(0xFFFFF0E6),
      Color(0xFFFFF7E6),
      Color(0xFFF3F4F6),
      Color(0xFFE6FFF4),
      Color(0xFFE6F0FA),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFFFB6A4), Color(0xFFFAD7A0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Tulip Theme (Red & Pink)
  final AppTheme tulipTheme = AppTheme(
    id: 'tulip',
    name: 'Tulip Theme',
    primaryColor: const Color(0xFFE74C3C),
    accentColor: const Color(0xFFF1948A),
    backgroundColor: const Color(0xFFF7F9F9),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF2D3436),
    secondaryTextColor: const Color(0xFFB2BEC3),
    cardColors: const [
      Color(0xFFFFE6E6),
      Color(0xFFF3E8FF),
        Color(0xFFF5F5F5),
      Color(0xFFFFF7F5),
      Color(0xFFE6F4FF),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFE74C3C), Color(0xFFF1948A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Basil Theme (Green & Lavender)
  final AppTheme basilTheme = AppTheme(
    id: 'basil',
    name: 'Basil Theme',
    primaryColor: const Color(0xFF2ECC71),
    accentColor: const Color(0xFFD7BDE2),
    backgroundColor: const Color(0xFFF0FFF4),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1F2937),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFE6FFF4),
      Color(0xFFF0F4E6),
      Color(0xFFF3F4F6),
      Color(0xFFFFF0E6),
      Color(0xFFF5F3FF),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF2ECC71), Color(0xFFD7BDE2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Lotus Theme (Pink & White)
  final AppTheme lotusTheme = AppTheme(
    id: 'lotus',
    name: 'Lotus Theme',
    primaryColor: const Color(0xFFF8C8DC),
    accentColor: const Color(0xFFFFFFFF),
    backgroundColor: const Color(0xFFFFF0F5),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF2D3436),
    secondaryTextColor: const Color(0xFFB2BEC3),
    cardColors: const [
      Color(0xFFFFE6E6),
      Color(0xFFF3E8FF),
      Color(0xFFF5F5F5),
      Color(0xFFFFF7F5),
      Color(0xFFE6F4FF),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFF8C8DC), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Jasmine Theme (White & Green)
  final AppTheme jasmineTheme = AppTheme(
    id: 'jasmine',
    name: 'Jasmine Theme',
    primaryColor: const Color(0xFFF7F9F9),
    accentColor: const Color(0xFF27AE60),
    backgroundColor: const Color(0xFFFFF8E7),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1F2937),
    secondaryTextColor: const Color(0xFF6B7280),
    cardColors: const [
      Color(0xFFFFF7E6),
      Color(0xFFE6FFF4),
      Color(0xFFF3F4F6),
      Color(0xFFFFF0E6),
      Color(0xFFE6F0E6),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFF7F9F9), Color(0xFF27AE60)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Pansy Theme (Purple & Yellow)
  final AppTheme pansyTheme = AppTheme(
    id: 'pansy',
    name: 'Pansy Theme',
    primaryColor: const Color(0xFF8E44AD),
    accentColor: const Color(0xFFFFC107),
    backgroundColor: const Color(0xFFF7F9F9),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF2D3436),
    secondaryTextColor: const Color(0xFFB2BEC3),
    cardColors: const [
      Color(0xFFF5F3FF),
      Color(0xFFFFF7E6),
      Color(0xFFF3F4F6),
      Color(0xFFE6F4FF),
      Color(0xFFFFF0E6),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF8E44AD), Color(0xFFFFC107)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // Lavender Theme (Soft Purple & Lilac)
  final AppTheme lavenderTheme = AppTheme(
    id: 'lavender',
    name: 'Lavender Theme',
    primaryColor: const Color(0xFFB2B1CF),
    accentColor: const Color(0xFFE6E6FA),
    backgroundColor: const Color(0xFFF5F3FF),
    cardBackground: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF1F2937),
    secondaryTextColor: const Color(0xFFA29BFE),
    cardColors: const [
      Color(0xFFF5F3FF),
      Color(0xFFE6F4FF),
      Color(0xFFF3F4F6),
      Color(0xFFFFF0E6),
      Color(0xFFE6FFF4),
      Color(0xFFECEFF1),
    ],
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFB2B1CF), Color(0xFFE6E6FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  List<AppTheme> get availableThemes => [
    defaultTheme,
    ramadanTheme,
    eidTheme,
    mothersDayTheme,
    gardeniaTheme,
    vibrantTheme,
    cosmicTheme,
    modernMinimalTheme,
    energeticYouthfulTheme,
    ecoWellnessTheme,
    luxuryEleganceTheme,
    techInnovationTheme,
    celestialGlowTheme,
    acaciaTheme,
    carnationTheme,
    violetTheme,
    orchidTheme,
    julietRoseTheme,
    tulipTheme,
    basilTheme,
    lotusTheme,
    jasmineTheme,
    pansyTheme,
    lavenderTheme,
    banquemisrTheme, // Add the new theme here
    insurelyTheme, // Add the new theme here
  ];

  Future<void> initialize(BuildContext context) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('app_settings')
          .select('theme_id')
          .eq('setting_key', 'active_theme')
          .maybeSingle();
      final themeId = response?['theme_id'] as String? ?? 'default';
      await setTheme(context, themeId);

      // Subscribe to real-time updates
      _subscribeToThemeChanges(context);
    } catch (e) {
      print('Error fetching theme from Supabase: $e');
      _currentTheme = defaultTheme;
      _applyTheme();
      notifyListeners();
    }
  }

  Future<void> setTheme(BuildContext context, String themeId) async {
    if (!availableThemes.any((theme) => theme.id == themeId)) {
      print('Invalid theme ID: $themeId. Falling back to default.');
      _currentTheme = defaultTheme;
    } else {
      _currentTheme = availableThemes.firstWhere((theme) => theme.id == themeId);
    }

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient.from('app_settings').upsert({
        'setting_key': 'active_theme',
        'theme_id': themeId,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('Theme updated in Supabase: $themeId');
    } catch (e) {
      print('Error saving theme to Supabase: $e');
    }

    _applyTheme();
    notifyListeners(); // Notify ChangeNotifier listeners
  }

  void _applyTheme() {
    final theme = _currentTheme ?? defaultTheme;
    themeNotifier.value = ThemeData(
      primaryColor: theme.primaryColor,
      scaffoldBackgroundColor: theme.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.textColor,
        elevation: 0,
      ),
      textTheme: GoogleFonts.cairoTextTheme().apply(
        bodyColor: theme.textColor,
        displayColor: theme.textColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: theme.textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(100, 0),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: theme.primaryColor,
        secondary: theme.accentColor,
        surface: theme.cardBackground,
        onSurface: theme.textColor,
      ).copyWith(brightness: theme.backgroundColor.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: theme.secondaryTextColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        color: theme.cardBackground,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.secondaryTextColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.cairo(color: theme.secondaryTextColor.withOpacity(0.6), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _subscribeToThemeChanges(BuildContext context) {
    final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
    _subscription?.unsubscribe();
    _subscription = supabaseConfig.secondaryClient
        .channel('app_settings')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'app_settings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'setting_key',
        value: 'active_theme',
      ),
      callback: (payload) {
        supabaseConfig.secondaryClient
            .from('app_settings')
            .select('theme_id')
            .eq('setting_key', 'active_theme')
            .maybeSingle()
            .then((response) {
          final themeId = response?['theme_id'] as String? ?? 'default';
          setTheme(context, themeId);
          print('Real-time theme update: $themeId');
        });
      },
    )
        .subscribe();
  }

  Future<void> dispose() async {
    _subscription?.unsubscribe();
    notifyListeners();
  }

  AppTheme get currentTheme => _currentTheme ?? defaultTheme;

  static const double cardPadding = 20.0;
  static const double cardBorderRadius = 24.0;
  static const Duration animationDuration = Duration(milliseconds: 400);
}
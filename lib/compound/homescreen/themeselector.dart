import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // For SupabaseConfig
import '../core/config/supabase_config.dart';
import 'thememanager.dart';

class ThemeSelectorScreen extends StatefulWidget {
  const ThemeSelectorScreen({super.key});

  @override
  _ThemeSelectorScreenState createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen> {
  String? _selectedTheme;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentTheme();
  }

  Future<void> _fetchCurrentTheme() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('app_settings')
          .select('theme_id')
          .eq('setting_key', 'active_theme')
          .maybeSingle();
      setState(() {
        _selectedTheme = response?['theme_id'] as String? ?? 'default';
      });
    } catch (e) {
      print('Error fetching current theme: $e');
      setState(() {
        _selectedTheme = 'default';
      });
    }
  }

  Future<void> _updateTheme(String themeId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ThemeManager().setTheme(context, themeId);
      setState(() {
        _selectedTheme = themeId;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Theme updated to $themeId')),
      );
    } catch (e) {
      print('Error updating theme: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update theme')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final availableThemes = ThemeManager().availableThemes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'اختيار الثيم',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: theme.appBarGradient,
            ),
          ),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر الثيم النشط',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTheme,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardBackground,
                ),
                items: availableThemes
                    .map((t) => DropdownMenuItem(
                  value: t.id,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: t.appBarGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.name,
                        style: GoogleFonts.cairo(
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateTheme(value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../customerapp/auth_provider.dart';
import '../customerapp/register.dart';
import 'homescreen/thememanager.dart';

class OnlineSupermarketSection extends StatelessWidget {
  final bool isMobile;

  const OnlineSupermarketSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    // Access the AuthProvider to check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Check if the user is authenticated
    final isAuthenticated = authProvider.isAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سوبر ماركت إلكتروني',
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.textColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Center(
            child: Container(
              width: isMobile ? double.infinity : 400,
              decoration: BoxDecoration(
                color: theme.cardColors[0],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: const FaIcon(
                        FontAwesomeIcons.cartShopping,
                        size: 28,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تسوق أونلاين',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'قريباً',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: theme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (!isAuthenticated) {
                          // Navigate to RegisterPage for unauthenticated users
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        } else {
                          // Show a snackbar for authenticated users
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'شكرا لتسجيلك! السوبر ماركت قيد التطوير وسيتم إتاحته قريباً',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              backgroundColor: theme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(200, 48), // Ensure button width accommodates long text
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        child: Text(
                          isAuthenticated
                              ? 'شكرا لتسجيلك سيتم اتاحه السوبر ماركت قريبا'
                              : ' سجل الآن وكن من اول المستفيدين من السوبر ماركت',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 13 : 14, // Adjusted for long text
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
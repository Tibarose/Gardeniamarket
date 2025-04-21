import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/compound/homescreen/thememanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import '../adminpane/addbusinessrequests.dart';
import '../adminpane/adminpanel.dart';
import '../adminpane/managecatousal.dart';
import '../adminpane/managesupermarket.dart';
import '../renthouse/SellApartmentsPage.dart';
import '../renthouse/renthoues.dart';
import '../renthouse/test.dart';

class OnlineServicesSection extends StatelessWidget {
  const OnlineServicesSection({super.key, required this.isMobile});

  final bool isMobile;

  static const List<Map<String, dynamic>> onlineServices = [
    {
      'title': 'ايجار الشقق',
      'subtitle': 'اضافه والاطلاع على الشقق المتاحه للايجار',
      'imageUrl': 'https://cdn3d.iconscout.com/3d/premium/thumb/rent-house-3d-icon-download-in-png-blend-fbx-gltf-file-formats--real-estate-business-pack-icons-6148259.png',
      'backgroundColor': Color(0xFFE3F2FD),
    },
    {
      'title': 'بيع الشقق',
      'subtitle': 'اضافه والاطلاع على الشقق المتاحه للبيع',
      'imageUrl': 'https://cdn3d.iconscout.com/3d/premium/thumb/buy-house-3d-icon-download-in-png-blend-fbx-gltf-file-formats--for-sale-real-estate-home-homes-property-pack-buildings-icons-6184500.png', // Different icon for selling apartments
      'backgroundColor': Color(0xFFFCE4EC),
    },
   {
      'title': 'العقارات',
      'subtitle': 'اضافه والاطلاع على الشقق المتاحه للبيع',
      'imageUrl': 'https://cdn3d.iconscout.com/3d/premium/thumb/buy-house-3d-icon-download-in-png-blend-fbx-gltf-file-formats--for-sale-real-estate-home-homes-property-pack-buildings-icons-6184500.png', // Different icon for selling apartments
      'backgroundColor': Color(0xFFFCE4EC),
    },

  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ايجار- بيع شقق',
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textColor,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'سيتم عرض جميع الخدمات الأونلاين قريبًا',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                    ),
                    backgroundColor: theme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'عرض الكل',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    size: 14,
                    color: theme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: onlineServices.length,
            itemBuilder: (context, index) {
              final service = onlineServices[index];
              return FadeInRight(
                duration: Duration(milliseconds: 400 + (index * 150)),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (service['title'] == 'ايجار الشقق') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RentHousesPage(),
                          ),
                        );
                      } else if (service['title'] == 'بيع الشقق') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SellApartmentsPage(),
                          ),
                        );
                      } else if (service['title'] == 'العقارات') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPanelPage(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'سيتم عرض تفاصيل ${service['title']} قريبًا',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                            ),
                            backgroundColor: theme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 6),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 160,
                            decoration: BoxDecoration(
                              color: service['backgroundColor'],
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                            ),
                            child: Center(
                              child: Image.network(
                                service['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => FaIcon(
                                  FontAwesomeIcons.exclamationCircle,
                                  color: theme.secondaryTextColor.withOpacity(0.5),
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    service['title'],
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textColor,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    service['subtitle'],
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: theme.secondaryTextColor.withOpacity(0.8),
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'استكشف',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
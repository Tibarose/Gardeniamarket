import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/bottombar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class OrderConfirmationPage extends StatelessWidget {
  final List<Map<String, dynamic>> orderItems;
  final double subtotal;
  final double deliveryFee;
  final double tipAmount;
  final double discount;
  final double finalTotal;
  final Color awesomeColor;
  final int loyaltyPoints; // New parameter

  const OrderConfirmationPage({
    required this.orderItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.tipAmount,
    required this.discount,
    required this.finalTotal,
    required this.awesomeColor,
    required this.loyaltyPoints, // Added to constructor
    super.key,
  });

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => BottomNavigation(initialTab: tabIndex),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate a consistent width based on screen size, leaving some padding
    final cardWidth = MediaQuery.of(context).size.width - 32; // 16 padding on each side

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [awesomeColor.withOpacity(0.05), Colors.grey[100]!],
              ),
            ),
            child: Column(
              children: [
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header Section with Card
                          ZoomIn(
                            duration: const Duration(milliseconds: 600),
                            child: Container(
                              width: cardWidth,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: awesomeColor.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Bounce(
                                    duration: const Duration(milliseconds: 800),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: awesomeColor.withOpacity(0.1),
                                        border: Border.all(color: awesomeColor.withOpacity(0.4)),
                                      ),
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 50,
                                        color: awesomeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'تم الطلب بنجاح!',
                                    style: GoogleFonts.cairo(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'شكراً لتسوقك معنا',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Order Items Section
                          Container(
                            width: cardWidth,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: orderItems.map((item) {
                                    return FadeInUp(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Container(
                                          width: 230,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  item['image'],
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.image_not_supported,
                                                        size: 24, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      item['name'],
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'الكمية: ${item['quantity']}',
                                                      style: GoogleFonts.cairo(
                                                          fontSize: 13, color: Colors.grey[600]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${item['subtotal'].toStringAsFixed(2)} ج.م',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: awesomeColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Price Summary Section
                          Container(
                            width: cardWidth,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildPriceRow('المجموع الفرعي', subtotal, Colors.grey[700]!),
                                const SizedBox(height: 8),
                                _buildPriceRow('رسوم التوصيل', deliveryFee, Colors.grey[700]!),
                                if (discount > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildPriceRow('الخصم', -discount, Colors.green),
                                ],
                                if (tipAmount > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildPriceRow('إكرامية المندوب', tipAmount, Colors.grey[700]!),
                                ],
                                const SizedBox(height: 10),
                                Divider(color: Colors.grey[200], thickness: 1),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'الإجمالي',
                                      style: GoogleFonts.cairo(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '${finalTotal.toStringAsFixed(2)} ج.م',
                                      style: GoogleFonts.cairo(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: awesomeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed Buttons
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _navigateToTab(context, 3),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: awesomeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: Text(
                          'تتبع الطلب',
                          style: GoogleFonts.cairo(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _navigateToTab(context, 0),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: awesomeColor, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'العودة إلى المتجر',
                          style: GoogleFonts.cairo(fontSize: 17, color: awesomeColor, fontWeight: FontWeight.w600),
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

  Widget _buildPriceRow(String label, double amount, Color textColor, {bool isPoints = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 16, color: textColor),
        ),
        Text(
          isPoints
              ? '$amount نقاط' // Display as points
              : '${amount < 0 ? '-' : ''}${amount.abs().toStringAsFixed(2)} ج.م', // Display as currency
          style: GoogleFonts.cairo(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
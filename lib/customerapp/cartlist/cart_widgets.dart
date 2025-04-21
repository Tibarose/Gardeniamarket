import 'package:flutter/material.dart';
import 'package:gardeniamarket/customerapp/cartlist/cartprovider.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentOptionButton extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color awesomeColor;

  const PaymentOptionButton({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.awesomeColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? awesomeColor.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? awesomeColor : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: isSelected ? awesomeColor : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: awesomeColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class DeliverySection extends StatelessWidget {
  final String? deliveryAddress;

  const DeliverySection({
    required this.deliveryAddress,

    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,

      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('عنوان التوصيل',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryAddress ?? 'جارٍ التحميل...',
                        style: GoogleFonts.cairo(
                            fontSize: 16, color: deliveryAddress != null ? Colors.black87 : Colors.grey[500]),
                      ),

                    ],
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSection extends StatelessWidget {
  final String? selectedPaymentMethod;
  final ValueChanged<String?> onPaymentChanged;

  const PaymentSection({
    required this.selectedPaymentMethod,
    required this.onPaymentChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,

      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('طريقة الدفع',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            const SizedBox(height: 12),
            Column(
              children: [
                PaymentOptionButton(
                  value: 'cash',
                  label: 'نقدًا عند التسليم',
                  isSelected: selectedPaymentMethod == 'cash',
                  onTap: () => onPaymentChanged('cash'),
                  awesomeColor: AppConstants.awesomeColor,
                ),
                PaymentOptionButton(
                  value: 'instapay',
                  label: 'إنستاباي',
                  isSelected: selectedPaymentMethod == 'instapay',
                  onTap: () => onPaymentChanged('instapay'),
                  awesomeColor: AppConstants.awesomeColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PriceSummary extends StatelessWidget {
  final CartProvider cartProvider;
  final double deliveryFee;
  final double tipAmount;
  final double finalTotal;

  const PriceSummary({
    required this.cartProvider,
    required this.deliveryFee,
    required this.tipAmount,
    required this.finalTotal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,

      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ملخص السعر',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            const SizedBox(height: 12),
            _buildPriceRow('المجموع الفرعي', cartProvider.totalPriceBeforeOffer),
            if (cartProvider.offerDiscount > 0)
              _buildPriceRow('خصم العروض', -cartProvider.offerDiscount, color: Colors.red),
            _buildPriceRow('رسوم التوصيل', deliveryFee),
            if (cartProvider.discount > 0) _buildPriceRow('الخصم', -cartProvider.discount, color: Colors.green),
            if (tipAmount > 0) _buildPriceRow('إكرامية المندوب', tipAmount),
            const Divider(height: 20),
            _buildPriceRow('المجموع الكلي', finalTotal, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
                fontSize: isTotal ? 18 : 16,
                color: color ?? Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            '${amount >= 0 ? '' : '-'}${amount.abs().toStringAsFixed(2)} ج.م',
            style: GoogleFonts.cairo(
                fontSize: isTotal ? 18 : 16,
                color: color ?? Colors.black87,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}

class CheckoutFooter extends StatelessWidget {
  final double finalTotal;
  final VoidCallback? onCheckout;
  final bool hasUnavailableItems;

  const CheckoutFooter({
    required this.finalTotal,
    required this.onCheckout,
    required this.hasUnavailableItems,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المجموع الكلي',
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
              Text('${finalTotal.toStringAsFixed(2)} ج.م',
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.awesomeColor)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: hasUnavailableItems
                ? null
                : onCheckout, // Disable button if there are unavailable items
            style: ElevatedButton.styleFrom(
              backgroundColor: hasUnavailableItems ? Colors.grey : AppConstants.awesomeColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              hasUnavailableItems ? 'أزل المنتجات غير المتاحة' : 'تنفيذ الطلب',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuantityControlss extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final int maxQuantity;
  final Color awesomeColor;

  const QuantityControlss({
    required this.quantity,
    required this.onQuantityChanged,
    required this.maxQuantity,
    required this.awesomeColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (maxQuantity == 0) {
      return Text(
        'نفدت الكمية',
        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (quantity > 0)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 26),
            color: awesomeColor,
            onPressed: () => onQuantityChanged(quantity - 1),
          ),
        if (quantity > 0)
          Text(
            '$quantity',
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: awesomeColor),
          ),
        IconButton(
          icon: Icon(
            quantity == 0 ? Icons.add_shopping_cart : Icons.add_circle_outline,
            size: 26,
            color: quantity < maxQuantity ? awesomeColor : Colors.grey[400],
          ),
          onPressed: quantity < maxQuantity ? () => onQuantityChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}
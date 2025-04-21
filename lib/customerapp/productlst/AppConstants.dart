import 'package:flutter/material.dart';

class AppConstants {
  static const Color awesomeColor = Color(0xFF6A1B9A);
  static const Color categoryColor = Color(0xFF28A745);
  static const Color gradientStart = Color(0xFF6A1B9A);
  static const Color gradientEnd = Color(0xFF9C27B0);
  static const String supabaseUsersTable = 'users';
  static const String supabaseCartsTable = 'carts';
  static const String supabaseProductsTable = 'products';
  static const String supabaseOrdersTable = 'orders';
  static const String supabasePromoCodesTable = 'promo_codes';
  static const String supabaseCompoundsTable = 'compounds';
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const List<Color> cardColors = [
    Color(0xFFF8BBD0),
    Color(0xFFD1C4E9),
    Color(0xFFB3E5FC),
    Color(0xFFFFF9C4),
    Color(0xFFC8E6C9),
    Color(0xFFFFCDD2),

  ];
  static const int pageSize = 20;
  static const String productsTable = 'products';
  static const String cartsTable = 'carts';
  static const String favoritesTable = 'favorites';
  static const String usersTable = 'users';
  static const String metadataTable = 'metadata';
  static const String searchHint = 'ابحث عن منتج...';
  static const String noProductsMessage = 'لا توجد منتجات';
  static const String noCategoriesMessage = 'لا توجد فئات تحتوي على منتجات';

}
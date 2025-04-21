import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
final Set<String> _favorites = {};

Set<String> get favorites => _favorites;

FavoritesProvider() {
_loadFavorites();
}

Future<void> _loadFavorites() async {
final prefs = await SharedPreferences.getInstance();
final favoriteList = prefs.getStringList('favorites') ?? [];
_favorites.addAll(favoriteList);
notifyListeners();
}

Future<void> toggleFavorite(String serviceName) async {
if (_favorites.contains(serviceName)) {
_favorites.remove(serviceName);
} else {
_favorites.add(serviceName);
}
final prefs = await SharedPreferences.getInstance();
await prefs.setStringList('favorites', _favorites.toList());
notifyListeners();
}

Future<void> clearFavorites() async {
_favorites.clear();
final prefs = await SharedPreferences.getInstance();
await prefs.setStringList('favorites', []);
notifyListeners();
}
}

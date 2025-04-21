import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _currentUserId;
  bool _isLoading = false;

  AuthProvider() {
    _loadSavedSession();
  }

  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _currentUserId != null;
  bool get isLoading => _isLoading;
  SupabaseClient get supabase => Supabase.instance.client;

  Future<void> _loadSavedSession() async {
    _setLoading(true);
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('currentUserId');
    if (savedUserId != null) {
      _currentUserId = savedUserId;
      notifyListeners();
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', userId);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signUp({
    required String mobileNumber,
    required String password,
    String? name,
    String? buildingNumber,
    String? apartmentNumber,
    String? compoundId,
  }) async {
    try {
      _setLoading(true);
      final hashedPassword = _hashPassword(password);

      final existingUser = await supabase
          .from('users')
          .select()
          .eq('mobile_number', mobileNumber)
          .maybeSingle();

      if (existingUser != null) {
        throw AuthException('رقم الهاتف مسجل بالفعل');
      }

      final response = await supabase.from('users').insert({
        'mobile_number': mobileNumber,
        'password': hashedPassword,
        'name': name,
        'building_number': buildingNumber,
        'apartment_number': apartmentNumber,
        'compound_id': compoundId,
      }).select().single();

      _currentUserId = response['id'].toString();
      await _saveSession(_currentUserId!);
      notifyListeners();
    } catch (e) {
      throw AuthException('فشل التسجيل: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({required String mobileNumber, required String password}) async {
    try {
      _setLoading(true);
      final hashedPassword = _hashPassword(password);

      final response = await supabase
          .from('users')
          .select()
          .eq('mobile_number', mobileNumber)
          .eq('password', hashedPassword)
          .maybeSingle();

      if (response == null) {
        throw AuthException('رقم الهاتف أو كلمة المرور غير صحيحة');
      }

      _currentUserId = response['id'].toString();
      await _saveSession(_currentUserId!);
      notifyListeners();
    } catch (e) {
      throw AuthException('فشل تسجيل الدخول: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _currentUserId = null;
    await _clearSession();
    notifyListeners();
    _setLoading(false);
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    if (_currentUserId == null) return null;
    try {
      final response = await supabase
          .from('users')
          .select('name, mobile_number, building_number, apartment_number, compound_id, compounds(name, delivery_fee)')
          .eq('id', _currentUserId!)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
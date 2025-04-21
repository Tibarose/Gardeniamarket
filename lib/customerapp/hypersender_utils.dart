import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsAppUtils {
  static const String _baseUrl = 'https://waapi-fly.fly.dev';
  static const String _loginEndpoint = '/login';
  static const String _sendEndpoint = '/send';
  static const String _username = 'HardenedSecureAdmin2025';
  static const String _password = 'S3cur3P@ssw0rd!2025';

  // Retry configuration
  static const int _maxRetries = 3;
  static const int _retryDelayMs = 2000;

  /// Fetches a JWT token from the Fly.io API with retry logic
  static Future<String> _getToken({int retryCount = 0}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_loginEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': _username,
          'password': _password,
        }),
      );

      print('Login response (Attempt ${retryCount + 1}): ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          return data['token'] as String;
        }
        throw Exception('Token not found in response');
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching token (Attempt ${retryCount + 1}): $e');
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(milliseconds: _retryDelayMs));
        return _getToken(retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  /// Validates and sanitizes mobile number
  static String _sanitizeMobile(String mobile) {
    String cleanMobile = mobile.replaceAll(RegExp(r'[+\-\s]'), '');
    // Ensure it starts with country code (e.g., +20 for Egypt or 2)
    if (!cleanMobile.startsWith(RegExp(r'[0-9]{1,3}'))) {
      cleanMobile = '20$cleanMobile'; // Default to Egypt (+20) if no country code
    }
    if (cleanMobile.length != 12 && cleanMobile.length != 11) { // e.g., +201234567890 or 01234567890
      throw Exception('Invalid mobile number format: $mobile');
    }
    return cleanMobile;
  }

  /// Sends OTP via Fly.io WhatsApp API with retry logic
  static Future<void> sendOtpViaWhatsApp(String mobile, String otp, {int retryCount = 0}) async {
    try {
      print('Input mobile: $mobile');
      final cleanMobile = _sanitizeMobile(mobile);
      print('Clean mobile: $cleanMobile');

      // Get token
      final token = await _getToken();

      final payload = {
        'number': cleanMobile,
        'message': '🌟 اهلا بك فى جاردينيا ماركت 🌟\nكود التحقق الخاص بك هو:\n🔒 $otp 🔒',
      };

      print('Sending payload: $payload');

      final response = await http.post(
        Uri.parse('$_baseUrl$_sendEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print('WhatsApp response (Attempt ${retryCount + 1}): ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('OTP sent successfully to $cleanMobile');
          return;
        }
        throw Exception('Send failed: ${response.body}');
      } else if (response.statusCode == 403) {
        throw Exception('Invalid token. Please try again.');
      } else if (response.statusCode == 503) {
        throw Exception('Server not ready: ${response.body}');
      } else {
        throw Exception('Send failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending OTP via WhatsApp (Attempt ${retryCount + 1}): $e');
      if ((e.toString().contains('Failed to fetch') || e.toString().contains('SocketException')) && retryCount < _maxRetries) {
        await Future.delayed(Duration(milliseconds: _retryDelayMs));
        return sendOtpViaWhatsApp(mobile, otp, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }
}
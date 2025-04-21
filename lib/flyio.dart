import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardeniamarket/customerapp/productlst/AppConstants.dart';

import 'customerapp/hypersender_utils.dart';

class FlyInstanceManager extends StatefulWidget {
  const FlyInstanceManager({super.key});

  @override
  _FlyInstanceManagerState createState() => _FlyInstanceManagerState();
}

class _FlyInstanceManagerState extends State<FlyInstanceManager> {
  bool isLoading = false;
  String machineStatus = 'جارٍ التحقق...';
  String whatsappStatus = 'جارٍ التحقق...';
  String lastError = '';
  String? flyApiToken;
  final appName = 'waapi-fly';
  final machineId = '7815601f935978';
  final testNumber = '+201011937796';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flyApiToken = dotenv.env['FLY_API_TOKEN'];
      if (flyApiToken == null || flyApiToken!.isEmpty) {
        setState(() {
          lastError = 'لم يتم العثور على FLY_API_TOKEN';
          machineStatus = 'خطأ';
          isLoading = false;
        });
        return;
      }
      _promptAdminLogin();
    });
  }

  Future<void> _promptAdminLogin() async {
    String? password = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تسجيل دخول المشرف', style: GoogleFonts.cairo()),
        content: TextField(
          obscureText: true,
          decoration: InputDecoration(labelText: 'كلمة المرور'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (password == 'admin123') {
      setState(() => _isAuthenticated = true);
      _checkInstanceStatus();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _checkInstanceStatus() async {
    if (!_isAuthenticated) return;

    setState(() {
      isLoading = true;
      machineStatus = 'جارٍ التحقق...';
      whatsappStatus = 'جارٍ التحقق...';
      lastError = '';
    });

    try {
      final machineResponse = await http.post(
        Uri.parse('https://api.fly.io/graphql'),
        headers: {
          'Authorization': 'Bearer $flyApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': '''
            query {
              app(name: "$appName") {
                machines {
                  nodes {
                    id
                    state
                    updatedAt
                  }
                }
              }
            }
          ''',
        }),
      );

      print('Fly.io response: ${machineResponse.statusCode} - ${machineResponse.body}');

      if (machineResponse.statusCode == 200) {
        final data = jsonDecode(machineResponse.body);
        final machines = data['data']['app']['machines']['nodes'];
        final machine = machines.firstWhere(
              (m) => m['id'] == machineId,
          orElse: () => null,
        );
        if (machine != null) {
          machineStatus = machine['state'] == 'started' ? 'يعمل' : machine['state'];
        } else {
          machineStatus = 'غير موجود';
          lastError = 'الجهاز $machineId غير موجود';
        }
      } else {
        machineStatus = 'خطأ';
        lastError = 'فشل التحقق: ${machineResponse.body}';
      }

      try {
        final qrResponse = await http.get(
          Uri.parse('${dotenv.env['WA_API_URL']}/qr'),
          headers: {'Accept': 'application/json'},
        );

        print('WhatsApp QR response: ${qrResponse.statusCode} - ${qrResponse.body}');

        if (qrResponse.statusCode == 200 && jsonDecode(qrResponse.body).containsKey('qr')) {
          whatsappStatus = 'يحتاج مسح QR';
        } else {
          final testOtp = 'CHECK${DateTime.now().millisecondsSinceEpoch % 10000}';
          await WhatsAppUtils.sendOtpViaWhatsApp(testNumber, testOtp);
          whatsappStatus = 'يعمل';
        }
      } catch (e) {
        whatsappStatus = 'غير متصل';
        lastError += '\nواتساب: $e';
      }
    } catch (e) {
      machineStatus = 'خطأ';
      lastError = 'خطأ عام: $e';
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _restartMachine() async {
    if (!_isAuthenticated) return;

    setState(() {
      isLoading = true;
      lastError = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.fly.io/graphql'),
        headers: {
          'Authorization': 'Bearer $flyApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': '''
            mutation {
              restartMachine(input: { appId: "$appName", id: "$machineId" }) {
                machine {
                  id
                  state
                }
              }
            }
          ''',
        }),
      );

      print('Restart response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 && jsonDecode(response.body)['data'] != null) {
        _showSnackBar('تم إعادة تشغيل الجهاز بنجاح!');
        await _checkInstanceStatus();
      } else {
        lastError = 'فشل إعادة التشغيل: ${response.body}';
      }
    } catch (e) {
      lastError = 'خطأ في إعادة التشغيل: $e';
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _redeployApp() async {
    if (!_isAuthenticated) return;

    setState(() {
      isLoading = true;
      lastError = '';
    });

    try {
      await _restartMachine();
      _showSnackBar('تم تحديث التطبيق بنجاح!');
    } catch (e) {
      lastError = 'خطأ في التحديث: $e';
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            'إدارة الخادم',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          offset: const Offset(4, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud, size: 60, color: AppConstants.awesomeColor),
                        const SizedBox(height: 16),
                        Text(
                          'حالة الخادم',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'حالة الجهاز:',
                              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              machineStatus,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: machineStatus == 'يعمل' ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'حالة واتساب:',
                              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              whatsappStatus,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: whatsappStatus == 'يعمل' ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (lastError.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'خطأ: $lastError',
                            style: GoogleFonts.cairo(fontSize: 14, color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? CircularProgressIndicator(color: AppConstants.awesomeColor)
                      : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _checkInstanceStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppConstants.gradientStart, AppConstants.gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.awesomeColor.withOpacity(0.4),
                                spreadRadius: 2,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          child: Text(
                            'تحقق من الحالة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _restartMachine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppConstants.gradientStart, AppConstants.gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.awesomeColor.withOpacity(0.4),
                                spreadRadius: 2,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          child: Text(
                            'إعادة تشغيل الخادم',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _redeployApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppConstants.gradientStart, AppConstants.gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.awesomeColor.withOpacity(0.4),
                                spreadRadius: 2,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          child: Text(
                            'تحديث التطبيق',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
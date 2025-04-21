import 'dart:html' as html;
import 'dart:js' as js;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardeniamarket/customerapp/cartlist/cartprovider.dart';
import 'package:gardeniamarket/customerapp/productlst/CategoryProductsPage.dart';
import 'package:gardeniamarket/marketadmin/Delieveryguy.dart';
import 'package:gardeniamarket/marketadmin/ManageUsersPage.dart';
import 'package:gardeniamarket/marketadmin/landingpage.dart';
import 'package:gardeniamarket/marketadmin/managecarousal.dart';
import 'package:gardeniamarket/marketadmin/orders.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'compound/TutorialScreens.dart';
import 'compound/adminpane/adminpanel.dart';
import 'compound/core/config/supabase_config.dart';
import 'compound/entrypoint.dart';
import 'compound/forgetpassword.dart';
import 'compound/home_screen.dart';
import 'compound/homescreen/favouritenotify.dart';
import 'compound/homescreen/thememanager.dart';
import 'compound/homescreen/themeselector.dart';
import 'compound/renthouse/renthoues.dart';
import 'compound/resturantscreen.dart';
import 'customerapp/auth_provider.dart';
import 'customerapp/bottombar.dart';
import 'customerapp/market.dart';
import 'customerapp/register.dart';
import 'customerapp/login.dart';
import 'marketadmin/managecategory.dart';
import 'marketadmin/productmanagment.dart';
import 'compound/pharmacy.dart';
import 'compound/supermarket.dart';
import 'compound/water.dart';
import 'compound/ATM.dart';
import 'compound/Edara.dart';
import 'compound/backery.dart';
import 'compound/banks.dart';
import 'compound/building.dart';
import 'compound/electricity.dart';
import 'compound/fruits.dart';
import 'compound/gates.dart';
import 'compound/gaz.dart';
import 'compound/mosques.dart';
import 'compound/nursury.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log: Start of main initialization
  print('DEBUG: Starting main initialization');

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
  print('DEBUG: SharedPreferences initialized, hasSeenTutorial: $hasSeenTutorial');

  // Supabase credentials
  const String supabaseUrl = 'https://wrnawucrpcpkoasdmhhd.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndybmF3dWNycGNwa29hc2RtaGhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4NzU4NzksImV4cCI6MjA1OTQ1MTg3OX0.nagaHjI0byOvIaO58j8j2cFXMdCa-42NcXVh7Q5r1eI';
  const String secondarySupabaseUrl = 'https://bzqzwkpnskkkiuabrjvh.supabase.co';
  const String secondarySupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ6cXp3a3Buc2tra2l1YWJyanZoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2NTU5NjYsImV4cCI6MjA2MDIzMTk2Nn0.5M-eUWxZO-MH5R06vDVJxgGJjAXVDrGtElCfZiOgLZc';

  // Initialize Supabase
  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('DEBUG: Supabase initialized successfully');
  } catch (e, stackTrace) {
    print('DEBUG: Error initializing Supabase: $e');
    print('DEBUG: Stack trace: $stackTrace');
  }

  // Initialize Firebase for web
  if (kIsWeb) {
    try {
      print('DEBUG: Initializing Firebase for web');
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAP8Jq96CySgpAEcYU13vMiw95vTlKYAEA",
          authDomain: "gardeniatoday-82e68.firebaseapp.com",
          projectId: "gardeniatoday-82e68",
          storageBucket: "gardeniatoday-82e68.firebasestorage.app",
          messagingSenderId: "79911467145",
          appId: "1:79911467145:web:34adee95f50ac65e4eae58",
          measurementId: "G-0KWN75E378",
        ),
      );
      print('DEBUG: Firebase initialized successfully');

      // Register service worker
      if (html.window.navigator.serviceWorker != null) {
        final isLocalhost =
            html.window.location.hostname == 'localhost' || html.window.location.hostname == '127.0.0.1';
        // Fix the swPath to include the base href /Gardeniamarket/
        final swPath = isLocalhost ? '/firebase-messaging-sw.js' : '/Gardeniamarket/firebase-messaging-sw.js';
        print('DEBUG: Registering service worker at path: $swPath');
        try {
          final registration = await js.context['navigator']['serviceWorker'].callMethod('register', [
            swPath,
            js.JsObject.jsify({'scope': '/Gardeniamarket/'})
          ]);
          print('DEBUG: Service worker registered successfully: $registration');
          await html.window.navigator.serviceWorker!.ready;
          print('DEBUG: Service worker is ready');
        } catch (e, stackTrace) {
          print('DEBUG: Error registering service worker: $e');
          print('DEBUG: Stack trace: $stackTrace');
        }
      } else {
        print('DEBUG: Service worker not supported in this browser');
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error initializing Firebase: $e');
      print('DEBUG: Stack trace: $stackTrace');
    }
  } else {
    print('DEBUG: Skipping Firebase initialization (not running on web)');
  }

  // Initialize Hive
  try {
    await Hive.initFlutter();
    await Hive.openBox('marketData');
    await Hive.openBox('userData');
    await Hive.openBox('categoryProducts');
    print('DEBUG: Hive initialized successfully');
  } catch (e, stackTrace) {
    print('DEBUG: Error initializing Hive: $e');
    print('DEBUG: Stack trace: $stackTrace');
  }

  // Initialize secondary Supabase client
  try {
    final secondaryClient = SupabaseClient(secondarySupabaseUrl, secondarySupabaseAnonKey);
    print('DEBUG: Secondary Supabase client initialized');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ChangeNotifierProvider<FavoritesProvider>(create: (_) => FavoritesProvider()),
          ChangeNotifierProvider<ThemeManager>(create: (_) => ThemeManager()),
          Provider<SupabaseConfig>(
            create: (_) => SupabaseConfig(
              primaryClient: Supabase.instance.client,
              secondaryClient: secondaryClient,
            ),
          ),
        ],
        child: MyApp(hasSeenTutorial: hasSeenTutorial),
      ),
    );
  } catch (e, stackTrace) {
    print('DEBUG: Error initializing secondary Supabase client: $e');
    print('DEBUG: Stack trace: $stackTrace');
  }
}

// Rest of the code remains unchanged (MyApp, CheckLoginPage, AdminThemeScreen, AdminNotificationScreen)
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final bool hasSeenTutorial;
  const MyApp({super.key, required this.hasSeenTutorial});

  static final navigatorKey = GlobalKey<NavigatorState>();

  void setupForegroundNotifications() {
    print('DEBUG: Setting up foreground notifications');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('DEBUG: Foreground notification received: ${message.notification?.title}');
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.notification?.body ?? 'New Notification',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: ThemeManager().currentTheme.primaryColor,
          ),
        );
      } else {
        print('DEBUG: Cannot show snackbar, navigator context is null');
      }
    });
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    print('DEBUG: Generating route for: ${settings.name}');
    Widget page;
    try {
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
        print('DEBUG: SupabaseConfig available in _generateRoute for ${settings.name}: $supabaseConfig');
        switch (settings.name) {
          case '/checkLogin':
            print('DEBUG: Handling /checkLogin route');
            page = CheckLoginPage(hasSeenTutorial: hasSeenTutorial);
            break;
          case '/LandingPage':
            print('DEBUG: Handling / route');
            page = const LandingPage();
            break;
          case '/login':
            page = const LoginPage();
            break;
          case '/register':
            page = const RegisterPage();
            break;
          case '/forget_password':
            page = const ForgetPasswordPage();
            break;
          case '/products':
            page = ProductManagementPage();
            break;
          case '/ManageUsersPages':
            page = ManageUsersPages();
            break;
          case '/GardeniaTodayApp':
            page = GardeniaTodayApp(supabaseConfig: supabaseConfig);
            break;
          case '/categories':
            page = MarketCategoriesPage();
            break;
          case '/market':
            final args = settings.arguments as Map<String, dynamic>?;
            page = BottomNavigation(initialTab: args?['tab'] as int? ?? 0);
            break;
          case '/orders':
            page = MarketOrdersPage();
            break;
          case '/CarouselItemsPage':
            page = CarouselItemsPage();
            break;
          case '/DeliveryGuyOrdersPage':
            page = DeliveryGuyOrdersPage();
            break;
          case '/categoryProducts':
            final args = settings.arguments as Map<String, dynamic>?;
            page = CategoryProductsPage(
              categoryName: args?['categoryName'] as String?,
              initialProducts: args?['initialProducts'] as List<Map<String, dynamic>> ?? [],
              cartQuantities: args?['cartQuantities'] as Map<String, int> ?? {},
              categories: args?['categories'] as List<Map<String, dynamic>> ?? [],
            );
            break;
          case '/theme_selector':
            page = const ThemeSelectorScreen();
            break;
          case '/admin/theme':
            page = const AdminThemeScreen();
            break;
          case '/admin/notifications':
            page = AdminNotificationScreen();
            break;
          case '/home':
            page = EntryScreen(supabaseConfig: supabaseConfig);
            break;
          case '/supermarkets':
            page = const SupermarketsScreen();
            break;
          case '/pharmacies':
            page = const PharmaciesScreen();
            break;
          case '/Nursury':
            page = const NurseriesScreen();
            break;
          case '/mosque':
            page = const MosquesScreen();
            break;
          case '/RestaurantsScreen':
            page = const RestaurantsScreen();
            break;
          case '/building':
            page = const BuildingsScreen();
            break;
          case '/atm':
            page = const ATMsScreen();
            break;
          case '/bank':
            page = const BanksScreen();
            break;
          case '/gates':
            page = const GatesScreen();
            break;
          case '/Edara':
            page = const CompanyDetailsScreen();
            break;
          case '/Electricity':
            page = const ElectricityMeterScreen();
            break;
          case '/water':
            page = const WaterMeterScreen();
            break;
          case '/gaz':
            page = const GasMeterScreen();
            break;
          case '/BakeriesScreen':
            page = const BakeriesScreen();
            break;
          case '/VegetablesFruitsScreen':
            page = const VegetablesFruitsScreen();
            break;
          case '/clinic':
            page = const PlaceholderScreen(title: 'العيادات');
            break;
          case '/tutorial':
            final args = settings.arguments as Map<String, dynamic>?;
            page = TutorialScreens(nextRoute: args?['nextRoute'] as String? ?? '/home');
            break;
          default:
            print('DEBUG: Unknown route: ${settings.name}');
            page = Scaffold(
              body: Center(
                child: Text(
                  'الصفحة غير موجودة: ${settings.name}',
                  style: GoogleFonts.cairo(fontSize: 24),
                ),
              ),
            );
        }
      } else {
        print('DEBUG: Navigator context is null in _generateRoute for ${settings.name}');
        page = Scaffold(
          body: Center(
            child: Text(
              'الصفحة غير موجودة: ${settings.name}',
              style: GoogleFonts.cairo(fontSize: 24),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error accessing SupabaseConfig in _generateRoute for ${settings.name}: $e');
      print('DEBUG: Stack trace: $stackTrace');
      page = Scaffold(
        body: Center(
          child: Text(
            'خطأ: $e',
            style: GoogleFonts.cairo(fontSize: 24),
          ),
        ),
      );
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building MyApp, hasSeenTutorial: $hasSeenTutorial');
    if (kIsWeb) {
      setupForegroundNotifications();
    }
    return FutureBuilder(
      future: ThemeManager().initialize(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('DEBUG: ThemeManager initializing, showing loading screen');
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          print('DEBUG: Error initializing ThemeManager: ${snapshot.error}');
        }
        print('DEBUG: ThemeManager initialized, building MaterialApp');
        return ValueListenableBuilder<ThemeData>(
          valueListenable: ThemeManager().themeNotifier,
          builder: (context, theme, child) {
            print('DEBUG: MaterialApp built with theme: $theme');
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: CheckLoginPage(hasSeenTutorial: hasSeenTutorial),
              onGenerateRoute: _generateRoute,
              navigatorKey: navigatorKey,
              theme: theme,
            );
          },
        );
      },
    );
  }
}

class CheckLoginPage extends StatefulWidget {
  final bool hasSeenTutorial;
  const CheckLoginPage({super.key, required this.hasSeenTutorial});

  @override
  _CheckLoginPageState createState() => _CheckLoginPageState();
}

class _CheckLoginPageState extends State<CheckLoginPage> {
  @override
  void initState() {
    super.initState();
    print('DEBUG: CheckLoginPage initState, hasSeenTutorial: ${widget.hasSeenTutorial}');
    // Navigate after frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigate(context);
    });
  }

  void _navigate(BuildContext navContext) {
    final authProvider = Provider.of<AuthProvider>(navContext, listen: false);
    final nextRoute = authProvider.isAuthenticated ? '/GardeniaTodayApp' : '/home';
    print('DEBUG: Navigating from CheckLoginPage to: ${widget.hasSeenTutorial ? nextRoute : '/tutorial'}, nextRoute: $nextRoute');
    Navigator.pushReplacementNamed(
      navContext,
      widget.hasSeenTutorial ? nextRoute : '/tutorial',
      arguments: {'nextRoute': nextRoute},
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building CheckLoginPage, hasSeenTutorial: ${widget.hasSeenTutorial}');
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      print('DEBUG: SupabaseConfig available in CheckLoginPage: $supabaseConfig');
    } catch (e, stackTrace) {
      print('DEBUG: Error accessing SupabaseConfig in CheckLoginPage: $e');
      print('DEBUG: Stack trace: $stackTrace');
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('DEBUG: CheckLoginPage Consumer, isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}');
        if (authProvider.isLoading) {
          print('DEBUG: AuthProvider is loading, showing loading indicator');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class AdminThemeScreen extends StatefulWidget {
  const AdminThemeScreen({super.key});

  @override
  _AdminThemeScreenState createState() => _AdminThemeScreenState();
}

class _AdminThemeScreenState extends State<AdminThemeScreen> {
  String? _selectedTheme;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: AdminThemeScreen initState');
    _fetchCurrentTheme();
  }

  Future<void> _fetchCurrentTheme() async {
    print('DEBUG: Fetching current theme');
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.primaryClient
          .from('app_settings')
          .select('theme_id')
          .eq('setting_key', 'active_theme')
          .maybeSingle();
      if (mounted) {
        setState(() {
          _selectedTheme = response?['theme_id'] as String? ?? 'default';
          print('DEBUG: Current theme fetched: $_selectedTheme');
        });
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error fetching current theme: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _selectedTheme = 'default';
        });
      }
    }
  }

  Future<void> _updateTheme(String themeId) async {
    print('DEBUG: Updating theme to: $themeId');
    setState(() {
      _isLoading = true;
    });
    try {
      await ThemeManager().setTheme(context, themeId);
      if (mounted) {
        setState(() {
          _selectedTheme = themeId;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث الثيم إلى $themeId',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
        print('DEBUG: Theme updated successfully: $themeId');
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error updating theme: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحديث الثيم',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building AdminThemeScreen');
    final theme = ThemeManager().currentTheme;
    final availableThemes = ThemeManager().availableThemes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة الثيمات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          flexibleSpace: Container(),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر الثيم النشط',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTheme,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardBackground,
                ),
                items: availableThemes
                    .map((t) => DropdownMenuItem(
                  value: t.id,
                  child: Text(
                    t.name,
                    style: GoogleFonts.cairo(
                      color: theme.textColor,
                    ),
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateTheme(value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminNotificationScreen extends StatelessWidget {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building AdminNotificationScreen');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إرسال إشعار عام',
            style: GoogleFonts.cairo(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'المحتوى',
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  print('DEBUG: Sending notification: title=${_titleController.text}, body=${_bodyController.text}');
                  try {
                    await Supabase.instance.client.from('notifications').insert({
                      'title': _titleController.text,
                      'body': _bodyController.text,
                      'target': 'all',
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إرسال الإشعار',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                    );
                    print('DEBUG: Notification sent successfully');
                    _titleController.clear();
                    _bodyController.clear();
                  } catch (e, stackTrace) {
                    print('DEBUG: Error sending notification: $e');
                    print('DEBUG: Stack trace: $stackTrace');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'فشل إرسال الإشعار: $e',
                          style: GoogleFonts.cairo(),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  'إرسال',
                  style: GoogleFonts.cairo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/farmer/farmer_home.dart';
import 'screens/provider/provider_home.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Read cached session BEFORE runApp
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userRole = prefs.getString('userRole');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(AgriLogisticsApp(
    isLoggedIn: isLoggedIn,
    userRole: userRole,
  ));
}

class AgriLogisticsApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userRole;

  const AgriLogisticsApp({
    super.key,
    required this.isLoggedIn,
    this.userRole,
  });

  Widget _routeByRole(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'serviceProvider':
        return const ProviderHome();
      case 'farmer':
      default:
        return const FarmerHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decide initial screen BEFORE building the widget tree
    final Widget initialScreen;
    if (isLoggedIn && userRole != null) {
      initialScreen = _routeByRole(userRole!);
    } else {
      initialScreen = const AuthWrapper();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'ប្រព័ន្ធដឹកជញ្ជូនកសិកម្ម — បន្ទាយមានជ័យ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: initialScreen,
      ),
    );
  }
}

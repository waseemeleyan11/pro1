import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/admin/screens/admin_dashboard.dart';
import 'package:storify/customer/screens/customer_dashboard.dart';
import 'package:storify/firebase_options.dart';
import 'package:storify/supplier/screens/supplier_dashboard.dart';
import 'package:storify/utilis/notification_service.dart';
import 'package:storify/utilis/theme_provider.dart';
import 'package:storify/utilis/auth_service.dart';

// Background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  // Get stored user role
  final prefs = await SharedPreferences.getInstance();
  final userRole = prefs.getString('userRole') ?? 'customer';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MyApp(initialRole: userRole),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRole;

  const MyApp({
    Key? key,
    required this.initialRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 1024),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Storify',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color.fromARGB(255, 28, 39, 55),
            primaryColor: const Color.fromARGB(255, 105, 65, 198),
            colorScheme: ColorScheme.dark(
              primary: const Color.fromARGB(255, 105, 65, 198),
              secondary: const Color.fromARGB(255, 105, 65, 198),
            ),
            fontFamily: 'SpaceGrotesk',
          ),
          home: _getInitialScreen(),
        );
      },
    );
  }

  Widget _getInitialScreen() {
    // Check if user is logged in
    final authService = AuthService();
    final isLoggedIn = authService.isLoggedIn;

    if (!isLoggedIn) {
      // Return login screen if not logged in
      return LoginScreen();
    }

    // Return appropriate dashboard based on user role
    switch (initialRole.toLowerCase()) {
      case 'admin':
        return AdminDashboard();
      case 'supplier':
        return SupplierDashboard();
      case 'customer':
      default:
        return CustomerDashboard();
    }
  }
}

// Your existing LoginScreen implementation

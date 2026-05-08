import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/admin_home_screen.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/seller_products_screen.dart';
import 'screens/seller_product_new_screen.dart';
import 'screens/seller_product_edit_screen.dart';
// Seller module screens
import 'screens/seller/seller_main_screen.dart';
import 'screens/seller/seller_orders_screen.dart';
import 'screens/seller/seller_stats_screen.dart';
import 'screens/seller/seller_withdraw_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/purchase_history_screen.dart';
import 'models/product.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Remove splash once the first frame is rendered
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jualin Mobile',
      theme: ThemeData(
        primaryColor: const Color(0xFFE83030),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE83030)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        primaryTextTheme: GoogleFonts.jetBrainsMonoTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        // ── Buyer routes (unchanged) ─────────────────────────
        '/': (context) => const AuthGateScreen(),
        '/main': (context) => const MainScreen(),
        '/auth': (context) => const AuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/admin_home': (context) => const AdminHomeScreen(),
        '/product_detail': (context) => const ProductDetailScreen(),
        '/profile_edit': (context) => const ProfileEditScreen(),
        '/purchase_history': (context) => const PurchaseHistoryScreen(),

        // ── Legacy seller routes (kept for backward compatibility) ──
        '/seller_dashboard': (context) => const SellerDashboardScreen(),
        '/seller_products': (context) => const SellerProductsScreen(),
        '/seller_product_new': (context) => const SellerProductNewScreen(),
        '/seller_product_edit': (context) => const SellerProductEditScreen(),

        // ── Seller module routes ─────────────────────────────
        '/seller_main': (context) => const SellerMainScreen(),
        '/seller_orders': (context) => const SellerOrdersScreen(),
        '/seller_stats': (context) => const SellerStatsScreen(),
        '/seller_withdraw': (context) => const SellerWithdrawScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/checkout') {
          // Expect a Product object
          final product = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (context) => CheckoutScreen(product: product),
          );
        }
        return null;
      },
    );
  }
}

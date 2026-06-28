import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'navigation/app_navigator.dart';
import 'screens/admin_home_screen.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/auth_required_screen.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/seller_store_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/seller_products_screen.dart';
import 'screens/seller_product_new_screen.dart';
import 'screens/seller_product_edit_screen.dart';
import 'screens/WalletScreen.dart';
// Seller module screens
import 'screens/seller/seller_main_screen.dart';
import 'screens/seller/seller_orders_screen.dart';
import 'screens/seller/seller_stats_screen.dart';
import 'screens/seller/seller_withdraw_screen.dart';
import 'screens/seller/seller_withdrawal_history_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/purchase_history_screen.dart';
import 'services/push_notification_service.dart';
import 'models/product.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await PushNotificationService.instance.initialize(
    navigatorKey: appNavigatorKey,
  );
  runApp(const MyApp());
}

/// Globally disables Android overscroll stretch & forces ClampingScrollPhysics.
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
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
      navigatorKey: appNavigatorKey,
      scrollBehavior: const NoStretchScrollBehavior(),
      // ── Global font scaling ──────────────────────────────────────────────
      // Reduces all text in the app by ~12% so it fits better on small screens.
      // Overrides the system accessibility font-size setting to a safe cap.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              (mq.textScaler.scale(1.0)).clamp(0.0, 1.0) * 0.88,
            ),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: const Color(0xFFE83030),
        scaffoldBackgroundColor: Colors.white,
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
        '/admin_home': (context) => const AuthRequiredScreen(
              message: 'Silakan login sebagai admin untuk melanjutkan.',
              child: AdminHomeScreen(),
            ),
        '/product_detail': (context) => const ProductDetailScreen(),
        '/seller_store': (context) => const SellerStoreScreen(),
        '/profile_edit': (context) => const AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk mengubah profil.',
              child: ProfileEditScreen(),
            ),
        '/purchase_history': (context) => const AuthRequiredScreen(
              message:
                  'Silakan login terlebih dahulu untuk melihat riwayat pembelian.',
              child: PurchaseHistoryScreen(),
            ),

        // ── Legacy seller routes (kept for backward compatibility) ──
        '/seller_dashboard': (context) => const AuthRequiredScreen(
              message:
                  'Silakan login terlebih dahulu untuk mengakses dashboard penjual.',
              child: SellerDashboardScreen(),
            ),
        '/seller_products': (context) => const AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk mengelola produk.',
              child: SellerProductsScreen(),
            ),
        '/seller_product_new': (context) => const AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk menambah produk.',
              child: SellerProductNewScreen(),
            ),
        '/seller_product_edit': (context) => const AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk mengubah produk.',
              child: SellerProductEditScreen(),
            ),

        // ── Seller module routes ─────────────────────────────
        '/seller_main': (context) => const AuthRequiredScreen(
              message:
                  'Silakan login terlebih dahulu untuk mengakses menu penjual.',
              child: SellerMainScreen(),
            ),

        '/seller_orders': (context) => const AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk melihat pesanan.',
              child: SellerOrdersScreen(),
            ),

        '/seller_stats': (context) => const AuthRequiredScreen(
              message:
                  'Silakan login terlebih dahulu untuk melihat statistik penjualan.',
              child: SellerStatsScreen(),
            ),

        '/seller_withdraw': (context) => const AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk menarik saldo.',
              child: SellerWithdrawScreen(),
            ),

        '/seller_withdrawals': (context) => const AuthRequiredScreen(
              message:
                  'Silakan login terlebih dahulu untuk melihat riwayat penarikan.',
              child: SellerWithdrawalHistoryScreen(),
            ),

        '/wallet': (context) => const AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk mengakses dompet.',
              child: WalletScreen(),
            ),
      },
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '';
        if (routeName.startsWith('/reset_password') ||
            routeName.startsWith('/auth/reset-password')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const ResetPasswordScreen(),
          );
        }

        if (settings.name == '/checkout') {
          // Expect a Product object
          final product = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (context) => AuthRequiredScreen(
              message: 'Silakan login terlebih dahulu untuk checkout.',
              child: CheckoutScreen(product: product),
            ),
          );
        }
        return null;
      },
    );
  }
}

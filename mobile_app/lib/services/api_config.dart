class ApiConfig {
  // Use http://10.0.2.2:8000/api/v1 for Android Emulator
  // Use http://localhost:8000/api/v1 for iOS Simulator / Web / Desktop
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // ── Auth ────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String refreshToken = '/refresh-token';
  static const String passwordEmail = '/password/email';
  static const String passwordReset = '/password/reset';

  // ── Products ────────────────────────────────────
  static const String products = '/products';
  static const String sellerProducts = '/seller/products';

  // ── Profile ─────────────────────────────────────
  static const String profileUpdate = '/profile/update';
  static String userUpdate(int userId) => '/users/$userId/update';

  // ── Transactions & Payments ───────────────────────
  static const String transactions = '/transactions';
  static const String payWallet = '/transactions/pay-wallet';
  static const String createPayment = '/payments/create';
  static const String paymentHistory = '/payments/history';
  static const String sellerStats = '/transactions/income/statistics';
  static const String sellerWithdraw = '/transactions/withdraw';
  static const String escrow = '/escrow';
  static String escrowRefund(int transactionId) => '$escrow/$transactionId/refund';
  static String escrowClaim(int transactionId) => '$escrow/$transactionId/claim';

  // ── Chat ────────────────────────────────────────
  static const String chatRooms = '/chat/rooms';
  static const String chatRoomsStart = '/chat/rooms/start';
  static String chatMessages(int roomId) => '/chat/rooms/$roomId/messages';
}

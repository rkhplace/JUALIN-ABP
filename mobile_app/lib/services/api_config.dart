class ApiConfig {
  static const String defaultBaseUrl =
      'https://jualin-abp-production-b531.up.railway.app/api/v1';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

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

  // ── Transactions & Payments ───────────────────────
  static const String transactions = '/transactions';
  static const String payWallet = '/transactions/pay-wallet';
  static const String createPayment = '/payments/create';
  static const String paymentHistory = '/payments/history';
  static const String sellerStats = '/transactions/income/statistics';
  static const String sellerWithdraw = '/transactions/withdraw';
  static const String sellerVerificationStatus = '/seller/verification-status';
  static const String reports = '/reports';
  static const String escrow = '/escrow';
  static String escrowRefund(int transactionId) =>
      '$escrow/$transactionId/refund';
  static String escrowClaim(int transactionId) =>
      '$escrow/$transactionId/claim';

  // ── Chat ────────────────────────────────────────
  static const String chatRooms = '/chat/rooms';
  static const String chatRoomsStart = '/chat/rooms/start';
  static String chatMessages(int roomId) => '/chat/rooms/$roomId/messages';
  static String chatProductMessage(int roomId) =>
      '/chat/rooms/$roomId/product-message';

  // ── Notifications ───────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationDeviceTokens = '/notifications/device-tokens';
}

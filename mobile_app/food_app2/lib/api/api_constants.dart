// class ApiConstants {
//   static const String baseUrl = 'http://192.168.56.1:8081'; // Use your actual IP
//
//   static const String login = '/api/auth/login';
//   static const String registerCustomer = '/api/auth/register/customer';
//   static const String registerMerchant = '/api/auth/register/merchant';
//   static const String verifyEmail = '/api/auth/verify-email';
//   static const String resendCode = '/api/auth/resend-code';
//   static const String forgotPassword = '/api/auth/forgot-password';
//   static const String resetPassword = '/api/auth/reset-password';
//
//   static const String menuItems = '/api/menu-items';
//   static const String foodCategories = '/api/food-categories';
//   static const String todaysMenu = '/api/menu/today';
//
//   static const String placeOrder = '/api/orders/place';
//   static const String myOrders = '/api/orders/my-history';
//   static const String cancelOrder = '/api/orders/cancel/'; // Append {orderId}
//   static const String customerProfile = '/api/customer/profile';
//   static const String customerProfilePicture = '/api/customer/profile/picture';
//   static const String topupRequest = '/api/topup/request';
//   static const String topupBalance = '/api/topup/balance';
//   static const String myTopupRequests = '/api/topup/my-requests';
//   static const String deleteTopupRequest = '/api/topup/request/';
//
//   static const String merchantOrdersByStatus = '/api/orders/merchant/';
//   static const String acceptOrder = '/api/orders/';
//   static const String completeOrder = '/api/orders/';
//   static const String merchantMenu = '/api/merchant/menu';
//   static const String merchantMenuImage = '/api/merchant/menu/';
//   static const String merchantReportsDaily = '/api/merchant/reports/sales/daily';
//
//   static const String pendingTopups = '/api/topup/pending';
//   static const String respondToTopup = '/api/topup/respond/';
//
//   static const String adminDashboard = '/api/admin/dashboard';
//   static const String adminAllCustomers = '/api/admin/users/customers';
//   static const String adminAllMerchants = '/api/admin/users/merchants';
//   static const String adminActivateUser = '/api/admin/users/';
//   static const String adminDeactivateUser = '/api/admin/users/';
//
//   static const String uploads = '/api/uploads/';
// }


// class ApiConstants {
//   static const String baseUrl = 'http://13.229.83.22:8081'; // Use your actual IP
//
//   // Auth
//   static const String login = '/api/auth/login';
//   static const String registerCustomer = '/api/auth/register/customer';
//   static const String registerMerchant = '/api/auth/register/merchant';
//   static const String verifyEmail = '/api/auth/verify-email';
//   static const String resendCode = '/api/auth/resend-code';
//   static const String forgotPassword = '/api/auth/forgot-password';
//   static const String resetPassword = '/api/auth/reset-password';
//
//   // Menu & Categories
//   static const String menuItems = '/api/menu-items';
//   static const String foodCategories = '/api/food-categories';
//   static const String todaysMenu = '/api/menu/today';
//
//   // Orders
//   static const String placeOrder = '/api/orders/place';
//   static const String myOrders = '/api/orders/my-history';   // Assuming endpoint for customer orders
//   static const String cancelOrder = '/api/orders/cancel/';            // Append {orderId}
//
//   // Customer profile
//   static const String customerProfile = '/api/customer/profile';
//   static const String customerProfilePicture = '/api/customer/profile/picture';
//
//   // Topup
//   static const String topupRequest = '/api/topup/request';
//   static const String topupBalance = '/api/topup/balance';
//   static const String myTopupRequests = '/api/topup/my-requests';
//   static const String deleteTopupRequest = '/api/topup/request/';     // Append {requestId}
//   static const String pendingTopups = '/api/topup/pending';
//   static const String respondToTopup = '/api/topup/respond/';         // Append {requestId}
//
//   // Merchant
//   static const String merchantOrdersPending = '/api/orders/merchant/pending';
//   static const String merchantOrdersByStatus = '/api/orders/merchant/';
//   static const String merchantOrdersAccepted = '/api/orders/merchant/accepted';
//   static const String acceptOrder = '/api/orders/';          // Append {orderId}/accept
//   static const String completeOrder = '/api/orders/';        // Append {orderId}/complete
//   static const String completeOrderDirectly = '/api/orders/merchant/'; // Append {orderId}/completeDirectly
//   static const String merchantMenu = '/api/merchant/menu';
//   static const String merchantMenuImage = '/api/merchant/menu/';       // Append {imageId}
//   static const String merchantReportsDaily = '/api/merchant/reports/sales/daily';
//
//   // Admin
//   static const String adminDashboard = '/api/admin/dashboard';
//   static const String adminAllCustomers = '/api/admin/users/customers';
//   static const String adminAllMerchants = '/api/admin/users/merchants';
//   static const String adminActivateUser = '/api/admin/users/';        // Append {userId}/activate
//   static const String adminDeactivateUser = '/api/admin/users/';      // Append {userId}/deactivate
//
//   // Uploads
//   static const String uploads = '/api/uploads/';
//
//   // Messaging (added based on security config)
//   static const String sendMessage = '/api/messages/send';
//   static const String getConversation = '/api/messages/conversation/';  // Append {conversationId}
// }





class ApiConstants {
  static const String baseUrl = 'http://13.229.83.22:8081'; // Use your actual IP

  // Auth
  static const String login = '/api/auth/login';
  static const String registerCustomer = '/api/auth/register/customer';
  static const String registerMerchant = '/api/auth/register/merchant';
  static const String registerAdmin = '/api/auth/register/admin'; // <-- ADDED
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendCode = '/api/auth/resend-code';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // Menu & Categories
  static const String menuItems = '/api/menu-items';
  static const String foodCategories = '/api/food-categories';
  static const String todaysMenu = '/api/menu/today';

  // Orders
  static const String placeOrder = '/api/orders/place';
  static const String myOrders = '/api/orders/my-history';
  static const String cancelOrder = '/api/orders/cancel/';

  // Customer profile
  static const String customerProfile = '/api/customer/profile';
  static const String customerProfilePicture = '/api/customer/profile/picture';

  // Topup
  static const String topupRequest = '/api/topup/request';
  static const String topupBalance = '/api/topup/balance';
  static const String myTopupRequests = '/api/topup/my-requests';
  static const String deleteTopupRequest = '/api/topup/request/';
  static const String pendingTopups = '/api/topup/pending';
  static const String respondToTopup = '/api/topup/respond/';

  // Merchant
  static const String merchantOrdersPending = '/api/orders/merchant/pending';
  static const String merchantOrdersByStatus = '/api/orders/merchant/';
  static const String acceptOrder = '/api/orders/';
  static const String completeOrder = '/api/orders/';
  static const String completeOrderDirectly = '/api/orders/merchant/';
  static const String merchantMenu = '/api/merchant/menu';
  static const String merchantMenuImage = '/api/merchant/menu/';
  static const String merchantReportsDaily = '/api/merchant/reports/sales/daily';

  // Admin
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminAddAdmin = '/api/admin/add-admin';
  static const String adminAllCustomers = '/api/admin/users/customers';
  static const String adminAllMerchants = '/api/admin/users/merchants';
  static const String adminActivateUser = '/api/admin/users/';
  static const String adminDeactivateUser = '/api/admin/users/';
  static const String adminReportsSalesOverview = '/api/admin/reports/sales/overview';

  // Uploads
  static const String uploads = '/api/uploads/';

  // Messaging
  static const String sendMessage = '/api/messages/send';
  static const String getConversation = '/api/messages/conversation/';
}

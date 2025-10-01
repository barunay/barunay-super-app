import 'package:flutter/material.dart';

import '../presentation/business_directory_screen/business_directory_screen.dart';
import '../presentation/chat_landing_screen/chat_landing_screen.dart';
import '../presentation/chat_screen/chat_screen.dart';
import '../presentation/delivery_home_screen/delivery_home_screen.dart';
import '../presentation/delivery_runner_dashboard_screen/delivery_runner_dashboard_screen.dart';
import '../presentation/delivery_tracking_screen/delivery_tracking_screen.dart';
import '../presentation/edit_product_listing_screen/edit_product_listing_screen.dart';
import '../presentation/enhanced_delivery_request_screen/enhanced_delivery_request_screen.dart';
import '../presentation/enhanced_delivery_runner_dashboard_screen/enhanced_delivery_runner_dashboard_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/marketplace_home_screen/marketplace_home_screen.dart';
import '../presentation/post_item_screen/post_item_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';
import '../presentation/profile_management_screen/profile_management_screen.dart';
import '../presentation/profile_under_review_screen/profile_under_review_screen.dart';
import '../presentation/runner_profile_setup_screen/runner_profile_setup_screen.dart';
import '../presentation/seller_inventory_management_screen/seller_inventory_management_screen.dart';
import '../presentation/seller_inventory_screen/seller_inventory_screen.dart';
import '../presentation/seller_profile_setup_screen/seller_profile_setup_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/user_favorites_screen/user_favorites_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/user_registration_screen/user_registration_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String userRegistrationScreen = '/user-registration-screen';
  static const String profileManagementScreen = '/profile-management-screen';
  static const String sellerProfileSetupScreen = '/seller-profile-setup-screen';
  static const String runnerProfileSetupScreen = '/runner-profile-setup-screen';
  static const String profileUnderReviewScreen = '/profile-under-review-screen';
  static const String marketplaceHomeScreen = '/marketplace-home-screen';
  static const String postItemScreen = '/post-item-screen';
  static const String editProductListingScreen = '/edit-product-listing-screen';
  static const String productDetailScreen = '/product-detail-screen';
  static const String userProfileScreen = '/user-profile-screen';
  static const String userFavoritesScreen = '/user-favorites-screen';
  static const String sellerInventoryScreen = '/seller-inventory-screen';
  static const String sellerInventoryManagementScreen =
      '/seller-inventory-management-screen';
  static const String deliveryHomeScreen = '/delivery-home-screen';
  static const String deliveryRunnerDashboardScreen =
      '/delivery-runner-dashboard-screen';
  static const String enhancedDeliveryRequestScreen =
      '/enhanced-delivery-request-screen';
  static const String enhancedDeliveryRunnerDashboardScreen =
      '/enhanced-delivery-runner-dashboard-screen';
  static const String deliveryTrackingScreen = '/delivery-tracking-screen';
  static const String chatLandingScreen = '/chat-landing-screen';
  static const String chatScreen = '/chat-screen';
  static const String businessDirectoryScreen = '/business-directory-screen';

  static Map<String, WidgetBuilder> get routes => {
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    userRegistrationScreen: (context) => const UserRegistrationScreen(),
    profileManagementScreen: (context) => const ProfileManagementScreen(),
    sellerProfileSetupScreen: (context) => const SellerProfileSetupScreen(),
    runnerProfileSetupScreen: (context) => const RunnerProfileSetupScreen(),
    profileUnderReviewScreen: (context) => const ProfileUnderReviewScreen(),
    marketplaceHomeScreen: (context) => const MarketplaceHomeScreen(),
    postItemScreen: (context) => const PostItemScreen(),
    editProductListingScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final productId = args?['productId'] as String? ?? '';
      return EditProductListingScreen(productId: productId);
    },
    productDetailScreen: (context) => const ProductDetailScreen(),
    userProfileScreen: (context) => const UserProfileScreen(),
    userFavoritesScreen: (context) => const UserFavoritesScreen(),
    sellerInventoryScreen: (context) => const SellerInventoryScreen(),
    sellerInventoryManagementScreen:
        (context) => const SellerInventoryManagementScreen(),
    deliveryHomeScreen: (context) => const DeliveryHomeScreen(),
    deliveryRunnerDashboardScreen:
        (context) => const DeliveryRunnerDashboardScreen(),
    enhancedDeliveryRequestScreen:
        (context) => const EnhancedDeliveryRequestScreen(),
    enhancedDeliveryRunnerDashboardScreen:
        (context) => const EnhancedDeliveryRunnerDashboardScreen(),
    deliveryTrackingScreen: (context) => const DeliveryTrackingScreen(),
    chatLandingScreen: (context) => const ChatLandingScreen(),
    chatScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final conversationId = args?['conversationId'] as String? ?? '';
      final productId = args?['productId'] as String?;
      return ChatScreen(
        conversationId: conversationId,
        productId: productId,
      );
    },
    businessDirectoryScreen: (context) => const BusinessDirectoryScreen(),
  };

  // Helper methods for navigation with proper arguments
  static void navigateToEditProductListing(
    BuildContext context, {
    required String productId,
  }) {
    Navigator.pushNamed(
      context,
      editProductListingScreen,
      arguments: {'productId': productId},
    );
  }

  static void navigateToProductDetail(
    BuildContext context, {
    Map<String, dynamic>? product,
  }) {
    Navigator.pushNamed(context, productDetailScreen, arguments: product);
  }

  static void navigateToChat(
    BuildContext context, {
    required String conversationId,
    required Map<String, dynamic> participant,
    required String chatType,
  }) {
    Navigator.pushNamed(
      context,
      chatScreen,
      arguments: {
        'conversationId': conversationId,
        'participant': participant,
        'chatType': chatType,
      },
    );
  }
}
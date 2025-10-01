import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

class GlobalBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const GlobalBottomNavigation({Key? key, required this.currentIndex})
    : super(key: key);

  void _handleNavigation(BuildContext context, int index) {
    // Prevent navigation to same screen
    if (index == currentIndex) return;

    // Enhanced navigation with proper route management
    String routeName;
    switch (index) {
      case 0:
        routeName = AppRoutes.marketplaceHomeScreen;
        break;
      case 1:
        routeName = AppRoutes.businessDirectoryScreen;
        break;
      case 2:
        routeName = AppRoutes.deliveryHomeScreen;
        break;
      case 3:
        routeName = AppRoutes.chatLandingScreen;
        break;
      case 4:
        routeName = AppRoutes.userProfileScreen;
        break;
      default:
        return;
    }

    // Safe navigation with error handling
    try {
      Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
    } catch (e) {
      // Fallback navigation
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(
              alpha: 0.1,
            ),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.cardColor,
        selectedItemColor: AppTheme.lightTheme.primaryColor,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        selectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: AppTheme.lightTheme.textTheme.labelSmall,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'storefront',
              color:
                  currentIndex == 0
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'business',
              color:
                  currentIndex == 1
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Business',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'local_shipping',
              color:
                  currentIndex == 2
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Delivery',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'chat',
              color:
                  currentIndex == 3
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color:
                  currentIndex == 4
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

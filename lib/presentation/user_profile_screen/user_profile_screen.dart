import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/profile_image_service.dart';
import '../../services/user_service.dart';
import './widgets/bottom_navigation_widget.dart';
import './widgets/favorites_section_widget.dart';
import './widgets/language_toggle_widget.dart';
import './widgets/payment_methods_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String currentLanguage = 'English';
  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool smsNotifications = false;
  bool profileVisible = true;
  bool dataSharing = false;
  bool _isLoading = false;

  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _subProfiles = [];

  // Mock payment methods - in real app, fetch from backend
  final List<Map<String, dynamic>> paymentMethods = [
    {
      "id": 1,
      "type": "card",
      "name": "BIBD Visa Card",
      "details": "**** **** **** 1234",
      "isPrimary": true,
    },
    {
      "id": 2,
      "type": "bank",
      "name": "Standard Chartered",
      "details": "Account ending in 5678",
      "isPrimary": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!AuthService.instance.isSignedIn) {
      // Redirect to login if not authenticated
      Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile
      final profile = await UserService.instance.getCurrentUserProfile();
      final subProfiles = await UserService.instance.getUserSubProfiles();

      setState(() {
        _userProfile = profile;
        _subProfiles = subProfiles;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAvatarTap() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Update Profile Photo',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'camera_alt',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 6.w,
                  ),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleCameraCapture();
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'photo_library',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 6.w,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleGallerySelection();
                  },
                ),
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'delete_outline',
                    color: Colors.red,
                    size: 6.w,
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleRemovePhoto();
                  },
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
    );
  }

  Future<void> _handleCameraCapture() async {
    try {
      final imageFile =
          await ProfileImageService.instance.takePhotoWithCamera();
      if (imageFile != null && _userProfile != null) {
        await _uploadProfileImage(imageFile);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGallerySelection() async {
    try {
      final imageFile =
          await ProfileImageService.instance.pickImageFromGallery();
      if (imageFile != null && _userProfile != null) {
        await _uploadProfileImage(imageFile);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadProfileImage(imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AuthService.instance.currentUser!.id;

      // Delete old image if exists
      if (_userProfile!['avatar_url'] != null) {
        await ProfileImageService.instance.deleteProfileImage(
          _userProfile!['avatar_url'],
        );
      }

      // Upload new image
      final imageUrl = await ProfileImageService.instance.uploadProfileImage(
        userId: userId,
        imageFile: imageFile,
      );

      // Update user profile with new avatar URL
      await UserService.instance.updateUserProfile(
        fullName: _userProfile!['full_name'],
        phone: _userProfile!['phone'],
        avatarUrl: imageUrl,
      );

      // Reload profile
      await _loadUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile photo: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRemovePhoto() async {
    if (_userProfile?['avatar_url'] == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete image from storage
      await ProfileImageService.instance.deleteProfileImage(
        _userProfile!['avatar_url'],
      );

      // Update user profile to remove avatar URL
      await UserService.instance.updateUserProfile(
        fullName: _userProfile!['full_name'],
        phone: _userProfile!['phone'],
        avatarUrl: null,
      );

      // Reload profile
      await _loadUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile photo removed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove profile photo: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sign Out'),
            content: Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await AuthService.instance.signOut();
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.loginScreen,
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to sign out: ${error.toString()}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Sign Out', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  String _getDisplayAvatarUrl() {
    if (_userProfile?['avatar_url'] != null &&
        _userProfile!['avatar_url'].isNotEmpty) {
      return _userProfile!['avatar_url'];
    }
    // Use user ID as seed for consistent avatar generation
    final userId = AuthService.instance.currentUser?.id;
    return ProfileImageService.instance.getPlaceholderProfileImage(
      userId: userId,
    );
  }

  String _getUserDisplayName() {
    if (_userProfile?['full_name'] != null &&
        _userProfile!['full_name'].isNotEmpty) {
      return _userProfile!['full_name'];
    }
    return AuthService.instance.currentUser?.email ?? 'User';
  }

  String _getUserType() {
    if (_subProfiles.isNotEmpty) {
      final activeProfiles =
          _subProfiles.where((p) => p['is_active'] == true).toList();
      if (activeProfiles.isNotEmpty) {
        return activeProfiles
            .map((p) => p['profile_type'])
            .join(', ')
            .toUpperCase();
      }
    }
    return _userProfile?['role']?.toUpperCase() ?? 'BUYER';
  }

  int _getProfileCompletionPercentage() {
    int completed = 0;
    int total = 5;

    if (_userProfile?['full_name'] != null &&
        _userProfile!['full_name'].isNotEmpty)
      completed++;
    if (_userProfile?['phone'] != null && _userProfile!['phone'].isNotEmpty)
      completed++;
    if (_userProfile?['avatar_url'] != null &&
        _userProfile!['avatar_url'].isNotEmpty)
      completed++;
    if (AuthService.instance.currentUser?.email != null) completed++;
    if (_subProfiles.isNotEmpty) completed++;

    return ((completed / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                ProfileHeaderWidget(
                  userName: _getUserDisplayName(),
                  userType: _getUserType(),
                  avatarUrl: _getDisplayAvatarUrl(),
                  completionPercentage: _getProfileCompletionPercentage(),
                  onAvatarTap: _handleAvatarTap,
                ),

                SizedBox(height: 2.h),

                // Favorites Section - NEW
                if (_userProfile != null) FavoritesSectionWidget(),

                SizedBox(height: 2.h),

                // Settings Section
                SettingsSectionWidget(
                  title: 'Settings',
                  items: [
                    SettingsItem(
                      title: 'Privacy Settings',
                      icon: 'privacy_tip',
                      onTap: () {},
                    ),
                    SettingsItem(
                      title: 'Notification Settings',
                      icon: 'notifications',
                      onTap: () {},
                    ),
                    SettingsItem(
                      title: 'Help & Support',
                      icon: 'help',
                      onTap: () {},
                    ),
                    SettingsItem(
                      title: 'About',
                      icon: 'info',
                      onTap: () {},
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Payment Methods
                PaymentMethodsWidget(
                  paymentMethods: paymentMethods,
                  onAddPaymentMethod: _handleAddPaymentMethod,
                ),

                SizedBox(height: 2.h),

                // Language Toggle
                LanguageToggleWidget(
                  currentLanguage: currentLanguage,
                  onLanguageChanged: (language) {
                    setState(() {
                      currentLanguage = language;
                    });
                    _handleLanguageChange(language);
                  },
                ),

                SizedBox(height: 10.h), // Extra space for bottom navigation
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: 2,
        onTap: _handleBottomNavigation,
      ),
    );
  }

  Future<void> _refreshProfile() async {
    await _loadUserProfile();
  }

  void _handleAddPaymentMethod() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Payment Method'),
            content: const Text(
              'This feature will redirect you to add a new payment method.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Handle add payment method
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _handleLanguageChange(String language) {
    // Handle language change logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to $language'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleAccountDeletion() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Handle account deletion
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // Navigation methods
  void _navigateToPersonalDetails() {
    // Navigate to personal details screen
  }

  void _navigateToEmailSettings() {
    // Navigate to email settings screen
  }

  void _navigateToOrderHistory(String type) {
    // Navigate to order history screen with type filter
  }

  void _navigateToShopSettings() {
    // Navigate to shop settings screen
  }

  void _navigateToInventory() {
    // Navigate to inventory management screen
  }

  void _navigateToAnalytics() {
    // Navigate to sales analytics screen
  }

  void _navigateToChangePassword() {
    // Navigate to change password screen
  }

  void _navigateToTwoFactor() {
    // Navigate to two-factor authentication setup
  }

  void _navigateToActiveSessions() {
    // Navigate to active sessions management
  }

  void _navigateToHelpCenter() {
    // Navigate to help center
  }

  void _navigateToContactSupport() {
    // Navigate to contact support
  }

  void _navigateToFeedback() {
    // Navigate to feedback form
  }

  void _navigateToGuidelines() {
    // Navigate to P2P transaction guidelines
  }

  void _navigateToDeliveryHistory() {
    // Navigate to delivery history screen
  }

  void _navigateToEarningsReport() {
    // Navigate to earnings report screen
  }

  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/marketplace-home-screen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/business-directory-screen');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/delivery-tracking-screen');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/chat-screen');
        break;
      case 4:
        // Already on profile screen
        break;
    }
  }
}
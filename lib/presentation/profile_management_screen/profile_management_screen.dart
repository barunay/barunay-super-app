import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _activeProfile = 'Shopper';
  bool _isLoading = false;

  // Add this block
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _subProfiles = [];
  //

  // Mock user data
  final Map<String, dynamic> _userData = {
    "id": 1,
    "name": "Ahmad Rahman",
    "email": "ahmad.rahman@email.com",
    "phone": "+673 8123456",
    "avatar":
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face",
    "accountCreatedAt": "January 2024",
    "isVerified": true,
  };

  // Profile data for different roles
  final Map<String, Map<String, dynamic>> _profilesData = {
    'Shopper': {
      "status": "Active",
      "isSetup": true,
      "orderCount": 25,
      "wishlistCount": 8,
      "totalSpent": "B\$1,250.50",
      "favoriteCategories": ["Electronics", "Fashion", "Food"],
      "icon": "shopping_bag",
      "color": Color(0xFF4CAF50),
    },
    'Seller': {
      "status": "Not Created",
      "isSetup": false,
      "shopName": "",
      "productsListed": 0,
      "totalEarnings": "B\$0.00",
      "rating": 0.0,
      "completionPercentage": 0,
      "icon": "store",
      "color": Color(0xFF2196F3),
    },
    'Runner': {
      "status": "Not Created",
      "isSetup": false,
      "deliveriesCompleted": 0,
      "totalEarnings": "B\$0.00",
      "rating": 0.0,
      "vehicleVerified": false,
      "icon": "delivery_dining",
      "color": Color(0xFFFF9800),
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userProfile = await UserService.instance.getCurrentUserProfile();
      final subProfiles = await UserService.instance.getUserSubProfiles();

      setState(() {
        _userProfile = userProfile;
        _subProfiles = subProfiles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSubProfile(String profileType) async {
    setState(() => _isLoading = true);

    try {
      String displayName = '';
      switch (profileType) {
        case 'seller':
          displayName = '${_userProfile?['full_name']} Shop';
          break;
        case 'runner':
          displayName = '${_userProfile?['full_name']} Delivery';
          break;
        default:
          displayName = '${_userProfile?['full_name']} $profileType';
      }

      await UserService.instance.createSubProfile(
        profileType: profileType,
        displayName: displayName,
        profileData: {'created_via': 'profile_management'},
      );

      // Navigate to appropriate setup screen
      switch (profileType) {
        case 'seller':
          Navigator.pushNamed(context, '/seller-profile-setup-screen');
          break;
        case 'runner':
          _showRunnerSetupDialog();
          break;
      }

      // Reload data
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create $profileType profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await AuthService.instance.signOut();

        if (mounted) {
          // Clear all navigation stack and go to login
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.loginScreen,
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to logout: ${e.toString()}')),
          );
        }
      }
    }
  }

  bool _hasProfileType(String profileType) {
    return _subProfiles.any(
      (profile) =>
          profile['profile_type'] == profileType &&
          profile['is_active'] == true,
    );
  }

  void _handleProfileSwitch(String profileType) {
    HapticFeedback.selectionClick();

    if (!_profilesData[profileType]!['isSetup']) {
      _handleSetupProfile(profileType);
      return;
    }

    setState(() {
      _activeProfile = profileType;
    });

    // Navigate to respective dashboard/screen based on profile
    switch (profileType) {
      case 'Shopper':
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.marketplaceHomeScreen,
        );
        break;
      case 'Seller':
        _navigateToSellerDashboard();
        break;
      case 'Runner':
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.deliveryRunnerDashboardScreen,
        );
        break;
    }

    Fluttertoast.showToast(
      msg: "Switched to $profileType profile",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleSetupProfile(String profileType) {
    switch (profileType) {
      case 'Seller':
        Navigator.pushNamed(context, AppRoutes.sellerProfileSetupScreen);
        break;
      case 'Runner':
        _showRunnerSetupDialog();
        break;
    }
  }

  void _showRunnerSetupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                CustomIconWidget(
                  iconName: 'delivery_dining',
                  color: _profilesData['Runner']!['color'],
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Setup Runner Profile',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To become a delivery runner, you need to:',
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),
                SizedBox(height: 2.h),
                _buildRequirementItem('Valid driving license'),
                _buildRequirementItem('Vehicle registration'),
                _buildRequirementItem('Insurance documents'),
                _buildRequirementItem('Background check'),
                SizedBox(height: 2.h),
                Text(
                  'The setup process takes 3-5 business days for verification.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.runnerProfileSetupScreen,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _profilesData['Runner']!['color'],
                ),
                child: const Text('Start Setup'),
              ),
            ],
          ),
    );
  }

  Widget _buildRequirementItem(String requirement) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle_outline',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              requirement,
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSellerDashboard() {
    // Navigate to seller dashboard (would be implemented)
    Fluttertoast.showToast(
      msg: "Seller dashboard would open here",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleQuickAction(String action) {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'settings':
        Navigator.pushNamed(context, AppRoutes.userProfileScreen);
        break;
      case 'help':
        _showHelpDialog();
        break;
      case 'verification':
        _showVerificationDialog();
        break;
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Profile Management Help'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multiple Profiles:',
                  style: AppTheme.lightTheme.textTheme.titleSmall,
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Shopper: Buy products and services\n'
                  '• Seller: Sell your products online\n'
                  '• Runner: Deliver orders and earn money',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Switch profiles anytime by tapping the profile cards below.',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Account Verification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: _userData['isVerified'] ? 'verified' : 'pending',
                  color:
                      _userData['isVerified']
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.error,
                  size: 12.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  _userData['isVerified']
                      ? 'Your account is verified'
                      : 'Account verification pending',
                  style: AppTheme.lightTheme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  _userData['isVerified']
                      ? 'You have full access to all features.'
                      : 'Complete verification to access all features.',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile Management'),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to marketplace home with safe fallback
            try {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppRoutes.marketplaceHomeScreen);
              }
            } catch (e) {
              // Fallback to marketplace home
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.marketplaceHomeScreen,
                (Route<dynamic> route) => false,
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const CustomIconWidget(iconName: 'logout'),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Profile Card
                _buildMainProfileCard(),

                SizedBox(height: 4.h),

                // Sub-Profiles Section
                _buildSubProfilesSection(),

                SizedBox(height: 4.h),

                // Quick Actions
                _buildQuickActionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainProfileCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 12.w,
            backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            child:
                _userProfile?['avatar_url'] != null
                    ? ClipOval(
                      child: CustomImageWidget(
                        imageUrl: _userProfile!['avatar_url'],
                        width: 24.w,
                        height: 24.w,
                        fit: BoxFit.cover,
                      ),
                    )
                    : CustomIconWidget(
                      iconName: 'person',
                      size: 12.w,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
          ),

          SizedBox(height: 2.h),

          // User Name
          Text(
            _userProfile?['full_name'] ?? 'User Name',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 1.h),

          // User Email
          Text(
            _userProfile?['email'] ?? 'user@example.com',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 1.h),

          // User Role Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Text(
              (_userProfile?['role'] ?? 'buyer').toString().toUpperCase(),
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubProfilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Profiles',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 2.h),

        // Seller Profile Card
        _buildProfileTypeCard(
          'seller',
          'Seller Profile',
          'Sell your products on the marketplace',
          'storefront',
          _hasProfileType('seller'),
        ),

        SizedBox(height: 3.h),

        // Runner Profile Card
        _buildProfileTypeCard(
          'runner',
          'Runner Profile',
          'Deliver orders and earn money',
          'delivery_dining',
          _hasProfileType('runner'),
        ),
      ],
    );
  }

  Widget _buildProfileTypeCard(
    String profileType,
    String title,
    String description,
    String iconName,
    bool hasProfile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color:
              hasProfile
                  ? AppTheme.lightTheme.colorScheme.primary.withValues(
                    alpha: 0.3,
                  )
                  : AppTheme.lightTheme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color:
                  hasProfile
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color:
                  hasProfile
                      ? Colors.white
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
          ),

          SizedBox(width: 4.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          hasProfile
              ? Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Text(
                  'Active',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : ElevatedButton(
                onPressed: () => _createSubProfile(profileType),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  minimumSize: Size(20.w, 5.h),
                ),
                child: Text(
                  'Setup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton('Edit Profile', 'edit', () {
                // Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile feature coming soon!'),
                  ),
                );
              }),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildQuickActionButton('Settings', 'settings', () {
                Navigator.pushNamed(context, AppRoutes.userProfileScreen);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String iconName,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        foregroundColor: AppTheme.lightTheme.colorScheme.primary,
        elevation: 2,
        minimumSize: Size(double.infinity, 6.h),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: iconName,
            size: 6.w,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

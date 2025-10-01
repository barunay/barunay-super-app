import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showRetryOption = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  Future<void> _startInitialization() async {
    try {
      setState(() {
        _isInitializing = true;
        _showRetryOption = false;
      });

      // Run initialization tasks with timeout
      await Future.wait([
        _checkAuthenticationStatus(),
        _loadUserPreferences(),
        _fetchMarketplaceCategories(),
        _prepareCachedVendorData(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Initialization timeout');
        },
      );

      // Wait for minimum splash duration
      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        await _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showRetryOption = true;
        });
      }
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Check if Supabase is initialized and user is authenticated
      final authService = AuthService.instance;
      final currentUser = authService.currentUser;

      if (currentUser != null) {
        // Verify session is still valid
        await authService.refreshSession();
      }

      debugPrint('Auth check completed. User: ${currentUser?.id ?? 'None'}');
    } catch (e) {
      debugPrint('Auth check failed: $e');
      // Continue initialization even if auth check fails
    }
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences from local storage
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _fetchMarketplaceCategories() async {
    // Simulate fetching marketplace categories from database
    await Future.delayed(const Duration(milliseconds: 900));
  }

  Future<void> _prepareCachedVendorData() async {
    // Simulate preparing cached vendor data
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final authService = AuthService.instance;
      final userService = UserService.instance;

      // Check authentication status
      final isAuthenticated = authService.isSignedIn;

      String nextRoute;

      if (isAuthenticated) {
        // User is authenticated, navigate directly to marketplace home
        // Profile management is now accessible through the marketplace app
        nextRoute = AppRoutes.marketplaceHomeScreen;
      } else {
        // User is not authenticated
        nextRoute = AppRoutes.loginScreen;
      }

      debugPrint('Navigating to: $nextRoute');

      if (mounted) {
        Navigator.pushReplacementNamed(context, nextRoute);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback navigation
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
      }
    }
  }

  void _retryInitialization() {
    _startInitialization();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.primaryColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.lightTheme.primaryColor,
                AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
                AppTheme.secondaryLight.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App Logo
                              Container(
                                width: 25.w,
                                height: 25.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4.w),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'B',
                                    style: AppTheme
                                        .lightTheme.textTheme.displayMedium
                                        ?.copyWith(
                                      color: AppTheme.lightTheme.primaryColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 3.h),
                              // App Name
                              Text(
                                'Barunay',
                                style: AppTheme
                                    .lightTheme.textTheme.headlineLarge
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8.sp,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              // Tagline
                              Text(
                                'Super App',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 4.sp,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Loading Section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isInitializing
                        ? _buildLoadingIndicator()
                        : _buildRetrySection(),
                    SizedBox(height: 2.h),
                    Text(
                      _isInitializing
                          ? 'Setting up your marketplace experience...'
                          : 'Connection timeout. Please try again.',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 3.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Footer Section
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Column(
                  children: [
                    Text(
                      'Connecting Brunei\'s Marketplace',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 3.sp,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Version 1.0.0',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 2.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 8.w,
      height: 8.w,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildRetrySection() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'refresh',
          color: Colors.white,
          size: 8.w,
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: _retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.lightTheme.primaryColor,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          child: Text(
            'Retry',
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 3.5.sp,
            ),
          ),
        ),
      ],
    );
  }
}

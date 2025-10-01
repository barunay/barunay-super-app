import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Add this import for kIsWeb
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/custom_text_field.dart';
import './widgets/location_permission_card.dart';
import './widgets/password_strength_indicator.dart';
import './widgets/terms_checkbox.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State variables
  bool _termsAccepted = false;
  bool _locationPermissionGranted = false;
  bool _isLoading = false;
  int _currentStep = 1;
  final int _totalSteps = 2;
  String? _emailError;
  String? _passwordError;

  // Mock user data for validation
  final List<Map<String, dynamic>> _existingUsers = [
    {"email": "john.doe@example.com", "phone": "2234567"},
    {"email": "sarah.lim@gmail.com", "phone": "8765432"},
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _updateProgress();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scrollController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    double progress = _currentStep / _totalSteps;
    _progressController.animateTo(progress);
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission granted successfully!'),
          backgroundColor: AppTheme.successLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    // Check for duplicate email
    final existingUser = _existingUsers.firstWhere(
      (user) => user['email'].toLowerCase() == value.trim().toLowerCase(),
      orElse: () => {},
    );
    if (existingUser.isNotEmpty) {
      return 'This email is already registered';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{7}$').hasMatch(value.trim())) {
      return 'Please enter a valid 7-digit Brunei phone number';
    }

    // Check for duplicate phone
    final existingUser = _existingUsers.firstWhere(
      (user) => user['phone'] == value.trim(),
      orElse: () => {},
    );
    if (existingUser.isNotEmpty) {
      return 'This phone number is already registered';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool _isFormValid() {
    return _fullNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _termsAccepted &&
        _formKey.currentState?.validate() == true;
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      _showTermsError();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Register user with Supabase (no role required - defaults to buyer)
      final response = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      );

      if (response.user != null) {
        // Success
        if (!kIsWeb) {
          HapticFeedback.lightImpact();
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Registration successful! Please check your email to verify your account.',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          ),
        );

        // Navigate back to login
        Navigator.pushReplacementNamed(context, '/login-screen');
      } else {
        setState(() {
          _emailError = 'Registration failed. Please try again.';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        switch (e.statusCode) {
          case '422':
            _emailError = 'Email already exists. Please use a different email.';
            break;
          case '400':
            _passwordError =
                'Password is too weak. Please use a stronger password.';
            break;
          default:
            _emailError = 'Registration failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _emailError =
            'Network error. Please check your connection and try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTermsError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please agree to the terms and conditions.'),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section
                      _buildWelcomeSection(),

                      SizedBox(height: 3.h),

                      // Personal information
                      _buildPersonalInformation(),

                      SizedBox(height: 3.h),

                      // Location permission
                      LocationPermissionCard(
                        isGranted: _locationPermissionGranted,
                        onRequestPermission: _requestLocationPermission,
                      ),

                      SizedBox(height: 3.h),

                      // Terms and conditions
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: TermsCheckbox(
                          isChecked: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Create account button
                      _buildCreateAccountButton(),

                      SizedBox(height: 3.h),

                      // Login link
                      _buildLoginLink(),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 6.w,
                ),
              ),
              Expanded(
                child: Text(
                  'Join Our Community',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 12.w), // Balance the back button
            ],
          ),
          SizedBox(height: 2.h),
          // Progress indicator
          Container(
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Step $_currentStep of $_totalSteps',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Barunay',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Create your account to access Brunei\'s premier marketplace and delivery ecosystem. You can set up seller or runner profiles later when you\'re ready.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          CustomTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _fullNameController,
            validator: _validateFullName,
            keyboardType: TextInputType.name,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
          ),
          SizedBox(height: 2.h),
          CustomTextField(
            label: 'Email Address',
            hint: 'Enter your email address',
            controller: _emailController,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 2.h),
          CustomTextField(
            label: 'Phone Number',
            hint: 'Enter 7-digit number',
            controller: _phoneController,
            validator: _validatePhone,
            keyboardType: TextInputType.phone,
            isPhone: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
          ),
          SizedBox(height: 2.h),
          CustomTextField(
            label: 'Password',
            hint: 'Create a strong password',
            controller: _passwordController,
            validator: _validatePassword,
            isPassword: true,
            onChanged: (value) {
              setState(() {});
              // Validate confirm password field when password changes
              _formKey.currentState?.validate();
            },
          ),
          PasswordStrengthIndicator(password: _passwordController.text),
          SizedBox(height: 2.h),
          CustomTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            validator: _validateConfirmPassword,
            isPassword: true,
            onChanged: (value) {
              setState(() {});
              // Re-validate this field when confirm password changes
              _formKey.currentState?.validate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: SizedBox(
        width: double.infinity,
        height: 6.h,
        child: ElevatedButton(
          onPressed: _isFormValid() && !_isLoading ? _handleRegistration : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFormValid() && !_isLoading
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline,
            foregroundColor: Colors.white,
            elevation: _isFormValid() && !_isLoading ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Create Account',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () =>
            Navigator.pushReplacementNamed(context, '/login-screen'),
        child: RichText(
          text: TextSpan(
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Sign In',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/seller_service.dart';
import './widgets/business_info_section_widget.dart';
import './widgets/setup_progress_widget.dart';
import './widgets/shop_customization_section_widget.dart';
import './widgets/terms_acceptance_section_widget.dart';
import './widgets/verification_section_widget.dart';

class SellerProfileSetupScreen extends StatefulWidget {
  const SellerProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<SellerProfileSetupScreen> createState() =>
      _SellerProfileSetupScreenState();
}

class _SellerProfileSetupScreenState extends State<SellerProfileSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4; // Reduced from 5 to 4 steps
  bool _isLoading = false;

  // Form data
  final Map<String, dynamic> _formData = {
    'shopName': '',
    'username': '', // New field
    'businessCategory': '',
    'shopDescription': '',
    'businessRegistration': null,
    'icVerification': null,
    'addressConfirmed': false,
    'verificationSkipped': false, // New field for skip functionality
    'shopLogo': null,
    'bannerImage': null,
    'operatingHours': {},
    'shippingOptions': [],
    'returnPolicy': '',
    'pricingTemplate': '',
    'termsAccepted': false,
  };

  // Form validation - Updated step validation
  final Map<String, bool> _stepValidation = {
    '0': false, // Business Info
    '1': false, // Verification (now optional)
    '2': false, // Shop Customization (moved from step 3)
    '3': false, // Terms Acceptance (moved from step 4)
  };

  List<String> _bruneiBusinessCategories = [
    'Food & Beverages',
    'Fashion & Clothing',
    'Electronics & Technology',
    'Health & Beauty',
    'Home & Garden',
    'Sports & Recreation',
    'Arts & Crafts',
    'Automotive',
    'Books & Education',
    'Services',
    'Others',
  ];

  List<String> _bruneiBanks = [
    'BIBD - Bank Islam Brunei Darussalam',
    'Standard Chartered Bank',
    'Maybank',
    'United Overseas Bank (UOB)',
    'Bank of China',
    'HSBC Bank',
    'Citibank',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
    _validateCurrentStep();
  }

  void _validateCurrentStep() {
    bool isValid = false;

    switch (_currentStep) {
      case 0: // Business Info
        isValid = _formData['shopName'].toString().isNotEmpty &&
            _formData['username']
                .toString()
                .isNotEmpty && // Added username validation
            _formData['businessCategory'].toString().isNotEmpty &&
            _formData['shopDescription'].toString().isNotEmpty;
        break;
      case 1: // Verification (Now Optional)
        // Allow step to be valid if either verified OR skipped
        isValid = (_formData['businessRegistration'] != null &&
                _formData['icVerification'] != null &&
                _formData['addressConfirmed'] == true) ||
            _formData['verificationSkipped'] == true;
        break;
      case 2: // Shop Customization
        isValid = _formData['shopLogo'] != null;
        break;
      case 3: // Terms Acceptance
        isValid = _formData['termsAccepted'] == true;
        break;
    }

    setState(() {
      _stepValidation[_currentStep.toString()] = isValid;
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1 &&
        _stepValidation[_currentStep.toString()] == true) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    if (_stepValidation[_currentStep.toString()] != true) {
      Fluttertoast.showToast(
        msg: "Please complete all required fields",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.heavyImpact();

    try {
      // Create seller profile via service with username
      final result = await SellerService().createSellerProfile(
        businessName: _formData['shopName'],
        username: _formData['username'], // New parameter
        businessCategory: _formData['businessCategory'],
        businessDescription: _formData['shopDescription'],
        businessAddress: 'Brunei', // Default address
        shopSettings: {
          'shop_logo': _formData['shopLogo'],
          'banner_image': _formData['bannerImage'],
          'operating_hours': _formData['operatingHours'],
          'shipping_options': _formData['shippingOptions'],
          'return_policy': _formData['returnPolicy'],
        },
        hasBusinessRegistration: _formData['businessRegistration'] != null,
        hasICVerification: _formData['icVerification'] != null,
        addressConfirmed: _formData['addressConfirmed'] ?? false,
        verificationSkipped: _formData['verificationSkipped'] ?? false,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Show success dialog with review status message
        final isUpdate = result['is_update'] ?? false;
        _showSuccessDialog(result['verification_status'], isUpdate);
      } else {
        throw Exception(result['error'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = "Failed to create profile: ${e.toString()}";

      // Provide more user-friendly error messages
      if (e.toString().contains('already exists')) {
        errorMessage =
            "You already have a seller profile. Please contact support if you need to make changes.";
      } else if (e
          .toString()
          .contains('user_sub_profiles_user_id_profile_type_key')) {
        errorMessage =
            "Seller profile already exists for your account. Please try refreshing the app.";
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSuccessDialog(String verificationStatus, [bool isUpdate = false]) {
    String title;
    String message;
    String actionText;

    if (isUpdate) {
      title = 'Profile Updated Successfully!';
      message = verificationStatus == 'pending'
          ? 'Your seller profile has been updated and is under review by our admin team. You will be notified once approved.'
          : 'Your seller profile has been successfully updated.';
      actionText = 'Continue';
    } else {
      if (verificationStatus == 'pending') {
        title = 'Profile Submitted for Review!';
        message =
            'Your seller profile has been submitted and is under review by our admin team. You will be notified once approved.';
        actionText = 'Continue';
      } else {
        title = 'Seller Profile Created!';
        message =
            'Congratulations! Your seller profile has been successfully created.';
        actionText = 'Start Selling';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.tertiary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: verificationStatus == 'pending'
                    ? 'schedule'
                    : 'celebration',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                size: 10.w,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Shop Name: ${_formData['shopName']}',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Category: ${_formData['businessCategory']}',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  if (verificationStatus == 'pending') ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      'Status: Under Review',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to profile management

              if (verificationStatus == 'pending') {
                Fluttertoast.showToast(
                  msg:
                      "Profile submitted for review. You'll be notified when approved.",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                );
              } else {
                Fluttertoast.showToast(
                  msg: "You can now start selling!",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              minimumSize: Size(double.infinity, 6.h),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  double get _completionPercentage {
    int completedSteps = 0;
    for (int i = 0; i <= _currentStep; i++) {
      if (_stepValidation[i.toString()] == true) {
        completedSteps++;
      }
    }
    return (completedSteps / _totalSteps) * 100;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with progress
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.shadowColor
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
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
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'Setup Your Seller Profile',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_completionPercentage.toInt()}%',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    SetupProgressWidget(
                      currentStep: _currentStep,
                      totalSteps: _totalSteps,
                      completionPercentage: _completionPercentage,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Step 1: Business Information
                    BusinessInfoSectionWidget(
                      formData: _formData,
                      categories: _bruneiBusinessCategories,
                      onDataChanged: _updateFormData,
                    ),

                    // Step 2: Verification (Optional)
                    VerificationSectionWidget(
                      formData: _formData,
                      onDataChanged: _updateFormData,
                    ),

                    // Step 3: Shop Customization (No Bank Details)
                    ShopCustomizationSectionWidget(
                      formData: _formData,
                      onDataChanged: _updateFormData,
                    ),

                    // Step 4: Terms Acceptance
                    TermsAcceptanceSectionWidget(
                      formData: _formData,
                      onDataChanged: _updateFormData,
                    ),
                  ],
                ),
              ),

              // Navigation buttons
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.shadowColor
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(0, 6.h),
                            side: BorderSide(
                              color: AppTheme.lightTheme.colorScheme.outline,
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: AppTheme.lightTheme.textTheme.labelLarge,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                    Expanded(
                      flex: _currentStep > 0 ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_currentStep == _totalSteps - 1
                                ? _completeSetup
                                : (_stepValidation[_currentStep.toString()] ==
                                        true
                                    ? _nextStep
                                    : null)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          minimumSize: Size(0, 6.h),
                          disabledBackgroundColor: AppTheme
                              .lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 5.w,
                                height: 5.w,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep == _totalSteps - 1
                                    ? 'Complete Setup'
                                    : 'Next',
                                style: AppTheme.lightTheme.textTheme.labelLarge
                                    ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
}

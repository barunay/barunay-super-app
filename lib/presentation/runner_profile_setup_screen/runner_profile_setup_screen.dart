import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/availability_preferences_widget.dart';
import './widgets/background_check_consent_widget.dart';
import './widgets/banking_setup_widget.dart';
import './widgets/document_upload_widget.dart';
import './widgets/personal_verification_widget.dart';
import './widgets/progress_stepper_widget.dart';
import './widgets/safety_training_widget.dart';
import './widgets/vehicle_registration_widget.dart';

class RunnerProfileSetupScreen extends StatefulWidget {
  const RunnerProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<RunnerProfileSetupScreen> createState() =>
      _RunnerProfileSetupScreenState();
}

class _RunnerProfileSetupScreenState extends State<RunnerProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  bool _isLoading = false;

  // Step completion tracking
  Map<int, bool> _stepCompletion = {
    0: false, // Personal Verification
    1: false, // Vehicle Registration
    2: false, // Document Upload
    3: false, // Banking Setup
    4: false, // Availability Preferences
    5: false, // Background Check Consent
    6: false, // Safety Training
  };

  // Form data storage
  Map<String, dynamic> _formData = {
    'personalVerification': {},
    'vehicleRegistration': {},
    'documents': {},
    'banking': {},
    'availability': {},
    'backgroundCheck': {},
    'safetyTraining': {},
  };

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Personal Verification',
      'subtitle': 'Verify your identity',
      'icon': 'person_outline',
      'description': 'Upload ID and take verification selfie',
    },
    {
      'title': 'Vehicle Registration',
      'subtitle': 'Add your delivery vehicle',
      'icon': 'directions_car',
      'description': 'Vehicle type, license plate, and photos',
    },
    {
      'title': 'Documentation',
      'subtitle': 'Upload required documents',
      'icon': 'description',
      'description': 'License, registration, and insurance',
    },
    {
      'title': 'Banking Setup',
      'subtitle': 'Setup payment method',
      'icon': 'account_balance',
      'description': 'Bank account and mobile wallet',
    },
    {
      'title': 'Availability',
      'subtitle': 'Set your working hours',
      'icon': 'schedule',
      'description': 'Schedule and preferred delivery areas',
    },
    {
      'title': 'Background Check',
      'subtitle': 'Consent and references',
      'icon': 'security',
      'description': 'Background verification consent',
    },
    {
      'title': 'Safety Training',
      'subtitle': 'Complete safety course',
      'icon': 'school',
      'description': 'Delivery protocols and guidelines',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticFeedback.lightImpact();
  }

  void _updateStepCompletion(
      int step, bool isComplete, Map<String, dynamic> data) {
    setState(() {
      _stepCompletion[step] = isComplete;
      String dataKey = '';
      switch (step) {
        case 0:
          dataKey = 'personalVerification';
          break;
        case 1:
          dataKey = 'vehicleRegistration';
          break;
        case 2:
          dataKey = 'documents';
          break;
        case 3:
          dataKey = 'banking';
          break;
        case 4:
          dataKey = 'availability';
          break;
        case 5:
          dataKey = 'backgroundCheck';
          break;
        case 6:
          dataKey = 'safetyTraining';
          break;
      }
      _formData[dataKey] = data;
    });
  }

  bool get _isCurrentStepComplete => _stepCompletion[_currentStep] ?? false;
  bool get _isAllStepsComplete =>
      _stepCompletion.values.every((completed) => completed);

  double get _completionPercentage {
    int completedSteps =
        _stepCompletion.values.where((completed) => completed).length;
    return completedSteps / _steps.length;
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call to create runner profile
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Show success dialog
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
                iconName: 'check',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                size: 10.w,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Runner Profile Created!',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Your delivery runner profile has been submitted for approval. You\'ll receive a notification within 24-48 hours.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/marketplace-home-screen',
                        (route) => false,
                      );
                    },
                    child: const Text('Continue Shopping'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                        context,
                        '/delivery-runner-dashboard-screen',
                      );
                    },
                    child: const Text('View Dashboard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Failed'),
        content: const Text(
          'There was an error creating your runner profile. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return PersonalVerificationWidget(
          initialData: _formData['personalVerification'],
          onDataChanged: (data) =>
              _updateStepCompletion(0, data['isComplete'] ?? false, data),
        );
      case 1:
        return VehicleRegistrationWidget(
          initialData: _formData['vehicleRegistration'],
          onDataChanged: (data) =>
              _updateStepCompletion(1, data['isComplete'] ?? false, data),
        );
      case 2:
        return DocumentUploadWidget(
          initialData: _formData['documents'],
          onDataChanged: (data) =>
              _updateStepCompletion(2, data['isComplete'] ?? false, data),
        );
      case 3:
        return BankingSetupWidget(
          initialData: _formData['banking'],
          onDataChanged: (data) =>
              _updateStepCompletion(3, data['isComplete'] ?? false, data),
        );
      case 4:
        return AvailabilityPreferencesWidget(
          initialData: _formData['availability'],
          onDataChanged: (data) =>
              _updateStepCompletion(4, data['isComplete'] ?? false, data),
        );
      case 5:
        return BackgroundCheckConsentWidget(
          initialData: _formData['backgroundCheck'],
          onDataChanged: (data) =>
              _updateStepCompletion(5, data['isComplete'] ?? false, data),
        );
      case 6:
        return SafetyTrainingWidget(
          initialData: _formData['safetyTraining'],
          onDataChanged: (data) =>
              _updateStepCompletion(6, data['isComplete'] ?? false, data),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'close',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Become a Delivery Runner',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Earn up to B\$500/week',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(_completionPercentage * 100).toInt()}%',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Progress Stepper
                  Container(
                    padding: EdgeInsets.all(4.w),
                    child: ProgressStepperWidget(
                      steps: _steps,
                      currentStep: _currentStep,
                      stepCompletion: _stepCompletion,
                      onStepTap: _goToStep,
                    ),
                  ),

                  // Step Content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentStep = index;
                        });
                      },
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Step Header
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.lightTheme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme
                                          .lightTheme.colorScheme.shadow
                                          .withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 12.w,
                                          height: 12.w,
                                          decoration: BoxDecoration(
                                            color:
                                                _stepCompletion[index] == true
                                                    ? AppTheme.lightTheme
                                                        .colorScheme.tertiary
                                                    : AppTheme.lightTheme
                                                        .colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: CustomIconWidget(
                                            iconName:
                                                _stepCompletion[index] == true
                                                    ? 'check'
                                                    : _steps[index]['icon'],
                                            color:
                                                _stepCompletion[index] == true
                                                    ? Colors.white
                                                    : AppTheme.lightTheme
                                                        .colorScheme.primary,
                                            size: 6.w,
                                          ),
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _steps[index]['title'],
                                                style: AppTheme.lightTheme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600),
                                              ),
                                              Text(
                                                _steps[index]['description'],
                                                style: AppTheme.lightTheme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: AppTheme
                                                      .lightTheme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 3.h),

                              // Step Content
                              _buildStepContent(),

                              SizedBox(
                                  height: 10.h), // Space for bottom buttons
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, 6.h),
                      side: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.outline,
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentStep > 0) SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCurrentStepComplete ||
                          _currentStep == _steps.length - 1
                      ? (_currentStep == _steps.length - 1 &&
                              _isAllStepsComplete
                          ? _completeSetup
                          : _nextStep)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentStep == _steps.length - 1 && _isAllStepsComplete
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.primary,
                    minimumSize: Size(0, 6.h),
                  ),
                  child: Text(
                    _currentStep == _steps.length - 1
                        ? (_isAllStepsComplete
                            ? 'Start Earning'
                            : 'Complete All Steps')
                        : 'Continue',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

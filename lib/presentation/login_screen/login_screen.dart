import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email or phone number is required';
    }

    if (value.startsWith('+673')) {
      if (!AuthService.instance.isValidBruneiPhone(value)) {
        return 'Please enter a valid Brunei phone number (+673XXXXXXX)';
      }
    } else if (value.contains('@')) {
      if (!AuthService.instance.isValidEmail(value)) {
        return 'Please enter a valid email address';
      }
    } else {
      return 'Please enter a valid email or phone number';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = _validateEmailOrPhone(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _passwordError = 'Please fill in all fields.';
        });
        return;
      }

      AuthResponse response;

      // Check if input is phone number or email
      if (email.startsWith('+673')) {
        response = await AuthService.instance.signInWithPhone(
          phone: email,
          password: password,
        );
      } else {
        response = await AuthService.instance.signIn(
          email: email,
          password: password,
        );
      }

      if (response.user != null && response.session != null) {
        // Success - trigger haptic feedback
        if (!kIsWeb) {
          HapticFeedback.lightImpact();
        }

        // Navigate to marketplace home screen regardless of user role
        // Users can access profile management and other role-specific features from the main app
        Navigator.pushReplacementNamed(
            context, AppRoutes.marketplaceHomeScreen);
      } else {
        setState(() {
          _passwordError = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        final errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          _passwordError = errorMessage.split('Exception:').last.trim();
        } else if (errorMessage.contains('network') ||
            errorMessage.contains('Network') ||
            errorMessage.contains('connection')) {
          _passwordError =
              'Network error. Please check your connection and try again.';
        } else {
          _passwordError = 'Login failed. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);

    try {
      bool success = false;

      switch (provider) {
        case 'Google':
          success = await AuthService.instance.signInWithGoogle();
          break;
        case 'Apple':
          success = await AuthService.instance.signInWithApple();
          break;
        case 'Facebook':
          success = await AuthService.instance.signInWithFacebook();
          break;
      }

      if (success) {
        // Listen for auth state change to handle navigation
        AuthService.instance.authStateChanges.listen((data) {
          if (data.event == AuthChangeEvent.signedIn && mounted) {
            Navigator.pushReplacementNamed(
                context, AppRoutes.marketplaceHomeScreen);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$provider login cancelled or failed.'),
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        String displayMessage;

        if (errorMessage.contains('Exception:')) {
          displayMessage = errorMessage.split('Exception:').last.trim();
        } else if (errorMessage.contains('network') ||
            errorMessage.contains('Network') ||
            errorMessage.contains('connection')) {
          displayMessage =
              'Network error. Please check your connection and try again.';
        } else {
          displayMessage = '$provider login failed. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (kIsWeb) return;

    try {
      // For demo purposes - in real implementation, you would use local_auth package
      await Future.delayed(const Duration(milliseconds: 500));
      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Biometric authentication is not implemented yet. Please use email/password login.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !AuthService.instance.isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid email address first')),
      );
      return;
    }

    try {
      await AuthService.instance.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset link sent to your email')),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        String displayMessage;

        if (errorMessage.contains('Exception:')) {
          displayMessage = errorMessage.split('Exception:').last.trim();
        } else if (errorMessage.contains('network') ||
            errorMessage.contains('Network') ||
            errorMessage.contains('connection')) {
          displayMessage =
              'Network error. Please check your connection and try again.';
        } else {
          displayMessage = 'Failed to send reset email. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Column(
              children: [
                // App Logo
                _buildAppLogo(),

                // Welcome Text
                _buildWelcomeText(),

                // Demo credentials section
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Credentials',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCredentialRow(
                          'Buyer', 'buyer@marketplace.com', 'password123'),
                      _buildCredentialRow(
                          'Seller', 'seller@marketplace.com', 'password123'),
                      _buildCredentialRow(
                          'Runner', 'runner@marketplace.com', 'password123'),
                      _buildCredentialRow(
                          'Admin', 'admin@marketplace.com', 'password123'),
                    ],
                  ),
                ),

                // Login Form
                _buildLoginForm(),

                // Forgot Password Link
                _buildForgotPasswordLink(),

                // Login Button
                _buildLoginButton(),

                // Biometric Login (Mobile only)
                if (!kIsWeb) _buildBiometricLogin(),

                // Divider
                _buildDivider(),

                // Social Login Options
                _buildSocialLoginOptions(),

                const Spacer(),

                // Sign Up Link
                _buildSignUpLink(),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'storefront',
            color: Colors.white,
            size: 8.w,
          ),
          SizedBox(height: 1.h),
          Text(
            'BARUNAY',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Sign in to access Brunei\'s marketplace',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCredentialRow(String role, String email, String password) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$role: $email / $password',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.content_copy, size: 16, color: Colors.grey[600]),
            onPressed: () {
              // Copy credentials to clipboard
              Clipboard.setData(ClipboardData(text: '$email:$password'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('$role credentials copied to clipboard')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email/Phone Field
          _buildEmailField(),
          SizedBox(height: 2.h),
          // Password Field
          _buildPasswordField(),
          SizedBox(height: 2.h),
          // Remember Me Checkbox
          _buildRememberMeCheckbox(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Email or Phone',
            hintText: 'Enter your email or +673XXXXXXX',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'alternate_email',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
            ),
            errorText: _emailError,
            errorMaxLines: 2,
          ),
          onChanged: (value) {
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock_outline',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
            ),
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName: _isPasswordVisible ? 'visibility_off' : 'visibility',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
            errorText: _passwordError,
            errorMaxLines: 2,
          ),
          onChanged: (value) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
          onFieldSubmitted: (_) => _handleLogin(),
        ),
      ],
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() => _rememberMe = value ?? false);
          },
        ),
        Expanded(
          child: Text(
            'Remember me',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: Text(
          'Forgot Password?',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? SizedBox(
                width: 5.w,
                height: 5.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                'Login',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBiometricLogin() {
    return Column(
      children: [
        Text(
          'or use biometric authentication',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: _handleBiometricLogin,
          child: Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: CustomIconWidget(
              iconName: 'fingerprint',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 8.w,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.lightTheme.colorScheme.outline,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'OR',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.lightTheme.colorScheme.outline,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginOptions() {
    return Column(
      children: [
        // Google Login
        _buildSocialLoginButton(
          'Continue with Google',
          'google',
          Colors.white,
          Colors.black87,
          () => _handleSocialLogin('Google'),
        ),
        SizedBox(height: 2.h),
        // Apple Login (iOS) / Facebook Login (Android/Web)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          _buildSocialLoginButton(
            'Continue with Apple',
            'apple',
            Colors.black,
            Colors.white,
            () => _handleSocialLogin('Apple'),
          )
        else
          _buildSocialLoginButton(
            'Continue with Facebook',
            'facebook',
            const Color(0xFF1877F2),
            Colors.white,
            () => _handleSocialLogin('Facebook'),
          ),
      ],
    );
  }

  Widget _buildSocialLoginButton(
    String text,
    String iconName,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: iconName == 'google'
                  ? 'g_translate'
                  : iconName == 'apple'
                      ? 'apple'
                      : 'facebook',
              color: textColor,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Text(
              text,
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to the marketplace? ',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/user-registration-screen');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign Up',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

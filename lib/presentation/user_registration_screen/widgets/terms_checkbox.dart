import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TermsCheckbox extends StatelessWidget {
  final bool isChecked;
  final Function(bool?) onChanged;

  const TermsCheckbox({
    Key? key,
    required this.isChecked,
    required this.onChanged,
  }) : super(key: key);

  void _openTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Terms of Service',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Text(
            '''Welcome to Barunay Super App. By creating an account, you agree to the following terms:

1. Account Responsibility
You are responsible for maintaining the security of your account and all activities that occur under your account.

2. Marketplace Usage
- Provide accurate product/service information
- Respect intellectual property rights
- Follow local laws and regulations

3. Delivery Services
- Accurate pickup and delivery information required
- Respect delivery timeframes
- Handle items with care

4. Communication
- Maintain respectful communication
- No spam or inappropriate content
- Report suspicious activities

5. Privacy
We protect your personal information as outlined in our Privacy Policy.

6. Termination
We reserve the right to suspend accounts that violate these terms.

Last updated: September 11, 2025''',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Privacy Policy',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Text(
            '''Barunay Super App Privacy Policy

Information We Collect:
- Account information (name, email, phone)
- Location data for delivery services
- Transaction history
- Communication records

How We Use Information:
- Provide marketplace and delivery services
- Improve user experience
- Ensure platform security
- Comply with legal requirements

Information Sharing:
- With delivery partners for service fulfillment
- With vendors for transaction processing
- With authorities when legally required

Data Security:
We implement industry-standard security measures to protect your information.

Your Rights:
- Access your personal data
- Request data correction
- Delete your account
- Opt-out of marketing communications

Contact Us:
For privacy concerns, contact us at privacy@barunay.app

Last updated: September 11, 2025''',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 6.w,
          height: 6.w,
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: AppTheme.lightTheme.colorScheme.primary,
            checkColor: Colors.white,
            side: BorderSide(
              color: AppTheme.lightTheme.colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _openTermsOfService(context),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _openPrivacyPolicy(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TermsAcceptanceSectionWidget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const TermsAcceptanceSectionWidget({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<TermsAcceptanceSectionWidget> createState() =>
      _TermsAcceptanceSectionWidgetState();
}

class _TermsAcceptanceSectionWidgetState
    extends State<TermsAcceptanceSectionWidget> {
  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              height: 50.h,
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ),
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'Terms & Agreement',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Please review and accept our terms to complete your seller profile setup.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),

          SizedBox(height: 3.h),

          // Seller agreement
          _buildTermsCard(
            title: 'Seller Agreement',
            subtitle: 'Terms and conditions for selling on our platform',
            icon: 'gavel',
            onTap:
                () => _showTermsDialog(
                  'Seller Agreement',
                  'By becoming a seller on Barunay Super App, you agree to:\n\n'
                      '1. Provide accurate product information\n'
                      '2. Deliver products as described\n'
                      '3. Maintain good customer service\n'
                      '4. Follow marketplace policies\n'
                      '5. Comply with local laws and regulations\n\n'
                      'Full terms and conditions apply. Contact support for more information.',
                ),
          ),

          SizedBox(height: 2.h),

          // Marketplace policies
          _buildTermsCard(
            title: 'Marketplace Policies',
            subtitle: 'Guidelines for maintaining a quality marketplace',
            icon: 'policy',
            onTap:
                () => _showTermsDialog(
                  'Marketplace Policies',
                  'Our marketplace policies include:\n\n'
                      '• Product Quality Standards\n'
                      '• Return and Refund Policies\n'
                      '• Customer Communication Guidelines\n'
                      '• Shipping and Delivery Requirements\n'
                      '• Prohibited Items List\n'
                      '• Account Suspension Criteria\n\n'
                      'Violation of these policies may result in account restrictions.',
                ),
          ),

          SizedBox(height: 4.h),

          // Acceptance checkbox
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(
                alpha: 0.05,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    widget.formData['termsAccepted'] == true
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline.withValues(
                          alpha: 0.3,
                        ),
                width: widget.formData['termsAccepted'] == true ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: widget.formData['termsAccepted'] ?? false,
                  onChanged: (value) {
                    widget.onDataChanged('termsAccepted', value ?? false);
                  },
                  activeColor: AppTheme.lightTheme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I agree to all terms and conditions',
                        style: AppTheme.lightTheme.textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.formData['termsAccepted'] == true
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme
                                          .lightTheme
                                          .colorScheme
                                          .onSurface,
                            ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'By checking this box, I confirm that I have read and agree to the Seller Agreement and Marketplace Policies outlined above.',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color:
                                  AppTheme
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
          ),

          SizedBox(height: 3.h),

          // Summary card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.tertiary.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.tertiary.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'assignment_turned_in',
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Setup Summary',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildSummaryItem(
                  'Shop Name',
                  widget.formData['shopName'] ?? 'Not set',
                ),
                _buildSummaryItem(
                  'Category',
                  widget.formData['businessCategory'] ?? 'Not set',
                ),
                _buildSummaryItem(
                  'Bank Account',
                  widget.formData['bankName']?.isNotEmpty == true
                      ? 'Added'
                      : 'Not added',
                ),
                _buildSummaryItem(
                  'Shop Logo',
                  widget.formData['shopLogo'] != null
                      ? 'Uploaded'
                      : 'Not uploaded',
                ),
                _buildSummaryItem(
                  'Terms Accepted',
                  widget.formData['termsAccepted'] == true ? 'Yes' : 'No',
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Final note
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.secondary.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.secondary.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to Start Selling?',
                        style: AppTheme.lightTheme.textTheme.titleSmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Once you complete the setup, you can immediately start adding products and selling to customers in Brunei. Our team will review your profile and verify your documents within 2-3 business days.',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard({
    required String title,
    required String subtitle,
    required String icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(minimumSize: Size(16.w, 5.h)),
            child: Text(
              'Read',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

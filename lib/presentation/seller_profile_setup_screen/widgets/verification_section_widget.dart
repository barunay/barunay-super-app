import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VerificationSectionWidget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const VerificationSectionWidget({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<VerificationSectionWidget> createState() =>
      _VerificationSectionWidgetState();
}

class _VerificationSectionWidgetState extends State<VerificationSectionWidget> {
  bool _isUploadingBusinessReg = false;
  bool _isUploadingIC = false;

  Future<void> _uploadBusinessRegistration() async {
    setState(() {
      _isUploadingBusinessReg = true;
    });

    // Simulate file upload
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isUploadingBusinessReg = false;
    });

    widget.onDataChanged('businessRegistration', 'business_registration.pdf');
    Fluttertoast.showToast(
      msg: "Business registration uploaded successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _uploadICVerification() async {
    setState(() {
      _isUploadingIC = true;
    });

    // Simulate file upload
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isUploadingIC = false;
    });

    widget.onDataChanged('icVerification', 'ic_verification.pdf');
    Fluttertoast.showToast(
      msg: "IC verification uploaded successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _confirmAddress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Bandar Seri Begawan, Brunei Darussalam',
              style: AppTheme.lightTheme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Is this your correct business address?',
              style: AppTheme.lightTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Change'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDataChanged('addressConfirmed', true);
              Fluttertoast.showToast(
                msg: "Address confirmed",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _skipVerification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 10.w,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Skip Verification?',
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
              'You can skip verification for now and complete it later. Your seller profile will show as "not yet verified" until documents are uploaded and approved.',
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
              child: Text(
                'Note: You can always verify your business later from your seller dashboard to gain customer trust and unlock premium features.',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
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
              widget.onDataChanged('verificationSkipped', true);
              Fluttertoast.showToast(
                msg: "Verification skipped. You can complete it later.",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
            ),
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSkipped = widget.formData['verificationSkipped'] == true;
    final bool hasUploads = widget.formData['businessRegistration'] != null &&
        widget.formData['icVerification'] != null &&
        widget.formData['addressConfirmed'] == true;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Business Verification',
                          style: AppTheme.lightTheme.textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.tertiary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.tertiary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'OPTIONAL',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                              fontSize: 8.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Verify your business to build trust with customers and unlock additional features. You can skip this step and complete it later.',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Skip status indicator
          if (isSkipped) ...[
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.secondary
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Skipped',
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'You can complete verification later from your seller dashboard.',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onDataChanged('verificationSkipped', false);
                    },
                    child: Text(
                      'Verify Now',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),
          ] else ...[
            // Business registration upload
            _buildUploadCard(
              title: 'Business Registration',
              subtitle: 'Upload your business registration certificate',
              icon: 'business',
              isRequired: false,
              isUploaded: widget.formData['businessRegistration'] != null,
              isUploading: _isUploadingBusinessReg,
              onTap: _uploadBusinessRegistration,
            ),

            SizedBox(height: 2.h),

            // IC verification upload
            _buildUploadCard(
              title: 'IC Verification',
              subtitle: 'Upload your identity card for individual sellers',
              icon: 'credit_card',
              isRequired: false,
              isUploaded: widget.formData['icVerification'] != null,
              isUploading: _isUploadingIC,
              onTap: _uploadICVerification,
            ),

            SizedBox(height: 2.h),

            // Address confirmation
            _buildUploadCard(
              title: 'Address Confirmation',
              subtitle: 'Confirm your business location',
              icon: 'location_on',
              isRequired: false,
              isUploaded: widget.formData['addressConfirmed'] == true,
              isUploading: false,
              onTap: _confirmAddress,
            ),

            SizedBox(height: 3.h),

            // Skip verification button
            Center(
              child: OutlinedButton.icon(
                onPressed: _skipVerification,
                icon: CustomIconWidget(
                  iconName: 'skip_next',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 5.w,
                ),
                label: Text(
                  'Skip Verification for Now',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                  minimumSize: Size(50.w, 6.h),
                ),
              ),
            ),

            SizedBox(height: 3.h),
          ],

          // Verification benefits
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.tertiary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.tertiary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'verified',
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Verification Benefits',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildBenefitItem('Verified badge on your shop profile'),
                _buildBenefitItem('Higher search ranking in marketplace'),
                _buildBenefitItem('Access to premium selling features'),
                _buildBenefitItem('Customer trust and credibility'),
                _buildBenefitItem('Priority customer support'),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Important note
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.secondary
                    .withValues(alpha: 0.2),
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
                        'Verification Process',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Your documents will be reviewed within 2-3 business days. We\'ll notify you once verification is complete. You can continue setting up your shop even without verification.',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
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

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required String icon,
    required bool isRequired,
    required bool isUploaded,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded
              ? AppTheme.lightTheme.colorScheme.tertiary
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: isUploaded ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: isUploaded
                  ? AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isUploading
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    )
                  : CustomIconWidget(
                      iconName: isUploaded ? 'check_circle' : icon,
                      color: isUploaded
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w,
                    ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUploaded
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    if (isRequired) ...[
                      SizedBox(width: 1.w),
                      Text(
                        '*',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
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
          ElevatedButton(
            onPressed: isUploading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: Size(20.w, 5.h),
            ),
            child: Text(
              isUploaded ? 'Done' : 'Upload',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: 'check',
            color: AppTheme.lightTheme.colorScheme.tertiary,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              benefit,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

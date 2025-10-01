import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/seller_service.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SellerProfileDeletionDialog extends StatefulWidget {
  const SellerProfileDeletionDialog({Key? key}) : super(key: key);

  @override
  State<SellerProfileDeletionDialog> createState() =>
      _SellerProfileDeletionDialogState();
}

class _SellerProfileDeletionDialogState
    extends State<SellerProfileDeletionDialog> {
  final SellerService _sellerService = SellerService();
  bool _isLoading = false;
  bool _isCheckingEligibility = true;
  Map<String, dynamic>? _eligibilityResult;

  @override
  void initState() {
    super.initState();
    _checkDeletionEligibility();
  }

  Future<void> _checkDeletionEligibility() async {
    try {
      final result = await _sellerService.checkCanDeleteSellerProfile();
      setState(() {
        _eligibilityResult = result;
        _isCheckingEligibility = false;
      });
    } catch (e) {
      setState(() {
        _eligibilityResult = {
          'can_delete': false,
          'reason': 'Error checking eligibility: ${e.toString()}',
        };
        _isCheckingEligibility = false;
      });
    }
  }

  Future<void> _deleteSellerProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _sellerService.deleteSellerProfile();

      if (result['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Seller profile deleted successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'Failed to delete seller profile',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEligibilityCheck() {
    if (_isCheckingEligibility) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 2.h),
          Text(
            'Checking deletion eligibility...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    if (_eligibilityResult == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 6.h),
          SizedBox(height: 2.h),
          Text(
            'Unable to check deletion eligibility',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final canDelete = _eligibilityResult!['can_delete'] as bool? ?? false;
    final reason = _eligibilityResult!['reason'] as String? ?? '';
    final activeProductCount =
        _eligibilityResult!['active_product_count'] as int? ?? 0;

    if (!canDelete) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 6.h),
          SizedBox(height: 2.h),
          Text(
            'Cannot Delete Seller Profile',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            reason,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (activeProductCount > 0) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.h),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(1.h),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.orange[700],
                    size: 4.h,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '$activeProductCount Active Products',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Please delete or deactivate all products before proceeding',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_forever_outlined, color: Colors.red, size: 8.h),
        SizedBox(height: 2.h),
        Text(
          'Delete Seller Profile',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(2.h),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(1.h),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[700],
                size: 5.h,
              ),
              SizedBox(height: 1.h),
              Text(
                'Warning: This action cannot be undone',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Deleting your seller profile will permanently remove:\n'
                '• Your business information and settings\n'
                '• Seller verification status\n'
                '• Access to seller features\n'
                '• All associated seller data',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.red[700],
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'You currently have no active products, so deletion is allowed.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _eligibilityResult?['can_delete'] as bool? ?? false;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.h)),
      child: Container(
        padding: EdgeInsets.all(3.h),
        constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 80.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delete Seller Profile',
                    style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 3.h,
                  ),
                ],
              ),
              Divider(height: 3.h, thickness: 1),

              // Content
              _buildEligibilityCheck(),

              SizedBox(height: 3.h),

              // Action buttons
              if (!_isCheckingEligibility) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (canDelete) ...[
                      SizedBox(width: 2.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _deleteSellerProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          ),
                          child:
                              _isLoading
                                  ? SizedBox(
                                    height: 2.h,
                                    width: 2.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'Delete Profile',
                                    style: AppTheme.lightTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!canDelete) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: Text(
                        'Go Back to Products',
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
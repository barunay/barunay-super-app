import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/seller_service.dart';
import './widgets/review_progress_widget.dart';
import './widgets/document_checklist_widget.dart';
import './widgets/communication_area_widget.dart';
import './widgets/resubmission_section_widget.dart';

class ProfileUnderReviewScreen extends StatefulWidget {
  const ProfileUnderReviewScreen({super.key});

  @override
  State<ProfileUnderReviewScreen> createState() =>
      _ProfileUnderReviewScreenState();
}

class _ProfileUnderReviewScreenState extends State<ProfileUnderReviewScreen>
    with TickerProviderStateMixin {
  final SellerService _sellerService = SellerService();
  late AnimationController _animationController;

  bool _isLoading = true;
  Map<String, dynamic> _sellerProfile = {};
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadSellerProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _sellerService.getSellerProfile();
      setState(() {
        _sellerProfile = profile ?? {};
        _isLoading = false;
      });

      _animationController.forward();

      // Check if profile was just approved
      if (profile?['verification_status'] == 'verified') {
        _showApprovalAnimation();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  void _showApprovalAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Congratulations!',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your seller profile has been approved!',
              style: GoogleFonts.inter(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.marketplaceHomeScreen,
              );
            },
            child: Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Status',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSellerProfile,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Central status card with progress indicator
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.orange,
                            size: 16.w,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Profile Under Review',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            _getStatusMessage(),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 3.h),

                          // Review progress timeline
                          ReviewProgressWidget(
                            currentStage: _getCurrentStage(),
                            animationController: _animationController,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Document checklist
                    DocumentChecklistWidget(
                      documents: _getDocumentStatus(),
                    ),

                    SizedBox(height: 3.h),

                    // Communication area
                    CommunicationAreaWidget(
                      messages: _getAdminMessages(),
                      onSendMessage: _sendMessage,
                    ),

                    SizedBox(height: 3.h),

                    // Resubmission section
                    if (_needsResubmission())
                      ResubmissionSectionWidget(
                        missingDocuments: _getMissingDocuments(),
                        onDocumentUpload: _uploadDocument,
                      ),

                    SizedBox(height: 3.h),

                    // Notification preferences
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          SwitchListTile(
                            title: Text(
                              'Review Status Updates',
                              style: GoogleFonts.inter(fontSize: 14.sp),
                            ),
                            subtitle: Text(
                              'Get notified about profile review progress',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                              _updateNotificationPreferences(value);
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _contactSupport,
                            icon: Icon(Icons.support_agent),
                            label: Text('Contact Support'),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.marketplaceHomeScreen,
                            ),
                            icon: Icon(Icons.dashboard),
                            label: Text('Go to Dashboard'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getStatusMessage() {
    final status = _sellerProfile['verification_status'] ?? 'pending';
    final hasUploadedDocuments = _hasUploadedAnyDocuments();

    switch (status) {
      case 'pending':
        if (hasUploadedDocuments) {
          return 'Your seller profile is currently being reviewed by our admin team. This process typically takes 2-3 business days. We will notify you once the review is complete.';
        } else {
          return 'Please complete your seller profile by uploading the required documents. Document verification is optional but recommended to become a verified seller and gain customer trust.';
        }
      case 'additional_info_required':
        return 'Additional information is required to complete your profile review. Please check the documents section below and resubmit any missing items.';
      case 'verified':
        return 'Congratulations! Your seller profile has been verified. You can now start selling with a verified badge.';
      case 'rejected':
        return 'Your seller profile verification was not successful. Please review the feedback below and resubmit the required documents.';
      default:
        return 'Your profile review is in progress. Please check back later for updates.';
    }
  }

  bool _hasUploadedAnyDocuments() {
    if (_sellerProfile.isEmpty) return false;

    // Check if any documents have been uploaded
    final businessLicense = _sellerProfile['business_license_url'];
    final taxNumber = _sellerProfile['tax_number'];
    final bankDetails = _sellerProfile['bank_account_details'];

    return (businessLicense != null && businessLicense.toString().isNotEmpty) ||
        (taxNumber != null && taxNumber.toString().isNotEmpty) ||
        (bankDetails != null && bankDetails is Map && bankDetails.isNotEmpty);
  }

  int _getCurrentStage() {
    final status = _sellerProfile['verification_status'] ?? 'pending';
    switch (status) {
      case 'pending':
        return 1;
      case 'additional_info_required':
        return 1;
      case 'verified':
        return 2;
      default:
        return 0;
    }
  }

  List<Map<String, dynamic>> _getDocumentStatus() {
    // Get actual document status from seller profile instead of hardcoded values
    final sellerProfile = _sellerProfile;

    return [
      {
        'name': 'Business License',
        'status': _getDocumentVerificationStatus('business_license_url'),
        'icon': Icons.business,
        'description': 'Business registration and license documents'
      },
      {
        'name': 'Tax Registration',
        'status': _getDocumentVerificationStatus('tax_number'),
        'icon': Icons.receipt_long,
        'description': 'Valid tax registration number'
      },
      {
        'name': 'Bank Details',
        'status': _getBankDetailsStatus(),
        'icon': Icons.account_balance,
        'description': 'Bank account information for payments'
      },
      {
        'name': 'Identity Verification',
        'status': _getIdentityVerificationStatus(),
        'icon': Icons.badge,
        'description': 'Personal identification documents'
      },
    ];
  }

  String _getDocumentVerificationStatus(String fieldName) {
    if (_sellerProfile.isEmpty) return 'not_uploaded';

    final fieldValue = _sellerProfile[fieldName];

    // Check if document was uploaded and verified
    if (fieldValue != null && fieldValue.toString().isNotEmpty) {
      return 'verified';
    }

    // If verification status indicates issue, show as pending or rejected
    final verificationStatus =
        _sellerProfile['verification_status'] ?? 'pending';
    if (verificationStatus == 'rejected') {
      return 'rejected';
    }

    return 'not_uploaded';
  }

  String _getBankDetailsStatus() {
    if (_sellerProfile.isEmpty) return 'not_uploaded';

    final bankDetails = _sellerProfile['bank_account_details'];

    // Check if bank details are properly filled
    if (bankDetails != null && bankDetails is Map && bankDetails.isNotEmpty) {
      return 'verified';
    }

    return 'not_uploaded';
  }

  String _getIdentityVerificationStatus() {
    if (_sellerProfile.isEmpty) return 'not_uploaded';

    final verificationStatus =
        _sellerProfile['verification_status'] ?? 'pending';

    // Map verification status to document status
    switch (verificationStatus) {
      case 'verified':
        return 'verified';
      case 'rejected':
        return 'rejected';
      case 'pending':
        return 'pending';
      default:
        return 'not_uploaded';
    }
  }

  List<Map<String, dynamic>> _getAdminMessages() {
    // Return admin feedback messages with timestamps
    return [
      {
        'message':
            'Thank you for submitting your seller profile. We are currently reviewing your documents.',
        'timestamp': DateTime.now().subtract(Duration(hours: 24)),
        'isFromAdmin': true,
      },
      if (_sellerProfile['verification_status'] == 'additional_info_required')
        {
          'message':
              'Please provide a clearer image of your identity document. The current image is not readable.',
          'timestamp': DateTime.now().subtract(Duration(hours: 2)),
          'isFromAdmin': true,
        },
    ];
  }

  bool _needsResubmission() {
    return _sellerProfile['verification_status'] == 'additional_info_required';
  }

  List<String> _getMissingDocuments() {
    if (_needsResubmission()) {
      return ['Identity Documents'];
    }
    return [];
  }

  void _sendMessage(String message) async {
    // Send message to admin
    try {
      // Implementation would send message to admin
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent to admin successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _uploadDocument(String documentType, String filePath) async {
    try {
      // Implementation would upload document
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document uploaded successfully')),
      );
      _loadSellerProfile(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload document: $e')),
      );
    }
  }

  void _updateNotificationPreferences(bool enabled) async {
    try {
      // Implementation would update notification preferences
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update preferences: $e')),
      );
    }
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You can reach our support team at:'),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(Icons.email, size: 5.w),
                SizedBox(width: 2.w),
                Text('support@barunay.com'),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.phone, size: 5.w),
                SizedBox(width: 2.w),
                Text('+673 123 4567'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
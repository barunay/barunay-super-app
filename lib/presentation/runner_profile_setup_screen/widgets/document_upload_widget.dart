import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentUploadWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const DocumentUploadWidget({
    Key? key,
    required this.initialData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  bool _drivingLicenseUploaded = false;
  bool _vehicleRegistrationUploaded = false;
  bool _insuranceUploaded = false;

  DateTime? _insuranceExpiryDate;
  DateTime? _licenseExpiryDate;

  final List<Map<String, dynamic>> _documents = [
    {
      'key': 'drivingLicense',
      'title': 'Driving License',
      'subtitle': 'Valid driving license for your vehicle type',
      'icon': 'drive_eta',
      'required': true,
      'hasExpiry': true,
    },
    {
      'key': 'vehicleRegistration',
      'title': 'Vehicle Registration',
      'subtitle': 'Vehicle registration certificate/card',
      'icon': 'description',
      'required': true,
      'hasExpiry': false,
    },
    {
      'key': 'insurance',
      'title': 'Insurance Certificate',
      'subtitle': 'Valid vehicle insurance certificate',
      'icon': 'security',
      'required': true,
      'hasExpiry': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _drivingLicenseUploaded =
        widget.initialData['drivingLicenseUploaded'] ?? false;
    _vehicleRegistrationUploaded =
        widget.initialData['vehicleRegistrationUploaded'] ?? false;
    _insuranceUploaded = widget.initialData['insuranceUploaded'] ?? false;

    if (widget.initialData['insuranceExpiryDate'] != null) {
      _insuranceExpiryDate =
          DateTime.parse(widget.initialData['insuranceExpiryDate']);
    }
    if (widget.initialData['licenseExpiryDate'] != null) {
      _licenseExpiryDate =
          DateTime.parse(widget.initialData['licenseExpiryDate']);
    }
  }

  void _updateData() {
    bool isComplete = _drivingLicenseUploaded &&
        _vehicleRegistrationUploaded &&
        _insuranceUploaded &&
        _licenseExpiryDate != null &&
        _insuranceExpiryDate != null;

    widget.onDataChanged({
      'drivingLicenseUploaded': _drivingLicenseUploaded,
      'vehicleRegistrationUploaded': _vehicleRegistrationUploaded,
      'insuranceUploaded': _insuranceUploaded,
      'licenseExpiryDate': _licenseExpiryDate?.toIso8601String(),
      'insuranceExpiryDate': _insuranceExpiryDate?.toIso8601String(),
      'isComplete': isComplete,
    });
  }

  void _uploadDocument(String docType) {
    setState(() {
      switch (docType) {
        case 'drivingLicense':
          _drivingLicenseUploaded = true;
          break;
        case 'vehicleRegistration':
          _vehicleRegistrationUploaded = true;
          break;
        case 'insurance':
          _insuranceUploaded = true;
          break;
      }
    });
    _updateData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getDocumentTitle(docType)} uploaded successfully'),
      ),
    );
  }

  String _getDocumentTitle(String docType) {
    switch (docType) {
      case 'drivingLicense':
        return 'Driving License';
      case 'vehicleRegistration':
        return 'Vehicle Registration';
      case 'insurance':
        return 'Insurance Certificate';
      default:
        return 'Document';
    }
  }

  bool _isDocumentUploaded(String docType) {
    switch (docType) {
      case 'drivingLicense':
        return _drivingLicenseUploaded;
      case 'vehicleRegistration':
        return _vehicleRegistrationUploaded;
      case 'insurance':
        return _insuranceUploaded;
      default:
        return false;
    }
  }

  Future<void> _selectExpiryDate(String docType) async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 365));
    DateTime firstDate = DateTime.now();
    DateTime lastDate =
        DateTime.now().add(const Duration(days: 3650)); // 10 years

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Expiry Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate != null) {
      setState(() {
        if (docType == 'drivingLicense') {
          _licenseExpiryDate = pickedDate;
        } else if (docType == 'insurance') {
          _insuranceExpiryDate = pickedDate;
        }
      });
      _updateData();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isDateExpiringSoon(DateTime? date) {
    if (date == null) return false;
    DateTime now = DateTime.now();
    DateTime thirtyDaysFromNow = now.add(const Duration(days: 30));
    return date.isBefore(thirtyDaysFromNow);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Documents',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Please upload clear, readable photos of the following documents',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 3.h),

        // Driving License
        _buildDocumentCard(
          title: 'Driving License',
          subtitle: 'Valid driving license for your vehicle type',
          icon: 'drive_eta',
          isUploaded: _drivingLicenseUploaded,
          onUpload: () => _uploadDocument('drivingLicense'),
          hasExpiry: true,
          expiryDate: _licenseExpiryDate,
          onSelectExpiry: () => _selectExpiryDate('drivingLicense'),
        ),

        SizedBox(height: 2.h),

        // Vehicle Registration
        _buildDocumentCard(
          title: 'Vehicle Registration',
          subtitle: 'Vehicle registration certificate/card',
          icon: 'description',
          isUploaded: _vehicleRegistrationUploaded,
          onUpload: () => _uploadDocument('vehicleRegistration'),
        ),

        SizedBox(height: 2.h),

        // Insurance Certificate
        _buildDocumentCard(
          title: 'Insurance Certificate',
          subtitle: 'Valid vehicle insurance certificate',
          icon: 'security',
          isUploaded: _insuranceUploaded,
          onUpload: () => _uploadDocument('insurance'),
          hasExpiry: true,
          expiryDate: _insuranceExpiryDate,
          onSelectExpiry: () => _selectExpiryDate('insurance'),
        ),

        SizedBox(height: 3.h),

        // Document Requirements Info
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Document Requirements',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildRequirementItem('• Documents must be clear and readable'),
              _buildRequirementItem('• All text and details must be visible'),
              _buildRequirementItem('• Documents must be current and valid'),
              _buildRequirementItem(
                  '• Upload both front and back sides if applicable'),
              _buildRequirementItem('• Ensure good lighting and focus'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required String icon,
    required bool isUploaded,
    required VoidCallback onUpload,
    bool hasExpiry = false,
    DateTime? expiryDate,
    VoidCallback? onSelectExpiry,
  }) {
    bool isExpiringSoon = hasExpiry && _isDateExpiringSoon(expiryDate);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded
              ? AppTheme.lightTheme.colorScheme.tertiary
              : AppTheme.lightTheme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: isUploaded ? 'check_circle' : icon,
                color: isUploaded
                    ? AppTheme.lightTheme.colorScheme.tertiary
                    : AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasExpiry) ...[
            SizedBox(height: 2.h),
            GestureDetector(
              onTap: onSelectExpiry,
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpiringSoon
                        ? AppTheme.lightTheme.colorScheme.error
                        : AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'calendar_today',
                      color: isExpiringSoon
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiry Date',
                            style: AppTheme.lightTheme.textTheme.labelMedium,
                          ),
                          Text(
                            _formatDate(expiryDate),
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: isExpiringSoon
                                  ? AppTheme.lightTheme.colorScheme.error
                                  : AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'keyboard_arrow_right',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 5.w,
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 2.h),
          if (!isUploaded) ...[
            ElevatedButton(
              onPressed: onUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                minimumSize: Size(double.infinity, 5.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'upload_file',
                    color: Colors.white,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text('Upload $title'),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.tertiary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'check',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text('$title uploaded and verified'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

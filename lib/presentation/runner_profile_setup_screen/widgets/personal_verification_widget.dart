import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PersonalVerificationWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const PersonalVerificationWidget({
    Key? key,
    required this.initialData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<PersonalVerificationWidget> createState() =>
      _PersonalVerificationWidgetState();
}

class _PersonalVerificationWidgetState
    extends State<PersonalVerificationWidget> {
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  bool _icUploaded = false;
  bool _selfieUploaded = false;
  bool _emergencyContactAdded = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _emergencyContactController.text =
        widget.initialData['emergencyContact'] ?? '';
    _emergencyPhoneController.text = widget.initialData['emergencyPhone'] ?? '';
    _icUploaded = widget.initialData['icUploaded'] ?? false;
    _selfieUploaded = widget.initialData['selfieUploaded'] ?? false;
    _emergencyContactAdded =
        widget.initialData['emergencyContactAdded'] ?? false;
  }

  void _updateData() {
    bool isComplete = _icUploaded && _selfieUploaded && _emergencyContactAdded;

    widget.onDataChanged({
      'emergencyContact': _emergencyContactController.text,
      'emergencyPhone': _emergencyPhoneController.text,
      'icUploaded': _icUploaded,
      'selfieUploaded': _selfieUploaded,
      'emergencyContactAdded': _emergencyContactAdded,
      'isComplete': isComplete,
    });
  }

  void _uploadIC() {
    setState(() {
      _icUploaded = true;
    });
    _updateData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IC uploaded successfully with data extraction'),
      ),
    );
  }

  void _takeSelfie() {
    setState(() {
      _selfieUploaded = true;
    });
    _updateData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification selfie captured successfully'),
      ),
    );
  }

  void _validateEmergencyContact() {
    bool hasContact = _emergencyContactController.text.trim().isNotEmpty;
    bool hasPhone = _emergencyPhoneController.text.trim().isNotEmpty;

    setState(() {
      _emergencyContactAdded = hasContact && hasPhone;
    });
    _updateData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IC Upload Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _icUploaded
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
                    iconName: _icUploaded ? 'check_circle' : 'badge',
                    color: _icUploaded
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
                          'Identity Card Upload',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Upload clear photos of both sides of your IC',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_icUploaded) ...[
                SizedBox(height: 2.h),
                ElevatedButton(
                  onPressed: _uploadIC,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'camera_alt',
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      const Text('Upload IC'),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(height: 2.h),
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
                      const Text('IC uploaded with automatic data extraction'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Selfie Verification Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selfieUploaded
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
                    iconName: _selfieUploaded ? 'check_circle' : 'face',
                    color: _selfieUploaded
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
                          'Identity Verification Selfie',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Take a selfie for identity matching with your IC',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_selfieUploaded) ...[
                SizedBox(height: 2.h),
                ElevatedButton(
                  onPressed: _takeSelfie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    minimumSize: Size(double.infinity, 5.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'camera_alt',
                        color: Colors.white,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      const Text('Take Verification Selfie'),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(height: 2.h),
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
                      const Text('Identity verification complete'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Emergency Contact Section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _emergencyContactAdded
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
                    iconName: _emergencyContactAdded
                        ? 'check_circle'
                        : 'contact_emergency',
                    color: _emergencyContactAdded
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
                          'Emergency Contact Information',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Provide emergency contact details for safety',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _emergencyContactController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Name',
                  hintText: 'Enter full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _validateEmergencyContact(),
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  hintText: '+673 XXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => _validateEmergencyContact(),
              ),
              if (_emergencyContactAdded) ...[
                SizedBox(height: 2.h),
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
                      const Text('Emergency contact information saved'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}

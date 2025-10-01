import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BackgroundCheckConsentWidget extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const BackgroundCheckConsentWidget({
    Key? key,
    required this.initialData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<BackgroundCheckConsentWidget> createState() =>
      _BackgroundCheckConsentWidgetState();
}

class _BackgroundCheckConsentWidgetState
    extends State<BackgroundCheckConsentWidget> {
  bool _backgroundCheckConsent = false;
  bool _criminalRecordConsent = false;

  final TextEditingController _reference1NameController =
      TextEditingController();
  final TextEditingController _reference1PhoneController =
      TextEditingController();
  final TextEditingController _reference2NameController =
      TextEditingController();
  final TextEditingController _reference2PhoneController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _backgroundCheckConsent =
        widget.initialData['backgroundCheckConsent'] ?? false;
    _criminalRecordConsent =
        widget.initialData['criminalRecordConsent'] ?? false;

    _reference1NameController.text = widget.initialData['reference1Name'] ?? '';
    _reference1PhoneController.text =
        widget.initialData['reference1Phone'] ?? '';
    _reference2NameController.text = widget.initialData['reference2Name'] ?? '';
    _reference2PhoneController.text =
        widget.initialData['reference2Phone'] ?? '';
  }

  void _updateData() {
    bool isComplete = _backgroundCheckConsent &&
        _criminalRecordConsent &&
        _reference1NameController.text.trim().isNotEmpty &&
        _reference1PhoneController.text.trim().isNotEmpty &&
        _reference2NameController.text.trim().isNotEmpty &&
        _reference2PhoneController.text.trim().isNotEmpty;

    widget.onDataChanged({
      'backgroundCheckConsent': _backgroundCheckConsent,
      'criminalRecordConsent': _criminalRecordConsent,
      'reference1Name': _reference1NameController.text,
      'reference1Phone': _reference1PhoneController.text,
      'reference2Name': _reference2NameController.text,
      'reference2Phone': _reference2PhoneController.text,
      'isComplete': isComplete,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Background Verification',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'For the safety of our platform, all runners undergo background verification',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 3.h),

        // Background Check Consent
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _backgroundCheckConsent
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
                    iconName:
                        _backgroundCheckConsent ? 'check_circle' : 'security',
                    color: _backgroundCheckConsent
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
                          'Background Check Authorization',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'I authorize a background check to be conducted',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: _backgroundCheckConsent,
                    onChanged: (value) {
                      setState(() {
                        _backgroundCheckConsent = value ?? false;
                      });
                      _updateData();
                    },
                  ),
                ],
              ),
              if (_backgroundCheckConsent) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Check Process:',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      _buildProcessItem(
                          '• Identity verification against national database'),
                      _buildProcessItem(
                          '• Criminal record check through official channels'),
                      _buildProcessItem('• Reference verification and contact'),
                      _buildProcessItem(
                          '• Previous employment or education verification'),
                      _buildProcessItem(
                          '• Driving record check (if applicable)'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Criminal Record Consent
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _criminalRecordConsent
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: _criminalRecordConsent ? 'check_circle' : 'gavel',
                color: _criminalRecordConsent
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
                      'Criminal Record Declaration',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'I declare that I have no criminal record that would affect my ability to safely perform deliveries',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: _criminalRecordConsent,
                onChanged: (value) {
                  setState(() {
                    _criminalRecordConsent = value ?? false;
                  });
                  _updateData();
                },
              ),
            ],
          ),
        ),

        SizedBox(height: 4.h),

        // Reference Contacts
        Text(
          'Reference Contacts',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Provide 2 references who can vouch for your character and reliability',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 3.h),

        // Reference 1
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'person',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Reference 1',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              TextFormField(
                controller: _reference1NameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter reference\'s full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => _updateData(),
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _reference1PhoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+673 XXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => _updateData(),
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Reference 2
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'person',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Reference 2',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              TextFormField(
                controller: _reference2NameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter reference\'s full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => _updateData(),
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _reference2PhoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+673 XXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => _updateData(),
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Privacy and Security Notice
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.tertiaryContainer
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.tertiary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lock',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Privacy & Security',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildPrivacyItem(
                  '• All information is encrypted and securely stored'),
              _buildPrivacyItem(
                  '• Background checks conducted by authorized agencies'),
              _buildPrivacyItem('• References contacted for verification only'),
              _buildPrivacyItem(
                  '• Information used solely for verification purposes'),
              _buildPrivacyItem('• Data retention as per legal requirements'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.tertiary,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reference1NameController.dispose();
    _reference1PhoneController.dispose();
    _reference2NameController.dispose();
    _reference2PhoneController.dispose();
    super.dispose();
  }
}

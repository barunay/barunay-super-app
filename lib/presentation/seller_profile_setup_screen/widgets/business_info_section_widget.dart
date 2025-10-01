import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BusinessInfoSectionWidget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final List<String> categories;
  final Function(String, dynamic) onDataChanged;

  const BusinessInfoSectionWidget({
    Key? key,
    required this.formData,
    required this.categories,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<BusinessInfoSectionWidget> createState() =>
      _BusinessInfoSectionWidgetState();
}

class _BusinessInfoSectionWidgetState extends State<BusinessInfoSectionWidget> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCheckingAvailability = false;
  bool _shopNameAvailable = true;
  bool _isCheckingUsernameAvailability = false;
  bool _usernameAvailable = true;

  @override
  void initState() {
    super.initState();
    _shopNameController.text = widget.formData['shopName'] ?? '';
    _usernameController.text = widget.formData['username'] ?? '';
    _descriptionController.text = widget.formData['shopDescription'] ?? '';
  }

  Future<void> _checkShopNameAvailability(String shopName) async {
    if (shopName.isEmpty) return;

    setState(() {
      _isCheckingAvailability = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock availability check (in real app, this would be an API call)
    final isAvailable = !shopName.toLowerCase().contains('test');

    setState(() {
      _isCheckingAvailability = false;
      _shopNameAvailable = isAvailable;
    });

    if (!isAvailable) {
      Fluttertoast.showToast(
        msg: "Shop name not available, try another one",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) return;

    setState(() {
      _isCheckingUsernameAvailability = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock availability check (in real app, this would be an API call)
    final isAvailable =
        !username.toLowerCase().contains('admin') && username.length >= 3;

    setState(() {
      _isCheckingUsernameAvailability = false;
      _usernameAvailable = isAvailable;
    });

    if (!isAvailable) {
      Fluttertoast.showToast(
        msg: "Username not available or invalid, try another one",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            'Business Information',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tell us about your business to help customers find and trust your shop.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),

          SizedBox(height: 3.h),

          // Shop name with availability checking
          Text(
            'Shop Name *',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _shopNameController,
            decoration: InputDecoration(
              hintText: 'Enter your shop name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              suffixIcon: _isCheckingAvailability
                  ? SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _shopNameController.text.isNotEmpty
                      ? CustomIconWidget(
                          iconName:
                              _shopNameAvailable ? 'check_circle' : 'cancel',
                          color: _shopNameAvailable
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme.lightTheme.colorScheme.error,
                          size: 6.w,
                        )
                      : null,
            ),
            onChanged: (value) {
              widget.onDataChanged('shopName', value);
              if (value.isNotEmpty) {
                _checkShopNameAvailability(value);
              }
            },
          ),
          if (!_shopNameAvailable && _shopNameController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Text(
                'This shop name is not available',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            ),

          SizedBox(height: 3.h),

          // Username field with availability checking
          Text(
            'Username *',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Choose a unique username',
              prefixText: '@',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              suffixIcon: _isCheckingUsernameAvailability
                  ? SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _usernameController.text.isNotEmpty
                      ? CustomIconWidget(
                          iconName:
                              _usernameAvailable ? 'check_circle' : 'cancel',
                          color: _usernameAvailable
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme.lightTheme.colorScheme.error,
                          size: 6.w,
                        )
                      : null,
            ),
            onChanged: (value) {
              // Remove special characters and convert to lowercase
              String cleanedValue =
                  value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
              if (cleanedValue != value) {
                _usernameController.value = TextEditingValue(
                  text: cleanedValue,
                  selection:
                      TextSelection.collapsed(offset: cleanedValue.length),
                );
              }
              widget.onDataChanged('username', cleanedValue);
              if (cleanedValue.isNotEmpty) {
                _checkUsernameAvailability(cleanedValue);
              }
            },
          ),
          if (!_usernameAvailable && _usernameController.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Text(
                'This username is not available or invalid',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Text(
              'Username can only contain letters, numbers, and underscores (3-30 characters)',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Business category
          Text(
            'Business Category *',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            value: widget.formData['businessCategory']?.isEmpty == true
                ? null
                : widget.formData['businessCategory'],
            decoration: InputDecoration(
              hintText: 'Select your business category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              widget.onDataChanged('businessCategory', value ?? '');
            },
          ),

          SizedBox(height: 3.h),

          // Shop description
          Text(
            'Shop Description *',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Describe your business, products, and what makes you unique...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              alignLabelWithHint: true,
            ),
            onChanged: (value) {
              widget.onDataChanged('shopDescription', value);
            },
          ),

          SizedBox(height: 3.h),

          // Tips section
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Tips for a Great Shop Profile',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildTipItem('Choose a memorable and unique shop name'),
                _buildTipItem('Pick a short, easy-to-remember username'),
                _buildTipItem('Select the most accurate business category'),
                _buildTipItem(
                    'Write a clear description of your products/services'),
                _buildTipItem(
                    'Mention your location (e.g., "Bandar Seri Begawan")'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.5.w,
            height: 1.5.w,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              tip,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

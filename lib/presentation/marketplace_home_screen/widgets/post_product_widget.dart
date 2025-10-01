import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/marketplace_service.dart';

class PostProductWidget extends StatefulWidget {
  final VoidCallback? onProductPosted;

  const PostProductWidget({Key? key, this.onProductPosted}) : super(key: key);

  @override
  State<PostProductWidget> createState() => _PostProductWidgetState();
}

class _PostProductWidgetState extends State<PostProductWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _locationController = TextEditingController();

  final MarketplaceService _marketplaceService = MarketplaceService();

  String _selectedCondition = 'good';
  String? _selectedCategoryId;
  String? _selectedBrandId;
  bool _isNegotiable = true;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBrands();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _marketplaceService.getProductCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await _marketplaceService.getProductBrands();
      setState(() {
        _brands = brands;
      });
    } catch (e) {
      print('Error loading brands: $e');
    }
  }

  Future<void> _checkSellerProfileAndPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Check if user has seller profile
      final hasProfile = await _marketplaceService.hasSellerProfile();

      if (!hasProfile) {
        // Show seller registration prompt
        _showSellerRegistrationPrompt();
        return;
      }

      // Proceed with posting
      await _postProduct();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _postProduct() async {
    try {
      await _marketplaceService.createProductListing(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        originalPrice:
            _originalPriceController.text.isNotEmpty
                ? double.tryParse(_originalPriceController.text)
                : null,
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        condition: _selectedCondition,
        locationText:
            _locationController.text.isEmpty ? null : _locationController.text,
        isNegotiable: _isNegotiable,
        tags: _generateTags(_titleController.text, _descriptionController.text),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Product posted successfully! It will be reviewed by admin before going live.',
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          ),
        );
        widget.onProductPosted?.call();
      }
    } catch (e) {
      throw e;
    }
  }

  List<String> _generateTags(String title, String description) {
    final text = '$title $description'.toLowerCase();
    final words = text.split(' ').where((word) => word.length > 2).toSet();
    return words.take(10).toList();
  }

  void _showSellerRegistrationPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const CustomIconWidget(
                  iconName: 'store',
                  color: Colors.orange,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                const Text('Seller Profile Required'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To post products on the marketplace, you need to register as a seller first.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Benefits of becoming a seller:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text('• Create unlimited product listings'),
                Text('• Reach thousands of customers'),
                Text('• Manage your business dashboard'),
                Text('• Track sales and earnings'),
                Text('• Get customer reviews and ratings'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close post product sheet
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close post product sheet
                  Navigator.pushNamed(
                    context,
                    AppRoutes.sellerProfileSetupScreen,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Register as Seller'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
            ),
            SizedBox(height: 3.h),

            Row(
              children: [
                const CustomIconWidget(iconName: 'add_box', size: 24),
                SizedBox(width: 2.w),
                Text(
                  'Post New Product',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Form Fields
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title *',
                hintText: 'e.g., iPhone 14 Pro Max - Space Black',
                prefixIcon: CustomIconWidget(iconName: 'title'),
              ),
              validator:
                  (value) =>
                      value?.isEmpty ?? true
                          ? 'Product title is required'
                          : null,
            ),

            SizedBox(height: 2.h),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe your product in detail',
                prefixIcon: CustomIconWidget(iconName: 'description'),
              ),
              maxLines: 3,
              validator:
                  (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
            ),

            SizedBox(height: 2.h),

            // Price Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (B\$) *',
                      hintText: '0.00',
                      prefixIcon: CustomIconWidget(iconName: 'payments'),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Price is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid price';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Original Price (B\$)',
                      hintText: '0.00 (optional)',
                      prefixIcon: CustomIconWidget(iconName: 'local_offer'),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Category and Condition
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: CustomIconWidget(iconName: 'category'),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Category'),
                      ),
                      ..._categories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category['id'],
                          child: Text(category['name'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged:
                        (value) => setState(() => _selectedCategoryId = value),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCondition,
                    decoration: const InputDecoration(
                      labelText: 'Condition',
                      prefixIcon: CustomIconWidget(iconName: 'verified'),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'new', child: Text('New')),
                      DropdownMenuItem(
                        value: 'like_new',
                        child: Text('Like New'),
                      ),
                      DropdownMenuItem(value: 'good', child: Text('Good')),
                      DropdownMenuItem(value: 'fair', child: Text('Fair')),
                      DropdownMenuItem(value: 'poor', child: Text('Poor')),
                    ],
                    onChanged:
                        (value) => setState(() => _selectedCondition = value!),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Brand and Location
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBrandId,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      prefixIcon: CustomIconWidget(iconName: 'brand'),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select Brand'),
                      ),
                      ..._brands.map(
                        (brand) => DropdownMenuItem<String>(
                          value: brand['id'],
                          child: Text(brand['name'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged:
                        (value) => setState(() => _selectedBrandId = value),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'e.g., Gadong',
                      prefixIcon: CustomIconWidget(iconName: 'location_on'),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Negotiable Checkbox
            CheckboxListTile(
              value: _isNegotiable,
              onChanged:
                  (value) => setState(() => _isNegotiable = value ?? true),
              title: const Text('Price is negotiable'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            SizedBox(height: 3.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _checkSellerProfileAndPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Post Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            SizedBox(height: 2.h),

            // Info Box
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                children: [
                  const CustomIconWidget(iconName: 'info', size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Your product will be reviewed by admin before going live on the marketplace.',
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            // Add bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

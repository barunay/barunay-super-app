import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/seller_service.dart';

class ProductFormWidget extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController originalPriceController;
  final TextEditingController locationController;

  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> brands;
  final String? selectedCategoryId;
  final String? selectedBrandId;
  final String selectedCondition;
  final bool isNegotiable;
  final List<String> tags;
  final Map<String, dynamic> specifications;
  final Map<String, dynamic> shippingInfo;

  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<bool> onNegotiableChanged;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<Map<String, dynamic>> onSpecificationsChanged;
  final ValueChanged<Map<String, dynamic>> onShippingInfoChanged;
  final Function(String?, List<String>) onCategoryChanged;

  const ProductFormWidget({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.originalPriceController,
    required this.locationController,
    required this.categories,
    required this.brands,
    this.selectedCategoryId,
    this.selectedBrandId,
    required this.selectedCondition,
    required this.isNegotiable,
    required this.tags,
    required this.specifications,
    required this.shippingInfo,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onConditionChanged,
    required this.onNegotiableChanged,
    required this.onTagsChanged,
    required this.onSpecificationsChanged,
    required this.onShippingInfoChanged,
  });

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final SellerService _sellerService = SellerService();
  List<Map<String, dynamic>> _currentCategories = [];
  List<String> _categoryPath = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    // Load root categories initially
    _loadRootCategories();
  }

  Future<void> _loadRootCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final response = await _sellerService._client.rpc(
        'get_category_hierarchy',
        {'p_parent_id': null},
      );

      setState(() {
        _currentCategories = List<Map<String, dynamic>>.from(response);
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
    }
  }

  Future<void> _loadSubcategories(String parentId) async {
    setState(() => _isLoadingCategories = true);

    try {
      final response = await _sellerService._client.rpc(
        'get_category_hierarchy',
        {'p_parent_id': parentId},
      );

      setState(() {
        _currentCategories = List<Map<String, dynamic>>.from(response);
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subcategories: $e')),
      );
    }
  }

  void _onCategorySelected(String categoryId) async {
    final selectedCategory = _currentCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
    );

    _categoryPath.add(selectedCategory['slug']);

    if (selectedCategory['has_children'] == true) {
      // Load subcategories
      await _loadSubcategories(categoryId);
    } else {
      // Final category selected
      widget.onCategoryChanged(categoryId, _categoryPath);
    }
  }

  void _goBackInCategoryPath() async {
    if (_categoryPath.isNotEmpty) {
      _categoryPath.removeLast();

      if (_categoryPath.isEmpty) {
        // Back to root categories
        await _loadRootCategories();
      } else {
        // Load parent categories - simplified implementation
        // In a full implementation, you'd track parent IDs
        await _loadRootCategories();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Information Section
          _buildSectionHeader('Product Information'),
          SizedBox(height: 1.h),

          _buildTextField(
            controller: widget.titleController,
            label: 'Product Title *',
            hint: 'Enter product title',
            maxLength: 100,
            validator:
                (value) => value?.isEmpty == true ? 'Title is required' : null,
          ),
          SizedBox(height: 1.h),

          // Dynamic Category Selection
          _buildDynamicCategorySelector(),
          SizedBox(height: 1.h),

          _buildDropdown(
            label: 'Brand (Optional)',
            value: widget.selectedBrandId,
            items:
                widget.brands
                    .map(
                      (brand) => DropdownMenuItem(
                        value: brand['id'] as String,
                        child: Text(brand['name'] as String),
                      ),
                    )
                    .toList(),
            onChanged: widget.onBrandChanged,
            hint: 'Select brand',
          ),
          SizedBox(height: 1.h),

          _buildTextField(
            controller: widget.descriptionController,
            label: 'Description *',
            hint: 'Describe your product in detail',
            maxLines: 3,
            maxLength: 1000,
            validator:
                (value) =>
                    value?.isEmpty == true ? 'Description is required' : null,
          ),
          SizedBox(height: 2.h),

          // Pricing Section
          _buildSectionHeader('Pricing'),
          SizedBox(height: 1.h),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: widget.priceController,
                  label: 'Price (BND) *',
                  hint: '0.00',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator:
                      (value) =>
                          value?.isEmpty == true ? 'Price is required' : null,
                  prefix: Text('B\$ '),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildTextField(
                  controller: widget.originalPriceController,
                  label: 'Original Price',
                  hint: '0.00',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  prefix: Text('B\$ '),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),

          _buildSwitchTile(
            title: 'Price Negotiable',
            subtitle: 'Allow buyers to negotiate the price',
            value: widget.isNegotiable,
            onChanged: widget.onNegotiableChanged,
          ),
          SizedBox(height: 2.h),

          // Condition Section
          _buildSectionHeader('Product Condition'),
          SizedBox(height: 1.h),

          _buildConditionSelector(),
          SizedBox(height: 2.h),

          // Location Section
          _buildSectionHeader('Location'),
          SizedBox(height: 1.h),

          _buildTextField(
            controller: widget.locationController,
            label: 'Location',
            hint: 'Enter pickup location',
            prefixIcon: Icons.location_on,
          ),
          SizedBox(height: 2.h),

          // Tags Section
          _buildSectionHeader('Tags'),
          SizedBox(height: 1.h),
          _buildTagsInput(),
        ],
      ),
    );
  }

  Widget _buildDynamicCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Category *',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_categoryPath.isNotEmpty)
              TextButton(
                onPressed: _goBackInCategoryPath,
                child: Text('Back', style: GoogleFonts.inter(fontSize: 11.sp)),
              ),
          ],
        ),
        SizedBox(height: 0.5.h),

        // Category breadcrumb
        if (_categoryPath.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _categoryPath.join(' > '),
              style: GoogleFonts.inter(fontSize: 12.sp),
            ),
          ),

        SizedBox(height: 1.h),

        if (_isLoadingCategories)
          const Center(child: CircularProgressIndicator())
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children:
                  _currentCategories.map((category) {
                    return ListTile(
                      title: Text(
                        category['name'],
                        style: GoogleFonts.inter(fontSize: 12.sp),
                      ),
                      trailing:
                          category['has_children'] == true
                              ? Icon(Icons.arrow_forward_ios, size: 4.w)
                              : null,
                      onTap: () => _onCategorySelected(category['id']),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? prefix,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefix: prefix,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 5.w) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
            counterText:
                maxLength != null
                    ? '${controller.text.length}/$maxLength'
                    : null,
          ),
          style: GoogleFonts.inter(fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
          ),
          style: GoogleFonts.inter(fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12.sp,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
                )
                : null,
        value: value,
        onChanged: onChanged,
        dense: true,
      ),
    );
  }

  Widget _buildConditionSelector() {
    final conditions = [
      {'value': 'new', 'label': 'New', 'description': 'Brand new, never used'},
      {
        'value': 'like_new',
        'label': 'Like New',
        'description': 'Excellent condition, barely used',
      },
      {'value': 'good', 'label': 'Good', 'description': 'Minor signs of wear'},
      {
        'value': 'fair',
        'label': 'Fair',
        'description': 'Noticeable wear but functional',
      },
      {
        'value': 'poor',
        'label': 'Poor',
        'description': 'Heavy wear, may need repairs',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children:
            conditions.map((condition) {
              final isSelected = widget.selectedCondition == condition['value'];
              return Container(
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.blue.withAlpha(26)
                          : Colors.transparent,
                  border: Border(
                    bottom:
                        condition != conditions.last
                            ? BorderSide(color: Colors.grey.shade200)
                            : BorderSide.none,
                  ),
                ),
                child: RadioListTile<String>(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  title: Text(
                    condition['label']!,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                      color: isSelected ? Colors.blue : null,
                    ),
                  ),
                  subtitle: Text(
                    condition['description']!,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: condition['value']!,
                  groupValue: widget.selectedCondition,
                  onChanged: (value) => widget.onConditionChanged(value!),
                  dense: true,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTagsInput() {
    final TextEditingController tagController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add tags to make your product more discoverable',
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
        ),
        SizedBox(height: 0.5.h),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tagController,
                decoration: InputDecoration(
                  hintText: 'Enter a tag',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.h,
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 12.sp),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !widget.tags.contains(value)) {
                    final newTags = [...widget.tags, value];
                    widget.onTagsChanged(newTags);
                    tagController.clear();
                  }
                },
              ),
            ),
            SizedBox(width: 2.w),
            ElevatedButton(
              onPressed: () {
                final value = tagController.text.trim();
                if (value.isNotEmpty && !widget.tags.contains(value)) {
                  final newTags = [...widget.tags, value];
                  widget.onTagsChanged(newTags);
                  tagController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
              child: Text('Add', style: GoogleFonts.inter(fontSize: 11.sp)),
            ),
          ],
        ),

        if (widget.tags.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Wrap(
            spacing: 1.w,
            runSpacing: 0.5.h,
            children:
                widget.tags.map((tag) {
                  return Chip(
                    label: Text(tag, style: GoogleFonts.inter(fontSize: 10.sp)),
                    onDeleted: () {
                      final newTags =
                          widget.tags.where((t) => t != tag).toList();
                      widget.onTagsChanged(newTags);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }
}
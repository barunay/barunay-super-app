import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/product_service.dart';
import '../../services/seller_service.dart';
import './widgets/edit_product_form_widget.dart';
import './widgets/edit_product_image_management_widget.dart';
import './widgets/edit_product_preview_widget.dart';
import './widgets/change_tracking_widget.dart';

class EditProductListingScreen extends StatefulWidget {
  final String productId;

  const EditProductListingScreen({super.key, required this.productId});

  @override
  State<EditProductListingScreen> createState() =>
      _EditProductListingScreenState();
}

class _EditProductListingScreenState extends State<EditProductListingScreen>
    with TickerProviderStateMixin {
  final SellerService _sellerService = SellerService();
  final ProductService _productService = ProductService();

  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _locationController = TextEditingController();

  // Form state
  String? _selectedCategoryId;
  List<String> _selectedCategoryPath = [];
  String? _selectedBrandId;
  String _selectedCondition = 'new';
  bool _isNegotiable = true;
  List<String> _tags = [];
  List<String> _imageUrls = [];
  Map<String, dynamic> _specifications = {};
  Map<String, dynamic> _shippingInfo = {};

  // Original data for change tracking
  Map<String, dynamic> _originalData = {};
  Map<String, dynamic> _changedFields = {};

  // Loading states
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Data
  Map<String, dynamic>? _product;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Track changes
    for (final c in [
      _titleController,
      _descriptionController,
      _priceController,
      _originalPriceController,
      _locationController,
    ]) {
      c.addListener(_trackChanges);
    }

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _productService.getProductById(widget.productId),
        _loadCategories(),
        _productService.getBrands(),
      ]);

      final product = results[0] as Map<String, dynamic>?;
      final categories = results[1] as List<Map<String, dynamic>>;
      final brands = results[2] as List<Map<String, dynamic>>;

      if (product == null) {
        throw Exception('Product not found');
      }

      setState(() {
        _product = product;
        _categories = categories;
        _brands = brands;
        _isLoading = false;
      });

      _populateForm(product);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load product: $e')));
      Navigator.pop(context);
    }
  }

  Future<List<Map<String, dynamic>>> _loadCategories() async {
    try {
      final response = await _sellerService._client.rpc(
        'get_category_hierarchy',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
  }

  void _populateForm(Map<String, dynamic> product) {
    // Store original data for change tracking
    _originalData = {
      'title': product['title'] ?? '',
      'description': product['description'] ?? '',
      'price': product['price']?.toString() ?? '',
      'original_price': product['original_price']?.toString() ?? '',
      'location': product['location_text'] ?? '',
      'category_id': product['category_id'],
      'brand_id': product['brand_id'],
      'condition': product['condition'] ?? 'good',
      'is_negotiable': product['is_negotiable'] ?? true,
      'tags': List<String>.from(product['tags'] ?? []),
      'specifications': Map<String, dynamic>.from(
        product['specifications'] ?? {},
      ),
      'shipping_info': Map<String, dynamic>.from(
        product['shipping_info'] ?? {},
      ),
    };

    // Extract images from product_images relationship
    final images = product['images'] as List<dynamic>? ?? [];
    final imageUrls =
        images
            .map((img) => img['image_url'] as String)
            .where((url) => url.isNotEmpty)
            .toList();

    setState(() {
      _titleController.text = _originalData['title'];
      _descriptionController.text = _originalData['description'];
      _priceController.text = _originalData['price'];
      _originalPriceController.text = _originalData['original_price'];
      _locationController.text = _originalData['location'];
      _selectedCategoryId = _originalData['category_id'];
      _selectedBrandId = _originalData['brand_id'];
      _selectedCondition = _originalData['condition'];
      _isNegotiable = _originalData['is_negotiable'];
      _tags = List<String>.from(_originalData['tags']);
      _imageUrls = imageUrls;
      _specifications = Map<String, dynamic>.from(
        _originalData['specifications'],
      );
      _shippingInfo = Map<String, dynamic>.from(_originalData['shipping_info']);
    });
  }

  void _trackChanges() {
    final currentData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'price': _priceController.text,
      'original_price': _originalPriceController.text,
      'location': _locationController.text,
      'category_id': _selectedCategoryId,
      'brand_id': _selectedBrandId,
      'condition': _selectedCondition,
      'is_negotiable': _isNegotiable,
      'tags': _tags,
      'specifications': _specifications,
      'shipping_info': _shippingInfo,
    };

    final changes = <String, dynamic>{};
    for (final key in currentData.keys) {
      if (currentData[key] != _originalData[key]) {
        changes[key] = currentData[key];
      }
    }

    setState(() {
      _changedFields = changes;
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _tabController.animateTo(_currentStep);
    }
  }

  Future<void> _updateProduct() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_changedFields.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save')));
      return;
    }

    // Show confirmation dialog
    final shouldUpdate = await _showUpdateConfirmationDialog();
    if (!shouldUpdate) return;

    setState(() => _isSubmitting = true);

    try {
      // Use the new RPC function that automatically sets status to under_review
      await _sellerService._client
          .rpc('update_product_with_categories', {
            'p_product_id': widget.productId,
            'p_title': _titleController.text.trim(),
            'p_description': _descriptionController.text.trim(),
            'p_price': double.parse(_priceController.text),
            'p_status': 'active',
            'p_category_slugs': _selectedCategoryPath,
          });

      if (!mounted) return;

      // Show success dialog with review information
      await _showUpdateSuccessDialog();

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _showUpdateConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'Update Listing',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your listing will go through review again after updating.',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Changes detected:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ..._changedFields.keys
                        .map(
                          (key) => Padding(
                            padding: EdgeInsets.only(left: 2.w, bottom: 0.5.h),
                            child: Text(
                              '• ${_getFieldDisplayName(key)}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Update Listing'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _showUpdateSuccessDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Listing Updated Successfully',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your updated listing has been submitted for admin review.',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.orange.shade700,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Review typically takes 1-2 business days',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View My Listings'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getFieldDisplayName(String key) {
    switch (key) {
      case 'title':
        return 'Product Title';
      case 'description':
        return 'Description';
      case 'price':
        return 'Price';
      case 'original_price':
        return 'Original Price';
      case 'location':
        return 'Location';
      case 'category_id':
        return 'Category';
      case 'brand_id':
        return 'Brand';
      case 'condition':
        return 'Condition';
      case 'is_negotiable':
        return 'Negotiable';
      case 'tags':
        return 'Tags';
      case 'specifications':
        return 'Specifications';
      case 'shipping_info':
        return 'Shipping Info';
      default:
        return key;
    }
  }

  bool _validateForm() {
    return _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _selectedCategoryId != null &&
        _imageUrls.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Edit Listing',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Listing',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Draft saved')));
            },
            child: const Text('Save Draft'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Images'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(12),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Change indicator
          if (_changedFields.isNotEmpty)
            ChangeTrackingWidget(changedFields: _changedFields),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
                _tabController.animateTo(index);
              },
              children: [
                // Step 1: Product Details
                EditProductFormWidget(
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  priceController: _priceController,
                  originalPriceController: _originalPriceController,
                  locationController: _locationController,
                  categories: _categories,
                  brands: _brands,
                  selectedCategoryId: _selectedCategoryId,
                  selectedBrandId: _selectedBrandId,
                  selectedCondition: _selectedCondition,
                  isNegotiable: _isNegotiable,
                  tags: _tags,
                  specifications: _specifications,
                  shippingInfo: _shippingInfo,
                  onCategoryChanged: (value, path) {
                    setState(() {
                      _selectedCategoryId = value;
                      _selectedCategoryPath = path;
                    });
                    _trackChanges();
                  },
                  onBrandChanged: (value) {
                    setState(() => _selectedBrandId = value);
                    _trackChanges();
                  },
                  onConditionChanged: (value) {
                    setState(() => _selectedCondition = value);
                    _trackChanges();
                  },
                  onNegotiableChanged: (value) {
                    setState(() => _isNegotiable = value);
                    _trackChanges();
                  },
                  onTagsChanged: (tags) {
                    setState(() => _tags = tags);
                    _trackChanges();
                  },
                  onSpecificationsChanged: (specs) {
                    setState(() => _specifications = specs);
                    _trackChanges();
                  },
                  onShippingInfoChanged: (info) {
                    setState(() => _shippingInfo = info);
                    _trackChanges();
                  },
                ),

                // Step 2: Images
                EditProductImageManagementWidget(
                  imageUrls: _imageUrls,
                  onImagesChanged: (urls) {
                    setState(() => _imageUrls = urls);
                    _trackChanges();
                  },
                ),

                // Step 3: Preview
                EditProductPreviewWidget(
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  price: double.tryParse(_priceController.text) ?? 0,
                  originalPrice: double.tryParse(_originalPriceController.text),
                  condition: _selectedCondition,
                  location: _locationController.text.trim(),
                  isNegotiable: _isNegotiable,
                  tags: _tags,
                  imageUrls: _imageUrls,
                  category: _getCategoryName(),
                  changedFields: _changedFields,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Previous'),
                )
              else
                const SizedBox.shrink(),
              if (_currentStep < 2)
                ElevatedButton(onPressed: _nextStep, child: const Text('Next'))
              else
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _updateProduct,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Update Listing'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName() {
    if (_selectedCategoryId == null) return 'Unknown';

    final category = _categories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => {'name': 'Unknown'},
    );

    return category['name'] as String;
  }
}
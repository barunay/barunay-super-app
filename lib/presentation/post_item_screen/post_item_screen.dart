import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/product_service.dart';
import '../../services/seller_service.dart';
import './widgets/product_form_widget.dart';
import './widgets/product_image_upload_widget.dart';
import './widgets/product_preview_widget.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen>
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

  // Loading states
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasSellerProfile = false;
  Map<String, dynamic> _sellerStatus = {};

  // Data - Updated to use new categories table
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Live preview updates while typing
    for (final c in [
      _titleController,
      _descriptionController,
      _priceController,
      _originalPriceController,
      _locationController,
    ]) {
      c.addListener(() => setState(() {}));
    }

    _checkSellerProfile();
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

  Future<void> _checkSellerProfile() async {
    try {
      final sellerStatus = await _sellerService.getSellerPostingStatus();
      setState(() {
        _sellerStatus = sellerStatus;
        _hasSellerProfile = sellerStatus['requires_registration'] != true;
      });

      if (sellerStatus['requires_registration'] == true) {
        _showSellerRegistrationDialog();
      } else if (sellerStatus['can_post'] != true) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.profileUnderReviewScreen,
        );
      }
    } catch (e) {
      debugPrint('Error checking seller profile: $e');
    }
  }

  void _showSellerRegistrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Seller Registration Required',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'You need to complete your seller profile to post items in the marketplace.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.sellerProfileSetupScreen,
                  ).then((_) => _checkSellerProfile());
                },
                child: const Text('Register as Seller'),
              ),
            ],
          ),
    );
  }

  Future<void> _showSellerStatusDialog() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.profileUnderReviewScreen);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _loadRootCategories(),
        _productService.getBrands(),
      ]);

      setState(() {
        _categories = results[0];
        _brands = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  Future<List<Map<String, dynamic>>> _loadRootCategories() async {
    try {
      final response = await _sellerService.supabaseClient.rpc(
        'get_category_hierarchy',
        {'p_parent_id': null},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
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

  // Updated to use RPC function with category slugs
  Future<void> _submitProduct() async {
    if (_sellerStatus['can_post'] != true) {
      if (_sellerStatus['requires_registration'] == true) {
        _showSellerRegistrationDialog();
      } else {
        _showSellerStatusDialog();
      }
      return;
    }

    if (!_validateForm()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Use the old service method that directly inserts into products table
      await _sellerService.createSellerProduct(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        brandId: _selectedBrandId,
        price: double.parse(_priceController.text),
        originalPrice:
            _originalPriceController.text.isNotEmpty
                ? double.parse(_originalPriceController.text)
                : null,
        condition: _selectedCondition,
        locationText: _locationController.text.trim(),
        isNegotiable: _isNegotiable,
        tags: _tags,
        specifications: _specifications,
        shippingInfo: _shippingInfo,
        imageUrls: _imageUrls,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product submitted for admin review successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    if (_sellerStatus['requires_registration'] == true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Post Item',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Seller Registration Required',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your seller profile to start posting items',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushNamed(
                      context,
                      AppRoutes.sellerProfileSetupScreen,
                    ).then((_) => _checkSellerProfile()),
                child: const Text('Register as Seller'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sellerStatus['can_post'] != true &&
        _sellerStatus['verification_status'] == 'pending') {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Post Item',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Profile Under Review',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Your seller profile is being reviewed by our admin team. You\'ll be able to post products once your profile is approved.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushNamed(
                      context,
                      AppRoutes.sellerInventoryScreen,
                    ),
                child: const Text('Go to Dashboard'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Listing',
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
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
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentStep = index);
                        _tabController.animateTo(index);
                      },
                      children: [
                        // Step 1: Product Details - Updated to use dynamic categories
                        ProductFormWidget(
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
                          },
                          onBrandChanged:
                              (value) =>
                                  setState(() => _selectedBrandId = value),
                          onConditionChanged:
                              (value) =>
                                  setState(() => _selectedCondition = value),
                          onNegotiableChanged:
                              (value) => setState(() => _isNegotiable = value),
                          onTagsChanged: (tags) => setState(() => _tags = tags),
                          onSpecificationsChanged:
                              (specs) =>
                                  setState(() => _specifications = specs),
                          onShippingInfoChanged:
                              (info) => setState(() => _shippingInfo = info),
                        ),

                        // Step 2: Images
                        ProductImageUploadWidget(
                          imageUrls: _imageUrls,
                          onImagesChanged:
                              (urls) => setState(() => _imageUrls = urls),
                        ),

                        // Step 3: Preview (centered, constrained, scrollable)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxCardWidth =
                                constraints.maxWidth < 500
                                    ? constraints.maxWidth
                                    : 500.0;
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: maxCardWidth,
                                ),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: ProductPreviewWidget(
                                    title: _titleController.text.trim(),
                                    description:
                                        _descriptionController.text.trim(),
                                    price:
                                        double.tryParse(
                                          _priceController.text,
                                        ) ??
                                        0,
                                    originalPrice: double.tryParse(
                                      _originalPriceController.text,
                                    ),
                                    condition: _selectedCondition,
                                    location: _locationController.text.trim(),
                                    isNegotiable: _isNegotiable,
                                    tags: _tags,
                                    imageUrls: _imageUrls,
                                    category: _getCategoryName(),
                                  ),
                                ),
                              ),
                            );
                          },
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
                  onPressed: _isSubmitting ? null : _submitProduct,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Submit for Review'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName() {
    if (_selectedCategoryId == null) return 'Unknown';

    // Look through all categories to find the selected one
    final category = _categories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => {'name': 'Unknown'},
    );

    return category['name'] as String;
  }
}
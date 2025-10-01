import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/product_service.dart';

class ProductCategoryChipsWidget extends StatefulWidget {
  final String? selectedCategoryId;
  final Function(String?)? onCategorySelected;

  const ProductCategoryChipsWidget({
    super.key,
    this.selectedCategoryId,
    this.onCategorySelected,
  });

  @override
  State<ProductCategoryChipsWidget> createState() =>
      _ProductCategoryChipsWidgetState();
}

class _ProductCategoryChipsWidgetState
    extends State<ProductCategoryChipsWidget> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All Categories chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildCategoryChip(
              categoryId: null,
              categoryName: 'All',
              iconName: 'grid_view',
              productCount: null,
              isSelected: widget.selectedCategoryId == null,
            ),
          ),

          // Category chips
          ..._categories.map((category) {
            final subcategories =
                category['subcategories'] as List<dynamic>? ?? [];
            final productCount = category['products_count'] as int? ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                categoryId: category['id'],
                categoryName: category['name'],
                iconName: category['icon_name'],
                productCount: productCount,
                isSelected: widget.selectedCategoryId == category['id'],
                hasSubcategories: subcategories.isNotEmpty,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String? categoryId,
    required String categoryName,
    String? iconName,
    int? productCount,
    required bool isSelected,
    bool hasSubcategories = false,
  }) {
    return GestureDetector(
      onTap: () {
        widget.onCategorySelected?.call(categoryId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Icon
            Icon(
              _getCategoryIcon(iconName),
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),

            // Category Name
            Text(
              categoryName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),

            // Product Count Badge
            if (productCount != null && productCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(51)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  productCount.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],

            // Subcategories Indicator
            if (hasSubcategories) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'devices':
        return Icons.devices;
      case 'smartphone':
        return Icons.smartphone;
      case 'laptop':
        return Icons.laptop;
      case 'shirt':
        return Icons.checkroom;
      case 'bag':
        return Icons.shopping_bag;
      case 'home':
        return Icons.home;
      case 'chair':
        return Icons.chair;
      case 'microwave':
        return Icons.microwave;
      case 'grid_view':
        return Icons.grid_view;
      default:
        return Icons.category;
    }
  }
}

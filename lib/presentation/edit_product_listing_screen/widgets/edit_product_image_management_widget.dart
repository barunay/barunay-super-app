import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/product_image_service.dart';
import '../../../widgets/custom_image_widget.dart';

class EditProductImageManagementWidget extends StatefulWidget {
  final List<String> imageUrls;
  final ValueChanged<List<String>> onImagesChanged;

  const EditProductImageManagementWidget({
    super.key,
    required this.imageUrls,
    required this.onImagesChanged,
  });

  @override
  State<EditProductImageManagementWidget> createState() =>
      _EditProductImageManagementWidgetState();
}

class _EditProductImageManagementWidgetState
    extends State<EditProductImageManagementWidget> {
  final ProductImageService _imageService = ProductImageService();
  bool _isUploading = false;

  Future<void> _addImage() async {
    setState(() => _isUploading = true);

    try {
      final imageFiles = await ProductImageService.pickImages(
        source: ImageSource.gallery,
        maxImages: 1,
      );
      if (imageFiles.isNotEmpty) {
        final imageUrls = await ProductImageService.uploadProductImages(
          productId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          imageFiles: imageFiles,
        );
        if (imageUrls.isNotEmpty) {
          final updatedUrls = <String>[...widget.imageUrls, imageUrls.first];
          widget.onImagesChanged(updatedUrls);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeImage(int index) {
    final updatedUrls = <String>[...widget.imageUrls];
    updatedUrls.removeAt(index);
    widget.onImagesChanged(updatedUrls);
  }

  void _reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final updatedUrls = [...widget.imageUrls];
    final item = updatedUrls.removeAt(oldIndex);
    updatedUrls.insert(newIndex, item);
    widget.onImagesChanged(updatedUrls);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Images',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),

          Text(
            'Add or remove images. Drag to reorder. First image will be the main photo.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.h),

          // Image grid with reordering
          if (widget.imageUrls.isNotEmpty)
            ReorderableGridView(
              itemCount: widget.imageUrls.length,
              onReorder: _reorderImages,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 2.w,
                childAspectRatio: 1.0,
              ),
              children:
                  widget.imageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imageUrl = entry.value;

                    return _buildImageTile(index, imageUrl);
                  }).toList(),
            ),

          SizedBox(height: 2.h),

          // Add image button
          Center(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _addImage,
              icon:
                  _isUploading
                      ? SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(Icons.add_photo_alternate, size: 5.w),
              label: Text(
                _isUploading ? 'Uploading...' : 'Add Image',
                style: GoogleFonts.inter(fontSize: 12.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              ),
            ),
          ),

          if (widget.imageUrls.isEmpty) ...[
            SizedBox(height: 4.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 12.w,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No images added yet',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Add at least one image to showcase your product',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageTile(int index, String imageUrl) {
    return Container(
      key: ValueKey(imageUrl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: index == 0 ? Colors.blue : Colors.grey.shade300,
          width: index == 0 ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            CustomImageWidget(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Primary image indicator
            if (index == 0)
              Positioned(
                top: 1.w,
                left: 1.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.5.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'MAIN',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Remove button
            Positioned(
              top: 1.w,
              right: 1.w,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 4.w),
                ),
              ),
            ),

            // Drag handle
            Positioned(
              bottom: 1.w,
              right: 1.w,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.white,
                  size: 4.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple reorderable grid view implementation
class ReorderableGridView extends StatelessWidget {
  final int itemCount;
  final ReorderCallback onReorder;
  final SliverGridDelegate gridDelegate;
  final List<Widget> children;

  const ReorderableGridView({
    super.key,
    required this.itemCount,
    required this.onReorder,
    required this.gridDelegate,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: onReorder,
      scrollDirection: Axis.vertical,
      children: children,
    );
  }
}
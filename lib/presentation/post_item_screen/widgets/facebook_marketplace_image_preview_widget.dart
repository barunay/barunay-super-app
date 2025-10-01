import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FacebookMarketplaceImagePreviewWidget extends StatefulWidget {
  final List<String> imageUrls;
  final Function(int index)? onImageTap;
  final Function(int index)? onImageRemove;
  final Function(int fromIndex, int toIndex)? onImageReorder;
  final bool isEditable;
  final double? height;

  const FacebookMarketplaceImagePreviewWidget({
    super.key,
    required this.imageUrls,
    this.onImageTap,
    this.onImageRemove,
    this.onImageReorder,
    this.isEditable = true,
    this.height,
  });

  @override
  State<FacebookMarketplaceImagePreviewWidget> createState() =>
      _FacebookMarketplaceImagePreviewWidgetState();
}

class _FacebookMarketplaceImagePreviewWidgetState
    extends State<FacebookMarketplaceImagePreviewWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Main image viewer with zoom functionality
        Container(
          height: widget.height ?? 400.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Main image viewer
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _transformationController.value = Matrix4.identity();
                },
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => widget.onImageTap?.call(index),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildZoomableImage(widget.imageUrls[index]),
                      ),
                    ),
                  );
                },
              ),

              // Image counter overlay
              if (widget.imageUrls.length > 1)
                Positioned(
                  top: 16.h,
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(179),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Navigation arrows (desktop/tablet)
              if (widget.imageUrls.length > 1 && !kIsWeb) ...[
                // Previous button
                if (_currentIndex > 0)
                  Positioned(
                    left: 16.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildNavigationButton(
                        icon: Icons.chevron_left,
                        onTap: () => _navigateToImage(_currentIndex - 1),
                      ),
                    ),
                  ),
                // Next button
                if (_currentIndex < widget.imageUrls.length - 1)
                  Positioned(
                    right: 16.w,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildNavigationButton(
                        icon: Icons.chevron_right,
                        onTap: () => _navigateToImage(_currentIndex + 1),
                      ),
                    ),
                  ),
              ],

              // Main image badge
              Positioned(
                top: 16.h,
                left: 16.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0
                        ? Theme.of(context).primaryColor
                        : Colors.black.withAlpha(179),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _currentIndex == 0 ? 'MAIN' : 'IMAGE ${_currentIndex + 1}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Remove button (if editable)
              if (widget.isEditable && widget.onImageRemove != null)
                Positioned(
                  bottom: 16.h,
                  right: 16.w,
                  child: _buildActionButton(
                    icon: Icons.delete,
                    color: Colors.red,
                    onTap: () => _showRemoveConfirmation(_currentIndex),
                  ),
                ),

              // Zoom instructions overlay
              Positioned(
                bottom: 16.h,
                left: 16.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Pinch to zoom',
                    style: GoogleFonts.inter(
                      color: Colors.white.withAlpha(204),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Thumbnail carousel (Facebook Marketplace style)
        if (widget.imageUrls.length > 1) _buildThumbnailCarousel(),
      ],
    );
  }

  Widget _buildZoomableImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade900,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Loading image...',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade900,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 48.sp,
              color: Colors.white54,
            ),
            SizedBox(height: 12.h),
            Text(
              'Failed to load image',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap to retry',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(179),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: color.withAlpha(230),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildThumbnailCarousel() {
    return Container(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentIndex;

          return GestureDetector(
            onTap: () => _navigateToImage(index),
            child: Container(
              width: 80.w,
              margin: EdgeInsets.only(
                right: index == widget.imageUrls.length - 1 ? 0 : 8.w,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image,
                          size: 20.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  // Main image indicator
                  if (index == 0)
                    Positioned(
                      bottom: 2.h,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'MAIN',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 6.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Selection overlay
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Theme.of(context).primaryColor.withAlpha(77),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height ?? 300.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 64.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'No images to preview',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Upload some images to see the preview',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToImage(int index) {
    if (index >= 0 && index < widget.imageUrls.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showRemoveConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Image',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          index == 0
              ? 'This is your main product image. Are you sure you want to remove it?'
              : 'Are you sure you want to remove this image?',
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onImageRemove?.call(index);
            },
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

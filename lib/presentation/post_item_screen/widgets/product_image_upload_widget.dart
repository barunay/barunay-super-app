import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/product_image_service.dart';
import '../../../widgets/custom_image_widget.dart';

class ProductImageUploadWidget extends StatefulWidget {
  final List<String> imageUrls;
  final ValueChanged<List<String>> onImagesChanged;
  final int maxImages;

  const ProductImageUploadWidget({
    super.key,
    required this.imageUrls,
    required this.onImagesChanged,
    this.maxImages = 8,
  });

  @override
  State<ProductImageUploadWidget> createState() =>
      _ProductImageUploadWidgetState();
}

class _ProductImageUploadWidgetState extends State<ProductImageUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadStatusText;
  int _currentCarouselIndex = 0;
  late PageController _carouselController;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countText = '${widget.imageUrls.length}/${widget.maxImages}';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Images',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                countText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Grid
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: widget.imageUrls.length +
                  (widget.imageUrls.length < widget.maxImages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.imageUrls.length) {
                  return _buildUploadButton(context);
                }
                return _buildImageItem(context, widget.imageUrls[index], index);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Tips
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo Tips',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Use good lighting and take clear photos\n'
                  '• Show all angles and any defects\n'
                  '• First photo will be your main image',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          if (_isUploading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: _uploadProgress),
                ),
                const SizedBox(width: 12),
                Text(_uploadStatusText ?? 'Uploading…',
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    final canAdd = widget.imageUrls.length < widget.maxImages;
    return InkWell(
      onTap: canAdd ? () => _showUploadOptions(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate,
                  size: 28, color: Colors.grey.shade600),
              const SizedBox(height: 6),
              Text(
                'Add Photo',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, String imageUrl, int index) {
    final isMainImage = index == 0;

    return Stack(
      children: [
        // Image container with fixed aspect ratio
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isMainImage ? Colors.blue : Colors.grey.shade300,
              width: isMainImage ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const AspectRatio(
              aspectRatio: 1.0,
              child: SizedBox.expand(), // placeholder for image
            ),
          ),
        ),
        // Actual image fills the square
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomImageWidget(imageUrl: imageUrl, fit: BoxFit.cover),
          ),
        ),

        // Main badge
        if (isMainImage)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Main',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),

        // Delete button
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: () => _removeImage(index),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xE6FF3B30), // red with alpha
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),

        // Set as main (tap on non-main)
        if (!isMainImage)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onLongPress: () => _setAsMain(index)),
            ),
          ),
      ],
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Add Photos',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ListTile(
                leading:
                    Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library,
                    color: Theme.of(context).primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
              if (kIsWeb)
                ListTile(
                  leading: Icon(Icons.file_upload,
                      color: Theme.of(context).primaryColor),
                  title: const Text('Upload Files'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImagesWithFilePicker();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImages(ImageSource source) async {
    if (_isUploading || widget.imageUrls.length >= widget.maxImages) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatusText = 'Selecting images...';
    });

    try {
      final List<XFile> selectedImages = await ProductImageService.pickImages(
        source: source,
        maxImages: widget.maxImages - widget.imageUrls.length,
        imageQuality: 85,
      );

      if (selectedImages.isNotEmpty) {
        await _uploadSelectedImages(selectedImages);
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to select images: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatusText = null;
      });
    }
  }

  void _pickImagesWithFilePicker() async {
    if (_isUploading || widget.imageUrls.length >= widget.maxImages) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatusText = 'Selecting images...';
    });

    try {
      final List<XFile> selectedImages =
          await ProductImageService.pickImagesWithFilePicker(
        maxImages: widget.maxImages - widget.imageUrls.length,
      );

      if (selectedImages.isNotEmpty) {
        await _uploadSelectedImages(selectedImages);
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to select images: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatusText = null;
      });
    }
  }

  Future<void> _uploadSelectedImages(List<XFile> images) async {
    setState(() {
      _uploadStatusText = 'Preparing upload...';
    });

    // Validate files
    for (final image in images) {
      if (!ProductImageService.validateImageFile(image)) {
        throw Exception('Invalid image format: ${image.name}');
      }

      final fileSize = await ProductImageService.getImageFileSize(image);
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception(
          'File too large: ${image.name} (${ProductImageService.formatFileSize(fileSize)})',
        );
      }
    }

    final tempProductId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final List<String> uploadedUrls =
        await ProductImageService.uploadProductImages(
      productId: tempProductId,
      imageFiles: images,
      onProgress: (current, total) {
        setState(() {
          _uploadProgress = current / total;
          _uploadStatusText = 'Uploading $current of $total images...';
        });
      },
    );

    final newImageUrls = [...widget.imageUrls, ...uploadedUrls];
    widget.onImagesChanged(newImageUrls);

    setState(() {
      _uploadStatusText = 'Upload completed!';
    });

    await Future.delayed(const Duration(seconds: 1));
  }

  void _removeImage(int index) {
    final newImageUrls = [...widget.imageUrls];
    newImageUrls.removeAt(index);
    widget.onImagesChanged(newImageUrls);

    if (_currentCarouselIndex >= newImageUrls.length &&
        newImageUrls.isNotEmpty) {
      setState(() {
        _currentCarouselIndex = newImageUrls.length - 1;
      });
      _carouselController.animateToPage(
        _currentCarouselIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _setAsMain(int index) {
    if (index == 0 || index >= widget.imageUrls.length) return;

    final newImageUrls = [...widget.imageUrls];
    final mainImage = newImageUrls.removeAt(index);
    newImageUrls.insert(0, mainImage);
    widget.onImagesChanged(newImageUrls);

    setState(() => _currentCarouselIndex = 0);
    _carouselController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upload Error',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ProductImageService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String bucketName = 'product-images';
  static final ImagePicker _imagePicker = ImagePicker();

  /// Upload multiple images for a product with progress tracking
  static Future<List<String>> uploadProductImages({
    required String productId,
    required List<XFile> imageFiles,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileExtension = path.extension(file.name).toLowerCase();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${productId}_${timestamp}_$i$fileExtension';
        final filePath = '$productId/$fileName';

        // Read file bytes
        final Uint8List fileBytes = await file.readAsBytes();

        // Upload to Supabase Storage
        await _client.storage
            .from(bucketName)
            .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        // Get public URL
        final publicUrl = _client.storage
            .from(bucketName)
            .getPublicUrl(filePath);
        uploadedUrls.add(publicUrl);

        // Update progress
        onProgress?.call(i + 1, imageFiles.length);
      }

      return uploadedUrls;
    } catch (error) {
      // Clean up any uploaded files on error
      for (final url in uploadedUrls) {
        try {
          final fileName = url.split('/').last;
          await _client.storage.from(bucketName).remove([
            '$productId/$fileName',
          ]);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
      throw Exception('Failed to upload product images: $error');
    }
  }

  /// Move temporary uploaded images to actual product folder and update URLs
  static Future<List<String>> moveTemporaryImagesToProduct({
    required String actualProductId,
    required List<String> temporaryImageUrls,
  }) async {
    final List<String> newImageUrls = [];

    try {
      for (int i = 0; i < temporaryImageUrls.length; i++) {
        final tempUrl = temporaryImageUrls[i];

        // Extract the temporary file path from URL
        final uri = Uri.parse(tempUrl);
        final tempPath = uri.pathSegments
            .skip(5)
            .join('/'); // Skip the bucket and storage parts

        // Create new file path with actual product ID
        final fileExtension = path.extension(tempPath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newFileName = '${actualProductId}_${timestamp}_$i$fileExtension';
        final newFilePath = '$actualProductId/$newFileName';

        // Copy file to new location
        final fileData = await _client.storage
            .from(bucketName)
            .download(tempPath);
        await _client.storage
            .from(bucketName)
            .uploadBinary(
              newFilePath,
              fileData,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        // Get new public URL
        final newPublicUrl = _client.storage
            .from(bucketName)
            .getPublicUrl(newFilePath);
        newImageUrls.add(newPublicUrl);

        // Delete temporary file
        try {
          await _client.storage.from(bucketName).remove([tempPath]);
        } catch (e) {
          print('Warning: Could not delete temporary file $tempPath: $e');
        }
      }

      return newImageUrls;
    } catch (error) {
      // Clean up any new files on error
      for (final url in newImageUrls) {
        try {
          final uri = Uri.parse(url);
          final filePath = uri.pathSegments.skip(5).join('/');
          await _client.storage.from(bucketName).remove([filePath]);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
      throw Exception('Failed to move temporary images: $error');
    }
  }

  /// Pick images from gallery or camera
  static Future<List<XFile>> pickImages({
    required ImageSource source,
    int maxImages = 8,
    int imageQuality = 80,
  }) async {
    try {
      if (source == ImageSource.camera) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: imageQuality,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        return image != null ? [image] : [];
      } else {
        final List<XFile> images = await _imagePicker.pickMultiImage(
          imageQuality: imageQuality,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        // Limit to maximum allowed images
        return images.take(maxImages).toList();
      }
    } catch (error) {
      throw Exception('Failed to pick images: $error');
    }
  }

  /// Pick images using file picker (web support)
  static Future<List<XFile>> pickImagesWithFilePicker({
    int maxImages = 8,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null && result.files.isNotEmpty) {
        final List<XFile> images = [];

        for (final file in result.files.take(maxImages)) {
          if (file.bytes != null) {
            // Web platform
            final XFile xFile = XFile.fromData(
              file.bytes!,
              name: file.name,
              mimeType: _getMimeType(file.name),
            );
            images.add(xFile);
          } else if (file.path != null) {
            // Mobile platform
            final XFile xFile = XFile(file.path!);
            images.add(xFile);
          }
        }

        return images;
      }

      return [];
    } catch (error) {
      throw Exception('Failed to pick images with file picker: $error');
    }
  }

  /// Save product images to database
  static Future<List<Map<String, dynamic>>> saveProductImagesToDatabase({
    required String productId,
    required List<String> imageUrls,
  }) async {
    try {
      final List<Map<String, dynamic>> imageRecords = [];

      for (int i = 0; i < imageUrls.length; i++) {
        final imageData = {
          'product_id': productId,
          'image_url': imageUrls[i],
          'sort_order': i,
          'is_primary': i == 0, // First image is primary
          'alt_text': 'Product image ${i + 1}',
        };

        imageRecords.add(imageData);
      }

      // Insert all images at once
      final response =
          await _client.from('product_images').insert(imageRecords).select();

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to save product images to database: $error');
    }
  }

  /// Update primary image
  static Future<void> updatePrimaryImage({
    required String productId,
    required String newPrimaryImageUrl,
  }) async {
    try {
      // Set all images as non-primary
      await _client
          .from('product_images')
          .update({'is_primary': false})
          .eq('product_id', productId);

      // Set new primary image
      await _client
          .from('product_images')
          .update({'is_primary': true})
          .eq('product_id', productId)
          .eq('image_url', newPrimaryImageUrl);
    } catch (error) {
      throw Exception('Failed to update primary image: $error');
    }
  }

  /// Delete product image
  static Future<void> deleteProductImage({
    required String productId,
    required String imageUrl,
  }) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      final filePath = '$productId/$fileName';

      // Delete from storage
      await _client.storage.from(bucketName).remove([filePath]);

      // Delete from database
      await _client
          .from('product_images')
          .delete()
          .eq('product_id', productId)
          .eq('image_url', imageUrl);
    } catch (error) {
      throw Exception('Failed to delete product image: $error');
    }
  }

  /// Get product images from database
  static Future<List<Map<String, dynamic>>> getProductImages(
    String productId,
  ) async {
    try {
      final response = await _client
          .from('product_images')
          .select()
          .eq('product_id', productId)
          .order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get product images: $error');
    }
  }

  /// Reorder product images
  static Future<void> reorderProductImages({
    required String productId,
    required List<String> orderedImageUrls,
  }) async {
    try {
      for (int i = 0; i < orderedImageUrls.length; i++) {
        await _client
            .from('product_images')
            .update({
              'sort_order': i,
              'is_primary': i == 0, // First image becomes primary
            })
            .eq('product_id', productId)
            .eq('image_url', orderedImageUrls[i]);
      }
    } catch (error) {
      throw Exception('Failed to reorder product images: $error');
    }
  }

  /// Helper method to get MIME type
  static String _getMimeType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Validate image file
  static bool validateImageFile(XFile file) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    final ext = path.extension(file.name).toLowerCase();
    return validExtensions.contains(ext);
  }

  /// Get image file size in bytes
  static Future<int> getImageFileSize(XFile file) async {
    try {
      if (file.path.isNotEmpty) {
        final File ioFile = File(file.path);
        return await ioFile.length();
      } else {
        final bytes = await file.readAsBytes();
        return bytes.length;
      }
    } catch (error) {
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

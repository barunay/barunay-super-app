import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

import './supabase_service.dart';

class ProfileImageService {
  static ProfileImageService? _instance;
  static ProfileImageService get instance =>
      _instance ??= ProfileImageService._();

  ProfileImageService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Upload profile image to Supabase storage
  Future<String> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      // Get the file extension and create proper file name
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = '$userId/$fileName';

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Determine the correct MIME type based on file extension
      String? mimeType = lookupMimeType(imageFile.path);

      // Upload to Supabase storage with proper content type
      await _client.storage.from('profile-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true, // Allow overwriting existing files
            ),
          );

      // Get public URL since bucket is public
      final imageUrl =
          _client.storage.from('profile-images').getPublicUrl(filePath);

      return imageUrl;
    } catch (error) {
      throw Exception('Failed to upload profile image: $error');
    }
  }

  /// Delete old profile image from storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final filePath = pathSegments
          .sublist(pathSegments.indexOf('profile-images') + 1)
          .join('/');

      if (filePath.isNotEmpty) {
        await _client.storage.from('profile-images').remove([filePath]);
      }
    } catch (error) {
      // Log error but don't throw as it's not critical
      print('Warning: Could not delete old profile image: $error');
    }
  }

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (error) {
      throw Exception('Failed to pick image from gallery: $error');
    }
  }

  /// Take photo with camera
  Future<XFile?> takePhotoWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return photo;
    } catch (error) {
      throw Exception('Failed to take photo with camera: $error');
    }
  }

  /// Get stock placeholder profile image URL - using avatar instead of random faces
  String getPlaceholderProfileImage({String? userId}) {
    // Use Dicebear avatars API for consistent, non-face avatars
    final seed = userId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Using different avatar styles that are professional and non-human
    final avatarStyles = [
      'identicon',
      'initials',
      'bottts',
      'shapes',
      'pixel-art',
    ];

    final style = avatarStyles[seed.hashCode.abs() % avatarStyles.length];

    return 'https://api.dicebear.com/7.x/$style/png?seed=$seed&size=400';
  }
}

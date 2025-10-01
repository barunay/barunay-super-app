import 'package:supabase_flutter/supabase_flutter.dart';
import './audit_logger.dart';
import './product_image_service.dart';

class SellerService {
  final SupabaseClient _client = Supabase.instance.client;

  // Add method to check admin status
  Future<bool> isCurrentUserAdmin() async {
    try {
      final response = await _client.rpc('is_admin_from_auth');

      return response == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Add method to update admin status (admin only)
  Future<void> updateAdminStatus(String userId, bool isAdmin) async {
    try {
      await _client.rpc(
        'update_admin_status',
        params: {'user_uuid': userId, 'is_admin_status': isAdmin},
      );
    } catch (e) {
      print('Error updating admin status: $e');
      throw Exception('Failed to update admin status: ${e.toString()}');
    }
  }

  // Add method to get seller document status from database
  Future<List<Map<String, dynamic>>> getSellerDocumentStatus(
    String sellerProfileId,
  ) async {
    try {
      final response = await _client.rpc(
        'get_seller_document_status',
        params: {'seller_profile_uuid': sellerProfileId},
      );

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching document status: $e');
      return [];
    }
  }

  // Enhanced seller profile checking with verification status
  Future<Map<String, dynamic>?> getSellerProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Get user's sub profile for seller
      final subProfileResponse =
          await _client
              .from('user_sub_profiles')
              .select('*')
              .eq('user_id', user.id)
              .eq('profile_type', 'seller')
              .maybeSingle();

      if (subProfileResponse == null) return null;

      // Get seller profile details
      final sellerResponse =
          await _client
              .from('seller_profiles')
              .select('*')
              .eq('user_profile_id', subProfileResponse['id'])
              .maybeSingle();

      if (sellerResponse == null) return null;

      // Combine the data
      final profileData = Map<String, dynamic>.from(sellerResponse);
      profileData['sub_profile_data'] = subProfileResponse;

      // Add actual document statuses
      try {
        final documentStatus = await getSellerDocumentStatus(
          sellerResponse['id'],
        );
        profileData['document_status'] = documentStatus;
      } catch (e) {
        print('Error getting document status: $e');
        profileData['document_status'] = [];
      }

      return profileData;
    } catch (e) {
      print('Error getting seller profile: $e');
      throw Exception('Failed to get seller profile: ${e.toString()}');
    }
  }

  // Enhanced seller profile checking with verification status
  Future<bool> hasSellerProfile() async {
    try {
      final sellerProfile = await getSellerProfile();
      return sellerProfile != null;
    } catch (e) {
      return false;
    }
  }

  // New method to check if seller can post products
  Future<Map<String, dynamic>> getSellerPostingStatus() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        return {
          'can_post': false,
          'message': 'Authentication required',
          'requires_registration': true,
        };
      }

      final sellerProfile = await getSellerProfile();

      if (sellerProfile == null) {
        return {
          'can_post': false,
          'message': 'Seller registration required',
          'requires_registration': true,
        };
      }

      final verificationStatus =
          sellerProfile['verification_status'] as String?;
      final isVerified = sellerProfile['is_verified'] as bool? ?? false;

      switch (verificationStatus) {
        case 'verified':
          return {
            'can_post': true,
            'message': 'Seller profile verified',
            'verification_status': verificationStatus,
          };
        case 'pending':
          return {
            'can_post': false,
            'message':
                'Your seller profile is under review. Please wait for admin approval before posting products.',
            'verification_status': verificationStatus,
            'requires_registration': false,
          };
        case 'rejected':
          return {
            'can_post': false,
            'message':
                'Your seller profile was rejected. Please contact support or resubmit your verification documents.',
            'verification_status': verificationStatus,
            'requires_registration': false,
          };
        default:
          return {
            'can_post': false,
            'message': 'Seller profile requires verification',
            'verification_status': 'unknown',
            'requires_registration': false,
          };
      }
    } catch (e) {
      print('Error checking seller posting status: $e');
      return {
        'can_post': false,
        'message': 'Error checking seller status',
        'requires_registration': true,
      };
    }
  }

  // Create seller profile with verification status and audit logging
  Future<Map<String, dynamic>> createSellerProfile({
    required String businessName,
    required String username, // New required parameter
    required String businessCategory,
    required String businessDescription,
    required String businessAddress,
    Map<String, dynamic>? shopSettings,
    bool hasBusinessRegistration = false,
    bool hasICVerification = false,
    bool addressConfirmed = false,
    bool verificationSkipped = false,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if seller profile already exists
      final existingProfile =
          await _client
              .from('seller_profiles')
              .select('id, verification_status')
              .eq('user_profile_id', user.id)
              .maybeSingle();

      Map<String, dynamic> profileData = {
        'business_name': businessName,
        'username': username, // New field
        'business_description': businessDescription,
        'business_address': businessAddress,
        'shop_settings': shopSettings ?? {},
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Set verification status based on document submission
      String verificationStatus = 'pending';
      if (verificationSkipped) {
        verificationStatus = 'pending'; // Still pending but without documents
      } else if (hasBusinessRegistration &&
          hasICVerification &&
          addressConfirmed) {
        verificationStatus = 'pending'; // Will be reviewed by admin
      } else {
        verificationStatus = 'pending'; // Incomplete but can still proceed
      }

      profileData['verification_status'] = verificationStatus;

      if (existingProfile != null) {
        // Update existing profile
        final result =
            await _client
                .from('seller_profiles')
                .update(profileData)
                .eq('user_profile_id', user.id)
                .select()
                .single();

        return {
          'success': true,
          'seller_profile': result,
          'verification_status': verificationStatus,
          'is_update': true,
        };
      } else {
        // Check username uniqueness
        final usernameCheck =
            await _client
                .from('seller_profiles')
                .select('id')
                .eq('username', username)
                .maybeSingle();

        if (usernameCheck != null) {
          throw Exception(
            'Username already taken. Please choose a different username.',
          );
        }

        // Create new profile with user_sub_profiles relationship
        final subProfileResult =
            await _client
                .from('user_sub_profiles')
                .insert({
                  'user_id': user.id,
                  'profile_type': 'seller',
                  'created_at': DateTime.now().toIso8601String(),
                })
                .select()
                .single();

        profileData['user_profile_id'] = subProfileResult['id'];
        profileData['created_at'] = DateTime.now().toIso8601String();

        final result =
            await _client
                .from('seller_profiles')
                .insert(profileData)
                .select()
                .single();

        await AuditLogger.createdSellerProfile(
          sellerProfileId: result['id'],
          businessName: businessName,
          username: username,
        );

        return {
          'success': true,
          'seller_profile': result,
          'verification_status': verificationStatus,
          'is_update': false,
        };
      }
    } catch (e) {
      print('Seller service error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // NEW: Delete seller profile with ownership verification and dependency checks
  Future<Map<String, dynamic>> deleteSellerProfile() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get current seller profile
      final sellerProfile = await getSellerProfile();
      if (sellerProfile == null) {
        return {'success': false, 'error': 'No seller profile found to delete'};
      }

      final sellerProfileId = sellerProfile['id'];
      final businessName = sellerProfile['business_name'] ?? 'Unknown Business';

      // Use the database function to delete with verification
      final result = await _client.rpc(
        'delete_seller_profile_with_verification',
        params: {'seller_profile_uuid': sellerProfileId},
      );

      if (result['success'] == true) {
        // Log successful deletion (this will be done by the database function too, but this is for the Flutter app)
        await AuditLogger.deletedSellerProfile(
          sellerProfileId: sellerProfileId,
          businessName: businessName,
        );

        return {
          'success': true,
          'message': result['message'] ?? 'Seller profile deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'Failed to delete seller profile',
        };
      }
    } catch (e) {
      print('Error deleting seller profile: $e');
      return {
        'success': false,
        'error': 'Failed to delete seller profile: ${e.toString()}',
      };
    }
  }

  // Check if seller profile can be deleted (no active products)
  Future<Map<String, dynamic>> checkCanDeleteSellerProfile() async {
    try {
      final sellerProfile = await getSellerProfile();
      if (sellerProfile == null) {
        return {'can_delete': false, 'reason': 'No seller profile found'};
      }

      final sellerProfileId = sellerProfile['id'];

      // Check if seller has active products
      final canDelete = await _client.rpc(
        'can_delete_seller_profile',
        params: {'seller_profile_uuid': sellerProfileId},
      );

      if (canDelete == true) {
        return {'can_delete': true, 'message': 'Seller profile can be deleted'};
      } else {
        // Get count of active products for better error message
        final productCount =
            await _client
                .from('products')
                .select('id')
                .eq('seller_profile_id', sellerProfileId)
                .filter('status', 'in', '(active,sold,reserved)')
                .count();

        return {
          'can_delete': false,
          'reason':
              'You have ${productCount.count} active products. Please delete or deactivate all products before deleting your seller profile.',
          'active_product_count': productCount.count,
        };
      }
    } catch (e) {
      print('Error checking if seller profile can be deleted: $e');
      return {
        'can_delete': false,
        'reason': 'Error checking deletion eligibility: ${e.toString()}',
      };
    }
  }

  // Update verification documents
  Future<Map<String, dynamic>> updateVerificationDocuments({
    required String sellerProfileId,
    String? businessRegistrationUrl,
    String? icVerificationUrl,
    bool? addressConfirmed,
  }) async {
    try {
      // Update verification status to 'pending' when documents are uploaded
      await _client
          .from('seller_profiles')
          .update({
            'business_license_url': businessRegistrationUrl,
            'verification_status': 'pending', // Set to pending for admin review
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerProfileId);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get seller profile by user ID
  Future<Map<String, dynamic>?> getSellerProfileByUserId(String userId) async {
    try {
      final response =
          await _client
              .from('seller_profiles')
              .select('''
            *,
            user_sub_profiles!inner(
              user_id,
              display_name,
              profile_data
            )
          ''')
              .eq('user_sub_profiles.user_id', userId)
              .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting seller profile: $e');
      return null;
    }
  }

  // Check verification status
  Future<Map<String, dynamic>> getVerificationStatus(
    String sellerProfileId,
  ) async {
    try {
      final response =
          await _client
              .from('seller_profiles')
              .select('verification_status, is_verified, business_license_url')
              .eq('id', sellerProfileId)
              .single();

      return {
        'verification_status': response['verification_status'],
        'is_verified': response['is_verified'],
        'has_documents': response['business_license_url'] != null,
      };
    } catch (e) {
      return {
        'verification_status': 'pending',
        'is_verified': false,
        'has_documents': false,
      };
    }
  }

  // Admin function to approve/reject verification
  Future<Map<String, dynamic>> updateVerificationStatus({
    required String sellerProfileId,
    required String status, // 'verified' or 'rejected'
    String? rejectionReason,
  }) async {
    try {
      await _client
          .from('seller_profiles')
          .update({
            'verification_status': status,
            'is_verified': status == 'verified',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerProfileId);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get verified seller badge data
  Map<String, dynamic> getSellerBadgeData(Map<String, dynamic> sellerProfile) {
    final verificationStatus = sellerProfile['verification_status'] as String?;
    final isVerified = sellerProfile['is_verified'] as bool? ?? false;

    switch (verificationStatus) {
      case 'verified':
        return {
          'show_badge': true,
          'badge_text': 'Verified Seller',
          'badge_color': 'verified', // Green
          'badge_icon': 'verified',
          'tooltip': 'This seller has been verified by our team',
        };
      case 'pending':
        return {
          'show_badge': true,
          'badge_text': 'Under Review',
          'badge_color': 'pending', // Orange
          'badge_icon': 'schedule',
          'tooltip': 'Verification documents are under review',
        };
      case 'rejected':
        return {
          'show_badge': true,
          'badge_text': 'Not Verified',
          'badge_color': 'not_verified', // Gray
          'badge_icon': 'info',
          'tooltip': 'Verification not completed',
        };
      default:
        return {
          'show_badge': true,
          'badge_text': 'Not Yet Verified',
          'badge_color': 'not_verified', // Gray
          'badge_icon': 'info',
          'tooltip': 'This seller has not completed verification',
        };
    }
  }

  // Seller Product Management with audit logging
  Future<List<Map<String, dynamic>>> getSellerProducts({
    String? status,
    String? listingStatus,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      var query = _client
          .from('products')
          .select('''
        *,
        category:product_categories!products_category_id_fkey(name, icon_name),
        brand:product_brands!products_brand_id_fkey(name, logo_url),
        images:product_images(image_url, is_primary, sort_order),
        reviews_count:product_reviews(count),
        favorites_count:product_favorites(count)
      ''')
          .eq('seller_id', currentUserId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (listingStatus != null) {
        query = query.eq('listing_status', listingStatus);
      }

      final response = await query
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch seller products: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createSellerProduct({
    required String title,
    required String description,
    required String categoryId,
    String? brandId,
    required double price,
    double? originalPrice,
    required String condition,
    String? locationText,
    double? latitude,
    double? longitude,
    bool isNegotiable = true,
    List<String> tags = const [],
    Map<String, dynamic> specifications = const {},
    Map<String, dynamic> shippingInfo = const {},
    List<String> imageUrls = const [],
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check posting status instead of just profile existence
      final postingStatus = await getSellerPostingStatus();
      if (postingStatus['can_post'] != true) {
        throw Exception(postingStatus['message']);
      }

      // Get seller profile ID
      final sellerProfile = await getSellerProfile();

      final response =
          await _client
              .from('products')
              .insert({
                'seller_id': currentUserId,
                'seller_profile_id': sellerProfile?['id'],
                'title': title,
                'description': description,
                'category_id': categoryId,
                'brand_id': brandId,
                'price': price,
                'original_price': originalPrice,
                'condition': condition,
                'location_text': locationText,
                'latitude': latitude,
                'longitude': longitude,
                'is_negotiable': isNegotiable,
                'tags': tags,
                'specifications': specifications,
                'shipping_info': shippingInfo,
                'status': 'active',
                'listing_status':
                    'under_review', // Default to under review for admin approval
              })
              .select('''
            *,
            category:product_categories!products_category_id_fkey(name, icon_name),
            images:product_images(image_url, is_primary, sort_order)
          ''')
              .single();

      // Handle product images if provided
      if (imageUrls.isNotEmpty) {
        List<String> finalImageUrls = imageUrls;

        // Check if images are from temporary upload (contain 'temp_')
        final hasTemporaryImages = imageUrls.any(
          (url) => url.contains('temp_'),
        );

        if (hasTemporaryImages) {
          // Import the ProductImageService for proper handling
          try {
            // Move temporary images to actual product folder
            finalImageUrls =
                await ProductImageService.moveTemporaryImagesToProduct(
                  actualProductId: response['id'],
                  temporaryImageUrls: imageUrls,
                );
          } catch (e) {
            print('Warning: Could not move temporary images: $e');
            // Continue with original URLs as fallback
            finalImageUrls = imageUrls;
          }
        }

        // Save image records to database
        await ProductImageService.saveProductImagesToDatabase(
          productId: response['id'],
          imageUrls: finalImageUrls,
        );
      }

      // Log product creation
      await AuditLogger.createdProduct(
        productId: response['id'],
        productTitle: title,
      );

      return response;
    } catch (e) {
      throw Exception('Failed to create product: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateSellerProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get current product for audit logging
      final currentProduct =
          await _client
              .from('products')
              .select('title, price, description')
              .eq('id', productId)
              .eq('seller_id', currentUserId)
              .single();

      // Reset to under_review when seller makes changes to approved products
      if (!updates.containsKey('listing_status')) {
        updates['listing_status'] = 'under_review';
      }

      final response =
          await _client
              .from('products')
              .update(updates)
              .eq('id', productId)
              .eq('seller_id', currentUserId)
              .select('''
            *,
            category:product_categories!products_category_id_fkey(name, icon_name),
            images:product_images(image_url, is_primary, sort_order)
          ''')
              .single();

      // Build diffs for audit logging
      final diffs = <Map<String, dynamic>>[];
      updates.forEach((key, newValue) {
        if (currentProduct.containsKey(key)) {
          final oldValue = currentProduct[key];
          if (oldValue != newValue) {
            diffs.add({'field': key, 'from': oldValue, 'to': newValue});
          }
        }
      });

      // Log product update if there are changes
      if (diffs.isNotEmpty) {
        await AuditLogger.editedProduct(productId: productId, diffs: diffs);
      }

      return response;
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  Future<void> deleteSellerProduct(String productId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('seller_id', currentUserId);

      // Log product deletion
      await AuditLogger.deletedProduct(productId: productId);
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  // Seller Analytics
  Future<Map<String, dynamic>> getSellerAnalytics() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get product counts by status
      final productStats = await _client
          .from('products')
          .select('status, listing_status, view_count, favorite_count')
          .eq('seller_id', currentUserId);

      // Calculate totals
      int totalProducts = productStats.length;
      int activeProducts =
          productStats.where((p) => p['status'] == 'active').length;
      int underReview =
          productStats
              .where((p) => p['listing_status'] == 'under_review')
              .length;
      int approved =
          productStats.where((p) => p['listing_status'] == 'approved').length;
      int rejected =
          productStats.where((p) => p['listing_status'] == 'rejected').length;
      int totalViews = productStats.fold(
        0,
        (sum, p) => sum + (p['view_count'] as int? ?? 0),
      );
      int totalFavorites = productStats.fold(
        0,
        (sum, p) => sum + (p['favorite_count'] as int? ?? 0),
      );

      // Get recent reviews
      final recentReviews = await _client
          .from('product_reviews')
          .select('''
            *,
            product:products!product_reviews_product_id_fkey(
              title, seller_id
            ),
            reviewer:user_profiles!product_reviews_reviewer_id_fkey(
              full_name, avatar_url
            )
          ''')
          .eq('product.seller_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(5);

      return {
        'total_products': totalProducts,
        'active_products': activeProducts,
        'under_review': underReview,
        'approved': approved,
        'rejected': rejected,
        'total_views': totalViews,
        'total_favorites': totalFavorites,
        'recent_reviews': recentReviews,
      };
    } catch (e) {
      throw Exception('Failed to fetch seller analytics: ${e.toString()}');
    }
  }

  // Product Image Management
  Future<String> uploadProductImage(String filePath) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final fileName =
          '${currentUserId}/${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      final response = await _client.storage
          .from('product-images')
          .upload(fileName, filePath);

      return _client.storage.from('product-images').getPublicUrl(response);
    } catch (e) {
      throw Exception('Failed to upload product image: ${e.toString()}');
    }
  }

  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await _client.storage.from('product-images').remove([fileName]);
    } catch (e) {
      throw Exception('Failed to delete product image: ${e.toString()}');
    }
  }

  // Seller Notifications
  Future<List<Map<String, dynamic>>> getSellerNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // This would typically come from a notifications table
      // For now, we'll simulate with product status changes
      final response = await _client
          .from('products')
          .select('id, title, listing_status, updated_at')
          .eq('seller_id', currentUserId)
          .neq('listing_status', 'draft')
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Transform to notification format
      return response.map<Map<String, dynamic>>((product) {
        String message;
        String type;

        switch (product['listing_status']) {
          case 'under_review':
            message =
                'Your product "${product['title']}" is under admin review';
            type = 'info';
            break;
          case 'approved':
            message =
                'Your product "${product['title']}" has been approved and is now live';
            type = 'success';
            break;
          case 'rejected':
            message =
                'Your product "${product['title']}" was rejected. Please review and resubmit';
            type = 'warning';
            break;
          default:
            message = 'Product "${product['title']}" status updated';
            type = 'info';
        }

        return {
          'id': product['id'],
          'title': 'Product Update',
          'message': message,
          'type': type,
          'created_at': product['updated_at'],
          'product_id': product['id'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch seller notifications: ${e.toString()}');
    }
  }
}

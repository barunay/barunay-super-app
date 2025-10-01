import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class MarketplaceService {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get client => _supabaseService.client;

  // Check if user has seller profile
  Future<Map<String, dynamic>?> getSellerProfile() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await client
          .from('seller_profiles')
          .select('''
            *,
            user_sub_profiles!seller_profiles_user_profile_id_fkey(
              user_profiles(full_name, email, avatar_url)
            )
          ''')
          .eq('user_profile_id', await _getUserSubProfileId())
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Get user's seller inventory
  Future<List<Map<String, dynamic>>> getSellerInventory() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await client
          .from('products')
          .select('''
            *,
            product_categories(name, id),
            product_brands(name, id),
            product_images(image_url)
          ''')
          .eq('seller_id', currentUserId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch inventory: ${e.toString()}');
    }
  }

  // Create new product listing
  Future<Map<String, dynamic>> createProductListing({
    required String title,
    required String description,
    required double price,
    String? categoryId,
    String? brandId,
    double? originalPrice,
    String? condition,
    List<String>? tags,
    List<String>? imageUrls,
    Map<String, dynamic>? specifications,
    Map<String, dynamic>? shippingInfo,
    String? locationText,
    double? latitude,
    double? longitude,
    bool isNegotiable = true,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if user has seller profile
      final sellerProfile = await getSellerProfile();
      if (sellerProfile == null || sellerProfile['is_verified'] != true) {
        throw Exception(
          'Seller profile required. Please complete your seller registration.',
        );
      }

      // Create product with pending approval status
      final response = await client
          .from('products')
          .insert({
            'title': title,
            'description': description,
            'price': price,
            'original_price': originalPrice,
            'category_id': categoryId,
            'brand_id': brandId,
            'condition': condition ?? 'good',
            'tags': tags,
            'specifications': specifications ?? {},
            'shipping_info': shippingInfo ?? {},
            'location_text': locationText,
            'latitude': latitude,
            'longitude': longitude,
            'is_negotiable': isNegotiable,
            'seller_id': currentUserId,
            'seller_profile_id': sellerProfile['id'],
            'status': 'active',
            'listing_status': 'pending', // Requires admin approval
          })
          .select()
          .single();

      // Add product images
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final imageInserts = imageUrls
            .asMap()
            .entries
            .map(
              (entry) => {
                'product_id': response['id'],
                'image_url': entry.value,
                'sort_order': entry.key,
              },
            )
            .toList();

        await client.from('product_images').insert(imageInserts);
      }

      return response;
    } catch (e) {
      throw Exception('Failed to create product listing: ${e.toString()}');
    }
  }

  // Update product listing
  Future<Map<String, dynamic>> updateProductListing({
    required String productId,
    String? title,
    String? description,
    double? price,
    String? categoryId,
    String? brandId,
    double? originalPrice,
    String? condition,
    List<String>? tags,
    Map<String, dynamic>? specifications,
    Map<String, dynamic>? shippingInfo,
    String? locationText,
    double? latitude,
    double? longitude,
    bool? isNegotiable,
    String? status,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (originalPrice != null) updateData['original_price'] = originalPrice;
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (brandId != null) updateData['brand_id'] = brandId;
      if (condition != null) updateData['condition'] = condition;
      if (tags != null) updateData['tags'] = tags;
      if (specifications != null) updateData['specifications'] = specifications;
      if (shippingInfo != null) updateData['shipping_info'] = shippingInfo;
      if (locationText != null) updateData['location_text'] = locationText;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (isNegotiable != null) updateData['is_negotiable'] = isNegotiable;
      if (status != null) updateData['status'] = status;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('products')
          .update(updateData)
          .eq('id', productId)
          .eq('seller_id', currentUserId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  // Delete product listing
  Future<void> deleteProductListing(String productId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Delete product images first
      await client.from('product_images').delete().eq('product_id', productId);

      // Delete product
      await client
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('seller_id', currentUserId);
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  // Get approved products for marketplace display
  Future<List<Map<String, dynamic>>> getApprovedProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = client.from('products').select('''
            *,
            product_categories(name, id),
            product_brands(name, id),
            product_images(image_url),
            seller_profiles!products_seller_profile_id_fkey(
              business_name,
              user_sub_profiles!seller_profiles_user_profile_id_fkey(
                user_profiles(full_name, avatar_url)
              )
            )
          ''').eq('status', 'active').eq('listing_status', 'approved');

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
        );
      }

      // Apply transformations without reassigning to the same variable
      var finalQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      if (offset != null) {
        finalQuery = finalQuery.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await finalQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch products: ${e.toString()}');
    }
  }

  // Get product categories
  Future<List<Map<String, dynamic>>> getProductCategories() async {
    try {
      final response =
          await client.from('product_categories').select('*').order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }

  // Get product brands
  Future<List<Map<String, dynamic>>> getProductBrands() async {
    try {
      final response =
          await client.from('product_brands').select('*').order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch brands: ${e.toString()}');
    }
  }

  // Helper method to get user sub profile ID
  Future<String> _getUserSubProfileId() async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await client
        .from('user_sub_profiles')
        .select('id')
        .eq('user_id', currentUserId)
        .single();

    return response['id'];
  }

  // Check if user has seller profile (public method)
  Future<bool> hasSellerProfile() async {
    final profile = await getSellerProfile();
    return profile != null && profile['is_verified'] == true;
  }

  // Update listing status (admin only)
  Future<void> updateListingStatus(String productId, String status) async {
    try {
      await client.from('products').update({
        'listing_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);
    } catch (e) {
      throw Exception('Failed to update listing status: ${e.toString()}');
    }
  }

  // Chat/Conversation Management
  Future<String> startConversation({
    required String productId,
    required String sellerId,
    required String buyerId,
  }) async {
    try {
      // Check if conversation already exists
      final existingConversation = await client
          .from('marketplace_conversations')
          .select('id')
          .eq('product_id', productId)
          .or('participant_one_id.eq.$buyerId,participant_two_id.eq.$buyerId')
          .or('participant_one_id.eq.$sellerId,participant_two_id.eq.$sellerId')
          .maybeSingle();

      if (existingConversation != null) {
        return existingConversation['id'];
      }

      // Create new conversation
      final response = await client
          .from('marketplace_conversations')
          .insert({
            'product_id': productId,
            'participant_one_id': buyerId,
            'participant_two_id': sellerId,
            'chat_type': 'product_inquiry',
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to start conversation: ${e.toString()}');
    }
  }
}

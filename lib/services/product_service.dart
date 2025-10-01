import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class ProductService {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get client => _supabaseService.client;

  // Product Management
  Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    int limit = 20,
    int offset = 0,
    String orderBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = client
          .from('products')
          .select('''
        *,
        seller:user_profiles!products_seller_id_fkey(
          id, full_name, avatar_url, role
        ),
        seller_profile:seller_profiles!products_seller_profile_id_fkey(
          business_name, business_address, is_verified
        ),
        category:product_categories!products_category_id_fkey(
          id, name, icon_name
        ),
        brand:product_brands!products_brand_id_fkey(
          id, name, logo_url
        ),
        images:product_images(image_url, alt_text, is_primary, sort_order),
        reviews_count:product_reviews(count),
        favorites_count:product_favorites(count)
      ''')
          .eq('status', 'active')
          .eq('listing_status', 'approved'); // Only show approved products

      // Apply filters
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
        );
      }

      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      if (condition != null) {
        query = query.eq('condition', condition);
      }

      if (location != null && location.isNotEmpty) {
        query = query.ilike('location_text', '%$location%');
      }

      // Apply ordering and pagination
      final response = await query
          .order(orderBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch products: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response =
          await client
              .from('products')
              .select('''
        *,
        seller:user_profiles!products_seller_id_fkey(
          id, full_name, avatar_url, role, phone
        ),
        seller_profile:seller_profiles!products_seller_profile_id_fkey(
          business_name, business_address, business_description, is_verified
        ),
        category:product_categories!products_category_id_fkey(
          id, name, icon_name, parent_category_id
        ),
        brand:product_brands!products_brand_id_fkey(
          id, name, logo_url, description
        ),
        images:product_images(
          id, image_url, alt_text, is_primary, sort_order
        ),
        reviews:product_reviews(
          id, rating, review_text, is_verified_purchase, created_at,
          reviewer:user_profiles!product_reviews_reviewer_id_fkey(
            full_name, avatar_url
          )
        ),
        related_products:products!inner(
          id, title, price, condition,
          images:product_images!product_images_product_id_fkey(image_url, is_primary)
        )
      ''')
              .eq('id', productId)
              .maybeSingle();

      if (response != null) {
        // Increment view count
        await incrementProductViews(productId);
      }

      return response;
    } catch (e) {
      throw Exception('Failed to fetch product: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserProducts(String userId) async {
    try {
      final response = await client
          .from('products')
          .select('''
        *,
        category:product_categories!products_category_id_fkey(name, icon_name),
        brand:product_brands!products_brand_id_fkey(name, logo_url),
        images:product_images(image_url, is_primary),
        reviews_count:product_reviews(count)
      ''')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user products: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createProduct({
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
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get user's seller profile
      final sellerProfile =
          await client
              .from('seller_profiles')
              .select('id')
              .eq('user_profile_id', currentUserId)
              .maybeSingle();

      final response =
          await client
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
                'listing_status': 'under_review', // Always goes to review
              })
              .select()
              .single();

      // Add product images if provided
      if (imageUrls.isNotEmpty) {
        final images =
            imageUrls
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'product_id': response['id'],
                    'image_url': entry.value,
                    'is_primary': entry.key == 0,
                    'sort_order': entry.key,
                  },
                )
                .toList();

        await client.from('product_images').insert(images);
      }

      return response;
    } catch (e) {
      throw Exception('Failed to create product: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Always set listing status to under_review when updating
      updates['listing_status'] = 'under_review';
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response =
          await client
              .from('products')
              .update(updates)
              .eq('id', productId)
              .eq('seller_id', currentUserId)
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await client
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('seller_id', currentUserId);
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  // Categories - Updated to use new hierarchical categories table
  Future<List<Map<String, dynamic>>> getCategories({
    String? parentId,
    bool includeSubcategories = true,
  }) async {
    try {
      // Use the new RPC function for dynamic category loading
      final response = await client.rpc('get_category_hierarchy', params: {
        'p_parent_id': parentId,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }

  // Get category path (breadcrumb)
  Future<List<Map<String, dynamic>>> getCategoryPath(String categoryId) async {
    try {
      // This would need a recursive function in the database
      // For now, return the single category
      final response =
          await client
              .from('categories')
              .select('id, name, slug, parent_id')
              .eq('id', categoryId)
              .maybeSingle();

      if (response != null) {
        return [response];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch category path: ${e.toString()}');
    }
  }

  // Brands
  Future<List<Map<String, dynamic>>> getBrands({
    bool verifiedOnly = false,
    int limit = 50,
  }) async {
    try {
      var query = client.from('product_brands').select('''
        *,
        products_count:products(count)
      ''');

      if (verifiedOnly) {
        query = query.eq('is_verified', true);
      }

      final response = await query.order('name').limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch brands: ${e.toString()}');
    }
  }

  // Favorites (Wishlist)
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await client
          .from('product_favorites')
          .select('''
        *,
        product:products!product_favorites_product_id_fkey(
          id, title, price, condition, status,
          images:product_images(image_url, is_primary),
          seller:user_profiles!products_seller_id_fkey(full_name, avatar_url)
        )
      ''')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch favorites: ${e.toString()}');
    }
  }

  // Updated toggle favorite to use the new database function
  Future<bool> toggleFavorite(String productId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Use the new RPC function that returns the new state
      final result = await client.rpc(
        'toggle_product_favorite',
        params: {'p_product_id': productId},
      );

      return result
          as bool; // Returns true if now favorited, false if unfavorited
    } catch (e) {
      throw Exception('Failed to toggle favorite: ${e.toString()}');
    }
  }

  Future<bool> isProductFavorited(String productId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final result =
          await client
              .from('product_favorites')
              .select('id')
              .eq('user_id', currentUserId)
              .eq('product_id', productId)
              .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  // Product Likes/Favorites
  Future<bool> isProductLiked(String productId, String userId) async {
    try {
      final result =
          await client
              .from('product_favorites')
              .select('id')
              .eq('product_id', productId)
              .eq('user_id', userId)
              .maybeSingle();

      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleProductLike(String productId, String userId) async {
    try {
      // Check if already liked
      final existing =
          await client
              .from('product_favorites')
              .select('id')
              .eq('product_id', productId)
              .eq('user_id', userId)
              .maybeSingle();

      if (existing != null) {
        // Remove like
        await client
            .from('product_favorites')
            .delete()
            .eq('id', existing['id']);
      } else {
        // Add like
        await client.from('product_favorites').insert({
          'product_id': productId,
          'user_id': userId,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle product like: ${e.toString()}');
    }
  }

  // Reviews
  Future<List<Map<String, dynamic>>> getProductReviews(
    String productId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await client
          .from('product_reviews')
          .select('''
        *,
        reviewer:user_profiles!product_reviews_reviewer_id_fkey(
          full_name, avatar_url
        )
      ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch reviews: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> addProductReview({
    required String productId,
    required int rating,
    String? reviewText,
    bool isVerifiedPurchase = false,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response =
          await client
              .from('product_reviews')
              .insert({
                'product_id': productId,
                'reviewer_id': currentUserId,
                'rating': rating,
                'review_text': reviewText,
                'is_verified_purchase': isVerifiedPurchase,
              })
              .select('''
        *,
        reviewer:user_profiles!product_reviews_reviewer_id_fkey(
          full_name, avatar_url
        )
      ''')
              .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add review: ${e.toString()}');
    }
  }

  // Search and Filters
  Future<List<Map<String, dynamic>>> searchProducts(
    String query, {
    String? categoryId,
    int limit = 20,
  }) async {
    try {
      var searchQuery = client
          .from('products')
          .select('''
        *,
        seller:user_profiles!products_seller_id_fkey(full_name, avatar_url),
        category:product_categories!products_category_id_fkey(name, icon_name),
        images:product_images(image_url, is_primary)
      ''')
          .eq('status', 'active')
          .eq('listing_status', 'approved'); // Only approved products

      if (query.isNotEmpty) {
        searchQuery = searchQuery.or(
          'title.ilike.%$query%,description.ilike.%$query%,tags.cs.{$query}',
        );
      }

      if (categoryId != null) {
        searchQuery = searchQuery.eq('category_id', categoryId);
      }

      final response = await searchQuery
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search products: ${e.toString()}');
    }
  }

  // Product Statistics
  Future<Map<String, dynamic>> getProductStats(String productId) async {
    try {
      final response = await client.rpc(
        'get_product_stats',
        params: {'product_uuid': productId},
      );

      return response.first;
    } catch (e) {
      throw Exception('Failed to get product stats: ${e.toString()}');
    }
  }

  Future<void> incrementProductViews(String productId) async {
    try {
      await client.rpc(
        'increment_product_views',
        params: {'product_uuid': productId},
      );
    } catch (e) {
      // Non-critical operation
      print('Failed to increment product views: ${e.toString()}');
    }
  }

  // Related Products
  Future<List<Map<String, dynamic>>> getRelatedProducts(
    String productId, {
    int limit = 5,
  }) async {
    try {
      // Get current product details
      final currentProduct =
          await client
              .from('products')
              .select('category_id, price')
              .eq('id', productId)
              .single();

      final categoryId = currentProduct['category_id'];
      final price = currentProduct['price'] as double;

      // Find related products in same category with similar price range
      final response = await client
          .from('products')
          .select('''
        *,
        seller:user_profiles!products_seller_id_fkey(full_name, avatar_url),
        images:product_images(image_url, is_primary)
      ''')
          .eq('category_id', categoryId)
          .eq('status', 'active')
          .eq('listing_status', 'approved')
          .neq('id', productId)
          .gte('price', price * 0.7)
          .lte('price', price * 1.3)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch related products: ${e.toString()}');
    }
  }

  // Featured Products
  Future<List<Map<String, dynamic>>> getFeaturedProducts({
    int limit = 10,
  }) async {
    try {
      final response = await client
          .from('products')
          .select('''
        *,
        seller:user_profiles!products_seller_id_fkey(full_name, avatar_url),
        category:product_categories!products_category_id_fkey(name, icon_name),
        images:product_images(image_url, is_primary)
      ''')
          .eq('status', 'active')
          .eq('listing_status', 'approved')
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch featured products: ${e.toString()}');
    }
  }
}
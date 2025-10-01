import 'package:supabase_flutter/supabase_flutter.dart';

class AuditLogger {
  static final _supa = Supabase.instance.client;

  static Future<void> _log({
    required String category, // 'marketplace' | 'profile' | 'delivery' | 'chat'
    required String action, // 'delete' | 'update' | 'rename' | 'create'
    required String entity, // 'products' | 'seller_profiles' | 'user_profiles'
    String? entityId, // UUID string or null
    required String description,
    List<Map<String, dynamic>>?
        changes, // e.g. [{'field':'title','from':'Old','to':'New'}]
  }) async {
    final params = {
      'p_category': category,
      'p_action': action,
      'p_entity': entity,
      'p_entity_id': entityId,
      'p_description': description,
      'p_changes': changes,
    };

    try {
      await _supa.rpc('log_simple', params: params);
    } catch (e) {
      // Non-fatal: you can ignore or surface this error
      print('Audit log failed: ${e.toString()}');
    }
  }

  // === Ready-to-use helpers for your 4 cases ===

  // 1) User deleted a seller profile
  static Future<void> deletedSellerProfile({
    required String sellerProfileId,
    required String businessName,
  }) =>
      _log(
        category: 'marketplace',
        action: 'delete',
        entity: 'seller_profiles',
        entityId: sellerProfileId,
        description:
            'User deleted seller profile <$sellerProfileId> "$businessName"',
      );

  // 2) User deleted a product
  static Future<void> deletedProduct({required String productId}) => _log(
        category: 'marketplace',
        action: 'delete',
        entity: 'products',
        entityId: productId,
        description: 'User deleted product <$productId>',
      );

  // 3) User edited a product (pass only changed fields)
  static Future<void> editedProduct({
    required String productId,
    required List<Map<String, dynamic>>
        diffs, // [{'field':'price','from':12.5,'to':10.0}, ...]
  }) =>
      _log(
        category: 'marketplace',
        action: 'update',
        entity: 'products',
        entityId: productId,
        description: 'User updated product <$productId>',
        changes: diffs,
      );

  // 4) User changed their profile name
  static Future<void> changedProfileName({
    required String userProfileId,
    required String fromName,
    required String toName,
  }) =>
      _log(
        category: 'profile',
        action: 'rename',
        entity: 'user_profiles',
        entityId: userProfileId,
        description: 'User changed name',
        changes: [
          {'field': 'full_name', 'from': fromName, 'to': toName},
        ],
      );

  // 5) User created a seller profile
  static Future<void> createdSellerProfile({
    required String sellerProfileId,
    required String businessName,
    required String username,
  }) =>
      _log(
        category: 'marketplace',
        action: 'create',
        entity: 'seller_profiles',
        entityId: sellerProfileId,
        description:
            'User created seller profile <$sellerProfileId> "$businessName" with username "@$username"',
      );

  // 6) User created a product
  static Future<void> createdProduct({
    required String productId,
    required String productTitle,
  }) =>
      _log(
        category: 'marketplace',
        action: 'create',
        entity: 'products',
        entityId: productId,
        description: 'User created product <$productId> "$productTitle"',
      );

  // 7) User updated seller profile
  static Future<void> updatedSellerProfile({
    required String sellerProfileId,
    required String businessName,
    required List<Map<String, dynamic>> diffs,
  }) =>
      _log(
        category: 'marketplace',
        action: 'update',
        entity: 'seller_profiles',
        entityId: sellerProfileId,
        description:
            'User updated seller profile <$sellerProfileId> "$businessName"',
        changes: diffs,
      );

  // 8) User updated profile settings
  static Future<void> updatedUserProfile({
    required String userProfileId,
    required List<Map<String, dynamic>> diffs,
  }) =>
      _log(
        category: 'profile',
        action: 'update',
        entity: 'user_profiles',
        entityId: userProfileId,
        description: 'User updated profile settings',
        changes: diffs,
      );

  // 9) Generic logging function for other activities
  static Future<void> logActivity({
    required String category,
    required String action,
    required String entity,
    String? entityId,
    required String description,
    List<Map<String, dynamic>>? changes,
  }) =>
      _log(
        category: category,
        action: action,
        entity: entity,
        entityId: entityId,
        description: description,
        changes: changes,
      );
}

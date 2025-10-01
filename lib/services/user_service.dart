import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();

  UserService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('user_profiles')
          .update({
            'full_name': fullName,
            'phone': phone,
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  /// Get user sub-profiles
  Future<List<Map<String, dynamic>>> getUserSubProfiles() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('user_sub_profiles')
          .select()
          .eq('user_id', user.id)
          .order('created_at');

      return response;
    } catch (error) {
      throw Exception('Failed to get sub-profiles: $error');
    }
  }

  /// Create sub-profile
  Future<Map<String, dynamic>> createSubProfile({
    required String profileType,
    required String displayName,
    Map<String, dynamic>? profileData,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('user_sub_profiles')
          .insert({
            'user_id': user.id,
            'profile_type': profileType,
            'display_name': displayName,
            'profile_data': profileData ?? {},
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create sub-profile: $error');
    }
  }

  /// Update sub-profile
  Future<Map<String, dynamic>> updateSubProfile({
    required String subProfileId,
    String? displayName,
    Map<String, dynamic>? profileData,
    bool? isActive,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updateData['display_name'] = displayName;
      if (profileData != null) updateData['profile_data'] = profileData;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _client
          .from('user_sub_profiles')
          .update(updateData)
          .eq('id', subProfileId)
          .eq('user_id',
              user.id) // Ensure user can only update their own profiles
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update sub-profile: $error');
    }
  }

  /// Create seller profile
  Future<Map<String, dynamic>> createSellerProfile({
    required String subProfileId,
    required String businessName,
    String? businessDescription,
    String? businessAddress,
    String? businessLicenseUrl,
    String? taxNumber,
    Map<String, dynamic>? bankAccountDetails,
    Map<String, dynamic>? shopSettings,
  }) async {
    try {
      final response = await _client
          .from('seller_profiles')
          .insert({
            'user_profile_id': subProfileId,
            'business_name': businessName,
            'business_description': businessDescription,
            'business_address': businessAddress,
            'business_license_url': businessLicenseUrl,
            'tax_number': taxNumber,
            'bank_account_details': bankAccountDetails ?? {},
            'shop_settings': shopSettings ?? {},
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create seller profile: $error');
    }
  }

  /// Create runner profile
  Future<Map<String, dynamic>> createRunnerProfile({
    required String subProfileId,
    String? vehicleType,
    String? licenseNumber,
    String? licenseDocumentUrl,
    String? vehicleRegistrationUrl,
    Map<String, dynamic>? availabilityPreferences,
    Map<String, dynamic>? bankingDetails,
  }) async {
    try {
      final response = await _client
          .from('runner_profiles')
          .insert({
            'user_profile_id': subProfileId,
            'vehicle_type': vehicleType,
            'license_number': licenseNumber,
            'license_document_url': licenseDocumentUrl,
            'vehicle_registration_url': vehicleRegistrationUrl,
            'availability_preferences': availabilityPreferences ?? {},
            'banking_details': bankingDetails ?? {},
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create runner profile: $error');
    }
  }

  /// Get seller profile by sub-profile ID
  Future<Map<String, dynamic>?> getSellerProfile(String subProfileId) async {
    try {
      final response = await _client
          .from('seller_profiles')
          .select('*, user_sub_profiles!inner(*)')
          .eq('user_profile_id', subProfileId)
          .eq('user_sub_profiles.user_id', _client.auth.currentUser!.id)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get seller profile: $error');
    }
  }

  /// Get runner profile by sub-profile ID
  Future<Map<String, dynamic>?> getRunnerProfile(String subProfileId) async {
    try {
      final response = await _client
          .from('runner_profiles')
          .select('*, user_sub_profiles!inner(*)')
          .eq('user_profile_id', subProfileId)
          .eq('user_sub_profiles.user_id', _client.auth.currentUser!.id)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get runner profile: $error');
    }
  }

  /// Update seller profile
  Future<Map<String, dynamic>> updateSellerProfile({
    required String profileId,
    String? businessName,
    String? businessDescription,
    String? businessAddress,
    String? businessLicenseUrl,
    String? taxNumber,
    Map<String, dynamic>? bankAccountDetails,
    Map<String, dynamic>? shopSettings,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (businessName != null) updateData['business_name'] = businessName;
      if (businessDescription != null)
        updateData['business_description'] = businessDescription;
      if (businessAddress != null)
        updateData['business_address'] = businessAddress;
      if (businessLicenseUrl != null)
        updateData['business_license_url'] = businessLicenseUrl;
      if (taxNumber != null) updateData['tax_number'] = taxNumber;
      if (bankAccountDetails != null)
        updateData['bank_account_details'] = bankAccountDetails;
      if (shopSettings != null) updateData['shop_settings'] = shopSettings;

      final response = await _client
          .from('seller_profiles')
          .update(updateData)
          .eq('id', profileId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update seller profile: $error');
    }
  }

  /// Update runner profile
  Future<Map<String, dynamic>> updateRunnerProfile({
    required String profileId,
    String? vehicleType,
    String? licenseNumber,
    String? licenseDocumentUrl,
    String? vehicleRegistrationUrl,
    bool? isAvailable,
    Map<String, dynamic>? availabilityPreferences,
    Map<String, dynamic>? bankingDetails,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (vehicleType != null) updateData['vehicle_type'] = vehicleType;
      if (licenseNumber != null) updateData['license_number'] = licenseNumber;
      if (licenseDocumentUrl != null)
        updateData['license_document_url'] = licenseDocumentUrl;
      if (vehicleRegistrationUrl != null)
        updateData['vehicle_registration_url'] = vehicleRegistrationUrl;
      if (isAvailable != null) updateData['is_available'] = isAvailable;
      if (availabilityPreferences != null)
        updateData['availability_preferences'] = availabilityPreferences;
      if (bankingDetails != null)
        updateData['banking_details'] = bankingDetails;

      final response = await _client
          .from('runner_profiles')
          .update(updateData)
          .eq('id', profileId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update runner profile: $error');
    }
  }

  /// Check if user has specific profile type
  Future<bool> hasProfileType(String profileType) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('user_sub_profiles')
          .select('id')
          .eq('user_id', user.id)
          .eq('profile_type', profileType)
          .eq('is_active', true);

      return response.isNotEmpty;
    } catch (error) {
      return false;
    }
  }

  /// Get active profile type
  Future<String?> getActiveProfileType() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_sub_profiles')
          .select('profile_type')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('created_at')
          .limit(1);

      if (response.isEmpty) return null;
      return response.first['profile_type'] as String?;
    } catch (error) {
      return null;
    }
  }
}

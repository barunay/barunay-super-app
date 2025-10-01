import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class DeliveryService {
  final SupabaseService _supabaseService = SupabaseService.instance;
  SupabaseClient get client => _supabaseService.client;

  // Delivery Request Management
  Future<List<Map<String, dynamic>>> getUserDeliveryRequests() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await client
          .from('delivery_requests')
          .select('''
            *,
            runner_profiles:assigned_runner_id(
              id,
              user_sub_profiles!runner_profiles_user_profile_id_fkey(
                user_profiles(full_name, avatar_url, phone)
              ),
              vehicle_type,
              rating_average,
              total_deliveries,
              current_latitude,
              current_longitude
            )
          ''')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch delivery requests: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getDeliveryRequest(String requestId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response =
          await client
              .from('delivery_requests')
              .select('''
            *,
            runner_profiles:assigned_runner_id(
              id,
              user_sub_profiles!runner_profiles_user_profile_id_fkey(
                user_profiles(full_name, avatar_url, phone)
              ),
              vehicle_type,
              rating_average,
              total_deliveries,
              current_latitude,
              current_longitude
            )
          ''')
              .eq('id', requestId)
              .or(
                'user_id.eq.$currentUserId,assigned_runner_id.in.(select id from runner_profiles where user_profile_id in (select id from user_sub_profiles where user_id = $currentUserId))',
              )
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch delivery request: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createDeliveryRequest({
    required String title,
    required String description,
    required String pickupAddress,
    required String deliveryAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? recipientName,
    String? recipientPhone,
    String? packageSize,
    double? packageWeight,
    double? packageValue,
    double? maxBudget,
    String urgency = 'medium',
    String? specialInstructions,
    DateTime? scheduledPickupTime,
    List<String>? photoUrls,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response =
          await client
              .from('delivery_requests')
              .insert({
                'user_id': currentUserId,
                'title': title,
                'description': description,
                'pickup_address': pickupAddress,
                'delivery_address': deliveryAddress,
                'pickup_latitude': pickupLatitude,
                'pickup_longitude': pickupLongitude,
                'delivery_latitude': deliveryLatitude,
                'delivery_longitude': deliveryLongitude,
                'recipient_name': recipientName,
                'recipient_phone': recipientPhone,
                'package_size': packageSize,
                'package_weight': packageWeight,
                'package_value': packageValue,
                'max_budget': maxBudget,
                'urgency': urgency,
                'special_instructions': specialInstructions,
                'scheduled_pickup_time': scheduledPickupTime?.toIso8601String(),
                'photo_urls': photoUrls,
                'status': 'pending',
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create delivery request: ${e.toString()}');
    }
  }

  Future<void> updateDeliveryRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      await client
          .from('delivery_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to update delivery status: ${e.toString()}');
    }
  }

  // Delivery Tasks Management
  Future<List<Map<String, dynamic>>> getRunnerDeliveryTasks() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final runnerProfileId = await _getRunnerProfileId();
      final response = await client
          .from('delivery_tasks')
          .select('''
            *,
            delivery_requests(
              title,
              description,
              pickup_address,
              delivery_address,
              recipient_name,
              recipient_phone,
              package_size,
              urgency,
              special_instructions,
              user_profiles!delivery_requests_user_id_fkey(
                full_name,
                phone,
                avatar_url
              )
            )
          ''')
          .eq('runner_id', runnerProfileId ?? '')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch delivery tasks: ${e.toString()}');
    }
  }

  Future<String?> _getRunnerProfileId() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response =
          await client
              .from('runner_profiles')
              .select('id')
              .eq(
                'user_profile_id',
                await client
                    .from('user_sub_profiles')
                    .select('id')
                    .eq('user_id', currentUserId)
                    .single()
                    .then((profile) => profile['id']),
              )
              .maybeSingle();

      return response?['id'];
    } catch (e) {
      return null;
    }
  }

  // Runner Proposals
  Future<List<Map<String, dynamic>>> getRunnerProposals(
    String deliveryRequestId,
  ) async {
    try {
      final response = await client
          .from('runner_proposals')
          .select('''
            *,
            runner_profiles(
              user_sub_profiles!runner_profiles_user_profile_id_fkey(
                user_profiles(full_name, avatar_url)
              ),
              vehicle_type,
              rating_average,
              total_deliveries
            )
          ''')
          .eq('delivery_request_id', deliveryRequestId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch runner proposals: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createRunnerProposal({
    required String deliveryRequestId,
    required double proposedFee,
    String? message,
    int? estimatedTime,
  }) async {
    try {
      final runnerId = await _getRunnerProfileId();
      if (runnerId == null) throw Exception('Runner profile not found');

      final response =
          await client
              .from('runner_proposals')
              .insert({
                'delivery_request_id': deliveryRequestId,
                'runner_id': runnerId,
                'proposed_fee': proposedFee,
                'message': message,
                'estimated_time_minutes': estimatedTime,
                'status': 'pending',
              })
              .select()
              .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create runner proposal: ${e.toString()}');
    }
  }

  Future<void> acceptRunnerProposal(String proposalId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Start a transaction
      await client.rpc(
        'accept_runner_proposal',
        params: {'proposal_id': proposalId, 'user_id': currentUserId},
      );
    } catch (e) {
      throw Exception('Failed to accept runner proposal: ${e.toString()}');
    }
  }

  // Delivery Tracking
  Future<Map<String, dynamic>?> getDeliveryTracking(
    String deliveryRequestId,
  ) async {
    try {
      final response =
          await client
              .from('delivery_tasks')
              .select('''
            *,
            delivery_requests(
              *,
              user_profiles!delivery_requests_user_id_fkey(full_name, phone)
            ),
            runner_profiles(
              user_sub_profiles!runner_profiles_user_profile_id_fkey(
                user_profiles(full_name, avatar_url, phone)
              ),
              vehicle_type,
              current_latitude,
              current_longitude,
              rating_average,
              total_deliveries
            )
          ''')
              .eq('delivery_request_id', deliveryRequestId)
              .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch delivery tracking: ${e.toString()}');
    }
  }

  Future<void> updateDeliveryLocation(
    String taskId,
    double latitude,
    double longitude,
  ) async {
    try {
      await client.rpc(
        'update_runner_location',
        params: {'task_id': taskId, 'lat': latitude, 'lng': longitude},
      );
    } catch (e) {
      throw Exception('Failed to update delivery location: ${e.toString()}');
    }
  }

  // Delivery Completion
  Future<void> completeDelivery({
    required String taskId,
    String? deliveryPhoto,
    String? runnerNotes,
    int? customerRating,
    String? customerFeedback,
  }) async {
    try {
      await client
          .from('delivery_tasks')
          .update({
            'task_status': 'delivered',
            'delivery_confirmation_photo': deliveryPhoto,
            'runner_notes': runnerNotes,
            'customer_rating': customerRating,
            'customer_feedback': customerFeedback,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to complete delivery: ${e.toString()}');
    }
  }

  // Real-time Subscriptions
  RealtimeChannel subscribeToDeliveryUpdates(
    String deliveryRequestId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return client
        .channel('delivery:$deliveryRequestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_requests',
          callback: (payload) {
            if (payload.newRecord['id'] == deliveryRequestId) {
              onUpdate(payload.newRecord);
            }
          },
        );
  }

  RealtimeChannel subscribeToRunnerLocation(
    String taskId,
    void Function(Map<String, dynamic>) onLocationUpdate,
  ) {
    return client
        .channel('runner_location:$taskId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_tasks',
          callback: (payload) {
            if (payload.newRecord['id'] == taskId) {
              onLocationUpdate(payload.newRecord);
            }
          },
        );
  }

  void unsubscribe(RealtimeChannel channel) {
    client.removeChannel(channel);
  }
}

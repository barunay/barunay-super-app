-- Location: supabase/migrations/20250912091122_comprehensive_mock_data.sql
-- Schema Analysis: Complete marketplace system with chat, delivery, and user management
-- Integration Type: Mock data population for existing schema
-- Dependencies: user_profiles, delivery_requests, marketplace_conversations, marketplace_messages

-- Comprehensive mock data for testing marketplace functionality
DO $$
DECLARE
    -- User IDs
    buyer_uuid UUID := gen_random_uuid();
    seller_uuid UUID := gen_random_uuid(); 
    runner_uuid UUID := gen_random_uuid();
    admin_uuid UUID := gen_random_uuid();
    
    -- Business record IDs
    delivery_request_1 UUID := gen_random_uuid();
    delivery_request_2 UUID := gen_random_uuid();
    delivery_request_3 UUID := gen_random_uuid();
    conversation_1 UUID := gen_random_uuid();
    conversation_2 UUID := gen_random_uuid();
    conversation_3 UUID := gen_random_uuid();
    
    -- Runner profile IDs
    runner_profile_1 UUID := gen_random_uuid();
    runner_profile_2 UUID := gen_random_uuid();
    
    -- Sub profile IDs
    sub_profile_1 UUID := gen_random_uuid();
    sub_profile_2 UUID := gen_random_uuid();
    sub_profile_3 UUID := gen_random_uuid();
    
BEGIN
    -- Step 1: Create comprehensive auth.users with all required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (buyer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'buyer@marketplace.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, '+673 123 4567', '', '', null),
         
        (seller_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'seller@marketplace.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Seller"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, '+673 234 5678', '', '', null),
         
        (runner_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'runner@marketplace.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Mike Runner"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, '+673 345 6789', '', '', null),
         
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@marketplace.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, '+673 456 7890', '', '', null);

    -- Step 2: Update existing user_profiles with comprehensive data
    UPDATE public.user_profiles SET
        full_name = 'Comprehensive Test User',
        phone = '+673 987 6543',
        role = 'buyer'::user_role,
        profile_status = 'active'::profile_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = '7f32eb2f-8ee1-4a1f-8a8e-fd405dc95402';

    -- Step 3: Create user sub profiles
    INSERT INTO public.user_sub_profiles (id, user_id, profile_type, business_name, business_address, contact_phone, contact_email, is_verified)
    VALUES 
        (sub_profile_1, seller_uuid, 'seller'::profile_type, 'Sarah''s Electronics Store', 'Gadong Central, Bandar Seri Begawan', '+673 234 5678', 'sarah@electronics.bn', true),
        (sub_profile_2, runner_uuid, 'runner'::profile_type, 'Mike Express Delivery', 'Jerudong Area, Brunei', '+673 345 6789', 'mike@express.bn', true),
        (sub_profile_3, buyer_uuid, 'shopper'::profile_type, 'Personal Shopping', 'Kampong Ayer, BSB', '+673 123 4567', 'john@personal.bn', true);

    -- Step 4: Create runner profiles  
    INSERT INTO public.runner_profiles (id, user_profile_id, vehicle_type, license_plate, availability_status, current_location, rating_average, total_deliveries, is_active)
    VALUES
        (runner_profile_1, sub_profile_2, 'motorcycle', 'BA 1234 A', 'available', POINT(114.9398, 4.9031), 4.8, 156, true),
        (runner_profile_2, sub_profile_3, 'car', 'KB 5678 B', 'busy', POINT(114.8619, 4.8903), 4.6, 89, true);

    -- Step 5: Create comprehensive delivery requests
    INSERT INTO public.delivery_requests (
        id, user_id, title, description, pickup_address, delivery_address, 
        pickup_latitude, pickup_longitude, delivery_latitude, delivery_longitude,
        recipient_name, recipient_phone, package_size, package_weight, package_value,
        max_budget, urgency, status, special_instructions, assigned_runner_id,
        scheduled_pickup_time, estimated_distance
    ) VALUES
        (delivery_request_1, buyer_uuid, 'Urgent Document Delivery', 
         'Important legal documents need to be delivered to lawyer office before 5 PM today',
         'UBD Campus, Jalan Tungku Link', 'Legal Associates Office, Kiulap Plaza',
         4.9679, 114.9080, 4.9087, 114.9141, 
         'Dato Ahmad', '+673 222 3456', 'small', 0.5, 500.00,
         20.00, 'urgent'::urgency_level, 'awaiting_runner'::delivery_status,
         'Handle with extreme care. Ring buzzer twice.', null, 
         now() + interval '1 hour', 8.5),

        (delivery_request_2, seller_uuid, 'Gadget Delivery to Customer',
         'Brand new smartphone delivery to satisfied customer in Jerudong area',
         'Gadong Central Shopping Complex', 'Jerudong Park Country Club',
         4.9087, 114.9141, 4.8532, 114.8644,
         'Hjh Fatimah', '+673 333 4567', 'medium', 1.2, 2500.00,
         35.00, 'medium'::urgency_level, 'runner_assigned'::delivery_status,
         'Customer will pay additional $50 upon delivery. Get receipt.', runner_profile_1,
         now() + interval '2 hours', 15.3),

        (delivery_request_3, buyer_uuid, 'Birthday Surprise Cake',
         'Special order chocolate cake for daughter''s 10th birthday party',
         'Secret Recipe Gadong', 'Taman Jubli Emas, Tutong',
         4.9087, 114.9141, 4.8087, 114.6441,
         'Md. Rahman', '+673 444 5678', 'large', 2.5, 80.00,
         45.00, 'high'::urgency_level, 'in_transit'::delivery_status,
         'Keep cake level. Party starts at 3 PM. Call upon arrival.', runner_profile_2,
         now() + interval '30 minutes', 28.7);

    -- Step 6: Create marketplace conversations
    INSERT INTO public.marketplace_conversations (
        id, participant_one_id, participant_two_id, chat_type, 
        delivery_request_id, last_message_at, is_blocked, is_archived
    ) VALUES
        (conversation_1, buyer_uuid, runner_uuid, 'delivery'::chat_type, 
         delivery_request_1, now() - interval '5 minutes', false, false),
         
        (conversation_2, seller_uuid, buyer_uuid, 'product_inquiry'::chat_type,
         null, now() - interval '15 minutes', false, false),
         
        (conversation_3, buyer_uuid, runner_uuid, 'delivery'::chat_type,
         delivery_request_3, now() - interval '2 minutes', false, false);

    -- Step 7: Create realistic marketplace messages
    INSERT INTO public.marketplace_messages (
        conversation_id, sender_id, message_text, status, media_type, is_quick_reply
    ) VALUES
        -- Conversation 1: Delivery coordination
        (conversation_1, buyer_uuid, 'Hi! I have an urgent document delivery request. Can you handle it today?', 'read'::message_status, null, false),
        (conversation_1, runner_uuid, 'Hello! Yes, I can definitely help. What time do you need it delivered?', 'read'::message_status, null, false),
        (conversation_1, buyer_uuid, 'Before 5 PM today if possible. It''s legal documents.', 'read'::message_status, null, false),
        (conversation_1, runner_uuid, 'Perfect! I can pick it up within 30 minutes. I''ll be very careful with the documents.', 'delivered'::message_status, null, false),
        (conversation_1, buyer_uuid, 'Thank you so much! I''ll be waiting at UBD Campus main entrance.', 'sent'::message_status, null, false),

        -- Conversation 2: Product inquiry
        (conversation_2, buyer_uuid, 'Hi! Is the iPhone 15 Pro still available? What''s the condition?', 'read'::message_status, null, false),
        (conversation_2, seller_uuid, 'Yes it''s still available! Brand new, sealed box with 1 year warranty.', 'read'::message_status, null, false),
        (conversation_2, buyer_uuid, 'Great! Can I see more photos? Especially the box and accessories?', 'read'::message_status, null, false),
        (conversation_2, seller_uuid, 'Of course! I''ll send photos now. All original accessories included.', 'delivered'::message_status, null, false),

        -- Conversation 3: Birthday cake delivery
        (conversation_3, buyer_uuid, 'Hi Mike! How''s the cake delivery going? The party starts soon.', 'read'::message_status, null, false),
        (conversation_3, runner_uuid, 'Hi! I''m 10 minutes away. The cake is safe and level. ETA 2:45 PM.', 'delivered'::message_status, null, false),
        (conversation_3, buyer_uuid, 'Perfect timing! Thank you for being so careful with it.', 'sent'::message_status, null, false);

    -- Step 8: Create quick reply templates
    INSERT INTO public.quick_reply_templates (user_id, template_name, message_text, chat_type, usage_count, is_active)
    VALUES
        (runner_uuid, 'Pickup Confirmation', 'I''m here for pickup. Where exactly should I meet you?', 'delivery'::chat_type, 25, true),
        (runner_uuid, 'Delivery Update', 'I''m 10 minutes away from delivery location. Please be ready to receive.', 'delivery'::chat_type, 32, true),
        (runner_uuid, 'Safe Delivery', 'Package delivered safely. Thank you for choosing our service!', 'delivery'::chat_type, 45, true),
        (seller_uuid, 'Product Available', 'Yes, this item is still available. Would you like to see more details?', 'product_inquiry'::chat_type, 18, true),
        (seller_uuid, 'Price Negotiation', 'The lowest price I can offer is as mentioned. Quality guaranteed!', 'product_inquiry'::chat_type, 12, true),
        (buyer_uuid, 'Interested Buyer', 'Hi! I''m interested in this item. Is it still available?', 'general'::chat_type, 8, true);

    -- Step 9: Create runner proposals for delivery requests
    INSERT INTO public.runner_proposals (runner_id, delivery_request_id, proposed_price, estimated_time, proposal_message, status)
    VALUES
        (runner_profile_1, delivery_request_1, 18.00, 45, 'I can handle this urgent delivery with extra care. I have experience with legal documents.', 'pending'::proposal_status),
        (runner_profile_2, delivery_request_1, 22.00, 35, 'Available now for immediate pickup. I guarantee safe delivery before 5 PM.', 'pending'::proposal_status),
        (runner_profile_1, delivery_request_2, 30.00, 60, 'I''ll ensure the gadget is delivered safely with proper handling.', 'accepted'::proposal_status);

    -- Step 10: Create delivery tasks for accepted proposals
    INSERT INTO public.delivery_tasks (delivery_request_id, runner_id, accepted_proposal_id, pickup_time, delivery_time, completion_status, total_amount)
    VALUES
        (delivery_request_2, runner_profile_1, (SELECT id FROM public.runner_proposals WHERE runner_id = runner_profile_1 AND delivery_request_id = delivery_request_2 LIMIT 1),
         now() - interval '1 hour', null, 'in_progress', 30.00),
        
        (delivery_request_3, runner_profile_2, null,
         now() - interval '30 minutes', null, 'in_progress', 45.00);

    -- Step 11: Create runner earnings records
    INSERT INTO public.runner_earnings (runner_id, delivery_task_id, base_amount, tip_amount, platform_fee, net_earnings, earned_at)
    VALUES
        (runner_profile_2, (SELECT id FROM public.delivery_tasks WHERE runner_id = runner_profile_2 LIMIT 1),
         45.00, 10.00, 4.50, 50.50, now() - interval '2 days'),
        
        (runner_profile_1, (SELECT id FROM public.delivery_tasks WHERE runner_id = runner_profile_1 LIMIT 1),
         30.00, 5.00, 3.00, 32.00, now() - interval '1 day');

    -- Step 12: Create delivery notifications
    INSERT INTO public.delivery_notifications (user_id, delivery_request_id, notification_type, title, message, is_read)
    VALUES
        (buyer_uuid, delivery_request_1, 'status_update', 'Delivery Request Update', 'Your urgent document delivery has received 2 runner proposals.', false),
        (seller_uuid, delivery_request_2, 'runner_assigned', 'Runner Assigned', 'Mike Runner has been assigned to your gadget delivery. Estimated pickup in 30 minutes.', true),
        (buyer_uuid, delivery_request_3, 'in_transit', 'Delivery In Progress', 'Your birthday cake is on the way! Estimated arrival: 2:45 PM.', false);

    -- Success notification
    RAISE NOTICE 'Comprehensive mock data created successfully!';
    RAISE NOTICE 'Test Credentials Created:';
    RAISE NOTICE 'Buyer: buyer@marketplace.com / password123';  
    RAISE NOTICE 'Seller: seller@marketplace.com / password123';
    RAISE NOTICE 'Runner: runner@marketplace.com / password123';
    RAISE NOTICE 'Admin: admin@marketplace.com / password123';
    RAISE NOTICE 'Total Records: 4 users, 3 delivery requests, 3 conversations, 13 messages';

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error during mock data creation: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error during mock data creation: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error during mock data creation: %', SQLERRM;
END $$;

-- Create cleanup function for test data
CREATE OR REPLACE FUNCTION public.cleanup_marketplace_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    test_user_ids UUID[];
BEGIN
    -- Get test user IDs
    SELECT ARRAY_AGG(id) INTO test_user_ids
    FROM auth.users
    WHERE email IN ('buyer@marketplace.com', 'seller@marketplace.com', 'runner@marketplace.com', 'admin@marketplace.com');

    -- Delete in dependency order (children first)
    DELETE FROM public.delivery_notifications WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.runner_earnings WHERE runner_id IN (SELECT id FROM public.runner_profiles WHERE user_profile_id = ANY(test_user_ids));
    DELETE FROM public.delivery_tasks WHERE runner_id IN (SELECT id FROM public.runner_profiles WHERE user_profile_id = ANY(test_user_ids));
    DELETE FROM public.runner_proposals WHERE runner_id IN (SELECT id FROM public.runner_profiles WHERE user_profile_id = ANY(test_user_ids));
    DELETE FROM public.quick_reply_templates WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.chat_read_receipts WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.marketplace_messages WHERE sender_id = ANY(test_user_ids);
    DELETE FROM public.marketplace_conversations WHERE participant_one_id = ANY(test_user_ids) OR participant_two_id = ANY(test_user_ids);
    DELETE FROM public.delivery_requests WHERE user_id = ANY(test_user_ids) OR assigned_runner_id IN (SELECT id FROM public.runner_profiles WHERE user_profile_id = ANY(test_user_ids));
    DELETE FROM public.runner_profiles WHERE user_profile_id IN (SELECT id FROM public.user_sub_profiles WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.seller_profiles WHERE user_profile_id IN (SELECT id FROM public.user_sub_profiles WHERE user_id = ANY(test_user_ids));
    DELETE FROM public.user_sub_profiles WHERE user_id = ANY(test_user_ids);
    DELETE FROM public.user_profiles WHERE id = ANY(test_user_ids);
    
    -- Delete auth.users last
    DELETE FROM auth.users WHERE id = ANY(test_user_ids);
    
    RAISE NOTICE 'Test data cleanup completed successfully!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END $$;
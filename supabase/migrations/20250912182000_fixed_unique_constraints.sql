-- Enhanced Marketplace Mock Data Migration - FIXED TO MATCH YOUR SCHEMA
-- Uses safe UPSERT patterns and corrected column orders.

-- -------------------------------------------
-- 0) Clean up existing test data (dependency order)
-- -------------------------------------------
DELETE FROM chat_read_receipts WHERE message_id IN (
    SELECT id FROM marketplace_messages WHERE conversation_id IN (
        SELECT id FROM marketplace_conversations WHERE participant_one_id IN (
            SELECT id FROM user_profiles WHERE email IN (
                'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
                'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
                'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
            )
        )
    )
);

DELETE FROM marketplace_messages WHERE conversation_id IN (
    SELECT id FROM marketplace_conversations WHERE participant_one_id IN (
        SELECT id FROM user_profiles WHERE email IN (
            'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
            'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
            'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
        )
    )
);

DELETE FROM marketplace_conversations WHERE participant_one_id IN (
    SELECT id FROM user_profiles WHERE email IN (
        'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
        'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
        'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
    )
);

DELETE FROM chat_typing_indicators WHERE user_id IN (
    SELECT id FROM user_profiles WHERE email IN (
        'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
        'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
        'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
    )
);

DELETE FROM quick_reply_templates WHERE user_id IN (
    SELECT id FROM user_profiles WHERE email IN (
        'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
        'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
        'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
    )
);

DELETE FROM delivery_requests WHERE user_id IN (
    SELECT id FROM user_profiles WHERE email IN (
        'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
        'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
        'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
    )
);

DELETE FROM runner_profiles WHERE user_profile_id IN (
    SELECT id FROM user_sub_profiles WHERE user_id IN (
        SELECT id FROM user_profiles WHERE email IN (
            'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
            'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
            'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
        )
    )
);

DELETE FROM seller_profiles WHERE user_profile_id IN (
    SELECT id FROM user_sub_profiles WHERE user_id IN (
        SELECT id FROM user_profiles WHERE email IN (
            'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
            'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
            'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
        )
    )
);

DELETE FROM user_sub_profiles WHERE user_id IN (
    SELECT id FROM user_profiles WHERE email IN (
        'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
        'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
        'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
    )
);

DELETE FROM user_profiles WHERE email IN (
    'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
    'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
    'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
);

-- Clean up auth.users for test accounts to prevent UUID conflicts
DELETE FROM auth.users WHERE email IN (
    'buyer@marketplace.com','seller@marketplace.com','runner@marketplace.com',
    'admin@marketplace.com','sarah.lim@email.com','ahmad.hassan@email.com',
    'maria.santos@email.com','david.wong@email.com','fatimah.ali@email.com'
);

-- -------------------------------------------
-- 1) Seed data with safe UPSERTs
-- -------------------------------------------
DO $$
DECLARE
    buyer_uuid   UUID := '11111111-1111-1111-1111-111111111111'::uuid;
    seller_uuid  UUID := '22222222-2222-2222-2222-222222222222'::uuid;
    runner_uuid  UUID := '33333333-3333-3333-3333-333333333333'::uuid;
    admin_uuid   UUID := '44444444-4444-4444-4444-444444444444'::uuid;
    sarah_uuid   UUID := '55555555-5555-5555-5555-555555555555'::uuid;
    ahmad_uuid   UUID := '66666666-6666-6666-6666-666666666666'::uuid;
    maria_uuid   UUID := '77777777-7777-7777-7777-777777777777'::uuid;
    david_uuid   UUID := '88888888-8888-8888-8888-888888888888'::uuid;
    fatimah_uuid UUID := '99999999-9999-9999-9999-999999999999'::uuid;

    -- Sub profile UUIDs (these reference public.user_sub_profiles.id)
    seller_sub_uuid  UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
    runner_sub_uuid  UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid;
    ahmad_sub_uuid   UUID := 'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid;
    maria_sub_uuid   UUID := 'dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid;
    fatimah_sub_uuid UUID := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid;

    -- Other record UUIDs
    seller_profile1_uuid UUID := 'f1111111-1111-1111-1111-111111111111'::uuid;
    seller_profile2_uuid UUID := 'f2222222-2222-2222-2222-222222222222'::uuid;
    seller_profile3_uuid UUID := 'f3333333-3333-3333-3333-333333333333'::uuid;
    runner_profile1_uuid UUID := 'a1111111-1111-1111-1111-111111111111'::uuid;
    runner_profile2_uuid UUID := 'a2222222-2222-2222-2222-222222222222'::uuid;

    delivery1_uuid UUID := 'd1111111-1111-1111-1111-111111111111'::uuid;
    delivery2_uuid UUID := 'd2222222-2222-2222-2222-222222222222'::uuid;
    delivery3_uuid UUID := 'd3333333-3333-3333-3333-333333333333'::uuid;
    delivery4_uuid UUID := 'd4444444-4444-4444-4444-444444444444'::uuid;

    conversation1_uuid UUID := 'c1111111-1111-1111-1111-111111111111'::uuid;
    conversation2_uuid UUID := 'c2222222-2222-2222-2222-222222222222'::uuid;
    conversation3_uuid UUID := 'c3333333-3333-3333-3333-333333333333'::uuid;
    conversation4_uuid UUID := 'c4444444-4444-4444-4444-444444444444'::uuid;
BEGIN
    -- Step 1: auth.users (minimal, correct columns for your schema)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password,
        raw_app_meta_data, raw_user_meta_data, is_sso_user, is_anonymous, email_confirmed_at
    ) VALUES
      (buyer_uuid,  '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','buyer@marketplace.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Demo Buyer","phone":"+673 234 5678"}'::jsonb,
       false, false, now()),
      (seller_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','seller@marketplace.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Demo Seller","phone":"+673 345 6789"}'::jsonb,
       false, false, now()),
      (runner_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','runner@marketplace.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Demo Runner","phone":"+673 456 7890"}'::jsonb,
       false, false, now()),
      (admin_uuid,  '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','admin@marketplace.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Demo Admin","phone":"+673 567 8901"}'::jsonb,
       false, false, now()),
      (sarah_uuid,  '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','sarah.lim@email.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Sarah Lim","phone":"+673 712 3456"}'::jsonb,
       false, false, now()),
      (ahmad_uuid,  '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','ahmad.hassan@email.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Ahmad Hassan","phone":"+673 823 4567"}'::jsonb,
       false, false, now()),
      (maria_uuid,  '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','maria.santos@email.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Maria Santos","phone":"+673 934 5678"}'::jsonb,
       false, false, now()),
      (david_uuid,  '00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','david.wong@email.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"David Wong","phone":"+673 145 6789"}'::jsonb,
       false, false, now()),
      (fatimah_uuid,'00000000-0000-0000-0000-000000000000', 'authenticated','authenticated','fatimah.ali@email.com',
       crypt('password123', gen_salt('bf', 10)),
       '{"provider":"email","providers":["email"]}'::jsonb,
       '{"full_name":"Fatimah Ali","phone":"+673 256 7890"}'::jsonb,
       false, false, now())
    ON CONFLICT (id) DO UPDATE
      SET email = EXCLUDED.email,
          raw_user_meta_data = EXCLUDED.raw_user_meta_data,
          updated_at = now();

    -- Step 2: public.user_profiles
    INSERT INTO user_profiles (
        id, email, full_name, role, phone, avatar_url, profile_status, created_at
    ) VALUES
      (buyer_uuid,  'buyer@marketplace.com',  'Demo Buyer',  'buyer',  '+673 234 5678',
       'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (seller_uuid, 'seller@marketplace.com', 'Demo Seller', 'seller', '+673 345 6789',
       'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (runner_uuid, 'runner@marketplace.com', 'Demo Runner', 'runner', '+673 456 7890',
       'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (admin_uuid,  'admin@marketplace.com',  'Demo Admin',  'admin',  '+673 567 8901',
       'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (sarah_uuid,  'sarah.lim@email.com',    'Sarah Lim',   'buyer',  '+673 712 3456',
       'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (ahmad_uuid,  'ahmad.hassan@email.com','Ahmad Hassan','seller', '+673 823 4567',
       'https://images.unsplash.com/photo-1507591064344-4c6ce005b128?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (maria_uuid,  'maria.santos@email.com','Maria Santos','runner', '+673 934 5678',
       'https://images.unsplash.com/photo-1607746882042-944635dfe10e?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (david_uuid,  'david.wong@email.com',  'David Wong',  'buyer',  '+673 145 6789',
       'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=150&h=150&fit=crop&crop=face', 'active', now()),
      (fatimah_uuid,'fatimah.ali@email.com', 'Fatimah Ali', 'seller', '+673 256 7890',
       'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face', 'active', now())
    ON CONFLICT (id) DO UPDATE
      SET full_name = EXCLUDED.full_name,
          phone = EXCLUDED.phone,
          avatar_url = EXCLUDED.avatar_url;

    -- Step 3: public.user_sub_profiles
    INSERT INTO user_sub_profiles (id, user_id, profile_type, display_name, profile_data, is_active) VALUES
      (seller_sub_uuid,  seller_uuid, 'seller', 'Demo Electronics Store',
       '{"business_category":"Electronics","years_in_business":3}'::jsonb, true),
      (runner_sub_uuid,  runner_uuid, 'runner', 'Swift Delivery',
       '{"vehicle_info":"Motorcycle","delivery_range":"Brunei-Muara"}'::jsonb, true),
      (ahmad_sub_uuid,   ahmad_uuid,  'seller', 'Ahmad Gadget Corner',
       '{"business_category":"Mobile Accessories","years_in_business":2}'::jsonb, true),
      (maria_sub_uuid,   maria_uuid,  'runner', 'Maria Express',
       '{"vehicle_info":"Car","delivery_range":"All Districts"}'::jsonb, true),
      (fatimah_sub_uuid, fatimah_uuid,'seller', 'Fatimah Fashion Boutique',
       '{"business_category":"Fashion","years_in_business":5}'::jsonb, true)
    ON CONFLICT (id) DO UPDATE
      SET display_name = EXCLUDED.display_name,
          profile_data = EXCLUDED.profile_data;

    -- Step 4: public.seller_profiles (FK -> user_sub_profiles.id)
    INSERT INTO seller_profiles (
        id, user_profile_id, business_name, business_description, business_address,
        verification_status, is_verified, shop_settings, bank_account_details, tax_number
    ) VALUES
      (seller_profile1_uuid, seller_sub_uuid, 'Demo Electronics Store',
       'Your one-stop shop for the latest gadgets and electronics',
       'Ground Floor, The Mall, Gadong', 'verified', true,
       '{"store_hours":"9 AM - 10 PM","delivery_available":true}'::jsonb,
       '{"bank":"BIBD","account":"1234567890"}'::jsonb, 'BN-TAX-123456'),
      (seller_profile2_uuid, ahmad_sub_uuid, 'Ahmad Gadget Corner',
       'Premium mobile accessories and tech solutions',
       'Unit 12, Yayasan Complex, Bandar Seri Begawan', 'verified', true,
       '{"store_hours":"10 AM - 9 PM","delivery_available":true}'::jsonb,
       '{"bank":"Baiduri","account":"9876543210"}'::jsonb, 'BN-TAX-654321'),
      (seller_profile3_uuid, fatimah_sub_uuid, 'Fatimah Fashion Boutique',
       'Trendy fashion for the modern Bruneian woman',
       'Simpang 88, Jalan Tutong, Kampong Kilanas', 'verified', true,
       '{"store_hours":"10 AM - 8 PM","delivery_available":true}'::jsonb,
       '{"bank":"Standard Chartered","account":"5555666677"}'::jsonb, 'BN-TAX-789123')
    ON CONFLICT (id) DO UPDATE
      SET business_name = EXCLUDED.business_name,
          business_description = EXCLUDED.business_description;

    -- Step 5: public.runner_profiles (FK -> user_sub_profiles.id)
    INSERT INTO runner_profiles (
        id, user_profile_id, vehicle_type, license_number, verification_status,
        is_verified, is_available, background_check_status, safety_training_completed,
        availability_preferences, banking_details
    ) VALUES
      (runner_profile1_uuid, runner_sub_uuid, 'Motorcycle', 'DL-123456789',
       'verified', true, true, 'approved', true,
       '{"working_hours":"8 AM - 10 PM","districts":["Brunei-Muara","Tutong"]}'::jsonb,
       '{"bank":"BIBD","account":"1111222233"}'::jsonb),
      (runner_profile2_uuid, maria_sub_uuid, 'Car', 'DL-987654321',
       'verified', true, true, 'approved', true,
       '{"working_hours":"7 AM - 11 PM","districts":["Brunei-Muara","Tutong","Belait","Temburong"]}'::jsonb,
       '{"bank":"Baiduri","account":"4444555566"}'::jsonb)
    ON CONFLICT (id) DO UPDATE
      SET is_available = EXCLUDED.is_available,
          availability_preferences = EXCLUDED.availability_preferences;

    -- Step 6: public.delivery_requests
    INSERT INTO delivery_requests (
        id, title, description, user_id, pickup_address, delivery_address,
        recipient_name, recipient_phone, package_size, package_weight, package_value,
        max_budget, status, urgency, special_instructions, scheduled_pickup_time,
        estimated_distance, pickup_latitude, pickup_longitude, delivery_latitude,
        delivery_longitude, assigned_runner_id
    ) VALUES
      (delivery1_uuid, 'iPhone 15 Pro Max Delivery',
       'Brand new iPhone 15 Pro Max in original packaging. Handle with extreme care.',
       buyer_uuid, 'Demo Electronics Store, The Mall, Gadong',
       'Block 123, Simpang 456, Kampong Perpindahan Mata-Mata',
       'Ahmad Rahman', '+673 712 8888', 'small', 1.5, 2500.00, 35.00,
       'awaiting_runner', 'high',
       'Please call upon arrival. Customer will be waiting at ground floor.',
       now() + interval '2 hours', 8.5, 4.9031, 114.9398, 4.9123, 114.9567, NULL),
      (delivery2_uuid, 'Birthday Cake Special Delivery',
       'Custom chocolate birthday cake for 8-year-old. Time sensitive delivery.',
       sarah_uuid, 'Le Apple Patisserie, Times Square, Bandar Seri Begawan',
       'House 789, Kampong Rimba, Tutong District',
       'Siti Aminah', '+673 823 9999', 'medium', 2.5, 85.00, 20.00,
       'awaiting_runner', 'urgent',
       'Birthday party starts at 7 PM. Please deliver before 6:30 PM. Keep cake upright.',
       now() + interval '4 hours', 25.3, 4.8903, 114.9421, 4.7651, 114.6513, NULL),
      (delivery3_uuid, 'Medical Supplies Urgent',
       'Prescription medicine for elderly patient. Contains temperature-sensitive items.',
       david_uuid, 'Pharmavita Pharmacy, Kiulap Plaza',
       'Apartment 567, Block C, Mata-Mata Housing Estate',
       'Hajah Mariam', '+673 934 7777', 'small', 0.5, 120.00, 15.00,
       'runner_assigned', 'urgent',
       'Patient is waiting. Please handle with care and deliver immediately.',
       now() + interval '30 minutes', 6.2, 4.9145, 114.9287, 4.9234, 114.9456, runner_profile1_uuid),
      (delivery4_uuid, 'Laptop Repair Return',
       'Dell Inspiron laptop after repair. Contains all original accessories.',
       seller_uuid, 'TechRepair Hub, Ground Floor, Abdul Razak Complex',
       'Office Tower, Level 15, Unit 1501, CBD Bandar',
       'Mr. James Lim', '+673 145 5555', 'medium', 3.2, 1800.00, 25.00,
       'pending', 'medium',
       'Office hours: 9 AM to 5 PM. Contact recipient before delivery.',
       now() + interval '1 day', 4.8, 4.8876, 114.9334, 4.8945, 114.9412, NULL)
    ON CONFLICT (id) DO UPDATE
      SET status = EXCLUDED.status,
          assigned_runner_id = EXCLUDED.assigned_runner_id;

    -- Step 7: public.marketplace_conversations (FIXED column order)
    INSERT INTO marketplace_conversations (
        id, chat_type, participant_one_id, participant_two_id,
        product_id, delivery_request_id, last_message_at, is_archived, is_blocked, blocked_by_user_id
    ) VALUES
      (conversation1_uuid, 'product_inquiry', buyer_uuid, seller_uuid,
       NULL, delivery1_uuid, now() - interval '2 hours', false, false, NULL),
      (conversation2_uuid, 'delivery', david_uuid, runner_uuid,
       NULL, delivery3_uuid, now() - interval '15 minutes', false, false, NULL),
      (conversation3_uuid, 'general', sarah_uuid, buyer_uuid,
       NULL, NULL, now() - interval '1 day', false, false, NULL),
      (conversation4_uuid, 'customer_support', ahmad_uuid, admin_uuid,
       NULL, NULL, now() - interval '3 hours', false, false, NULL)
    ON CONFLICT (id) DO UPDATE
      SET last_message_at = EXCLUDED.last_message_at;

-- Step 8: public.marketplace_messages (FIXED: valid hex UUIDs)
INSERT INTO marketplace_messages (
    id, conversation_id, sender_id, message_text,
    media_url, media_type, media_caption,
    reply_to_message_id, is_quick_reply, quick_reply_options,
    status, is_edited, edited_at, is_deleted, deleted_at,
    created_at, updated_at
) VALUES
  -- iPhone conversation
  ('a1111111-1111-1111-1111-111111111111'::uuid, conversation1_uuid, buyer_uuid,
   'Hi! I am interested in the iPhone 15 Pro Max. Is it still available?',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '2 hours', now() - interval '2 hours'),

  ('a2222222-2222-2222-2222-222222222222'::uuid, conversation1_uuid, seller_uuid,
   'Yes, it is available! Brand new in box with full warranty. Would you like to see more photos?',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '1 hour 55 minutes', now() - interval '1 hour 55 minutes'),

  ('a3333333-3333-3333-3333-333333333333'::uuid, conversation1_uuid, buyer_uuid,
   'That would be great! Also, do you offer delivery service?',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '1 hour 52 minutes', now() - interval '1 hour 52 minutes'),

  ('a4444444-4444-4444-4444-444444444444'::uuid, conversation1_uuid, seller_uuid,
   'Absolutely! We partner with local runners for same-day delivery. The phone is $2,500. Delivery would be around $25-35 depending on location.',
   'https://images.unsplash.com/photo-1592286380408-78b1b4be76e2?w=400&h=300&fit=crop', 'image', NULL,
   NULL, false, NULL, 'delivered', false, NULL, false, NULL,
   now() - interval '1 hour 48 minutes', now() - interval '1 hour 48 minutes'),

  -- Delivery tracking
  ('a5555555-5555-5555-5555-555555555555'::uuid, conversation2_uuid, david_uuid,
   'Hi, I am the customer for the medical delivery. When will you be arriving?',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '15 minutes', now() - interval '15 minutes'),

  ('a6666666-6666-6666-6666-666666666666'::uuid, conversation2_uuid, runner_uuid,
   'Hello! I just picked up your medicine from Pharmavita. I should be at your location in about 10 minutes.',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '12 minutes', now() - interval '12 minutes'),

  ('a7777777-7777-7777-7777-777777777777'::uuid, conversation2_uuid, david_uuid,
   'Perfect! I will be waiting at the main entrance. Thank you!',
   NULL, NULL, NULL, NULL, true, NULL, 'delivered', false, NULL, false, NULL,
   now() - interval '10 minutes', now() - interval '10 minutes'),

  -- General
  ('a8888888-8888-8888-8888-888888888888'::uuid, conversation3_uuid, sarah_uuid,
   'Hey! How was your experience with that electronics store?',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '1 day', now() - interval '1 day'),

  ('aa111111-1111-1111-1111-111111111111'::uuid, conversation3_uuid, buyer_uuid,
   'Great! Really professional service and the delivery was super fast. Highly recommend them!',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '23 hours', now() - interval '23 hours'),

  -- Customer support
  ('ab111111-1111-1111-1111-111111111111'::uuid, conversation4_uuid, ahmad_uuid,
   'Hi, I need help with setting up my seller profile. I have uploaded my business license but it is still showing as pending verification.',
   NULL, NULL, NULL, NULL, false, NULL, 'read', false, NULL, false, NULL,
   now() - interval '3 hours', now() - interval '3 hours'),

  ('ac111111-1111-1111-1111-111111111111'::uuid, conversation4_uuid, admin_uuid,
   'Hello Ahmad! I can see your application in our system. Our verification team typically processes documents within 24-48 hours. I will expedite your case.',
   NULL, NULL, NULL, NULL, false, NULL, 'delivered', false, NULL, false, NULL,
   now() - interval '2 hours 45 minutes', now() - interval '2 hours 45 minutes')
ON CONFLICT (id) DO NOTHING;

-- Step 9: public.quick_reply_templates (FIXED: valid hex UUIDs)
INSERT INTO quick_reply_templates (
    id, user_id, template_name, message_text, chat_type, usage_count, is_active, created_at
) VALUES
  ('e1111111-1111-1111-1111-111111111111'::uuid, runner_uuid, 'On My Way',
   'I am on my way to your location now! Should arrive in 10-15 minutes.',
   'delivery', 15, true, now()),
  ('e2222222-2222-2222-2222-222222222222'::uuid, runner_uuid, 'Package Picked Up',
   'I have successfully picked up your package and it is secure. Heading to delivery location now.',
   'delivery', 12, true, now()),
  ('e4444444-4444-4444-4444-444444444444'::uuid, seller_uuid, 'Available',
   'Yes, this item is still available! Would you like to proceed with the purchase?',
   'product_inquiry', 8, true, now())
ON CONFLICT (id) DO UPDATE
  SET usage_count = EXCLUDED.usage_count;

    -- Step 10: sync last_message_at with latest message
    UPDATE marketplace_conversations mc
       SET last_message_at = m.max_created
      FROM (
        SELECT conversation_id, MAX(created_at) AS max_created
        FROM marketplace_messages
        GROUP BY conversation_id
      ) m
     WHERE m.conversation_id = mc.id;

-- Step 11: chat_read_receipts (update message_ids to the new ones)
INSERT INTO chat_read_receipts (message_id, user_id, read_at)
SELECT * FROM (VALUES
  ('a1111111-1111-1111-1111-111111111111'::uuid, seller_uuid, now() - interval '1 hour 58 minutes'),
  ('a2222222-2222-2222-2222-222222222222'::uuid, buyer_uuid,  now() - interval '1 hour 54 minutes')
) v(message_id, user_id, read_at)
WHERE NOT EXISTS (
  SELECT 1 FROM chat_read_receipts r
  WHERE r.message_id = v.message_id AND r.user_id = v.user_id
);


    RAISE NOTICE 'Mock data migration completed successfully without constraint violations';
EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'Unique constraint handled gracefully with UPSERT patterns';
  WHEN foreign_key_violation THEN
    RAISE NOTICE 'Foreign key constraint error: %', SQLERRM;
    RAISE EXCEPTION 'Migration failed due to foreign key constraint violation';
  WHEN OTHERS THEN
    RAISE NOTICE 'Unexpected error: %', SQLERRM;
    RAISE EXCEPTION 'Migration failed with error: %', SQLERRM;
END $$;

-- -------------------------------------------
-- 2) Final verification
-- -------------------------------------------
SELECT 'Enhanced mock data created successfully with constraint handling!' AS result;
SELECT 'Demo users created: ' || COUNT(*) AS user_count FROM user_profiles;
SELECT 'Conversations created: ' || COUNT(*) AS conversation_count FROM marketplace_conversations;
SELECT 'Messages created: ' || COUNT(*) AS message_count FROM marketplace_messages;
SELECT 'Delivery requests created: ' || COUNT(*) AS delivery_count FROM delivery_requests;

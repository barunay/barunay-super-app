-- Enhanced Marketplace Mock Data Migration
-- This migration creates comprehensive test data for the marketplace application

-- Clean up existing test data first
DELETE FROM marketplace_messages;
DELETE FROM marketplace_conversations;
DELETE FROM delivery_requests;
DELETE FROM runner_profiles;
DELETE FROM seller_profiles;
DELETE FROM user_sub_profiles;
DELETE FROM user_profiles WHERE email IN (
    'buyer@marketplace.com', 
    'seller@marketplace.com', 
    'runner@marketplace.com', 
    'admin@marketplace.com',
    'sarah.lim@email.com',
    'ahmad.hassan@email.com',
    'maria.santos@email.com',
    'david.wong@email.com',
    'fatimah.ali@email.com'
);

-- Insert demo users with predefined UUIDs for consistency
INSERT INTO user_profiles (
    id, 
    email, 
    full_name, 
    role, 
    phone, 
    avatar_url,
    profile_status,
    created_at
) VALUES 
-- Demo Login Users (matching login screen credentials)
(
    '11111111-1111-1111-1111-111111111111'::uuid, 
    'buyer@marketplace.com', 
    'Demo Buyer', 
    'buyer'::user_role, 
    '+673 234 5678', 
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),
(
    '22222222-2222-2222-2222-222222222222'::uuid, 
    'seller@marketplace.com', 
    'Demo Seller', 
    'seller'::user_role, 
    '+673 345 6789', 
    'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),
(
    '33333333-3333-3333-3333-333333333333'::uuid, 
    'runner@marketplace.com', 
    'Demo Runner', 
    'runner'::user_role, 
    '+673 456 7890', 
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),
(
    '44444444-4444-4444-4444-444444444444'::uuid, 
    'admin@marketplace.com', 
    'Demo Admin', 
    'admin'::user_role, 
    '+673 567 8901', 
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),

-- Additional realistic users
(
    '55555555-5555-5555-5555-555555555555'::uuid, 
    'sarah.lim@email.com', 
    'Sarah Lim', 
    'buyer'::user_role, 
    '+673 712 3456', 
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),
(
    '66666666-6666-6666-6666-666666666666'::uuid, 
    'ahmad.hassan@email.com', 
    'Ahmad Hassan', 
    'seller'::user_role, 
    '+673 823 4567', 
    'https://images.unsplash.com/photo-1507591064344-4c6ce005b128?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),
(
    '77777777-7777-7777-7777-777777777777'::uuid, 
    'maria.santos@email.com', 
    'Maria Santos', 
    'runner'::user_role, 
    '+673 934 5678', 
    'https://images.unsplash.com/photo-1607746882042-944635dfe10e?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),
(
    '88888888-8888-8888-8888-888888888888'::uuid, 
    'david.wong@email.com', 
    'David Wong', 
    'buyer'::user_role, 
    '+673 145 6789', 
    'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
),
(
    '99999999-9999-9999-9999-999999999999'::uuid, 
    'fatimah.ali@email.com', 
    'Fatimah Ali', 
    'seller'::user_role, 
    '+673 256 7890', 
    'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
    'active'::profile_status,
    NOW()
);

-- Create user sub profiles for sellers and runners
INSERT INTO user_sub_profiles (
    id,
    user_id, 
    profile_type, 
    display_name, 
    profile_data,
    is_active
) VALUES 
-- Demo Seller Sub Profile
(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid, 
    'seller'::profile_type, 
    'Demo Electronics Store', 
    '{"business_category": "Electronics", "years_in_business": 3}'::jsonb,
    true
),
-- Demo Runner Sub Profile
(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid, 
    'runner'::profile_type, 
    'Swift Delivery', 
    '{"vehicle_info": "Motorcycle", "delivery_range": "Brunei-Muara"}'::jsonb,
    true
),
-- Ahmad Hassan Seller Sub Profile
(
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid, 
    'seller'::profile_type, 
    'Ahmad Gadget Corner', 
    '{"business_category": "Mobile Accessories", "years_in_business": 2}'::jsonb,
    true
),
-- Maria Runner Sub Profile
(
    'dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid,
    '77777777-7777-7777-7777-777777777777'::uuid, 
    'runner'::profile_type, 
    'Maria Express', 
    '{"vehicle_info": "Car", "delivery_range": "All Districts"}'::jsonb,
    true
),
-- Fatimah Seller Sub Profile
(
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid,
    '99999999-9999-9999-9999-999999999999'::uuid, 
    'seller'::profile_type, 
    'Fatimah Fashion Boutique', 
    '{"business_category": "Fashion", "years_in_business": 5}'::jsonb,
    true
);

-- Create seller profiles
INSERT INTO seller_profiles (
    id,
    user_profile_id,
    business_name,
    business_description,
    business_address,
    verification_status,
    is_verified,
    shop_settings,
    bank_account_details,
    tax_number
) VALUES 
(
    'f1111111-1111-1111-1111-111111111111'::uuid,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    'Demo Electronics Store',
    'Your one-stop shop for the latest gadgets and electronics',
    'Ground Floor, The Mall, Gadong',
    'verified'::verification_status,
    true,
    '{"store_hours": "9 AM - 10 PM", "delivery_available": true}'::jsonb,
    '{"bank": "BIBD", "account": "1234567890"}'::jsonb,
    'BN-TAX-123456'
),
(
    'f2222222-2222-2222-2222-222222222222'::uuid,
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    'Ahmad Gadget Corner',
    'Premium mobile accessories and tech solutions',
    'Unit 12, Yayasan Complex, Bandar Seri Begawan',
    'verified'::verification_status,
    true,
    '{"store_hours": "10 AM - 9 PM", "delivery_available": true}'::jsonb,
    '{"bank": "Baiduri", "account": "9876543210"}'::jsonb,
    'BN-TAX-654321'
),
(
    'f3333333-3333-3333-3333-333333333333'::uuid,
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid,
    'Fatimah Fashion Boutique',
    'Trendy fashion for the modern Bruneian woman',
    'Simpang 88, Jalan Tutong, Kampong Kilanas',
    'verified'::verification_status,
    true,
    '{"store_hours": "10 AM - 8 PM", "delivery_available": true}'::jsonb,
    '{"bank": "Standard Chartered", "account": "5555666677"}'::jsonb,
    'BN-TAX-789123'
);

-- Create runner profiles
INSERT INTO runner_profiles (
    id,
    user_profile_id,
    vehicle_type,
    license_number,
    verification_status,
    is_verified,
    is_available,
    background_check_status,
    safety_training_completed,
    availability_preferences,
    banking_details
) VALUES 
(
    'r1111111-1111-1111-1111-111111111111'::uuid,
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
    'Motorcycle',
    'DL-123456789',
    'verified'::verification_status,
    true,
    true,
    'approved',
    true,
    '{"working_hours": "8 AM - 10 PM", "districts": ["Brunei-Muara", "Tutong"]}'::jsonb,
    '{"bank": "BIBD", "account": "1111222233"}'::jsonb
),
(
    'r2222222-2222-2222-2222-222222222222'::uuid,
    'dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid,
    'Car',
    'DL-987654321',
    'verified'::verification_status,
    true,
    true,
    'approved',
    true,
    '{"working_hours": "7 AM - 11 PM", "districts": ["Brunei-Muara", "Tutong", "Belait", "Temburong"]}'::jsonb,
    '{"bank": "Baiduri", "account": "4444555566"}'::jsonb
);

-- Create delivery requests
INSERT INTO delivery_requests (
    id,
    title,
    description,
    user_id,
    pickup_address,
    delivery_address,
    recipient_name,
    recipient_phone,
    package_size,
    package_weight,
    package_value,
    max_budget,
    status,
    urgency,
    special_instructions,
    scheduled_pickup_time,
    estimated_distance,
    pickup_latitude,
    pickup_longitude,
    delivery_latitude,
    delivery_longitude
) VALUES 
(
    'd1111111-1111-1111-1111-111111111111'::uuid,
    'iPhone 15 Pro Max Delivery',
    'Brand new iPhone 15 Pro Max in original packaging. Handle with extreme care.',
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Demo Electronics Store, The Mall, Gadong',
    'Block 123, Simpang 456, Kampong Perpindahan Mata-Mata',
    'Ahmad Rahman',
    '+673 712 8888',
    'small',
    1.5,
    2500.00,
    35.00,
    'awaiting_runner'::delivery_status,
    'high'::urgency_level,
    'Please call upon arrival. Customer will be waiting at ground floor.',
    NOW() + INTERVAL '2 hours',
    8.5,
    4.9031,
    114.9398,
    4.9123,
    114.9567
),
(
    'd2222222-2222-2222-2222-222222222222'::uuid,
    'Birthday Cake Special Delivery',
    'Custom chocolate birthday cake for 8-year-old. Time sensitive delivery.',
    '55555555-5555-5555-5555-555555555555'::uuid,
    'Le Apple Patisserie, Times Square, Bandar Seri Begawan',
    'House 789, Kampong Rimba, Tutong District',
    'Siti Aminah',
    '+673 823 9999',
    'medium',
    2.5,
    85.00,
    20.00,
    'awaiting_runner'::delivery_status,
    'urgent'::urgency_level,
    'Birthday party starts at 7 PM. Please deliver before 6:30 PM. Keep cake upright.',
    NOW() + INTERVAL '4 hours',
    25.3,
    4.8903,
    114.9421,
    4.7651,
    114.6513
),
(
    'd3333333-3333-3333-3333-333333333333'::uuid,
    'Medical Supplies Urgent',
    'Prescription medicine for elderly patient. Contains temperature-sensitive items.',
    '88888888-8888-8888-8888-888888888888'::uuid,
    'Pharmavita Pharmacy, Kiulap Plaza',
    'Apartment 567, Block C, Mata-Mata Housing Estate',
    'Hajah Mariam',
    '+673 934 7777',
    'small',
    0.5,
    120.00,
    15.00,
    'runner_assigned'::delivery_status,
    'urgent'::urgency_level,
    'Patient is waiting. Please handle with care and deliver immediately.',
    NOW() + INTERVAL '30 minutes',
    6.2,
    4.9145,
    114.9287,
    4.9234,
    114.9456
),
(
    'd4444444-4444-4444-4444-444444444444'::uuid,
    'Laptop Repair Return',
    'Dell Inspiron laptop after repair. Contains all original accessories.',
    '22222222-2222-2222-2222-222222222222'::uuid,
    'TechRepair Hub, Ground Floor, Abdul Razak Complex',
    'Office Tower, Level 15, Unit 1501, CBD Bandar',
    'Mr. James Lim',
    '+673 145 5555',
    'medium',
    3.2,
    1800.00,
    25.00,
    'pending'::delivery_status,
    'medium'::urgency_level,
    'Office hours: 9 AM to 5 PM. Contact recipient before delivery.',
    NOW() + INTERVAL '1 day',
    4.8,
    4.8876,
    114.9334,
    4.8945,
    114.9412
);

-- Assign runners to some delivery requests
UPDATE delivery_requests 
SET assigned_runner_id = 'r1111111-1111-1111-1111-111111111111'::uuid,
    status = 'runner_assigned'::delivery_status
WHERE id = 'd3333333-3333-3333-3333-333333333333'::uuid;

-- Create marketplace conversations
INSERT INTO marketplace_conversations (
    id,
    participant_one_id,
    participant_two_id,
    chat_type,
    delivery_request_id,
    product_id,
    is_archived,
    is_blocked,
    last_message_at
) VALUES 
-- Conversation between buyer and seller about iPhone
(
    'c1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Demo Buyer
    '22222222-2222-2222-2222-222222222222'::uuid, -- Demo Seller
    'product_inquiry'::chat_type,
    NULL,
    'd1111111-1111-1111-1111-111111111111'::uuid, -- iPhone delivery as product context
    false,
    false,
    NOW() - INTERVAL '2 hours'
),
-- Conversation between buyer and runner about delivery
(
    'c2222222-2222-2222-2222-222222222222'::uuid,
    '88888888-8888-8888-8888-888888888888'::uuid, -- David Wong (buyer)
    '33333333-3333-3333-3333-333333333333'::uuid, -- Demo Runner
    'delivery'::chat_type,
    'd3333333-3333-3333-3333-333333333333'::uuid, -- Medical supplies delivery
    NULL,
    false,
    false,
    NOW() - INTERVAL '15 minutes'
),
-- General conversation between buyers
(
    'c3333333-3333-3333-3333-333333333333'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid, -- Sarah Lim
    '11111111-1111-1111-1111-111111111111'::uuid, -- Demo Buyer
    'general'::chat_type,
    NULL,
    NULL,
    false,
    false,
    NOW() - INTERVAL '1 day'
),
-- Customer support conversation
(
    'c4444444-4444-4444-4444-444444444444'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid, -- Ahmad Hassan (seller)
    '44444444-4444-4444-4444-444444444444'::uuid, -- Demo Admin
    'customer_support'::chat_type,
    NULL,
    NULL,
    false,
    false,
    NOW() - INTERVAL '3 hours'
);

-- Create marketplace messages
INSERT INTO marketplace_messages (
    id,
    conversation_id,
    sender_id,
    message_text,
    media_type,
    media_url,
    status,
    is_quick_reply,
    reply_to_message_id,
    created_at
) VALUES 
-- Messages for iPhone conversation
(
    'm1111111-1111-1111-1111-111111111111'::uuid,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Demo Buyer
    'Hi! I am interested in the iPhone 15 Pro Max. Is it still available?',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '2 hours'
),
(
    'm2222222-2222-2222-2222-222222222222'::uuid,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid, -- Demo Seller
    'Yes, it is available! Brand new in box with full warranty. Would you like to see more photos?',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '2 hours' + INTERVAL '5 minutes'
),
(
    'm3333333-3333-3333-3333-333333333333'::uuid,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Demo Buyer
    'That would be great! Also, do you offer delivery service?',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '2 hours' + INTERVAL '8 minutes'
),
(
    'm4444444-4444-4444-4444-444444444444'::uuid,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid, -- Demo Seller
    'Absolutely! We partner with local runners for same-day delivery. The phone is $2,500. Delivery would be around $25-35 depending on location.',
    'image'::media_type,
    'https://images.unsplash.com/photo-1592286380408-78b1b4be76e2?w=400&h=300&fit=crop',
    'delivered'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '2 hours' + INTERVAL '12 minutes'
),

-- Messages for delivery tracking conversation
(
    'm5555555-5555-5555-5555-555555555555'::uuid,
    'c2222222-2222-2222-2222-222222222222'::uuid,
    '88888888-8888-8888-8888-888888888888'::uuid, -- David Wong
    'Hi, I am the customer for the medical delivery. When will you be arriving?',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '15 minutes'
),
(
    'm6666666-6666-6666-6666-666666666666'::uuid,
    'c2222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid, -- Demo Runner
    'Hello! I just picked up your medicine from Pharmavita. I should be at your location in about 10 minutes.',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '12 minutes'
),
(
    'm7777777-7777-7777-7777-777777777777'::uuid,
    'c2222222-2222-2222-2222-222222222222'::uuid,
    '88888888-8888-8888-8888-888888888888'::uuid, -- David Wong
    'Perfect! I will be waiting at the main entrance. Thank you!',
    NULL,
    NULL,
    'delivered'::message_status,
    true,
    NULL,
    NOW() - INTERVAL '10 minutes'
),
(
    'm8888888-8888-8888-8888-888888888888'::uuid,
    'c2222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid, -- Demo Runner
    'I am here at the main entrance now. I can see the building directory.',
    'location'::media_type,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '2 minutes'
),

-- Messages for general conversation
(
    'm9999999-9999-9999-9999-999999999999'::uuid,
    'c3333333-3333-3333-3333-333333333333'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid, -- Sarah Lim
    'Hey! How was your experience with that electronics store?',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '1 day'
),
(
    'ma111111-a111-a111-a111-a11111111111'::uuid,
    'c3333333-3333-3333-3333-333333333333'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Demo Buyer
    'Great! Really professional service and the delivery was super fast. Highly recommend them!',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '23 hours'
),

-- Messages for customer support
(
    'mb111111-b111-b111-b111-b11111111111'::uuid,
    'c4444444-4444-4444-4444-444444444444'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid, -- Ahmad Hassan
    'Hi, I need help with setting up my seller profile. I have uploaded my business license but it is still showing as pending verification.',
    NULL,
    NULL,
    'read'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '3 hours'
),
(
    'mc111111-c111-c111-c111-c11111111111'::uuid,
    'c4444444-4444-4444-4444-444444444444'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid, -- Demo Admin
    'Hello Ahmad! I can see your application in our system. Our verification team typically processes documents within 24-48 hours. I will expedite your case.',
    NULL,
    NULL,
    'delivered'::message_status,
    false,
    NULL,
    NOW() - INTERVAL '2 hours' + INTERVAL '45 minutes'
),
(
    'md111111-d111-d111-d111-d11111111111'::uuid,
    'c4444444-4444-4444-4444-444444444444'::uuid,
    '66666666-6666-6666-6666-666666666666'::uuid, -- Ahmad Hassan
    'That would be wonderful! Thank you so much for the quick response.',
    NULL,
    NULL,
    'sent'::message_status,
    true,
    NULL,
    NOW() - INTERVAL '2 hours' + INTERVAL '30 minutes'
);

-- Create some quick reply templates
INSERT INTO quick_reply_templates (
    id,
    user_id,
    template_name,
    message_text,
    chat_type,
    usage_count,
    is_active
) VALUES 
-- Demo Runner quick replies
(
    'q1111111-1111-1111-1111-111111111111'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid, -- Demo Runner
    'On My Way',
    'I am on my way to your location now! Should arrive in 10-15 minutes.',
    'delivery'::chat_type,
    15,
    true
),
(
    'q2222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid, -- Demo Runner
    'Package Picked Up',
    'I have successfully picked up your package and it is secure. Heading to delivery location now.',
    'delivery'::chat_type,
    12,
    true
),
(
    'q3333333-3333-3333-3333-333333333333'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid, -- Demo Runner
    'Arrived',
    'I have arrived at the delivery location. Please let me know where to meet you.',
    'delivery'::chat_type,
    20,
    true
),

-- Demo Seller quick replies
(
    'q4444444-4444-4444-4444-444444444444'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid, -- Demo Seller
    'Available',
    'Yes, this item is still available! Would you like to proceed with the purchase?',
    'product_inquiry'::chat_type,
    8,
    true
),
(
    'q5555555-5555-5555-5555-555555555555'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid, -- Demo Seller
    'Delivery Info',
    'We offer same-day delivery through our partner runners. Delivery fee depends on your location.',
    'product_inquiry'::chat_type,
    6,
    true
),
(
    'q6666666-6666-6666-6666-666666666666'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid, -- Demo Seller
    'Thanks for Interest',
    'Thank you for your interest! Feel free to ask if you have any questions.',
    'general'::chat_type,
    10,
    true
);

-- Update conversation timestamps to match latest messages
UPDATE marketplace_conversations 
SET last_message_at = (
    SELECT MAX(created_at) 
    FROM marketplace_messages 
    WHERE marketplace_messages.conversation_id = marketplace_conversations.id
);

-- Insert some chat read receipts
INSERT INTO chat_read_receipts (
    message_id,
    user_id,
    read_at
) VALUES 
(
    'm1111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid, -- Demo Seller read buyer's message
    NOW() - INTERVAL '2 hours' + INTERVAL '2 minutes'
),
(
    'm2222222-2222-2222-2222-222222222222'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid, -- Demo Buyer read seller's message
    NOW() - INTERVAL '2 hours' + INTERVAL '6 minutes'
),
(
    'm5555555-5555-5555-5555-555555555555'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid, -- Demo Runner read customer's message
    NOW() - INTERVAL '14 minutes'
);

-- Add some sample product references (using delivery request IDs as product IDs for simplicity)
-- This creates the link between products and conversations
UPDATE marketplace_conversations 
SET product_id = 'd1111111-1111-1111-1111-111111111111'::uuid 
WHERE id = 'c1111111-1111-1111-1111-111111111111'::uuid;

-- Create sample notification data would go here if we had a notifications table

-- Verify the data was inserted correctly
SELECT 'Mock Data Creation Summary:' as summary;
SELECT 
    'Users Created: ' || COUNT(*) as count 
FROM user_profiles 
WHERE email LIKE '%@marketplace.com' OR email LIKE '%@email.com';

SELECT 
    'Conversations Created: ' || COUNT(*) as count 
FROM marketplace_conversations;

SELECT 
    'Messages Created: ' || COUNT(*) as count 
FROM marketplace_messages;

SELECT 
    'Delivery Requests Created: ' || COUNT(*) as count 
FROM delivery_requests;

SELECT 
    'Quick Reply Templates: ' || COUNT(*) as count 
FROM quick_reply_templates;

-- Success message
SELECT 'Enhanced mock data has been successfully created!' as result;
SELECT 'You can now use the demo credentials in the login screen:' as instruction;
SELECT 'buyer@marketplace.com / password123' as buyer_login;
SELECT 'seller@marketplace.com / password123' as seller_login;  
SELECT 'runner@marketplace.com / password123' as runner_login;
SELECT 'admin@marketplace.com / password123' as admin_login;
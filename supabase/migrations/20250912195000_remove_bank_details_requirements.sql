-- Remove bank details requirements from seller profile setup
-- Migration to make bank details completely optional and demonstrate this functionality

-- Update seller_profiles table to make bank_account_details nullable and optional
-- (Column is already nullable, just adding documentation comment)
COMMENT ON COLUMN public.seller_profiles.bank_account_details IS 
'Optional bank account details for sellers. Sellers can complete profile setup without providing bank information.';

-- Use INSERT ... ON CONFLICT to safely add demonstration data
-- This prevents duplicate key errors if migration is run multiple times
INSERT INTO public.user_profiles (
  id,
  email,
  full_name,
  phone,
  role,
  profile_status,
  created_at,
  updated_at
) VALUES (
  '44444444-4444-4444-4444-444444444444',
  'maria.arts@example.com',
  'Maria Santos',
  '+673 888 1234',
  'seller'::user_role,
  'active'::profile_status,
  '2025-09-12 19:50:00.000000+00'::timestamptz,
  '2025-09-12 19:50:00.000000+00'::timestamptz
) ON CONFLICT (id) DO NOTHING;

-- Insert user_sub_profile with conflict handling on primary key
INSERT INTO public.user_sub_profiles (
  id,
  user_id,
  profile_type,
  display_name,
  profile_data,
  is_active,
  created_at,
  updated_at
) VALUES (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  '44444444-4444-4444-4444-444444444444',
  'seller'::profile_type,
  'Creative Arts Studio',
  '{"business_category": "Arts & Crafts", "verification_documents_uploaded": false, "bank_details_provided": false}'::jsonb,
  true,
  '2025-09-12 19:50:00.000000+00'::timestamptz,
  '2025-09-12 19:50:00.000000+00'::timestamptz
) ON CONFLICT (id) DO NOTHING;

-- Insert seller_profile demonstrating optional bank details with conflict handling
INSERT INTO public.seller_profiles (
  id,
  user_profile_id,
  business_name,
  business_description,
  business_address,
  verification_status,
  is_verified,
  shop_settings,
  bank_account_details,
  created_at,
  updated_at
) VALUES (
  'f3333333-3333-3333-3333-333333333333',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'Creative Arts Studio',
  'Handmade crafts and artistic creations for your home and office',
  'Unit 8, Times Square, Brunei',
  'pending'::verification_status,
  false,
  '{"store_hours": "10 AM - 6 PM", "accepts_custom_orders": true, "shipping_available": true, "minimum_order": null}'::jsonb,
  '{}'::jsonb, -- Empty bank details to demonstrate optional nature
  '2025-09-12 19:50:00.000000+00'::timestamptz,
  '2025-09-12 19:50:00.000000+00'::timestamptz
) ON CONFLICT (id) DO NOTHING;
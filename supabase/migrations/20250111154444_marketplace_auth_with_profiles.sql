-- Location: supabase/migrations/20250111154444_marketplace_auth_with_profiles.sql
-- Schema Analysis: Fresh project with no existing schema
-- Integration Type: FRESH_PROJECT - Complete authentication and marketplace schema
-- Dependencies: None (new schema)

-- 1. TYPES - Create custom enums for marketplace functionality
CREATE TYPE public.user_role AS ENUM ('buyer', 'seller', 'runner', 'admin');
CREATE TYPE public.profile_status AS ENUM ('active', 'inactive', 'suspended', 'pending');
CREATE TYPE public.verification_status AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE public.profile_type AS ENUM ('shopper', 'seller', 'runner');

-- 2. CORE TABLES - Start with user profiles as intermediary table
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT,
    role public.user_role DEFAULT 'buyer'::public.user_role,
    profile_status public.profile_status DEFAULT 'active'::public.profile_status,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. MULTI-PROFILE SYSTEM - Supporting user's requirement for sub-profiles
CREATE TABLE public.user_sub_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    profile_type public.profile_type NOT NULL,
    display_name TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    profile_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, profile_type)
);

-- 4. SELLER PROFILES - Business information for sellers
CREATE TABLE public.seller_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id UUID REFERENCES public.user_sub_profiles(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    business_description TEXT,
    business_address TEXT,
    verification_status public.verification_status DEFAULT 'pending'::public.verification_status,
    business_license_url TEXT,
    tax_number TEXT,
    bank_account_details JSONB DEFAULT '{}'::jsonb,
    shop_settings JSONB DEFAULT '{}'::jsonb,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. RUNNER PROFILES - Delivery runner information  
CREATE TABLE public.runner_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_profile_id UUID REFERENCES public.user_sub_profiles(id) ON DELETE CASCADE,
    vehicle_type TEXT,
    license_number TEXT,
    verification_status public.verification_status DEFAULT 'pending'::public.verification_status,
    license_document_url TEXT,
    vehicle_registration_url TEXT,
    background_check_status TEXT DEFAULT 'pending',
    availability_preferences JSONB DEFAULT '{}'::jsonb,
    banking_details JSONB DEFAULT '{}'::jsonb,
    safety_training_completed BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. ESSENTIAL INDEXES - Performance optimization
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_user_profiles_status ON public.user_profiles(profile_status);
CREATE INDEX idx_user_sub_profiles_user_id ON public.user_sub_profiles(user_id);
CREATE INDEX idx_user_sub_profiles_type ON public.user_sub_profiles(profile_type);
CREATE INDEX idx_seller_profiles_user_id ON public.seller_profiles(user_profile_id);
CREATE INDEX idx_seller_profiles_verification ON public.seller_profiles(verification_status);
CREATE INDEX idx_runner_profiles_user_id ON public.runner_profiles(user_profile_id);
CREATE INDEX idx_runner_profiles_available ON public.runner_profiles(is_available);

-- 7. FUNCTIONS - Helper functions for triggers and RLS (BEFORE RLS POLICIES)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'buyer')::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_user_profile_update()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- 8. RLS SETUP - Enable row level security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sub_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runner_profiles ENABLE ROW LEVEL SECURITY;

-- 9. RLS POLICIES - Following Pattern 1 for core user tables, Pattern 2 for related tables

-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for sub-profiles
CREATE POLICY "users_manage_own_sub_profiles"
ON public.user_sub_profiles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for seller profiles (via sub-profiles)
CREATE POLICY "users_manage_own_seller_profiles"
ON public.seller_profiles
FOR ALL
TO authenticated
USING (
  user_profile_id IN (
    SELECT id FROM public.user_sub_profiles WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  user_profile_id IN (
    SELECT id FROM public.user_sub_profiles WHERE user_id = auth.uid()
  )
);

-- Pattern 2: Simple user ownership for runner profiles (via sub-profiles) 
CREATE POLICY "users_manage_own_runner_profiles"
ON public.runner_profiles
FOR ALL
TO authenticated
USING (
  user_profile_id IN (
    SELECT id FROM public.user_sub_profiles WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  user_profile_id IN (
    SELECT id FROM public.user_sub_profiles WHERE user_id = auth.uid()
  )
);

-- 10. TRIGGERS - Automatic profile creation and updates
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_user_profile_updated
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_profile_update();

CREATE TRIGGER on_sub_profile_updated
  BEFORE UPDATE ON public.user_sub_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_profile_update();

-- 11. MOCK DATA - Complete auth users with marketplace-specific data
DO $$
DECLARE
    buyer_uuid UUID := gen_random_uuid();
    seller_uuid UUID := gen_random_uuid();
    runner_uuid UUID := gen_random_uuid();
    mobile_uuid UUID := gen_random_uuid();
    john_uuid UUID := gen_random_uuid();
    sarah_uuid UUID := gen_random_uuid();
    ahmad_uuid UUID := gen_random_uuid();
    
    buyer_sub_profile_id UUID;
    seller_sub_profile_id UUID;
    runner_sub_profile_id UUID;
BEGIN
    -- Create auth users with complete field structure matching existing mock credentials
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        -- Existing mock credentials from login screen
        (buyer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'buyer@barunay.com', crypt('buyer123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Buyer", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        
        (seller_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'seller@barunay.com', crypt('seller123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Seller", "role": "seller"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
         
        (runner_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'runner@barunay.com', crypt('runner123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Mike Runner", "role": "runner"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
         
        (mobile_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'mobile@barunay.com', crypt('mobile123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Mobile User", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '+6738123456', '', '', null),
         
        -- Additional users based on conversation context  
        (john_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'john.doe@example.com', crypt('2234567', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Doe", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
         
        (sarah_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sarah.lim@gmail.com', crypt('8765432', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Lim", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
         
        (ahmad_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'ahmad.rahman@email.com', crypt('ahmad123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Ahmad Rahman", "role": "seller"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create sub-profiles for multi-profile functionality
    INSERT INTO public.user_sub_profiles (user_id, profile_type, display_name, profile_data)
    VALUES
        (seller_uuid, 'seller'::public.profile_type, 'Sarah Shop', '{"business_focus": "electronics"}'::jsonb),
        (runner_uuid, 'runner'::public.profile_type, 'Mike Delivery', '{"preferred_areas": ["Bandar Seri Begawan", "Tutong"]}'::jsonb),
        (ahmad_uuid, 'seller'::public.profile_type, 'Ahmad Electronics', '{"business_focus": "electronics", "verified": true}'::jsonb)
    RETURNING id, user_id, profile_type;

    -- Get sub-profile IDs for seller and runner profiles
    SELECT id INTO seller_sub_profile_id FROM public.user_sub_profiles 
    WHERE user_id = seller_uuid AND profile_type = 'seller'::public.profile_type;
    
    SELECT id INTO runner_sub_profile_id FROM public.user_sub_profiles 
    WHERE user_id = runner_uuid AND profile_type = 'runner'::public.profile_type;

    -- Create seller profile details
    INSERT INTO public.seller_profiles (
        user_profile_id, business_name, business_description, business_address,
        verification_status, is_verified, shop_settings
    ) VALUES
        (seller_sub_profile_id, 'Sarah Electronics Store', 
         'Quality electronics and gadgets for modern life',
         'Block 123, Spg 456, Bandar Seri Begawan',
         'verified'::public.verification_status, true,
         '{"shop_theme": "modern", "auto_accept_orders": true}'::jsonb);

    -- Create runner profile details  
    INSERT INTO public.runner_profiles (
        user_profile_id, vehicle_type, license_number, verification_status,
        is_verified, is_available, availability_preferences, safety_training_completed
    ) VALUES
        (runner_sub_profile_id, 'Motorcycle', 'KB123456',
         'verified'::public.verification_status, true, true,
         '{"working_hours": "9am-9pm", "max_distance": 20}'::jsonb, true);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 12. CLEANUP FUNCTION - For testing purposes
CREATE OR REPLACE FUNCTION public.cleanup_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs first
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@barunay.com' OR email LIKE '%@example.com' OR email LIKE '%@gmail.com' OR email LIKE '%@email.com';

    -- Delete in dependency order (children first, then auth.users last)
    DELETE FROM public.runner_profiles WHERE user_profile_id IN (
        SELECT id FROM public.user_sub_profiles WHERE user_id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.seller_profiles WHERE user_profile_id IN (
        SELECT id FROM public.user_sub_profiles WHERE user_id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.user_sub_profiles WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);

    -- Delete auth.users last (after all references are removed)
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;
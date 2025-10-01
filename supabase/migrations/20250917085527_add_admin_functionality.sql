-- Location: supabase/migrations/20250917085527_add_admin_functionality.sql
-- Schema Analysis: Existing user_profiles table with role enum already supports 'admin'
-- Integration Type: Extension - Adding admin functionality support
-- Dependencies: user_profiles, user_role enum

-- Check if admin role already exists in user_role enum, if not add it
DO $$
BEGIN
    -- Check if 'admin' value exists in user_role enum
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumtypid = 'public.user_role'::regtype 
        AND enumlabel = 'admin'
    ) THEN
        -- Add 'admin' to existing user_role enum
        ALTER TYPE public.user_role ADD VALUE 'admin';
    END IF;
END $$;

-- Add is_admin column for quick admin checks (denormalized for performance)
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- Add index for admin queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_admin ON public.user_profiles(is_admin) WHERE is_admin = true;

-- Create function to check admin status from auth metadata (recommended approach)
CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' = 'admin' 
         OR au.raw_app_meta_data->>'role' = 'admin'
         OR EXISTS (
             SELECT 1 FROM public.user_profiles up 
             WHERE up.id = au.id 
             AND (up.role = 'admin' OR up.is_admin = true)
         ))
)
$$;

-- Create function to safely update admin status
CREATE OR REPLACE FUNCTION public.update_admin_status(user_uuid UUID, is_admin_status BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only allow existing admins to modify admin status
    IF NOT public.is_admin_from_auth() THEN
        RAISE EXCEPTION 'Access denied: Admin privileges required';
    END IF;
    
    -- Update both role and is_admin fields
    UPDATE public.user_profiles 
    SET 
        role = CASE WHEN is_admin_status THEN 'admin'::public.user_role ELSE 'buyer'::public.user_role END,
        is_admin = is_admin_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;
    
    -- Also update auth metadata for consistency
    UPDATE auth.users 
    SET 
        raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || 
            jsonb_build_object('role', CASE WHEN is_admin_status THEN 'admin' ELSE 'buyer' END),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;
END $$;

-- Add admin policies for seller_profiles (admins can manage all seller profiles)
CREATE POLICY "admin_full_access_seller_profiles"
ON public.seller_profiles
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- Add admin policies for products (admins can manage all products)  
CREATE POLICY "admin_full_access_products"
ON public.products
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- Create function to get document verification status from actual data
CREATE OR REPLACE FUNCTION public.get_seller_document_status(seller_profile_uuid UUID)
RETURNS TABLE(
    document_name TEXT,
    document_description TEXT,
    document_status TEXT,
    document_icon TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    profile_record RECORD;
BEGIN
    -- Get seller profile data
    SELECT sp.*, usp.profile_data 
    INTO profile_record
    FROM public.seller_profiles sp
    JOIN public.user_sub_profiles usp ON sp.user_profile_id = usp.id
    WHERE sp.id = seller_profile_uuid;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Seller profile not found';
    END IF;
    
    -- Return document status based on actual database fields
    RETURN QUERY
    SELECT 
        'Business License'::TEXT,
        'Business registration and license documents'::TEXT,
        CASE 
            WHEN profile_record.business_license_url IS NOT NULL THEN 'verified'
            ELSE 'not_uploaded'
        END::TEXT,
        'business'::TEXT
    UNION ALL
    SELECT 
        'Tax Registration'::TEXT,
        'Valid tax registration number'::TEXT,
        CASE 
            WHEN profile_record.tax_number IS NOT NULL AND profile_record.tax_number != '' THEN 'verified'
            ELSE 'not_uploaded'
        END::TEXT,
        'receipt_long'::TEXT
    UNION ALL
    SELECT 
        'Bank Details'::TEXT,
        'Bank account information for payments'::TEXT,
        CASE 
            WHEN profile_record.bank_account_details IS NOT NULL 
                 AND jsonb_typeof(profile_record.bank_account_details) = 'object'
                 AND profile_record.bank_account_details != '{}'::jsonb THEN 'verified'
            ELSE 'not_uploaded'
        END::TEXT,
        'account_balance'::TEXT
    UNION ALL
    SELECT 
        'Identity Verification'::TEXT,
        'Personal identification documents'::TEXT,
        CASE 
            WHEN profile_record.verification_status = 'verified' THEN 'verified'
            WHEN profile_record.verification_status = 'rejected' THEN 'rejected' 
            ELSE 'not_uploaded'
        END::TEXT,
        'badge'::TEXT;
END $$;

-- Update existing admin user in mock data to have proper admin flags
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Find existing admin users by email pattern or role
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email LIKE '%admin%' OR raw_user_meta_data->>'role' = 'admin'
    LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- Update user_profiles to have admin flags
        UPDATE public.user_profiles 
        SET 
            role = 'admin'::public.user_role,
            is_admin = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = admin_user_id;
        
        -- Update auth.users metadata
        UPDATE auth.users 
        SET 
            raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb,
            raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = admin_user_id;
    END IF;
END $$;

-- Create cleanup function for admin functionality
CREATE OR REPLACE FUNCTION public.cleanup_admin_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Reset all admin flags for testing
    UPDATE public.user_profiles SET is_admin = false, role = 'buyer'::public.user_role;
    
    -- Clean auth metadata
    UPDATE auth.users SET 
        raw_user_meta_data = raw_user_meta_data - 'role',
        raw_app_meta_data = raw_app_meta_data - 'role'
    WHERE raw_user_meta_data->>'role' = 'admin' OR raw_app_meta_data->>'role' = 'admin';
    
    RAISE NOTICE 'Admin test data cleaned up successfully';
END $$;
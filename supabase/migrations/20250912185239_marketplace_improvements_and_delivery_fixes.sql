-- Location: supabase/migrations/20250912185239_marketplace_improvements_and_delivery_fixes.sql
-- Schema Analysis: Existing marketplace and delivery schema with missing columns
-- Integration Type: MODIFICATIVE - Adding missing columns and new enum value
-- Dependencies: products, runner_profiles, seller_profiles tables

-- Add missing rating_average column to runner_profiles (fixes delivery screen error)
ALTER TABLE public.runner_profiles 
ADD COLUMN rating_average NUMERIC(3,2) DEFAULT 0.0;

-- Add index for rating queries
CREATE INDEX idx_runner_profiles_rating_average ON public.runner_profiles(rating_average);

-- Add total_deliveries column for rating context
ALTER TABLE public.runner_profiles 
ADD COLUMN total_deliveries INTEGER DEFAULT 0;

-- Add current location columns for real-time tracking
ALTER TABLE public.runner_profiles 
ADD COLUMN current_latitude NUMERIC DEFAULT NULL,
ADD COLUMN current_longitude NUMERIC DEFAULT NULL;

-- Create new enum type for listing status
CREATE TYPE public.listing_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');

-- Add listing_status column to products table for admin approval
ALTER TABLE public.products 
ADD COLUMN listing_status public.listing_status DEFAULT 'pending'::public.listing_status;

-- Add index for listing status filtering
CREATE INDEX idx_products_listing_status ON public.products(listing_status);

-- Update existing RLS policy to include listing status check for public access
DROP POLICY IF EXISTS "public_read_active_products" ON public.products;
CREATE POLICY "public_read_active_products" 
ON public.products 
FOR SELECT 
TO public 
USING (status = 'active'::product_status AND listing_status = 'approved'::public.listing_status);

-- Create function to update runner rating
CREATE OR REPLACE FUNCTION public.update_runner_rating(runner_profile_id UUID, new_rating INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_total INTEGER;
    current_average NUMERIC;
BEGIN
    -- Get current stats
    SELECT total_deliveries, rating_average 
    INTO current_total, current_average 
    FROM public.runner_profiles 
    WHERE id = runner_profile_id;
    
    -- Update total deliveries
    UPDATE public.runner_profiles 
    SET total_deliveries = current_total + 1,
        rating_average = ROUND(
            ((current_average * current_total) + new_rating) / (current_total + 1), 
            2
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = runner_profile_id;
END;
$$;

-- Create function to check seller profile exists
CREATE OR REPLACE FUNCTION public.user_has_seller_profile()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.seller_profiles sp
    JOIN public.user_sub_profiles usp ON sp.user_profile_id = usp.id
    WHERE usp.user_id = auth.uid() 
    AND sp.is_verified = true
)
$$;

-- Update existing mock data to include new columns
DO $$
DECLARE
    runner_id UUID;
BEGIN
    -- Update existing runner profiles with rating data
    FOR runner_id IN (SELECT id FROM public.runner_profiles) LOOP
        UPDATE public.runner_profiles 
        SET 
            rating_average = 4.0 + (RANDOM() * 1.0), -- Rating between 4.0-5.0
            total_deliveries = FLOOR(RANDOM() * 50) + 10, -- 10-60 deliveries
            current_latitude = 4.9 + (RANDOM() * 0.1), -- Brunei area
            current_longitude = 114.9 + (RANDOM() * 0.1)
        WHERE id = runner_id;
    END LOOP;

    -- Update existing products to approved status (simulate admin approval)
    UPDATE public.products 
    SET listing_status = 'approved'::public.listing_status
    WHERE id IN (
        SELECT id FROM public.products 
        ORDER BY created_at DESC 
        LIMIT 10
    );

    -- Set a few products as pending for demo
    UPDATE public.products 
    SET listing_status = 'pending'::public.listing_status
    WHERE id NOT IN (
        SELECT id FROM public.products 
        WHERE listing_status = 'approved'::public.listing_status
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data update failed: %', SQLERRM;
END $$;
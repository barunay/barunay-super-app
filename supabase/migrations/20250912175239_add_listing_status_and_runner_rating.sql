-- Location: supabase/migrations/20250912175239_add_listing_status_and_runner_rating.sql
-- Schema Analysis: Existing marketplace schema with products, seller_profiles, runner_profiles
-- Integration Type: Column additions to support admin approval workflow and delivery rating system
-- Dependencies: products, runner_profiles, seller_profiles tables

-- 1. Create listing status enum for products
CREATE TYPE public.listing_status AS ENUM ('draft', 'under_review', 'approved', 'rejected', 'inactive');

-- 2. Add listing_status column to products table
ALTER TABLE public.products
ADD COLUMN listing_status public.listing_status DEFAULT 'under_review'::public.listing_status;

-- 3. Add missing columns to runner_profiles for delivery system
ALTER TABLE public.runner_profiles
ADD COLUMN rating_average DECIMAL(3,2) DEFAULT 0.00,
ADD COLUMN total_deliveries INTEGER DEFAULT 0,
ADD COLUMN current_latitude DECIMAL(10,8) NULL,
ADD COLUMN current_longitude DECIMAL(11,8) NULL;

-- 4. Create indexes for better query performance
CREATE INDEX idx_products_listing_status ON public.products(listing_status);
CREATE INDEX idx_runner_profiles_rating ON public.runner_profiles(rating_average);
CREATE INDEX idx_runner_profiles_location ON public.runner_profiles(current_latitude, current_longitude);

-- 5. Update existing RLS policies to include listing_status filtering
DROP POLICY IF EXISTS "public_read_active_products" ON public.products;

-- Updated public read policy to only show approved products
CREATE POLICY "public_read_approved_products"
ON public.products
FOR SELECT
TO public
USING (status = 'active'::public.product_status AND listing_status = 'approved'::public.listing_status);

-- Sellers can manage their own products regardless of listing status
-- (Policy already exists: sellers_manage_own_products)

-- 6. Create storage bucket for product images (public bucket for marketplace)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
) ON CONFLICT (id) DO NOTHING;

-- 7. RLS policies for product images storage
CREATE POLICY "anyone_can_view_product_images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- Only authenticated users can upload product images
CREATE POLICY "authenticated_users_upload_product_images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'product-images');

-- Only file owner can update/delete their product images
CREATE POLICY "owners_manage_product_images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'product-images' AND owner = auth.uid());

CREATE POLICY "owners_delete_product_images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());

-- 8. Function to calculate runner rating average
CREATE OR REPLACE FUNCTION public.update_runner_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update runner's rating average when a delivery task is completed
    UPDATE public.runner_profiles
    SET 
        rating_average = (
            SELECT COALESCE(AVG(customer_rating), 0)
            FROM public.delivery_tasks dt
            WHERE dt.runner_id = NEW.runner_id 
            AND dt.customer_rating IS NOT NULL
        ),
        total_deliveries = (
            SELECT COUNT(*)
            FROM public.delivery_tasks dt
            WHERE dt.runner_id = NEW.runner_id 
            AND dt.task_status = 'delivered'
        )
    WHERE id = NEW.runner_id;
    
    RETURN NEW;
END;
$$;

-- Trigger to update runner rating when delivery task is updated
CREATE TRIGGER update_runner_rating_trigger
    AFTER UPDATE OF customer_rating, task_status ON public.delivery_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_runner_rating();

-- 9. Update existing products to have approved status for demo data
UPDATE public.products 
SET listing_status = 'approved'::public.listing_status
WHERE status = 'active'::public.product_status;

-- 10. Update existing runner profiles with sample ratings
UPDATE public.runner_profiles
SET 
    rating_average = 4.5,
    total_deliveries = 25,
    current_latitude = CASE 
        WHEN id = 'a1111111-1111-1111-1111-111111111111' THEN 4.9031
        ELSE 4.8895
    END,
    current_longitude = CASE 
        WHEN id = 'a1111111-1111-1111-1111-111111111111' THEN 114.9398
        ELSE 114.9421
    END;
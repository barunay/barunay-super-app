-- Create dedicated storage bucket for product images (public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images', 
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
) ON CONFLICT (id) DO UPDATE SET
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

-- RLS Policy: Anyone can view product images (public access)
DROP POLICY IF EXISTS "public_can_view_product_images" ON storage.objects;
CREATE POLICY "public_can_view_product_images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- RLS Policy: Only authenticated users can upload product images
DROP POLICY IF EXISTS "authenticated_users_upload_product_images" ON storage.objects;
CREATE POLICY "authenticated_users_upload_product_images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images' 
    AND owner = auth.uid()
);

-- RLS Policy: Users can update their own product images
DROP POLICY IF EXISTS "users_update_own_product_images" ON storage.objects;
CREATE POLICY "users_update_own_product_images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid())
WITH CHECK (bucket_id = 'product-images' AND owner = auth.uid());

-- RLS Policy: Users can delete their own product images
DROP POLICY IF EXISTS "users_delete_own_product_images" ON storage.objects;
CREATE POLICY "users_delete_own_product_images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'product-images' AND owner = auth.uid());

-- Add listing_status column to products if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'products' AND column_name = 'listing_status') THEN
        
        -- Create enum type for listing status
        DO $enum$ BEGIN
            CREATE TYPE listing_status AS ENUM ('pending', 'approved', 'rejected', 'under_review');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $enum$;
        
        -- Add listing_status column
        ALTER TABLE public.products 
        ADD COLUMN listing_status public.listing_status DEFAULT 'pending'::public.listing_status;
        
        -- Add index for listing status
        CREATE INDEX IF NOT EXISTS idx_products_listing_status 
        ON public.products USING btree (listing_status);
    END IF;
END $$;
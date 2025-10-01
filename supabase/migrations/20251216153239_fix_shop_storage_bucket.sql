-- Create shop-assets storage bucket for marketplace shop customization
-- This will handle shop logos and banner images

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'shop-assets',
    'shop-assets', 
    true,  -- Public bucket since shop images need to be visible to all users
    10485760,  -- 10MB limit to accommodate both logo (2MB) and banner (5MB) requirements
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'image/gif']
) ON CONFLICT (id) DO UPDATE SET
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'image/gif'];

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "public_can_view_shop_assets" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_users_upload_shop_assets" ON storage.objects;
DROP POLICY IF EXISTS "users_update_own_shop_assets" ON storage.objects;
DROP POLICY IF EXISTS "users_delete_own_shop_assets" ON storage.objects;

-- RLS Policy: Anyone can view shop assets (public visibility for marketplace)
CREATE POLICY "public_can_view_shop_assets"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'shop-assets');

-- RLS Policy: Only authenticated users can upload shop assets
CREATE POLICY "authenticated_users_upload_shop_assets"
ON storage.objects  
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'shop-assets'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS Policy: Users can update their own shop assets
CREATE POLICY "users_update_own_shop_assets"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'shop-assets' AND owner = auth.uid())
WITH CHECK (bucket_id = 'shop-assets' AND owner = auth.uid());

-- RLS Policy: Users can delete their own shop assets
CREATE POLICY "users_delete_own_shop_assets"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'shop-assets' AND owner = auth.uid());
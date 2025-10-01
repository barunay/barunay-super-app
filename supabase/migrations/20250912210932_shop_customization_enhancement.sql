-- Location: supabase/migrations/20250912210932_shop_customization_enhancement.sql
-- Schema Analysis: Existing seller_profiles table with shop_settings JSONB column
-- Integration Type: Enhancement - Adding storage bucket for shop assets and updating mock data
-- Dependencies: seller_profiles table, existing profile-images and product-images buckets

-- Create dedicated bucket for shop assets (logos and banners)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'shop-assets',
    'shop-assets',
    true,
    10485760, -- 10MB limit for banners
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- RLS Policy: Anyone can view shop assets (public bucket)
CREATE POLICY "public_can_view_shop_assets"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'shop-assets');

-- RLS Policy: Only authenticated sellers can upload shop assets
CREATE POLICY "sellers_upload_shop_assets"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'shop-assets'
    AND auth.uid() IN (
        SELECT user_profile_id FROM public.seller_profiles
    )
);

-- RLS Policy: Only asset owner can update/delete
CREATE POLICY "sellers_manage_own_shop_assets"
ON storage.objects
FOR ALL
TO authenticated
USING (
    bucket_id = 'shop-assets' 
    AND owner = auth.uid()
)
WITH CHECK (
    bucket_id = 'shop-assets' 
    AND owner = auth.uid()
);

-- Update existing seller profiles with comprehensive shop settings including operating hours
DO $$
DECLARE
    seller_1_id UUID;
    seller_2_id UUID;
BEGIN
    -- Get existing seller profile IDs
    SELECT id INTO seller_1_id 
    FROM public.seller_profiles 
    WHERE business_name = 'Demo Electronics Store' 
    LIMIT 1;
    
    SELECT id INTO seller_2_id 
    FROM public.seller_profiles 
    WHERE business_name = 'Ahmad Gadget Corner' 
    LIMIT 1;

    -- Update seller 1 with comprehensive operating hours
    IF seller_1_id IS NOT NULL THEN
        UPDATE public.seller_profiles
        SET shop_settings = jsonb_build_object(
            'operating_hours', jsonb_build_object(
                'Monday', jsonb_build_object('start', '09:00', 'end', '22:00', 'isOpen', 'true'),
                'Tuesday', jsonb_build_object('start', '09:00', 'end', '22:00', 'isOpen', 'true'),
                'Wednesday', jsonb_build_object('start', '09:00', 'end', '22:00', 'isOpen', 'true'),
                'Thursday', jsonb_build_object('start', '09:00', 'end', '22:00', 'isOpen', 'true'),
                'Friday', jsonb_build_object('start', '09:00', 'end', '23:00', 'isOpen', 'true'),
                'Saturday', jsonb_build_object('start', '09:00', 'end', '23:00', 'isOpen', 'true'),
                'Sunday', jsonb_build_object('start', '10:00', 'end', '21:00', 'isOpen', 'true')
            ),
            'shop_logo', 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=512&h=512&fit=crop',
            'banner_image', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&h=675&fit=crop',
            'theme_color', '#2563eb',
            'description', 'Your one-stop shop for the latest gadgets and electronics in Brunei'
        )
        WHERE id = seller_1_id;
    END IF;

    -- Update seller 2 with comprehensive operating hours
    IF seller_2_id IS NOT NULL THEN
        UPDATE public.seller_profiles
        SET shop_settings = jsonb_build_object(
            'operating_hours', jsonb_build_object(
                'Monday', jsonb_build_object('start', '10:00', 'end', '21:00', 'isOpen', 'true'),
                'Tuesday', jsonb_build_object('start', '10:00', 'end', '21:00', 'isOpen', 'true'),
                'Wednesday', jsonb_build_object('start', '10:00', 'end', '21:00', 'isOpen', 'true'),
                'Thursday', jsonb_build_object('start', '10:00', 'end', '21:00', 'isOpen', 'true'),
                'Friday', jsonb_build_object('start', '09:00', 'end', '22:00', 'isOpen', 'true'),
                'Saturday', jsonb_build_object('start', '09:00', 'end', '22:00', 'isOpen', 'true'),
                'Sunday', jsonb_build_object('isOpen', 'false')
            ),
            'shop_logo', 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=512&h=512&fit=crop',
            'banner_image', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&h=675&fit=crop',
            'theme_color', '#059669',
            'description', 'Premium mobile accessories and tech solutions for modern lifestyle'
        )
        WHERE id = seller_2_id;
    END IF;
END $$;
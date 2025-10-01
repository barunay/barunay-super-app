-- Location: supabase/migrations/20250924104324_enhance_category_system_and_edit_listings.sql
-- Schema Analysis: Using existing categories table with hierarchical structure, products table with listing_status
-- Integration Type: Enhancement - Add RLS policies for categories and create product editing RPC
-- Dependencies: categories, products, user_profiles tables

-- 1. Functions (MUST BE BEFORE RLS POLICIES)

-- Function to create/update products with category slugs (for edit functionality)
CREATE OR REPLACE FUNCTION public.update_product_with_categories(
    p_product_id UUID,
    p_title TEXT,
    p_description TEXT,
    p_price NUMERIC,
    p_status TEXT DEFAULT 'active'::TEXT,
    p_category_slugs TEXT[] DEFAULT NULL
) 
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    v_category_id UUID;
    v_product_id UUID;
BEGIN
    -- Get the first category ID from slugs if provided
    IF p_category_slugs IS NOT NULL AND array_length(p_category_slugs, 1) > 0 THEN
        SELECT c.id INTO v_category_id 
        FROM public.categories c 
        WHERE c.slug = p_category_slugs[1] 
        AND c.is_active = true 
        LIMIT 1;
    END IF;

    -- Update the product and set status to under_review
    UPDATE public.products 
    SET 
        title = p_title,
        description = p_description,
        price = p_price,
        category_id = COALESCE(v_category_id, category_id),
        listing_status = 'under_review'::listing_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_product_id 
    AND seller_id = auth.uid()
    RETURNING id INTO v_product_id;

    IF v_product_id IS NULL THEN
        RAISE EXCEPTION 'Product not found or access denied';
    END IF;

    RETURN v_product_id;
END;
$func$;

-- Function for dynamic category hierarchy fetching
CREATE OR REPLACE FUNCTION public.get_category_hierarchy(p_parent_id UUID DEFAULT NULL)
RETURNS TABLE(
    id UUID,
    name TEXT,
    slug TEXT,
    icon TEXT,
    sort_order INTEGER,
    parent_id UUID,
    has_children BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $func$
    SELECT 
        c.id,
        c.name,
        c.slug,
        c.icon,
        c.sort_order,
        c.parent_id,
        EXISTS(SELECT 1 FROM public.categories cc WHERE cc.parent_id = c.id AND cc.is_active = true) as has_children
    FROM public.categories c
    WHERE c.is_active = true
    AND (
        (p_parent_id IS NULL AND c.parent_id IS NULL) OR 
        (p_parent_id IS NOT NULL AND c.parent_id = p_parent_id)
    )
    ORDER BY c.sort_order, c.name;
$func$;

-- Admin function to check role from auth metadata
CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $func$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' = 'admin' 
         OR au.raw_app_meta_data->>'role' = 'admin')
)
$func$;

-- 2. Enable RLS on categories table (if not already enabled)
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies for categories table

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "public_read_categories" ON public.categories;
DROP POLICY IF EXISTS "authenticated_manage_categories" ON public.categories;

-- Pattern 4: Public read, admin write for categories
CREATE POLICY "public_can_read_categories"
ON public.categories
FOR SELECT
TO public
USING (is_active = true);

-- Admin management policy using auth metadata
CREATE POLICY "admin_manage_categories"
ON public.categories
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- 4. Add missing categories data for testing hierarchy
DO $$
DECLARE
    electronics_id UUID;
    fashion_id UUID;
    home_id UUID;
BEGIN
    -- Get existing category IDs
    SELECT id INTO electronics_id FROM public.categories WHERE slug = 'electronics' LIMIT 1;
    SELECT id INTO fashion_id FROM public.categories WHERE slug = 'fashion' OR name ILIKE '%fashion%' LIMIT 1;
    SELECT id INTO home_id FROM public.categories WHERE slug = 'home-living' OR name ILIKE '%home%' LIMIT 1;
    
    -- Add subcategories to electronics if it exists
    IF electronics_id IS NOT NULL THEN
        INSERT INTO public.categories (name, slug, parent_id, sort_order, is_active, icon) VALUES
            ('Smartphones', 'smartphones', electronics_id, 10, true, 'smartphone'),
            ('Laptops', 'laptops', electronics_id, 20, true, 'laptop'),
            ('Tablets', 'tablets', electronics_id, 30, true, 'tablet')
        ON CONFLICT (slug) DO NOTHING;
    END IF;
    
    -- Add subcategories to fashion if it exists
    IF fashion_id IS NOT NULL THEN
        INSERT INTO public.categories (name, slug, parent_id, sort_order, is_active, icon) VALUES
            ('Men Clothing', 'men-clothing', fashion_id, 10, true, 'shirt'),
            ('Women Clothing', 'women-clothing', fashion_id, 20, true, 'dress'),
            ('Shoes', 'shoes', fashion_id, 30, true, 'shoe')
        ON CONFLICT (slug) DO NOTHING;
    END IF;
    
    -- Add subcategories to home if it exists
    IF home_id IS NOT NULL THEN
        INSERT INTO public.categories (name, slug, parent_id, sort_order, is_active, icon) VALUES
            ('Furniture', 'furniture', home_id, 10, true, 'sofa'),
            ('Appliances', 'appliances', home_id, 20, true, 'appliance'),
            ('Decor', 'decor', home_id, 30, true, 'decor')
        ON CONFLICT (slug) DO NOTHING;
    END IF;
    
    -- Add "Others" category at top level if not exists
    INSERT INTO public.categories (name, slug, parent_id, sort_order, is_active, icon) VALUES
        ('Others', 'others', NULL, 999, true, 'category')
    ON CONFLICT (slug) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error adding categories: %', SQLERRM;
END $$;
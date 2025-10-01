-- Location: supabase/migrations/20250912184500_marketplace_products_and_chat.sql
-- Schema Analysis: Existing marketplace chat system with conversations and messages
-- Integration Type: Enhancement - Adding missing product tables and enhancing existing chat
-- Dependencies: user_profiles, seller_profiles, marketplace_conversations, marketplace_messages

-- ===============================
-- PHASE 1: PRODUCT CATALOG TABLES
-- ===============================

-- Product status and condition types
CREATE TYPE public.product_status AS ENUM ('active', 'inactive', 'sold', 'reserved');
CREATE TYPE public.product_condition AS ENUM ('new', 'like_new', 'good', 'fair', 'poor');

-- Product categories table
CREATE TABLE public.product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_name TEXT,
    parent_category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Product brands table
CREATE TABLE public.product_brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    logo_url TEXT,
    description TEXT,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Main products table
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    seller_profile_id UUID REFERENCES public.seller_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
    brand_id UUID REFERENCES public.product_brands(id) ON DELETE SET NULL,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    condition public.product_condition DEFAULT 'good'::public.product_condition,
    status public.product_status DEFAULT 'active'::public.product_status,
    location_text TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_negotiable BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    tags TEXT[],
    specifications JSONB DEFAULT '{}',
    shipping_info JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Product images table
CREATE TABLE public.product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text TEXT,
    is_primary BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Product favorites table (wishlist)
CREATE TABLE public.product_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, product_id)
);

-- Product reviews table
CREATE TABLE public.product_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    reviewer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT false,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, reviewer_id)
);

-- ===============================
-- PHASE 2: INDEXES FOR PERFORMANCE
-- ===============================

CREATE INDEX idx_products_seller_id ON public.products(seller_id);
CREATE INDEX idx_products_category_id ON public.products(category_id);
CREATE INDEX idx_products_status ON public.products(status);
CREATE INDEX idx_products_price ON public.products(price);
CREATE INDEX idx_products_location ON public.products(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
CREATE INDEX idx_products_created_at ON public.products(created_at);
CREATE INDEX idx_products_featured ON public.products(is_featured, created_at) WHERE is_featured = true;

CREATE INDEX idx_product_categories_parent ON public.product_categories(parent_category_id);
CREATE INDEX idx_product_images_product_id ON public.product_images(product_id);
CREATE INDEX idx_product_favorites_user_id ON public.product_favorites(user_id);
CREATE INDEX idx_product_reviews_product_id ON public.product_reviews(product_id);

-- ===============================
-- PHASE 3: RLS POLICIES
-- ===============================

ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_reviews ENABLE ROW LEVEL SECURITY;

-- Categories: Public read, admin manage
CREATE POLICY "public_read_categories" ON public.product_categories
    FOR SELECT TO public USING (true);

CREATE POLICY "authenticated_manage_categories" ON public.product_categories
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Brands: Public read, admin manage  
CREATE POLICY "public_read_brands" ON public.product_brands
    FOR SELECT TO public USING (true);

CREATE POLICY "authenticated_manage_brands" ON public.product_brands
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Products: Public read, sellers manage their own
CREATE POLICY "public_read_active_products" ON public.products
    FOR SELECT TO public USING (status = 'active'::public.product_status);

CREATE POLICY "sellers_manage_own_products" ON public.products
    FOR ALL TO authenticated
    USING (seller_id = auth.uid())
    WITH CHECK (seller_id = auth.uid());

-- Product Images: Follow product access
CREATE POLICY "public_read_product_images" ON public.product_images
    FOR SELECT TO public USING (
        product_id IN (
            SELECT id FROM public.products 
            WHERE status = 'active'::public.product_status
        )
    );

CREATE POLICY "sellers_manage_product_images" ON public.product_images
    FOR ALL TO authenticated
    USING (
        product_id IN (
            SELECT id FROM public.products 
            WHERE seller_id = auth.uid()
        )
    )
    WITH CHECK (
        product_id IN (
            SELECT id FROM public.products 
            WHERE seller_id = auth.uid()
        )
    );

-- Product Favorites: Users manage their own
CREATE POLICY "users_manage_own_favorites" ON public.product_favorites
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Product Reviews: Public read, users manage their own
CREATE POLICY "public_read_reviews" ON public.product_reviews
    FOR SELECT TO public USING (true);

CREATE POLICY "users_manage_own_reviews" ON public.product_reviews
    FOR ALL TO authenticated
    USING (reviewer_id = auth.uid())
    WITH CHECK (reviewer_id = auth.uid());

-- ===============================
-- PHASE 4: FOREIGN KEY CONSTRAINT FOR EXISTING CONVERSATIONS
-- ===============================

-- Add foreign key constraint to existing marketplace_conversations.product_id
ALTER TABLE public.marketplace_conversations
ADD CONSTRAINT marketplace_conversations_product_id_fkey
FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;

-- ===============================
-- PHASE 5: ENHANCED FUNCTIONS
-- ===============================

-- Function to update product updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_product_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Trigger for products
CREATE TRIGGER update_products_timestamp
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.update_product_timestamp();

-- Function to increment product view count
CREATE OR REPLACE FUNCTION public.increment_product_views(product_uuid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.products
    SET view_count = view_count + 1
    WHERE id = product_uuid;
END;
$$;

-- Function to get product statistics
CREATE OR REPLACE FUNCTION public.get_product_stats(product_uuid UUID)
RETURNS TABLE(
    view_count INTEGER,
    favorite_count INTEGER,
    review_count BIGINT,
    average_rating DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.view_count,
        p.favorite_count,
        COUNT(pr.id) as review_count,
        COALESCE(AVG(pr.rating), 0)::DECIMAL as average_rating
    FROM public.products p
    LEFT JOIN public.product_reviews pr ON p.id = pr.product_id
    WHERE p.id = product_uuid
    GROUP BY p.id, p.view_count, p.favorite_count;
END;
$$;

-- ===============================
-- PHASE 6: COMPREHENSIVE MOCK DATA
-- ===============================

DO $$
DECLARE
    -- Category UUIDs
    electronics_id UUID := gen_random_uuid();
    phones_id UUID := gen_random_uuid();
    laptops_id UUID := gen_random_uuid();
    fashion_id UUID := gen_random_uuid();
    clothing_id UUID := gen_random_uuid();
    accessories_id UUID := gen_random_uuid();
    home_id UUID := gen_random_uuid();
    furniture_id UUID := gen_random_uuid();
    appliances_id UUID := gen_random_uuid();
    
    -- Brand UUIDs
    apple_id UUID := gen_random_uuid();
    samsung_id UUID := gen_random_uuid();
    nike_id UUID := gen_random_uuid();
    dell_id UUID := gen_random_uuid();
    ikea_id UUID := gen_random_uuid();
    
    -- Product UUIDs
    iphone_id UUID := gen_random_uuid();
    macbook_id UUID := gen_random_uuid();
    samsung_phone_id UUID := gen_random_uuid();
    nike_shoes_id UUID := gen_random_uuid();
    dell_laptop_id UUID := gen_random_uuid();
    ikea_chair_id UUID := gen_random_uuid();
    
    -- User UUIDs from existing data
    buyer_id UUID := '11111111-1111-1111-1111-111111111111';
    seller1_id UUID;
    seller2_id UUID;
    seller_profile1_id UUID := 'f1111111-1111-1111-1111-111111111111';
    seller_profile2_id UUID := 'f2222222-2222-2222-2222-222222222222';
    
BEGIN
    -- Get existing seller user IDs
    SELECT id INTO seller1_id FROM public.user_profiles WHERE role = 'seller'::public.user_role LIMIT 1 OFFSET 0;
    SELECT id INTO seller2_id FROM public.user_profiles WHERE role = 'seller'::public.user_role LIMIT 1 OFFSET 1;
    
    -- If no sellers found, use buyer ID as fallback
    IF seller1_id IS NULL THEN seller1_id := buyer_id; END IF;
    IF seller2_id IS NULL THEN seller2_id := buyer_id; END IF;

    -- Insert Categories
    INSERT INTO public.product_categories (id, name, description, icon_name, sort_order) VALUES
        (electronics_id, 'Electronics', 'Latest gadgets and electronic devices', 'devices', 1),
        (fashion_id, 'Fashion & Style', 'Clothing, shoes, and accessories', 'shirt', 2),
        (home_id, 'Home & Living', 'Furniture, appliances, and home decor', 'home', 3);
        
    -- Insert Subcategories
    INSERT INTO public.product_categories (id, name, description, icon_name, parent_category_id, sort_order) VALUES
        (phones_id, 'Mobile Phones', 'Smartphones and accessories', 'smartphone', electronics_id, 1),
        (laptops_id, 'Laptops & Computers', 'Computers, laptops, and peripherals', 'laptop', electronics_id, 2),
        (clothing_id, 'Clothing', 'Mens, womens, and kids clothing', 'shirt', fashion_id, 1),
        (accessories_id, 'Accessories', 'Bags, watches, jewelry', 'bag', fashion_id, 2),
        (furniture_id, 'Furniture', 'Tables, chairs, beds, sofas', 'chair', home_id, 1),
        (appliances_id, 'Home Appliances', 'Kitchen, cleaning, electronics', 'microwave', home_id, 2);

    -- Insert Brands
    INSERT INTO public.product_brands (id, name, logo_url, description, is_verified) VALUES
        (apple_id, 'Apple', 'https://images.unsplash.com/photo-1611174743420-3d7df880ce32?w=100&h=100&fit=crop', 'Premium technology products', true),
        (samsung_id, 'Samsung', 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=100&h=100&fit=crop', 'Innovation for everyone', true),
        (nike_id, 'Nike', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=100&h=100&fit=crop', 'Just Do It', true),
        (dell_id, 'Dell', 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=100&h=100&fit=crop', 'Technology solutions', true),
        (ikea_id, 'IKEA', 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=100&h=100&fit=crop', 'Affordable home solutions', true);

    -- Insert Products with realistic data
    INSERT INTO public.products (
        id, seller_id, seller_profile_id, title, description, category_id, brand_id,
        price, original_price, condition, status, location_text, latitude, longitude,
        is_negotiable, is_featured, view_count, favorite_count, tags, specifications
    ) VALUES
        (iphone_id, seller1_id, seller_profile1_id, 'iPhone 14 Pro Max - Space Black 256GB', 
         'Barely used iPhone 14 Pro Max in excellent condition. Includes original box, charger, and unused EarPods. No scratches or dents. Always kept in protective case and screen protector.',
         phones_id, apple_id, 1299.00, 1499.00, 'like_new', 'active', 
         'Gadong, Brunei-Muara', 4.9031, 114.9398, true, true, 45, 12,
         ARRAY['iPhone', 'Apple', 'smartphone', '256GB', 'Pro Max'],
         '{"storage": "256GB", "color": "Space Black", "model": "iPhone 14 Pro Max", "warranty": "10 months remaining"}'::jsonb),
         
        (samsung_phone_id, seller2_id, seller_profile2_id, 'Samsung Galaxy S23 Ultra - Phantom Black', 
         'Samsung Galaxy S23 Ultra in mint condition. Perfect for photography enthusiasts. Comes with S Pen, wireless charger, and premium case. Battery health excellent.',
         phones_id, samsung_id, 999.00, 1299.00, 'like_new', 'active',
         'Bandar Seri Begawan, Brunei-Muara', 4.8895, 114.9421, true, false, 32, 8,
         ARRAY['Samsung', 'Galaxy', 'S23 Ultra', 'Android', 'S Pen'],
         '{"storage": "256GB", "color": "Phantom Black", "model": "Galaxy S23 Ultra", "warranty": "8 months remaining"}'::jsonb),
         
        (macbook_id, seller1_id, seller_profile1_id, 'MacBook Air M2 13-inch - Midnight', 
         'Brand new MacBook Air with M2 chip. Perfect for students and professionals. Incredible battery life and performance. Still sealed in original packaging.',
         laptops_id, apple_id, 1399.00, 1599.00, 'new', 'active',
         'Kiulap, Brunei-Muara', 4.8780, 114.9320, false, true, 67, 22,
         ARRAY['MacBook', 'Apple', 'M2', 'laptop', 'new'],
         '{"processor": "Apple M2", "ram": "8GB", "storage": "256GB SSD", "display": "13.6-inch Liquid Retina", "warranty": "1 year Apple warranty"}'::jsonb),
         
        (dell_laptop_id, seller2_id, seller_profile2_id, 'Dell XPS 15 Gaming Laptop - RTX 3060', 
         'High-performance Dell XPS 15 perfect for gaming and creative work. NVIDIA RTX 3060 graphics card, Intel i7 processor, pristine condition. Ideal for designers and gamers.',
         laptops_id, dell_id, 1899.00, 2299.00, 'good', 'active',
         'Seria, Belait', 4.6063, 114.3244, true, false, 28, 5,
         ARRAY['Dell', 'XPS', 'gaming', 'RTX 3060', 'laptop'],
         '{"processor": "Intel Core i7-11800H", "ram": "16GB DDR4", "storage": "512GB SSD", "graphics": "NVIDIA RTX 3060 6GB", "display": "15.6-inch 4K OLED"}'::jsonb),
         
        (nike_shoes_id, seller1_id, seller_profile1_id, 'Nike Air Jordan 1 Retro High - Chicago Colorway', 
         'Authentic Nike Air Jordan 1 in iconic Chicago colors. Size US 9.5, worn only twice for special occasions. No box but includes authentication certificate from StockX.',
         clothing_id, nike_id, 389.00, 450.00, 'like_new', 'active',
         'Kuala Belait, Belait', 4.5832, 114.2312, true, false, 89, 31,
         ARRAY['Nike', 'Air Jordan', 'sneakers', 'Chicago', 'US 9.5'],
         '{"size": "US 9.5", "color": "White/Black-Chicago Red", "model": "Air Jordan 1 Retro High OG", "authentication": "StockX Verified"}'::jsonb),
         
        (ikea_chair_id, seller2_id, seller_profile2_id, 'IKEA MARKUS Office Chair - Black', 
         'Comfortable IKEA MARKUS ergonomic office chair in excellent condition. Perfect for home office or study. Adjustable height, lumbar support, and breathable mesh back.',
         furniture_id, ikea_id, 89.00, 149.00, 'good', 'active',
         'Tutong, Tutong', 4.8023, 114.6499, true, false, 15, 4,
         ARRAY['IKEA', 'office chair', 'ergonomic', 'MARKUS', 'furniture'],
         '{"color": "Black", "material": "Fabric/Mesh", "adjustable": true, "warranty": "10 years", "dimensions": "62x62x129-140 cm"}'::jsonb);

    -- Insert Product Images
    INSERT INTO public.product_images (product_id, image_url, alt_text, is_primary, sort_order) VALUES
        -- iPhone images
        (iphone_id, 'https://images.unsplash.com/photo-1678911820864-e2c567c655d7?w=800&h=600', 'iPhone 14 Pro Max Space Black front view', true, 0),
        (iphone_id, 'https://images.unsplash.com/photo-1678911820485-2e3a6b282354?w=800&h=600', 'iPhone 14 Pro Max with original box', false, 1),
        (iphone_id, 'https://images.unsplash.com/photo-1678911820331-41e9b89c52a8?w=800&h=600', 'iPhone 14 Pro Max camera detail', false, 2),
        
        -- Samsung Galaxy images
        (samsung_phone_id, 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800&h=600', 'Samsung Galaxy S23 Ultra front', true, 0),
        (samsung_phone_id, 'https://images.unsplash.com/photo-1555774698-0b77e0d5fac6?w=800&h=600', 'Samsung Galaxy with S Pen', false, 1),
        
        -- MacBook images
        (macbook_id, 'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=800&h=600', 'MacBook Air M2 Midnight color', true, 0),
        (macbook_id, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&h=600', 'MacBook Air keyboard detail', false, 1),
        
        -- Dell laptop images
        (dell_laptop_id, 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&h=600', 'Dell XPS 15 laptop open', true, 0),
        (dell_laptop_id, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800&h=600', 'Dell XPS gaming setup', false, 1),
        
        -- Nike shoes images
        (nike_shoes_id, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&h=600', 'Nike Air Jordan 1 Chicago colorway', true, 0),
        (nike_shoes_id, 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800&h=600', 'Air Jordan 1 side profile', false, 1),
        
        -- IKEA chair images
        (ikea_chair_id, 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&h=600', 'IKEA MARKUS office chair', true, 0),
        (ikea_chair_id, 'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=800&h=600', 'Office chair ergonomic features', false, 1);

    -- Insert Product Favorites (wishlist items)
    INSERT INTO public.product_favorites (user_id, product_id) VALUES
        (buyer_id, iphone_id),
        (buyer_id, macbook_id),
        (buyer_id, nike_shoes_id);

    -- Insert Product Reviews
    INSERT INTO public.product_reviews (product_id, reviewer_id, rating, review_text, is_verified_purchase) VALUES
        (samsung_phone_id, buyer_id, 5, 'Amazing phone with incredible camera quality. The S Pen is a game changer for productivity. Seller was very responsive and item was exactly as described.', false),
        (dell_laptop_id, buyer_id, 4, 'Great laptop for gaming and work. RTX 3060 handles all modern games smoothly. Only minor wear on the corners but performance is excellent.', false),
        (ikea_chair_id, buyer_id, 5, 'Very comfortable office chair. Great value for money. Assembly was easy and the seller even included extra screws. Highly recommended!', false);

    -- Insert Product-Specific Conversations
    INSERT INTO public.marketplace_conversations (
        id, participant_one_id, participant_two_id, product_id, chat_type, 
        created_at, last_message_at
    ) VALUES
        (gen_random_uuid(), buyer_id, seller1_id, iphone_id, 'product_inquiry', 
         CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
        (gen_random_uuid(), buyer_id, seller2_id, samsung_phone_id, 'product_inquiry',
         CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
        (gen_random_uuid(), buyer_id, seller1_id, macbook_id, 'product_inquiry',
         CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '1 day');

END $$;

-- ===============================
-- PHASE 7: PRODUCT-SPECIFIC CHAT MESSAGES
-- ===============================

DO $$
DECLARE
    buyer_id UUID := '11111111-1111-1111-1111-111111111111';
    seller1_id UUID;
    seller2_id UUID;
    iphone_conversation_id UUID;
    samsung_conversation_id UUID;
    macbook_conversation_id UUID;
BEGIN
    -- Get seller IDs
    SELECT id INTO seller1_id FROM public.user_profiles WHERE role = 'seller'::public.user_role LIMIT 1 OFFSET 0;
    SELECT id INTO seller2_id FROM public.user_profiles WHERE role = 'seller'::public.user_role LIMIT 1 OFFSET 1;
    
    -- Get conversation IDs for product inquiries
    SELECT id INTO iphone_conversation_id FROM public.marketplace_conversations 
    WHERE participant_one_id = buyer_id AND participant_two_id = seller1_id 
    AND chat_type = 'product_inquiry'::public.chat_type LIMIT 1;
    
    SELECT id INTO samsung_conversation_id FROM public.marketplace_conversations 
    WHERE participant_one_id = buyer_id AND participant_two_id = seller2_id 
    AND chat_type = 'product_inquiry'::public.chat_type LIMIT 1;
    
    SELECT id INTO macbook_conversation_id FROM public.marketplace_conversations 
    WHERE participant_one_id = buyer_id AND participant_two_id = seller1_id 
    AND chat_type = 'product_inquiry'::public.chat_type 
    AND id != iphone_conversation_id LIMIT 1;

    -- iPhone conversation messages
    IF iphone_conversation_id IS NOT NULL THEN
        INSERT INTO public.marketplace_messages (conversation_id, sender_id, message_text, created_at, status) VALUES
            (iphone_conversation_id, buyer_id, 'Hi! Is this iPhone 14 Pro Max still available?', CURRENT_TIMESTAMP - INTERVAL '2 hours', 'read'),
            (iphone_conversation_id, seller1_id, 'Yes it is! The phone is in excellent condition, barely used for 3 months.', CURRENT_TIMESTAMP - INTERVAL '1 hour 50 minutes', 'read'),
            (iphone_conversation_id, buyer_id, 'Can you send me more photos of the back and sides?', CURRENT_TIMESTAMP - INTERVAL '1 hour 30 minutes', 'read'),
            (iphone_conversation_id, seller1_id, 'Sure! I will send them shortly. The phone has been in a case since day one.', CURRENT_TIMESTAMP - INTERVAL '1 hour 15 minutes', 'read'),
            (iphone_conversation_id, buyer_id, 'Great! Is the price negotiable? I can pick it up today.', CURRENT_TIMESTAMP - INTERVAL '45 minutes', 'read'),
            (iphone_conversation_id, seller1_id, 'I can do $1250 if you can meet me at The Mall Gadong today.', CURRENT_TIMESTAMP - INTERVAL '30 minutes', 'delivered');
    END IF;

    -- Samsung conversation messages  
    IF samsung_conversation_id IS NOT NULL THEN
        INSERT INTO public.marketplace_messages (conversation_id, sender_id, message_text, created_at, status) VALUES
            (samsung_conversation_id, buyer_id, 'Hello! Interested in your Samsung Galaxy S23 Ultra. Does it come with the original charger?', CURRENT_TIMESTAMP - INTERVAL '1 day', 'read'),
            (samsung_conversation_id, seller2_id, 'Hi there! Yes, it comes with the original charger, wireless charger, and S Pen. Everything is included.', CURRENT_TIMESTAMP - INTERVAL '23 hours', 'read'),
            (samsung_conversation_id, buyer_id, 'Perfect! How is the battery life? Any issues with the screen?', CURRENT_TIMESTAMP - INTERVAL '22 hours', 'read'),
            (samsung_conversation_id, seller2_id, 'Battery is still excellent, easily lasts full day with heavy usage. Screen is perfect, no scratches at all.', CURRENT_TIMESTAMP - INTERVAL '21 hours', 'read'),
            (samsung_conversation_id, buyer_id, 'Sounds great! Can we meet somewhere in BSB? I am free this weekend.', CURRENT_TIMESTAMP - INTERVAL '3 hours', 'read'),
            (samsung_conversation_id, seller2_id, 'Sure! How about at Yayasan Complex on Saturday around 2 PM?', CURRENT_TIMESTAMP - INTERVAL '2 hours', 'delivered');
    END IF;

    -- MacBook conversation messages
    IF macbook_conversation_id IS NOT NULL THEN
        INSERT INTO public.marketplace_messages (conversation_id, sender_id, message_text, created_at, status) VALUES
            (macbook_conversation_id, buyer_id, 'Hi! Is this MacBook Air still sealed? I am looking for a new laptop for university.', CURRENT_TIMESTAMP - INTERVAL '3 days', 'read'),
            (macbook_conversation_id, seller1_id, 'Hello! Yes, it is completely sealed and brand new. Perfect for university work with amazing battery life.', CURRENT_TIMESTAMP - INTERVAL '2 days 20 hours', 'read'),
            (macbook_conversation_id, buyer_id, 'That is exactly what I need! Why are you selling it if it is new?', CURRENT_TIMESTAMP - INTERVAL '2 days 10 hours', 'read'),
            (macbook_conversation_id, seller1_id, 'I received it as a gift but I already have a MacBook Pro for work. This one is perfect for students.', CURRENT_TIMESTAMP - INTERVAL '2 days', 'read'),
            (macbook_conversation_id, buyer_id, 'I understand. The price is firm at $1399?', CURRENT_TIMESTAMP - INTERVAL '1 day 5 hours', 'read'),
            (macbook_conversation_id, seller1_id, 'Since it is brand new and sealed, I cannot go lower. But I can include a laptop sleeve and wireless mouse.', CURRENT_TIMESTAMP - INTERVAL '1 day', 'delivered');
    END IF;

END $$;
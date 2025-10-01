-- Schema Analysis: product_favorites table and favorite_count column already exist
-- Integration Type: addition - adding missing toggle function
-- Dependencies: products, product_favorites, user_profiles tables

-- Toggle favorite function that returns the new state (true = liked, false = unliked)
CREATE OR REPLACE FUNCTION public.toggle_product_favorite(p_product_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    exists_like BOOLEAN;
BEGIN
    -- Check if user already liked this product
    SELECT TRUE INTO exists_like
    FROM public.product_favorites
    WHERE user_id = auth.uid() AND product_id = p_product_id
    LIMIT 1;

    IF exists_like THEN
        -- Remove favorite
        DELETE FROM public.product_favorites
        WHERE user_id = auth.uid() AND product_id = p_product_id;
        RETURN FALSE; -- now unliked
    ELSE
        -- Add favorite
        INSERT INTO public.product_favorites(user_id, product_id)
        VALUES (auth.uid(), p_product_id);
        RETURN TRUE; -- now liked
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to toggle favorite: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.toggle_product_favorite(UUID) TO authenticated;

-- Function to sync favorite count (triggers should already exist based on schema)
-- This ensures the products.favorite_count stays accurate
CREATE OR REPLACE FUNCTION public.sync_product_favorite_count(p_product_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.products 
    SET favorite_count = (
        SELECT COUNT(*) 
        FROM public.product_favorites 
        WHERE product_id = p_product_id
    )
    WHERE id = p_product_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_product_favorite_count(UUID) TO authenticated;
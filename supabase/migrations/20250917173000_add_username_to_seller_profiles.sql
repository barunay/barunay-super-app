-- Schema Analysis: seller_profiles table exists with business_name, business_description, verification_status
-- Integration Type: Modification - adding username column to existing table
-- Dependencies: seller_profiles table

-- Add username column to seller_profiles table
ALTER TABLE public.seller_profiles 
ADD COLUMN username TEXT UNIQUE;

-- Add index for username column (for performance and uniqueness)
CREATE INDEX idx_seller_profiles_username ON public.seller_profiles(username);

-- Add constraint to ensure username follows a valid pattern
ALTER TABLE public.seller_profiles 
ADD CONSTRAINT check_username_format 
CHECK (username ~ '^[a-zA-Z0-9_]{3,30}$');

-- Update existing seller profiles with sample usernames (optional - for existing data)
DO $$
DECLARE
    seller_record RECORD;
    generated_username TEXT;
    counter INTEGER := 1;
BEGIN
    -- Loop through existing seller profiles without usernames
    FOR seller_record IN 
        SELECT id, business_name FROM public.seller_profiles WHERE username IS NULL
    LOOP
        -- Generate username from business name
        generated_username := LOWER(REGEXP_REPLACE(seller_record.business_name, '[^a-zA-Z0-9]', '_', 'g'));
        generated_username := SUBSTRING(generated_username, 1, 20) || '_' || counter::TEXT;
        
        -- Update the record
        UPDATE public.seller_profiles 
        SET username = generated_username 
        WHERE id = seller_record.id;
        
        counter := counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Updated % seller profiles with usernames', counter - 1;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error updating seller profiles: %', SQLERRM;
END $$;
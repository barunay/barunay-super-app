-- Location: supabase/migrations/20250917162923_audit_logging_and_seller_deletion.sql
-- Schema Analysis: Existing marketplace schema with user_profiles, seller_profiles, products tables
-- Integration Type: Addition - Adding audit_app schema and seller deletion functionality
-- Dependencies: user_profiles, seller_profiles, products tables

-- 1. Create audit_app schema for application audit logs
CREATE SCHEMA IF NOT EXISTS audit_app;

-- 2. Create audit activity_log table in audit_app schema
CREATE TABLE IF NOT EXISTS audit_app.activity_log (
    id BIGSERIAL PRIMARY KEY,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    category TEXT NOT NULL, -- 'marketplace' | 'delivery' | 'chat' | 'profile'
    actor_user_id UUID NOT NULL, -- auto-filled from auth.uid()
    action TEXT NOT NULL, -- 'create' | 'update' | 'delete' | 'rename' | ...
    entity TEXT NOT NULL, -- 'seller_profiles' | 'products' | 'user_profiles' | ...
    entity_id UUID, -- affected row id (nullable if N/A)
    description TEXT NOT NULL, -- human string: e.g. "deleted product <id>"
    changes JSONB -- optional diff: [{"field":"title","from":"A","to":"B"}]
);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_audit_app_occurred_at ON audit_app.activity_log(occurred_at);
CREATE INDEX IF NOT EXISTS idx_audit_app_actor ON audit_app.activity_log(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_app_category ON audit_app.activity_log(category);

-- 4. Create RPC function for logging (server-side insert that stamps auth.uid())
CREATE OR REPLACE FUNCTION audit_app.log_simple(
    p_category TEXT,
    p_action TEXT,
    p_entity TEXT,
    p_entity_id UUID,
    p_description TEXT,
    p_changes JSONB DEFAULT NULL
) RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = audit_app, public
AS $$
    INSERT INTO audit_app.activity_log(category, actor_user_id, action, entity, entity_id, description, changes)
    VALUES (p_category, auth.uid(), p_action, p_entity, p_entity_id, p_description, p_changes);
$$;

-- 5. Create function to check if seller profile can be deleted (no active products)
CREATE OR REPLACE FUNCTION public.can_delete_seller_profile(seller_profile_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT NOT EXISTS (
    SELECT 1 FROM public.products p
    WHERE p.seller_profile_id = seller_profile_uuid
    AND p.status IN ('active', 'sold', 'reserved')
);
$$;

-- 6. Create function to delete seller profile with ownership verification
CREATE OR REPLACE FUNCTION public.delete_seller_profile_with_verification(seller_profile_uuid UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    seller_record RECORD;
    user_sub_profile_id UUID;
    business_name TEXT;
    result JSON;
BEGIN
    -- 1. Get seller profile with ownership verification
    SELECT sp.*, usp.user_id, usp.id as sub_profile_id
    INTO seller_record
    FROM public.seller_profiles sp
    JOIN public.user_sub_profiles usp ON sp.user_profile_id = usp.id
    WHERE sp.id = seller_profile_uuid
    AND usp.user_id = auth.uid(); -- Only owner can delete

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Seller profile not found or you do not have permission to delete it'
        );
    END IF;

    -- Store for audit logging
    user_sub_profile_id := seller_record.sub_profile_id;
    business_name := seller_record.business_name;

    -- 2. Check if seller has active products
    IF NOT public.can_delete_seller_profile(seller_profile_uuid) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot delete seller profile. You still have active products. Please delete or deactivate all products first.'
        );
    END IF;

    -- 3. Delete seller profile (cascading will handle related records)
    DELETE FROM public.seller_profiles WHERE id = seller_profile_uuid;

    -- 4. Delete user sub profile
    DELETE FROM public.user_sub_profiles WHERE id = user_sub_profile_id;

    -- 5. Update user role back to buyer if no other seller profiles
    UPDATE public.user_profiles 
    SET role = 'buyer'
    WHERE id = auth.uid()
    AND NOT EXISTS (
        SELECT 1 FROM public.user_sub_profiles usp2
        WHERE usp2.user_id = auth.uid() 
        AND usp2.profile_type = 'seller'
        AND usp2.is_active = true
    );

    -- 6. Log the deletion
    PERFORM audit_app.log_simple(
        'marketplace',
        'delete',
        'seller_profiles',
        seller_profile_uuid,
        'User deleted seller profile <' || seller_profile_uuid::text || '> "' || business_name || '"'
    );

    RETURN json_build_object(
        'success', true,
        'message', 'Seller profile deleted successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Failed to delete seller profile: ' || SQLERRM
        );
END;
$func$;

-- 7. Enable RLS on audit_app.activity_log
ALTER TABLE audit_app.activity_log ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS policies for audit log access
-- Users can only see their own audit logs
CREATE POLICY "users_view_own_audit_logs"
ON audit_app.activity_log
FOR SELECT
TO authenticated
USING (actor_user_id = auth.uid());

-- Only authenticated users can insert audit logs (through RPC function)
CREATE POLICY "authenticated_users_insert_audit_logs"
ON audit_app.activity_log
FOR INSERT
TO authenticated
WITH CHECK (actor_user_id = auth.uid());

-- Admin can view all audit logs
CREATE POLICY "admin_view_all_audit_logs"
ON audit_app.activity_log
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- 9. Grant permissions
GRANT USAGE ON SCHEMA audit_app TO authenticated;
GRANT EXECUTE ON FUNCTION audit_app.log_simple(TEXT, TEXT, TEXT, UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_delete_seller_profile(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_seller_profile_with_verification(UUID) TO authenticated;
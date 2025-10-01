-- Location: supabase/migrations/20250911171031_enhanced_marketplace_chat.sql
-- Schema Analysis: Existing delivery system with delivery_chat_messages, user_profiles, delivery_requests
-- Integration Type: Extension - Adding general marketplace chat capabilities
-- Dependencies: user_profiles, delivery_requests, delivery_chat_messages (existing)

-- 1. New Types for Enhanced Chat Features
CREATE TYPE public.chat_type AS ENUM ('product_inquiry', 'general', 'delivery', 'customer_support');
CREATE TYPE public.message_status AS ENUM ('sent', 'delivered', 'read');
CREATE TYPE public.media_type AS ENUM ('image', 'video', 'audio', 'document', 'location');

-- 2. Enhanced Marketplace Chat Tables
CREATE TABLE public.marketplace_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_type public.chat_type DEFAULT 'general'::public.chat_type,
    participant_one_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    participant_two_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    product_id UUID, -- Optional reference to product being discussed
    delivery_request_id UUID REFERENCES public.delivery_requests(id) ON DELETE SET NULL,
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_archived BOOLEAN DEFAULT false,
    is_blocked BOOLEAN DEFAULT false,
    blocked_by_user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.marketplace_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.marketplace_conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    message_text TEXT,
    media_url TEXT,
    media_type public.media_type,
    media_caption TEXT,
    reply_to_message_id UUID REFERENCES public.marketplace_messages(id) ON DELETE SET NULL,
    is_quick_reply BOOLEAN DEFAULT false,
    quick_reply_options JSONB, -- Store predefined quick reply options
    status public.message_status DEFAULT 'sent'::public.message_status,
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.chat_read_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES public.marketplace_messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, user_id)
);

CREATE TABLE public.chat_typing_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.marketplace_conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(conversation_id, user_id)
);

CREATE TABLE public.quick_reply_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    template_name TEXT NOT NULL,
    message_text TEXT NOT NULL,
    chat_type public.chat_type DEFAULT 'general'::public.chat_type,
    usage_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes for Performance
CREATE INDEX idx_marketplace_conversations_participants ON public.marketplace_conversations(participant_one_id, participant_two_id);
CREATE INDEX idx_marketplace_conversations_product ON public.marketplace_conversations(product_id) WHERE product_id IS NOT NULL;
CREATE INDEX idx_marketplace_conversations_last_message ON public.marketplace_conversations(last_message_at DESC);
CREATE INDEX idx_marketplace_messages_conversation ON public.marketplace_messages(conversation_id, created_at DESC);
CREATE INDEX idx_marketplace_messages_sender ON public.marketplace_messages(sender_id);
CREATE INDEX idx_marketplace_messages_status ON public.marketplace_messages(status);
CREATE INDEX idx_chat_read_receipts_message ON public.chat_read_receipts(message_id);
CREATE INDEX idx_chat_typing_indicators_conversation ON public.chat_typing_indicators(conversation_id);
CREATE INDEX idx_quick_reply_templates_user ON public.quick_reply_templates(user_id, chat_type);

-- 4. Functions for Chat Operations
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    UPDATE public.marketplace_conversations
    SET 
        last_message_at = NEW.created_at,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$func$;

CREATE OR REPLACE FUNCTION public.mark_messages_as_delivered(conv_id UUID, user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    UPDATE public.marketplace_messages
    SET 
        status = 'delivered'::public.message_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE conversation_id = conv_id
    AND sender_id != user_id
    AND status = 'sent'::public.message_status;
END;
$func$;

CREATE OR REPLACE FUNCTION public.get_unread_message_count(user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO unread_count
    FROM public.marketplace_messages mm
    JOIN public.marketplace_conversations mc ON mm.conversation_id = mc.id
    WHERE (mc.participant_one_id = user_id OR mc.participant_two_id = user_id)
    AND mm.sender_id != user_id
    AND mm.status != 'read'::public.message_status
    AND mm.is_deleted = false;
    
    RETURN COALESCE(unread_count, 0);
END;
$func$;

-- 5. Enable RLS
ALTER TABLE public.marketplace_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_read_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quick_reply_templates ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies using Pattern 2 (Simple User Ownership)
CREATE POLICY "users_access_own_conversations"
ON public.marketplace_conversations
FOR ALL
TO authenticated
USING (participant_one_id = auth.uid() OR participant_two_id = auth.uid())
WITH CHECK (participant_one_id = auth.uid() OR participant_two_id = auth.uid());

CREATE POLICY "participants_access_messages"
ON public.marketplace_messages
FOR ALL
TO authenticated
USING (
    conversation_id IN (
        SELECT id FROM public.marketplace_conversations
        WHERE participant_one_id = auth.uid() OR participant_two_id = auth.uid()
    )
)
WITH CHECK (
    sender_id = auth.uid() AND
    conversation_id IN (
        SELECT id FROM public.marketplace_conversations
        WHERE participant_one_id = auth.uid() OR participant_two_id = auth.uid()
    )
);

CREATE POLICY "users_manage_read_receipts"
ON public.chat_read_receipts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "participants_manage_typing_indicators"
ON public.chat_typing_indicators
FOR ALL
TO authenticated
USING (
    user_id = auth.uid() OR
    conversation_id IN (
        SELECT id FROM public.marketplace_conversations
        WHERE participant_one_id = auth.uid() OR participant_two_id = auth.uid()
    )
)
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_quick_replies"
ON public.quick_reply_templates
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Triggers
CREATE TRIGGER update_conversation_timestamp
    AFTER INSERT ON public.marketplace_messages
    FOR EACH ROW EXECUTE FUNCTION public.update_conversation_last_message();

-- 8. Mock Data for Enhanced Chat Features
DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    conversation_id UUID := gen_random_uuid();
    message1_id UUID := gen_random_uuid();
    message2_id UUID := gen_random_uuid();
    message3_id UUID := gen_random_uuid();
BEGIN
    -- Get existing user IDs from user_profiles
    SELECT id INTO user1_id FROM public.user_profiles ORDER BY created_at LIMIT 1;
    SELECT id INTO user2_id FROM public.user_profiles ORDER BY created_at LIMIT 1 OFFSET 1;
    
    -- If we don't have two users, create a single conversation with one user
    IF user2_id IS NULL THEN
        user2_id := user1_id;
    END IF;
    
    -- Create sample marketplace conversation
    INSERT INTO public.marketplace_conversations (id, chat_type, participant_one_id, participant_two_id)
    VALUES (conversation_id, 'product_inquiry'::public.chat_type, user1_id, user2_id);
    
    -- Create sample messages with different types
    INSERT INTO public.marketplace_messages (id, conversation_id, sender_id, message_text, status) VALUES
        (message1_id, conversation_id, user1_id, 'Hi! Is this iPhone still available?', 'read'::public.message_status),
        (message2_id, conversation_id, user2_id, 'Yes, it is! Would you like to see more photos?', 'delivered'::public.message_status),
        (message3_id, conversation_id, user1_id, 'That would be great, thanks!', 'sent'::public.message_status);
    
    -- Create sample quick reply templates
    INSERT INTO public.quick_reply_templates (user_id, template_name, message_text, chat_type) VALUES
        (user1_id, 'Greeting', 'Hello! How can I help you today?', 'general'::public.chat_type),
        (user1_id, 'Price Inquiry', 'What is your best price for this item?', 'product_inquiry'::public.chat_type),
        (user2_id, 'Still Available', 'Yes, this item is still available!', 'product_inquiry'::public.chat_type),
        (user2_id, 'Meet Location', 'We can meet at Times Square Brunei if convenient for you.', 'general'::public.chat_type);
    
    -- Create sample read receipts
    INSERT INTO public.chat_read_receipts (message_id, user_id) VALUES
        (message1_id, user2_id);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data creation failed: %', SQLERRM;
END $$;

-- 9. Cleanup function for enhanced chat
CREATE OR REPLACE FUNCTION public.cleanup_marketplace_chat_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    -- Delete in dependency order
    DELETE FROM public.chat_read_receipts;
    DELETE FROM public.chat_typing_indicators;
    DELETE FROM public.marketplace_messages;
    DELETE FROM public.marketplace_conversations;
    DELETE FROM public.quick_reply_templates;
    
    RAISE NOTICE 'Marketplace chat data cleaned up successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$func$;
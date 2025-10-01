-- Location: supabase/migrations/20250911165809_delivery_system.sql
-- Schema Analysis: Existing user_profiles, user_sub_profiles, runner_profiles, seller_profiles
-- Integration Type: NEW_MODULE - Complete delivery system functionality
-- Dependencies: user_profiles, user_sub_profiles, runner_profiles

-- 1. Create delivery system types
CREATE TYPE public.delivery_status AS ENUM (
    'pending',
    'awaiting_runner',
    'runner_assigned',
    'in_transit',
    'delivered',
    'cancelled',
    'failed'
);

CREATE TYPE public.proposal_status AS ENUM (
    'pending',
    'accepted',
    'rejected',
    'expired'
);

CREATE TYPE public.urgency_level AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);

-- 2. Delivery requests table
CREATE TABLE public.delivery_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    pickup_address TEXT NOT NULL,
    pickup_latitude DECIMAL(10, 8),
    pickup_longitude DECIMAL(11, 8),
    delivery_address TEXT NOT NULL,
    delivery_latitude DECIMAL(10, 8),
    delivery_longitude DECIMAL(11, 8),
    urgency public.urgency_level DEFAULT 'medium'::public.urgency_level,
    estimated_distance DECIMAL(6, 2), -- in km
    max_budget DECIMAL(8, 2), -- maximum budget user is willing to pay
    special_instructions TEXT,
    status public.delivery_status DEFAULT 'pending'::public.delivery_status,
    assigned_runner_id UUID REFERENCES public.runner_profiles(id) ON DELETE SET NULL,
    scheduled_pickup_time TIMESTAMPTZ,
    actual_pickup_time TIMESTAMPTZ,
    actual_delivery_time TIMESTAMPTZ,
    recipient_name TEXT,
    recipient_phone TEXT,
    package_size TEXT, -- small, medium, large
    package_weight DECIMAL(5, 2), -- in kg
    package_value DECIMAL(10, 2), -- for insurance
    photo_urls TEXT[], -- photos of package
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Runner proposals table
CREATE TABLE public.runner_proposals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_request_id UUID REFERENCES public.delivery_requests(id) ON DELETE CASCADE,
    runner_id UUID REFERENCES public.runner_profiles(id) ON DELETE CASCADE,
    proposed_fee DECIMAL(8, 2) NOT NULL,
    estimated_duration INTEGER, -- in minutes
    message TEXT,
    status public.proposal_status DEFAULT 'pending'::public.proposal_status,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Delivery tasks table (created when proposal is accepted)
CREATE TABLE public.delivery_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_request_id UUID REFERENCES public.delivery_requests(id) ON DELETE CASCADE,
    runner_id UUID REFERENCES public.runner_profiles(id) ON DELETE CASCADE,
    accepted_proposal_id UUID REFERENCES public.runner_proposals(id) ON DELETE SET NULL,
    task_status public.delivery_status DEFAULT 'runner_assigned'::public.delivery_status,
    agreed_fee DECIMAL(8, 2) NOT NULL,
    pickup_confirmation_photo TEXT,
    delivery_confirmation_photo TEXT,
    runner_notes TEXT,
    customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5),
    customer_feedback TEXT,
    runner_rating INTEGER CHECK (runner_rating >= 1 AND runner_rating <= 5),
    runner_feedback TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Delivery chat messages table
CREATE TABLE public.delivery_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_request_id UUID REFERENCES public.delivery_requests(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type TEXT DEFAULT 'text', -- text, image, location, system
    attachments TEXT[],
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Delivery notifications table
CREATE TABLE public.delivery_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    delivery_request_id UUID REFERENCES public.delivery_requests(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    notification_type TEXT NOT NULL, -- new_request, new_proposal, status_update, chat_message
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Runner earnings table
CREATE TABLE public.runner_earnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    runner_id UUID REFERENCES public.runner_profiles(id) ON DELETE CASCADE,
    delivery_task_id UUID REFERENCES public.delivery_tasks(id) ON DELETE CASCADE,
    gross_amount DECIMAL(8, 2) NOT NULL,
    platform_fee DECIMAL(8, 2) DEFAULT 0,
    net_amount DECIMAL(8, 2) NOT NULL,
    payment_status TEXT DEFAULT 'pending', -- pending, processed, failed
    payment_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. Create indexes for better performance
CREATE INDEX idx_delivery_requests_user_id ON public.delivery_requests(user_id);
CREATE INDEX idx_delivery_requests_status ON public.delivery_requests(status);
CREATE INDEX idx_delivery_requests_assigned_runner ON public.delivery_requests(assigned_runner_id);
CREATE INDEX idx_delivery_requests_created_at ON public.delivery_requests(created_at);
CREATE INDEX idx_delivery_requests_urgency ON public.delivery_requests(urgency);

CREATE INDEX idx_runner_proposals_delivery_request ON public.runner_proposals(delivery_request_id);
CREATE INDEX idx_runner_proposals_runner_id ON public.runner_proposals(runner_id);
CREATE INDEX idx_runner_proposals_status ON public.runner_proposals(status);
CREATE INDEX idx_runner_proposals_expires_at ON public.runner_proposals(expires_at);

CREATE INDEX idx_delivery_tasks_runner_id ON public.delivery_tasks(runner_id);
CREATE INDEX idx_delivery_tasks_delivery_request ON public.delivery_tasks(delivery_request_id);
CREATE INDEX idx_delivery_tasks_status ON public.delivery_tasks(task_status);

CREATE INDEX idx_delivery_chat_messages_delivery_request ON public.delivery_chat_messages(delivery_request_id);
CREATE INDEX idx_delivery_chat_messages_sender ON public.delivery_chat_messages(sender_id);
CREATE INDEX idx_delivery_chat_messages_created_at ON public.delivery_chat_messages(created_at);

CREATE INDEX idx_delivery_notifications_user_id ON public.delivery_notifications(user_id);
CREATE INDEX idx_delivery_notifications_is_read ON public.delivery_notifications(is_read);

CREATE INDEX idx_runner_earnings_runner_id ON public.runner_earnings(runner_id);
CREATE INDEX idx_runner_earnings_payment_status ON public.runner_earnings(payment_status);

-- 9. Enable RLS for all tables
ALTER TABLE public.delivery_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runner_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runner_earnings ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies using Pattern 2 (Simple User Ownership)

-- Delivery requests policies
CREATE POLICY "users_manage_own_delivery_requests"
ON public.delivery_requests
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Runners can view delivery requests that are awaiting runners
CREATE POLICY "runners_view_available_delivery_requests"
ON public.delivery_requests
FOR SELECT
TO authenticated
USING (
    status = 'awaiting_runner' 
    OR assigned_runner_id = (
        SELECT rp.id FROM public.runner_profiles rp 
        JOIN public.user_sub_profiles usp ON rp.user_profile_id = usp.id
        WHERE usp.user_id = auth.uid()
    )
);

-- Runner proposals policies
CREATE POLICY "runners_manage_own_proposals"
ON public.runner_proposals
FOR ALL
TO authenticated
USING (
    runner_id = (
        SELECT rp.id FROM public.runner_profiles rp 
        JOIN public.user_sub_profiles usp ON rp.user_profile_id = usp.id
        WHERE usp.user_id = auth.uid()
    )
)
WITH CHECK (
    runner_id = (
        SELECT rp.id FROM public.runner_profiles rp 
        JOIN public.user_sub_profiles usp ON rp.user_profile_id = usp.id
        WHERE usp.user_id = auth.uid()
    )
);

-- Users can view proposals for their delivery requests
CREATE POLICY "users_view_proposals_for_their_requests"
ON public.runner_proposals
FOR SELECT
TO authenticated
USING (
    delivery_request_id IN (
        SELECT id FROM public.delivery_requests WHERE user_id = auth.uid()
    )
);

-- Delivery tasks policies
CREATE POLICY "runners_manage_own_delivery_tasks"
ON public.delivery_tasks
FOR ALL
TO authenticated
USING (
    runner_id = (
        SELECT rp.id FROM public.runner_profiles rp 
        JOIN public.user_sub_profiles usp ON rp.user_profile_id = usp.id
        WHERE usp.user_id = auth.uid()
    )
)
WITH CHECK (
    runner_id = (
        SELECT rp.id FROM public.runner_profiles rp 
        JOIN public.user_sub_profiles usp ON rp.user_profile_id = usp.id
        WHERE usp.user_id = auth.uid()
    )
);

-- Users can view tasks for their delivery requests
CREATE POLICY "users_view_tasks_for_their_requests"
ON public.delivery_tasks
FOR SELECT
TO authenticated
USING (
    delivery_request_id IN (
        SELECT id FROM public.delivery_requests WHERE user_id = auth.uid()
    )
);

-- Delivery chat messages policies
CREATE POLICY "users_manage_delivery_chat_messages"
ON public.delivery_chat_messages
FOR ALL
TO authenticated
USING (sender_id = auth.uid())
WITH CHECK (sender_id = auth.uid());

-- Users and runners can view messages for their delivery requests
CREATE POLICY "participants_view_delivery_chat_messages"
ON public.delivery_chat_messages
FOR SELECT
TO authenticated
USING (
    delivery_request_id IN (
        SELECT dr.id FROM public.delivery_requests dr 
        WHERE dr.user_id = auth.uid() 
        OR dr.assigned_runner_id = (
            SELECT rp.id FROM public.runner_profiles rp 
            JOIN public.user_sub_profiles usp ON rp.user_profile_id = usp.id
            WHERE usp.user_id = auth.uid()
        )
    )
);

-- Delivery notifications policies
CREATE POLICY "users_manage_own_delivery_notifications"
ON public.delivery_notifications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Runner earnings policies
CREATE POLICY "runners_view_own_earnings"
ON public.runner_earnings
FOR SELECT
TO authenticated
USING (
    runner_id = (
        SELECT rp.id FROM public.runner_profiles rp 
        JOIN public.user_sub_profiles usp ON rp.user_profile_id = usp.id
        WHERE usp.user_id = auth.uid()
    )
);

-- 11. Create helpful functions
CREATE OR REPLACE FUNCTION public.update_delivery_request_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update the parent delivery request status when task status changes
    IF TG_TABLE_NAME = 'delivery_tasks' THEN
        UPDATE public.delivery_requests 
        SET status = NEW.task_status, updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.delivery_request_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger to sync delivery request status
CREATE TRIGGER on_delivery_task_status_update
    AFTER UPDATE OF task_status ON public.delivery_tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.update_delivery_request_status();

-- Function to expire old proposals
CREATE OR REPLACE FUNCTION public.expire_old_proposals()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE public.runner_proposals 
    SET status = 'expired'::public.proposal_status
    WHERE status = 'pending'::public.proposal_status 
    AND expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$;

-- 12. Create mock data for testing
DO $$
DECLARE
    existing_user_id UUID;
    existing_runner_profile_id UUID;
    delivery_request_1 UUID := gen_random_uuid();
    delivery_request_2 UUID := gen_random_uuid();
    proposal_1 UUID := gen_random_uuid();
    proposal_2 UUID := gen_random_uuid();
BEGIN
    -- Get existing user and runner profile
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    SELECT id INTO existing_runner_profile_id FROM public.runner_profiles LIMIT 1;

    IF existing_user_id IS NOT NULL THEN
        -- Create sample delivery requests
        INSERT INTO public.delivery_requests (
            id, user_id, title, description, pickup_address, delivery_address,
            urgency, max_budget, status, package_size, recipient_name, recipient_phone
        ) VALUES
            (delivery_request_1, existing_user_id, 'Urgent Medicine Delivery', 
             'Need to deliver prescription medicine to elderly patient', 
             'RIPAS Hospital, Bandar Seri Begawan', 'Kampong Ayer, Bandar Seri Begawan',
             'urgent', 15.00, 'awaiting_runner', 'small', 'Haji Ahmad', '+673 123 4567'),
            (delivery_request_2, existing_user_id, 'Birthday Cake Delivery',
             'Surprise birthday cake for my daughter',
             'Secret Recipe, Gadong', 'Jerudong Park, Jerudong',
             'medium', 25.00, 'awaiting_runner', 'medium', 'Sarah Ali', '+673 234 5678');

        -- Create sample proposals if runner profile exists
        IF existing_runner_profile_id IS NOT NULL THEN
            INSERT INTO public.runner_proposals (
                id, delivery_request_id, runner_id, proposed_fee, estimated_duration,
                message, expires_at
            ) VALUES
                (proposal_1, delivery_request_1, existing_runner_profile_id, 12.00, 30,
                 'I can handle this urgent delivery quickly. I am near RIPAS Hospital.',
                 CURRENT_TIMESTAMP + INTERVAL '2 hours'),
                (proposal_2, delivery_request_2, existing_runner_profile_id, 20.00, 45,
                 'I have experience with cake deliveries and will handle it carefully.',
                 CURRENT_TIMESTAMP + INTERVAL '4 hours');
        END IF;

        -- Create sample notifications
        INSERT INTO public.delivery_notifications (
            user_id, delivery_request_id, title, body, notification_type
        ) VALUES
            (existing_user_id, delivery_request_1, 'New Proposal Received', 
             'A runner has submitted a proposal for your urgent medicine delivery',
             'new_proposal'),
            (existing_user_id, delivery_request_2, 'New Proposal Received',
             'A runner has submitted a proposal for your birthday cake delivery',
             'new_proposal');

        RAISE NOTICE 'Sample delivery system data created successfully';
    ELSE
        RAISE NOTICE 'No existing users found. Create users first to generate delivery system test data.';
    END IF;
END $$;
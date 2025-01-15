-- Create a function to check if a user is a dispatcher
CREATE OR REPLACE FUNCTION is_dispatcher(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = user_id
        AND (
            email LIKE '%@ovgi.com'
            OR raw_user_meta_data->>'role' = 'dispatcher'
        )
    );
END;
$$;

-- Update RLS policies for drivers table
DROP POLICY IF EXISTS "Authenticated users can view drivers" ON drivers;
DROP POLICY IF EXISTS "Users can update their own driver profile" ON drivers;

-- Dispatchers have full access to drivers table
CREATE POLICY "Dispatchers have full access to drivers" ON drivers
    FOR ALL
    TO authenticated
    USING (is_dispatcher(auth.uid()))
    WITH CHECK (is_dispatcher(auth.uid()));

-- Drivers can view their own profile
CREATE POLICY "Drivers can view their own profile" ON drivers
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid() OR is_dispatcher(auth.uid()));

-- Update RLS policies for active_delivery_runs
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON active_delivery_runs;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON active_delivery_runs;
DROP POLICY IF EXISTS "Enable update access for authenticated users" ON active_delivery_runs;
DROP POLICY IF EXISTS "Enable delete access for authenticated users" ON active_delivery_runs;

-- Dispatchers have full access to active_delivery_runs
CREATE POLICY "Dispatchers have full access to runs" ON active_delivery_runs
    FOR ALL
    TO authenticated
    USING (is_dispatcher(auth.uid()))
    WITH CHECK (is_dispatcher(auth.uid()));

-- Drivers can view their assigned runs
CREATE POLICY "Drivers can view their assigned runs" ON active_delivery_runs
    FOR SELECT
    TO authenticated
    USING (fl_driver_id IN (
        SELECT id FROM drivers WHERE user_id = auth.uid()
    ) OR is_dispatcher(auth.uid()));

-- Create function to add a new driver user
CREATE OR REPLACE FUNCTION create_driver_user(
    p_email text,
    p_first_name text,
    p_last_name text,
    p_has_cdl boolean DEFAULT false,
    p_cdl_number text DEFAULT null,
    p_cdl_expiration_date date DEFAULT null
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid;
    v_driver_id uuid;
BEGIN
    -- Check if caller is a dispatcher
    IF NOT is_dispatcher(auth.uid()) THEN
        RAISE EXCEPTION 'Only dispatchers can create driver users';
    END IF;

    -- Create auth user
    v_user_id := auth.uid();
    
    -- Create driver record
    INSERT INTO drivers (
        user_id,
        email,
        first_name,
        last_name,
        has_cdl,
        cdl_number,
        cdl_expiration_date,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        v_user_id,
        p_email,
        p_first_name,
        p_last_name,
        p_has_cdl,
        p_cdl_number,
        p_cdl_expiration_date,
        true,
        now(),
        now()
    ) RETURNING id INTO v_driver_id;

    RETURN v_driver_id;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION is_dispatcher TO authenticated;
GRANT EXECUTE ON FUNCTION create_driver_user TO authenticated;

-- Update existing RLS policies for any other tables that need dispatcher access
DO $$
DECLARE
    v_table text;
BEGIN
    FOR v_table IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public')
    LOOP
        EXECUTE format('
            DROP POLICY IF EXISTS "Dispatchers have full access" ON %I;
            CREATE POLICY "Dispatchers have full access" ON %I
                FOR ALL
                TO authenticated
                USING (is_dispatcher(auth.uid()))
                WITH CHECK (is_dispatcher(auth.uid()));
        ', v_table, v_table);
    END LOOP;
END;
$$;

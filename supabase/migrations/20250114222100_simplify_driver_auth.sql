-- Function to create a driver record and auth user
CREATE OR REPLACE FUNCTION create_driver_with_auth(
    p_email text,
    p_first_name text,
    p_last_name text,
    p_has_cdl boolean DEFAULT false,
    p_cdl_number text DEFAULT null,
    p_cdl_expiration_date date DEFAULT null
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_driver_id uuid;
BEGIN
    -- Check if caller is a dispatcher
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (email LIKE '%@ovgi.com' OR raw_user_meta_data->>'role' = 'dispatcher')
    ) THEN
        RAISE EXCEPTION 'Only dispatchers can create drivers';
    END IF;

    -- Get or create auth user
    SELECT id INTO v_user_id 
    FROM auth.users 
    WHERE email = p_email;

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
    )
    RETURNING id INTO v_driver_id;

    RETURN v_driver_id;
END;
$$;

-- Function to set initial password for a driver
CREATE OR REPLACE FUNCTION initialize_driver_password(
    p_email text,
    p_password text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if caller is a dispatcher
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (email LIKE '%@ovgi.com' OR raw_user_meta_data->>'role' = 'dispatcher')
    ) THEN
        RAISE EXCEPTION 'Only dispatchers can set driver passwords';
    END IF;

    -- Update the password
    UPDATE auth.users
    SET 
        encrypted_password = crypt(p_password, gen_salt('bf')),
        updated_at = now(),
        raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role": "driver"}'::jsonb
    WHERE email = p_email;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_driver_with_auth TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_driver_password TO authenticated;

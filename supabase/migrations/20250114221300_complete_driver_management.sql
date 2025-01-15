-- Function to create both auth user and driver record
CREATE OR REPLACE FUNCTION create_driver_user(
    p_email text,
    p_first_name text,
    p_last_name text,
    p_password text,
    p_has_cdl boolean DEFAULT false,
    p_cdl_number text DEFAULT null,
    p_cdl_expiration_date date DEFAULT null
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
    v_driver_id uuid;
BEGIN
    -- Check if user is a dispatcher
    IF NOT auth.is_dispatcher() THEN
        RAISE EXCEPTION 'Only dispatchers can create drivers';
    END IF;

    -- Create auth user first
    v_user_id := auth.uid();
    
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        p_email,
        crypt(p_password, gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider": "email", "providers": ["email"]}',
        jsonb_build_object(
            'first_name', p_first_name,
            'last_name', p_last_name,
            'role', 'driver'
        ),
        now(),
        now(),
        encode(gen_random_bytes(32), 'base64'),
        p_email,
        encode(gen_random_bytes(32), 'base64'),
        encode(gen_random_bytes(32), 'base64')
    )
    RETURNING id INTO v_user_id;

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

    RETURN json_build_object(
        'user_id', v_user_id,
        'driver_id', v_driver_id
    );
END;
$$;

-- Function to update user password (for dispatchers only)
CREATE OR REPLACE FUNCTION update_driver_password(
    p_driver_id uuid,
    p_new_password text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
BEGIN
    -- Check if user is a dispatcher
    IF NOT auth.is_dispatcher() THEN
        RAISE EXCEPTION 'Only dispatchers can update driver passwords';
    END IF;

    -- Get user_id from driver record
    SELECT user_id INTO v_user_id
    FROM drivers
    WHERE id = p_driver_id;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;

    -- Update password in auth.users
    UPDATE auth.users
    SET 
        encrypted_password = crypt(p_new_password, gen_salt('bf')),
        updated_at = now()
    WHERE id = v_user_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_driver_user TO authenticated;
GRANT EXECUTE ON FUNCTION update_driver_password TO authenticated;

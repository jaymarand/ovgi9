-- Drop existing functions
DROP FUNCTION IF EXISTS update_password(text, text);
DROP FUNCTION IF EXISTS create_driver(text, text, text, boolean, text, date);

-- Function to create both auth user and driver record
CREATE OR REPLACE FUNCTION create_driver(
    p_email text,
    p_password text,
    p_first_name text,
    p_last_name text,
    p_has_cdl boolean DEFAULT false,
    p_cdl_number text DEFAULT null,
    p_cdl_expiration_date date DEFAULT null
) RETURNS jsonb
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

    -- Create auth user
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at
    )
    VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        p_email,
        crypt(p_password, gen_salt('bf')),
        now(),
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        jsonb_build_object(
            'role', 'driver',
            'first_name', p_first_name,
            'last_name', p_last_name
        ),
        now(),
        now()
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

    RETURN jsonb_build_object(
        'user_id', v_user_id,
        'driver_id', v_driver_id,
        'email', p_email
    );
END;
$$;

-- Function to update password
CREATE OR REPLACE FUNCTION update_password(
    user_email text,
    new_password text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
BEGIN
    -- Check if caller is a dispatcher
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (email LIKE '%@ovgi.com' OR raw_user_meta_data->>'role' = 'dispatcher')
    ) THEN
        RAISE EXCEPTION 'Only dispatchers can update passwords';
    END IF;

    -- Get the user ID
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = user_email;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No user found with email %', user_email;
    END IF;

    -- Update the password
    UPDATE auth.users
    SET 
        encrypted_password = crypt(new_password, gen_salt('bf')),
        updated_at = now()
    WHERE id = v_user_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_driver TO authenticated;
GRANT EXECUTE ON FUNCTION update_password TO authenticated;

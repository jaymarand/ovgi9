-- Drop existing functions to avoid conflicts
DROP FUNCTION IF EXISTS create_driver_user(text,text,text,text,boolean,text,date);
DROP FUNCTION IF EXISTS update_driver_password(uuid,text);
DROP FUNCTION IF EXISTS create_new_driver(text,text,text,boolean,text,date);

-- Step 1: Create auth user function
CREATE OR REPLACE FUNCTION create_auth_user(
    auth_email text,
    auth_password text,
    user_metadata jsonb
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid;
BEGIN
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
        auth_email,
        crypt(auth_password, gen_salt('bf')),
        now(),
        '{"provider": "email", "providers": ["email"]}',
        user_metadata,
        now(),
        now()
    )
    RETURNING id INTO v_user_id;

    RETURN v_user_id;
END;
$$;

-- Step 2: Create driver record function
CREATE OR REPLACE FUNCTION create_driver_record(
    driver_user_id uuid,
    driver_email text,
    driver_first_name text,
    driver_last_name text,
    driver_has_cdl boolean DEFAULT false,
    driver_cdl_number text DEFAULT null,
    driver_cdl_expiration_date date DEFAULT null
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_driver_id uuid;
BEGIN
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
        driver_user_id,
        driver_email,
        driver_first_name,
        driver_last_name,
        driver_has_cdl,
        driver_cdl_number,
        driver_cdl_expiration_date,
        true,
        now(),
        now()
    )
    RETURNING id INTO v_driver_id;

    RETURN v_driver_id;
END;
$$;

-- Step 3: Main function to create driver with auth user
CREATE OR REPLACE FUNCTION register_new_driver(
    p_email text,
    p_first_name text,
    p_last_name text,
    p_initial_password text,
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
        RAISE EXCEPTION 'Only dispatchers can register new drivers';
    END IF;

    -- Create auth user
    v_user_id := create_auth_user(
        p_email,
        p_initial_password,
        jsonb_build_object(
            'first_name', p_first_name,
            'last_name', p_last_name,
            'role', 'driver'
        )
    );

    -- Create driver record
    v_driver_id := create_driver_record(
        v_user_id,
        p_email,
        p_first_name,
        p_last_name,
        p_has_cdl,
        p_cdl_number,
        p_cdl_expiration_date
    );

    RETURN jsonb_build_object(
        'user_id', v_user_id,
        'driver_id', v_driver_id
    );
END;
$$;

-- Step 4: Function to update password
CREATE OR REPLACE FUNCTION set_driver_password(
    driver_id uuid,
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
        RAISE EXCEPTION 'Only dispatchers can set driver passwords';
    END IF;

    -- Get user_id from driver record
    SELECT user_id INTO v_user_id
    FROM drivers
    WHERE id = driver_id;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Driver not found';
    END IF;

    -- Update password
    UPDATE auth.users
    SET 
        encrypted_password = crypt(new_password, gen_salt('bf')),
        updated_at = now()
    WHERE id = v_user_id;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION register_new_driver TO authenticated;
GRANT EXECUTE ON FUNCTION set_driver_password TO authenticated;

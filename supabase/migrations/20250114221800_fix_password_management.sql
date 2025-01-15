-- Drop existing function
DROP FUNCTION IF EXISTS set_driver_password(uuid, text);

-- Create improved password management function
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
    v_exists boolean;
BEGIN
    -- Check if caller is a dispatcher
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (email LIKE '%@ovgi.com' OR raw_user_meta_data->>'role' = 'dispatcher')
    ) THEN
        RAISE EXCEPTION 'Only dispatchers can set driver passwords';
    END IF;

    -- Check if driver exists
    SELECT EXISTS (
        SELECT 1 FROM drivers WHERE id = driver_id
    ) INTO v_exists;

    IF NOT v_exists THEN
        RAISE EXCEPTION 'Driver with ID % not found', driver_id;
    END IF;

    -- Get user_id from driver record
    SELECT user_id INTO v_user_id
    FROM drivers
    WHERE id = driver_id;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No auth user associated with driver %', driver_id;
    END IF;

    -- Check if auth user exists
    SELECT EXISTS (
        SELECT 1 FROM auth.users WHERE id = v_user_id
    ) INTO v_exists;

    IF NOT v_exists THEN
        RAISE EXCEPTION 'Auth user % not found', v_user_id;
    END IF;

    -- Update password
    UPDATE auth.users
    SET 
        encrypted_password = crypt(new_password, gen_salt('bf')),
        updated_at = now()
    WHERE id = v_user_id;

    -- Log the password change
    INSERT INTO auth.audit_log_entries (
        instance_id,
        id,
        payload,
        created_at,
        ip_address
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        jsonb_build_object(
            'action', 'password_change',
            'actor', auth.uid(),
            'target', v_user_id
        ),
        now(),
        '127.0.0.1'
    );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION set_driver_password TO authenticated;

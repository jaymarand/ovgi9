-- Drop ALL existing password functions to avoid conflicts
DROP FUNCTION IF EXISTS set_driver_password(uuid, text);
DROP FUNCTION IF EXISTS set_driver_password(text, text);
DROP FUNCTION IF EXISTS initialize_driver_password(text, text);
DROP FUNCTION IF EXISTS update_driver_password(uuid, text);
DROP FUNCTION IF EXISTS create_driver_user(text, text, text, text, boolean, text, date);
DROP FUNCTION IF EXISTS register_new_driver(text, text, text, text, boolean, text, date);
DROP FUNCTION IF EXISTS create_driver_with_auth(text, text, text, boolean, text, date);

-- Create a single, clean password update function
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_password TO authenticated;

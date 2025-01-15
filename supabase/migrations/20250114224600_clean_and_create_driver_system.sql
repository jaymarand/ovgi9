-- Drop all existing functions with any possible signature
DROP FUNCTION IF EXISTS create_driver(text, text, text, text, boolean, text, date);
DROP FUNCTION IF EXISTS create_driver(text, text, text, text);
DROP FUNCTION IF EXISTS create_driver(text, text, text);
DROP FUNCTION IF EXISTS create_driver_record(uuid, text, text, text, boolean, text, date);
DROP FUNCTION IF EXISTS create_driver_record(uuid, text, text, text);
DROP FUNCTION IF EXISTS update_password(text, text);
DROP FUNCTION IF EXISTS set_driver_password(uuid, text);
DROP FUNCTION IF EXISTS set_driver_password(text, text);

-- Drop and recreate the drivers table
DROP TABLE IF EXISTS drivers CASCADE;

CREATE TABLE drivers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id),
    email text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    has_cdl boolean NOT NULL DEFAULT false,
    cdl_number text,
    cdl_expiration_date date,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create indexes
CREATE INDEX drivers_user_id_idx ON drivers(user_id);
CREATE INDEX drivers_email_idx ON drivers(email);
CREATE UNIQUE INDEX drivers_email_unique_idx ON drivers(email);

-- Set up RLS policies
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- View policy: Admins and dispatchers can view all, drivers can view their own
CREATE POLICY "View drivers policy"
ON drivers FOR SELECT
TO authenticated
USING (
    (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id = auth.uid() 
            AND (
                raw_user_meta_data->>'role' = 'dispatcher' OR 
                raw_user_meta_data->>'role' = 'admin'
            )
        )
    ) OR 
    auth.uid() = user_id
);

-- Insert policy: Admins and dispatchers can create
CREATE POLICY "Create drivers policy"
ON drivers FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (
            raw_user_meta_data->>'role' = 'dispatcher' OR 
            raw_user_meta_data->>'role' = 'admin'
        )
    )
);

-- Update policy: Admins and dispatchers can update
CREATE POLICY "Update drivers policy"
ON drivers FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (
            raw_user_meta_data->>'role' = 'dispatcher' OR 
            raw_user_meta_data->>'role' = 'admin'
        )
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (
            raw_user_meta_data->>'role' = 'dispatcher' OR 
            raw_user_meta_data->>'role' = 'admin'
        )
    )
);

-- Delete policy: Admins and dispatchers can delete
CREATE POLICY "Delete drivers policy"
ON drivers FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (
            raw_user_meta_data->>'role' = 'dispatcher' OR 
            raw_user_meta_data->>'role' = 'admin'
        )
    )
);

-- Create the driver management function
CREATE OR REPLACE FUNCTION manage_driver(
    p_email text,
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
    v_password text;
BEGIN
    -- Check if caller is a dispatcher or admin
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = auth.uid() 
        AND (
            raw_user_meta_data->>'role' = 'dispatcher' OR 
            raw_user_meta_data->>'role' = 'admin'
        )
    ) THEN
        RAISE EXCEPTION 'Only dispatchers and admins can create drivers';
    END IF;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email already exists';
    END IF;

    -- Generate a random password
    v_password := encode(gen_random_bytes(12), 'base64');

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
        crypt(v_password, gen_salt('bf')),
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

    -- Create auth identity
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        created_at,
        updated_at
    )
    VALUES (
        v_user_id,
        v_user_id,
        jsonb_build_object('sub', v_user_id::text),
        'email',
        now(),
        now()
    );

    RETURN jsonb_build_object(
        'user_id', v_user_id,
        'driver_id', v_driver_id,
        'email', p_email,
        'password', v_password
    );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION manage_driver TO authenticated;

-- Grant permissions on drivers table
GRANT ALL ON drivers TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON drivers TO authenticated;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Drop existing objects
DROP TABLE IF EXISTS drivers CASCADE;
DROP FUNCTION IF EXISTS create_driver_with_auth CASCADE;

-- Create the drivers table
CREATE TABLE drivers (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Drivers can view own record" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers and admins can insert" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers and admins can update" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers and admins can delete" ON drivers;

-- Create RLS policies
CREATE POLICY "Drivers can view own record"
    ON drivers FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND (
                raw_user_meta_data->>'role' = 'dispatcher' OR
                raw_user_meta_data->>'role' = 'admin'
            )
        )
    );

CREATE POLICY "Only dispatchers and admins can insert"
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

CREATE POLICY "Only dispatchers and admins can update"
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

CREATE POLICY "Only dispatchers and admins can delete"
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

-- Create an index on the role metadata for better performance
CREATE INDEX IF NOT EXISTS idx_users_role ON auth.users USING gin ((raw_user_meta_data->'role'));

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create updated_at trigger
CREATE TRIGGER update_drivers_updated_at
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- Function to create a driver with auth
CREATE OR REPLACE FUNCTION create_driver_with_auth(
    p_email text,
    p_first_name text,
    p_last_name text,
    p_has_cdl boolean DEFAULT false,
    p_cdl_number text DEFAULT null,
    p_cdl_expiration_date date DEFAULT null,
    p_user_id uuid DEFAULT null
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_driver_id uuid;
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

    -- Check if email already exists in drivers table
    IF EXISTS (SELECT 1 FROM drivers WHERE email = p_email) THEN
        RAISE EXCEPTION 'Driver with this email already exists';
    END IF;

    -- Validate CDL data
    IF p_has_cdl AND (p_cdl_number IS NULL OR p_cdl_expiration_date IS NULL) THEN
        RAISE EXCEPTION 'CDL number and expiration date are required when has_cdl is true';
    END IF;

    -- Create driver record
    INSERT INTO drivers (
        email,
        first_name,
        last_name,
        has_cdl,
        cdl_number,
        cdl_expiration_date,
        is_active,
        user_id
    ) VALUES (
        p_email,
        p_first_name,
        p_last_name,
        p_has_cdl,
        CASE WHEN p_has_cdl THEN p_cdl_number ELSE NULL END,
        CASE WHEN p_has_cdl THEN p_cdl_expiration_date ELSE NULL END,
        true,
        p_user_id
    )
    RETURNING id INTO v_driver_id;

    RETURN jsonb_build_object(
        'driver_id', v_driver_id,
        'email', p_email,
        'success', true
    );
END;
$$;

-- Function to create a driver and auth user
CREATE OR REPLACE FUNCTION create_driver_and_user(
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

    -- Create auth user
    v_user_id := gen_random_uuid();
    
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        role,
        confirmation_token
    )
    VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000',
        p_email,
        crypt(p_password, gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object(
            'role', 'driver',
            'first_name', p_first_name,
            'last_name', p_last_name
        ),
        now(),
        now(),
        'authenticated',
        encode(gen_random_bytes(32), 'base64')
    );

    -- Create identities record
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
        jsonb_build_object(
            'sub', v_user_id::text,
            'email', p_email
        ),
        'email',
        now(),
        now()
    );

    -- Create driver record
    INSERT INTO drivers (
        email,
        first_name,
        last_name,
        has_cdl,
        cdl_number,
        cdl_expiration_date,
        is_active,
        user_id
    ) VALUES (
        p_email,
        p_first_name,
        p_last_name,
        p_has_cdl,
        CASE WHEN p_has_cdl THEN p_cdl_number ELSE NULL END,
        CASE WHEN p_has_cdl THEN p_cdl_expiration_date ELSE NULL END,
        true,
        v_user_id
    )
    RETURNING id INTO v_driver_id;

    RETURN jsonb_build_object(
        'user_id', v_user_id,
        'driver_id', v_driver_id,
        'email', p_email,
        'success', true
    );
END;
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION create_driver_and_user TO authenticated;

-- Function to link driver to auth user
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    -- If the new user has role 'driver', link them to their driver record
    IF NEW.raw_user_meta_data->>'role' = 'driver' THEN
        UPDATE drivers 
        SET user_id = NEW.id 
        WHERE email = NEW.email 
        AND user_id IS NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE PROCEDURE handle_new_user();

-- Grant necessary permissions
GRANT ALL ON drivers TO postgres, authenticated;

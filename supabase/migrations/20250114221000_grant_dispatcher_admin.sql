-- First, let's create a simpler function to check if user is a dispatcher
CREATE OR REPLACE FUNCTION auth.is_dispatcher()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM auth.users
    WHERE id = auth.uid()
    AND (
      email LIKE '%@ovgi.com'
      OR raw_user_meta_data->>'role' = 'dispatcher'
    )
  );
$$;

-- Grant dispatchers access to all tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;

-- Simple policy for drivers table
DROP POLICY IF EXISTS "Dispatchers have full access to drivers" ON drivers;
DROP POLICY IF EXISTS "Drivers can view their own profile" ON drivers;

CREATE POLICY "Enable full access for dispatchers" ON drivers
  FOR ALL 
  TO authenticated
  USING (auth.is_dispatcher())
  WITH CHECK (auth.is_dispatcher());

-- Create a function to add a new driver that any dispatcher can use
CREATE OR REPLACE FUNCTION public.create_new_driver(
  p_email text,
  p_first_name text,
  p_last_name text,
  p_has_cdl boolean DEFAULT false,
  p_cdl_number text DEFAULT null,
  p_cdl_expiration_date date DEFAULT null
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_driver_id uuid;
BEGIN
  -- Check if user is a dispatcher
  IF NOT auth.is_dispatcher() THEN
    RAISE EXCEPTION 'Only dispatchers can create new drivers';
  END IF;

  -- Insert the new driver
  INSERT INTO public.drivers (
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

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.create_new_driver TO authenticated;

-- Simple policy for active_delivery_runs
DROP POLICY IF EXISTS "Dispatchers have full access to runs" ON active_delivery_runs;
DROP POLICY IF EXISTS "Drivers can view their assigned runs" ON active_delivery_runs;

CREATE POLICY "Enable full access for dispatchers" ON active_delivery_runs
  FOR ALL 
  TO authenticated
  USING (auth.is_dispatcher())
  WITH CHECK (auth.is_dispatcher());

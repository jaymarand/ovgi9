/*
  # Fix User Roles Policies

  1. Changes
    - Drop existing policies that may cause recursion
    - Create simplified policies using JWT claims directly
    - Remove circular policy dependencies

  2. Security
    - Maintain role-based access control
    - Use JWT claims for role checks
    - Keep existing functionality but implement more efficiently
*/

-- First drop all existing policies from user_roles
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_roles'
  ) THEN
    DROP POLICY IF EXISTS "Allow users to view own role" ON user_roles;
    DROP POLICY IF EXISTS "Allow dispatchers full access" ON user_roles;
  END IF;
END $$;

-- Create new simplified policies that avoid recursion
CREATE POLICY "Enable read access for authenticated users"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable write access for dispatchers"
  ON user_roles
  FOR INSERT UPDATE DELETE
  TO authenticated
  USING (
    current_setting('request.jwt.claims', true)::jsonb -> 'user_metadata' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    current_setting('request.jwt.claims', true)::jsonb -> 'user_metadata' ->> 'role' = 'dispatcher'
  );

-- Update the handle_new_user function to be more robust
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'driver')
  )
  ON CONFLICT (user_id) 
  DO UPDATE SET
    role = EXCLUDED.role,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
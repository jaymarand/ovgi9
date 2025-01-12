/*
  # Fix User Roles Recursion

  1. Changes
    - Drop existing policies that may cause recursion
    - Create simplified policies using direct JWT claims
    - Remove circular dependencies in policy checks

  2. Security
    - Maintain role-based access control
    - Use JWT claims directly instead of recursive checks
    - Keep existing functionality with improved performance
*/

-- First drop existing policies
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_roles'
  ) THEN
    DROP POLICY IF EXISTS "Enable read access for authenticated users" ON user_roles;
    DROP POLICY IF EXISTS "Enable write access for dispatchers" ON user_roles;
  END IF;
END $$;

-- Create new simplified policies
CREATE POLICY "Allow read access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow dispatcher management"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    current_setting('request.jwt.claim.raw_user_meta_data')::jsonb->>'role' = 'dispatcher'
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
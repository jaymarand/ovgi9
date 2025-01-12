/*
  # Fix User Roles Policies

  1. Changes
    - Drop existing policies safely
    - Recreate policies with proper checks
    - Add admin privileges for dispatchers
    - Update helper functions

  2. Security
    - Maintain RLS
    - Ensure proper role-based access
*/

-- First drop existing policies safely
DO $$ 
BEGIN
  -- Drop user_roles policies if they exist
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_roles' 
    AND policyname = 'Users can view their own role'
  ) THEN
    DROP POLICY "Users can view their own role" ON user_roles;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_roles' 
    AND policyname = 'Dispatchers can manage all roles'
  ) THEN
    DROP POLICY "Dispatchers can manage all roles" ON user_roles;
  END IF;
END $$;

-- Create new policies for user_roles
CREATE POLICY "Enable users to view own role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Enable dispatchers to manage all roles"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'dispatcher'
    )
  );

-- Update helper functions
CREATE OR REPLACE FUNCTION is_dispatcher()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND role = 'dispatcher'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_role()
RETURNS text AS $$
BEGIN
  RETURN (
    SELECT role FROM user_roles
    WHERE user_id = auth.uid()
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
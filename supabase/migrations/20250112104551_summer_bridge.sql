/*
  # Fix User Roles Recursion

  1. Changes
    - Remove recursive policies that were causing infinite recursion
    - Use JWT metadata directly for role checks
    - Simplify policy structure
    - Keep existing data and functionality intact

  2. Security
    - Maintain RLS protection
    - Keep dispatcher privileges
    - Prevent policy recursion
*/

-- Drop existing policies from user_roles
DROP POLICY IF EXISTS "Enable read access for own role" ON user_roles;
DROP POLICY IF EXISTS "Enable dispatcher access" ON user_roles;

-- Create new simplified policies using JWT metadata
CREATE POLICY "Allow users to view own role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Allow dispatchers full access"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  );

-- Update store_supplies policies to use JWT metadata directly
DROP POLICY IF EXISTS "Enable dispatcher management" ON store_supplies;
CREATE POLICY "Allow dispatchers to manage supplies"
  ON store_supplies
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  );

-- Update daily_container_counts policies
DROP POLICY IF EXISTS "Enable dispatcher management for counts" ON daily_container_counts;
CREATE POLICY "Allow dispatchers to manage container counts"
  ON daily_container_counts
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  );
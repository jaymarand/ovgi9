/*
  # Fix User Roles Policies

  1. Changes
    - Remove recursive policies from user_roles table
    - Use auth.jwt() metadata for role checks instead of querying user_roles
    - Simplify policy structure

  2. Security
    - Maintain RLS
    - Keep dispatcher privileges
    - Prevent infinite recursion
*/

-- Drop existing policies from user_roles
DROP POLICY IF EXISTS "Enable users to view own role" ON user_roles;
DROP POLICY IF EXISTS "Enable dispatchers to manage all roles" ON user_roles;

-- Create new non-recursive policies
CREATE POLICY "Enable read access for own role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Enable dispatcher access"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );

-- Update store_supplies policies to use JWT metadata
DROP POLICY IF EXISTS "Dispatchers can manage supplies" ON store_supplies;
CREATE POLICY "Enable dispatcher management"
  ON store_supplies
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );

-- Update daily_container_counts policies
DROP POLICY IF EXISTS "Allow dispatchers to manage container counts" ON daily_container_counts;
CREATE POLICY "Enable dispatcher management for counts"
  ON daily_container_counts
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );
/*
  # Dispatcher Admin Privileges

  1. Changes
    - Add admin privileges for dispatchers
    - Update policies to give dispatchers full access to all tables
    - Add policies for managing user roles and data

  2. Security
    - Ensure dispatchers can manage all aspects of the system
    - Maintain existing RLS for drivers
*/

-- Update user_roles policies to give dispatchers full access
DROP POLICY IF EXISTS "Dispatchers can view all roles" ON user_roles;
CREATE POLICY "Dispatchers can manage all roles"
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

-- Update store_supplies policies
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;
CREATE POLICY "Dispatchers can manage supplies"
  ON store_supplies
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'dispatcher'
    )
  );

-- Update daily_container_counts policies
DROP POLICY IF EXISTS "Allow authenticated users to insert container counts" ON daily_container_counts;
DROP POLICY IF EXISTS "Allow authenticated users to read container counts" ON daily_container_counts;

CREATE POLICY "Allow users to insert container counts"
  ON daily_container_counts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow users to read container counts"
  ON daily_container_counts
  FOR SELECT
  TO
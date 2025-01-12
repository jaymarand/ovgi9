/*
  # Fix Container Counts Policies

  1. Changes
    - Complete the incomplete policies from violet migration
    - Add proper access control for container counts
    - Ensure dispatchers have full access

  2. Security
    - Maintain RLS
    - Allow users to submit counts
    - Allow dispatchers full access
*/

-- Update daily_container_counts policies
DROP POLICY IF EXISTS "Allow users to insert container counts" ON daily_container_counts;
DROP POLICY IF EXISTS "Allow users to read container counts" ON daily_container_counts;

-- Create new policies for daily_container_counts
CREATE POLICY "Allow users to insert container counts"
  ON daily_container_counts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow users to read container counts"
  ON daily_container_counts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow dispatchers to manage container counts"
  ON daily_container_counts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'dispatcher'
    )
  );

-- Ensure store_supplies has proper dispatcher access
DROP POLICY IF EXISTS "Dispatchers can manage supplies" ON store_supplies;
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
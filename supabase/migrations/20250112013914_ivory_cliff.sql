/*
  # Fix Store Supplies RLS Policies

  1. Changes
    - Drop existing policies
    - Create new policies using correct metadata access
    - Add WITH CHECK clause for write operations
  
  2. Security
    - Maintain read access for all authenticated users
    - Restrict write access to dispatchers only
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;

-- Create new policies with correct metadata access
CREATE POLICY "Allow authenticated read access"
  ON store_supplies
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow dispatchers to modify supplies"
  ON store_supplies
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );
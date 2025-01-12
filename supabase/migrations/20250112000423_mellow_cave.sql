/*
  # Fix store permissions

  1. Changes
    - Drop existing policies
    - Create a simple policy allowing all users to read store data
    - Create a policy for dispatchers to manage stores
  
  2. Security
    - Enables read access for all authenticated users
    - Maintains write access only for dispatchers
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for all users" ON stores;
DROP POLICY IF EXISTS "Enable write access for dispatchers" ON stores;

-- Create new simplified policies
CREATE POLICY "Allow all users to read stores"
  ON stores
  FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow dispatchers to manage stores"
  ON stores
  FOR ALL
  USING (
    auth.role() = 'authenticated' AND
    (auth.jwt() ->> 'role')::text = 'dispatcher'
  );
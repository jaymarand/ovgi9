/*
  # Fix Store Supplies Policies

  1. Changes
    - Drop existing policies
    - Create new simplified policies using JWT claims
    - Remove dependency on auth.users table queries
  
  2. Security
    - Maintain read access for all authenticated users
    - Enable write access for dispatchers using JWT claims
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;

-- Create new policies using JWT claims
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
  );
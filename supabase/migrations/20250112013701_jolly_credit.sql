/*
  # Fix Store Supplies RLS Policies

  1. Changes
    - Drop existing policies
    - Create simplified policies using correct JWT claim path
    - Add separate policies for read and write operations
  
  2. Security
    - Enable read access for all authenticated users
    - Enable write access for dispatchers only using JWT claims
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;

-- Create new policies using correct JWT claim path
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
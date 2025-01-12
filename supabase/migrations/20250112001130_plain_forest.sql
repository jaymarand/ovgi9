/*
  # Fix Store RLS Policies

  1. Changes
    - Drop existing store policies
    - Create new simplified policies that work with the current auth setup
    - Enable read access for all authenticated users
    - Enable write access for dispatchers only

  2. Security
    - Maintains RLS protection
    - Uses correct auth checks
    - Properly handles user roles
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read stores" ON stores;
DROP POLICY IF EXISTS "Allow dispatchers to manage stores" ON stores;

-- Create new policies with simpler, more reliable auth checks
CREATE POLICY "Enable read access for authenticated users"
  ON stores
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable write access for dispatchers"
  ON stores
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() ->> 'user_metadata'->>'role' = 'dispatcher'
  );
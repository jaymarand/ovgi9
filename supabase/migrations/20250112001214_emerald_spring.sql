/*
  # Fix Store Policies Syntax

  1. Changes
    - Drop existing policies
    - Create new policies with correct syntax for role checking
    - Maintain same access rules but with proper JWT metadata access

  2. Security
    - Maintains RLS protection
    - Uses correct syntax for accessing JWT claims
    - Properly handles user roles
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON stores;
DROP POLICY IF EXISTS "Enable write access for dispatchers" ON stores;

-- Create new policies with correct syntax
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
    (auth.jwt() ->> 'raw_user_meta_data')::jsonb ->> 'role' = 'dispatcher'
  );
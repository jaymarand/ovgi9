/*
  # Fix Store Policies

  1. Changes
    - Drop existing store policies
    - Create new policies with correct JWT claim access
    - Fix syntax for role checking

  2. Security
    - Maintains RLS protection
    - Uses correct syntax for accessing user metadata
    - Preserves existing access rules
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON stores;
DROP POLICY IF EXISTS "Enable write access for dispatchers" ON stores;

-- Create new policies with correct syntax for metadata access
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
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );
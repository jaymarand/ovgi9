/*
  # Simplify store access policies

  1. Changes
    - Drop existing complex policies
    - Add single simple policy for authenticated read access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON stores;
DROP POLICY IF EXISTS "Enable write access for dispatchers" ON stores;

-- Create simple read-only policy for authenticated users
CREATE POLICY "Allow authenticated read access"
  ON stores
  FOR SELECT
  TO authenticated
  USING (true);
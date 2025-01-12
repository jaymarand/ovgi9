/*
  # Fix stores table RLS policies
  
  1. Changes
    - Drop existing policies to avoid conflicts
    - Create new policies with correct metadata access
  
  2. Security
    - Enable read access for all authenticated users
    - Enable write access for dispatchers only using raw_user_meta_data
*/

-- First drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated read access" ON stores;
DROP POLICY IF EXISTS "Allow dispatchers to modify stores" ON stores;

-- Create policies with correct metadata access
CREATE POLICY "Allow authenticated read access"
  ON stores
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow dispatchers to modify stores"
  ON stores
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  );
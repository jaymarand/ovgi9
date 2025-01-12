/*
  # Update Store RLS Policies

  1. Changes
    - Drop existing RLS policies for stores table
    - Create new simplified RLS policy for authenticated access
    - Add policy for public read access to stores table
  
  2. Security
    - Enables all authenticated users to read store data
    - Maintains dispatcher-only write access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read stores" ON stores;
DROP POLICY IF EXISTS "Allow dispatchers to manage stores" ON stores;

-- Create new simplified policies
CREATE POLICY "Enable read access for all users"
  ON stores
  FOR SELECT
  USING (true);

CREATE POLICY "Enable write access for dispatchers"
  ON stores
  FOR ALL
  USING (
    auth.role() = 'authenticated' AND
    (
      SELECT raw_user_meta_data->>'role'
      FROM auth.users
      WHERE auth.users.id = auth.uid()
    ) = 'dispatcher'
  )
  WITH CHECK (
    auth.role() = 'authenticated' AND
    (
      SELECT raw_user_meta_data->>'role'
      FROM auth.users
      WHERE auth.users.id = auth.uid()
    ) = 'dispatcher'
  );
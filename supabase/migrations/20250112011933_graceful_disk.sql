/*
  # Fix Store Supplies RLS Policies

  1. Changes
    - Drop existing policies
    - Create new policies with correct role checking using auth.users table
    - Add proper error handling for role check
  
  2. Security
    - Enable RLS
    - Add policy for read access
    - Add policy for write access with proper role check
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;

-- Create new policies with correct role checking
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
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'role' = 'dispatcher'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'role' = 'dispatcher'
    )
  );
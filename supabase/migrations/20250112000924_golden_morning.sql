/*
  # Fix Store RLS Policies

  1. Changes
    - Drop existing policies that use incorrect auth checks
    - Create new policies with correct auth and role checks
    - Simplify policy logic for better maintainability

  2. Security
    - Maintain read access for all authenticated users
    - Restrict write access to dispatchers only
    - Use correct metadata access patterns
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow all users to read stores" ON stores;
DROP POLICY IF EXISTS "Allow dispatchers to manage stores" ON stores;

-- Create new policies with correct auth checks
CREATE POLICY "Allow authenticated users to read stores"
  ON stores
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow dispatchers to manage stores"
  ON stores
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.raw_user_meta_data->>'role' = 'dispatcher'
    )
  );
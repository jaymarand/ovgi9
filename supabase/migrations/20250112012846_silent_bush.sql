/*
  # Fix Store Supplies RLS Policies

  1. Changes
    - Drop existing policies
    - Create new policies with simplified role checking
    - Use direct JWT claims access
  
  2. Security
    - Maintain read access for all authenticated users
    - Allow dispatchers to modify data
    - Use simpler, more reliable role checking
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;

-- Create new policies with simplified role checking
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
    coalesce(
      current_setting('request.jwt.claims', true)::jsonb -> 'raw_user_meta_data' ->> 'role',
      current_setting('request.jwt.claim.raw_user_meta_data', true)::jsonb ->> 'role'
    ) = 'dispatcher'
  );
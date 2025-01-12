/*
  # Fix Store Supplies RLS Policies

  1. Changes
    - Drop existing policies
    - Create new policies with direct metadata access
    - Simplify role checking logic
  
  2. Security
    - Maintain read access for all authenticated users
    - Restrict write access to dispatchers only
    - Use raw_user_meta_data for role checking
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;

-- Create new policies with direct metadata access
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
    (current_setting('request.jwt.claim.raw_user_meta_data')::jsonb->>'role')::text = 'dispatcher'
  );
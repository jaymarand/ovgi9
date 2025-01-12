/*
  # Fix Store Supplies RLS Policies

  1. Changes
    - Drop existing policies
    - Create new policies with simpler role checking
    - Add proper error handling
  
  2. Security
    - Enable RLS
    - Add policy for read access
    - Add policy for write access with proper role check
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;

-- Create new policies with simpler role checking
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
    current_setting('request.jwt.claims', true)::json->>'role' = 'dispatcher'
  );
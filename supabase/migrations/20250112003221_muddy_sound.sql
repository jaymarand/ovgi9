/*
  # Add dispatcher write access policy
  
  1. Changes
    - Add policy to allow dispatchers to modify store data
  
  2. Security
    - Only dispatchers can modify store data
    - Policy checks user's role metadata
*/

-- Create policy for dispatcher write access
CREATE POLICY "Allow dispatchers to modify stores"
  ON stores
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );
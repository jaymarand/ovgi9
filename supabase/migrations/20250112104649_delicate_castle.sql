/*
  # Fix Container Counts Policies

  1. Changes
    - Drop existing policies safely
    - Recreate policies with proper checks
    - Use JWT metadata for role checks
    - Maintain existing functionality

  2. Security
    - Keep RLS protection
    - Maintain dispatcher privileges
    - Allow authenticated users to read and insert
*/

-- First drop existing policies safely
DO $$ 
BEGIN
  -- Drop container counts policies if they exist
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'daily_container_counts' 
    AND policyname = 'Allow dispatchers to manage container counts'
  ) THEN
    DROP POLICY "Allow dispatchers to manage container counts" ON daily_container_counts;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'daily_container_counts' 
    AND policyname = 'Allow users to insert container counts'
  ) THEN
    DROP POLICY "Allow users to insert container counts" ON daily_container_counts;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'daily_container_counts' 
    AND policyname = 'Allow users to read container counts'
  ) THEN
    DROP POLICY "Allow users to read container counts" ON daily_container_counts;
  END IF;
END $$;

-- Create new policies with proper checks
CREATE POLICY "Enable read access for all authenticated users"
  ON daily_container_counts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable insert for authenticated users"
  ON daily_container_counts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Enable full access for dispatchers"
  ON daily_container_counts
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' = 'dispatcher'
  );
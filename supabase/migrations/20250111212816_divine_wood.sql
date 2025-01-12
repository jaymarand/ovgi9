/*
  # Fix driver column type in active_delivery_runs table

  1. Changes
    - Modify the driver column to use UUID type
    - Update policies to use the correct type comparison

  2. Security
    - Recreate policies with proper type handling
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Drivers can view their assigned runs" ON active_delivery_runs;
DROP POLICY IF EXISTS "Drivers can update their assigned runs" ON active_delivery_runs;

-- Modify the column type with proper casting
ALTER TABLE active_delivery_runs 
  ALTER COLUMN driver TYPE uuid USING driver::uuid;

-- Recreate policies with correct type handling
CREATE POLICY "Drivers can view their assigned runs"
  ON active_delivery_runs
  FOR SELECT
  TO authenticated
  USING (driver = auth.uid());

CREATE POLICY "Drivers can update their assigned runs"
  ON active_delivery_runs
  FOR UPDATE
  TO authenticated
  USING (driver = auth.uid());
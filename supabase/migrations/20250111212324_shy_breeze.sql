/*
  # Fix driver column reference

  1. Changes
    - Rename `driver_id` to `driver` in active_delivery_runs table
    - Update policies to use the correct column name

  2. Security
    - Update RLS policies to reference the correct column name
*/

-- Rename the column
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'active_delivery_runs' AND column_name = 'driver_id'
  ) THEN
    ALTER TABLE active_delivery_runs RENAME COLUMN driver_id TO driver;
  END IF;
END $$;

-- Drop existing policies that reference the old column name
DROP POLICY IF EXISTS "Drivers can view their assigned runs" ON active_delivery_runs;
DROP POLICY IF EXISTS "Drivers can update their assigned runs" ON active_delivery_runs;

-- Recreate policies with correct column name
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
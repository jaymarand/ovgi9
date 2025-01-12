/*
  # Update daily_container_counts table

  1. Changes
    - Alter existing table instead of dropping
    - Add missing columns and constraints
    - Update column types
    - Add indexes for performance

  2. Security
    - Maintain existing RLS policies
*/

-- First drop the foreign key if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_store_supplies'
    AND table_name = 'daily_container_counts'
  ) THEN
    ALTER TABLE daily_container_counts DROP CONSTRAINT fk_store_supplies;
  END IF;
END $$;

-- Modify arrival_time to be timestamptz
ALTER TABLE daily_container_counts 
  ALTER COLUMN arrival_time TYPE timestamptz 
  USING arrival_time::timestamptz;

-- Add updated_at column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'daily_container_counts'
    AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE daily_container_counts 
      ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Add constraints
ALTER TABLE daily_container_counts
  ADD CONSTRAINT check_donation_count CHECK (donation_count >= 0),
  ADD CONSTRAINT check_trailer_fullness CHECK (trailer_fullness >= 0 AND trailer_fullness <= 100),
  ADD CONSTRAINT check_hardlines_raw CHECK (hardlines_raw >= 0),
  ADD CONSTRAINT check_softlines_raw CHECK (softlines_raw >= 0),
  ADD CONSTRAINT check_canvases CHECK (canvases >= 0),
  ADD CONSTRAINT check_sleeves CHECK (sleeves >= 0),
  ADD CONSTRAINT check_caps CHECK (caps >= 0),
  ADD CONSTRAINT check_totes CHECK (totes >= 0);

-- Add foreign key constraint
ALTER TABLE daily_container_counts
  ADD CONSTRAINT fk_store_supplies 
  FOREIGN KEY (store_id) 
  REFERENCES store_supplies(department_number)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

-- Create updated_at trigger if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_daily_container_counts_updated_at'
  ) THEN
    CREATE TRIGGER update_daily_container_counts_updated_at
      BEFORE UPDATE ON daily_container_counts
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

-- Create indexes if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_daily_container_counts_store_id'
  ) THEN
    CREATE INDEX idx_daily_container_counts_store_id 
      ON daily_container_counts(store_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_daily_container_counts_created_at'
  ) THEN
    CREATE INDEX idx_daily_container_counts_created_at 
      ON daily_container_counts(created_at DESC);
  END IF;
END $$;
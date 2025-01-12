/*
  # Add timestamp columns to stores table

  1. Changes
    - Add created_at and updated_at columns if they don't exist
    - Create trigger for automatically updating updated_at
    - Add indexes for better query performance

  2. Notes
    - Uses IF NOT EXISTS to prevent errors if columns already exist
    - Adds default values using now()
    - Creates trigger to maintain updated_at automatically
*/

-- Add timestamp columns if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE stores ADD COLUMN created_at timestamptz DEFAULT now();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE stores ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Create index for timestamp columns if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_stores_created_at'
  ) THEN
    CREATE INDEX idx_stores_created_at ON stores(created_at);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_stores_updated_at'
  ) THEN
    CREATE INDEX idx_stores_updated_at ON stores(updated_at);
  END IF;
END $$;

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION update_stores_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_stores_updated_at_trigger'
  ) THEN
    CREATE TRIGGER update_stores_updated_at_trigger
      BEFORE UPDATE ON stores
      FOR EACH ROW
      EXECUTE FUNCTION update_stores_updated_at();
  END IF;
END $$;
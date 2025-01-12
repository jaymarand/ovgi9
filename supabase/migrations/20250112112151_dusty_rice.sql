/*
  # Update store_supplies to reference stores table

  1. Changes
    - Drop existing store_supplies table
    - Recreate store_supplies with proper foreign key reference to stores
    - Migrate existing data to new structure
    - Update all dependent tables to use new references

  2. Notes
    - Preserves all existing data
    - Maintains referential integrity
    - Updates foreign key constraints
*/

-- First create a temporary table to store existing data
CREATE TEMP TABLE temp_store_supplies AS 
SELECT * FROM store_supplies;

-- Drop existing store_supplies table
DROP TABLE IF EXISTS store_supplies CASCADE;

-- Create new store_supplies table with proper references
CREATE TABLE store_supplies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id),
  sleeves integer NOT NULL DEFAULT 0,
  caps integer NOT NULL DEFAULT 0,
  canvases integer NOT NULL DEFAULT 0,
  totes integer NOT NULL DEFAULT 0,
  hardlines_raw integer NOT NULL DEFAULT 0,
  softlines_raw integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(store_id)
);

-- Enable RLS
ALTER TABLE store_supplies ENABLE ROW LEVEL SECURITY;

-- Create policies
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
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );

-- Create updated_at trigger
CREATE TRIGGER update_store_supplies_updated_at
  BEFORE UPDATE ON store_supplies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Migrate data from temporary table
INSERT INTO store_supplies (store_id, sleeves, caps, canvases, totes, hardlines_raw, softlines_raw)
SELECT 
  s.id as store_id,
  ts.sleeves,
  ts.caps,
  ts.canvases,
  ts.totes,
  ts.hardlines_raw,
  ts.softlines_raw
FROM temp_store_supplies ts
JOIN stores s ON s.department_number = ts.department_number;

-- Update daily_container_counts to reference stores
ALTER TABLE daily_container_counts 
  DROP CONSTRAINT IF EXISTS fk_store_supplies,
  ADD COLUMN store_uuid uuid,
  ADD CONSTRAINT fk_store FOREIGN KEY (store_uuid) REFERENCES stores(id);

-- Migrate existing daily_container_counts data
UPDATE daily_container_counts dc
SET store_uuid = s.id
FROM stores s
WHERE s.department_number = dc.store_id;

-- Make store_uuid required and drop old store_id
ALTER TABLE daily_container_counts
  ALTER COLUMN store_uuid SET NOT NULL,
  DROP COLUMN store_id;
/*
  # Fix daily container counts table structure

  1. Changes
    - Properly handle column renaming and constraints
    - Maintain data integrity during migration
    - Update foreign key relationships

  2. Notes
    - Uses ALTER TABLE with proper syntax
    - Preserves existing data
    - Maintains referential integrity
*/

-- First add the temporary UUID column
ALTER TABLE daily_container_counts 
  ADD COLUMN temp_store_uuid uuid;

-- Update the temporary column with the correct UUID from stores
UPDATE daily_container_counts dc
SET temp_store_uuid = s.id
FROM stores s
WHERE s.department_number = dc.store_id;

-- Drop existing constraints
ALTER TABLE daily_container_counts
  DROP CONSTRAINT IF EXISTS fk_store_supplies,
  DROP CONSTRAINT IF EXISTS fk_store;

-- Drop old column and add new one
ALTER TABLE daily_container_counts
  DROP COLUMN IF EXISTS store_id CASCADE;

ALTER TABLE daily_container_counts
  ADD COLUMN store_id uuid;

-- Copy data from temporary column
UPDATE daily_container_counts
SET store_id = temp_store_uuid;

-- Drop temporary column
ALTER TABLE daily_container_counts
  DROP COLUMN temp_store_uuid;

-- Make store_id NOT NULL and add foreign key constraint
ALTER TABLE daily_container_counts
  ALTER COLUMN store_id SET NOT NULL,
  ADD CONSTRAINT fk_store 
    FOREIGN KEY (store_id) 
    REFERENCES stores(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

-- Create index for better join performance
CREATE INDEX IF NOT EXISTS idx_daily_container_counts_store_id 
ON daily_container_counts(store_id);
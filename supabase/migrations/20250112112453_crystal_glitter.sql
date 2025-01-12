/*
  # Fix store references and data migration

  1. Changes
    - Add temporary column for storing UUID during migration
    - Update references using proper type casting
    - Clean up temporary columns
    - Ensure referential integrity

  2. Notes
    - Preserves all existing data
    - Maintains relationships between tables
    - Uses safe type conversions
*/

-- First add a temporary UUID column to daily_container_counts
ALTER TABLE daily_container_counts 
  ADD COLUMN temp_store_uuid uuid;

-- Update the temporary column with the correct UUID from stores
UPDATE daily_container_counts dc
SET temp_store_uuid = s.id
FROM stores s
WHERE s.department_number = dc.store_id;

-- Now we can safely drop the old column and rename the new one
ALTER TABLE daily_container_counts
  DROP CONSTRAINT IF EXISTS fk_store_supplies,
  DROP CONSTRAINT IF EXISTS fk_store,
  DROP COLUMN store_uuid,
  DROP COLUMN store_id,
  ALTER COLUMN temp_store_uuid SET NOT NULL,
  RENAME COLUMN temp_store_uuid TO store_id;

-- Add the foreign key constraint
ALTER TABLE daily_container_counts
  ADD CONSTRAINT fk_store 
  FOREIGN KEY (store_id) 
  REFERENCES stores(id)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

-- Create index for better join performance
CREATE INDEX IF NOT EXISTS idx_daily_container_counts_store_id 
ON daily_container_counts(store_id);
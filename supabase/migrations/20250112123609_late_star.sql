-- Add store_name and department_number columns to daily_container_counts
ALTER TABLE daily_container_counts
  ADD COLUMN IF NOT EXISTS department_number text,
  ADD COLUMN IF NOT EXISTS store_name text;

-- Create index for department_number if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_daily_container_counts_department_number 
ON daily_container_counts(department_number);

-- Update existing records with store information
UPDATE daily_container_counts dc
SET 
  department_number = s.department_number,
  store_name = s.store_name
FROM stores s
WHERE dc.store_id = s.id;

-- Make columns NOT NULL after data migration
ALTER TABLE daily_container_counts
  ALTER COLUMN department_number SET NOT NULL,
  ALTER COLUMN store_name SET NOT NULL;
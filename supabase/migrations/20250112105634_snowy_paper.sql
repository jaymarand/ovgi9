/*
  # Add Store Columns Migration

  1. Changes
    - Add new columns to store_supplies table
    - Add constraints and defaults
    - Update existing records with new column data
    - Add indexes for performance

  2. Security
    - Preserve existing RLS policies
*/

-- Add new columns to store_supplies
ALTER TABLE store_supplies
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS city text,
  ADD COLUMN IF NOT EXISTS state text,
  ADD COLUMN IF NOT EXISTS zip text,
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS ecommerce_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS manager_id uuid;

-- Create index for manager lookup
CREATE INDEX IF NOT EXISTS idx_store_supplies_manager_id ON store_supplies(manager_id);

-- Update existing records with new data
UPDATE store_supplies SET
  is_active = true,
  ecommerce_enabled = CASE 
    WHEN department_number IN ('9011', '9014', '9016', '9018', '9021', '9024', '9025', '9027', '9031', '9033') THEN true
    ELSE false
  END
WHERE department_number IN (
  '9011', '9012', '9014', '9015', '9016', '9017', '9018', '9019', '9020',
  '9021', '9023', '9024', '9025', '9026', '9027', '9029', '9030', '9031',
  '9032', '9033'
);
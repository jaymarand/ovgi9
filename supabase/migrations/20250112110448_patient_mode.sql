/*
  # Add Store Columns Migration

  1. Changes
    - Add new columns to stores table for address, contact info, and status flags
    - Add manager_id column with index
    - Set default values for boolean flags
    - Add constraints for data integrity

  2. New Columns
    - address: Store street address
    - city: Store city
    - state: Store state
    - zip: Store ZIP code
    - is_active: Flag for active stores
    - ecommerce_enabled: Flag for ecommerce capability
    - manager_id: UUID for store manager reference
*/

-- Add new columns to stores table
ALTER TABLE stores
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS city text,
  ADD COLUMN IF NOT EXISTS state text,
  ADD COLUMN IF NOT EXISTS zip text,
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS ecommerce_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS manager_id uuid;

-- Create index for manager lookup
CREATE INDEX IF NOT EXISTS idx_stores_manager_id ON stores(manager_id);

-- Update existing records with default values
UPDATE stores SET
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
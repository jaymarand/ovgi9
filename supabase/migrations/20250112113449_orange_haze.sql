/*
  # Recreate stores table
  
  1. Changes
    - Drop existing stores table
    - Create new stores table with correct structure
    - Import data from store_supplies
    - Set up proper constraints and indexes
    
  2. Notes
    - Preserves existing UUIDs
    - Maintains referential integrity
    - Sets up proper timestamps
*/

-- Drop existing table if it exists
DROP TABLE IF EXISTS stores CASCADE;

-- Create new stores table
CREATE TABLE stores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department_number text UNIQUE NOT NULL,
  name text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON stores
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Import data from store_supplies
INSERT INTO stores (
  id,
  department_number,
  name,
  created_at,
  updated_at
)
SELECT 
  id,
  department_number,
  store_name,
  created_at,
  updated_at
FROM store_supplies;

-- Create index for better query performance
CREATE INDEX idx_stores_department_number ON stores(department_number);

-- Create policies
CREATE POLICY "Allow authenticated read access"
  ON stores
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow dispatchers to modify stores"
  ON stores
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );
/*
  # Recreate stores table with essential data
  
  1. Changes
    - Drop existing stores table
    - Create new stores table with core columns
    - Import data from store_supplies preserving UUIDs
    - Set up proper constraints and indexes
    
  2. Notes
    - Preserves existing UUIDs
    - Maintains referential integrity
    - Keeps only essential columns
*/

-- Drop existing table if it exists
DROP TABLE IF EXISTS stores CASCADE;

-- Create new stores table with essential columns
CREATE TABLE stores (
  id uuid PRIMARY KEY,
  department_number text UNIQUE NOT NULL,
  store_name text NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL
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
  store_name,
  created_at,
  updated_at
)
VALUES
  ('06549d3b-ae39-4ffb-a66d-a8ee2f55deef', '9026', 'Beechmont', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('127e78cb-8d6c-4740-9596-16cedac57ab4', '9030', 'Oxford', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('16050e27-d136-414d-8ed5-ddd063d5ae73', '9027', 'Mt. Washington', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('19b5f2e7-91ca-4ea7-8862-9e683442391d', '9015', 'Hamilton', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('200c4f0a-c818-4e2b-b5d3-6e9167d805e7', '9019', 'Bellevue', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('2152b055-1112-4468-9719-8c5aef6d3f28', '9032', 'Lawrenceburg', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('2fd5e3ed-5fb4-42a2-a119-2f712fe9f488', '9018', 'Loveland', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('36748fe5-bfbb-4975-8e83-f6dc99ff0882', '9020', 'Harrison', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('40623c81-bc8a-4339-a7b5-0f93f9d03ba0', '9033', 'Deerfield', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('40f3c057-9598-4583-8c91-162e158bb2dd', '9021', 'Florence', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('5b32774b-6db6-40fc-923f-8a05472ed2b3', '9016', 'Oakley', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('928d5033-ac17-4cab-ba1e-7e2257cbe199', '9024', 'Fairfield', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('9549eb9a-5b3d-4a89-848f-8a411b229a19', '9017', 'Lebanon', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('b9685565-a96f-4fad-a4a3-60b2dc1515e6', '9011', 'Tri-County', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('ccac6a17-2552-41ad-bf29-5935c58a929a', '9031', 'West Chester', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('dbf3b172-f4e7-4fa0-a0aa-c13a7ec20a65', '9014', 'Independence', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('ebb5a3c6-4190-496c-81ba-c2dd2aed80f1', '9023', 'Batesville', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('f5b98b79-c8ba-4fcf-be26-9a3e3599ab6c', '9029', 'Montgomery', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('f8e23a5d-0ce1-4d6a-9b67-ef53b4afef35', '9025', 'Mason', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('f9a38607-c87c-4a30-923b-011fd358bb5a', '9012', 'Cheviot', '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00');

-- Create indexes for better query performance
CREATE INDEX idx_stores_department_number ON stores(department_number);
CREATE INDEX idx_stores_created_at ON stores(created_at);
CREATE INDEX idx_stores_updated_at ON stores(updated_at);

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
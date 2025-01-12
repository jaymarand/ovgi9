-- Drop existing table if it exists
DROP TABLE IF EXISTS store_supplies CASCADE;

-- Create new store_supplies table
CREATE TABLE store_supplies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department_number text UNIQUE NOT NULL,
  store_name text NOT NULL,
  sleeves integer NOT NULL DEFAULT 0 CHECK (sleeves >= 0),
  caps integer NOT NULL DEFAULT 0 CHECK (caps >= 0),
  canvases integer NOT NULL DEFAULT 0 CHECK (canvases >= 0),
  totes integer NOT NULL DEFAULT 0 CHECK (totes >= 0),
  hardlines_raw integer NOT NULL DEFAULT 0 CHECK (hardlines_raw >= 0),
  softlines_raw integer NOT NULL DEFAULT 0 CHECK (softlines_raw >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX idx_store_supplies_department_number ON store_supplies(department_number);
CREATE INDEX idx_store_supplies_created_at ON store_supplies(created_at);
CREATE INDEX idx_store_supplies_updated_at ON store_supplies(updated_at);

-- Create updated_at trigger
CREATE TRIGGER update_store_supplies_updated_at
  BEFORE UPDATE ON store_supplies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE store_supplies ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable read access for authenticated users"
  ON store_supplies
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable full access for dispatchers"
  ON store_supplies
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  )
  WITH CHECK (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );

-- Insert initial data
INSERT INTO store_supplies (
  id,
  department_number,
  store_name,
  sleeves,
  caps,
  canvases,
  totes,
  hardlines_raw,
  softlines_raw,
  created_at,
  updated_at
) VALUES
  ('06549d3b-ae39-4ffb-a66d-a8ee2f55deef', '9026', 'Beechmont', 6, 8, 76, 25, 18, 18, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('127e78cb-8d6c-4740-9596-16cedac57ab4', '9030', 'Oxford', 56, 34, 56, 56, 6, 6, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('16050e27-d136-414d-8ed5-ddd063d5ae73', '9027', 'Mt. Washington', 3, 6, 54, 56, 6, 6, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('19b5f2e7-91ca-4ea7-8862-9e683442391d', '9015', 'Hamilton', 15, 20, 22, 22, 12, 12, '2025-01-12 00:49:23.658056+00', '2025-01-12 13:27:13.66308+00'),
  ('200c4f0a-c818-4e2b-b5d3-6e9167d805e7', '9019', 'Bellevue', 26, 52, 22, 26, 15, 15, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('2152b055-1112-4468-9719-8c5aef6d3f28', '9032', 'Lawrenceburg', 12, 24, 28, 38, 10, 10, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('2fd5e3ed-5fb4-42a2-a119-2f712fe9f488', '9018', 'Loveland', 30, 60, 32, 24, 20, 20, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('36748fe5-bfbb-4975-8e83-f6dc99ff0882', '9020', 'Harrison', 32, 64, 35, 55, 12, 12, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('40623c81-bc8a-4339-a7b5-0f93f9d03ba0', '9033', 'Deerfield', 45, 90, 51, 19, 20, 20, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('40f3c057-9598-4583-8c91-162e158bb2dd', '9021', 'Florence', 34, 68, 54, 20, 20, 13, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('5b32774b-6db6-40fc-923f-8a05472ed2b3', '9016', 'Oakley', 21, 42, 21, 34, 20, 20, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('928d5033-ac17-4cab-ba1e-7e2257cbe199', '9024', 'Fairfield', 33, 66, 86, 12, 20, 20, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('9549eb9a-5b3d-4a89-848f-8a411b229a19', '9017', 'Lebanon', 20, 40, 34, 33, 17, 17, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('b9685565-a96f-4fad-a4a3-60b2dc1515e6', '9011', 'Tri-County', 39, 80, 12, 21, 20, 45, '2025-01-12 00:49:23.658056+00', '2025-01-12 13:29:32.732779+00'),
  ('ccac6a17-2552-41ad-bf29-5935c58a929a', '9031', 'West Chester', 43, 86, 46, 37, 14, 14, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('dbf3b172-f4e7-4fa0-a0aa-c13a7ec20a65', '9014', 'Independence', 11, 22, 11, 13, 10, 10, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('ebb5a3c6-4190-496c-81ba-c2dd2aed80f1', '9023', 'Batesville', 32, 64, 38, 45, 12, 12, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('f5b98b79-c8ba-4fcf-be26-9a3e3599ab6c', '9029', 'Montgomery', 44, 88, 57, 47, 6, 6, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('f8e23a5d-0ce1-4d6a-9b67-ef53b4afef35', '9025', 'Mason', 46, 92, 54, 11, 6, 6, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00'),
  ('f9a38607-c87c-4a30-923b-011fd358bb5a', '9012', 'Cheviot', 10, 20, 13, 12, 5, 5, '2025-01-12 00:49:23.658056+00', '2025-01-12 10:57:18.179181+00');
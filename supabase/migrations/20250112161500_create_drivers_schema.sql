-- Drop existing views if they exist
DROP VIEW IF EXISTS drivers_view;
DROP VIEW IF EXISTS drivers_with_emails;
DROP VIEW IF EXISTS active_drivers;

-- Drop existing tables if they exist
DROP TABLE IF EXISTS drivers CASCADE;

-- Create the drivers table
CREATE TABLE drivers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id),
    first_name text NOT NULL,
    last_name text NOT NULL,
    has_cdl boolean NOT NULL DEFAULT false,
    cdl_number text,
    cdl_expiration_date date,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Create the drivers view that includes email
CREATE VIEW drivers_view AS
SELECT 
    d.*,
    u.email,
    u.created_at as account_created_at
FROM drivers d
JOIN auth.users u ON d.user_id = u.id;

-- Create RLS policies
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to view drivers
CREATE POLICY "View drivers for authenticated users" ON drivers
    FOR SELECT TO authenticated USING (true);

-- Allow dispatchers to manage drivers
CREATE POLICY "Manage drivers for dispatchers" ON drivers
    FOR ALL TO authenticated
    USING (auth.jwt() ->> 'role' = 'dispatcher')
    WITH CHECK (auth.jwt() ->> 'role' = 'dispatcher');

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_drivers_updated_at
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_is_active ON drivers(is_active);
CREATE INDEX idx_drivers_created_at ON drivers(created_at);

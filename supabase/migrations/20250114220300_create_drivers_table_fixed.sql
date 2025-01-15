-- Drop existing drivers table if it exists
DROP TABLE IF EXISTS drivers CASCADE;

-- Create drivers table with correct columns
CREATE TABLE drivers (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id),
    email text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    has_cdl boolean,
    cdl_number text,
    cdl_expiration_date date,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add RLS policies
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view drivers" ON drivers
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can update their own driver profile" ON drivers
    FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_drivers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_drivers_updated_at
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE FUNCTION update_drivers_updated_at();

-- Grant necessary permissions
GRANT ALL ON drivers TO authenticated;

-- First, clean up any existing objects
DROP VIEW IF EXISTS drivers_view CASCADE;
DROP VIEW IF EXISTS drivers_with_emails CASCADE;
DROP VIEW IF EXISTS active_drivers CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;

-- Create the drivers table with proper foreign key reference
CREATE TABLE drivers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name text NOT NULL,
    last_name text NOT NULL,
    has_cdl boolean NOT NULL DEFAULT false,
    cdl_number text,
    cdl_expiration_date date,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Enable read access for authenticated users"
    ON drivers FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Enable insert for authenticated users"
    ON drivers FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users"
    ON drivers FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users"
    ON drivers FOR DELETE
    TO authenticated
    USING (true);

-- Create function to handle updated_at
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS on_drivers_updated ON drivers;
CREATE TRIGGER on_drivers_updated
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE PROCEDURE handle_updated_at();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_is_active ON drivers(is_active);

-- Grant necessary permissions
GRANT ALL ON drivers TO authenticated;
GRANT ALL ON drivers TO service_role;

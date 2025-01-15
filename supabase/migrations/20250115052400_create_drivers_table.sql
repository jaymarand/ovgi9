-- Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    first_name text NOT NULL,
    last_name text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add trigger for updated_at
CREATE TRIGGER set_timestamp
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- Insert some sample drivers
INSERT INTO drivers (first_name, last_name, is_active)
VALUES 
    ('John', 'Smith', true),
    ('Jane', 'Doe', true),
    ('Mike', 'Johnson', true),
    ('Sarah', 'Williams', true)
ON CONFLICT (id) DO NOTHING;

-- Grant access to the drivers table
GRANT SELECT ON drivers TO anon, authenticated;
GRANT INSERT, UPDATE ON drivers TO authenticated;

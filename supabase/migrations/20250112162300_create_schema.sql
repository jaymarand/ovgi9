-- Clean up existing objects
DROP VIEW IF EXISTS drivers_view CASCADE;
DROP VIEW IF EXISTS drivers_with_emails CASCADE;
DROP VIEW IF EXISTS active_drivers CASCADE;
DROP TABLE IF EXISTS runs CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;

-- Create the drivers table
CREATE TABLE IF NOT EXISTS drivers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NULL,
    email TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    has_cdl BOOLEAN DEFAULT false,
    cdl_number TEXT,
    cdl_expiration_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create runs table
CREATE TABLE runs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id uuid REFERENCES drivers(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'pending',
    start_time timestamptz,
    end_time timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE runs ENABLE ROW LEVEL SECURITY;

-- Create triggers for updated_at
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER on_runs_updated
    BEFORE UPDATE ON runs
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- Create indexes
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_is_active ON drivers(is_active);
CREATE INDEX idx_runs_driver_id ON runs(driver_id);
CREATE INDEX idx_runs_status ON runs(status);

-- Grant necessary permissions
GRANT ALL ON drivers TO authenticated;
GRANT ALL ON drivers TO service_role;
GRANT ALL ON runs TO authenticated;
GRANT ALL ON runs TO service_role;

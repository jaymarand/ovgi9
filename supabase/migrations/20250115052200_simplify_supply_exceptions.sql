-- Drop the previous table if it exists
DROP TABLE IF EXISTS supply_exceptions;

-- Create simplified supply exceptions table without RLS
CREATE TABLE supply_exceptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID REFERENCES active_delivery_runs(id) ON DELETE CASCADE,
    -- Requested supplies (from run_supply_needs)
    requested_sleeves INTEGER NOT NULL DEFAULT 0,
    requested_caps INTEGER NOT NULL DEFAULT 0,
    requested_canvases INTEGER NOT NULL DEFAULT 0,
    requested_totes INTEGER NOT NULL DEFAULT 0,
    requested_hardlines INTEGER NOT NULL DEFAULT 0,
    requested_softlines INTEGER NOT NULL DEFAULT 0,
    -- Actual loaded supplies
    actual_sleeves INTEGER NOT NULL DEFAULT 0,
    actual_caps INTEGER NOT NULL DEFAULT 0,
    actual_canvases INTEGER NOT NULL DEFAULT 0,
    actual_totes INTEGER NOT NULL DEFAULT 0,
    actual_hardlines INTEGER NOT NULL DEFAULT 0,
    actual_softlines INTEGER NOT NULL DEFAULT 0,
    -- Metadata
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX idx_supply_exceptions_run_id ON supply_exceptions(run_id);

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_supply_exceptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_supply_exceptions_updated_at
    BEFORE UPDATE ON supply_exceptions
    FOR EACH ROW
    EXECUTE FUNCTION update_supply_exceptions_updated_at();

-- Grant all permissions for demo
GRANT ALL ON supply_exceptions TO anon, authenticated, service_role;

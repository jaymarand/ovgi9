-- Clean up existing policies
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON drivers;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON drivers;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON drivers;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON drivers;

-- Create proper role-based policies
-- Dispatchers can view all drivers
CREATE POLICY "Dispatchers can view all drivers"
    ON drivers FOR SELECT
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

-- Drivers can view their own profile
CREATE POLICY "Drivers can view own profile"
    ON drivers FOR SELECT
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'driver'
        AND user_id = auth.uid()
    );

-- Only dispatchers can create drivers
CREATE POLICY "Only dispatchers can create drivers"
    ON drivers FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

-- Only dispatchers can update drivers
CREATE POLICY "Only dispatchers can update drivers"
    ON drivers FOR UPDATE
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'dispatcher'
    )
    WITH CHECK (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

-- Only dispatchers can delete drivers
CREATE POLICY "Only dispatchers can delete drivers"
    ON drivers FOR DELETE
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

-- Create runs table if it doesn't exist
CREATE TABLE IF NOT EXISTS runs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id uuid REFERENCES drivers(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'pending',
    start_time timestamptz,
    end_time timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS on runs
ALTER TABLE runs ENABLE ROW LEVEL SECURITY;

-- Dispatchers can view all runs
CREATE POLICY "Dispatchers can view all runs"
    ON runs FOR SELECT
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

-- Drivers can view their own runs
CREATE POLICY "Drivers can view own runs"
    ON runs FOR SELECT
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'driver'
        AND driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    );

-- Only dispatchers can create runs
CREATE POLICY "Only dispatchers can create runs"
    ON runs FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

-- Dispatchers can update any run
CREATE POLICY "Dispatchers can update runs"
    ON runs FOR UPDATE
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'dispatcher'
    )
    WITH CHECK (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

-- Drivers can update their own runs (for loading/unloading)
CREATE POLICY "Drivers can update own runs"
    ON runs FOR UPDATE
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'driver'
        AND driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        auth.jwt() ->> 'role' = 'driver'
        AND driver_id IN (
            SELECT id FROM drivers WHERE user_id = auth.uid()
        )
    );

-- Create trigger for updated_at on runs
DROP TRIGGER IF EXISTS on_runs_updated ON runs;
CREATE TRIGGER on_runs_updated
    BEFORE UPDATE ON runs
    FOR EACH ROW
    EXECUTE PROCEDURE handle_updated_at();

-- Create indexes for runs
CREATE INDEX IF NOT EXISTS idx_runs_driver_id ON runs(driver_id);
CREATE INDEX IF NOT EXISTS idx_runs_status ON runs(status);

-- Grant necessary permissions
GRANT ALL ON runs TO authenticated;
GRANT ALL ON runs TO service_role;

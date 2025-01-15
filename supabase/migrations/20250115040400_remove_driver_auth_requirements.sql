-- Drop existing RLS policies
DROP POLICY IF EXISTS "Drivers can view own record" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers and admins can insert" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers and admins can update" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers and admins can delete" ON drivers;
DROP POLICY IF EXISTS "dispatchers_manage_all" ON drivers;
DROP POLICY IF EXISTS "drivers_view_own" ON drivers;
DROP POLICY IF EXISTS "Authenticated users can view drivers" ON drivers;
DROP POLICY IF EXISTS "Users can update their own driver profile" ON drivers;

-- Create new simplified RLS policies
CREATE POLICY "Enable read access for all users" ON drivers
    FOR SELECT
    USING (true);

CREATE POLICY "Enable insert access for all users" ON drivers
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON drivers
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Enable delete access for all users" ON drivers
    FOR DELETE
    USING (true);

-- Make user_id column nullable since we're not using auth
ALTER TABLE drivers ALTER COLUMN user_id DROP NOT NULL;

-- Drop all existing policies
DROP POLICY IF EXISTS "Dispatchers can view all drivers" ON drivers;
DROP POLICY IF EXISTS "Drivers can view own profile" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers can create drivers" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers can update drivers" ON drivers;
DROP POLICY IF EXISTS "Only dispatchers can delete drivers" ON drivers;
DROP POLICY IF EXISTS "Drivers can view own record" ON drivers;
DROP POLICY IF EXISTS "Dispatchers can manage drivers" ON drivers;
DROP POLICY IF EXISTS "Allow dispatchers full access" ON drivers;
DROP POLICY IF EXISTS "Allow drivers to view own record" ON drivers;
DROP POLICY IF EXISTS "dispatchers_select" ON drivers;
DROP POLICY IF EXISTS "dispatchers_insert" ON drivers;
DROP POLICY IF EXISTS "dispatchers_update" ON drivers;
DROP POLICY IF EXISTS "dispatchers_delete" ON drivers;
DROP POLICY IF EXISTS "drivers_view_own" ON drivers;
DROP POLICY IF EXISTS "authenticated_access" ON drivers;
DROP POLICY IF EXISTS "allow_all_authenticated" ON drivers;
DROP POLICY IF EXISTS "dispatchers_all_access" ON drivers;
DROP POLICY IF EXISTS "allow_dispatcher_access" ON drivers;
DROP POLICY IF EXISTS "allow_driver_view" ON drivers;

-- Temporarily disable RLS for testing
ALTER TABLE drivers DISABLE ROW LEVEL SECURITY;

-- Enable RLS
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON drivers TO authenticated;
GRANT ALL ON drivers TO service_role;

-- Trust RLS from service role
ALTER TABLE drivers FORCE ROW LEVEL SECURITY;

-- Drop existing functions
DROP FUNCTION IF EXISTS auth.is_dispatcher();
DROP FUNCTION IF EXISTS auth.is_driver();

-- Create a simple policy for dispatchers
CREATE POLICY "dispatchers_manage_all" ON drivers
    FOR ALL
    TO authenticated
    USING (
        auth.jwt()->'user_metadata'->>'role' = 'dispatcher'
    )
    WITH CHECK (
        auth.jwt()->'user_metadata'->>'role' = 'dispatcher'
    );

-- Create a simple policy for drivers to view their own records
CREATE POLICY "drivers_view_own" ON drivers
    FOR SELECT
    TO authenticated
    USING (
        auth.jwt()->'user_metadata'->>'role' = 'driver'
        AND auth.uid() = user_id
    );

-- Create a secure view for drivers with user data
CREATE OR REPLACE VIEW driver_profiles AS
SELECT 
    d.id,
    d.user_id,
    d.first_name,
    d.last_name,
    d.has_cdl,
    d.cdl_number,
    d.cdl_expiration_date,
    d.is_active,
    d.created_at,
    d.updated_at,
    u.email,
    u.created_at as account_created_at
FROM drivers d
JOIN auth.users u ON d.user_id = u.id;

-- Enable RLS on the view
ALTER VIEW driver_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for the view
CREATE POLICY "Dispatchers can view all driver profiles"
    ON driver_profiles FOR SELECT
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'dispatcher'
    );

CREATE POLICY "Drivers can view own profile"
    ON driver_profiles FOR SELECT
    TO authenticated
    USING (
        auth.jwt() ->> 'role' = 'driver'
        AND user_id = auth.uid()
    );

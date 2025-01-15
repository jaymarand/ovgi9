-- Drop existing drivers table if it exists
DROP TABLE IF EXISTS drivers CASCADE;

-- Create drivers table with all columns
CREATE TABLE drivers (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id),
    name text NOT NULL,
    email text UNIQUE NOT NULL,
    phone text,
    license_number text,
    license_expiry date,
    dot_number text,
    dot_expiry date,
    medical_card_expiry date,
    preferred_truck_type vehicle_type,
    max_hours_per_week integer DEFAULT 40,
    preferred_start_time time,
    preferred_end_time time,
    is_active boolean DEFAULT true,
    employment_status text CHECK (employment_status IN ('full_time', 'part_time', 'contractor')),
    hire_date date,
    termination_date date,
    notes text,
    emergency_contact_name text,
    emergency_contact_phone text,
    last_safety_training_date date,
    last_drug_test_date date,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_by uuid REFERENCES auth.users(id),
    updated_by uuid REFERENCES auth.users(id)
);

-- Add indexes for frequently accessed columns
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_is_active ON drivers(is_active);
CREATE INDEX idx_drivers_license_expiry ON drivers(license_expiry);
CREATE INDEX idx_drivers_dot_expiry ON drivers(dot_expiry);
CREATE INDEX idx_drivers_medical_card_expiry ON drivers(medical_card_expiry);

-- Add RLS policies
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY "Admins have full access" ON drivers
    FOR ALL
    TO authenticated
    USING (
        auth.uid() IN (
            SELECT au.id 
            FROM auth.users au 
            WHERE au.email LIKE '%@ovgi.com'
        )
    );

-- Drivers can view their own profile
CREATE POLICY "Drivers can view their own profile" ON drivers
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Drivers can update specific fields in their own profile
CREATE POLICY "Drivers can update their own contact info" ON drivers
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (
        user_id = auth.uid() AND
        (
            NEW.phone IS NOT DISTINCT FROM OLD.phone OR
            NEW.email IS NOT DISTINCT FROM OLD.email OR
            NEW.emergency_contact_name IS NOT DISTINCT FROM OLD.emergency_contact_name OR
            NEW.emergency_contact_phone IS NOT DISTINCT FROM OLD.emergency_contact_phone
        )
    );

-- Create function to update driver profile
CREATE OR REPLACE FUNCTION update_driver_profile(
    p_driver_id uuid,
    p_name text DEFAULT NULL,
    p_email text DEFAULT NULL,
    p_phone text DEFAULT NULL,
    p_license_number text DEFAULT NULL,
    p_license_expiry date DEFAULT NULL,
    p_dot_number text DEFAULT NULL,
    p_dot_expiry date DEFAULT NULL,
    p_medical_card_expiry date DEFAULT NULL,
    p_preferred_truck_type vehicle_type DEFAULT NULL,
    p_max_hours_per_week integer DEFAULT NULL,
    p_preferred_start_time time DEFAULT NULL,
    p_preferred_end_time time DEFAULT NULL,
    p_is_active boolean DEFAULT NULL,
    p_employment_status text DEFAULT NULL,
    p_hire_date date DEFAULT NULL,
    p_termination_date date DEFAULT NULL,
    p_notes text DEFAULT NULL,
    p_emergency_contact_name text DEFAULT NULL,
    p_emergency_contact_phone text DEFAULT NULL,
    p_last_safety_training_date date DEFAULT NULL,
    p_last_drug_test_date date DEFAULT NULL
) RETURNS drivers
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_driver drivers;
BEGIN
    UPDATE drivers
    SET
        name = COALESCE(p_name, name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        license_number = COALESCE(p_license_number, license_number),
        license_expiry = COALESCE(p_license_expiry, license_expiry),
        dot_number = COALESCE(p_dot_number, dot_number),
        dot_expiry = COALESCE(p_dot_expiry, dot_expiry),
        medical_card_expiry = COALESCE(p_medical_card_expiry, medical_card_expiry),
        preferred_truck_type = COALESCE(p_preferred_truck_type, preferred_truck_type),
        max_hours_per_week = COALESCE(p_max_hours_per_week, max_hours_per_week),
        preferred_start_time = COALESCE(p_preferred_start_time, preferred_start_time),
        preferred_end_time = COALESCE(p_preferred_end_time, preferred_end_time),
        is_active = COALESCE(p_is_active, is_active),
        employment_status = COALESCE(p_employment_status, employment_status),
        hire_date = COALESCE(p_hire_date, hire_date),
        termination_date = COALESCE(p_termination_date, termination_date),
        notes = COALESCE(p_notes, notes),
        emergency_contact_name = COALESCE(p_emergency_contact_name, emergency_contact_name),
        emergency_contact_phone = COALESCE(p_emergency_contact_phone, emergency_contact_phone),
        last_safety_training_date = COALESCE(p_last_safety_training_date, last_safety_training_date),
        last_drug_test_date = COALESCE(p_last_drug_test_date, last_drug_test_date),
        updated_at = now(),
        updated_by = auth.uid()
    WHERE id = p_driver_id
    RETURNING * INTO v_driver;

    RETURN v_driver;
END;
$$;

-- Create function to get driver expiry notifications
CREATE OR REPLACE FUNCTION get_driver_expiry_notifications(
    p_days_warning integer DEFAULT 30
)
RETURNS TABLE (
    driver_id uuid,
    driver_name text,
    notification_type text,
    expiry_date date,
    days_until_expiry integer
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH expiries AS (
        SELECT
            id,
            name,
            'License' as type,
            license_expiry as expiry
        FROM drivers
        WHERE is_active = true
        UNION ALL
        SELECT
            id,
            name,
            'DOT',
            dot_expiry
        FROM drivers
        WHERE is_active = true
        UNION ALL
        SELECT
            id,
            name,
            'Medical Card',
            medical_card_expiry
        FROM drivers
        WHERE is_active = true
    )
    SELECT
        e.id,
        e.name,
        e.type,
        e.expiry,
        (e.expiry - CURRENT_DATE)::integer as days_remaining
    FROM expiries e
    WHERE 
        e.expiry IS NOT NULL
        AND e.expiry >= CURRENT_DATE
        AND (e.expiry - CURRENT_DATE) <= p_days_warning
    ORDER BY days_remaining;
END;
$$;

-- Grant necessary permissions
GRANT ALL ON drivers TO authenticated;
GRANT EXECUTE ON FUNCTION update_driver_profile TO authenticated;
GRANT EXECUTE ON FUNCTION get_driver_expiry_notifications TO authenticated;

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

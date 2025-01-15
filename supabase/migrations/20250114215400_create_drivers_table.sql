-- Create drivers table
CREATE TABLE IF NOT EXISTS drivers (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid REFERENCES auth.users(id),
    name text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add RLS policies for drivers table
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view drivers" ON drivers
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can update their own driver profile" ON drivers
    FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- Add foreign key to active_delivery_runs for fl_driver
ALTER TABLE active_delivery_runs 
    ADD COLUMN IF NOT EXISTS fl_driver_id uuid REFERENCES drivers(id),
    DROP COLUMN IF EXISTS fl_driver;

-- Create function to assign driver to run
CREATE OR REPLACE FUNCTION assign_driver_to_run(
    p_run_id uuid,
    p_driver_id uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE active_delivery_runs
    SET 
        fl_driver_id = p_driver_id,
        updated_at = now()
    WHERE id = p_run_id;
END;
$$;

-- Grant access to authenticated users
GRANT SELECT ON drivers TO authenticated;
GRANT EXECUTE ON FUNCTION assign_driver_to_run TO authenticated;

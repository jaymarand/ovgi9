-- Drop all versions of the function
DROP FUNCTION IF EXISTS public.assign_driver_to_run(uuid);
DROP FUNCTION IF EXISTS public.assign_driver_to_run(uuid, uuid);

-- Create the function with the correct signature and table name
CREATE OR REPLACE FUNCTION public.assign_driver_to_run(
    p_run_id uuid,
    p_driver_id uuid DEFAULT NULL
) RETURNS void AS $$
BEGIN
    -- Update the fl_driver_id in the delivery_runs table
    UPDATE delivery_runs
    SET 
        fl_driver_id = p_driver_id,
        updated_at = now()
    WHERE id = p_run_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to all roles
REVOKE ALL ON FUNCTION public.assign_driver_to_run(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO service_role;

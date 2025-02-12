-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS assign_driver_to_run(uuid, uuid);

-- Create the function with explicit parameter names and types
CREATE OR REPLACE FUNCTION public.assign_driver_to_run(
    p_run_id uuid,
    p_driver_id uuid
) RETURNS void AS $$
BEGIN
    UPDATE active_delivery_runs
    SET 
        fl_driver_id = p_driver_id,
        updated_at = now()
    WHERE id = p_run_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
REVOKE ALL ON FUNCTION public.assign_driver_to_run(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO service_role;

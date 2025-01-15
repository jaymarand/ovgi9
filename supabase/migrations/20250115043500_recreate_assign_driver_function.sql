-- Recreate the assign_driver_to_run function
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

-- Grant access to all users since we removed auth requirements
GRANT EXECUTE ON FUNCTION assign_driver_to_run TO anon;
GRANT EXECUTE ON FUNCTION assign_driver_to_run TO authenticated;
GRANT EXECUTE ON FUNCTION assign_driver_to_run TO service_role;

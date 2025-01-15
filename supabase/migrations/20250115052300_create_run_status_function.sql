-- Drop existing function if it exists
DROP FUNCTION IF EXISTS update_run_status;

-- Create function to update run status and time
CREATE OR REPLACE FUNCTION update_run_status(
  p_run_id UUID,
  p_status TEXT,
  p_time_column TEXT
) RETURNS void AS $$
BEGIN
  EXECUTE format(
    'UPDATE active_delivery_runs 
     SET status = $1, %I = NOW() 
     WHERE id = $2',
    p_time_column
  ) USING p_status, p_run_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to all roles for demo
GRANT EXECUTE ON FUNCTION update_run_status(UUID, TEXT, TEXT) TO anon, authenticated, service_role;

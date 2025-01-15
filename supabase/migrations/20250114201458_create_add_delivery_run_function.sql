-- Create function to add a new delivery run
CREATE OR REPLACE FUNCTION add_delivery_run(
  p_run_type text,
  p_store_id uuid,
  p_store_name text,
  p_department_number text,
  p_truck_type text
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_position integer;
  v_run_id uuid;
  v_run_type text;
BEGIN
  -- Convert the run type to proper case
  v_run_type := CASE 
    WHEN lower(p_run_type) = 'morning' THEN 'Morning'
    WHEN lower(p_run_type) = 'afternoon' THEN 'Afternoon'
    WHEN lower(p_run_type) = 'adc' THEN 'ADC'
    ELSE p_run_type
  END;

  -- Calculate next position for this run type
  SELECT COALESCE(MAX(position), 0) + 1
  INTO v_next_position
  FROM active_delivery_runs
  WHERE run_type::text = v_run_type
  AND DATE(created_at) = CURRENT_DATE;

  -- Insert new run and get the ID
  INSERT INTO active_delivery_runs (
    run_type,
    store_id,
    store_name,
    department_number,
    truck_type,
    position,
    status,
    created_at,
    updated_at
  ) VALUES (
    v_run_type::run_type,
    p_store_id,
    p_store_name,
    p_department_number,
    p_truck_type::vehicle_type,
    v_next_position,
    'pending',
    now(),
    now()
  ) RETURNING id INTO v_run_id;

  RETURN v_run_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_delivery_run TO authenticated;

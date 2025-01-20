-- Drop and recreate the add_delivery_run function with proper type handling
DROP FUNCTION IF EXISTS add_delivery_run(text, uuid, text, text, text);

CREATE OR REPLACE FUNCTION add_delivery_run(
  p_run_type varchar,
  p_store_id uuid,
  p_store_name varchar,
  p_department_number varchar,
  p_truck_type varchar
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_position integer;
  v_run_id uuid;
BEGIN
  -- Calculate next position for this run type
  SELECT COALESCE(MAX(position), 0) + 1
  INTO v_next_position
  FROM active_delivery_runs
  WHERE run_type = p_run_type
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
    p_run_type,
    p_store_id,
    p_store_name,
    p_department_number,
    p_truck_type,
    v_next_position,
    'upcoming',
    now(),
    now()
  ) RETURNING id INTO v_run_id;

  RETURN v_run_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_delivery_run TO authenticated;

-- Create the handle_updated_at function first
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

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
    'pending',
    now(),
    now()
  ) RETURNING id INTO v_run_id;

  RETURN v_run_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_delivery_run TO authenticated;

-- Add RLS policy for active_delivery_runs
ALTER TABLE active_delivery_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all runs"
    ON active_delivery_runs
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can insert runs"
    ON active_delivery_runs
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Fix the date field in run_supply_needs view
CREATE OR REPLACE VIEW run_supply_needs AS
WITH daily_counts AS (
    SELECT DISTINCT department_number
    FROM daily_container_counts
    WHERE DATE(created_at) = CURRENT_DATE
),
store_totals AS (
    SELECT 
        department_number,
        SUM(sleeves) as total_sleeves,
        SUM(caps) as total_caps,
        SUM(canvases) as total_canvases,
        SUM(totes) as total_totes,
        SUM(hardlines_raw) as total_hardlines,
        SUM(softlines_raw) as total_softlines
    FROM daily_container_counts
    WHERE DATE(created_at) = CURRENT_DATE
    GROUP BY department_number
)
SELECT 
    r.id as run_id,
    r.store_name,
    r.department_number,
    r.run_type,
    r.truck_type,
    r.status,
    r.position,
    r.driver as driver_id,
    r.start_time,
    r.preload_time,
    r.complete_time,
    r.depart_time,
    -- Calculate needed supplies (par level - current total)
    COALESCE(ss.sleeves, 0) - COALESCE(st.total_sleeves, 0) as sleeves_needed,
    COALESCE(ss.caps, 0) - COALESCE(st.total_caps, 0) as caps_needed,
    COALESCE(ss.canvases, 0) - COALESCE(st.total_canvases, 0) as canvases_needed,
    COALESCE(ss.totes, 0) - COALESCE(st.total_totes, 0) as totes_needed,
    COALESCE(ss.hardlines_raw, 0) - COALESCE(st.total_hardlines, 0) as hardlines_needed,
    COALESCE(ss.softlines_raw, 0) - COALESCE(st.total_softlines, 0) as softlines_needed
FROM active_delivery_runs r
LEFT JOIN store_totals st ON r.department_number = st.department_number
LEFT JOIN store_supplies ss ON r.department_number = ss.department_number
WHERE DATE(r.created_at) = CURRENT_DATE;

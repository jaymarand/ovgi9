-- Step 1: Update the active_delivery_runs table
ALTER TABLE active_delivery_runs 
    DROP COLUMN IF EXISTS fl_driver,
    ADD COLUMN IF NOT EXISTS fl_driver_id uuid REFERENCES drivers(id),
    ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Step 2: Drop the existing view
DROP VIEW IF EXISTS run_supply_needs;

-- Step 3: Recreate the view with proper driver reference
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
    r.id,
    r.store_id,
    r.store_name,
    r.department_number,
    r.status::text,
    r.run_type::text,
    r.sleeves_needed,
    r.caps_needed,
    r.canvases_needed,
    r.totes_needed,
    r.hardlines_needed,
    r.softlines_needed,
    r.fl_driver_id,
    r.start_time,
    r.preload_time,
    r.complete_time,
    r.depart_time,
    r.run_type::text as type,
    r.run_id,
    r.position,
    r.created_at,
    r.updated_at
FROM active_delivery_runs r
LEFT JOIN store_totals st ON r.department_number = st.department_number
WHERE DATE(r.created_at) = CURRENT_DATE;

-- Step 4: Drop existing function if it exists
DROP FUNCTION IF EXISTS public.assign_driver_to_run(uuid);
DROP FUNCTION IF EXISTS public.assign_driver_to_run(uuid, uuid);

-- Step 5: Create the assign_driver_to_run function
CREATE OR REPLACE FUNCTION public.assign_driver_to_run(
    p_run_id uuid,
    p_driver_id uuid DEFAULT NULL
) RETURNS void AS $$
BEGIN
    UPDATE active_delivery_runs
    SET 
        fl_driver_id = p_driver_id,
        updated_at = now()
    WHERE id = p_run_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Grant permissions
REVOKE ALL ON FUNCTION public.assign_driver_to_run(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_driver_to_run(uuid, uuid) TO service_role;

-- Step 7: Grant view access
GRANT SELECT ON run_supply_needs TO anon;
GRANT SELECT ON run_supply_needs TO authenticated;
GRANT SELECT ON run_supply_needs TO service_role;

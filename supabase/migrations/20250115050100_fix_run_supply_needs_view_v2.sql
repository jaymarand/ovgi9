-- Step 1: Drop the existing view
DROP VIEW IF EXISTS run_supply_needs;

-- Step 2: Recreate the view with correct columns
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
    r.run_type::text as run_type,
    r.truck_type::text as type,
    r.status::text as status,
    r.position,
    r.fl_driver_id,
    r.start_time,
    r.preload_time,
    r.complete_time,
    r.depart_time,
    r.created_at,
    r.updated_at,
    -- Calculate needed supplies (par level - current total)
    COALESCE(ss.sleeves, 0) - COALESCE(st.total_sleeves, 0) as sleeves_needed,
    COALESCE(ss.caps, 0) - COALESCE(st.total_caps, 0) as caps_needed,
    COALESCE(ss.canvases, 0) - COALESCE(st.total_canvases, 0) as canvases_needed,
    COALESCE(ss.totes, 0) - COALESCE(st.total_totes, 0) as totes_needed,
    COALESCE(ss.hardlines_raw, 0) - COALESCE(st.total_hardlines, 0) as hardlines_needed,
    COALESCE(ss.softlines_raw, 0) - COALESCE(st.total_softlines, 0) as softlines_needed
FROM active_delivery_runs r
LEFT JOIN store_totals st ON r.department_number = st.department_number
LEFT JOIN store_supplies ss ON r.department_number = ss.department_number;

-- Step 3: Grant view access
GRANT SELECT ON run_supply_needs TO anon;
GRANT SELECT ON run_supply_needs TO authenticated;
GRANT SELECT ON run_supply_needs TO service_role;

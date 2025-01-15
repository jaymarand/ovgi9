-- Step 1: Drop the existing view
DROP VIEW IF EXISTS run_supply_needs;

-- Step 2: Recreate the view without the date filter
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
    r.sleeves,
    r.caps,
    r.canvases,
    r.totes,
    r.hardlines_raw,
    r.softlines_raw,
    r.fl_driver_id,
    r.start_time,
    r.preload_time,
    r.complete_time,
    r.depart_time,
    r.run_type::text as type,
    r.id as run_id,
    r.position,
    r.created_at,
    r.updated_at
FROM active_delivery_runs r
LEFT JOIN store_totals st ON r.department_number = st.department_number;

-- Step 3: Grant view access
GRANT SELECT ON run_supply_needs TO anon;
GRANT SELECT ON run_supply_needs TO authenticated;
GRANT SELECT ON run_supply_needs TO service_role;

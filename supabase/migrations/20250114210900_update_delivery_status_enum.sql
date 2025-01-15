-- First, drop the dependent view
DROP VIEW IF EXISTS run_supply_needs;

-- Create the new delivery_status type
CREATE TYPE delivery_status_new AS ENUM (
    'upcoming',
    'loading',
    'preloaded',
    'in_transit',
    'complete',
    'cancelled'
);

-- Handle delivery_runs table
ALTER TABLE delivery_runs 
    ALTER COLUMN status DROP DEFAULT;
ALTER TABLE delivery_runs 
    ALTER COLUMN status TYPE text;
UPDATE delivery_runs
SET status = 'upcoming'
WHERE status = 'pending';
ALTER TABLE delivery_runs 
    ALTER COLUMN status TYPE delivery_status_new 
    USING status::delivery_status_new;
ALTER TABLE delivery_runs
    ALTER COLUMN status SET DEFAULT 'upcoming';

-- Handle active_delivery_runs table
ALTER TABLE active_delivery_runs 
    ALTER COLUMN status DROP DEFAULT;
ALTER TABLE active_delivery_runs 
    ALTER COLUMN status TYPE text;
UPDATE active_delivery_runs
SET status = 'upcoming'
WHERE status = 'pending';
ALTER TABLE active_delivery_runs 
    ALTER COLUMN status TYPE delivery_status_new 
    USING status::delivery_status_new;
ALTER TABLE active_delivery_runs
    ALTER COLUMN status SET DEFAULT 'upcoming';

-- Drop the old type with CASCADE to handle any remaining dependencies
DROP TYPE IF EXISTS delivery_status CASCADE;

-- Recreate the run_supply_needs view
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
    r.driver_id,
    r.start_time,
    r.preload_time,
    r.complete_time,
    r.depart_time,
    r.created_at,
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

-- Grant access to authenticated users
GRANT SELECT ON run_supply_needs TO authenticated;

-- First, make position nullable temporarily
ALTER TABLE active_delivery_runs
    ALTER COLUMN position DROP NOT NULL;

-- Update existing rows to have a position based on their run_type
WITH ordered_runs AS (
    SELECT 
        id,
        run_type,
        ROW_NUMBER() OVER (
            PARTITION BY run_type 
            ORDER BY created_at
        ) as new_position
    FROM active_delivery_runs
)
UPDATE active_delivery_runs ar
SET position = ord.new_position
FROM ordered_runs ord
WHERE ar.id = ord.id;

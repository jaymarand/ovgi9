-- Check recent runs
SELECT 
    id,
    store_name,
    department_number,
    run_type,
    status,
    created_at
FROM active_delivery_runs
WHERE DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC
LIMIT 5;

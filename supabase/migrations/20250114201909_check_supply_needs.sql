-- Check run supply needs
SELECT 
    run_id,
    store_name,
    department_number,
    run_type,
    status,
    sleeves_needed,
    caps_needed,
    canvases_needed,
    totes_needed,
    hardlines_needed,
    softlines_needed,
    created_at
FROM run_supply_needs
WHERE DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC
LIMIT 5;

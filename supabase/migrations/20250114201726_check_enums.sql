-- Check enum values
SELECT 
    t.typname as enum_type,
    e.enumlabel as enum_value,
    e.enumsortorder
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname IN ('run_type', 'vehicle_type', 'delivery_status')
ORDER BY t.typname, e.enumsortorder;

-- Get column information for store_supplies table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'store_supplies'
ORDER BY ordinal_position;

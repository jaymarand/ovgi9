-- Check the table structure
SELECT column_name, data_type, udt_name, character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'active_delivery_runs';

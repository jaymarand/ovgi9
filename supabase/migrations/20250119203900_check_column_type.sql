-- Check column type
DO $$
DECLARE
    col_type text;
BEGIN
    SELECT data_type 
    INTO col_type
    FROM information_schema.columns 
    WHERE table_name = 'active_delivery_runs' 
    AND column_name = 'run_type';
    
    RAISE NOTICE 'run_type column type is: %', col_type;
END $$;

-- Drop all functions created today
DROP FUNCTION IF EXISTS add_delivery_run(text, uuid, text, text, text);
DROP FUNCTION IF EXISTS add_delivery_run(varchar, uuid, varchar, varchar, varchar);
DROP FUNCTION IF EXISTS clear_runs();

-- Remove realtime publication
alter publication supabase_realtime drop table active_delivery_runs;

-- Drop RLS policies
drop policy if exists "Enable realtime for authenticated users" on active_delivery_runs;
drop policy if exists "Enable updates for authenticated users" on active_delivery_runs;
drop policy if exists "Enable insert for authenticated users" on active_delivery_runs;
drop policy if exists "Enable delete for authenticated users" on active_delivery_runs;

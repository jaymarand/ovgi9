-- Create function to clear active runs
create or replace function clear_active_runs()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    -- Delete all runs from active_delivery_runs regardless of status
    delete from active_delivery_runs
    where true;  -- This ensures we have a WHERE clause while deleting all rows
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function clear_active_runs to authenticated;

-- Add policy for clear_active_runs
drop policy if exists "Enable clear_active_runs for authenticated users" on active_delivery_runs;
create policy "Enable clear_active_runs for authenticated users"
    on active_delivery_runs
    for delete
    to authenticated
    using (true);  -- Allow deletion of all runs

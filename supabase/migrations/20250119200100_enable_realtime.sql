-- Enable realtime for required tables
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
    and schemaname = 'public'
    and tablename = 'active_delivery_runs'
  ) then
    alter publication supabase_realtime add table active_delivery_runs;
  end if;
end $$;

-- Ensure RLS policies allow realtime subscriptions and updates
drop policy if exists "Enable realtime for authenticated users" on active_delivery_runs;
create policy "Enable realtime for authenticated users"
on active_delivery_runs
for select
to authenticated
using (true);

drop policy if exists "Enable updates for authenticated users" on active_delivery_runs;
create policy "Enable updates for authenticated users"
on active_delivery_runs
for update
to authenticated
using (true)
with check (true);

drop policy if exists "Enable insert for authenticated users" on active_delivery_runs;
create policy "Enable insert for authenticated users"
on active_delivery_runs
for insert
to authenticated
with check (true);

drop policy if exists "Enable delete for authenticated users" on active_delivery_runs;
create policy "Enable delete for authenticated users"
on active_delivery_runs
for delete
to authenticated
using (true);

-- Enable row level security
alter table active_delivery_runs enable row level security;

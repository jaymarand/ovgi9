-- Create user_profiles table
create table if not exists user_profiles (
    id uuid references auth.users on delete cascade primary key,
    user_role text not null check (user_role in ('dispatcher', 'driver', 'admin')),
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Enable RLS
alter table user_profiles enable row level security;

-- Create policies
create policy "Users can view their own profile"
    on user_profiles for select
    using (auth.uid() = id);

create policy "Admin can view all profiles"
    on user_profiles for select
    using (auth.jwt() ->> 'role' = 'admin');

create policy "Dispatcher can view all profiles"
    on user_profiles for select
    using (auth.jwt() ->> 'role' = 'dispatcher');

-- Create trigger to update updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger update_user_profiles_updated_at
    before update on user_profiles
    for each row
    execute function update_updated_at_column();

-- Function to sync user profiles
create or replace function sync_user_profiles()
returns void
security definer
set search_path = public
language plpgsql as $$
begin
    -- Insert profiles for users that don't have one
    insert into user_profiles (id, user_role)
    select 
        users.id,
        coalesce(users.raw_user_meta_data->>'role', 'driver')::text
    from auth.users
    left join user_profiles on user_profiles.id = users.id
    where user_profiles.id is null;
end;
$$;

-- Function to handle new user signups
create or replace function handle_new_user()
returns trigger
security definer
set search_path = public
language plpgsql as $$
begin
    insert into user_profiles (id, user_role)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'role', 'driver')
    );
    return new;
end;
$$;

-- Create trigger for new users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function handle_new_user();

-- Update our driver functions to use JWT claims instead of user_profiles table
create or replace function update_user_password(
  user_id uuid,
  new_password text
)
returns boolean
security definer
set search_path = public
language plpgsql
as $$
begin
  -- Check if the caller is a dispatcher using JWT claim
  if auth.jwt() ->> 'role' != 'dispatcher' then
    raise exception 'Only dispatchers can update passwords';
  end if;

  -- Check if the target user exists
  if not exists(
    select 1
    from auth.users
    where id = user_id
  ) then
    raise exception 'User not found';
  end if;

  -- Update the password
  perform auth.change_user_password(user_id, new_password);

  return true;
end;
$$;

create or replace function create_driver_user(
  p_email text,
  p_password text,
  p_first_name text,
  p_last_name text,
  p_has_cdl boolean,
  p_cdl_number text default null,
  p_cdl_expiration_date date default null
)
returns json
security definer
set search_path = public
language plpgsql
as $$
declare
  v_user_id uuid;
  v_driver record;
begin
  -- Check if the caller is a dispatcher using JWT claim
  if auth.jwt() ->> 'role' != 'dispatcher' then
    raise exception 'Only dispatchers can create drivers';
  end if;

  -- Create the auth user
  select id into v_user_id
  from auth.create_user(
    email := p_email,
    password := p_password,
    email_confirmed := true,
    user_metadata := jsonb_build_object('role', 'driver')
  );

  -- Create the driver record
  insert into drivers (
    user_id,
    email,
    first_name,
    last_name,
    has_cdl,
    cdl_number,
    cdl_expiration_date,
    is_active
  ) values (
    v_user_id,
    p_email,
    p_first_name,
    p_last_name,
    p_has_cdl,
    p_cdl_number,
    p_cdl_expiration_date,
    true
  ) returning * into v_driver;

  return json_build_object(
    'user_id', v_user_id,
    'driver', v_driver
  );
exception
  when others then
    -- Clean up auth user if driver creation fails
    if v_user_id is not null then
      perform auth.delete_user(v_user_id);
    end if;
    raise;
end;
$$;

-- Initial sync of user profiles
select sync_user_profiles();

-- Enable the pgcrypto extension for password hashing
create extension if not exists pgcrypto;

-- Create a function to update user password
create or replace function update_user_password(
  user_id uuid,
  new_password text
)
returns boolean
security definer
set search_path = public
language plpgsql
as $$
declare
  calling_user_role text;
  target_user_exists boolean;
begin
  -- Get the role of the calling user
  select user_role into calling_user_role
  from user_profiles
  where id = auth.uid();

  -- Check if the caller is a dispatcher
  if calling_user_role != 'dispatcher' then
    raise exception 'Only dispatchers can update passwords';
  end if;

  -- Check if the target user exists
  select exists(
    select 1
    from auth.users
    where id = user_id
  ) into target_user_exists;

  if not target_user_exists then
    raise exception 'User not found';
  end if;

  -- Update the password
  perform auth.change_user_password(user_id, new_password);

  return true;
end;
$$;

-- Create a function to create a driver user
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
  calling_user_role text;
  v_user_id uuid;
  v_driver record;
begin
  -- Get the role of the calling user
  select user_role into calling_user_role
  from user_profiles
  where id = auth.uid();

  -- Check if the caller is a dispatcher
  if calling_user_role != 'dispatcher' then
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

-- Grant execute permissions to authenticated users
grant execute on function update_user_password to authenticated;
grant execute on function create_driver_user to authenticated;

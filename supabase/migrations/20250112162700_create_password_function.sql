-- Create a function to update user password
create or replace function update_user_password(
  user_id uuid,
  new_password text
)
returns boolean
security definer
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
  perform auth.update_user(
    user_id,
    jsonb_build_object('password', new_password)
  );

  return true;
end;
$$ language plpgsql;

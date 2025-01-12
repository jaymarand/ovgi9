-- Create function to get user data by IDs (only accessible by service role)
CREATE OR REPLACE FUNCTION get_users_by_ids(user_ids uuid[])
RETURNS TABLE (
    id uuid,
    email text,
    created_at timestamptz
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if user has dispatcher role
    IF (SELECT auth.jwt() ->> 'role') != 'dispatcher' THEN
        RAISE EXCEPTION 'Only dispatchers can access user data';
    END IF;

    RETURN QUERY
    SELECT 
        u.id,
        u.email,
        u.created_at
    FROM auth.users u
    WHERE u.id = ANY(user_ids);
END;
$$;

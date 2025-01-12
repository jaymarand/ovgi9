-- Create a view for active drivers
CREATE OR REPLACE VIEW active_drivers AS
SELECT 
    d.*,
    a.email,
    a.created_at as account_created_at
FROM drivers d
JOIN auth.users a ON d.user_id = a.id
WHERE d.is_active = true;

-- Add active status to drivers table
ALTER TABLE drivers ADD COLUMN is_active boolean NOT NULL DEFAULT true;

-- Update the drivers_with_emails view to include is_active
CREATE OR REPLACE VIEW drivers_with_emails AS
SELECT 
    d.*,
    a.email,
    a.created_at as account_created_at
FROM drivers d
JOIN auth.users a ON d.user_id = a.id;

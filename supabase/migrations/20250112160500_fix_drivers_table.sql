-- Drop existing views if they exist
DROP VIEW IF EXISTS drivers_with_emails;
DROP VIEW IF EXISTS active_drivers;

-- Create the drivers table if it doesn't exist
CREATE TABLE IF NOT EXISTS drivers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id),
    first_name text NOT NULL,
    last_name text NOT NULL,
    has_cdl boolean NOT NULL DEFAULT false,
    cdl_number text,
    cdl_expiration_date date,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Create the drivers view that includes email
CREATE VIEW drivers_view AS
SELECT 
    d.*,
    u.email,
    u.created_at as account_created_at
FROM drivers d
JOIN auth.users u ON d.user_id = u.id;

-- Add email column to drivers table
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE drivers ALTER COLUMN email SET NOT NULL;
ALTER TABLE drivers ADD CONSTRAINT drivers_email_unique UNIQUE (email);

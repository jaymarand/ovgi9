/*
  # Fix User Roles and Policies

  1. Changes
    - Drop and recreate user_roles table with proper structure
    - Create non-recursive policies using JWT claims
    - Update trigger function for new user creation
    - Add proper indexes for performance

  2. Security
    - Enable RLS
    - Create read-only policy for all authenticated users
    - Create management policy for dispatchers
    - Use JWT claims for role checks to avoid recursion
*/

-- Drop existing table and related objects
DROP TABLE IF EXISTS user_roles CASCADE;

-- Create user_roles table
CREATE TABLE IF NOT EXISTS user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  role text NOT NULL CHECK (role IN ('driver', 'dispatcher')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- Create index for performance
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);

-- Enable RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Create simple, non-recursive policies
CREATE POLICY "Enable read access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable dispatcher management"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );

-- Create trigger for updated_at
CREATE TRIGGER update_user_roles_updated_at
  BEFORE UPDATE ON user_roles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_roles (user_id, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'driver')
  )
  ON CONFLICT (user_id) 
  DO UPDATE SET
    role = EXCLUDED.role,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Migrate existing users
INSERT INTO user_roles (user_id, role)
SELECT 
  id as user_id,
  COALESCE(raw_user_meta_data->>'role', 'driver') as role
FROM auth.users
ON CONFLICT (user_id) DO UPDATE SET
  role = EXCLUDED.role,
  updated_at = now();
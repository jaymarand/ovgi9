/*
  # Disable Row Level Security

  1. Changes
    - Disable RLS on all tables
    - Drop all existing policies
  
  2. Security
    - WARNING: This removes all access control at the database level
    - All authenticated users will have full access to all tables
*/

-- Disable RLS on all tables
ALTER TABLE IF EXISTS driver_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS active_delivery_runs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS run_loading_progress DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS stores DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS store_supplies DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Drivers can view their own profile" ON driver_profiles;
DROP POLICY IF EXISTS "Dispatchers can view all driver profiles" ON driver_profiles;
DROP POLICY IF EXISTS "Drivers can view their assigned runs" ON active_delivery_runs;
DROP POLICY IF EXISTS "Drivers can update their assigned runs" ON active_delivery_runs;
DROP POLICY IF EXISTS "Dispatchers can view all runs" ON active_delivery_runs;
DROP POLICY IF EXISTS "Drivers can manage their run progress" ON run_loading_progress;
DROP POLICY IF EXISTS "Dispatchers can view all run progress" ON run_loading_progress;
DROP POLICY IF EXISTS "Allow authenticated read access" ON store_supplies;
DROP POLICY IF EXISTS "Allow dispatchers to modify supplies" ON store_supplies;
/*
  # Create Core Tables

  1. New Tables
    - driver_profiles: Store driver information
    - active_delivery_runs: Track delivery runs
    - run_loading_progress: Track loading progress for runs

  2. Changes
    - Create tables in correct order to maintain referential integrity
    - Add appropriate foreign key constraints
    - Set up timestamps and default values
*/

-- Create driver_profiles table first
CREATE TABLE IF NOT EXISTS driver_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  email text NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  has_cdl boolean DEFAULT false,
  cdl_number text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id),
  UNIQUE(email)
);

-- Create active_delivery_runs table
CREATE TABLE IF NOT EXISTS active_delivery_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver uuid REFERENCES auth.users NOT NULL,
  store_id text NOT NULL,
  store_name text NOT NULL,
  department_number text NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'loading', 'preloaded', 'in_transit', 'complete')),
  type text NOT NULL CHECK (type IN ('Box Truck', 'Tractor Trailer')),
  sleeves integer NOT NULL DEFAULT 0,
  caps integer NOT NULL DEFAULT 0,
  canvases integer NOT NULL DEFAULT 0,
  totes integer NOT NULL DEFAULT 0,
  hardlines_raw integer NOT NULL DEFAULT 0,
  softlines_raw integer NOT NULL DEFAULT 0,
  fl_driver text,
  start_time timestamptz,
  preload_time timestamptz,
  complete_time timestamptz,
  depart_time timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create run_loading_progress table
CREATE TABLE IF NOT EXISTS run_loading_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid REFERENCES active_delivery_runs NOT NULL,
  progress_data jsonb NOT NULL,
  updated_at timestamptz DEFAULT now()
);

-- Disable RLS on all tables for now
ALTER TABLE driver_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE active_delivery_runs DISABLE ROW LEVEL SECURITY;
ALTER TABLE run_loading_progress DISABLE ROW LEVEL SECURITY;
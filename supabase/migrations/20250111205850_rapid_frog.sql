/*
  # Initial Schema Setup for Dispatch Management System

  1. New Tables
    - `driver_profiles`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `email` (text)
      - `first_name` (text)
      - `last_name` (text)
      - `has_cdl` (boolean)
      - `cdl_number` (text)
      - `created_at` (timestamp)
    
    - `active_delivery_runs`
      - `id` (uuid, primary key)
      - `driver_id` (uuid, references auth.users)
      - `store_id` (text)
      - `store_name` (text)
      - `department_number` (text)
      - `status` (text with check constraint)
      - Various timestamps for tracking progress
    
    - `run_loading_progress`
      - `id` (uuid, primary key)
      - `run_id` (uuid, references active_delivery_runs)
      - `progress_data` (jsonb)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create driver_profiles table
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
  driver_id uuid REFERENCES auth.users NOT NULL,
  store_id text NOT NULL,
  store_name text NOT NULL,
  department_number text NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'loading', 'preloaded', 'in_transit', 'complete')),
  start_time timestamptz,
  depart_time timestamptz,
  complete_time timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create run_loading_progress table
CREATE TABLE IF NOT EXISTS run_loading_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid REFERENCES active_delivery_runs NOT NULL,
  progress_data jsonb NOT NULL,
  updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE driver_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_delivery_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE run_loading_progress ENABLE ROW LEVEL SECURITY;

-- Policies for driver_profiles
CREATE POLICY "Drivers can view their own profile"
  ON driver_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Dispatchers can view all driver profiles"
  ON driver_profiles
  FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'dispatcher'
  ));

-- Policies for active_delivery_runs
CREATE POLICY "Drivers can view their assigned runs"
  ON active_delivery_runs
  FOR SELECT
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Drivers can update their assigned runs"
  ON active_delivery_runs
  FOR UPDATE
  TO authenticated
  USING (driver_id = auth.uid());

CREATE POLICY "Dispatchers can view all runs"
  ON active_delivery_runs
  FOR ALL
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'dispatcher'
  ));

-- Policies for run_loading_progress
CREATE POLICY "Drivers can manage their run progress"
  ON run_loading_progress
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM active_delivery_runs
      WHERE active_delivery_runs.id = run_id
      AND active_delivery_runs.driver_id = auth.uid()
    )
  );

CREATE POLICY "Dispatchers can view all run progress"
  ON run_loading_progress
  FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.role = 'dispatcher'
  ));
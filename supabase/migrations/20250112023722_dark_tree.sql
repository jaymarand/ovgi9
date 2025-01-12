/*
  # Update daily_container_counts table

  1. Changes
    - Drop and recreate table with proper time handling
    - Add proper constraints
    - Add updated_at column with trigger
    - Improve RLS policies

  2. Security
    - Enable RLS
    - Add policies for authenticated users
*/

-- Drop existing table
DROP TABLE IF EXISTS daily_container_counts;

-- Create table with proper structure
CREATE TABLE IF NOT EXISTS daily_container_counts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id text NOT NULL REFERENCES store_supplies(department_number),
  opener_name text NOT NULL,
  arrival_time timestamptz NOT NULL,
  donation_count integer NOT NULL DEFAULT 0 CHECK (donation_count >= 0),
  trailer_fullness integer NOT NULL DEFAULT 0 CHECK (trailer_fullness >= 0 AND trailer_fullness <= 100),
  hardlines_raw integer NOT NULL DEFAULT 0 CHECK (hardlines_raw >= 0),
  softlines_raw integer NOT NULL DEFAULT 0 CHECK (softlines_raw >= 0),
  canvases integer NOT NULL DEFAULT 0 CHECK (canvases >= 0),
  sleeves integer NOT NULL DEFAULT 0 CHECK (sleeves >= 0),
  caps integer NOT NULL DEFAULT 0 CHECK (caps >= 0),
  totes integer NOT NULL DEFAULT 0 CHECK (totes >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create updated_at trigger
CREATE TRIGGER update_daily_container_counts_updated_at
  BEFORE UPDATE ON daily_container_counts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE daily_container_counts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to insert container counts"
  ON daily_container_counts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to read container counts"
  ON daily_container_counts
  FOR SELECT
  TO authenticated
  USING (true);

-- Create index for store_id for better query performance
CREATE INDEX idx_daily_container_counts_store_id ON daily_container_counts(store_id);
CREATE INDEX idx_daily_container_counts_created_at ON daily_container_counts(created_at DESC);
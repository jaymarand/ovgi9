/*
  # Create daily container counts table

  1. New Tables
    - `daily_container_counts`
      - `id` (uuid, primary key)
      - `store_id` (uuid, references stores)
      - `opener_name` (text)
      - `arrival_time` (timestamptz)
      - `donation_count` (integer)
      - `trailer_fullness` (integer)
      - `hardlines_raw` (integer)
      - `softlines_raw` (integer)
      - `canvases` (integer)
      - `sleeves` (integer)
      - `caps` (integer)
      - `totes` (integer)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policies for authenticated users
*/

-- Drop existing table if it exists
DROP TABLE IF EXISTS daily_container_counts CASCADE;

-- Create new daily_container_counts table
CREATE TABLE daily_container_counts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id uuid NOT NULL REFERENCES stores(id),
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

-- Create indexes for better query performance
CREATE INDEX idx_daily_container_counts_store_id ON daily_container_counts(store_id);
CREATE INDEX idx_daily_container_counts_created_at ON daily_container_counts(created_at DESC);
CREATE INDEX idx_daily_container_counts_arrival_time ON daily_container_counts(arrival_time DESC);

-- Create updated_at trigger
CREATE TRIGGER update_daily_container_counts_updated_at
  BEFORE UPDATE ON daily_container_counts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE daily_container_counts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable read access for authenticated users"
  ON daily_container_counts
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable insert for authenticated users"
  ON daily_container_counts
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Enable full access for dispatchers"
  ON daily_container_counts
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() -> 'user_metadata' ->> 'role' = 'dispatcher'
  );
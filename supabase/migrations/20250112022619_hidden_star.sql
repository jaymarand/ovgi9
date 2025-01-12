/*
  # Create daily container counts table

  1. New Tables
    - `daily_container_counts`
      - `id` (uuid, primary key)
      - `store_id` (text, references store_supplies)
      - `opener_name` (text)
      - `arrival_time` (text)
      - `donation_count` (integer)
      - `trailer_fullness` (integer)
      - `hardlines_raw` (integer)
      - `softlines_raw` (integer)
      - `canvases` (integer)
      - `sleeves` (integer)
      - `caps` (integer)
      - `totes` (integer)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS
    - Add policy for authenticated users to insert data
    - Add policy for authenticated users to read data
*/

CREATE TABLE IF NOT EXISTS daily_container_counts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id text NOT NULL REFERENCES store_supplies(department_number),
  opener_name text NOT NULL,
  arrival_time text NOT NULL,
  donation_count integer NOT NULL DEFAULT 0,
  trailer_fullness integer NOT NULL DEFAULT 0,
  hardlines_raw integer NOT NULL DEFAULT 0,
  softlines_raw integer NOT NULL DEFAULT 0,
  canvases integer NOT NULL DEFAULT 0,
  sleeves integer NOT NULL DEFAULT 0,
  caps integer NOT NULL DEFAULT 0,
  totes integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
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
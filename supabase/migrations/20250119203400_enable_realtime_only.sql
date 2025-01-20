-- Enable row level security
ALTER TABLE active_delivery_runs ENABLE ROW LEVEL SECURITY;

-- Add table to realtime publication
alter publication supabase_realtime add table active_delivery_runs;

-- Create policies for authenticated users
CREATE POLICY "Enable realtime for authenticated users" ON active_delivery_runs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable updates for authenticated users" ON active_delivery_runs
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Enable insert for authenticated users" ON active_delivery_runs
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users" ON active_delivery_runs
  FOR DELETE TO authenticated USING (true);

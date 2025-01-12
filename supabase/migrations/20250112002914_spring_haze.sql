/*
  # Verify and fix store data

  1. Changes
    - Verifies if data exists in stores table
    - Re-inserts store data if table is empty
    - Does not modify existing data
*/

-- First, verify if data exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM stores LIMIT 1) THEN
    -- Re-insert the data only if the table is empty
    INSERT INTO stores (department_number, name, sleeves, caps, canvases, totes, hardlines_raw, softlines_raw)
    VALUES
      ('9011', 'Tri-County', 40, 80, 12, 21, 20, 45),
      ('9012', 'Cheviot', 10, 20, 13, 12, 5, 5),
      ('9014', 'Independence', 11, 22, 11, 13, 10, 10),
      ('9015', 'Hamilton', 10, 20, 22, 22, 12, 12),
      ('9016', 'Oakley', 21, 42, 21, 34, 20, 20),
      ('9017', 'Lebanon', 20, 40, 34, 33, 17, 17),
      ('9018', 'Loveland', 30, 60, 32, 24, 20, 20),
      ('9019', 'Bellevue', 26, 52, 22, 26, 15, 15),
      ('9020', 'Harrison', 32, 64, 35, 55, 12, 12),
      ('9021', 'Florence', 34, 68, 54, 20, 20, 13),
      ('9023', 'Batesville', 32, 64, 38, 45, 12, 12),
      ('9024', 'Fairfield', 33, 66, 86, 12, 20, 20),
      ('9025', 'Mason', 46, 92, 54, 11, 6, 6),
      ('9026', 'Beechmont', 4, 8, 76, 25, 18, 18),
      ('9027', 'Mt. Washington', 3, 6, 54, 56, 6, 6),
      ('9029', 'Montgomery', 44, 88, 57, 47, 6, 6),
      ('9030', 'Oxford', 56, 112, 56, 56, 6, 6),
      ('9031', 'West Chester', 43, 86, 46, 37, 14, 14),
      ('9032', 'Lawrenceburg', 12, 24, 28, 38, 10, 10),
      ('9033', 'Deerfield', 45, 90, 51, 19, 20, 20);
  END IF;
END $$;
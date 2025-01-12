/*
  # Add Store Data Migration

  1. Changes
    - Insert store data with preserved UUIDs and metadata
    - Includes all store information including ecommerce flags
    - Preserves original timestamps

  2. Data
    - 20 stores with complete information
    - Includes active/inactive status
    - Preserves ecommerce enabled flags
*/

-- Insert store data with preserved UUIDs and metadata
INSERT INTO stores (
  id,
  department_number,
  name,
  address,
  city,
  state,
  zip,
  is_active,
  ecommerce_enabled,
  created_at,
  updated_at,
  manager_id
) VALUES 
  ('05a3625b-9ef7-4470-a281-aeab8b37fdfe', '9016', 'Oakley', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('18666e12-8c95-4685-9daf-1f6e3fb804ac', '9011', 'Tri-County', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('20d1307b-512a-42d5-9dc7-d2981abfe6ad', '9020', 'Harrison', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('288308a5-2359-479f-9e5b-371343f32a18', '9030', 'Oxford', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('3be9d7c3-b6ef-4f61-ab18-aa35e7777da0', '9033', 'Deerfield', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('4ad2c35c-e621-4416-8708-d6209ea8c6da', '9025', 'Mason', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('520fb843-4c88-4511-a872-00fc549c8e7b', '9017', 'Lebanon', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('6ecde7fb-37f2-43de-851b-9307a8a1e19b', '9019', 'Bellevue', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('6eecf80c-671d-48a2-b122-f0e9e4dd8e1e', '9012', 'Cheviot', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('73dcdd6a-f53c-477e-bbc7-1ac1714a8af9', '9024', 'Fairfield', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('8110fefe-e18d-4a90-80a2-5968097ee8c0', '9031', 'West Chester', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('a63d260d-0352-47f8-8173-fc0a35573637', '9029', 'Montgomery', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('ad44be5a-322a-45b1-a8c5-a26e2f24fef3', '9014', 'Independence', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('b9ad6cd1-1af2-41ba-9523-45cdac08484a', '9026', 'Beechmont', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('c316d509-1a47-403e-a86c-2c45f11eb6eb', '9023', 'Batesville', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('c338f74f-ecf2-4e9f-a707-843cba9b27ce', '9015', 'Hamilton', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('c7eff76e-80a5-498b-891b-6451fc9e9f68', '9032', 'Lawrenceburg', null, null, null, null, true, false, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('cb58562a-946d-455b-acb3-74a757dc7a4d', '9021', 'Florence', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('f47a0201-1653-4103-acfb-4a16e2b98c5d', '9018', 'Loveland', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null),
  ('f517ba64-e57d-450c-b006-4f8db56b68ab', '9027', 'Mt. Washington', null, null, null, null, true, true, '2024-12-28 17:00:48.233438+00', '2024-12-28 17:00:48.233438+00', null)
ON CONFLICT (id) DO UPDATE SET
  department_number = EXCLUDED.department_number,
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  city = EXCLUDED.city,
  state = EXCLUDED.state,
  zip = EXCLUDED.zip,
  is_active = EXCLUDED.is_active,
  ecommerce_enabled = EXCLUDED.ecommerce_enabled,
  created_at = EXCLUDED.created_at,
  updated_at = EXCLUDED.updated_at,
  manager_id = EXCLUDED.manager_id;
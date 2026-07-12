INSERT INTO public.university (name, address, contact_info)
VALUES (
  'FPT University',
  'Hoa Lac Hi-Tech Park, Hanoi',
  'contact@fpt.edu.vn'
)
ON CONFLICT (name) DO UPDATE
SET
  address = EXCLUDED.address,
  contact_info = EXCLUDED.contact_info;

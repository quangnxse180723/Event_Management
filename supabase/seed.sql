-- Seed data for Event Management.
-- Auth users are not inserted here. On Supabase Cloud, create demo login
-- users from Authentication > Users, then map public.app_user.auth_id to the
-- generated Auth user IDs.
-- Run after all migrations. This file is intended to be re-runnable.

BEGIN;

INSERT INTO public.university (name, address, contact_info)
VALUES
  ('HUTECH University', '475A Dien Bien Phu, Binh Thanh, Ho Chi Minh City', 'contact@hutech.edu.vn'),
  ('Hanoi University of Science and Technology', '1 Dai Co Viet, Hai Ba Trung, Hanoi', 'contact@hust.edu.vn'),
  ('University of Economics Ho Chi Minh City', '59C Nguyen Dinh Chieu, District 3, Ho Chi Minh City', 'contact@ueh.edu.vn'),
  ('FPT University', 'Hoa Lac Hi-Tech Park, Hanoi', 'contact@fpt.edu.vn')
ON CONFLICT (name) DO UPDATE
SET
  address = EXCLUDED.address,
  contact_info = EXCLUDED.contact_info;

INSERT INTO public.university_campus (university_id, name, address, contact_info)
SELECT university.university_id, source.name, source.address, source.contact_info
FROM (
  VALUES
    ('Ha Noi', 'Khu Giao duc va Dao tao, Khu Cong nghe cao Hoa Lac, Km29 Dai lo Thang Long, Xa Hoa Lac, TP. Ha Noi', '(024) 7300 5588'),
    ('TP. Ho Chi Minh', 'Lo E2a-7, Duong D1, Khu Cong nghe cao, Phuong Tang Nhon Phu, TP. Ho Chi Minh', '(028) 7300 5588'),
    ('Da Nang', 'Khu do thi cong nghe FPT Da Nang, Phuong Ngu Hanh Son, TP. Da Nang', '(0236) 730 0999'),
    ('Can Tho', 'So 600, duong Nguyen Van Cu (noi dai), Phuong An Binh, TP. Can Tho', '(0292) 730 3636'),
    ('Quy Nhon', 'Khu do thi moi An Phu Thinh, Phuong Quy Nhon Dong, Tinh Gia Lai', '(0256) 7300 999')
) AS source(name, address, contact_info)
JOIN public.university ON university.name = 'FPT University'
ON CONFLICT (university_id, name) DO UPDATE
SET
  address = EXCLUDED.address,
  contact_info = EXCLUDED.contact_info;

INSERT INTO public.app_user (email, role, password_hash)
VALUES
  ('admin@event.local', 'admin', NULL),
  ('minh.nguyen@event.local', 'organizer', NULL),
  ('lan.tran@event.local', 'organizer', NULL),
  ('an.nguyen@student.local', 'student', NULL),
  ('binh.le@student.local', 'student', NULL),
  ('chi.pham@student.local', 'student', NULL),
  ('dung.vo@student.local', 'student', NULL),
  ('ha.do@student.local', 'student', NULL),
  ('khanh.bui@student.local', 'student', NULL)
ON CONFLICT (email) DO UPDATE
SET role = EXCLUDED.role;

INSERT INTO public.student (
  user_id, university_id, name, email, student_code, phone
)
SELECT
  app_user.user_id,
  university.university_id,
  source.name,
  source.email,
  source.student_code,
  source.phone
FROM (
  VALUES
    ('an.nguyen@student.local', 'HUTECH University', 'Nguyen Minh An', 'SV2026001', '0901000001'),
    ('binh.le@student.local', 'HUTECH University', 'Le Gia Binh', 'SV2026002', '0901000002'),
    ('chi.pham@student.local', 'Hanoi University of Science and Technology', 'Pham Ngoc Chi', 'SV2026003', '0901000003'),
    ('dung.vo@student.local', 'Hanoi University of Science and Technology', 'Vo Hoang Dung', 'SV2026004', '0901000004'),
    ('ha.do@student.local', 'University of Economics Ho Chi Minh City', 'Do Thu Ha', 'SV2026005', '0901000005'),
    ('khanh.bui@student.local', 'University of Economics Ho Chi Minh City', 'Bui Quang Khanh', 'SV2026006', '0901000006')
) AS source(email, university_name, name, student_code, phone)
JOIN public.app_user AS app_user ON app_user.email = source.email
JOIN public.university AS university ON university.name = source.university_name
ON CONFLICT (email) DO UPDATE
SET
  user_id = EXCLUDED.user_id,
  university_id = EXCLUDED.university_id,
  name = EXCLUDED.name,
  student_code = EXCLUDED.student_code,
  phone = EXCLUDED.phone;

INSERT INTO public.event (
  user_id, title, description, organizer, start_date, end_date
)
SELECT
  app_user.user_id,
  source.title,
  source.description,
  source.organizer,
  source.start_date,
  source.end_date
FROM (
  VALUES
    (
      'minh.nguyen@event.local',
      'Technology Day 2026',
      'Student project showcase, career booths, and technology talks.',
      'Nguyen Minh',
      TIMESTAMPTZ '2026-08-15 08:00:00+07',
      TIMESTAMPTZ '2026-08-15 17:30:00+07'
    ),
    (
      'lan.tran@event.local',
      'Career Skills for Students',
      'CV writing, interview practice, and career orientation sessions.',
      'Tran Ngoc Lan',
      TIMESTAMPTZ '2026-08-22 08:30:00+07',
      TIMESTAMPTZ '2026-08-22 16:30:00+07'
    ),
    (
      'minh.nguyen@event.local',
      'Flutter Basics Workshop',
      'Build a Flutter application connected to Supabase.',
      'Nguyen Minh',
      TIMESTAMPTZ '2026-09-05 13:30:00+07',
      TIMESTAMPTZ '2026-09-05 17:00:00+07'
    )
) AS source(owner_email, title, description, organizer, start_date, end_date)
JOIN public.app_user AS app_user ON app_user.email = source.owner_email
WHERE NOT EXISTS (
  SELECT 1
  FROM public.event AS existing_event
  WHERE existing_event.title = source.title
);

INSERT INTO public.event_session (event_id, title, start_time, end_time, location)
SELECT
  event.event_id,
  source.title,
  source.start_time,
  source.end_time,
  source.location
FROM (
  VALUES
    ('Technology Day 2026', 'Opening and Program Overview', TIMESTAMPTZ '2026-08-15 08:00:00+07', TIMESTAMPTZ '2026-08-15 09:00:00+07', 'Auditorium A'),
    ('Technology Day 2026', 'Student Project Showcase', TIMESTAMPTZ '2026-08-15 09:15:00+07', TIMESTAMPTZ '2026-08-15 11:30:00+07', 'Hall B'),
    ('Career Skills for Students', 'Writing a Strong CV', TIMESTAMPTZ '2026-08-22 08:30:00+07', TIMESTAMPTZ '2026-08-22 10:00:00+07', 'Room C201'),
    ('Career Skills for Students', 'Mock Interview Practice', TIMESTAMPTZ '2026-08-22 13:30:00+07', TIMESTAMPTZ '2026-08-22 16:30:00+07', 'Room C201'),
    ('Flutter Basics Workshop', 'Building Flutter UI', TIMESTAMPTZ '2026-09-05 13:30:00+07', TIMESTAMPTZ '2026-09-05 15:00:00+07', 'Lab 03'),
    ('Flutter Basics Workshop', 'Connecting Supabase', TIMESTAMPTZ '2026-09-05 15:15:00+07', TIMESTAMPTZ '2026-09-05 17:00:00+07', 'Lab 03')
) AS source(event_title, title, start_time, end_time, location)
JOIN public.event AS event ON event.title = source.event_title
WHERE NOT EXISTS (
  SELECT 1
  FROM public.event_session AS existing_session
  WHERE existing_session.event_id = event.event_id
    AND existing_session.title = source.title
);

INSERT INTO public.student_in_event (event_id, student_id, status)
SELECT
  event.event_id,
  student.student_id,
  source.status
FROM (
  VALUES
    ('Technology Day 2026', 'SV2026001', 'registered'),
    ('Technology Day 2026', 'SV2026002', 'checked_in'),
    ('Technology Day 2026', 'SV2026003', 'registered'),
    ('Technology Day 2026', 'SV2026004', 'checked_in'),
    ('Career Skills for Students', 'SV2026003', 'registered'),
    ('Career Skills for Students', 'SV2026005', 'registered'),
    ('Career Skills for Students', 'SV2026006', 'cancelled'),
    ('Flutter Basics Workshop', 'SV2026001', 'registered'),
    ('Flutter Basics Workshop', 'SV2026002', 'registered'),
    ('Flutter Basics Workshop', 'SV2026005', 'registered')
) AS source(event_title, student_code, status)
JOIN public.event AS event ON event.title = source.event_title
JOIN public.student AS student ON student.student_code = source.student_code
ON CONFLICT (event_id, student_id) DO UPDATE
SET status = EXCLUDED.status;

INSERT INTO public.session_checkin (session_id, student_id, user_id, method, created_at)
SELECT
  event_session.session_id,
  student.student_id,
  student.user_id,
  source.method,
  source.created_at
FROM (
  VALUES
    ('Student Project Showcase', 'SV2026002', 'qr', TIMESTAMPTZ '2026-08-15 09:22:00+07'),
    ('Student Project Showcase', 'SV2026004', 'manual', TIMESTAMPTZ '2026-08-15 09:28:00+07'),
    ('Writing a Strong CV', 'SV2026003', 'qr', TIMESTAMPTZ '2026-08-22 08:38:00+07'),
    ('Building Flutter UI', 'SV2026001', 'qr', TIMESTAMPTZ '2026-09-05 13:42:00+07')
) AS source(session_title, student_code, method, created_at)
JOIN public.event_session AS event_session ON event_session.title = source.session_title
JOIN public.student AS student ON student.student_code = source.student_code
ON CONFLICT (session_id, student_id) DO UPDATE
SET
  user_id = EXCLUDED.user_id,
  method = EXCLUDED.method,
  created_at = EXCLUDED.created_at;

COMMIT;

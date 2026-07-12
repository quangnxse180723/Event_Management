-- Hoàn thiện schema để khớp với các trường và RPC mà ứng dụng Flutter sử dụng.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

ALTER TABLE public.student
  ADD COLUMN IF NOT EXISTS phone VARCHAR(30);

UPDATE public.student
SET phone = ''
WHERE phone IS NULL;

ALTER TABLE public.student
  ALTER COLUMN phone SET DEFAULT '',
  ALTER COLUMN phone SET NOT NULL;

-- Tên trường cần duy nhất để seed có thể chạy lặp lại mà không tạo bản ghi trùng.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'university_name_key'
      AND conrelid = 'public.university'::regclass
  ) THEN
    ALTER TABLE public.university
      ADD CONSTRAINT university_name_key UNIQUE (name);
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS student_user_id_idx
  ON public.student (user_id);
CREATE INDEX IF NOT EXISTS student_university_id_idx
  ON public.student (university_id);
CREATE INDEX IF NOT EXISTS event_user_id_idx
  ON public.event (user_id);
CREATE INDEX IF NOT EXISTS event_session_event_id_idx
  ON public.event_session (event_id);
CREATE INDEX IF NOT EXISTS student_in_event_event_id_idx
  ON public.student_in_event (event_id);
CREATE INDEX IF NOT EXISTS student_in_event_student_id_idx
  ON public.student_in_event (student_id);
CREATE INDEX IF NOT EXISTS session_checkin_session_id_idx
  ON public.session_checkin (session_id);
CREATE INDEX IF NOT EXISTS session_checkin_student_id_idx
  ON public.session_checkin (student_id);

-- RPC dùng ở màn hình tạo/chỉnh sửa sự kiện.
CREATE OR REPLACE FUNCTION public.get_organizers()
RETURNS TABLE (
  user_id BIGINT,
  email VARCHAR,
  role VARCHAR
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT au.user_id, au.email, au.role
  FROM public.app_user AS au
  WHERE au.role = 'organizer'
  ORDER BY au.email;
$$;

GRANT EXECUTE ON FUNCTION public.get_organizers() TO anon, authenticated;

-- Create the public profile as soon as Supabase Auth creates a user.
-- The Flutter sign-up screen sends full_name, student_code and university_id
-- in raw_user_meta_data. This also works when email confirmation is enabled.

CREATE OR REPLACE FUNCTION public.create_student_profile_for_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id BIGINT;
  v_role VARCHAR;
  v_full_name TEXT;
  v_student_code TEXT;
  v_university_id BIGINT;
BEGIN
  -- A seeded public profile may exist before its matching auth.users row.
  UPDATE public.app_user
  SET auth_id = NEW.id
  WHERE email = NEW.email
    AND auth_id IS NULL
  RETURNING user_id, role INTO v_user_id, v_role;

  IF v_user_id IS NULL THEN
    INSERT INTO public.app_user (auth_id, email, role)
    VALUES (NEW.id, NEW.email, 'student')
    RETURNING user_id, role INTO v_user_id, v_role;
  END IF;

  -- Existing admin and organizer accounts must not receive a student profile.
  IF v_role <> 'student' THEN
    RETURN NEW;
  END IF;

  v_full_name := NULLIF(TRIM(NEW.raw_user_meta_data ->> 'full_name'), '');
  v_student_code := UPPER(NULLIF(TRIM(NEW.raw_user_meta_data ->> 'student_code'), ''));
  IF COALESCE(NEW.raw_user_meta_data ->> 'university_id', '') ~ '^\d+$' THEN
    v_university_id := (NEW.raw_user_meta_data ->> 'university_id')::BIGINT;
  END IF;

  -- Demo accounts are mapped only. Their existing profile data is preserved.
  IF EXISTS (SELECT 1 FROM public.student WHERE user_id = v_user_id) THEN
    RETURN NEW;
  END IF;

  IF v_full_name IS NOT NULL
    AND v_student_code IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.university WHERE university_id = v_university_id
    ) THEN
    INSERT INTO public.student (
      user_id, university_id, name, email, student_code, phone
    ) VALUES (
      v_user_id, v_university_id, v_full_name, NEW.email, v_student_code, ''
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_student_profile ON auth.users;

CREATE TRIGGER on_auth_user_created_student_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.create_student_profile_for_auth_user();

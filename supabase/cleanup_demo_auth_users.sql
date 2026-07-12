-- Clean broken demo Auth users created manually in auth.users/auth.identities.
-- This keeps business data in public.* tables, but unmaps app_user.auth_id.
-- After running this, create Auth users from Supabase Dashboard:
-- Authentication > Users > Add user, password: Password123!, auto-confirm ON.

BEGIN;

CREATE TEMP TABLE demo_auth_cleanup_emails (
  email TEXT PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO demo_auth_cleanup_emails (email)
VALUES
  ('admin@event.local'),
  ('minh.nguyen@event.local'),
  ('lan.tran@event.local'),
  ('an.nguyen@student.local'),
  ('binh.le@student.local'),
  ('chi.pham@student.local'),
  ('dung.vo@student.local'),
  ('ha.do@student.local'),
  ('khanh.bui@student.local');

UPDATE public.app_user AS au
SET auth_id = NULL
FROM demo_auth_cleanup_emails AS demo
WHERE au.email = demo.email;

DELETE FROM auth.identities AS identities
USING auth.users AS users, demo_auth_cleanup_emails AS demo
WHERE identities.user_id = users.id
  AND users.email = demo.email;

DELETE FROM auth.refresh_tokens AS refresh_tokens
USING auth.sessions AS sessions, auth.users AS users, demo_auth_cleanup_emails AS demo
WHERE refresh_tokens.session_id = sessions.id
  AND sessions.user_id = users.id
  AND users.email = demo.email;

DELETE FROM auth.sessions AS sessions
USING auth.users AS users, demo_auth_cleanup_emails AS demo
WHERE sessions.user_id = users.id
  AND users.email = demo.email;

DELETE FROM auth.users AS users
USING demo_auth_cleanup_emails AS demo
WHERE users.email = demo.email;

COMMIT;

SELECT email, auth_id, role
FROM public.app_user
WHERE email IN (
  'admin@event.local',
  'minh.nguyen@event.local',
  'lan.tran@event.local',
  'an.nguyen@student.local',
  'binh.le@student.local',
  'chi.pham@student.local',
  'dung.vo@student.local',
  'ha.do@student.local',
  'khanh.bui@student.local'
)
ORDER BY role, email;

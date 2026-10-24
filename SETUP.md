# Supabase setup

1. Create a Supabase project and keep its database password private.
2. Open **SQL Editor**, create a new query, paste `schema.sql`, and run it. If a policy or enum already exists because you re-ran part of the script, resolve that migration error deliberately; do not blindly drop production tables.
3. In **Project Settings → API**, copy the Project URL and publishable/anon key into `js/config.js`. Never put a `service_role` key in frontend code.
4. In **Authentication → Providers / Settings**, enable email/password, configure the email provider, set minimum password length to at least 8 (prefer 12+), and configure redirect URLs for local testing and the final HTTPS domain. Enable MFA for administrators if available.
5. Create the first administrator through Authentication (invite/create user), then run this in SQL Editor with the exact Auth user UUID:
   `update public.profiles set role='admin', display_name='School Administrator' where id='PASTE-AUTH-USER-UUID';`
   Do this only for the real administrator. New sign-ups default to parent and cannot self-assign admin/teacher.
6. Create teacher and parent users using Auth invites. Link a teacher to classes using `teacher_classes`, and link a parent to students using `parent_students`. Set profiles' roles using SQL Editor as an administrator.
7. Create Storage bucket `talent-private` with **Public bucket OFF**. For real private clips, add Storage policies and use a small trusted Supabase Edge Function that checks the signed-in user's role/relationship before issuing short-lived signed URLs. Do not make the bucket public. The included frontend signed URL call is a demo placeholder and should be replaced by that checked endpoint.
8. Configure Auth email templates and rate limits. Supabase Auth provides throttling; don't rely on a browser-only login counter. Configure SMTP for reliable email delivery.
9. Add approved school email and WhatsApp number in `js/config.js`.
10. Open `index.html` through VS Code Live Server or serve the folder using a local web server. Auth redirects and PWA features work best on localhost/HTTPS, not by opening a `file://` path.

## Important limitation
This is a working starter/prototype, not a complete audited school information system. Before real pupil data: review every RLS policy, add audit logs, secure file uploads and private signed URLs, test backups/restore, consent/retention for children’s data, and obtain the school's written approval. The admission form currently does not upload documents or automatically generate a formal admission letter. Report card entry/calculation, complete timetable editor, teacher attendance interface, and automated absence notifications still need implementation. Never promise these unfinished features to the school as completed.

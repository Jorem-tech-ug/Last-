# Seeds of Gold Junior School — Supabase starter

Mobile-first school portal prototype for Seeds of Gold Junior School, Kitende. Frontend: HTML, CSS, JavaScript. Backend/database/auth: Supabase (Postgres + Auth + Storage). No school fees module.

## Folder structure
- `index.html` — public home, admission enquiry, sign-in and private dashboards
- `assets/style.css` — responsive design
- `assets/school-mark.svg`, `assets/school-illustration.svg` — original local vector assets (no external image downloads needed)
- `js/config.js` — Supabase public configuration and school contact placeholders
- `js/app.js` — authentication, role dashboards, admission intake, basic attendance, notices and parent report/attendance views
- `supabase/schema.sql` — database tables, helper functions and starter RLS policies
- `supabase/SETUP.md` — setup instructions and unfinished production work
- `manifest.webmanifest`, `service-worker.js` — basic installable PWA shell

## Run locally
1. Create/configure Supabase using `supabase/SETUP.md`.
2. Put the project URL and publishable/anon key into `js/config.js`.
3. In VS Code install/use Live Server, then open `index.html` with Live Server.
4. Test using separate accounts for admin, teacher and parent. A new Auth account defaults to parent; assign role and relationships from SQL Editor.

## Scope honestly included
- Public home page and admission enquiry submission (no documents uploaded yet)
- Email/password sign-in, password reset, role-specific starter dashboards
- Admin summary counts, admission enquiry review status, notices
- Teacher attendance roster and present/absent/late saving for assigned classes
- Parent linked-child view, published reports and recent attendance
- Basic private talent metadata view (storage signed-link flow needs a trusted endpoint before production)
- Database schema for classes, students, attendance, admissions, reports, school events, timetable, library, notices, notifications and talent clips

## Not complete yet
- Admission document upload and automatic provisional admission-letter PDF
- Full marks-entry UI, automatic grading/position calculation, report card template and print-ready individual report
- Daily/monthly percentage analytics and teacher attendance entry UI
- Absence-triggered parent notifications and in-app notification centre read/unread UI
- Timetable/calendar/library content management interfaces
- Audited secure signed URL endpoint for private talent clips and library documents
- Full audit log, retention policy, backups, monitoring and independent security review

Do not use real student data until the school has approved the privacy policy and all incomplete security controls are finished.

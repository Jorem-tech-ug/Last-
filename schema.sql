-- Seeds of Gold Junior School - Supabase schema starter
-- Run in Supabase Dashboard > SQL Editor. Review and test policies before using real pupil data.
create extension if not exists pgcrypto;

create type public.school_role as enum ('admin','teacher','parent');
create type public.attendance_status as enum ('present','absent','late');
create type public.admission_status as enum ('submitted','reviewing','provisionally_accepted','declined','completed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role public.school_role not null default 'parent',
  phone text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  level text not null check (level in ('nursery','primary')),
  sort_order int not null default 0,
  active boolean not null default true
);
insert into public.classes(name,level,sort_order) values
('Baby','nursery',1),('Middle','nursery',2),('Top','nursery',3),
('P.1','primary',4),('P.2','primary',5),('P.3','primary',6),('P.4','primary',7),
('P.5','primary',8),('P.6','primary',9),('P.7','primary',10)
on conflict(name) do nothing;

create table public.students (
  id uuid primary key default gen_random_uuid(),
  student_code text unique not null,
  full_name text not null,
  date_of_birth date,
  residence text,
  class_id uuid references public.classes(id),
  study_mode text not null default 'Day' check(study_mode in ('Day','Boarding')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.parent_students (
  parent_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  relationship text default 'Parent/Guardian',
  primary key(parent_id,student_id)
);
create table public.teacher_classes (
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  primary key(teacher_id,class_id)
);
create table public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id),
  class_id uuid not null references public.classes(id),
  attendance_date date not null default current_date,
  status public.attendance_status not null,
  marked_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(student_id,attendance_date)
);
create table public.teacher_attendance (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id),
  attendance_date date not null default current_date,
  status public.attendance_status not null default 'present',
  recorded_by uuid references public.profiles(id),
  unique(teacher_id,attendance_date)
);
create table public.admission_enquiries (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  date_of_birth date not null,
  residence text not null,
  guardian_name text not null,
  guardian_phone text not null,
  guardian_email text,
  class_requested text not null check(class_requested in ('Baby','Middle','Top','P.1','P.2','P.3','P.4','P.5','P.6','P.7')),
  study_mode text not null check(study_mode in ('Day','Boarding')),
  notes text,
  status public.admission_status not null default 'submitted',
  created_at timestamptz not null default now()
);
create table public.report_cards (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id),
  term text not null check(term in ('Term 1','Term 2','Term 3')),
  academic_year int not null,
  marks jsonb not null default '{}'::jsonb,
  average numeric(5,2),
  grade text,
  position int,
  teacher_comment text,
  headteacher_comment text,
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(student_id,term,academic_year)
);
create table public.school_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  details text,
  event_date date not null,
  audience text not null default 'all' check(audience in ('all','parents','teachers')),
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.timetables (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id),
  weekday int not null check(weekday between 1 and 7),
  start_time time not null,
  end_time time not null,
  subject text not null,
  room text,
  created_by uuid references public.profiles(id)
);
create table public.library_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null check(category in ('nursery_book','primary_book','assignment','other')),
  class_id uuid references public.classes(id),
  description text,
  storage_path text,
  visibility text not null default 'signed_in' check(visibility in ('signed_in','teachers_only')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  audience text not null default 'all' check(audience in ('all','parents','teachers')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.talent_clips (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  storage_path text not null,
  approved boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- Helper functions are SECURITY DEFINER and have a fixed search_path.
create or replace function public.current_role()
returns public.school_role language sql stable security definer
set search_path = public
as $$ select role from public.profiles where id = auth.uid() and active = true $$;
create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$ select coalesce(public.current_role() = 'admin', false) $$;
create or replace function public.can_teach_class(target_class uuid)
returns boolean language sql stable security definer
set search_path = public
as $$ select public.is_admin() or exists(select 1 from public.teacher_classes where teacher_id=auth.uid() and class_id=target_class) $$;
create or replace function public.is_parent_of(target_student uuid)
returns boolean language sql stable security definer
set search_path = public
as $$ select exists(select 1 from public.parent_students where parent_id=auth.uid() and student_id=target_student) $$;

-- Automatically create a restricted parent profile for new Auth users.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
 insert into public.profiles(id,display_name,role)
 values(new.id, coalesce(new.raw_user_meta_data->>'display_name',''), 'parent')
 on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.parent_students enable row level security;
alter table public.teacher_classes enable row level security;
alter table public.attendance_records enable row level security;
alter table public.teacher_attendance enable row level security;
alter table public.admission_enquiries enable row level security;
alter table public.report_cards enable row level security;
alter table public.school_events enable row level security;
alter table public.timetables enable row level security;
alter table public.library_items enable row level security;
alter table public.announcements enable row level security;
alter table public.notifications enable row level security;
alter table public.talent_clips enable row level security;


-- Prevent a user from promoting their own account by editing profiles.role.
create or replace function public.prevent_self_role_change()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
  if new.role is distinct from old.role and not public.is_admin() then
    raise exception 'Only an administrator may change account roles';
  end if;
  return new;
end; $$;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role before update on public.profiles
for each row execute procedure public.prevent_self_role_change();

-- Profiles: user can see/update limited own profile; role changes are admin-only via SQL/dashboard.
create policy "profile read own or admin" on public.profiles for select to authenticated using(id=auth.uid() or public.is_admin());
create policy "profile update own non-role fields" on public.profiles for update to authenticated using(id=auth.uid() or public.is_admin()) with check(id=auth.uid() or public.is_admin());
create policy "classes visible to signed in" on public.classes for select to authenticated using(true);
create policy "classes admin manage" on public.classes for all to authenticated using(public.is_admin()) with check(public.is_admin());

create policy "students admin teacher linked parent read" on public.students for select to authenticated using(
 public.is_admin() or exists(select 1 from public.teacher_classes tc where tc.teacher_id=auth.uid() and tc.class_id=students.class_id) or public.is_parent_of(id));
create policy "students admin manage" on public.students for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "parent links own or admin read" on public.parent_students for select to authenticated using(parent_id=auth.uid() or public.is_admin());
create policy "parent links admin manage" on public.parent_students for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "teacher class own or admin read" on public.teacher_classes for select to authenticated using(teacher_id=auth.uid() or public.is_admin());
create policy "teacher class admin manage" on public.teacher_classes for all to authenticated using(public.is_admin()) with check(public.is_admin());

create policy "attendance read by relevant users" on public.attendance_records for select to authenticated using(public.is_admin() or public.can_teach_class(class_id) or public.is_parent_of(student_id));
create policy "attendance teacher insert assigned class" on public.attendance_records for insert to authenticated with check(public.can_teach_class(class_id) and exists(select 1 from public.students s where s.id=student_id and s.class_id=class_id));
create policy "attendance teacher update assigned class" on public.attendance_records for update to authenticated using(public.can_teach_class(class_id)) with check(public.can_teach_class(class_id));
create policy "teacher attendance read own or admin" on public.teacher_attendance for select to authenticated using(teacher_id=auth.uid() or public.is_admin());
create policy "teacher attendance admin manage" on public.teacher_attendance for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Public admission enquiry intake: only listed fields can be inserted by anon/authenticated; no public reads.
create policy "public submit admission enquiry" on public.admission_enquiries for insert to anon,authenticated with check(
 length(trim(student_name)) between 2 and 120 and length(trim(guardian_name)) between 2 and 120 and length(trim(guardian_phone)) between 5 and 40);
create policy "admin read admissions" on public.admission_enquiries for select to authenticated using(public.is_admin());
create policy "admin update admissions" on public.admission_enquiries for update to authenticated using(public.is_admin()) with check(public.is_admin());

create policy "reports relevant read" on public.report_cards for select to authenticated using(public.is_admin() or (published and public.is_parent_of(student_id)) or (public.current_role()='teacher' and exists(select 1 from public.students s where s.id=student_id and public.can_teach_class(s.class_id))));
create policy "reports admin teacher insert" on public.report_cards for insert to authenticated with check(public.is_admin() or (public.current_role()='teacher' and exists(select 1 from public.students s where s.id=student_id and public.can_teach_class(s.class_id))));
create policy "reports admin teacher update" on public.report_cards for update to authenticated using(public.is_admin() or (public.current_role()='teacher' and exists(select 1 from public.students s where s.id=student_id and public.can_teach_class(s.class_id)))) with check(public.is_admin() or (public.current_role()='teacher' and exists(select 1 from public.students s where s.id=student_id and public.can_teach_class(s.class_id))));

create policy "published events visible" on public.school_events for select to authenticated using(published or public.is_admin() or public.current_role()='teacher');
create policy "events admin manage" on public.school_events for all to authenticated using(public.is_admin()) with check(public.is_admin());
create or replace function public.parent_has_class(target_class uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.parent_students ps join public.students s on s.id=ps.student_id where ps.parent_id=auth.uid() and s.class_id=target_class) $$;
create policy "timetable relevant read" on public.timetables for select to authenticated using(public.can_teach_class(class_id) or public.parent_has_class(class_id));
create policy "timetable admin manage" on public.timetables for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "library signed in read" on public.library_items for select to authenticated using(public.is_admin() or (visibility='signed_in' and (public.current_role() in ('teacher','parent'))) or (visibility='teachers_only' and public.current_role()='teacher'));
create policy "library admin teacher manage" on public.library_items for all to authenticated using(public.is_admin() or public.current_role()='teacher') with check(public.is_admin() or public.current_role()='teacher');
create policy "announcements relevant read" on public.announcements for select to authenticated using(audience='all' or (audience='parents' and public.current_role()='parent') or (audience='teachers' and public.current_role()='teacher') or public.is_admin());
create policy "announcements admin manage" on public.announcements for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "notifications recipient read" on public.notifications for select to authenticated using(recipient_id=auth.uid() or public.is_admin());
create policy "notifications recipient mark read" on public.notifications for update to authenticated using(recipient_id=auth.uid()) with check(recipient_id=auth.uid());
create policy "talent approved read" on public.talent_clips for select to authenticated using((approved and public.current_role() in ('parent','teacher')) or public.is_admin());
create policy "talent admin manage" on public.talent_clips for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Private storage bucket. Create bucket in Storage UI with name talent-private and Public bucket OFF.
-- Storage policies:
-- insert: authenticated admin only; select: admin only (serve signed URLs through a trusted server/Edge Function).
-- Avoid granting broad storage read access. This starter frontend's signed URL call needs an appropriate server-side signed-URL endpoint in production.

-- SISTEM SEKOLAH ONLINE TERPADU V2.1
-- Supabase/PostgreSQL - jalankan utuh di SQL Editor pada project baru.

create extension if not exists pgcrypto;

do $$ begin
  create type public.app_role as enum ('ADMIN','KEPALA_SEKOLAH','GURU','WALI_KELAS','ORANG_TUA','SISWA','TAMU');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.attendance_status as enum ('H','S','I','A');
exception when duplicate_object then null; end $$;

create table if not exists public.schools (
 id uuid primary key default gen_random_uuid(), name text not null, npsn text, nss text,
 address text, village text, district text, regency text, province text, postal_code text,
 phone text, email text, website text, logo_url text, principal_name text, academic_year text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade, school_id uuid references public.schools(id) on delete cascade,
 full_name text not null default '', email text, role public.app_role not null default 'TAMU',
 active boolean not null default true, phone text, avatar_url text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.teachers (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 user_id uuid references auth.users(id) on delete set null, nip text, nuptk text, name text not null, email text, phone text,
 gender text, subject_specialization text, status text not null default 'Aktif', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.students (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 user_id uuid references auth.users(id) on delete set null, nis text, nisn text, name text not null, gender text,
 birth_place text, birth_date date, address text, phone text, parent_name text, parent_phone text,
 status text not null default 'Aktif', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.classes (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 name text not null, level text, major text, academic_year text, homeroom_teacher_id uuid references public.teachers(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.class_students (
 class_id uuid references public.classes(id) on delete cascade, student_id uuid references public.students(id) on delete cascade,
 joined_at date default current_date, primary key(class_id,student_id)
);

create table if not exists public.subjects (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 name text not null, code text, level text, kkm numeric(5,2) default 75, created_at timestamptz not null default now()
);
create table if not exists public.subject_teachers (
 subject_id uuid references public.subjects(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete cascade,
 class_id uuid references public.classes(id) on delete cascade, primary key(subject_id,teacher_id,class_id)
);

create table if not exists public.modules (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 teacher_id uuid references public.teachers(id) on delete set null, subject_id uuid references public.subjects(id) on delete set null,
 class_id uuid references public.classes(id) on delete set null, title text not null, identity jsonb not null default '{}'::jsonb,
 objectives text, prompt text, material text, activities text, lkpd text, media text, assessment text, reflection text,
 enrichment text, remedial text, sources text, status text default 'Draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.attendance (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 class_id uuid not null references public.classes(id) on delete cascade, subject_id uuid references public.subjects(id) on delete set null,
 student_id uuid not null references public.students(id) on delete cascade, teacher_id uuid references public.teachers(id) on delete set null,
 attendance_date date not null, period text, status public.attendance_status not null, note text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(student_id,attendance_date,class_id,subject_id,period)
);

create table if not exists public.grades (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 student_id uuid not null references public.students(id) on delete cascade, subject_id uuid references public.subjects(id) on delete set null,
 teacher_id uuid references public.teachers(id) on delete set null, class_id uuid references public.classes(id) on delete set null,
 assessment_type text not null, assessment_name text not null, score numeric(5,2) not null check(score between 0 and 100), weight numeric(6,2) default 1,
 note text, assessment_date date not null default current_date, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.followups (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 teacher_id uuid references public.teachers(id) on delete set null, student_id uuid references public.students(id) on delete set null,
 type text not null, title text not null, description text, status text not null default 'Open', due_date date, created_at timestamptz not null default now()
);
create table if not exists public.announcements (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 title text not null, content text not null, audience text not null default 'ALL', published boolean not null default true,
 publish_at timestamptz default now(), created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.school_programs (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 name text not null, category text, objective text, indicator text, start_date date, end_date date, target text, status text default 'Planned', progress numeric(5,2) default 0,
 owner_teacher_id uuid references public.teachers(id) on delete set null, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.supervisions (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 teacher_id uuid not null references public.teachers(id) on delete cascade, supervisor_id uuid references auth.users(id) on delete set null,
 observation_date date not null default current_date, class_id uuid references public.classes(id) on delete set null,
 planning_score numeric(5,2), opening_score numeric(5,2), learning_score numeric(5,2), assessment_score numeric(5,2), closing_score numeric(5,2),
 strengths text, recommendations text, followup text, status text default 'Draft', created_at timestamptz not null default now()
);
create table if not exists public.performance_indicators (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 code text, name text not null, category text, weight numeric(6,2) default 1, scale_min numeric(5,2) default 0, scale_max numeric(5,2) default 100, active boolean default true,
 created_at timestamptz not null default now()
);
create table if not exists public.performance_assessments (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 teacher_id uuid not null references public.teachers(id) on delete cascade, indicator_id uuid not null references public.performance_indicators(id) on delete cascade,
 assessor_id uuid references auth.users(id) on delete set null, period text, score numeric(5,2) not null check(score between 0 and 100), note text, created_at timestamptz not null default now()
);
create table if not exists public.decisions (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 title text not null, issue text, evidence text, options text, decision text, action_plan text, owner text, due_date date, status text default 'Open', created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.calendar_events (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schools(id) on delete cascade,
 title text not null, description text, start_at timestamptz not null, end_at timestamptz, audience text default 'ALL', location text,
 created_by uuid references auth.users(id) on delete set null, created_at timestamptz not null default now()
);
create table if not exists public.parent_students (
 parent_profile_id uuid references public.profiles(id) on delete cascade, student_id uuid references public.students(id) on delete cascade,
 relation text default 'Orang Tua/Wali', primary key(parent_profile_id,student_id)
);
create table if not exists public.audit_logs (
 id bigint generated always as identity primary key, school_id uuid references public.schools(id) on delete cascade, actor_id uuid references auth.users(id) on delete set null,
 action text not null, entity text, entity_id uuid, metadata jsonb default '{}'::jsonb, created_at timestamptz not null default now()
);

create index if not exists idx_profiles_school on profiles(school_id); create index if not exists idx_students_school on students(school_id);
create index if not exists idx_teachers_school on teachers(school_id); create index if not exists idx_classes_school on classes(school_id);
create index if not exists idx_attendance_school_date on attendance(school_id,attendance_date); create index if not exists idx_grades_school on grades(school_id);
create index if not exists idx_modules_school on modules(school_id); create index if not exists idx_programs_school on school_programs(school_id);
create index if not exists idx_supervision_school on supervisions(school_id); create index if not exists idx_audit_school on audit_logs(school_id,created_at desc);

create or replace function public.my_school_id() returns uuid language sql stable security definer set search_path=public as $$ select school_id from public.profiles where id=auth.uid() limit 1 $$;
create or replace function public.my_role() returns public.app_role language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() limit 1 $$;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select coalesce((select role='ADMIN' from public.profiles where id=auth.uid()),false) $$;
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$ select coalesce((select role in ('ADMIN','KEPALA_SEKOLAH','GURU','WALI_KELAS') from public.profiles where id=auth.uid()),false) $$;
create or replace function public.is_parent_of_student(p_student uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.parent_students ps join public.profiles p on p.id=ps.parent_profile_id where ps.student_id=p_student and ps.parent_profile_id=auth.uid() and p.school_id=public.my_school_id()) $$;
create or replace function public.is_self_student(p_student uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.students s where s.id=p_student and s.user_id=auth.uid()) $$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,school_id,full_name,email,role) values(new.id,nullif(new.raw_user_meta_data->>'school_id','')::uuid,coalesce(new.raw_user_meta_data->>'full_name',split_part(coalesce(new.email,''),'@',1)),new.email,coalesce((new.raw_user_meta_data->>'role')::public.app_role,'TAMU')) on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users; create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- RLS
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['schools','profiles','teachers','students','classes','class_students','subjects','subject_teachers','modules','attendance','grades','followups','announcements','school_programs','supervisions','performance_indicators','performance_assessments','decisions','calendar_events','parent_students','audit_logs'] LOOP
   EXECUTE format('alter table public.%I enable row level security',t);
 END LOOP;
END $$;

-- Untuk project baru, jalankan script ini sekali. Jika mengulang di project lama,
-- hapus policy lama hanya pada tabel SIS Terpadu, jangan menghapus policy aplikasi lain.
create policy schools_select on schools for select to authenticated using (id=my_school_id());
create policy schools_admin_update on schools for update to authenticated using (id=my_school_id() and is_admin()) with check(id=my_school_id() and is_admin());
create policy profiles_select on profiles for select to authenticated using (id=auth.uid() or (school_id=my_school_id() and is_admin()));
create policy profiles_admin_all on profiles for all to authenticated using (school_id=my_school_id() and is_admin()) with check(school_id=my_school_id() and is_admin());

-- Staff dapat mengelola data sekolah; orang tua/siswa hanya data yang relevan.
create policy teachers_staff_all on teachers for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy students_select on students for select to authenticated using (school_id=my_school_id() and (is_staff() or is_parent_of_student(id) or is_self_student(id)));
create policy students_staff_write on students for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy classes_staff_all on classes for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy class_students_staff_all on class_students for all to authenticated using ((select school_id from classes where id=class_id)=my_school_id() and is_staff()) with check((select school_id from classes where id=class_id)=my_school_id() and is_staff());
create policy subjects_staff_all on subjects for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy subject_teachers_staff_all on subject_teachers for all to authenticated using ((select school_id from subjects where id=subject_id)=my_school_id() and is_staff()) with check((select school_id from subjects where id=subject_id)=my_school_id() and is_staff());
create policy modules_staff_all on modules for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());

create policy attendance_select on attendance for select to authenticated using (school_id=my_school_id() and (is_staff() or is_parent_of_student(student_id) or is_self_student(student_id)));
create policy attendance_staff_write on attendance for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy grades_select on grades for select to authenticated using (school_id=my_school_id() and (is_staff() or is_parent_of_student(student_id) or is_self_student(student_id)));
create policy grades_staff_write on grades for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy followups_staff_all on followups for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy announcements_select on announcements for select to authenticated using (school_id=my_school_id() and (published=true or is_staff()));
create policy announcements_staff_all on announcements for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy programs_staff_all on school_programs for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy supervision_staff_all on supervisions for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy indicators_staff_all on performance_indicators for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy assessments_staff_all on performance_assessments for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy decisions_staff_all on decisions for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy calendar_select on calendar_events for select to authenticated using (school_id=my_school_id());
create policy calendar_staff_all on calendar_events for all to authenticated using (school_id=my_school_id() and is_staff()) with check(school_id=my_school_id() and is_staff());
create policy parent_students_select on parent_students for select to authenticated using ((parent_profile_id=auth.uid() or is_admin()) and (select school_id from public.profiles where id=parent_profile_id)=my_school_id());
create policy parent_students_admin_all on parent_students for all to authenticated using (is_admin() and (select school_id from public.profiles where id=parent_profile_id)=my_school_id()) with check(is_admin() and (select school_id from public.profiles where id=parent_profile_id)=my_school_id());
create policy audit_select on audit_logs for select to authenticated using (school_id=my_school_id() and (is_admin() or my_role()='KEPALA_SEKOLAH'));
create policy audit_insert on audit_logs for insert to authenticated with check(school_id=my_school_id() and actor_id=auth.uid());

-- Hak Data API minimal. Sesuaikan bila project Anda memakai konfigurasi Data API yang ketat.
grant usage on schema public to authenticated;
grant select,insert,update,delete on all tables in schema public to authenticated;
grant usage,select on all sequences in schema public to authenticated;
grant execute on all functions in schema public to authenticated;

-- Seed indikator kinerja: jalankan setelah sekolah dibuat, ganti UUID_SEKOLAH.
-- insert into performance_indicators(school_id,code,name,category,weight) values
-- ('UUID_SEKOLAH','PER-01','Perencanaan Pembelajaran','Perencanaan',20),
-- ('UUID_SEKOLAH','PER-02','Pelaksanaan Pembelajaran','Pelaksanaan',30),
-- ('UUID_SEKOLAH','PER-03','Asesmen Pembelajaran','Asesmen',20),
-- ('UUID_SEKOLAH','PER-04','Refleksi dan Tindak Lanjut','Tindak Lanjut',15),
-- ('UUID_SEKOLAH','PER-05','Administrasi dan Kolaborasi','Profesional',15);

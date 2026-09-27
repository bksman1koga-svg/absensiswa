-- ========================================================
-- SKEMA UTAMA DATABASE SIS TERPADU (Vercel + Supabase)
-- ========================================================

-- 1. HAPUS TABEL LAMA JIKA ADA (CASCADE)
DROP TABLE IF EXISTS public.parent_students CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.teachers CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.schools CASCADE;

-- 2. TABEL: SCHOOLS (SEKOLAH)
CREATE TABLE public.schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    academic_year TEXT DEFAULT '2026/2027',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABEL: PROFILES (PROFIL USER / ADMIN / GURU)
-- Catatan: Primary Key HANYA pada kolom 'id' yang terhubung ke auth.users
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    school_id UUID REFERENCES public.schools(id) ON DELETE SET NULL,
    full_name TEXT,
    role TEXT DEFAULT 'ADMIN',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABEL: TEACHERS (GURU)
CREATE TABLE public.teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    nip TEXT,
    full_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABEL: STUDENTS (SISWA)
CREATE TABLE public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    nis TEXT,
    nisn TEXT,
    full_name TEXT NOT NULL,
    gender CHAR(1),
    class_name TEXT,
    qr_code TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABEL: PARENT_STUDENTS (RELASI ORANG TUA - SISWA)
CREATE TABLE public.parent_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================================
-- PENGATURAN DATA DEFAULT & HAK AKSES (DISABLE RLS)
-- ========================================================

-- Nonaktifkan RLS agar tidak memblokir query aplikasi
ALTER TABLE public.schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_students DISABLE ROW LEVEL SECURITY;

-- Masukkan Data Sekolah Default
INSERT INTO public.schools (id, name, academic_year) 
VALUES ('00000000-0000-0000-0000-000000000001', 'SMA Negeri 1', '2026/2027')
ON CONFLICT (id) DO NOTHING;

-- ========================================================
-- OTOMATISASI TRIGGER (AUTO-SYNC PROFILES FROM AUTH.USERS)
-- ========================================================

-- Buat Fungsi Trigger untuk Menambahkan User Baru ke Profiles Otomatis
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, school_id, full_name, role, active)
  VALUES (
    NEW.id,
    '00000000-0000-0000-0000-000000000001',
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email, 'User Baru'),
    'ADMIN',
    TRUE
  )
  ON CONFLICT (id) DO UPDATE 
  SET 
    school_id = '00000000-0000-0000-0000-000000000001',
    role = 'ADMIN',
    active = TRUE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Pasang Trigger ke Tabel auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Synchronize User Terdaftar Saat Ini Ke Profiles
INSERT INTO public.profiles (id, school_id, full_name, role, active)
SELECT 
  id, 
  '00000000-0000-0000-0000-000000000001', 
  COALESCE(raw_user_meta_data->>'full_name', email, 'Admin Utama'), 
  'ADMIN', 
  TRUE
FROM auth.users
ON CONFLICT (id) DO UPDATE 
SET 
  school_id = '00000000-0000-0000-0000-000000000001',
  role = 'ADMIN',
  active = TRUE;

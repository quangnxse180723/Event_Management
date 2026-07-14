-- ==========================================
-- SCRIPT TẠO BẢNG CHO STUDENT ATTENDANCE APP
-- ==========================================

-- Bảng 1: University (Trường đại học)
CREATE TABLE IF NOT EXISTS public.university (
    university_id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    contact_info VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bảng 2: App User (Người dùng ứng dụng)
CREATE TABLE IF NOT EXISTS public.app_user (
    user_id BIGSERIAL PRIMARY KEY,
    auth_id UUID UNIQUE, -- Liên kết với auth.users của Supabase
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL, -- admin, organizer, student
    password_hash VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bảng 3: Student (Sinh viên)
CREATE TABLE IF NOT EXISTS public.student (
    student_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES public.app_user(user_id) ON DELETE CASCADE,
    university_id BIGINT REFERENCES public.university(university_id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    student_code VARCHAR(50) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bảng 4: Event (Sự kiện / Khóa học)
CREATE TABLE IF NOT EXISTS public.event (
    event_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES public.app_user(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    organizer VARCHAR(255),
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bảng 5: Event Session (Các buổi của sự kiện / buổi học)
CREATE TABLE IF NOT EXISTS public.event_session (
    session_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES public.event(event_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    location VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bảng 6: Student in Event (Sinh viên đăng ký tham gia sự kiện)
CREATE TABLE IF NOT EXISTS public.student_in_event (
    student_in_event_id BIGSERIAL PRIMARY KEY,
    event_id BIGINT REFERENCES public.event(event_id) ON DELETE CASCADE,
    student_id BIGINT REFERENCES public.student(student_id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'registered',
    rating INT DEFAULT 0,
    feedback TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, student_id)
);

-- Bảng 7: Session Checkin (Điểm danh buổi học)
CREATE TABLE IF NOT EXISTS public.session_checkin (
    checkin_id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES public.event_session(session_id) ON DELETE CASCADE,
    student_id BIGINT REFERENCES public.student(student_id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES public.app_user(user_id) ON DELETE CASCADE,
    method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(session_id, student_id)
);

-- ==========================================
-- Bật Row Level Security (RLS) cho tất cả bảng
-- ==========================================
ALTER TABLE public.university ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_in_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_checkin ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Các Policy mẫu: Mở full quyền cho môi trường Local
-- (Trên Production cần sửa lại để kiểm tra auth.uid() cho an toàn)
-- ==========================================
CREATE POLICY "Allow public all on university" ON public.university FOR ALL USING (true);
CREATE POLICY "Allow public all on app_user" ON public.app_user FOR ALL USING (true);
CREATE POLICY "Allow public all on student" ON public.student FOR ALL USING (true);
CREATE POLICY "Allow public all on event" ON public.event FOR ALL USING (true);
CREATE POLICY "Allow public all on event_session" ON public.event_session FOR ALL USING (true);
CREATE POLICY "Allow public all on student_in_event" ON public.student_in_event FOR ALL USING (true);
CREATE POLICY "Allow public all on session_checkin" ON public.session_checkin FOR ALL USING (true);

-- ==========================================
-- RPC Functions (Hàm hỗ trợ lấy dữ liệu cho App)
-- ==========================================
CREATE OR REPLACE FUNCTION get_checkin_status_for_session(session_id BIGINT)
RETURNS TABLE (
    student_id BIGINT,
    student_name VARCHAR,
    student_code VARCHAR,
    checkin_id BIGINT,
    method VARCHAR,
    checkin_time TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.student_id,
        s.name AS student_name,
        s.student_code,
        c.checkin_id,
        c.method,
        c.created_at AS checkin_time
    FROM public.student_in_event sie
    JOIN public.student s ON s.student_id = sie.student_id
    JOIN public.event_session es ON es.event_id = sie.event_id
    LEFT JOIN public.session_checkin c ON c.student_id = s.student_id AND c.session_id = es.session_id
    WHERE es.session_id = $1;
END;
$$;

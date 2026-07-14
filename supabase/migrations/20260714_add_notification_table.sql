-- ==========================================
-- Bảng Notification (Thông báo)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.notification (
    notification_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES public.app_user(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- Bật Row Level Security (RLS) cho bảng notification
-- ==========================================
ALTER TABLE public.notification ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policy mẫu: Mở full quyền cho bảng notification
-- ==========================================
CREATE POLICY "Allow public all on notification" ON public.notification FOR ALL USING (true);

-- ==========================================
-- Bật Realtime cho bảng notification
-- (Quan trọng: Phải chạy lệnh này để WebSockets push dữ liệu về App)
-- ==========================================
-- Nếu publication 'supabase_realtime' chưa có thì tạo mới (tránh lỗi)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication
        WHERE pubname = 'supabase_realtime'
    ) THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE public.notification;

-- ==========================================
-- Trigger tự động tạo thông báo khi có sự kiện mới
-- ==========================================
CREATE OR REPLACE FUNCTION notify_new_event() RETURNS TRIGGER AS $$
BEGIN
  -- Tạo một dòng thông báo cho tất cả user có role là 'student'
  INSERT INTO public.notification (user_id, title, message)
  SELECT 
    user_id, 
    'Sự kiện mới: ' || NEW.title, 
    'Một sự kiện mới vừa được tạo. Hãy vào xem và đăng ký tham gia ngay!'
  FROM public.app_user
  WHERE role = 'student';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Nếu trigger đã tồn tại thì xóa trước khi tạo lại
DROP TRIGGER IF EXISTS event_insert_trigger ON public.event;

CREATE TRIGGER event_insert_trigger
AFTER INSERT ON public.event
FOR EACH ROW EXECUTE FUNCTION notify_new_event();

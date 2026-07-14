# Event Management

## Kết nối cơ sở dữ liệu SQL

Ứng dụng dùng [Supabase](https://supabase.com/) làm backend SQL (PostgreSQL).
Schema có tại `supabase/migrations/20260527031425_init_tables.sql` (bản sao ở
`init_tables.sql`).

Mặc định ứng dụng kết nối tới Supabase project hiện có. Để kết nối database
của bạn, lấy **Project URL** và **anon/public key** trong Supabase Dashboard,
rồi chạy:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Không đưa `service_role` key vào ứng dụng Flutter. Hãy cấu hình Row Level
Security (RLS) trong Supabase để kiểm soát quyền dữ liệu.

## Khởi tạo schema

Tạo một Supabase project rồi chạy migration trong thư mục `supabase` bằng
Supabase CLI, hoặc dán nội dung migration vào SQL Editor của Supabase Dashboard.

## Dữ liệu mẫu

File `supabase/seed.sql` thêm 3 trường đại học, 9 người dùng mẫu, 6 sinh viên,
3 sự kiện, 6 phiên sự kiện, lượt đăng ký và điểm danh. Sau khi chạy toàn bộ
migration, chạy file này trong SQL Editor để seed dữ liệu. File có thể chạy lại
mà không tạo dữ liệu trùng.

## AI Event Chatbot Assistant

The app includes an event assistant tab named Poki. It reads event and
event_session data from Supabase, adds that data to the prompt as RAG context,
and calls Gemini through the REST generateContent API.

Run with a Gemini API key:

```bash
flutter run --dart-define=GEMINI_API_KEY=your-gemini-api-key
```

On Windows, you can put local secrets in `.env.local` and run:

```powershell
.\scripts\run_with_gemini.ps1
```

Optional model override:

```bash
flutter run --dart-define=GEMINI_API_KEY=your-gemini-api-key --dart-define=GEMINI_MODEL=gemini-3.1-flash-lite
```

Do not commit a real Gemini API key into source code.

## AI OCR student card

The student registration screen can capture a card photo or choose an image,
then calls OCR.space to fill the name, student code, and matching university.
The user must review the values before submitting the form.

1. Add `OCR_SPACE_API_KEY=your-key` to the ignored `.env.local` file.
2. Run `./scripts/run_with_gemini.ps1` on Windows, or use the configured
   Android Studio `main.dart` run target.

Apply `supabase/migrations/20260712010000_student_signup_profile.sql` in the
Supabase SQL Editor before testing registration. It creates the `app_user` and
`student` profile from Auth metadata, including when email confirmation is on.

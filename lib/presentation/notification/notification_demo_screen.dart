import 'package:flutter/material.dart';
import 'package:student_attendance/data/services/notification_service.dart';

class NotificationDemoScreen extends StatelessWidget {
  const NotificationDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Notification Service'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Demo các loại thông báo:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Success notification
            ElevatedButton.icon(
              onPressed: () {
                NotificationService.showSuccess(
                  context,
                  "Thao tác thành công! Dữ liệu đã được lưu.",
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Hiển thị thông báo Thành công'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Error notification
            ElevatedButton.icon(
              onPressed: () {
                NotificationService.showError(
                  context,
                  "Có lỗi xảy ra! Vui lòng kiểm tra lại thông tin.",
                );
              },
              icon: const Icon(Icons.error),
              label: const Text('Hiển thị thông báo Lỗi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Warning notification
            ElevatedButton.icon(
              onPressed: () {
                NotificationService.showWarning(
                  context,
                  "Cảnh báo: Vui lòng kiểm tra thông tin trước khi tiếp tục.",
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Hiển thị thông báo Cảnh báo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Info notification
            ElevatedButton.icon(
              onPressed: () {
                NotificationService.showInfo(
                  context,
                  "Thông tin: Dữ liệu đã được cập nhật thành công.",
                );
              },
              icon: const Icon(Icons.info),
              label: const Text('Hiển thị thông báo Thông tin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Divider(),
            
            const SizedBox(height: 20),
            
            const Text(
              'Thông báo tùy chỉnh:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Custom notification 1
            ElevatedButton.icon(
              onPressed: () {
                NotificationService.showCustom(
                  context,
                  "Thông báo tùy chỉnh với màu tím và icon sao!",
                  backgroundColor: Colors.purple,
                  textColor: Colors.white,
                  icon: Icons.star,
                  duration: const Duration(seconds: 5),
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('Thông báo tùy chỉnh (Tím + Sao)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Custom notification 2
            ElevatedButton.icon(
              onPressed: () {
                NotificationService.showCustom(
                  context,
                  "Thông báo với màu hồng và icon tim ❤️",
                  backgroundColor: Colors.pink,
                  textColor: Colors.white,
                  icon: Icons.favorite,
                  duration: const Duration(seconds: 4),
                );
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Thông báo tùy chỉnh (Hồng + Tim)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Divider(),
            
            const SizedBox(height: 20),
            
            // Hide notification button
            OutlinedButton.icon(
              onPressed: () {
                NotificationService.hide();
              },
              icon: const Icon(Icons.close),
              label: const Text('Ẩn thông báo hiện tại'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class Event {
  final int? id;
  final int? userId;
  final String title;
  final String description;
  final String organizer;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final String? location;
  final String? category; // Danh mục sự kiện

  Event({
    this.id,
    this.userId,
    required this.title,
    required this.description,
    required this.organizer,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.location,
    this.category,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['event_id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      organizer: json['organizer'] ?? '',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : DateTime.now(),
      imageUrl: json['image_url'],
      location: json['location'],
      category: json['category'] as String?,
    );
  }

// Hàm toJson không cần thiết khi dùng cách tiếp cận này,
// vì chúng ta tạo Map dữ liệu trực tiếp trong màn hình Create/Edit.
// Bạn có thể giữ hoặc xóa nó đi.
}
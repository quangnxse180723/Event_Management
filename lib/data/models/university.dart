class University {
  final int? universityId;   // nullable
  final String name;
  final String? address;
  final String? contactInfo;

  University({
    this.universityId,
    required this.name,
    this.address,
    this.contactInfo,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      universityId: json['university_id'] as int?,
      name: json['name'] as String,
      address: json['address'] as String?,
      contactInfo: json['contact_info'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (universityId != null) 'university_id': universityId, // chỉ gửi khi update
      'name': name,
      'address': address,
      'contact_info': contactInfo,
    };
  }
}

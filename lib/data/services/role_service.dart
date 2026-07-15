class RoleService {
  static bool isAdmin(Map<String, dynamic> user) {
    return user['role'] == 'Admin';
  }

  static bool isOrganizer(Map<String, dynamic> user) {
    return user['role'] == 'Event Organizer';
  }

  static bool isStudent(Map<String, dynamic> user) {
    return user['role'] == 'Student';
  }
}

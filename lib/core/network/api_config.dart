class ApiConfig {
  // Use your local IP address instead of localhost so that the Android device can connect to your PC's backend

  static const String baseUrl = 'http://192.168.29.55:5000/api';
  static const String checkSetup = '$baseUrl/users/check-setup';
  static const String setupPrincipal = '$baseUrl/users/setup';
  static const String login = '$baseUrl/users/login';
  static const String pinLogin = '$baseUrl/users/pin-login';
  static const String resetSetup = '$baseUrl/users/reset-setup';

  static const String academicSession = '$baseUrl/academic';
  static const String teachers = '$baseUrl/teachers';
  static const String classes = '$baseUrl/classes';
  static const String fees = '$baseUrl/fees';
  static const String students = '$baseUrl/students';
  static const String sendMessage = '$baseUrl/students/send-message';
  static const String certificates = '$baseUrl/certificates';
  static const String recentCertificates = '$baseUrl/certificates/recent';

  // Examination
  static const String exams = '$baseUrl/exams';
  static const String examMarks = '$baseUrl/exams/marks';
  static const String reportCard = '$baseUrl/exams/report-card';
}
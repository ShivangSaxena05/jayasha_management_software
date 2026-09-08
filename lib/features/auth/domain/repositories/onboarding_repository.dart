import 'package:jayasha_childrens_academy/core/models/principal.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';

abstract class OnboardingRepository {
  // Check if school is already set up
  Future<bool> isSchoolSetup();

  // Initial setup (POST all data)
  Future<bool> setupPrincipal({
    required String name,
    required String securityPin,
    required Principal principalDetails,
  });

  // Login with PIN
  Future<bool> loginWithPin(String pin);

  // Local storage methods (keep them for temporary state if needed)
  Future<void> savePrincipalDetails(Principal principal);
  Future<void> saveAcademicSession(AcademicSession session);
  Future<void> saveTeachersDetails(List<Teacher> teachers);
  Future<void> saveFeeStructure(Map<String, Map<String, double>> fees);

  Future<Principal?> getPrincipalDetails();
  Future<Principal?> getPrincipalProfileFromServer();
  Future<bool> updatePrincipalProfile(Principal principal);
  Future<AcademicSession?> getAcademicSession();
  Future<List<Teacher>> getTeachersDetails();

  Future<bool> isOnboardingComplete();
  Future<void> clearOnboardingData();

  // Sync data to server after setup
  Future<void> syncOnboardingData();

  // File upload
  Future<String?> uploadFile(String filePath, String fieldName);
}

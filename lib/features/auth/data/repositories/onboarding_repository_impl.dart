import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/models/principal.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/features/auth/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _tokenKey = 'auth_token';
  static const String _principalKey = 'principal_details';
  static const String _academicSessionKey = 'academic_session';
  static const String _teachersKey = 'teachers_details';
  static const String _feesKey = 'fee_structure';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  @override
  Future<bool> isSchoolSetup() async {
    try {
      print('DEBUG: Checking school setup at ${ApiConfig.checkSetup}');
      final response = await http.get(Uri.parse(ApiConfig.checkSetup));
      print('DEBUG: isSchoolSetup status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isSetup'] ?? false;
      }
      print('DEBUG: isSchoolSetup failed with body: ${response.body}');
      return false;
    } catch (e) {
      print('DEBUG: Error in isSchoolSetup: $e');
      return false;
    }
  }

  @override
  Future<bool> setupPrincipal({
    required String name,
    required String securityPin,
    required Principal principalDetails,
  }) async {
    try {
      print('DEBUG: Setting up principal at ${ApiConfig.setupPrincipal}');
      final response = await http.post(
        Uri.parse(ApiConfig.setupPrincipal),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'securityPin': securityPin,
          'principalDetails': principalDetails.toJson(),
        }),
      );

      print('DEBUG: setupPrincipal status code: ${response.statusCode}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        await prefs.setBool(_onboardingCompleteKey, true);
        return true;
      }
      print('DEBUG: setupPrincipal failed with body: ${response.body}');
      return false;
    } catch (e) {
      print('DEBUG: Error in setupPrincipal: $e');
      return false;
    }
  }

  @override
  Future<bool> loginWithPin(String pin) async {
    try {
      print('DEBUG: Logging in with PIN at ${ApiConfig.pinLogin}');
      final response = await http.post(
        Uri.parse(ApiConfig.pinLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'securityPin': pin}),
      );

      print('DEBUG: loginWithPin status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        return true;
      }
      print('DEBUG: loginWithPin failed with body: ${response.body}');
      return false;
    } catch (e) {
      print('DEBUG: Error in loginWithPin: $e');
      return false;
    }
  }

  // Local state management for onboarding steps
  @override
  Future<void> savePrincipalDetails(Principal principal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_principalKey, jsonEncode(principal.toJson()));
  }

  @override
  Future<void> saveAcademicSession(AcademicSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_academicSessionKey, jsonEncode(session.toJson()));

    // Also try to save to server if token exists
    final token = prefs.getString(_tokenKey);
    if (token != null) {
       try {
         print('DEBUG: Saving academic session to ${ApiConfig.academicSession}');
         final response = await http.post(
          Uri.parse(ApiConfig.academicSession),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode(session.toJson()),
        );
         print('DEBUG: saveAcademicSession status code: ${response.statusCode}');
       } catch (e) {
         print('DEBUG: Error in saveAcademicSession (server): $e');
       }
    }
  }

  @override
  Future<void> saveTeachersDetails(List<Teacher> teachers) async {
    final prefs = await SharedPreferences.getInstance();
    final teachersJson = teachers.map((t) => t.toJson()).toList();
    await prefs.setString(_teachersKey, jsonEncode(teachersJson));

    final token = prefs.getString(_tokenKey);
    if (token != null) {
      try {
        print('DEBUG: Saving teachers details to ${ApiConfig.teachers}');
        final response = await http.post(
          Uri.parse(ApiConfig.teachers),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode({'teachers': teachersJson}),
        );
        print('DEBUG: saveTeachersDetails status code: ${response.statusCode}');
        if (response.statusCode != 200 && response.statusCode != 201) {
          print('DEBUG: saveTeachersDetails failed with body: ${response.body}');
        }
      } catch (e) {
        print('DEBUG: Error in saveTeachersDetails (server): $e');
      }
    }
  }

  @override
  Future<void> saveFeeStructure(Map<String, Map<String, double>> fees) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feesKey, jsonEncode(fees));

    final token = prefs.getString(_tokenKey);
    if (token != null) {
      // Syncing fees requires session and class IDs which might not be available yet.
      // We'll handle this in syncOnboardingData
      await syncOnboardingData();
    }
  }

  @override
  Future<Principal?> getPrincipalDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final principalJson = prefs.getString(_principalKey);
    if (principalJson == null) return null;
    return Principal.fromJson(jsonDecode(principalJson));
  }

  @override
  Future<Principal?> getPrincipalProfileFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final principal = Principal.fromJson(data);
        // Sync to local storage
        await savePrincipalDetails(principal);
        return principal;
      }
      return null;
    } catch (e) {
      print('DEBUG: Error in getPrincipalProfileFromServer: $e');
      return null;
    }
  }

  @override
  Future<bool> updatePrincipalProfile(Principal principal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(principal.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedPrincipal = Principal.fromJson(data);
        await savePrincipalDetails(updatedPrincipal);
        return true;
      }
      return false;
    } catch (e) {
      print('DEBUG: Error in updatePrincipalProfile: $e');
      return false;
    }
  }

  @override
  Future<AcademicSession?> getAcademicSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_academicSessionKey);
    if (sessionJson == null) return null;
    return AcademicSession.fromJson(jsonDecode(sessionJson));
  }

  @override
  Future<List<Teacher>> getTeachersDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final teachersJson = prefs.getString(_teachersKey);
    if (teachersJson == null) return [];
    final List<dynamic> decoded = jsonDecode(teachersJson);
    return decoded.map((item) => Teacher.fromJson(item)).toList();
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  @override
  Future<void> clearOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();

    // Call backend to reset setup first (deletes all DB data)
    try {
      print('DEBUG: Resetting setup on server (wiping database)...');
      final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/users/reset-setup'));
      print('DEBUG: Reset setup status code: ${response.statusCode}');
    } catch (e) {
      print('DEBUG: Error resetting server setup: $e');
    }

    // Now clear all local storage
    await prefs.clear();
    print('DEBUG: Local SharedPreferences cleared.');
  }

  @override
  Future<void> syncOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      print('DEBUG: No auth token found, skipping sync.');
      return;
    }

    // 1. Sync Academic Session & Classes
    final session = await getAcademicSession();
    if (session != null) {
      print('DEBUG: Syncing academic session...');
      final sessionResponse = await http.post(
        Uri.parse(ApiConfig.academicSession),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(session.toJson()),
      );

      print('DEBUG: Sync academic session status: ${sessionResponse.statusCode}');

      if (sessionResponse.statusCode == 200 || sessionResponse.statusCode == 201) {
        final sessionData = jsonDecode(sessionResponse.body);
        final sessionId = sessionData['_id'];

        // 2. Sync Fees (Requires classes created above)
        final feesJson = prefs.getString(_feesKey);
        if (feesJson != null) {
          print('DEBUG: Syncing fee structure...');
          final Map<String, dynamic> fees = jsonDecode(feesJson);

          // Get created classes from server for THIS session to match IDs
          final classesResponse = await http.get(
            Uri.parse('${ApiConfig.classes}?sessionId=$sessionId'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (classesResponse.statusCode == 200) {
            final List<dynamic> serverClasses = jsonDecode(classesResponse.body);
            final List<Map<String, dynamic>> feePayload = [];

            for (var entry in fees.entries) {
              final className = entry.key;
              final components = entry.value as Map<String, dynamic>;

              final serverClass = serverClasses.firstWhere(
                (c) => (c['name'] == className),
                orElse: () => null,
              );

              if (serverClass != null) {
                feePayload.add({
                  'academicSessionId': sessionId,
                  'classId': serverClass['_id'],
                  'components': [
                    {
                      'name': 'Monthly Tuition Fee',
                      'amount': components['Monthly Tuition Fee'],
                      'frequency': 'monthly'
                    },
                    {
                      'name': 'Annual Admission Fee',
                      'amount': components['Annual Admission Fee'],
                      'frequency': 'annually'
                    },
                    {
                      'name': 'Examination Fee',
                      'amount': components['Examination Fee'],
                      'frequency': 'term-wise'
                    },
                  ]
                });
              } else {
                print('DEBUG: Could not find server class ID for $className');
              }
            }

            if (feePayload.isNotEmpty) {
              final feeResponse = await http.post(
                Uri.parse('${ApiConfig.baseUrl}/fees/structure'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token'
                },
                body: jsonEncode({'fees': feePayload}),
              );
              print('DEBUG: Sync fee structure status: ${feeResponse.statusCode}');
            }
          } else {
            print('DEBUG: Failed to fetch classes for fee sync: ${classesResponse.statusCode}');
          }
        }
      } else {
        print('DEBUG: Academic session sync failed: ${sessionResponse.body}');
      }
    }

    // 3. Sync Teachers
    final teachers = await getTeachersDetails();
    if (teachers.isNotEmpty) {
      print('DEBUG: Syncing ${teachers.length} teachers...');
      final teachersJson = teachers.map((t) => t.toJson()).toList();
      final response = await http.post(
        Uri.parse(ApiConfig.teachers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'teachers': teachersJson}),
      );
      print('DEBUG: Sync teachers status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('DEBUG: Teachers sync failed: ${response.body}');
      }
    }
  }

  @override
  Future<String?> uploadFile(String filePath, String fieldName) async {
    try {
      print('DEBUG: Uploading file $filePath to ${ApiConfig.baseUrl}/upload/photo');
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/upload/photo'));
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));
      // Using 'photo' as generic field name for single uploads as per route

      final response = await request.send();
      print('DEBUG: uploadFile status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['url'];
      } else {
        final respStr = await response.stream.bytesToString();
        print('DEBUG: uploadFile failed with body: $respStr');
      }
      return null;
    } catch (e) {
      print('DEBUG: Error in uploadFile: $e');
      return null;
    }
  }
}

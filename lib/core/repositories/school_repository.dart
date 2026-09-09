import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/school_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchoolRepository {
  Future<SchoolSettings> getSettings() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/school/settings'),
      headers: ApiConfig.headers(),
    );

    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load school settings');
    }
  }

  Future<SchoolSettings> updateSettings(SchoolSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/school/settings'),
      headers: {
        ...ApiConfig.headers(),
        'Authorization': 'Bearer $token',
      },
      body: json.encode(settings.toJson()),
    );

    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to update school settings');
    }
  }
}

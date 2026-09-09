import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/core/models/school_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';

class SchoolRepository extends ChangeNotifier {
  SchoolSettings? _settings;
  SchoolSettings? get settings => _settings;

  Future<SchoolSettings> getSettings() async {
    final response = await ApiClient.get(
      '${ApiConfig.baseUrl}/school/settings',
    );

    if (response.statusCode == 200) {
      _settings = SchoolSettings.fromJson(json.decode(response.body));
      notifyListeners();
      return _settings!;
    } else {
      throw Exception('Failed to load school settings');
    }
  }

  Future<SchoolSettings> updateSettings(SchoolSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await ApiClient.put(
      '${ApiConfig.baseUrl}/school/settings',
      settings.toJson(),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _settings = SchoolSettings.fromJson(json.decode(response.body));
      notifyListeners();
      return _settings!;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to update school settings');
    }
  }
}

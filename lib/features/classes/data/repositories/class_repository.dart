import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import '../models/school_class.dart';

class ClassRepository extends ChangeNotifier {
  List<SchoolClass> _classes = [];
  bool _isLoading = false;

  List<SchoolClass> get classes => _classes;
  List<String> get classNames => _classes.map((c) => c.name).toList();
  bool get isLoading => _isLoading;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<dynamic>> getClasses() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.classes),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error getting classes: $e');
    }
    return [];
  }

  Future<void> fetchClasses(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.classes}?sessionId=$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _classes = data.map((json) => SchoolClass.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching classes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addClass(String sessionId, String name, List<String> sections) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.classes}/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'academicSessionId': sessionId,
          'name': name,
          'sections': sections,
        }),
      );

      if (response.statusCode == 201) {
        final newClass = SchoolClass.fromJson(jsonDecode(response.body));
        _classes.add(newClass);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding class: $e');
    }
    return false;
  }

  Future<bool> updateClass(SchoolClass updatedClass) async {
    if (updatedClass.id == null) return false;

    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.classes}/${updatedClass.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedClass.toJson()),
      );

      if (response.statusCode == 200) {
        final index = _classes.indexWhere((c) => c.id == updatedClass.id);
        if (index != -1) {
          _classes[index] = updatedClass;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating class: $e');
    }
    return false;
  }

  SchoolClass? getClassByName(String name) {
    try {
      return _classes.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  // Local helper for backward compatibility or placeholder
  SchoolClass? getClass(String name) => getClassByName(name);

  void updateFeeStructure(String className, Map<String, double> newFees) {
    final index = _classes.indexWhere((c) => c.name == className);
    if (index != -1) {
      _classes[index] = _classes[index].copyWith(feeStructure: newFees);
      notifyListeners();
      // In a real app, also call backend to save FeeStructure
    }
  }

  void updateTimetableEntry(String className, int period, int day, TimetableEntry? entry) {
    final index = _classes.indexWhere((c) => c.name == className);
    if (index != -1) {
      final currentTimetable = List<List<TimetableEntry?>>.from(
        _classes[index].timetable.map((row) => List<TimetableEntry?>.from(row))
      );
      currentTimetable[period][day] = entry;
      _classes[index] = _classes[index].copyWith(timetable: currentTimetable);
      notifyListeners();
      // In a real app, also call backend to save Timetable
    }
  }
}

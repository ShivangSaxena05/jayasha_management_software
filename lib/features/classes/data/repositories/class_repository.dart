import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jayasha_childrens_academy/core/network/api_config.dart';
import 'package:jayasha_childrens_academy/features/fees/data/models/fee_structure.dart';
import 'package:jayasha_childrens_academy/services/api_client.dart';
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
      final response = await ApiClient.get(
        ApiConfig.classes,
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
      final response = await ApiClient.get(
        '${ApiConfig.classes}?sessionId=$sessionId',
        headers: {
          'Authorization': 'Bearer $token',
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
      final response = await ApiClient.post(
        '${ApiConfig.classes}/add',
        {
          'academicSessionId': sessionId,
          'name': name,
          'sections': sections,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
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
      final response = await ApiClient.put(
        '${ApiConfig.classes}/${updatedClass.id}',
        updatedClass.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final index = _classes.indexWhere((c) => c.id == updatedClass.id);
        if (index != -1) {
          _classes[index] = updatedClass;
          notifyListeners();
        }
        return true;
      } else {
        debugPrint('Failed to update class. Status: ${response.statusCode}, Body: ${response.body}');
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

  Future<bool> updateFeeStructure(String classId, List<FeeComponent> newFees) async {
    final index = _classes.indexWhere((c) => c.id == classId);
    if (index != -1) {
      final updatedClass = _classes[index].copyWith(feeStructure: newFees);
      try {
        final success = await updateClass(updatedClass);
        return success;
      } catch (e) {
        debugPrint('Error updating fee structure: $e');
        return false;
      }
    }
    return false;
  }

  Future<bool> updateTimetableEntry(String classId, int period, int day, TimetableEntry? entry) async {
    final index = _classes.indexWhere((c) => c.id == classId);
    if (index != -1) {
      final currentTimetable = List<List<TimetableEntry?>>.from(
        _classes[index].timetable.map((row) => List<TimetableEntry?>.from(row))
      );
      currentTimetable[period][day] = entry;
      final updatedClass = _classes[index].copyWith(timetable: currentTimetable);

      try {
        final success = await updateClass(updatedClass);
        return success;
      } catch (e) {
        debugPrint('Error updating timetable: $e');
        return false;
      }
    }
    return false;
  }

  Future<bool> addSubjectToClass(String classId, String subject) async {
    final index = _classes.indexWhere((c) => c.id == classId);
    if (index == -1) return false;

    final currentClass = _classes[index];
    if (currentClass.subjects.contains(subject)) return true;

    final updatedSubjects = List<String>.from(currentClass.subjects)..add(subject);
    final updatedClass = currentClass.copyWith(subjects: updatedSubjects);

    try {
      final success = await updateClass(updatedClass);
      return success;
    } catch (e) {
      debugPrint('Error adding subject to class: $e');
      return false;
    }
  }

  Future<bool> updateClassSubjects(String classId, List<String> subjects) async {
    final index = _classes.indexWhere((c) => c.id == classId);
    if (index == -1) return false;

    final updatedClass = _classes[index].copyWith(subjects: subjects);
    return await updateClass(updatedClass);
  }

  Future<bool> updateNumberOfPeriods(String classId, int newCount) async {
    final index = _classes.indexWhere((c) => c.id == classId);
    if (index == -1) return false;

    final currentClass = _classes[index];
    if (currentClass.numberOfPeriods == newCount) return true;

    final updatedClass = currentClass.copyWith(numberOfPeriods: newCount);
    // When updating numberOfPeriods, the backend should handle timetable resizing
    // to preserve existing data where possible or re-initialize.
    // Our updateClass call sends the whole object, but if we change numberOfPeriods
    // locally, the 'timetable' getter in SchoolClass might behave differently if not handled.
    // However, the model uses 'numberOfPeriods' to generate/parse.

    return await updateClass(updatedClass);
  }
}

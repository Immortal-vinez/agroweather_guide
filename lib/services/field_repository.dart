// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field_polygon.dart';

/// Repository for storing and retrieving field polygons locally
class FieldRepository {
  static const String _fieldsKey = 'saved_fields';
  static const String _activeFieldKey = 'active_field_id';

  /// Save a field to local storage
  Future<bool> saveField(FieldPolygon field) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fields = await getAllFields();

      // Check if field already exists (by ID or name)
      final existingIndex = fields.indexWhere((f) =>
          (field.id != null && f.id == field.id) || f.name == field.name);

      if (existingIndex >= 0) {
        // Update existing field
        fields[existingIndex] = field;
      } else {
        // Add new field
        fields.add(field);
      }

      final jsonList = fields.map((f) => f.toLocalJson()).toList();
      return await prefs.setString(_fieldsKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving field: $e');
      return false;
    }
  }

  /// Get all saved fields
  Future<List<FieldPolygon>> getAllFields() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_fieldsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => FieldPolygon.fromLocalJson(json)).toList();
    } catch (e) {
      print('Error getting fields: $e');
      return [];
    }
  }

  /// Get a specific field by ID
  Future<FieldPolygon?> getFieldById(String id) async {
    try {
      final fields = await getAllFields();
      return fields.firstWhere(
        (f) => f.id == id,
        orElse: () => throw Exception('Field not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get a specific field by name
  Future<FieldPolygon?> getFieldByName(String name) async {
    try {
      final fields = await getAllFields();
      return fields.firstWhere(
        (f) => f.name == name,
        orElse: () => throw Exception('Field not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Delete a field
  Future<bool> deleteField(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fields = await getAllFields();

      fields.removeWhere((f) => f.id == id);

      final jsonList = fields.map((f) => f.toLocalJson()).toList();
      return await prefs.setString(_fieldsKey, json.encode(jsonList));
    } catch (e) {
      print('Error deleting field: $e');
      return false;
    }
  }

  /// Delete a field by name
  Future<bool> deleteFieldByName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fields = await getAllFields();

      fields.removeWhere((f) => f.name == name);

      final jsonList = fields.map((f) => f.toLocalJson()).toList();
      return await prefs.setString(_fieldsKey, json.encode(jsonList));
    } catch (e) {
      print('Error deleting field: $e');
      return false;
    }
  }

  /// Clear all fields
  Future<bool> clearAllFields() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_fieldsKey);
    } catch (e) {
      print('Error clearing fields: $e');
      return false;
    }
  }

  /// Set active field (the field currently being monitored)
  Future<bool> setActiveField(String? fieldId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (fieldId == null) {
        return await prefs.remove(_activeFieldKey);
      }
      return await prefs.setString(_activeFieldKey, fieldId);
    } catch (e) {
      print('Error setting active field: $e');
      return false;
    }
  }

  /// Get active field ID
  Future<String?> getActiveFieldId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeFieldKey);
    } catch (e) {
      print('Error getting active field: $e');
      return null;
    }
  }

  /// Get active field
  Future<FieldPolygon?> getActiveField() async {
    try {
      final fieldId = await getActiveFieldId();
      if (fieldId == null) return null;
      return await getFieldById(fieldId);
    } catch (e) {
      print('Error getting active field: $e');
      return null;
    }
  }

  /// Check if a field with the given name already exists
  Future<bool> fieldExists(String name) async {
    final fields = await getAllFields();
    return fields.any((f) => f.name.toLowerCase() == name.toLowerCase());
  }

  /// Get total number of saved fields
  Future<int> getFieldCount() async {
    final fields = await getAllFields();
    return fields.length;
  }
}

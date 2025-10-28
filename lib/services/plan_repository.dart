import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/planned_crop.dart';
import '../models/plan_task.dart';

class PlanRepository {
  static const _key = 'planned_crops_v1';

  Future<List<PlannedCrop>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    final List<dynamic> list = json.decode(jsonStr);
    return list
        .map((e) => PlannedCrop.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<PlannedCrop> crops) async {
    final prefs = await SharedPreferences.getInstance();
    final list = crops.map((e) => e.toMap()).toList();
    await prefs.setString(_key, json.encode(list));
  }

  Future<void> upsert(PlannedCrop crop) async {
    final items = await load();
    final idx = items.indexWhere((c) => c.id == crop.id);
    if (idx >= 0) {
      items[idx] = crop;
    } else {
      items.add(crop);
    }
    await save(items);
  }

  Future<void> remove(String id) async {
    final items = await load();
    items.removeWhere((c) => c.id == id);
    await save(items);
  }

  Future<void> updateTaskCompleted(
    String cropId,
    String taskId,
    bool completed,
  ) async {
    final items = await load();
    final idx = items.indexWhere((c) => c.id == cropId);
    if (idx == -1) return;
    final crop = items[idx];
    final tIdx = crop.tasks.indexWhere((t) => t.id == taskId);
    if (tIdx == -1) return;
    final updatedTasks = List.of(crop.tasks);
    updatedTasks[tIdx] = updatedTasks[tIdx].copyWith(completed: completed);
    items[idx] = crop.copyWith(tasks: updatedTasks);
    await save(items);
  }

  Future<void> deleteTask(String cropId, String taskId) async {
    final items = await load();
    final idx = items.indexWhere((c) => c.id == cropId);
    if (idx == -1) return;
    final crop = items[idx];
    final updatedTasks = List.of(crop.tasks)
      ..removeWhere((t) => t.id == taskId);
    items[idx] = crop.copyWith(tasks: updatedTasks);
    await save(items);
  }

  Future<void> rescheduleTask(
    String cropId,
    String taskId,
    DateTime newDue,
  ) async {
    final items = await load();
    final idx = items.indexWhere((c) => c.id == cropId);
    if (idx == -1) return;
    final crop = items[idx];
    final tIdx = crop.tasks.indexWhere((t) => t.id == taskId);
    if (tIdx == -1) return;
    final updatedTasks = List.of(crop.tasks);
    updatedTasks[tIdx] = updatedTasks[tIdx].copyWith(due: newDue);
    updatedTasks.sort((a, b) => a.due.compareTo(b.due));
    items[idx] = crop.copyWith(tasks: updatedTasks);
    await save(items);
  }

  Future<void> addTask(String cropId, PlanTask task) async {
    final items = await load();
    final idx = items.indexWhere((c) => c.id == cropId);
    if (idx == -1) return;
    final crop = items[idx];
    final updated = List.of(crop.tasks)..add(task);
    updated.sort((a, b) => a.due.compareTo(b.due));
    items[idx] = crop.copyWith(tasks: updated);
    await save(items);
  }
}

import 'dart:convert';
import 'plan_task.dart';

class PlannedCrop {
  final String id;
  final String name;
  final String icon;
  final DateTime plantingDate;
  final String? variety;
  final List<PlanTask> tasks;

  PlannedCrop({
    required this.id,
    required this.name,
    required this.icon,
    required this.plantingDate,
    this.variety,
    required this.tasks,
  });

  PlannedCrop copyWith({
    String? id,
    String? name,
    String? icon,
    DateTime? plantingDate,
    String? variety,
    List<PlanTask>? tasks,
  }) {
    return PlannedCrop(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      plantingDate: plantingDate ?? this.plantingDate,
      variety: variety ?? this.variety,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'plantingDate': plantingDate.toIso8601String(),
      'variety': variety,
      'tasks': tasks.map((t) => t.toMap()).toList(),
    };
  }

  static PlannedCrop fromMap(Map<String, dynamic> map) {
    return PlannedCrop(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      plantingDate: DateTime.parse(map['plantingDate'] as String),
      variety: map['variety'] as String?,
      tasks:
          (map['tasks'] as List<dynamic>?)
              ?.map((e) => PlanTask.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String toJson() => json.encode(toMap());
  static PlannedCrop fromJson(String source) => fromMap(json.decode(source));
}

import 'dart:convert';

enum TaskType { weeding, pestControl, fertilization, irrigation, harvest, other }

class PlanTask {
  final String id;
  final DateTime due;
  final TaskType type;
  final String title;
  final String description;
  final bool completed;

  PlanTask({
    required this.id,
    required this.due,
    required this.type,
    required this.title,
    required this.description,
    this.completed = false,
  });

  PlanTask copyWith({
    String? id,
    DateTime? due,
    TaskType? type,
    String? title,
    String? description,
    bool? completed,
  }) {
    return PlanTask(
      id: id ?? this.id,
      due: due ?? this.due,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'due': due.toIso8601String(),
      'type': type.name,
      'title': title,
      'description': description,
      'completed': completed,
    };
  }

  static PlanTask fromMap(Map<String, dynamic> map) {
    return PlanTask(
      id: map['id'] as String,
      due: DateTime.parse(map['due'] as String),
      type: TaskType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TaskType.other,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      completed: map['completed'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());
  static PlanTask fromJson(String source) => fromMap(json.decode(source));
}

import 'dart:async';
import '../models/plan_task.dart';
import 'plan_repository.dart';
import 'notification_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final PlanRepository _repo = PlanRepository();
  Timer? _timer;

  void start() {
    _timer?.cancel();
    // Check every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkDue());
    // Also run immediately on start
    _checkDue();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkDue() async {
    final items = await _repo.load();
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(minutes: 1));
    final windowEnd = now.add(const Duration(minutes: 1));

    for (final crop in items) {
      for (final task in crop.tasks) {
        if (task.completed) continue;
        if (task.due.isAfter(windowStart) && task.due.isBefore(windowEnd)) {
          await NotificationService.showNotification(
            title: '${_taskEmoji(task.type)} ${task.title}',
            body: '${crop.icon} ${crop.name}: ${task.description}',
          );
        }
      }
    }
  }

  String _taskEmoji(TaskType type) {
    switch (type) {
      case TaskType.weeding:
        return '🌿';
      case TaskType.pestControl:
        return '🐛';
      case TaskType.fertilization:
        return '🧪';
      case TaskType.irrigation:
        return '💧';
      case TaskType.harvest:
        return '🧺';
      case TaskType.other:
        return '📌';
    }
  }
}

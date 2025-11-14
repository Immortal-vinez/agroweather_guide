import '../widgets/gradient_app_bar.dart';
// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/crop.dart';
import '../models/weather.dart';
import '../widgets/crop_recommendation_card.dart';
import '../models/planned_crop.dart';
import '../models/plan_task.dart';
import '../services/plan_repository.dart';
import 'add_crop_plan_screen.dart';
import '../services/season_service.dart';

enum _CropViewMode { recommendations, calendar }

class CropRecommendationScreen extends StatefulWidget {
  final Weather? currentWeather;
  final bool startInPlan;
  const CropRecommendationScreen({
    super.key,
    this.currentWeather,
    this.startInPlan = false,
  });

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  _CropViewMode _mode = _CropViewMode.recommendations;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Crop> _allCrops = [];
  bool _isLoading = true;
  List<PlannedCrop> _planned = [];
  bool _rainyOnly = false;

  // Calendar state
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    // Initialize starting mode based on flag
    if (widget.startInPlan) {
      _mode = _CropViewMode.calendar;
    }
    _loadCrops();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final items = await PlanRepository().load();
    setState(() {
      _planned = items;
    });
  }

  Future<void> _loadCrops() async {
    try {
      final data = await rootBundle.loadString('lib/data/crops.json');
      final List<dynamic> jsonResult = json.decode(data);
      final crops = jsonResult
          .map(
            (e) => Crop(
              name: e['name'],
              season: e['season'],
              careTip: e['careTip'],
              minTemp: (e['minTemp'] as num).toDouble(),
              maxTemp: (e['maxTemp'] as num).toDouble(),
              icon: e['icon'],
            ),
          )
          .toList();
      setState(() {
        _allCrops = crops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allCrops = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: GradientAppBar(
        title: Row(
          children: [
            Icon(LucideIcons.sprout, size: 22),
            const SizedBox(width: 8),
            const Text('Crops'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Recommendations',
                    icon: LucideIcons.listChecks,
                    selected: _mode == _CropViewMode.recommendations,
                    onTap: () => setState(
                      () => _mode = _CropViewMode.recommendations,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    label: 'Plan',
                    icon: LucideIcons.calendarDays,
                    selected: _mode == _CropViewMode.calendar,
                    onTap: () => setState(() => _mode = _CropViewMode.calendar),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => _searchFocus.unfocus(),
              child: _mode == _CropViewMode.recommendations
                  ? _buildRecommendations(theme)
                  : _buildCalendar(theme),
            ),
      floatingActionButton: _mode == _CropViewMode.calendar
          ? FloatingActionButton.extended(
              onPressed: () async {
                final crop = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddCropPlanScreen(
                      knownCrops: _allCrops,
                      currentWeather: widget.currentWeather,
                    ),
                  ),
                );
                if (crop != null) {
                  await _loadPlans();
                }
              },
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Plan'),
            )
          : null,
    );
  }

  Widget _buildRecommendations(ThemeData theme) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _allCrops.where((c) {
      final q = c.name.toLowerCase();
      return query.isEmpty || q.contains(query);
    }).toList();

    final seasonInfo = SeasonService().getSeasonInfo(DateTime.now());
    final isRainyNow = seasonInfo.name == 'Rainy';

    // Compute suitability if we have current weather
    final weather = widget.currentWeather;
    List<Crop> display = List.from(filtered);
    if (weather != null) {
      display.sort((a, b) {
        double score(Crop crop) {
          final mid = (crop.minTemp + crop.maxTemp) / 2.0;
          final diff = (weather.temperature - mid).abs();
          final range = (crop.maxTemp - crop.minTemp) / 2.0;
          final s = 1.0 - (diff / (range + 0.1));
          return s.clamp(0.0, 1.0);
        }

        return score(b).compareTo(score(a));
      });
    }

    // Apply rainy season filtering BEFORE building list to avoid mutating during itemBuilder
    if (isRainyNow && _rainyOnly) {
      display = display
          .where((c) => c.season == 'Rainy' || c.season == 'Any')
          .toList();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search crops...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (isRainyNow)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _rainyOnly = !_rainyOnly),
                  icon: const Icon(LucideIcons.cloudRain),
                  label: Text(
                    _rainyOnly ? 'Show All Crops' : 'Show Rainy Season Crops',
                  ),
                ),
              ),
            ),
          ),
        if (weather != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.thermometer,
                    size: 18,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Using current weather: ${weather.temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        if (display.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No crops match your search',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: display.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final crop = display[i];

              // Calculate suitability and waterSaving similar to dashboard
              double suitability = 0.5;
              double waterSaving = 0.0;
              String reason = 'Season: ${crop.season}';
              if (weather != null) {
                final tempMid = (crop.minTemp + crop.maxTemp) / 2.0;
                final tempDiff = (weather.temperature - tempMid).abs();
                final tempRange = (crop.maxTemp - crop.minTemp) / 2.0;
                suitability = (1.0 - (tempDiff / (tempRange + 0.1))).clamp(
                  0.0,
                  1.0,
                );

                final cropWaterNeed = crop.minTemp * 1.5; // proxy
                waterSaving = (weather.rainfall /
                        (cropWaterNeed == 0 ? 1 : cropWaterNeed)) *
                    100.0;
                waterSaving = waterSaving.clamp(0.0, 100.0);

                if (suitability > 0.85) {
                  reason = 'Ideal temperature and season for this crop.';
                } else if (suitability > 0.6) {
                  reason = 'Good match, monitor temperature.';
                } else {
                  reason = 'Suboptimal temperature, consider alternatives.';
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CropRecommendationCard(
                  crop: crop,
                  suitability: suitability,
                  waterSaving: waterSaving,
                  reason: reason,
                ),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun, 6=Sat
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7.0).ceil();
    final today = DateTime.now();
    final tasksByDate = <int, List<_DayTask>>{}; // key = day
    for (final crop in _planned) {
      for (final t in crop.tasks) {
        if (t.due.year == _visibleMonth.year &&
            t.due.month == _visibleMonth.month) {
          tasksByDate.putIfAbsent(t.due.day, () => []).add(_DayTask(crop, t));
        }
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    );
                  }),
                  icon: const Icon(LucideIcons.chevronLeft),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    );
                  }),
                  icon: const Icon(LucideIcons.chevronRight),
                ),
              ],
            ),
          ),
        ),
        // Weekday header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                _WeekdayCell('Sun'),
                _WeekdayCell('Mon'),
                _WeekdayCell('Tue'),
                _WeekdayCell('Wed'),
                _WeekdayCell('Thu'),
                _WeekdayCell('Fri'),
                _WeekdayCell('Sat'),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // Slightly taller cells to prevent tiny overflows on some devices
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < startWeekday || index >= startWeekday + daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = index - startWeekday + 1;
              final date = DateTime(
                _visibleMonth.year,
                _visibleMonth.month,
                day,
              );
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final tasks = tasksByDate[day] ?? const [];

              return InkWell(
                onTap:
                    tasks.isNotEmpty ? () => _showDayTasks(date, tasks) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade300,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF212121),
                        ),
                      ),
                      // Use Expanded+Align to avoid minute overflow due to pixel rounding
                      const SizedBox(height: 2),
                      if (tasks.isNotEmpty)
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Wrap(
                              spacing: 3,
                              runSpacing: 1,
                              children: tasks
                                  .take(3)
                                  .map(
                                    (pair) => _Dot(
                                      color: _taskColor(pair.task.type),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }, childCount: rows * 7),
          ),
        ),
      ],
    );
  }

  void _showDayTasks(DateTime date, List<_DayTask> tasks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks on ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, index) {
                      final pair = tasks[index];
                      final crop = pair.crop;
                      final t = pair.task;
                      final textStyle = t.completed
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            )
                          : null;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _taskColor(t.type).withOpacity(0.15),
                          child: Text(_taskEmoji(t.type)),
                        ),
                        title: Text(t.title, style: textStyle),
                        subtitle: Text(
                          '${crop.icon} ${crop.name} — ${t.description}',
                          style: textStyle,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'toggle') {
                              await PlanRepository().updateTaskCompleted(
                                crop.id,
                                t.id,
                                !t.completed,
                              );
                              if (!mounted) return;
                              await _loadPlans();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t.completed
                                        ? 'Marked as undone'
                                        : 'Marked as done',
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              Navigator.pop(context);
                            } else if (value == 'reschedule') {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: t.due,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 2),
                                ),
                              );
                              if (picked != null) {
                                await PlanRepository().rescheduleTask(
                                  crop.id,
                                  t.id,
                                  DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    t.due.hour,
                                    t.due.minute,
                                  ),
                                );
                                if (!mounted) return;
                                await _loadPlans();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Task rescheduled to ${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                              }
                            } else if (value == 'delete') {
                              await PlanRepository().deleteTask(crop.id, t.id);
                              if (!mounted) return;
                              await _loadPlans();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task deleted')),
                              );
                              if (!mounted) return;
                              Navigator.pop(context);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                t.completed ? 'Mark as Undone' : 'Mark as Done',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reschedule',
                              child: Text('Reschedule'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final added = await _addTaskForDate(date);
                      if (!mounted) return;
                      if (added) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task added')),
                        );
                      }
                      Navigator.pop(context);
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Add task for this day'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _addTaskForDate(DateTime date) async {
    final crop = await _pickCropForTask();
    if (crop == null) return false;
    final task = await _promptTaskDetails(date);
    if (task == null) return false;
    await PlanRepository().addTask(crop.id, task);
    await _loadPlans();
    return true;
  }

  Future<PlannedCrop?> _pickCropForTask() async {
    return showDialog<PlannedCrop>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Select crop'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _planned
                  .map(
                    (c) => ListTile(
                      leading: Text(
                        c.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(c.name),
                      onTap: () => Navigator.pop(context, c),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Future<PlanTask?> _promptTaskDetails(DateTime date) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TaskType selected = TaskType.other;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TaskType>(
              value: selected,
              items: TaskType.values
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.name)),
                  )
                  .toList(),
              onChanged: (v) {
                selected = v ?? TaskType.other;
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return null;
    return PlanTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      due: DateTime(date.year, date.month, date.day, 8, 0),
      type: selected,
      title: titleCtrl.text.trim().isEmpty ? 'Task' : titleCtrl.text.trim(),
      description: descCtrl.text.trim().isEmpty ? '—' : descCtrl.text.trim(),
    );
  }

  Color _taskColor(TaskType type) {
    switch (type) {
      case TaskType.weeding:
        return const Color(0xFF4CAF50);
      case TaskType.pestControl:
        return Colors.orange;
      case TaskType.fertilization:
        return Colors.blue;
      case TaskType.irrigation:
        return Colors.teal;
      case TaskType.harvest:
        return Colors.purple;
      case TaskType.other:
        return Colors.grey;
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

  String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[(m - 1).clamp(0, 11)];
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final bg = selected ? Colors.white : Colors.white.withOpacity(0.2);
    final fg = selected ? const Color(0xFF4CAF50) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayCell extends StatelessWidget {
  final String day;
  const _WeekdayCell(this.day);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DayTask {
  final PlannedCrop crop;
  final PlanTask task;
  _DayTask(this.crop, this.task);
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/crop.dart';
import '../models/planned_crop.dart';
import '../models/plan_task.dart';
import '../models/weather.dart';
import '../services/plan_repository.dart';

class AddCropPlanScreen extends StatefulWidget {
  final List<Crop> knownCrops;
  final Weather? currentWeather;
  final String? initialCropName;
  const AddCropPlanScreen({
    super.key,
    required this.knownCrops,
    this.currentWeather,
    this.initialCropName,
  });

  @override
  State<AddCropPlanScreen> createState() => _AddCropPlanScreenState();
}

class _AddCropPlanScreenState extends State<AddCropPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _varietyCtrl = TextEditingController();
  DateTime _plantingDate = DateTime.now();
  String _icon = '🌱';
  bool _useTemplate = true;

  Crop? _matchedCrop;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_matchCrop);
    // Prefill if an initial crop name is provided
    if (widget.initialCropName != null && widget.initialCropName!.isNotEmpty) {
      _nameCtrl.text = widget.initialCropName!;
      // Run matching to pick up icon and recommendations
      _matchCrop();
    }
  }

  void _matchCrop() {
    final text = _nameCtrl.text.trim().toLowerCase();
    final match = widget.knownCrops.firstWhere(
      (c) => c.name.toLowerCase() == text,
      orElse:
          () => widget.knownCrops.firstWhere(
            (c) => c.name.toLowerCase().contains(text),
            orElse:
                () => Crop(
                  name: '',
                  season: '',
                  careTip: '',
                  minTemp: 0,
                  maxTemp: 0,
                  icon: '🌱',
                ),
          ),
    );
    setState(() {
      _matchedCrop = match.name.isEmpty ? null : match;
      if (_matchedCrop != null) _icon = _matchedCrop!.icon;
    });
  }

  List<PlanTask> _buildTemplateTasks(DateTime start) {
    final List<PlanTask> tasks = [];
    String id() =>
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

    // Base templates: weeding at 14 and 28 days, pest check weekly x4, fertilizer at 21 and 45 days, irrigation weekly x8
    tasks.addAll([
      PlanTask(
        id: id(),
        due: start.add(const Duration(days: 14)),
        type: TaskType.weeding,
        title: 'Weeding Round 1',
        description: 'Remove weeds to reduce competition for nutrients.',
      ),
      PlanTask(
        id: id(),
        due: start.add(const Duration(days: 28)),
        type: TaskType.weeding,
        title: 'Weeding Round 2',
        description: 'Second weeding to keep field clean.',
      ),
      PlanTask(
        id: id(),
        due: start.add(const Duration(days: 21)),
        type: TaskType.fertilization,
        title: 'Fertilizer Application 1',
        description: 'Apply NPK based on soil test or recommendation.',
      ),
      PlanTask(
        id: id(),
        due: start.add(const Duration(days: 45)),
        type: TaskType.fertilization,
        title: 'Fertilizer Application 2',
        description: 'Top dress as required for the crop.',
      ),
      PlanTask(
        id: id(),
        due: start.add(const Duration(days: 90)),
        type: TaskType.harvest,
        title: 'Harvest Window',
        description: 'Inspect readiness and plan harvest.',
      ),
    ]);

    // Pest monitoring weekly for first 8 weeks
    for (int i = 7; i <= 56; i += 7) {
      tasks.add(
        PlanTask(
          id: id(),
          due: start.add(Duration(days: i)),
          type: TaskType.pestControl,
          title: 'Pest & Disease Check',
          description: 'Scout field and treat if necessary.',
        ),
      );
    }
    // Irrigation based on current rainfall proxy
    final rainfall = widget.currentWeather?.rainfall ?? 0.0;
    final irrigationIntervalDays =
        rainfall < 2
            ? 3
            : rainfall < 5
            ? 5
            : 7;
    for (int i = irrigationIntervalDays; i <= 56; i += irrigationIntervalDays) {
      tasks.add(
        PlanTask(
          id: id(),
          due: start.add(Duration(days: i)),
          type: TaskType.irrigation,
          title: 'Irrigation',
          description: 'Irrigate as per soil moisture needs.',
        ),
      );
    }

    return tasks..sort((a, b) => a.due.compareTo(b.due));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    final tasks =
        _useTemplate ? _buildTemplateTasks(_plantingDate) : <PlanTask>[];
    final crop = PlannedCrop(
      id: id,
      name: _nameCtrl.text.trim(),
      icon: _icon,
      plantingDate: _plantingDate,
      variety:
          _varietyCtrl.text.trim().isEmpty ? null : _varietyCtrl.text.trim(),
      tasks: tasks,
    );
    await PlanRepository().upsert(crop);
    if (mounted) Navigator.pop(context, crop);
  }

  @override
  void dispose() {
    // Remove listeners and dispose controllers to avoid memory leaks
    _nameCtrl.removeListener(_matchCrop);
    _nameCtrl.dispose();
    _varietyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.knownCrops.map((c) => c.name).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Crop Plan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Crop name',
                prefixIcon: const Icon(LucideIcons.sprout),
                hintText: 'e.g., Maize',
                suffixIcon:
                    _matchedCrop != null
                        ? Text(
                          _matchedCrop!.icon,
                          style: const TextStyle(fontSize: 18),
                        )
                        : null,
              ),
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Enter crop name'
                          : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  suggestions
                      .take(8)
                      .map(
                        (s) => ActionChip(
                          label: Text(s),
                          onPressed: () {
                            _nameCtrl.text = s;
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _varietyCtrl,
              decoration: const InputDecoration(
                labelText: 'Variety (optional)',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.calendarDays),
              title: const Text('Planting date'),
              subtitle: Text(
                '${_plantingDate.year}-${_plantingDate.month.toString().padLeft(2, '0')}-${_plantingDate.day.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _plantingDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _plantingDate = picked);
              },
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              value: _useTemplate,
              onChanged: (v) => setState(() => _useTemplate = v),
              title: const Text('Use recommended schedule'),
              subtitle: Text(
                _matchedCrop != null
                    ? 'Based on ${_matchedCrop!.name} (${_matchedCrop!.season})'
                    : 'Generic template with weeding, fertilizer, pest checks, irrigation',
              ),
            ),
            if (_matchedCrop != null)
              _RecommendationsBox(
                crop: _matchedCrop!,
                currentRainfall: widget.currentWeather?.rainfall ?? 0,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(LucideIcons.save),
              label: const Text('Save Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsBox extends StatelessWidget {
  final Crop crop;
  final double currentRainfall;
  const _RecommendationsBox({
    required this.crop,
    required this.currentRainfall,
  });

  @override
  Widget build(BuildContext context) {
    final seasonNote = _seasonalNote(DateTime.now().month);
    final waterNote =
        currentRainfall < 2
            ? 'Low rainfall expected, plan regular irrigation.'
            : currentRainfall < 5
            ? 'Moderate rainfall, monitor soil moisture.'
            : 'Good rainfall, reduce irrigation where possible.';

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(crop.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Recommendations for ${crop.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _bullet(
              'Pest control: scout weekly; treat aphids/borers early where present.',
            ),
            _bullet('Weeding: at 2 and 4 weeks after planting.'),
            _bullet('Fertilizer: NPK at 3 and 6 weeks (adjust by soil test).'),
            _bullet(
              'Irrigation: drip or furrow based on soil; avoid waterlogging.',
            ),
            _bullet('Crop specifics: ${crop.careTip}'),
            _bullet('Seasonal weather: $seasonNote $waterNote'),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Text('• '), Expanded(child: Text(text))],
    ),
  );

  String _seasonalNote(int month) {
    // Very simple placeholder mapping
    if ([12, 1, 2].contains(month)) return 'Cool season conditions likely.';
    if ([3, 4, 5].contains(month)) return 'Warming up; intermittent rains.';
    if ([6, 7, 8].contains(month)) return 'Peak rains expected.';
    return 'Late rains/transition to dry season.';
  }
}

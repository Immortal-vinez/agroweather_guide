import 'package:intl/intl.dart';

class SeasonInfo {
  final String name; // 'Rainy', 'Cool Dry', 'Hot Dry'
  final DateTime start;
  final DateTime end;
  final String nextName;
  final DateTime nextStart;
  final double progress; // 0.0..1.0 of current season elapsed
  final List<String> datasetTags; // Compatible dataset season tags

  SeasonInfo({
    required this.name,
    required this.start,
    required this.end,
    required this.nextName,
    required this.nextStart,
    required this.progress,
    required this.datasetTags,
  });

  String get dateRange =>
      '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
}

/// Zambia has three main seasons:
/// - Rainy/Wet: Nov 1 – Apr 30
/// - Cool Dry: May 1 – Aug 31
/// - Hot Dry: Sep 1 – Oct 31
class SeasonService {
  SeasonInfo getSeasonInfo(DateTime now) {
    // Build season windows relative to this year
    final y = now.year;
    final rainyStart = DateTime(y, 11, 1);
    final rainyEnd = DateTime(y + 1, 4, 30);
    final coolStart = DateTime(y, 5, 1);
    final coolEnd = DateTime(y, 8, 31);
    final hotStart = DateTime(y, 9, 1);
    final hotEnd = DateTime(y, 10, 31);

    // Determine which window contains 'now'; rainy crosses year boundary
    if (_inRangeCrossYear(now, rainyStart, rainyEnd)) {
      final total = rainyEnd.difference(rainyStart).inDays + 1;
      final elapsed =
          now.isBefore(rainyStart)
              ? 0
              : now.difference(rainyStart).inDays.clamp(0, total);
      return SeasonInfo(
        name: 'Rainy',
        start: rainyStart,
        end: rainyEnd,
        nextName: 'Cool Dry',
        nextStart: coolStart.isAfter(now) ? coolStart : DateTime(y + 1, 5, 1),
        progress: total > 0 ? elapsed / total : 0,
        datasetTags: const ['Rainy', 'Wet', 'Any'],
      );
    }
    if (_inRangeSameYear(now, coolStart, coolEnd)) {
      final total = coolEnd.difference(coolStart).inDays + 1;
      final elapsed = now.difference(coolStart).inDays.clamp(0, total);
      return SeasonInfo(
        name: 'Cool Dry',
        start: coolStart,
        end: coolEnd,
        nextName: 'Hot Dry',
        nextStart: hotStart,
        progress: total > 0 ? elapsed / total : 0,
        datasetTags: const ['Cool', 'Dry', 'Any'],
      );
    }
    // Else hot dry
    final total = hotEnd.difference(hotStart).inDays + 1;
    final elapsed = now.difference(hotStart).inDays.clamp(0, total);
    return SeasonInfo(
      name: 'Hot Dry',
      start: hotStart,
      end: hotEnd,
      nextName: 'Rainy',
      nextStart: rainyStart.isAfter(now) ? rainyStart : DateTime(y + 1, 11, 1),
      progress: total > 0 ? elapsed / total : 0,
      datasetTags: const ['Warm', 'Dry', 'Any'],
    );
  }

  bool _inRangeSameYear(DateTime d, DateTime start, DateTime end) {
    return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
        d.isBefore(end.add(const Duration(days: 1)));
  }

  bool _inRangeCrossYear(DateTime d, DateTime start, DateTime end) {
    // where end is in next year
    if (end.year == start.year) return _inRangeSameYear(d, start, end);
    // Consider the window from start..Dec 31 of start.year, and Jan 1..end
    final endOfYear = DateTime(start.year, 12, 31);
    final startOfNext = DateTime(end.year, 1, 1);
    return _inRangeSameYear(d, start, endOfYear) ||
        _inRangeSameYear(d, startOfNext, end);
  }
}

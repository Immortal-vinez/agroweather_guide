import '../widgets/gradient_app_bar.dart';
import '../services/season_service.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/crop.dart';
import '../models/weather.dart';
import 'crop_details_screen.dart';
import '../services/crops_service.dart';
import 'add_crop_plan_screen.dart';

class CropsListScreen extends StatefulWidget {
  final Weather? currentWeather;
  final String? initialSeasonFilter; // e.g., 'Rainy'

  const CropsListScreen(
      {super.key, this.currentWeather, this.initialSeasonFilter});

  @override
  State<CropsListScreen> createState() => _CropsListScreenState();
}

class _CropsListScreenState extends State<CropsListScreen> {
  List<Crop> _allCrops = [];
  List<Crop> _filteredCrops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSeason = 'All';

  final List<String> _seasons = ['All', 'Rainy', 'Cool', 'Warm', 'Dry', 'Any'];

  @override
  void initState() {
    super.initState();
    if (widget.initialSeasonFilter != null) {
      _selectedSeason = widget.initialSeasonFilter!;
    }
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    try {
      final crops = await CropsService().loadCrops();
      setState(() {
        _allCrops = crops;
        _filteredCrops = crops;
        _isLoading = false;
      });
      _filterCrops();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCrops() {
    setState(() {
      _filteredCrops = _allCrops.where((crop) {
        final matchesSearch = crop.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        final matchesSeason = _selectedSeason == 'All'
            ? true
            : (crop.season == _selectedSeason || crop.season == 'Any');
        return matchesSearch && matchesSeason;
      }).toList();

      // Weather-aware sorting if weather data is available
      if (widget.currentWeather != null) {
        final temp = widget.currentWeather!.temperature;
        final currentSeason = _getCurrentSeason();
        double score(Crop c) {
          final ideal = (c.minTemp + c.maxTemp) / 2.0;
          final diff = (temp - ideal).abs(); // lower is better
          final seasonBonus = (c.season == currentSeason || c.season == 'Any')
              ? -0.25 // nudge matching seasons up
              : 0.0;
          final inRangePenalty = (temp < c.minTemp || temp > c.maxTemp)
              ? 1.0
              : 0.0; // out of range, push down
          return diff + inRangePenalty + seasonBonus;
        }

        _filteredCrops.sort((a, b) => score(a).compareTo(score(b)));
      }
    });
  }

  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if ([6, 7, 8, 9].contains(month)) return 'Rainy';
    if ([10, 11, 12, 1].contains(month)) return 'Cool';
    if ([2, 3, 4, 5].contains(month)) return 'Warm';
    return 'Dry';
  }

  Color _getSeasonColor(String season) {
    switch (season) {
      case 'Rainy':
        return Colors.blue;
      case 'Cool':
        return Colors.cyan;
      case 'Warm':
        return Colors.orange;
      case 'Dry':
        return Colors.amber;
      case 'Any':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeasonIcon(String season) {
    switch (season) {
      case 'Rainy':
        return LucideIcons.cloudRain;
      case 'Cool':
        return LucideIcons.snowflake;
      case 'Warm':
        return LucideIcons.sun;
      case 'Dry':
        return LucideIcons.wind;
      case 'Any':
        return LucideIcons.calendar;
      default:
        return LucideIcons.leaf;
    }
  }

  bool _isSuitableForCurrentWeather(Crop crop) {
    if (widget.currentWeather == null) return false;
    final temp = widget.currentWeather!.temperature;
    final currentSeason = _getCurrentSeason();
    return temp >= crop.minTemp &&
        temp <= crop.maxTemp &&
        (crop.season == currentSeason || crop.season == 'Any');
  }

  @override
  Widget build(BuildContext context) {
    final currentSeason = _getCurrentSeason();
    final seasonInfo = SeasonService().getSeasonInfo(DateTime.now());
    final isRainyNow = seasonInfo.name == 'Rainy';
    final rainyActive = _selectedSeason == 'Rainy';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: GradientAppBar(
        title: Row(
          children: [
            Icon(LucideIcons.sprout, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Crops Database',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                // Search and Filter Section
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterCrops();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search crops...',
                            prefixIcon: Icon(
                              LucideIcons.search,
                              color: Colors.grey.shade600,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(LucideIcons.x, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      _filterCrops();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Season Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _seasons.map((season) {
                              final isSelected = _selectedSeason == season;
                              final isCurrent = season == currentSeason;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (season != 'All')
                                        Icon(
                                          _getSeasonIcon(season),
                                          size: 16,
                                          color: isSelected
                                              ? Colors.white
                                              : _getSeasonColor(
                                                  season,
                                                ),
                                        ),
                                      if (season != 'All')
                                        const SizedBox(width: 4),
                                      Text(season),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.star,
                                          size: 12,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.amber,
                                        ),
                                      ],
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSeason = season;
                                    });
                                    _filterCrops();
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: _getSeasonColor(season),
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? _getSeasonColor(season)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (isRainyNow) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedSeason =
                                      rainyActive ? 'All' : 'Rainy';
                                });
                                _filterCrops();
                              },
                              icon: const Icon(LucideIcons.cloudRain),
                              label: Text(rainyActive
                                  ? 'Show All Crops'
                                  : 'Show Rainy Season Crops'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Results Count
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filteredCrops.length} crop${_filteredCrops.length != 1 ? 's' : ''} found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.currentWeather != null)
                          Row(
                            children: [
                              Icon(
                                Icons.thermostat,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.currentWeather!.temperature.toStringAsFixed(0)}°C',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // Crops List / Empty state
                if (_filteredCrops.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyStateContent(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final crop = _filteredCrops[index];
                        final isSuitable = _isSuitableForCurrentWeather(crop);
                        return _buildCropCard(crop, isSuitable);
                      }, childCount: _filteredCrops.length),
                    ),
                  ),
              ],
            ),
    );
  }

  // Simplified empty-state content for use inside SliverFillRemaining
  Widget _buildEmptyStateContent() {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No crops found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedSeason = 'All';
                });
                _filterCrops();
              },
              icon: Icon(LucideIcons.refreshCw),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(Crop crop, bool isSuitable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSuitable
            ? BorderSide(color: const Color(0xFF4CAF50), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropDetailsScreen(crop: crop),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Crop Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: _getSeasonColor(crop.season).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(crop.icon, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),

              // Crop Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            crop.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                        if (isSuitable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Suitable Now',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          _getSeasonIcon(crop.season),
                          size: 14,
                          color: _getSeasonColor(crop.season),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          crop.season,
                          style: TextStyle(
                            fontSize: 13,
                            color: _getSeasonColor(crop.season),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.thermostat,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${crop.minTemp.toStringAsFixed(0)}°C - ${crop.maxTemp.toStringAsFixed(0)}°C',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      crop.careTip,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final planned = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddCropPlanScreen(
                                knownCrops: _allCrops,
                                currentWeather: widget.currentWeather,
                                initialCropName: crop.name,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          if (planned != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Plan saved for ${crop.name}'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.calendarPlus),
                        label: const Text('Plan'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                LucideIcons.chevronRight,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

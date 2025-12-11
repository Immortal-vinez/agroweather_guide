// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/field_polygon.dart';
import '../models/agro_weather_data.dart';
import '../services/field_repository.dart';
import '../services/agro_monitoring_service.dart';
import '../widgets/field_map_widget.dart';
import '../widgets/gradient_app_bar.dart';
import '../config/env.dart';

/// Screen for managing fields and viewing field-specific data
class FieldManagementScreen extends StatefulWidget {
  const FieldManagementScreen({super.key});

  @override
  State<FieldManagementScreen> createState() => _FieldManagementScreenState();
}

class _FieldManagementScreenState extends State<FieldManagementScreen> {
  final FieldRepository _fieldRepo = FieldRepository();
  late final AgroMonitoringService? _agroService;

  List<FieldPolygon> _savedFields = [];
  FieldPolygon? _selectedField;
  FieldData? _fieldData;
  bool _isLoading = true;
  bool _isLoadingFieldData = false;
  String? _activeFieldId;

  bool get _hasAgroApi => Env.agroMonitoringApiKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _agroService =
        _hasAgroApi ? AgroMonitoringService(Env.agroMonitoringApiKey) : null;
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() => _isLoading = true);

    final fields = await _fieldRepo.getAllFields();
    final activeId = await _fieldRepo.getActiveFieldId();

    setState(() {
      _savedFields = fields;
      _activeFieldId = activeId;
      _isLoading = false;
    });

    // If there's an active field, load it
    if (activeId != null) {
      final activeField = fields.firstWhere(
        (f) => f.id == activeId,
        orElse: () => fields.first,
      );
      _selectField(activeField);
    }
  }

  Future<void> _onPolygonCreated(FieldPolygon polygon) async {
    // Save locally first
    await _fieldRepo.saveField(polygon);

    // Try to sync with Agro API if available
    if (_agroService != null) {
      final apiPolygon = await _agroService.createPolygon(polygon);
      if (apiPolygon != null) {
        // Update with API ID
        await _fieldRepo.saveField(apiPolygon);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Field synced with Agro Monitoring API'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    _loadFields();
  }

  Future<void> _selectField(FieldPolygon field) async {
    setState(() {
      _selectedField = field;
      _isLoadingFieldData = true;
    });

    // Load field data if we have Agro API
    if (_agroService != null && field.id != null) {
      final data = await _agroService.getCompleteFieldData(field);
      setState(() {
        _fieldData = data;
        _isLoadingFieldData = false;
      });
    } else {
      setState(() {
        _isLoadingFieldData = false;
      });
    }
  }

  Future<void> _setActiveField(FieldPolygon field) async {
    await _fieldRepo.setActiveField(field.id);
    setState(() {
      _activeFieldId = field.id;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${field.name} set as active field')),
    );
  }

  Future<void> _deleteField(FieldPolygon field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Are you sure you want to delete "${field.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Delete from API if synced
    if (_agroService != null && field.id != null) {
      await _agroService.deletePolygon(field.id!);
    }

    // Delete locally
    await _fieldRepo.deleteFieldByName(field.name);

    setState(() {
      _selectedField = null;
      _fieldData = null;
    });

    _loadFields();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${field.name} deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: GradientAppBar(
        title: Row(
          children: [
            Icon(LucideIcons.map, size: 24),
            const SizedBox(width: 8),
            const Text(
              'My Fields',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw),
            onPressed: _loadFields,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map section
                Expanded(
                  flex: 2,
                  child: FieldMapWidget(
                    existingFields: _savedFields,
                    selectedField: _selectedField,
                    onPolygonCreated: _onPolygonCreated,
                    onFieldSelected: _selectField,
                    enableDrawing: true,
                  ),
                ),

                // Field list and details section
                Expanded(
                  flex: 1,
                  child: _savedFields.isEmpty
                      ? _buildEmptyState()
                      : _selectedField == null
                          ? _buildFieldsList()
                          : _buildFieldDetails(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.mapPin, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No fields yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button on the map to create your first field',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _savedFields.length,
      itemBuilder: (context, index) {
        final field = _savedFields[index];
        final isActive = field.id == _activeFieldId;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.green : Colors.blue,
              child: Icon(
                isActive ? LucideIcons.check : LucideIcons.map,
                color: Colors.white,
              ),
            ),
            title: Text(
              field.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${field.coordinates.length} points • '
              '${field.calculateArea().toStringAsFixed(2)} hectares',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(LucideIcons.eye),
                      const SizedBox(width: 8),
                      const Text('View Details'),
                    ],
                  ),
                  onTap: () => _selectField(field),
                ),
                if (!isActive)
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(LucideIcons.check),
                        const SizedBox(width: 8),
                        const Text('Set as Active'),
                      ],
                    ),
                    onTap: () => _setActiveField(field),
                  ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => _deleteField(field),
                ),
              ],
            ),
            onTap: () => _selectField(field),
          ),
        );
      },
    );
  }

  Widget _buildFieldDetails() {
    if (_selectedField == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedField!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x),
                onPressed: () => setState(() => _selectedField = null),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Basic info
          _buildInfoCard(
            'Field Information',
            [
              _buildInfoRow('Area',
                  '${_selectedField!.calculateArea().toStringAsFixed(2)} hectares'),
              _buildInfoRow('Points', '${_selectedField!.coordinates.length}'),
              _buildInfoRow('Created', _formatDate(_selectedField!.createdAt)),
              if (_selectedField!.id != null)
                _buildInfoRow('API ID', _selectedField!.id!),
            ],
          ),

          const SizedBox(height: 12),

          // Weather data
          if (_isLoadingFieldData)
            const Center(child: CircularProgressIndicator())
          else if (_fieldData?.currentWeather != null)
            _buildWeatherCard(_fieldData!.currentWeather!)
          else if (!_hasAgroApi)
            _buildApiKeyWarning()
          else
            _buildNoDataCard(),

          const SizedBox(height: 12),

          // NDVI data
          if (_fieldData?.latestNdvi != null)
            _buildNdviCard(_fieldData!.latestNdvi!),

          const SizedBox(height: 12),

          // Soil data
          if (_fieldData?.currentSoil != null)
            _buildSoilCard(_fieldData!.currentSoil!),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(AgroWeatherData weather) {
    return _buildInfoCard(
      'Current Weather',
      [
        _buildInfoRow(
            'Temperature', '${weather.tempCelsius?.toStringAsFixed(1)}°C'),
        if (weather.humidity != null)
          _buildInfoRow('Humidity', '${weather.humidity!.toStringAsFixed(0)}%'),
        if (weather.windSpeed != null)
          _buildInfoRow(
              'Wind Speed', '${weather.windSpeed!.toStringAsFixed(1)} m/s'),
        if (weather.precipitation != null)
          _buildInfoRow('Precipitation',
              '${weather.precipitation!.toStringAsFixed(1)} mm'),
        if (weather.weatherDescription != null)
          _buildInfoRow('Conditions', weather.weatherDescription!),
      ],
    );
  }

  Widget _buildNdviCard(NdviData ndvi) {
    return _buildInfoCard(
      'Vegetation Health (NDVI)',
      [
        _buildInfoRow('Health Rating', '${ndvi.healthRating}/100'),
        _buildInfoRow('Status', ndvi.healthDescription),
        _buildInfoRow('NDVI Mean', ndvi.mean?.toStringAsFixed(3) ?? 'N/A'),
        _buildInfoRow('Last Updated', _formatDate(ndvi.dateTime)),
      ],
    );
  }

  Widget _buildSoilCard(SoilData soil) {
    return _buildInfoCard(
      'Soil Conditions',
      [
        if (soil.surfaceTempCelsius != null)
          _buildInfoRow('Surface Temperature',
              '${soil.surfaceTempCelsius!.toStringAsFixed(1)}°C'),
        if (soil.temp10cmCelsius != null)
          _buildInfoRow('Temperature at 10cm',
              '${soil.temp10cmCelsius!.toStringAsFixed(1)}°C'),
        if (soil.moisturePercent != null) ...[
          _buildInfoRow(
              'Soil Moisture', '${soil.moisturePercent!.toStringAsFixed(0)}%'),
          _buildMoistureStatus(soil.moisturePercent!),
        ],
        _buildInfoRow('Last Updated', _formatDate(soil.dateTime)),
      ],
    );
  }

  Widget _buildMoistureStatus(double moisture) {
    String status;
    Color statusColor;
    IconData icon;

    if (moisture < 10) {
      status = 'Critical - Immediate irrigation needed';
      statusColor = Colors.red;
      icon = Icons.water_drop_outlined;
    } else if (moisture < 20) {
      status = 'Dry - Irrigation recommended';
      statusColor = Colors.orange;
      icon = Icons.water_drop;
    } else if (moisture < 40) {
      status = 'Optimal - Good moisture level';
      statusColor = Colors.green;
      icon = Icons.check_circle;
    } else if (moisture < 60) {
      status = 'Moist - Monitor drainage';
      statusColor = Colors.blue;
      icon = Icons.water;
    } else {
      status = 'Saturated - Risk of waterlogging';
      statusColor = Colors.purple;
      icon = Icons.warning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Visual moisture bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.grey[200],
            ),
            child: FractionallySizedBox(
              widthFactor: (moisture / 100).clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyWarning() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(LucideIcons.info, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add OPENWEATHER_API_KEY to get field-specific weather data',
                style: TextStyle(color: Colors.orange[900]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            'No field data available yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

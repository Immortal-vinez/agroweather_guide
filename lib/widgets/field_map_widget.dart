// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/field_polygon.dart';

/// Interactive map widget for drawing field polygons
/// Centered on Zambia with polygon drawing capabilities
class FieldMapWidget extends StatefulWidget {
  final List<FieldPolygon> existingFields;
  final FieldPolygon? selectedField;
  final Function(FieldPolygon)? onPolygonCreated;
  final Function(FieldPolygon)? onFieldSelected;
  final bool enableDrawing;
  final LatLng? initialCenter;

  const FieldMapWidget({
    super.key,
    this.existingFields = const [],
    this.selectedField,
    this.onPolygonCreated,
    this.onFieldSelected,
    this.enableDrawing = true,
    this.initialCenter,
  });

  @override
  State<FieldMapWidget> createState() => _FieldMapWidgetState();
}

class _FieldMapWidgetState extends State<FieldMapWidget> {
  final MapController _mapController = MapController();
  List<LatLng> _currentPolygonPoints = [];
  bool _isDrawing = false;
  String? _selectedFieldId;
  String _mapType = 'street'; // Default to street view

  // Zambia's approximate center coordinates
  static const LatLng _zambiaCenter = LatLng(-13.1339, 27.8493);
  static const double _zambiaZoom = 6.0;

  @override
  void initState() {
    super.initState();
    _selectedFieldId = widget.selectedField?.id;
  }

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _currentPolygonPoints = [];
      _selectedFieldId = null;
    });
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawing = false;
      _currentPolygonPoints = [];
    });
  }

  void _completePolygon() {
    if (_currentPolygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A field must have at least 3 points'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showNameDialog();
  }

  void _showNameDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Field'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            hintText: 'e.g., North Field, Maize Plot 1',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a field name')),
                );
                return;
              }
              Navigator.pop(context);
              _savePolygon(name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _savePolygon(String name) {
    final polygon = FieldPolygon(
      name: name,
      coordinates: List.from(_currentPolygonPoints),
    );

    setState(() {
      _isDrawing = false;
      _currentPolygonPoints = [];
    });

    widget.onPolygonCreated?.call(polygon);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Field "$name" created successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isDrawing) {
      // Check if tapped on an existing field
      _checkFieldTap(point);
      return;
    }

    setState(() {
      _currentPolygonPoints.add(point);
    });
  }

  void _checkFieldTap(LatLng point) {
    // Check if the tap is inside any existing field polygon
    for (final field in widget.existingFields) {
      if (_isPointInPolygon(point, field.coordinates)) {
        setState(() {
          _selectedFieldId = field.id;
        });
        widget.onFieldSelected?.call(field);
        return;
      }
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude) &&
          point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter ?? _zambiaCenter,
            initialZoom: _zambiaZoom,
            onTap: _onMapTap,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Map tiles based on selected type
            _buildTileLayer(),

            // Existing fields
            ...widget.existingFields.map((field) => PolygonLayer(
                  polygons: [
                    Polygon(
                      points: field.coordinates,
                      color: _selectedFieldId == field.id
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.green.withOpacity(0.2),
                      borderColor: _selectedFieldId == field.id
                          ? Colors.blue
                          : Colors.green,
                      borderStrokeWidth: 2,
                      isFilled: true,
                    ),
                  ],
                )),

            // Current polygon being drawn
            if (_isDrawing && _currentPolygonPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _currentPolygonPoints,
                    color: Colors.red,
                    strokeWidth: 3,
                  ),
                ],
              ),

            // Markers for current polygon points
            if (_isDrawing)
              MarkerLayer(
                markers: _currentPolygonPoints
                    .asMap()
                    .entries
                    .map((entry) => Marker(
                          point: entry.value,
                          width: 30,
                          height: 30,
                          child: GestureDetector(
                            onTap: () {
                              // Remove point on tap
                              setState(() {
                                _currentPolygonPoints.removeAt(entry.key);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

            // Markers for existing fields (labels)
            MarkerLayer(
              markers: widget.existingFields.map((field) {
                // Calculate center of polygon
                final center = _calculatePolygonCenter(field.coordinates);
                return Marker(
                  point: center,
                  width: 120,
                  height: 40,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _selectedFieldId == field.id
                          ? Colors.blue
                          : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        field.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // User location marker (always visible)
            if (widget.initialCenter != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.initialCenter!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Drawing controls
        if (widget.enableDrawing)
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                // Map type toggle button
                FloatingActionButton.small(
                  heroTag: 'mapType',
                  onPressed: _cycleMapType,
                  backgroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.layers, color: Colors.blue, size: 18),
                      Text(
                        _getMapTypeLabel(),
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (!_isDrawing)
                  FloatingActionButton(
                    heroTag: 'draw',
                    onPressed: _startDrawing,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.draw),
                  )
                else ...[
                  FloatingActionButton(
                    heroTag: 'complete',
                    onPressed: _completePolygon,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.check),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'cancel',
                    onPressed: _cancelDrawing,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
          ),

        // Drawing instructions
        if (_isDrawing)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tap on the map to add points',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Points: ${_currentPolygonPoints.length}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap on a point to remove it',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Zoom controls
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoomIn',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoomOut',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'recenter',
                onPressed: () {
                  _mapController.move(_zambiaCenter, _zambiaZoom);
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return _zambiaCenter;

    double lat = 0;
    double lon = 0;

    for (final point in points) {
      lat += point.latitude;
      lon += point.longitude;
    }

    return LatLng(lat / points.length, lon / points.length);
  }

  Widget _buildTileLayer() {
    // OpenStreetMap - simple and reliable
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.agroweather.guide',
      maxZoom: 19,
    );
  }

  void _cycleMapType() {
    setState(() {
      switch (_mapType) {
        case 'street':
          _mapType = 'satellite';
          break;
        case 'satellite':
          _mapType = 'hybrid';
          break;
        case 'hybrid':
          _mapType = 'terrain';
          break;
        case 'terrain':
        default:
          _mapType = 'street';
          break;
      }
    });
  }

  String _getMapTypeLabel() {
    switch (_mapType) {
      case 'satellite':
        return 'Satellite';
      case 'hybrid':
        return 'Hybrid';
      case 'terrain':
        return 'Terrain';
      case 'street':
      default:
        return 'Street';
    }
  }
}

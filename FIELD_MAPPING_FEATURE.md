# Field Mapping & Agro Monitoring Integration

## Overview

The AgroWeather Guide app now includes an interactive map feature that allows farmers to define their field boundaries using polygons and receive field-specific agricultural data through the OpenWeather Agro Monitoring API.

## Features

### 🗺️ Interactive Zambian Map
- Map centered on Zambia with zoom and pan controls
- OpenStreetMap tiles for clear visualization
- Supports multiple saved fields
- Visual field highlighting and labels

### ✏️ Polygon Drawing
- Tap to add points and create custom field shapes
- Minimum 3 points required for valid polygon
- Remove points by tapping on them
- Visual feedback during drawing
- Automatic area calculation in hectares

### 📊 Field-Specific Data

When connected to the Agro Monitoring API, you get:

1. **Current Weather Data**
   - Temperature
   - Humidity
   - Wind speed
   - Precipitation
   - Weather conditions

2. **Soil Conditions**
   - Soil temperature
   - Soil moisture levels

3. **NDVI (Vegetation Health)**
   - Normalized Difference Vegetation Index
   - Health rating (0-100)
   - Historical NDVI trends
   - Vegetation status interpretation

4. **Satellite Imagery**
   - True color images
   - False color composites
   - NDVI visualizations

## How to Use

### 1. Access Field Management

From the Weather screen, tap the **Map icon** (🗺️) in the top-right corner to open the Field Management screen.

### 2. Create a New Field

1. On the Field Management screen, tap the green **+** button (floating action button)
2. Tap on the map to add points that outline your field
   - Each tap adds a numbered point
   - Connect at least 3 points to form a polygon
3. Tap the **checkmark (✓)** button when finished
4. Enter a name for your field (e.g., "North Maize Field")
5. Tap **Save**

### 3. View Field Information

- Tap on any saved field in the list or on the map
- View field details including:
  - Area in hectares
  - Number of boundary points
  - Creation date
  - Current weather conditions
  - Vegetation health (NDVI)
  - Soil conditions

### 4. Set Active Field

- Tap the three-dot menu on any field
- Select "Set as Active"
- The active field will be used for primary monitoring

### 5. Delete a Field

- Tap the three-dot menu on the field
- Select "Delete"
- Confirm deletion

## Setup

### API Configuration

The feature uses your OpenWeather API key for both regular weather and Agro Monitoring data.

#### Get Your Free API Key

1. Visit [OpenWeather API Keys](https://home.openweathermap.org/api_keys)
2. Sign up for a free account
3. Generate an API key
4. The Agro Monitoring API is free for up to 1,000 requests/day

#### Running with API Key

```powershell
flutter run --dart-define=OPENWEATHER_API_KEY=your_api_key_here
```

#### Demo Mode

Without an API key, the app will:
- Still allow you to create and manage field polygons
- Store fields locally on your device
- Show basic field information (area, points, etc.)
- Display a message encouraging you to add an API key for full features

### Dependencies Added

The following packages were added to support this feature:

```yaml
flutter_map: ^7.0.2          # Interactive map widget
latlong2: ^0.9.1             # Latitude/longitude coordinates
flutter_map_dragmarker: ^1.1.1  # Marker interactions
```

## Technical Details

### Data Storage

- **Local Storage**: Fields are saved locally using `SharedPreferences`
- **Cloud Sync**: When an API key is configured, polygons are synced with the Agro Monitoring API
- **Active Field**: The currently monitored field is tracked separately

### Models

- `FieldPolygon`: Represents a field with coordinates and metadata
- `AgroWeatherData`: Weather data specific to a polygon
- `SoilData`: Soil temperature and moisture
- `NdviData`: Vegetation health indices
- `SatelliteImage`: Satellite imagery metadata

### Services

- `AgroMonitoringService`: Handles all Agro API communication
- `FieldRepository`: Manages local field storage and retrieval

### Map Features

- **Base Layer**: OpenStreetMap tiles
- **Polygon Layer**: Displays saved fields with color-coding
- **Marker Layer**: Shows field names and numbered points
- **Interactive Controls**: Zoom in/out, recenter, drawing tools

## Zambia-Specific Features

The map is preconfigured for Zambian farmers:
- Default center: 13.1339°S, 27.8493°E (Zambia's center)
- Default zoom level: 6 (shows entire country)
- Easy recenter button to return to Zambia view

## Best Practices

### Field Creation

1. **Zoom in** before drawing for better accuracy
2. Draw fields with **4-8 points** for optimal accuracy
3. Use descriptive names like "North Maize Field" or "Tomato Plot 2"
4. Regularly check **vegetation health** during growing season

### Data Monitoring

- **Weather data** updates in near real-time
- **NDVI data** typically updates every 5-8 days (depends on satellite passes)
- Check **soil moisture** regularly during dry seasons
- Use **historical NDVI** to compare crop health over time

### Performance

- Keep the number of fields under 20 for best performance
- Delete old/unused fields to reduce clutter
- Fields are stored locally even without internet

## Troubleshooting

### Map Not Loading

- Check internet connection
- Verify you have location permissions enabled
- Try refreshing the screen

### No Field Data Showing

- Ensure you've added your OpenWeather API key
- Verify the API key is valid
- Check that the field has been synced (has an API ID)
- Wait a few moments for initial data fetch

### Polygon Not Saving

- Ensure you have at least 3 points
- Check that you've entered a field name
- Verify local storage permissions

### NDVI Data Missing

- NDVI requires satellite data which may take 1-2 days after field creation
- Cloud cover can delay satellite imagery
- Historical data requires the field to exist for several days

## Future Enhancements

Potential future features:
- Crop-specific recommendations per field
- Field-to-field comparison
- Historical yield tracking
- Irrigation scheduling based on soil moisture
- Pest/disease alerts for specific fields
- Export field data to CSV/PDF

## Support

For issues or questions:
1. Check the app's settings for API key configuration
2. Verify internet connectivity
3. Ensure location permissions are granted
4. Review the OpenWeather API documentation at https://agromonitoring.com/api

---

**Note**: This feature requires an active internet connection for API data. Local field management works offline.

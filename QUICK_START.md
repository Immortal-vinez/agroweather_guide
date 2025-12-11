# Quick Start Guide - Field Mapping Feature

## Installation

1. **Install Dependencies**
   ```powershell
   flutter pub get
   ```

2. **Run the App**
   
   **With API Key (Recommended):**
   ```powershell
   flutter run --dart-define=OPENWEATHER_API_KEY=your_api_key_here
   ```
   
   **Demo Mode (Without API Key):**
   ```powershell
   flutter run
   ```

## Getting Started

### Step 1: Navigate to Field Management
- Open the app
- Go to the **Weather** screen
- Tap the **Map** icon (🗺️) in the top right

### Step 2: Create Your First Field
1. Tap the green **+ (Add)** button
2. Tap on the map to add boundary points (minimum 3 points)
3. Tap the **✓ (Check)** button when done
4. Enter a field name
5. Tap **Save**

### Step 3: View Field Data
- Tap on any field in the list or on the map
- View real-time weather, soil, and vegetation health data

## Features

✅ Interactive Zambian map  
✅ Custom polygon drawing  
✅ Field-specific weather data  
✅ Soil moisture and temperature  
✅ NDVI vegetation health  
✅ Local storage (works offline)  
✅ Cloud sync with Agro API  

## Files Created

### Models
- `lib/models/field_polygon.dart` - Field polygon data structure
- `lib/models/agro_weather_data.dart` - Agricultural weather data models

### Services
- `lib/services/agro_monitoring_service.dart` - Agro API integration
- `lib/services/field_repository.dart` - Local field storage

### Widgets
- `lib/widgets/field_map_widget.dart` - Interactive map component

### Screens
- `lib/screens/field_management_screen.dart` - Field management UI

## API Setup

Get your FREE API key:
1. Visit https://home.openweathermap.org/api_keys
2. Create a free account
3. Generate an API key
4. Free tier includes 1,000 requests/day

## Notes

- The same OpenWeather API key works for both weather and Agro Monitoring
- Fields are stored locally and synced to the cloud when an API key is available
- The map is centered on Zambia by default
- Polygon areas are calculated automatically in hectares

## Troubleshooting

**Issue**: Map not showing  
**Solution**: Check internet connection, ensure Flutter packages are installed

**Issue**: No field data  
**Solution**: Add your OpenWeather API key

**Issue**: Can't create polygon  
**Solution**: Ensure you have at least 3 points before completing

For more details, see `FIELD_MAPPING_FEATURE.md`

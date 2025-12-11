# Run Commands - AgroWeather Guide

## Run with Your Agro Monitoring API Key

**Windows (PowerShell):**
```powershell
flutter run --dart-define=OPENWEATHER_API_KEY=402f3186862061bdf7ee2d4070496a72
```

**For release build:**
```powershell
flutter build apk --dart-define=OPENWEATHER_API_KEY=402f3186862061bdf7ee2d4070496a72
```

## Quick Commands

**Standard run:**
```powershell
flutter run --dart-define=OPENWEATHER_API_KEY=402f3186862061bdf7ee2d4070496a72
```

**Debug with hot reload:**
```powershell
flutter run --dart-define=OPENWEATHER_API_KEY=402f3186862061bdf7ee2d4070496a72
```

**Release build:**
```powershell
flutter build apk --release --dart-define=OPENWEATHER_API_KEY=402f3186862061bdf7ee2d4070496a72
```

## What This Enables

With your API key configured, you get:

✅ **Current Weather** - Real-time weather for each field  
✅ **Weather Forecast** - 5-day forecast per field  
✅ **Soil Data** - Temperature and moisture levels  
✅ **NDVI** - Vegetation health indices  
✅ **Satellite Imagery** - Crop monitoring from space  
✅ **Historical Data** - Track changes over time  

## Features Available

1. **Field Management**
   - Create unlimited field polygons
   - Automatic area calculation
   - Cloud sync with Agro API

2. **Real-Time Monitoring**
   - Weather conditions per field
   - Soil moisture alerts
   - Crop health (NDVI) tracking

3. **Data Analysis**
   - Compare fields
   - Historical trends
   - Vegetation health over time

## API Limits (Free Tier)

- 1,000 API calls per day
- Unlimited field polygons
- Historical data access
- Satellite imagery

## Notes

- The same API key works for both regular weather and Agro Monitoring
- Fields are synced automatically when online
- Local storage keeps fields available offline
- NDVI data updates every 5-8 days (satellite passes)

## Test the Feature

1. Run the app with the command above
2. Go to Weather screen → tap Map icon 🗺️
3. Create a field by tapping the green + button
4. Draw your field boundaries
5. View real-time data for your field!

---

**Important**: Keep your API key secure. Don't commit it to public repositories.

# Web Deployment Guide

## Known Web Limitations

### CORS (Cross-Origin Resource Sharing) Issues

Flutter Web apps run in browsers which enforce CORS policies. This affects API calls to external services.

#### Current Issues:
- ❌ OpenWeatherMap API blocked by browser CORS policy
- ❌ Agro Monitoring API may be blocked by browser CORS policy
- ✅ Works perfectly on mobile (Android/iOS) and desktop (Windows/macOS/Linux)

### Development Workaround

To test the app locally with full API access:

```powershell
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=C:/temp-chrome"
```

**⚠️ Warning:** This disables browser security. Only use for development, not production.

### Production Solutions

#### Option 1: Backend Proxy (Recommended)
Deploy a simple backend service that:
- Receives requests from your Flutter web app
- Adds CORS headers
- Forwards requests to OpenWeather APIs
- Returns responses to your app

Example using Node.js/Express:
```javascript
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  next();
});
```

#### Option 2: Use Mobile/Desktop App
Recommend users download the native app version for full functionality:
- Android APK
- iOS App
- Windows/macOS/Linux Desktop

#### Option 3: Serverless CORS Proxy
Use services like:
- Cloudflare Workers
- AWS Lambda
- Vercel Edge Functions

## API Key Requirements

### OpenWeather API Key
- **Current weather data**: Works with basic free tier key
- **Get key at**: https://home.openweathermap.org/api_keys

### Agro Monitoring API Key
- **Field polygons, soil data, NDVI**: Requires separate activation
- **Even if you have an OpenWeather key**, you must:
  1. Visit https://home.openweathermap.org/api_keys
  2. Click on your API key
  3. Enable "Agro Monitoring" service
  4. Free tier: 1000 requests/day

⚠️ **Common Issue**: Your weather API key may return 401 errors for Agro endpoints if "Agro Monitoring" isn't enabled.

## Testing the App

### Full Feature Testing (Mobile/Desktop)
```powershell
# Android
flutter run -d <device-id>

# Windows Desktop
flutter run -d windows

# Build Release APK
flutter build apk --release
```

### Web Testing (Limited Features)
```powershell
# Development with CORS disabled
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=C:/temp-chrome"

# Build for production deployment
flutter build web --release
```

## Error Messages Explained

### "Web CORS Error: Browser blocked the request"
- **Cause**: Browser security policy blocking cross-origin API calls
- **Fix**: Use development workaround or deploy CORS proxy

### "Invalid API key for Agro Monitoring API"
- **Cause**: API key doesn't have Agro Monitoring service enabled
- **Fix**: Enable service at https://home.openweathermap.org/api_keys

### "Failed to load font Noto Color Emoji"
- **Impact**: Cosmetic only (emojis may not render)
- **Fix**: Not critical, can be suppressed or ignored

## Recommended Approach

For **production deployment**:
1. ✅ Deploy native mobile apps (Android/iOS) - Full features
2. ✅ Deploy desktop apps (Windows/macOS/Linux) - Full features
3. ⚠️ Deploy web version with disclaimer about limited features
4. 💡 Or implement a backend CORS proxy for web

The app is designed for mobile/desktop where it works perfectly without CORS restrictions.

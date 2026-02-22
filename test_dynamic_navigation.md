# GiaTV Dynamic Navigation Test Guide

## Overview
This document outlines the testing process for the newly implemented dynamic navigation system in the GiaTV Roku application.

## Changes Made

### 1. Project Rebranding
- ✅ Changed manifest title from "JoyGo" to "GiaTV"
- ✅ Updated icon references to use GiaTV branding
- ✅ Copied GiaTV logo from Flutter project

### 2. Dynamic Navigation System
- ✅ Created `NavigationApi` component to fetch navigation items from API
- ✅ Created `dynamic_navigation_bar` component to handle dynamic tabs
- ✅ Updated `home_scene` to use dynamic navigation

### 3. Content Models
- ✅ Created `ContentItemHelper.brs` - Roku equivalent of Flutter content models
- ✅ Created `DynamicContentApi` to fetch content based on navigation type

### 4. API Integration
- Navigation API endpoint: `https://api.giatv.com/api/v1/navigation`
- Content API endpoints:
  - Home: `https://api.giatv.com/api/v1/home`
  - Live: `https://api.giatv.com/api/v1/live`
  - Movies: `https://api.giatv.com/api/v1/movies`
  - TV Shows: `https://api.giatv.com/api/v1/tv-shows`

## Testing Steps

### 1. Authentication Test
1. Launch the application
2. Verify login screen appears if not authenticated
3. Login with valid credentials
4. Verify navigation bar appears after successful login

### 2. Dynamic Navigation Test
1. Check if navigation items are loaded from API
2. If API fails, verify fallback to default navigation items:
   - Search
   - Home
   - Live
   - Movies
   - TV Shows
   - Account

### 3. Navigation Functionality Test
1. Use UP/DOWN arrows to navigate between tabs
2. Use RIGHT arrow to move focus to content area
3. Use ENTER to select navigation items
4. Verify active/inactive icon states

### 4. Content Loading Test
1. Navigate to each tab
2. Verify content loads for each navigation type
3. Check fallback content if API fails
4. Verify content displays correctly

### 5. Icon and Branding Test
1. Verify GiaTV logo appears in navigation
2. Check navigation icons are correct
3. Verify active/inactive icon states work

## Expected Behavior

### Navigation Structure
```
Search (Static)
├── Dynamic Navigation Items (from API)
│   ├── Home (ID: 1)
│   ├── Live (ID: 2)
│   ├── Movies (ID: 3)
│   └── TV Shows (ID: 4)
└── Account (Static)
```

### API Response Format
Navigation API should return:
```json
{
  "data": [
    {
      "id": 1,
      "title": "Home",
      "images": {
        "full_hd_images": ["icon_url"],
        "hd_images": ["icon_url"]
      }
    }
  ]
}
```

Content API should return:
```json
{
  "data": [
    {
      "id": 1,
      "title": "Content Title",
      "description": "Content Description",
      "type": "movie|series|live",
      "images": {
        "poster": "poster_url",
        "thumbnail": "thumb_url",
        "banner": "banner_url"
      },
      "sources": {
        "primary": "video_url",
        "hls": "hls_url"
      }
    }
  ]
}
```

## Fallback Mechanisms

1. **Navigation API Failure**: Uses default navigation items
2. **Content API Failure**: Shows placeholder content
3. **Authentication Failure**: Redirects to login screen
4. **Missing Images**: Uses default placeholder images

## Files Modified/Created

### New Files
- `components/api/NavigationApi.xml`
- `components/api/NavigationApi.brs`
- `components/api/DynamicContentApi.xml`
- `components/api/DynamicContentApi.brs`
- `components/screens/dynamic_navigation_bar.xml`
- `components/screens/dynamic_navigation_bar.brs`
- `components/helpers/ContentItemHelper.brs`

### Modified Files
- `manifest` - Updated title and icons
- `components/home_scene.xml` - Added dynamic navigation
- `components/home_scene.brs` - Added dynamic navigation handling

### Assets Added
- `images/png/gia-tv-logo.png`
- `images/png/gia-tv-big.png`

## Next Steps

1. Test the application on Roku device/simulator
2. Verify API endpoints are working
3. Test error handling and fallback mechanisms
4. Optimize performance and user experience
5. Add additional content types as needed

## Troubleshooting

### Common Issues
1. **Navigation not loading**: Check API endpoint and authentication
2. **Content not displaying**: Verify content API responses
3. **Icons not showing**: Check image file paths and URLs
4. **Focus issues**: Verify focus handling in navigation components

### Debug Information
- Check Roku debug console for API response logs
- Verify authentication token is valid
- Check network connectivity
- Validate JSON response formats

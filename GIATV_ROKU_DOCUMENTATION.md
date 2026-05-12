# GiaTV Roku Application - Complete Technical Documentation

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Visual Architecture](#visual-architecture)
3. [API Patterns & Data Loading](#api-patterns--data-loading)
4. [Caching System](#caching-system)
5. [Screen Management](#screen-management)
6. [Component System](#component-system)
7. [Navigation System](#navigation-system)
8. [M3U IPTV Integration](#m3u-iptv-integration)
9. [Video Playback System](#video-playback-system)
10. [Performance Optimizations](#performance-optimizations)
11. [Agent Development Guide](#agent-development-guide)

---

## Architecture Overview

### Core Structure
The GiaTV Roku application follows a **modular SceneGraph architecture** with:

- **Main Scene**: `components/home_scene.xml` - Central coordinator for all screens and navigation
- **Dynamic Content System**: Screens generated based on API navigation data
- **Static Screens**: Profile, Search, Login - manually positioned
- **API Layer**: Asynchronous data fetching with comprehensive caching
- **Component Library**: Reusable UI components for different content types

### Key Design Patterns

1. **Observer Pattern**: Extensive use of `observeField` for state management
2. **Factory Pattern**: Dynamic screen creation based on content types
3. **Cache-First Strategy**: All API calls check cache before network requests
4. **Responsive Design**: Components adapt to different screen layouts

---

## Visual Architecture

### Screen Layout System

#### Navigation Bar (360px width)
```
Position: [0, 0] (fixed left)
Width: 360px (updated from 240px)
Background: #1f2740
Focus Color: #0069a880

Structure:
├── Logo (positioned left at [30, -40])
├── Dynamic Navigation Items (centered at [35, yPosition])
│   ├── Width: 290px focus indicators
│   ├── Spacing: 100px between items
│   └── Start Y: 150px from top
└── Profile Tab (always at bottom)
```

#### Content Area
```
Position: [360, 0] (right of navigation)
Width: 1560px (1920 - 360)
Height: 1080px

Content Positioning:
├── Dynamic Screens Container: [360, 0]
├── Static Screens: [360, 0]
├── Home Screen Content: [280, 20] (additional offset)
└── Account Screen: Custom positioning with 1560px width
```

### Component Layout Patterns

#### 6-Item Landscape Layout (280x196)
Used for: Live TV, TV Shows, Age Restricted, Personal, Series
```
Grid Configuration:
├── numColumns: 6
├── itemSize: [280, 196]
├── rowHeights: [220.0]
├── rowItemSpacing: [[15, 15]]
└── Component: SeriesItemComponent (responsive)
```

#### Portrait Layout (280x420)
Used for: Movies
```
Grid Configuration:
├── itemSize: [280, 420] 
├── rowHeights: [440.0]
├── rowItemSpacing: [[15, 20]]
└── Component: RowListItemComponent (adaptive)
```

### Responsive Component System

#### SeriesItemComponent (Dynamic Sizing)
```brightscript
' Auto-adjusts based on parent grid itemSize
onChange="updateSize" for width/height fields

updateSize() function:
├── Calculates scale ratio from default 350x245
├── Proportionally scales all child elements
├── Adjusts poster, title, live badge positions
└── Maintains aspect ratios
```

### Animation System

#### Navigation Expand/Collapse
```
Collapse: [0, 0] → [-360, 0] (hide navigation)
Expand: [-360, 0] → [0, 0] (show navigation)
Duration: 0.25s with outCubic easing
```

#### Content Area Animations
```
Content Expand: [360, 0] → [0, 0] (full screen)
Content Collapse: [0, 0] → [360, 0] (with navigation)
Banner animations sync with content
```

---

## API Patterns & Data Loading

### Base API Configuration
```
Base URL: https://giatv.dineo.uk/api/
Authentication: Bearer token from registry
Headers:
├── Content-Type: application/json
├── Accept: application/json
└── Authorization: Bearer {token}

Timeouts:
├── Connection: 3 seconds (navigation)
├── Connection: 60 seconds (M3U loading)
└── Response wait: 3-60 seconds based on API type
```

### API Endpoint Patterns

#### Navigation API (`NavigationApi.brs`)
```
Endpoint: /content-type/list
Purpose: Fetches dynamic navigation structure
Cache TTL: 1 hour (3600 seconds)
Response: Array of content types with metadata

Flow:
1. Check cache first
2. Return cached data immediately if valid
3. Fetch fresh data in background
4. Update cache for next request
```

#### Content APIs (`DynamicContentApi.brs`)
```
Endpoints by Content Type:
├── Home (0): /home-content/list
├── Movies (1): /vod-content/list
├── Series (2): /series-content/list  
├── Live TV (3): /live-content/list
├── User Channels (14): /user-channels/list?page={n}
├── Age Restricted (15): /age-restricted/list
├── Personal (16): /personal-content/list
└── TV Guide (17): /tv-guide/data

Cache TTL: 10 minutes (600 seconds)
Cache Key: "content_{typeId}_page_{pageNum}"
```

#### M3U Loader API (`M3ULoaderApi.brs`)
```
Purpose: Loads IPTV M3U playlists
Timeout: 60 seconds (IPTV servers can be slow)

Critical Headers for IPTV compatibility:
├── User-Agent: Browser-like string
├── Referer: Base URL of playlist
├── Origin: Host origin
├── Accept: */*
├── Accept-Encoding: identity (no compression)
└── Connection: keep-alive

Flow:
1. Parse M3U URL for validation
2. Set comprehensive headers
3. Load playlist with roMessagePort (async)
4. Parse #EXTINF entries
5. Extract channel names and stream URLs
```

### Authentication System
```
Storage: Registry section "AUTH"
Key: "authData" 
Format: JSON string

Structure:
{
  "accessToken": "bearer_token_here",
  "userId": 12345,
  "email": "user@example.com",
  "authenticated": true
}

Token Usage:
├── Automatically added to all API requests
├── Retrieved via RetrieveAuthData() function
└── Validated on each request
```

---

## Caching System

### Cache Architecture
The application uses `roRegistrySection` for persistent caching with TTL (Time To Live) expiration.

#### Cache Utility Functions
```brightscript
readCache(key as string, maxAgeSeconds as integer) as dynamic
├── Reads from registry with timestamp validation
├── Returns cached data if within TTL
└── Returns invalid if expired or not found

writeCache(key as string, data as string) as void
├── Stores data with current timestamp
└── Format: {"data": data, "timestamp": currentTime}

clearCache(pattern as string) as void
├── Removes cache entries matching pattern
└── Used for cache invalidation
```

#### Cache Strategy by API Type

**Navigation Cache**
```
TTL: 1 hour (3600 seconds)
Key: "navigationData"
Strategy: Cache-first with background refresh
Purpose: Minimize app startup time
```

**Content Cache**
```
TTL: 10 minutes (600 seconds) 
Key: "content_{typeId}_page_{pageNum}"
Strategy: Cache-first with background refresh
Purpose: Improve content browsing performance
```

**User Channels Pagination**
```
Special handling for contentTypeId=14:
├── Page-specific caching
├── Async loading for pages 2+
├── Background pre-loading
└── Infinite scroll support
```

---

## Screen Management

### Dynamic Screen System

#### Screen Creation Flow
```brightscript
rebuildContentScreens(navigationData) flow:
1. Clear existing dynamic screens
2. Filter navigation data by authentication
3. Create screens for each valid content type
4. Position screens in dynamicScreensContainer
5. Set up content loading and observers

Screen Positioning:
├── Container: [360, 0] (right of nav)
├── Visible screen: [0, 0] (within container)
├── Hidden screens: [5400, 0] (off-screen right)
└── Account screen: [360, 0] (static positioning)
```

#### Screen State Management
```
States:
├── Visible: translation [0, 0] within container
├── Hidden: translation [5400, 0] (off-screen)
├── Loading: Shows loading indicators
└── Error: Shows error states

Focus Management:
├── Only visible screen receives focus
├── Navigation bar manages screen switching
├── Focus restoration after detail views
└── Keyboard navigation between elements
```

### Static Screen System

#### Account/Profile Screen
```
Position: Absolute [360, 0] (not in container)
Width: 1560px (adjusted for 360px nav)
Components:
├── Profile header with avatar
├── Authentication status card
├── Login/Logout actions
├── App version and device info
└── User profile details (when authenticated)

Focus System:
├── Card-based navigation
├── Focusable login/logout groups
└── Visual focus indicators
```

#### Search Screen  
```
Position: [360, 0] (static)
Layout:
├── Full-width gradient background
├── Search container at [50, 200]
├── RowList with SearchItemComponent
└── Keyboard input handling
```

---

## Component System

### Adaptive Components

#### SeriesItemComponent (Landscape Content)
```
Default Size: 350x245px
Adaptive Sizing: onChange="updateSize"

Elements:
├── Poster image (scales proportionally)
├── Title label (adjusts width/position) 
├── Live badge (scales and repositions)
└── Background (matches component size)

Usage:
├── Live TV (6 items: 280x196)
├── TV Shows (6 items: 280x196)
├── Age Restricted (6 items: 280x196)  
├── Personal (6 items: 280x196)
└── Series (6 items: 280x196)
```

#### RowListItemComponent (Portrait Content + Adaptive)
```
Adaptive Layout: Based on content.isLiveChannel

Portrait Mode (Movies):
├── Size: 280x420px
├── Poster: 276x350px
├── Overlay: 66px height
├── Full title, description, meta labels
└── Centered play button

Landscape Mode (Live/TV Shows):
├── Size: 280x196px  
├── Poster: 276x155px
├── Overlay: 37px height (compact)
├── Title only (description/meta hidden)
└── Adjusted play button position

setupLayout(isLandscape) function handles switching
```

### Specialized Components

#### M3U Channel Preview System
```
Components:
├── Preview Player: 360x250px overlay
├── Status indicators: Loading, Error, Live
├── Dynamic positioning over focused item
└── Visual row calculation for floatingFocus

Advanced Features:
├── Stream format detection (HLS, TS, MP4)
├── Error handling and recovery
├── Single video instance management
└── Asynchronous loading
```

#### Navigation Components
```
NavigationItemComponent:
├── Focus indicator: 290px width
├── Label positioning: [30, 0] for centering
├── Background color: #0069a880 (focus)
└── Text color: #0069a8 (active)

Dynamic creation based on API data:
├── Profile tab always added at bottom
├── Responsive to authentication state
└── Synchronized with content screens
```

---

## Navigation System

### Multi-Navigation Architecture
```
Navigation Modes:
├── Mode 0: dynamic_navigation_bar (ACTIVE)
├── Mode 1: vertical_navigation_bar 
└── Mode 2: markup_navigation_bar

Current: m.navigationMode = 0 (dynamic)
```

### Dynamic Navigation Bar

#### Structure
```
Width: 360px
Background: #1f2740
Logo: [30, -40] positioning

Item Layout:
├── Container: [35, yPosition] (centered)
├── Focus indicator: 290px width
├── Vertical spacing: 100px
├── Start position: Y=150
└── Auto-generated from API data

Colors:
├── Background: #1f2740
├── Focus background: #0069a880  
├── Active text: #0069a8
├── Inactive text: #ffffff
└── Focus indicator opacity: 0.2
```

#### Navigation Data Flow
```
1. API fetches navigation structure
2. Filters by authentication status
3. Injects TV Guide tab (position after Live TV)
4. Injects User Channels tab (position after Movies)
5. Adds Profile tab at end
6. Builds UI components dynamically
7. Syncs with content screen creation
```

### Navigation Event Handling
```
Key Events:
├── Up/Down: Navigate between tabs
├── Right: Transfer focus to content
├── Left: Return focus to navigation  
├── OK: Activate selected tab
└── Back: Return to home/previous state

Focus Management:
├── Navigation bar maintains navHasFocus state
├── Content screens observe navigation changes
├── Smooth focus transitions with animations
└── Focus restoration after detail views
```

---

## M3U IPTV Integration

### M3U Channel Screen Architecture

#### Core Components
```
Grid System:
├── channelGrid: 4 columns (with categories)
├── channelGrid: 5 columns (no categories) 
├── Category sidebar: LabelList
├── Search results: Separate grid
└── Preview player: Floating overlay

Layout Adaptation:
├── With categories: Grid at [330, 0], 4 columns
├── Without categories: Grid at [0, 0], 5 columns  
├── Dynamic column switching based on content
└── Category list hidden when not needed
```

#### Category System
```brightscript
extractAndBuildCategories() flow:
1. Parse channel names for category patterns
2. Extract categories before ":" separator
3. Count channels per category
4. Build LabelList content with counts
5. Update UI layout based on category presence

Category Display:
├── Format: "Category Name (Count)"
├── Special handling for "All Channels" 
├── Padding for visual alignment
└── Focus animations and transitions
```

#### Preview Player System
```
Advanced Visual Row Calculation:
├── floatingFocus on MarkupGrid (numRows=3)
├── Direction-aware positioning (up vs down scroll)
├── Asymmetric scrolling behavior handling
├── Dynamic positioning over focused item
└── Size: 360x250px overlay

visualRow Logic:
Scroll Down: focus stays at bottom (visual row 2)
Scroll Up: focus at top for rows 0-1, middle for 2+
Initial: natural positioning based on row number
```

#### M3U Parsing & Loading
```
M3U Format Support:
├── #EXTINF parsing for channel metadata
├── Stream URL extraction  
├── Category detection from names
├── Logo/poster URL handling
└── Error handling for malformed entries

IPTV Server Compatibility:
├── Comprehensive HTTP headers
├── Extended timeout handling (60s)
├── Referer/Origin header calculation
├── User-Agent spoofing for compatibility
└── Connection keep-alive
```

### Search Functionality
```
Search Features:
├── Real-time filtering (100 result limit)
├── Case-insensitive matching
├── Channel name and category search
├── UI state management (hide categories)
├── Result counter with overflow indicator
└── Focus restoration on search exit

Search Flow:
1. Enter search mode (hide categories)
2. Filter channels by query
3. Limit results to prevent crashes  
4. Update grid with filtered content
5. Show result count and status
6. Restore full content on exit
```

---

## Video Playback System

### Single Video Instance Management
```
Roku Limitation: Only one Video node can be active
Strategy: 
├── Stop preview player before full playback
├── Use single Video node per screen
├── Clean up video resources on screen exit
└── Proper state management for overlays
```

### Stream Format Detection
```brightscript
detectStreamFormat(url) function:
├── HLS: .m3u8 extension → "hls"
├── MPEG-TS: .ts extension → "ts"  
├── MP4: .mp4 extension → "mp4"
├── Fallback: "hls" for unknown
└── Roku ContentNode format assignment

Error Handling:
├── IgnoreStreamErrors=true for malformed streams
├── Stream format forcing for compatibility
├── Loading state management
└── User-friendly error messages
```

### Focus Restoration
```
Video Playback Flow:
1. Store focused item index before playback
2. Navigate to full-screen video player  
3. Handle video player back button
4. Restore focus to stored index
5. Update preview player for restored item
6. Resume normal navigation

Implementation:
├── m.lastFocusedIndex storage
├── m.activeGrid.jumpToItem(index) restoration
├── onVisibilityChanged() handling
└── Cross-screen state preservation
```

---

## Performance Optimizations

### App Startup Optimizations
```
Strategies Implemented:
1. Cache navigation data (1-hour TTL)
2. Cache content data (10-minute TTL)
3. Async User Channels loading
4. Background data prefetching
5. Lazy content screen creation

Startup Flow:
1. Show splash screen
2. Load cached navigation immediately  
3. Build navigation UI with cached data
4. Create content screens lazily
5. Fetch fresh data in background
6. Hide splash when first screen ready
```

### Content Loading Strategy
```
User Channels (contentTypeId=14):
├── Synchronous → Asynchronous conversion
├── Page 1 only on initial load
├── Subsequent pages loaded on demand
├── Background pre-loading for smooth scrolling
└── Pagination state management

Other Content Types:
├── Cache-first loading
├── Background refresh strategy
├── Error fallback to defaults
└── Loading state indicators
```

### Memory Management
```
Techniques:
├── Content caching with TTL expiration
├── Off-screen positioning (not destruction)
├── Single video instance reuse
├── Event observer cleanup
└── Registry-based persistent storage

Screen Management:
├── Hide vs destroy for performance
├── Translation-based visibility
├── Focus management without recreation
└── Efficient state preservation
```

---

## Agent Development Guide

### Working with the Codebase

#### File Organization Patterns
```
Core Architecture:
├── components/home_scene.* - Main application controller
├── components/screens/ - Screen implementations  
├── components/api/ - Data fetching layer
├── components/widgets/ - Reusable UI components
└── components/screens/{screen}/ - Screen-specific files

Navigation:
├── components/screens/dynamic_navigation_bar.* - Active navigation
├── components/screens/navigation_bar.* - Legacy static navigation
├── components/screens/vertical_navigation_bar.* - Alternative nav
└── components/screens/markup_navigation_bar.* - Alternative nav
```

#### Key Development Patterns

**Screen Creation**
```brightscript
1. Create XML layout in components/screens/{name}/
2. Create BRS logic file with same name
3. Add to main scene XML if static screen
4. For dynamic screens: Add to navigation API response
5. Handle in rebuildContentScreens() flow
```

**Component Development** 
```brightscript
1. Create widget in components/widgets/
2. Make responsive with onChange handlers if needed
3. Use in screen RowList/MarkupGrid itemComponentName
4. Test with different content types/sizes
5. Add to buildContentDisplay() configurations
```

**API Integration**
```brightscript
1. Create Task in components/api/{Name}Api.*
2. Implement caching with readCache/writeCache
3. Handle authentication token injection
4. Add error handling and timeouts
5. Process response data appropriately
```

#### Common Modification Patterns

**Adding New Content Type**
```
1. Update navigation API to return new type
2. Add endpoint mapping in getApiEndpointForContentType()
3. Add case in buildContentDisplay() function
4. Create/update appropriate item component
5. Test with authentication requirements
```

**Layout Modifications**
```
Navigation Width Changes:
├── Update dynamic_navigation_bar.xml width
├── Update home_scene.xml container positions
├── Update static screen positioning in home_scene.brs
├── Update animation keyframes
└── Test expand/collapse functionality

Content Layout Changes:
├── Update itemSize arrays in buildContentDisplay()
├── Update rowHeights for new item sizes
├── Update rowItemSpacing for visual balance
├── Test component responsiveness
└── Verify different content types display correctly
```

**Performance Tuning**
```
Cache TTL Adjustments:
├── Navigation: 1 hour (infrequent changes)
├── Content: 10 minutes (moderate updates)
├── User-specific: Lower TTL for personalization
└── Static data: Longer TTL for better performance

Loading Optimizations:
├── Async API calls where possible  
├── Background data prefetching
├── Pagination for large datasets
├── Lazy loading for non-critical content
└── Progressive enhancement strategies
```

### Debugging Guidelines

#### Common Issue Areas
```
Focus Management:
├── Check navHasFocus state consistency
├── Verify focus restoration after transitions
├── Test keyboard navigation paths
└── Ensure focusable properties are correct

Video Playback:
├── Single video instance limitation
├── Stream format detection accuracy
├── Preview player state management  
└── Focus restoration after playback

Layout Issues:
├── Translation positioning calculations
├── Container vs absolute positioning
├── Animation keyframe accuracy
└── Content overflow handling
```

#### Debug Logging Patterns
```brightscript
Consistent Logging Format:
print "FileName.brs - [functionName] Message with context"

Key Debug Points:
├── API request/response logging
├── Focus state changes
├── Screen transitions
├── Content loading progress
└── Error conditions with stack context
```

### Best Practices for Agents

1. **Always Read First**: Use Read tool to examine existing code before modifications
2. **Preserve Comments**: The codebase has extensive debugging comments - maintain them
3. **Test Responsiveness**: Components should work across different screen layouts
4. **Check Authentication**: Many features require authentication state handling
5. **Verify Caching**: Understand cache behavior before modifying data flows
6. **Focus Management**: Test keyboard navigation after any UI changes
7. **Performance Impact**: Consider memory and loading time implications
8. **Cross-Screen Testing**: Test navigation between all screen types
9. **M3U Compatibility**: IPTV features require special header handling
10. **Error Handling**: Maintain robust error handling for network operations

### Current Configuration Summary
```
Navigation: 360px width, #1f2740 background, #0069a880 focus
Layout: 6-item landscape (280x196) for most content types  
Caching: 1-hour navigation, 10-minute content TTL
Authentication: Bearer token from registry
Video: Single instance with preview overlay system
M3U: Full IPTV compatibility with advanced features
Performance: Cache-first with background refresh strategy
```

This documentation should provide comprehensive guidance for future development and agent interactions with the GiaTV Roku application.
# M3U Channels Screen Documentation

## Overview

The **M3U Channels Screen** (`M3UChannelScreen`) is a specialized screen component for browsing and playing IPTV channels from M3U playlists. It provides a modern, TV-optimized interface with category filtering, channel search, live preview functionality, and seamless video playback integration.

---

## Table of Contents

1. [File Structure](#file-structure)
2. [Features](#features)
3. [UI Components](#ui-components)
4. [Data Flow](#data-flow)
5. [M3U Parsing](#m3u-parsing)
6. [Category System](#category-system)
7. [Search Functionality](#search-functionality)
8. [Preview Player](#preview-player)
9. [Navigation & Controls](#navigation--controls)
10. [Performance Optimizations](#performance-optimizations)
11. [Integration Points](#integration-points)
12. [Component API](#component-api)

---

## File Structure

```
components/screens/
├── M3UChannelScreen.xml      # UI layout definition
├── M3UChannelScreen.brs      # Screen logic and functionality
├── M3UChannelItem.xml        # Individual channel card UI
└── M3UChannelItem.brs        # Channel card logic

components/api/
└── M3ULoaderApi.brs          # Async M3U playlist fetching task
```

---

## Features

### Core Features
- **M3U Playlist Loading**: Fetches and parses M3U/M3U8 playlists from any URL
- **Category Filtering**: Auto-extracts categories from channel data (group-title or name prefix)
- **Channel Search**: Full-text search across channel names and categories
- **Live Preview**: Real-time video preview of focused channels
- **Pagination**: Lazy-loads channels in batches of 100 for performance
- **Focus Restoration**: Remembers position when returning from full-screen playback

### UI Features
- Modern dark theme with cyan accent colors
- Hero header with stats display and clock
- Animated grid transitions when changing categories
- Responsive category sidebar (hides when no categories found)
- Loading states with spinner and status messages
- Navigation hints for user guidance

---

## UI Components

### Layout Structure

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        HERO HEADER SECTION (140px)                        │
│  ┌──────────────┬───────────────────────────┬──────────────────────────┐ │
│  │ Screen Icon  │    Stats Card             │   Time    │  GiaTV Logo  │ │
│  │ M3U Channels │    "X Channels"           │   00:00   │              │ │
│  │ Subtitle     │    "Item Y of Z selected" │   Local   │              │ │
│  └──────────────┴───────────────────────────┴──────────────────────────┘ │
│  ════════════════════════════════════════════════════════════════════════│
├──────────────────────────────────────────────────────────────────────────┤
│                      SEARCH STATUS BAR (when searching)                   │
│  🔍 Searching: "query"                    OPTIONS: New Search • BACK: Clear│
├──────────────────────────────────────────────────────────────────────────┤
│ CONTENT AREA (starts at y=220)                                            │
│ ┌─────────────┬──────────────────────────────────────────────────────────┐│
│ │  SIDEBAR    │              CHANNEL GRID (4 columns)                    ││
│ │  (280px)    │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        ││
│ │ ┌─────────┐ │  │ Channel │ │ Channel │ │ Channel │ │ Channel │        ││
│ │ │📁 Categ │ │  │  Item   │ │  Item   │ │  Item   │ │  Item   │        ││
│ │ ├─────────┤ │  │ 340x240 │ │ 340x240 │ │ 340x240 │ │ 340x240 │        ││
│ │ │ All (X) │ │  └─────────┘ └─────────┘ └─────────┘ └─────────┘        ││
│ │ │ Cat1 (Y)│ │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        ││
│ │ │ Cat2 (Z)│ │  │ Channel │ │ Channel │ │ PREVIEW │ │ Channel │        ││
│ │ │ ...     │ │  │  Item   │ │  Item   │ │ PLAYER  │ │  Item   │        ││
│ │ │         │ │  │         │ │         │ │ Overlay │ │         │        ││
│ │ │         │ │  └─────────┘ └─────────┘ └─────────┘ └─────────┘        ││
│ │ ├─────────┤ │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        ││
│ │ │↑↓ • →   │ │  │ Channel │ │ Channel │ │ Channel │ │ Channel │        ││
│ │ └─────────┘ │  │  Item   │ │  Item   │ │  Item   │ │  Item   │        ││
│ │             │  └─────────┘ └─────────┘ └─────────┘ └─────────┘        ││
│ └─────────────┴──────────────────────────────────────────────────────────┘│
│                   OK: Play Full Screen • ←: Categories • OPTIONS: Search  │
└──────────────────────────────────────────────────────────────────────────┘
```

### Key UI Elements

| Element | ID | Description |
|---------|----|----|
| Background | `backgroundRect` | Dark base (`#0a0e14`) |
| Header Bar | `headerBarBg` | Top header (`#0f1419`) |
| Stats Card | `statsCardBg` | Channel count display (`#1a1f2e`) |
| Sidebar | `sidebarBg` | Category list container (`#111827`) |
| Category List | `categoryLabelList` | Scrollable `LabelList` with categories |
| Channel Grid | `channelGrid` | `MarkupGrid` with `M3UChannelItem` components |
| Search Grid | `searchResultsGrid` | Separate grid for search results |
| Preview Player | `previewPlayerContainer` | Video overlay on focused item |
| Loading Group | `loadingGroup` | Centered loading card with spinner |

### Channel Item Card (`M3UChannelItem`)

```
┌────────────────────────────────────┐
│  POSTER AREA (340x190)             │
│  ┌────────────────────────────────┐│
│  │ [Category]          [HD Badge] ││
│  │                                ││
│  │         Channel Logo           ││
│  │                                ││
│  │      [Play Icon on Focus]      ││
│  │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓││
│  └────────────────────────────────┘│
├────────────────────────────────────┤
│  TITLE SECTION (340x50)            │
│  ┃ Channel Name                    │
│  ┃ Category/Subtitle               │
└────────────────────────────────────┘
```

---

## Data Flow

```
┌─────────────────┐
│  User selects   │
│  M3U playlist   │
│  from Personal  │
│  tab content    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ M3UChannelScreen│
│ receives m3uUrl │
│ field change    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌─────────────────┐
│ loadM3UPlaylist │─────▶│ M3ULoaderApi    │
│ shows loading   │      │ Task (async)    │
└─────────────────┘      │                 │
                         │ - HTTP GET      │
                         │ - Custom headers│
                         │ - 60s timeout   │
                         └────────┬────────┘
                                  │
         ┌────────────────────────┘
         ▼
┌─────────────────┐
│ parseM3UContent │
│ - Parse lines   │
│ - Extract #EXTINF│
│ - Build channel │
│   array         │
└────────┬────────┘
         │
         ├──────────────────────────────────┐
         ▼                                  ▼
┌─────────────────┐              ┌─────────────────┐
│extractAndBuild  │              │ buildChannelGrid│
│Categories       │              │ - Paginate      │
│ - Find unique   │              │ - Create nodes  │
│ - Count per cat │              │ - Show grid     │
│ - Build sidebar │              └─────────────────┘
└─────────────────┘
```

---

## M3U Parsing

### Supported M3U Format

```m3u
#EXTM3U
#EXTINF:-1 tvg-id="channel1" tvg-name="CNN" tvg-logo="http://logo.url/cnn.png" group-title="News",CNN HD
http://stream.url/cnn/playlist.m3u8

#EXTINF:-1 tvg-name="BBC World" group-title="News",BBC World
http://stream.url/bbc/stream.ts
```

### Extracted Fields

| M3U Attribute | Channel Property | Fallback |
|---------------|------------------|----------|
| `tvg-name` | `name` | Text after comma |
| `tvg-logo` | `logo` | Placeholder image |
| `tvg-chno` | `channelNumber` | Empty |
| `group-title` | `category` | Prefix before colon in name |
| Stream URL | `url` | Required |

### Category Extraction Logic

Categories are extracted in this priority order:

1. **`group-title` attribute** - Standard M3U category tag
2. **Name prefix** - If channel name contains "PREFIX: Name" format (e.g., "USA: CNN HD" → category "USA")

```brightscript
' Example: "USA: CNN HD" -> category = "USA"
colonPos = Instr(1, currentChannel.name, ":")
if colonPos > 1 and colonPos <= 10
    prefixCategory = Left(currentChannel.name, colonPos - 1).Trim()
end if
```

---

## Category System

### Category List Behavior

- **Initial State**: "All" category selected, showing all channels
- **Category Selection**: Triggers grid fade-out → rebuild → fade-in animation
- **Grid Focus Reset**: Always resets to first item (index 0) after category change
- **Dynamic Column Count**:
  - **4 columns** when categories exist (sidebar visible)
  - **5 columns** when no categories (full width)

### Category Item Format

```
    All (1234)
    News (45)
    Sports (67)
    Entertainment (89)
```

### Visibility Logic

```brightscript
' Show sidebar if categories exist
if m.categories.Count() > 0
    m.categoryListContainer.visible = true
    m.channelGridContainer.translation = [310, 0]
    m.channelGrid.numColumns = 4
else
    m.categoryListContainer.visible = false
    m.channelGridContainer.translation = [0, 0]
    m.channelGrid.numColumns = 5
end if
```

---

## Search Functionality

### Search Flow

1. User presses **OPTIONS** button
2. `KeyboardDialog` appears with "Search Channels" title
3. User enters search text and presses "Search"
4. Screen enters **search mode**:
   - Category sidebar hides
   - Search status bar appears
   - Grid expands to full width
   - Search results displayed in separate grid

### Search Algorithm

```brightscript
' Case-insensitive search in name and category
searchLower = LCase(m.searchQuery)

for each channel in m.channels
    matchFound = false
    
    ' Search in channel name
    if LCase(channel.name).Instr(searchLower) >= 0
        matchFound = true
    end if
    
    ' Search in category
    if not matchFound and LCase(channel.category).Instr(searchLower) >= 0
        matchFound = true
    end if
    
    if matchFound
        m.filteredChannels.Push(channel)
    end if
end for
```

### Search Limits

- **Maximum results displayed**: 100 (prevents UI performance issues)
- Searches through **all channels**, not just loaded ones

### Exiting Search Mode

- **BACK button**: Returns to normal view, restores category sidebar
- **OPTIONS button**: Opens new search

---

## Preview Player

### Preview Player Behavior

The preview player overlays the **poster area only** (340x190px) of the focused channel item, leaving the title section visible.

### Position Calculation

```brightscript
' Grid item dimensions
itemWidth = 340
itemHeight = 240    ' Total item height
posterHeight = 190  ' Poster area only
spacingX = 25
spacingY = 25

' Calculate position
column = focusedIndex mod numColumns
visualRow = calculateVisualRow(row, scrollDirection)

posX = column * (itemWidth + spacingX)
posY = visualRow * (itemHeight + spacingY)
```

### Floating Focus Handling

The `MarkupGrid` uses `vertFocusAnimationStyle="floatingFocus"` with `numRows=3`, which means:

- **Scrolling DOWN**: Focus reaches bottom (row 2) and stays there while grid scrolls
- **Scrolling UP**: Focus moves up through visible positions, then grid scrolls

```brightscript
if scrollDirection = "down"
    if row >= 2 then visualRow = 2
else if scrollDirection = "up"
    if row <= 1 then visualRow = 0
    else if row >= 2 then visualRow = 1
end if
```

### Preview Player States

| State | UI Response |
|-------|-------------|
| `buffering` | Show "Loading Stream..." with spinner |
| `playing` | Hide status overlay |
| `error` | Show "Stream Error" message |
| `stopped` | Hide status overlay |

### Important: Single Video Instance

Roku only supports one active video instance. Before navigating to full-screen playback:

```brightscript
' MUST stop preview before full-screen play
stopPreviewPlayer()
m.previewPlayerContainer.visible = false
m.currentPreviewUrl = ""

' Then trigger full-screen video
m.top.videoPlayRequested = videoData
```

---

## Navigation & Controls

### Remote Control Mapping

| Button | Action |
|--------|--------|
| **OK** | Play selected channel full-screen |
| **LEFT** | Move to category sidebar (from grid column 0) |
| **RIGHT** | Move to channel grid (from category list) |
| **UP/DOWN** | Navigate within current list/grid |
| **OPTIONS** | Open search keyboard |
| **BACK** | Exit search mode → Exit screen |

### Focus Management

```brightscript
' Priority for focus restoration
1. Active grid (if has content)
2. Category list (if visible with content)
3. Main channel grid
4. Screen itself (fallback)
```

### Focus Restoration After Video Playback

```brightscript
' Store index before navigation
m.lastFocusedIndex = activeGrid.itemFocused

' Restore on visibility change
if m.lastFocusedIndex >= 0
    m.activeGrid.jumpToItem = m.lastFocusedIndex
end if
```

---

## Performance Optimizations

### Pagination System

- **Channels per page**: 100
- **Auto-load trigger**: When user focuses within last 10 items
- **Progress indicator**: Shows "Loading more channels..." briefly

```brightscript
triggerIndex = m.loadedChannels - 10
if focusedIndex >= triggerIndex and m.loadedChannels < m.totalChannels
    loadChannelPage()
end if
```

### Async M3U Loading

The `M3ULoaderApi` task runs in background:
- Uses `AsyncGetToString()` for non-blocking fetch
- 60-second connection timeout
- Custom HTTP headers for IPTV server compatibility

### Grid Animation

- **Fade out**: 0.15s duration with `outCubic` easing
- **Fade in**: 0.2s duration with `outCubic` easing
- Animation completion triggers grid rebuild

---

## Integration Points

### Interface Fields

```xml
<interface>
    <field id="m3uUrl" type="string" onChange="onM3uUrlChanged"/>
    <field id="videoPlayRequested" type="assocarray"/>
</interface>
```

### Input: `m3uUrl`

Set this field to trigger M3U playlist loading:

```brightscript
m3uScreen = m.top.findNode("m3uChannelScreen")
m3uScreen.m3uUrl = "http://provider.com/playlist.m3u"
```

### Output: `videoPlayRequested`

Observed by parent (`home_scene`) to trigger video playback:

```brightscript
videoData = {
    contentUrl: "http://stream.url/video.m3u8",
    title: "CNN HD",
    description: "Ch 101",
    thumbnail: "http://logo.url/cnn.png",
    isLive: true
}
m.top.videoPlayRequested = videoData
```

### M3U Playlist Detection (Nested M3U)

If a selected channel's URL is itself an M3U playlist, the screen loads it instead of playing:

```brightscript
if Instr(1, streamUrlLower, "type=m3u") > 0 or 
   Instr(1, streamUrlLower, ".m3u") > 0 or 
   Instr(1, streamUrlLower, "get.php") > 0 then
    ' Load as nested playlist
    m.top.m3uUrl = streamUrl
end if
```

---

## Component API

### M3UChannelScreen

| Field | Type | Direction | Description |
|-------|------|-----------|-------------|
| `m3uUrl` | string | Input | M3U playlist URL to load |
| `videoPlayRequested` | assocarray | Output | Video data for playback |

### M3UChannelItem

| Field | Type | Description |
|-------|------|-------------|
| `itemContent` | node | ContentNode with channel data |
| `focusPercent` | float | Focus animation progress (0.0-1.0) |
| `width` | float | Component width (default: 340) |
| `height` | float | Component height (default: 240) |

### ContentNode Properties (Channel)

| Property | Type | Description |
|----------|------|-------------|
| `title` | string | Channel name |
| `description` | string | Channel number or subtitle |
| `hdPosterUrl` | string | Channel logo URL |
| `streamUrl` | string | Video stream URL (custom field) |
| `category` | string | Channel category (custom field) |

---

## Error Handling

### Loading Errors

| Error | Display | Recovery |
|-------|---------|----------|
| Network timeout | "Error: Connection timeout" | Retry via BACK + re-navigate |
| HTTP error | "Error: HTTP [code]" | Check URL validity |
| Empty response | "Error: Empty M3U response" | Verify playlist exists |
| Parse failure | "Error: No channels found" | Check M3U format |

### Preview Player Errors

- Shows "Stream Error" in preview overlay
- Error flag prevents buffering message from overriding error
- User can still select channel for full-screen attempt

---

## Debug Logging

The screen includes extensive debug logging prefixed with:
```
M3UChannelScreen.brs - [functionName]
```

Key log points:
- M3U URL analysis
- Parsing progress (every 50 channels)
- First 10 channels detailed structure
- Category extraction results
- Preview player position calculations
- Navigation events

---

## Future Enhancement Considerations

1. **EPG Integration**: Display program guide data if available in M3U
2. **Favorites**: Allow marking favorite channels
3. **Recently Watched**: Track viewing history
4. **Channel Sorting**: Sort by name, number, or category
5. **Multi-playlist Support**: Combine multiple M3U sources
6. **Parental Controls**: Filter age-restricted content

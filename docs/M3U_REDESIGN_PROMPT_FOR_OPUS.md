# M3U Channel Screen — Redesign Implementation Guide for Opus
> Roku/BrightScript specific. Based on the approved design screenshot + existing M3U_CHANNELS_SCREEN_DOCUMENTATION.md.

---

## Context

You are rewriting the visual layer of `M3UChannelScreen.xml` and `M3UChannelItem.xml/.brs`.  
**All business logic in `M3UChannelScreen.brs` and `M3ULoaderApi.brs` stays untouched** unless a layout change requires a field rename or position value update.  
The goal is to match the approved design screenshot exactly — a modern, dark, TV-optimized layout with teal/cyan accents, a hero header, category sidebar, card grid, and bottom navigation bar.

Reference files:
- `components/screens/M3UChannelScreen.xml` — replace layout completely
- `components/screens/M3UChannelItem.xml` — replace layout completely
- `components/screens/M3UChannelItem.brs` — update position/size values only
- `components/screens/M3UChannelScreen.brs` — update only the numeric constants that reference layout (item sizes, spacings, grid offset, preview player size)

---

## Screen Dimensions

Roku 1080p canvas: **1920 × 1080px**

---

## Color Palette

| Token | Hex | Usage |
|---|---|---|
| `bg-primary` | `#0a0e14` | Main screen background |
| `bg-header` | `#0f1419` | Header bar background |
| `bg-card` | `#1a1f2e` | Stats card, category sidebar |
| `bg-item` | `#131720` | Channel item card background |
| `bg-item-focused` | `#1e2640` | Channel item focused state |
| `accent-cyan` | `#00bcd4` | Focus borders, accent bars, "gia.tv" logo tint |
| `accent-purple` | `#6366f1` | Dot separator in header |
| `live-red` | `#e53935` | LIVE badge background |
| `text-primary` | `#ffffff` | Main text |
| `text-secondary` | `#9ca3af` | Subtitles, category labels, hints |
| `text-muted` | `#4b5563` | Divider lines, disabled text |
| `divider` | `#1e2a3a` | Horizontal/vertical divider lines |

---

## Section 1 — Header Bar

**Position:** `[0, 0]`  
**Size:** `1920 × 130px`  
**Background:** `#0f1419`

The header is divided into three zones separated by internal spacing:

### Zone 1 — Screen Identity (Left)
Position: `[40, 0]`, height `130`

```xml
<!-- Screen title -->
<Label
    id="screenTabName"
    text="M3U Channels"
    translation="[40, 28]"
    color="#ffffff"
    width="420"
    height="44">
    <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="38"/>
</Label>

<!-- Subtitle: loading progress -->
<Label
    id="channelCountLabel"
    text="Loading..."
    translation="[40, 76]"
    color="#9ca3af"
    width="420"
    height="28">
    <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="22"/>
</Label>
```

### Zone 2 — Stats Card (Center)
Position: centered. Use `translation="[680, 18]"`. Card size: `340 × 94px`.

```xml
<Rectangle
    id="statsCardBg"
    translation="[680, 18]"
    width="340"
    height="94"
    color="#1a1f2e"/>

<Label
    id="statsChannelCount"
    text="0 Channels"
    translation="[700, 28]"
    color="#ffffff"
    width="300"
    horizAlign="center"
    height="36">
    <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="28"/>
</Label>

<Label
    id="selectedIndexLabel"
    text="Item 1 of 0 selected"
    translation="[700, 68]"
    color="#9ca3af"
    width="300"
    horizAlign="center"
    height="26">
    <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="20"/>
</Label>
```

> **Note for BRS:** Update `updateChannelCounter()` to set `statsChannelCount.text` with the channel count string (e.g., "11946 Channels"), and keep `selectedIndexLabel` for item position.

### Zone 3 — Clock + Logo (Right)
Position: right-aligned near `x=1620`.

```xml
<Label
    id="screenTimeLabel"
    text="00:00"
    translation="[1620, 22]"
    color="#ffffff"
    width="160"
    horizAlign="right"
    height="48">
    <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="40"/>
</Label>

<Label
    id="localTimeHint"
    text="Local Time"
    translation="[1620, 74]"
    color="#9ca3af"
    width="160"
    horizAlign="right"
    height="26">
    <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="20"/>
</Label>

<!-- GiaTV logo - right edge -->
<Poster
    id="screenBrandIcon"
    uri="pkg:/images/img/gia-tv-small.png"
    translation="[1800, 10]"
    width="100"
    height="100"
    loadDisplayMode="scaleToFit"/>
```

### Header Divider
Full-width 2px line at `y=130`:

```xml
<Rectangle
    id="headerDivider"
    translation="[0, 130]"
    width="1920"
    height="2"
    color="#1e2a3a"/>
```

---

## Section 2 — Search / Options Hint Bar

**Position:** `[0, 132]`  
**Height:** `52px`  
**Background:** transparent (no background rectangle needed)

A left-aligned label with a small vertical teal accent bar on its left edge.

```xml
<Group id="optionsHintGroup" translation="[40, 142]">
    <!-- Vertical accent bar -->
    <Rectangle
        id="optionsAccentBar"
        translation="[0, 2]"
        width="4"
        height="28"
        color="#00bcd4"/>

    <!-- Hint text -->
    <Label
        id="searchPromptLabel"
        text="Press OPTIONS to Search"
        translation="[14, 0]"
        color="#9ca3af"
        width="500"
        height="32"
        visible="false">
        <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="24"/>
    </Label>
</Group>
```

When in **search mode**, replace the hint with the search status group (same Y position):

```xml
<Group id="searchStatusGroup" translation="[40, 138]" visible="false">
    <Rectangle width="4" height="32" color="#00bcd4" translation="[0, 2]"/>
    <Label
        id="searchStatusLabel"
        text="Search:"
        translation="[14, 0]"
        color="#ffffff"
        width="110"
        height="36">
        <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="26"/>
    </Label>
    <Label
        id="searchQueryText"
        text=""
        translation="[130, 0]"
        color="#00bcd4"
        width="600"
        height="36">
        <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="26"/>
    </Label>
    <Label
        id="searchClearHint"
        text="OPTIONS: new search  •  BACK: clear"
        translation="[14, 38]"
        color="#4b5563"
        width="700"
        height="26">
        <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="20"/>
    </Label>
</Group>
```

---

## Section 3 — Content Area

**Starts at:** `y=200`  
**Available height:** `1080 - 200 - 50 (bottom bar) = 830px`

The content area has two sub-zones side-by-side:

| Zone | X | Width | Purpose |
|---|---|---|---|
| Category Sidebar | 0 | 220px | LabelList of categories |
| Channel Grid | 240 | 1640px | 4-column MarkupGrid |

---

## Section 3a — Category Sidebar

**Position:** `[0, 200]`  
**Width:** `220px`  
**Height:** `830px`  
**Background:** `#111827`

```xml
<Group id="categoryListContainer" translation="[0, 200]" visible="true">
    <!-- Sidebar background -->
    <Rectangle
        id="sidebarBg"
        width="220"
        height="830"
        color="#111827"/>

    <!-- "Categories" header label with accent bar -->
    <Rectangle
        id="sidebarAccentBar"
        translation="[0, 10]"
        width="4"
        height="28"
        color="#00bcd4"/>
    <Label
        id="sidebarHeaderLabel"
        text="Categories"
        translation="[14, 8]"
        color="#ffffff"
        width="200"
        height="34">
        <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="26"/>
    </Label>

    <!-- Category list starts below header -->
    <LabelList
        id="categoryLabelList"
        translation="[0, 52]"
        itemSize="[220, 38]"
        numRows="18"
        focusRow="0"
        drawFocusFeedback="true"
        focusBitmapUri="pkg:/images/png/shapes/category_focus.9.png"
        focusFootprintBitmapUri="pkg:/images/png/shapes/category_focus.9.png"
        color="#ffffff"
        focusedColor="#ffffff"
        vertFocusAnimationStyle="fixedFocus"
        itemSpacing="[0, 2]"
        wrap="false"
        visible="true"/>

    <!-- Bottom navigation hint -->
    <Label
        id="sidebarNavHint"
        text="↑↓ Browse  •  → Channels"
        translation="[10, 800]"
        color="#4b5563"
        width="200"
        height="26">
        <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="18"/>
    </Label>
</Group>
```

**Category focus image:** Create or use a 9-patch PNG that renders a white filled rectangle for focused items (the "All (11946)" selected state in the design shows white background + dark text when focused). In the BRS, the focused item text color should be `#131720` (dark) when focused so it reads on the white background.

> **BRS note:** In `extractAndBuildCategories()`, the LabelList `focusedColor` will need to be `#131720` to show dark text on the white focus rectangle. Keep `color="#ffffff"` for non-focused items.

---

## Section 3b — Channel Grid Container

**Position:** `[240, 200]` (when sidebar visible)  
**Position:** `[0, 200]` (when no categories, full width)  
**Width:** `1640px` (with sidebar) / `1880px` (without sidebar)

```xml
<Group id="channelGridContainer" translation="[240, 200]">

    <!-- Main channel grid -->
    <MarkupGrid
        id="channelGrid"
        translation="[0, 0]"
        visible="false"
        itemComponentName="M3UChannelItem"
        vertFocusAnimationStyle="floatingFocus"
        itemSize="[370, 268]"
        numColumns="4"
        numRows="3"
        itemSpacing="[18, 18]"
        drawFocusFeedback="false"/>

    <!-- Search results grid (same position, shown during search) -->
    <MarkupGrid
        id="searchResultsGrid"
        translation="[0, 0]"
        visible="false"
        itemComponentName="M3UChannelItem"
        vertFocusAnimationStyle="floatingFocus"
        itemSize="[370, 268]"
        numColumns="4"
        numRows="3"
        itemSpacing="[18, 18]"
        drawFocusFeedback="false"/>

    <!-- Preview player overlay (positioned dynamically over focused item) -->
    <Group id="previewPlayerContainer" translation="[0, 0]" visible="false">
        <Rectangle
            id="previewBackground"
            width="370"
            height="210"
            color="#000000"/>
        <Video
            id="previewPlayer"
            translation="[0, 0]"
            width="370"
            height="210"
            visible="true"
            loop="false"
            enableUI="false"/>
        <!-- Teal focus border around preview -->
        <Rectangle
            id="previewFocusBorder"
            translation="[-3, -3]"
            width="376"
            height="216"
            color="#00bcd4"
            opacity="0.0"/>
        <Group id="previewStatusGroup" translation="[0, 0]" visible="false">
            <Rectangle
                width="370"
                height="210"
                color="#000000"
                opacity="0.85"/>
            <Label
                id="previewStatusLabel"
                text="Loading Stream..."
                translation="[0, 88]"
                color="#ffffff"
                width="370"
                height="40"
                horizAlign="center"
                wrap="true">
                <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="22"/>
            </Label>
        </Group>
        <!-- LIVE badge -->
        <Rectangle
            id="liveIndicatorBg"
            translation="[10, 10]"
            width="76"
            height="30"
            color="#e53935"/>
        <Label
            id="liveIndicatorText"
            text="● LIVE"
            translation="[10, 10]"
            color="#ffffff"
            width="76"
            height="30"
            horizAlign="center"
            vertAlign="center">
            <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="18"/>
        </Label>
    </Group>

</Group>
```

> **BRS note — update these constants in `M3UChannelScreen.brs`:**
> ```brightscript
> ' In updatePreviewPlayer():
> itemWidth = 370
> itemHeight = 268
> posterHeight = 210   ' preview covers poster area only
> spacingX = 18
> spacingY = 18
> ```
> Grid container offset with categories: `[240, 0]`  
> Grid container offset without categories: `[0, 0]`  
> numColumns with categories: `4`  
> numColumns without categories: `5` (itemSize stays `[370, 268]`)

---

## Section 4 — Loading State Card

**Position:** centered on screen — `[760, 460]`  
Shown while M3U is loading. Replaces the old plain label.

```xml
<Group id="loadingGroup" translation="[660, 430]" visible="true">
    <Rectangle
        id="loadingCardBg"
        width="600"
        height="120"
        color="#1a1f2e"/>
    <Label
        id="loadingLabel"
        text="Loading M3U playlist..."
        translation="[0, 40]"
        color="#ffffff"
        width="600"
        height="40"
        horizAlign="center">
        <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="26"/>
    </Label>
</Group>
```

---

## Section 5 — Bottom Navigation Bar

**Position:** `[0, 1040]`  
**Height:** `40px`

```xml
<Rectangle
    id="bottomBarDivider"
    translation="[0, 1038]"
    width="1920"
    height="2"
    color="#1e2a3a"/>

<Label
    id="bottomNavHints"
    text="OK: Play Full Screen  •  ← Categories  •  OPTIONS: Search"
    translation="[0, 1046]"
    color="#4b5563"
    width="1920"
    height="30"
    horizAlign="center">
    <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="20"/>
</Label>
```

---

## Section 6 — Animations (keep existing, just update targets)

```xml
<Animation id="gridFadeOut" duration="0.15" repeat="false" easeFunction="outCubic">
    <FloatFieldInterpolator key="[1.0, 0.0]" fieldToInterp="channelGridContainer.opacity"/>
</Animation>
<Animation id="gridFadeIn" duration="0.2" repeat="false" easeFunction="outCubic">
    <FloatFieldInterpolator key="[0.0, 1.0]" fieldToInterp="channelGridContainer.opacity"/>
</Animation>
```

---

## Section 7 — Clock Timer (keep unchanged)

```xml
<Timer id="clockTimer" repeat="true" duration="60"/>
```

---

## Section 8 — M3UChannelItem Redesign

### `M3UChannelItem.xml`

Item total size: **370 × 268px**  
Poster area: **370 × 210px**  
Title section: **370 × 58px** (below poster)

```xml
<?xml version="1.0" encoding="utf-8" ?>
<component name="M3UChannelItem" extends="Group">
    <interface>
        <field id="itemContent" type="node" onChange="onContentChanged"/>
        <field id="focusPercent" type="float" onChange="onFocusPercentChanged"/>
        <field id="width" type="float" value="370"/>
        <field id="height" type="float" value="268"/>
    </interface>

    <script type="text/brightscript" uri="pkg:/components/screens/M3UChannelItem.brs"/>

    <children>
        <!-- Card background -->
        <Rectangle
            id="background"
            width="370"
            height="268"
            color="#131720"/>

        <!-- Poster area -->
        <Poster
            id="channelPoster"
            translation="[0, 0]"
            width="370"
            height="210"
            loadDisplayMode="scaleToFit"
            loadingBitmapUri="pkg:/images/png/poster_not_found_350x245.png"
            failedBitmapUri="pkg:/images/png/poster_not_found_350x245.png"/>

        <!-- Focus border — teal outline, shown when focused -->
        <Rectangle
            id="focusBorder"
            translation="[-3, -3]"
            width="376"
            height="274"
            color="#00bcd4"
            opacity="0.0"/>

        <!-- Bottom title section background -->
        <Rectangle
            id="titleBg"
            translation="[0, 210]"
            width="370"
            height="58"
            color="#0f1623"/>

        <!-- Left accent bar on title section (shown when focused) -->
        <Rectangle
            id="titleAccentBar"
            translation="[0, 210]"
            width="3"
            height="58"
            color="#00bcd4"
            opacity="0.0"/>

        <!-- Channel name -->
        <Label
            id="bottomTitle"
            translation="[10, 214]"
            text="Channel Name"
            color="#ffffff"
            width="350"
            height="30"
            truncateOnDelimiter="..."
            wrap="false">
            <Font role="font" uri="pkg:/images/UrbanistBold.ttf" size="22"/>
        </Label>

        <!-- Category label -->
        <Label
            id="categoryLabel"
            translation="[10, 244]"
            text=""
            color="#9ca3af"
            width="350"
            height="22">
            <Font role="font" uri="pkg:/images/UrbanistMedium.ttf" size="18"/>
        </Label>

        <!-- Focus indicator overlay (subtle tint) -->
        <Rectangle
            id="focusIndicator"
            translation="[0, 0]"
            width="370"
            height="210"
            color="#00bcd4"
            opacity="0.0"/>
    </children>
</component>
```

### `M3UChannelItem.brs` — updated logic

```brightscript
sub init()
    m.background = m.top.findNode("background")
    m.channelPoster = m.top.findNode("channelPoster")
    m.bottomTitle = m.top.findNode("bottomTitle")
    m.categoryLabel = m.top.findNode("categoryLabel")
    m.focusIndicator = m.top.findNode("focusIndicator")
    m.focusBorder = m.top.findNode("focusBorder")
    m.titleAccentBar = m.top.findNode("titleAccentBar")
    m.titleBg = m.top.findNode("titleBg")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then return

    ' Title
    channelTitle = "Unknown Channel"
    if content.title <> invalid and content.title <> ""
        channelTitle = content.title
    end if
    if m.bottomTitle <> invalid then m.bottomTitle.text = channelTitle

    ' Category subtitle
    if m.categoryLabel <> invalid
        if content.category <> invalid and content.category <> ""
            m.categoryLabel.text = content.category
        else
            m.categoryLabel.text = ""
        end if
    end if

    ' Poster
    posterUrl = ""
    if content.HDPosterUrl <> invalid and content.HDPosterUrl <> "" then posterUrl = content.HDPosterUrl
    if posterUrl = "" and content.hdPosterUrl <> invalid and content.hdPosterUrl <> "" then posterUrl = content.hdPosterUrl
    if posterUrl = "" and content.logo <> invalid and content.logo <> "" then posterUrl = content.logo

    if m.channelPoster <> invalid
        if posterUrl <> ""
            m.channelPoster.uri = posterUrl
        else
            m.channelPoster.uri = "pkg:/images/png/poster_not_found_350x245.png"
        end if
    end if
end sub

sub onFocusPercentChanged()
    focusPercent = m.top.focusPercent

    if focusPercent > 0.5
        ' Focused state
        if m.focusBorder <> invalid then m.focusBorder.opacity = 1.0
        if m.focusIndicator <> invalid then m.focusIndicator.opacity = 0.08
        if m.titleAccentBar <> invalid then m.titleAccentBar.opacity = 1.0
        if m.titleBg <> invalid then m.titleBg.color = "#1e2640"
        if m.bottomTitle <> invalid then m.bottomTitle.color = "#ffffff"
        if m.categoryLabel <> invalid then m.categoryLabel.color = "#00bcd4"
    else
        ' Unfocused state
        if m.focusBorder <> invalid then m.focusBorder.opacity = 0.0
        if m.focusIndicator <> invalid then m.focusIndicator.opacity = 0.0
        if m.titleAccentBar <> invalid then m.titleAccentBar.opacity = 0.0
        if m.titleBg <> invalid then m.titleBg.color = "#0f1623"
        if m.bottomTitle <> invalid then m.bottomTitle.color = "#cccccc"
        if m.categoryLabel <> invalid then m.categoryLabel.color = "#9ca3af"
    end if
end sub
```

---

## Section 9 — BRS Updates Required in `M3UChannelScreen.brs`

Only these numeric/positional values need updating. Do NOT change any logic, API calls, parsing, or event handling.

### 1. `updatePreviewPlayer()` — item dimension constants
```brightscript
' CHANGE FROM:
itemWidth = 360
itemHeight = 250
spacingX = 20
spacingY = 20
' CHANGE TO:
itemWidth = 370
itemHeight = 268
spacingX = 18
spacingY = 18
```

The preview player covers the **poster area only** (210px tall), not the full item height. Position calculation remains the same — `posY` targets the top of the item (the poster), not the title.

### 2. `extractAndBuildCategories()` — grid container offset
```brightscript
' With categories:
m.channelGridContainer.translation = [240, 0]   ' was [330, 0]

' Without categories:
m.channelGridContainer.translation = [0, 0]      ' unchanged
```

### 3. `updateChannelCounter()` — add statsChannelCount update
```brightscript
' Find the statsChannelCount label and update it alongside channelCountLabel
statsLabel = m.top.findNode("statsChannelCount")
if statsLabel <> invalid
    if m.isSearchMode
        statsLabel.text = m.filteredChannels.Count().ToStr() + " Results"
    else
        statsLabel.text = m.totalChannels.ToStr() + " Channels"
    end if
end if
```

### 4. `init()` — add new node references
```brightscript
' Add these alongside existing findNode calls:
m.statsChannelCount = m.top.findNode("statsChannelCount")
m.optionsHintGroup = m.top.findNode("optionsHintGroup")
m.bottomNavHints = m.top.findNode("bottomNavHints")
```

---

## Section 10 — Full XML Structure Order

The final `M3UChannelScreen.xml` `<children>` block must follow this order:

1. `backgroundRect` — full screen dark bg
2. `headerBarBg` — header rectangle `[0,0]` 1920×130
3. Header zone 1 (left) — `screenTabName`, `channelCountLabel`
4. `statsCardBg` + `statsChannelCount` + `selectedIndexLabel` (center)
5. Clock zone (right) — `screenTimeLabel`, `localTimeHint`, `screenBrandIcon`
6. `headerDivider` — 2px line at y=130
7. `optionsHintGroup` — search prompt with accent bar
8. `searchStatusGroup` — search mode status (hidden by default)
9. `categoryListContainer` — sidebar (contains `sidebarBg`, `categoryLabelList`, hint)
10. `channelGridContainer` — grid + preview player overlay
11. `loadingGroup` — centered loading card
12. `bottomBarDivider` + `bottomNavHints`
13. Grid fade animations (`gridFadeOut`, `gridFadeIn`)
14. `clockTimer`

---

## Section 11 — Roku-Specific Constraints to Respect

1. **No CSS, no flexbox.** Every position is an absolute `translation="[x, y]"`. Calculate all positions as integers.

2. **`drawFocusFeedback="false"` on MarkupGrid.** The focus border is handled manually inside `M3UChannelItem` via `focusPercent` + `focusBorder` rectangle. Never rely on the default Roku blue highlight.

3. **Single Video node.** The `previewPlayer` Video node is the only video on this screen. It must be stopped (`control = "stop"`, `content = invalid`) before `videoPlayRequested` fires. This is already handled in `onChannelSelected()` — do not remove it.

4. **LabelList focus bitmap.** The "All (11946)" selected state (white background, dark text) is achieved via `focusBitmapUri`. Use a 9-patch PNG that fills the item area with `#ffffff`. The `focusedColor` on the LabelList should be set to `#131720` so text is readable on white.

5. **`floatingFocus` visual row math.** The preview player position calculation in `updatePreviewPlayer()` compensates for Roku's asymmetric `floatingFocus` scroll behavior (different when scrolling down vs. up). Do not simplify this logic — it is correct and was hard-won.

6. **No `<Group>` opacity on the grid container during category transitions.** The fade animation uses `channelGridContainer.opacity`. This works because `FloatFieldInterpolator` targets the Group's opacity field. Do not wrap the grid in an additional Group or this animation will break.

7. **`itemSize` must match between XML and BRS.** The `MarkupGrid itemSize="[370, 268]"` must match the `itemWidth`/`itemHeight` constants in `updatePreviewPlayer()` exactly, or the preview overlay will be misaligned.

8. **Font files must exist.** Only use `UrbanistBold.ttf` and `UrbanistMedium.ttf` — these are already in `pkg:/images/`. Do not reference any other font file.

9. **`visible="false"` default on grids.** Both `channelGrid` and `searchResultsGrid` start hidden. `buildChannelGrid()` sets `channelGrid.visible = true` after content is loaded.

10. **`M3UChannelItem` must not use `<Poster>` loadingBitmap URIs that don't exist.** Verify `pkg:/images/png/poster_not_found_350x245.png` exists before referencing it. If not, use `pkg:/images/png/gia-tv-logo.png` as fallback.

---

## Checklist Before Submitting

- [ ] Header shows: title + loading subtitle + centered stats card + clock + logo
- [ ] Cyan accent bars appear on: options hint, sidebar header, focused item title
- [ ] Category sidebar: "Categories" header, scrollable LabelList, bottom nav hint
- [ ] Focused channel item: teal border visible, title section highlights, category turns cyan
- [ ] LIVE badge: red, top-left corner of preview overlay, "● LIVE" white text
- [ ] Preview player: covers poster area (370×210), correctly positioned over focused item
- [ ] Bottom bar: divider line + hint text centered
- [ ] Loading state: card centered, readable text
- [ ] Search mode: sidebar hidden, search status group visible, grid goes full width
- [ ] No Roku default blue focus ring visible anywhere on screen

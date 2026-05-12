sub init()
    print "M3UChannelScreen.brs - [init] *** INIT START ***"
    
    m.top.focusable = true
    m.channelGrid = m.top.findNode("channelGrid")
    m.searchResultsGrid = m.top.findNode("searchResultsGrid")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.channelCountLabel = m.top.findNode("channelCountLabel")
    m.selectedIndexLabel = m.top.findNode("selectedIndexLabel")
    m.searchPromptLabel = m.top.findNode("searchPromptLabel")
    m.searchStatusBar = m.top.findNode("searchStatusBar")
    m.searchStatusGroup = m.top.findNode("searchStatusGroup")
    m.searchQueryText = m.top.findNode("searchQueryText")
    m.searchClearHint = m.top.findNode("searchClearHint")
    
    ' Category filter UI
    m.categoryListContainer = m.top.findNode("categoryListContainer")
    m.categoryLabelList = m.top.findNode("categoryLabelList")
    m.selectedCategory = "all"  ' Default to "All"
    m.categories = []
    m.categoryCounts = {}  ' Store channel count per category
    
    ' Animations
    m.channelGridContainer = m.top.findNode("channelGridContainer")
    m.gridFadeOut = m.top.findNode("gridFadeOut")
    m.gridFadeIn = m.top.findNode("gridFadeIn")
    m.pendingCategoryChange = false
    
    ' Preview Player
    m.previewPlayerContainer = m.top.findNode("previewPlayerContainer")
    m.previewPlayer = m.top.findNode("previewPlayer")
    m.previewStatusGroup = m.top.findNode("previewStatusGroup")
    m.previewStatusLabel = m.top.findNode("previewStatusLabel")
    m.previewChannelName = m.top.findNode("previewChannelName")
    m.currentPreviewUrl = ""
    m.previewHasError = false
    m.lastFocusedRow = -1 ' Track previous row for scroll direction detection
    m.lastFocusedIndex = 0 ' Track last focused item for restoration after video playback
    
    ' New UI Elements
    m.statsChannelCount = m.top.findNode("statsChannelCount")
    m.optionsHintGroup = m.top.findNode("optionsHintGroup")
    m.bottomNavHints = m.top.findNode("bottomNavHints")
    m.sourceUrlLabel = m.top.findNode("sourceUrlLabel")
    
    print "M3UChannelScreen.brs - [init] categoryLabelList: " + Type(m.categoryLabelList)
    print "M3UChannelScreen.brs - [init] gridFadeOut: " + Type(m.gridFadeOut)
    print "M3UChannelScreen.brs - [init] gridFadeIn: " + Type(m.gridFadeIn)
    print "M3UChannelScreen.brs - [init] previewPlayer: " + Type(m.previewPlayer)
    
    ' Observe animation completion
    if m.gridFadeOut <> invalid
        m.gridFadeOut.observeField("state", "onFadeOutComplete")
    end if
    
    ' Observe preview player state
    if m.previewPlayer <> invalid
        m.previewPlayer.observeField("state", "onPreviewPlayerState")
    end if
    
    ' Search state
    m.isSearchMode = false
    m.searchQuery = ""
    m.filteredChannels = []
    m.activeGrid = m.channelGrid
    m.searchKeyboard = invalid
    
    ' Header elements
    m.screenHeaderGroup = m.top.findNode("screenHeaderGroup")
    m.screenTabName = m.top.findNode("screenTabName")
    m.screenTimeLabel = m.top.findNode("screenTimeLabel")
    m.clockTimer = m.top.findNode("clockTimer")
    
    ' Pagination variables
    m.channelsPerPage = 100
    m.currentPage = 0
    m.totalChannels = 0
    m.loadedChannels = 0
    
    ' Observe visibility changes to manage focus
    m.top.observeField("visible", "onVisibilityChanged")
    
    ' Observe channel selection and focus for auto-pagination
    if m.channelGrid <> invalid
        m.channelGrid.observeField("itemSelected", "onChannelSelected")
        m.channelGrid.observeField("itemFocused", "onChannelFocused")
    end if
    
    ' Observe search results grid
    if m.searchResultsGrid <> invalid
        m.searchResultsGrid.observeField("itemSelected", "onSearchResultSelected")
        m.searchResultsGrid.observeField("itemFocused", "onSearchResultFocused")
    end if
    
    ' Observe category selection
    if m.categoryLabelList <> invalid
        m.categoryLabelList.observeField("itemSelected", "onCategorySelected")
    end if
    
    ' Observe clock timer
    if m.clockTimer <> invalid
        m.clockTimer.observeField("fire", "updateClockDisplay")
    end if
    
    ' Initialize clock
    updateClockDisplay()
    
    ' Start clock timer
    if m.clockTimer <> invalid
        m.clockTimer.control = "start"
    end if
    
    print "M3UChannelScreen.brs - [init] *** INIT COMPLETE ***"
end sub

sub onVisibilityChanged()
    print "M3UChannelScreen.brs - [onVisibilityChanged] Visibility changed to: " + m.top.visible.ToStr()
    
    if m.top.visible = true
        print "M3UChannelScreen.brs - [onVisibilityChanged] Screen became visible, restoring focus"
        
        ' Restore focus to the active grid (not category list)
        ' This ensures we return to the same item after video playback
        if m.activeGrid <> invalid and m.activeGrid.content <> invalid and m.activeGrid.content.getChildCount() > 0
            print "M3UChannelScreen.brs - [onVisibilityChanged] Restoring focus to active grid"
            m.activeGrid.setFocus(true)
            
            ' Restore the previously focused item
            if m.lastFocusedIndex >= 0 and m.lastFocusedIndex < m.activeGrid.content.getChildCount()
                print "M3UChannelScreen.brs - [onVisibilityChanged] Jumping to previously focused item: " + m.lastFocusedIndex.ToStr()
                m.activeGrid.jumpToItem = m.lastFocusedIndex
            end if
        ' Fallback: If category list is visible, focus on it
        else if m.categoryLabelList <> invalid and m.categoryLabelList.visible = true and m.categoryLabelList.content <> invalid
            print "M3UChannelScreen.brs - [onVisibilityChanged] Category list visible, setting focus on category list"
            m.categoryLabelList.setFocus(true)
        ' Otherwise, if main grid has content, focus on it
        else if m.channelGrid <> invalid and m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
            print "M3UChannelScreen.brs - [onVisibilityChanged] Grid has content, setting focus on grid"
            m.channelGrid.setFocus(true)
        else
            print "M3UChannelScreen.brs - [onVisibilityChanged] Nothing loaded, setting focus on screen"
            m.top.setFocus(true)
        end if
        
        ' Restart clock timer
        if m.clockTimer <> invalid
            m.clockTimer.control = "start"
        end if
    else
        ' Stop clock timer when hidden
        if m.clockTimer <> invalid
            m.clockTimer.control = "stop"
        end if
        
        ' Stop preview player when screen is hidden
        stopPreviewPlayer()
        if m.previewPlayerContainer <> invalid
            m.previewPlayerContainer.visible = false
        end if
        m.currentPreviewUrl = ""
    end if
end sub

sub onM3uUrlChanged()
    print "M3UChannelScreen.brs - [onM3uUrlChanged] M3U URL changed: " + m.top.m3uUrl
    print "M3UChannelScreen.brs - [onM3uUrlChanged] Screen visible: " + m.top.visible.ToStr()
    
    if m.top.m3uUrl <> "" and m.top.m3uUrl <> invalid
        ' Update source URL display
        if m.sourceUrlLabel <> invalid
            m.sourceUrlLabel.text = m.top.m3uUrl
        end if
        loadM3UPlaylist()
    end if
end sub

sub loadM3UPlaylist()
    print "M3UChannelScreen.brs - [loadM3UPlaylist] =========================================="
    print "M3UChannelScreen.brs - [loadM3UPlaylist] INITIATING M3U PLAYLIST LOAD"
    print "M3UChannelScreen.brs - [loadM3UPlaylist] =========================================="
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Full URL: " + m.top.m3uUrl
    print "M3UChannelScreen.brs - [loadM3UPlaylist] URL Length: " + Len(m.top.m3uUrl).ToStr()
    
    ' Quick URL analysis
    urlLower = LCase(m.top.m3uUrl)
    print "M3UChannelScreen.brs - [loadM3UPlaylist] URL Type Analysis:"
    if Instr(1, urlLower, "get.php") > 0
        print "M3UChannelScreen.brs - [loadM3UPlaylist]   - IPTV Provider API (get.php)"
    else if Instr(1, urlLower, ".m3u") > 0
        print "M3UChannelScreen.brs - [loadM3UPlaylist]   - Direct M3U file"
    else
        print "M3UChannelScreen.brs - [loadM3UPlaylist]   - Unknown/Custom URL format"
    end if
    
    if Instr(1, urlLower, "username=") > 0 or Instr(1, urlLower, "password=") > 0
        print "M3UChannelScreen.brs - [loadM3UPlaylist]   - Contains authentication parameters"
    end if
    print "M3UChannelScreen.brs - [loadM3UPlaylist] =========================================="

    ' Reset loading label text (in case it was showing an error message before)
    loadingLabel = m.top.findNode("loadingLabel")
    if loadingLabel <> invalid
        loadingLabel.text = "Loading M3U playlist..."
    end if

    ' Show loading indicator, hide grid
    if m.loadingGroup <> invalid
        m.loadingGroup.visible = true
        print "M3UChannelScreen.brs - [loadM3UPlaylist] Loading indicator shown"
    end if

    if m.channelGrid <> invalid
        m.channelGrid.visible = false
        print "M3UChannelScreen.brs - [loadM3UPlaylist] Channel grid hidden"
    end if

    ' Create M3U Loader Task
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Creating M3ULoaderApi Task..."
    m.m3uLoader = CreateObject("roSGNode", "M3ULoaderApi")

    if m.m3uLoader = invalid
        print "M3UChannelScreen.brs - [loadM3UPlaylist] =========================================="
        print "M3UChannelScreen.brs - [loadM3UPlaylist] ERROR: Failed to create M3ULoaderApi Task!"
        print "M3UChannelScreen.brs - [loadM3UPlaylist] =========================================="
        return
    end if

    print "M3UChannelScreen.brs - [loadM3UPlaylist] Task created successfully"
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Setting up field observers..."
    m.m3uLoader.observeField("responseData", "onM3ULoaded")
    m.m3uLoader.observeField("errorMessage", "onM3UError")
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Observers configured"

    print "M3UChannelScreen.brs - [loadM3UPlaylist] Passing URL to Task: " + m.top.m3uUrl
    m.m3uLoader.m3uUrl = m.top.m3uUrl

    print "M3UChannelScreen.brs - [loadM3UPlaylist] Starting Task with control = 'RUN'..."
    m.m3uLoader.control = "RUN"

    print "M3UChannelScreen.brs - [loadM3UPlaylist] =========================================="
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Task started - waiting for response callback"
    print "M3UChannelScreen.brs - [loadM3UPlaylist] =========================================="
end sub

sub onM3ULoaded()
    print "M3UChannelScreen.brs - [onM3ULoaded] =========================================="
    print "M3UChannelScreen.brs - [onM3ULoaded] M3U data loaded successfully from API Task"
    print "M3UChannelScreen.brs - [onM3ULoaded] =========================================="
    
    responseData = m.m3uLoader.responseData
    if responseData <> invalid and responseData <> ""
        print "M3UChannelScreen.brs - [onM3ULoaded] Response type: " + Type(responseData)
        print "M3UChannelScreen.brs - [onM3ULoaded] Response length: " + Len(responseData).ToStr() + " bytes"
        print "M3UChannelScreen.brs - [onM3ULoaded] First 200 chars: " + Left(responseData, 200)
        print "M3UChannelScreen.brs - [onM3ULoaded] =========================================="
        print "M3UChannelScreen.brs - [onM3ULoaded] Calling parseM3UContent..."
        parseM3UContent(responseData)
    else
        print "M3UChannelScreen.brs - [onM3ULoaded] =========================================="
        print "M3UChannelScreen.brs - [onM3ULoaded] ERROR: Empty or invalid response"
        if responseData = invalid then print "M3UChannelScreen.brs - [onM3ULoaded] Response is INVALID"
        if responseData = "" then print "M3UChannelScreen.brs - [onM3ULoaded] Response is EMPTY STRING"
        print "M3UChannelScreen.brs - [onM3ULoaded] =========================================="
        showError("Empty M3U response")
    end if
end sub

sub onM3UError()
    print "M3UChannelScreen.brs - [onM3UError] =========================================="
    print "M3UChannelScreen.brs - [onM3UError] M3U loading FAILED"
    print "M3UChannelScreen.brs - [onM3UError] =========================================="
    
    errorMsg = m.m3uLoader.errorMessage
    if errorMsg <> invalid and errorMsg <> ""
        print "M3UChannelScreen.brs - [onM3UError] Error message: " + errorMsg
        showError(errorMsg)
    else
        print "M3UChannelScreen.brs - [onM3UError] No specific error message available"
        showError("Failed to load M3U playlist")
    end if
    print "M3UChannelScreen.brs - [onM3UError] =========================================="
end sub

sub checkM3UResponse_OLD()
    ' Only check if we're visible and have a port
    if m.port = invalid or not m.top.visible
        if m.responseTimer <> invalid
            m.responseTimer.control = "stop"
        end if
        return
    end if
    
    msg = m.port.GetMessage()
    
    if msg <> invalid
        if type(msg) = "roUrlEvent"
            responseCode = msg.GetResponseCode()
            print "M3UChannelScreen.brs - [checkM3UResponse] Response code: " + responseCode.ToStr()
            
            ' Stop timer
            if m.responseTimer <> invalid
                m.responseTimer.control = "stop"
                m.responseTimer = invalid
            end if
            
            if responseCode = 200
                responseString = msg.GetString()
                print "M3UChannelScreen.brs - [checkM3UResponse] Response received, length: " + Len(responseString).ToStr()
                
                ' Parse the M3U content
                parseM3UContent(responseString)
            else if responseCode = 301 or responseCode = 302
                ' Handle redirect
                print "M3UChannelScreen.brs - [checkM3UResponse] Redirect detected, following..."
                newUrl = msg.GetResponseHeaders()["location"]
                if newUrl <> invalid
                    m.top.m3uUrl = newUrl
                    loadM3UPlaylist()
                else
                    showError("Redirect failed - no location header")
                end if
            else
                print "M3UChannelScreen.brs - [checkM3UResponse] ERROR: HTTP " + responseCode.ToStr()
                showError("HTTP Error: " + responseCode.ToStr())
            end if
            
            ' Clean up
            m.urlTransfer = invalid
            m.port = invalid
        end if
    end if
end sub

sub parseM3UContent(content as String)
    print "M3UChannelScreen.brs - [parseM3UContent] =========================================="
    print "M3UChannelScreen.brs - [parseM3UContent] Starting to parse M3U content"
    print "M3UChannelScreen.brs - [parseM3UContent] =========================================="
    print "M3UChannelScreen.brs - [parseM3UContent] Content length: " + content.Len().ToStr() + " bytes"

    m.channels = []
    lines = content.Split(Chr(10)) ' Split by newline
    
    print "M3UChannelScreen.brs - [parseM3UContent] Total lines to parse: " + lines.Count().ToStr()
    print "M3UChannelScreen.brs - [parseM3UContent] =========================================="
    
    ' Show first 10 lines for debugging
    print "M3UChannelScreen.brs - [parseM3UContent] First 10 lines of content:"
    maxPreview = 10
    if lines.Count() < maxPreview then maxPreview = lines.Count()
    for i = 0 to maxPreview - 1
        print "M3UChannelScreen.brs - [parseM3UContent]   Line " + i.ToStr() + ": " + lines[i]
    end for
    print "M3UChannelScreen.brs - [parseM3UContent] =========================================="

    currentChannel = invalid
    channelCount = 0
    skippedLines = 0
    extinfLines = 0
    urlLines = 0

    for i = 0 to lines.Count() - 1
        line = lines[i].Trim()

        ' Skip empty lines and comments (except EXTINF)
        if line = "" or (line.Left(1) = "#" and line.Left(7) <> "#EXTINF")
            skippedLines = skippedLines + 1
            continue for
        end if

        ' Parse EXTINF line
        if line.Left(7) = "#EXTINF"
            extinfLines = extinfLines + 1
            currentChannel = {}
            
            ' Log first 5 EXTINF lines for debugging
            if extinfLines <= 5
                print "M3UChannelScreen.brs - [parseM3UContent] =========================================="
                print "M3UChannelScreen.brs - [parseM3UContent] Parsing EXTINF #" + extinfLines.ToStr()
                print "M3UChannelScreen.brs - [parseM3UContent] Raw line: " + line
            end if

            ' Extract channel info from EXTINF line
            ' Format: #EXTINF:-1 channel-id="..." tvg-id="..." tvg-chno="..." tvg-name="..." tvg-logo="..." group-title="...",Channel Name

            ' Extract tvg-name (channel name)
            nameStart = line.Instr("tvg-name=" + Chr(34))
            if nameStart > -1
                nameStart = nameStart + 10 ' Skip 'tvg-name="'
                nameEnd = line.Instr(nameStart, Chr(34))
                if nameEnd > -1
                    currentChannel.name = line.Mid(nameStart, nameEnd - nameStart)
                    if extinfLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   Extracted tvg-name: " + currentChannel.name
                end if
            end if

            ' Extract tvg-logo (channel logo)
            logoStart = line.Instr("tvg-logo=" + Chr(34))
            if logoStart > -1
                logoStart = logoStart + 10 ' Skip 'tvg-logo="'
                logoEnd = line.Instr(logoStart, Chr(34))
                if logoEnd > -1
                    currentChannel.logo = line.Mid(logoStart, logoEnd - logoStart)
                    if extinfLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   Extracted tvg-logo: " + currentChannel.logo
                end if
            end if

            ' Extract tvg-chno (channel number)
            chnoStart = line.Instr("tvg-chno=" + Chr(34))
            if chnoStart > -1
                chnoStart = chnoStart + 10 ' Skip 'tvg-chno="'
                chnoEnd = line.Instr(chnoStart, Chr(34))
                if chnoEnd > -1
                    currentChannel.channelNumber = line.Mid(chnoStart, chnoEnd - chnoStart)
                    if extinfLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   Extracted tvg-chno: " + currentChannel.channelNumber
                end if
            end if

            ' Extract group-title (category)
            groupStart = line.Instr("group-title=" + Chr(34))
            if groupStart > -1
                groupStart = groupStart + 13 ' Skip 'group-title="'
                groupEnd = line.Instr(groupStart, Chr(34))
                if groupEnd > -1
                    currentChannel.category = line.Mid(groupStart, groupEnd - groupStart)
                    if extinfLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   Extracted group-title: " + currentChannel.category
                end if
            end if

            ' If tvg-name wasn't found, try to get name from the end of the line
            if currentChannel.name = invalid or currentChannel.name = ""
                commaPos = line.InStr(",")
                if commaPos > -1 and commaPos < Len(line) - 1
                    currentChannel.name = line.Mid(commaPos + 1).Trim()
                    if extinfLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   Extracted name from comma: " + currentChannel.name
                end if
            end if

        ' Parse URL line (stream URL)
        else if currentChannel <> invalid and line.Left(4) = "http"
            urlLines = urlLines + 1
            currentChannel.url = line
            
            if urlLines <= 5
                print "M3UChannelScreen.brs - [parseM3UContent]   Extracted URL: " + Left(line, 100)
            end if

            ' Extract category from channel name prefix (e.g., "AFG: Channel Name" -> category="AFG")
            if currentChannel.name <> invalid and currentChannel.name <> ""
                colonPos = Instr(1, currentChannel.name, ":")
                if urlLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   Channel name: '" + currentChannel.name + "', colon position: " + colonPos.ToStr()
                
                if colonPos > 1 and colonPos <= 10 ' Prefix should be short (1-10 chars before colon)
                    prefixCategory = Left(currentChannel.name, colonPos - 1).Trim()
                    ' Only set category from prefix if not already set from group-title
                    if prefixCategory <> "" and (currentChannel.category = invalid or currentChannel.category = "")
                        currentChannel.category = prefixCategory
                        if urlLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   ✓ Extracted category from prefix: '" + prefixCategory + "'"
                    else
                        if urlLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   Category already set or prefix empty. Existing: " + Type(currentChannel.category)
                    end if
                else
                    if urlLines <= 5 and colonPos > 0 then print "M3UChannelScreen.brs - [parseM3UContent]   Colon found but position invalid for prefix extraction"
                end if
            end if
            
            ' Add channel to list
            if currentChannel.name <> invalid and currentChannel.name <> ""
                m.channels.Push(currentChannel)
                channelCount = channelCount + 1

                ' Log every 50 channels
                if channelCount mod 50 = 0
                    print "M3UChannelScreen.brs - [parseM3UContent] Progress: Parsed " + channelCount.ToStr() + " channels so far..."
                end if
            else
                if urlLines <= 5 then print "M3UChannelScreen.brs - [parseM3UContent]   WARNING: Channel skipped - no name found"
            end if

            currentChannel = invalid
        else if currentChannel <> invalid
            ' URL line but doesn't start with http
            if urlLines <= 5
                print "M3UChannelScreen.brs - [parseM3UContent]   WARNING: Expected URL but got: " + Left(line, 100)
            end if
        end if
    end for

    print "M3UChannelScreen.brs - [parseM3UContent] =========================================="
    print "M3UChannelScreen.brs - [parseM3UContent] Parsing Statistics:"
    print "M3UChannelScreen.brs - [parseM3UContent]   Total lines processed: " + lines.Count().ToStr()
    print "M3UChannelScreen.brs - [parseM3UContent]   Skipped lines: " + skippedLines.ToStr()
    print "M3UChannelScreen.brs - [parseM3UContent]   EXTINF lines found: " + extinfLines.ToStr()
    print "M3UChannelScreen.brs - [parseM3UContent]   URL lines found: " + urlLines.ToStr()
    print "M3UChannelScreen.brs - [parseM3UContent]   Channels successfully parsed: " + m.channels.Count().ToStr()
    print "M3UChannelScreen.brs - [parseM3UContent] =========================================="

    ' Print first 10 channels for debugging with detailed structure
    if m.channels.Count() > 0
        print "M3UChannelScreen.brs - [parseM3UContent] ========== FIRST 10 CHANNELS DETAILED =========="
        maxPrint = 10
        if m.channels.Count() < maxPrint then maxPrint = m.channels.Count()

        for i = 0 to maxPrint - 1
            ch = m.channels[i]
            print "M3UChannelScreen.brs - [parseM3UContent] ========== Channel " + i.ToStr() + " =========="
            print "  name: " + ch.name
            print "  name type: " + Type(ch.name)
            
            if ch.channelNumber <> invalid
                print "  channelNumber: " + ch.channelNumber
                print "  channelNumber type: " + Type(ch.channelNumber)
            else
                print "  channelNumber: INVALID/MISSING"
            end if
            
            if ch.category <> invalid
                print "  category: " + ch.category
                print "  category type: " + Type(ch.category)
            else
                print "  category: INVALID/MISSING"
            end if
            
            if ch.logo <> invalid
                print "  logo: " + ch.logo
                print "  logo type: " + Type(ch.logo)
                print "  logo length: " + Len(ch.logo).ToStr()
            else
                print "  logo: INVALID/MISSING"
            end if
            
            if ch.url <> invalid
                print "  url: " + Left(ch.url, 80)
                print "  url type: " + Type(ch.url)
            else
                print "  url: INVALID/MISSING"
            end if
            
            ' Print all keys in the channel object
            print "  All keys in channel object: " + FormatJson(ch.Keys())
        end for
        print "M3UChannelScreen.brs - [parseM3UContent] =========================================="

        ' Extract unique categories from channels
        extractAndBuildCategories()
        
        buildChannelGrid()
    else
        showError("No channels found in playlist")
    end if
end sub

sub extractAndBuildCategories()
    print "M3UChannelScreen.brs - [extractAndBuildCategories] =========================================="
    print "M3UChannelScreen.brs - [extractAndBuildCategories] Extracting categories from " + m.channels.Count().ToStr() + " channels..."
    
    ' Collect unique categories and count channels per category
    categoryMap = {}
    m.categoryCounts = {}
    channelsWithCategory = 0
    
    for each channel in m.channels
        if channel.category <> invalid and channel.category <> ""
            if not categoryMap.DoesExist(channel.category)
                print "M3UChannelScreen.brs - [extractAndBuildCategories] Found new category: " + channel.category
                categoryMap[channel.category] = true
                m.categoryCounts[channel.category] = 0
            end if
            m.categoryCounts[channel.category] = m.categoryCounts[channel.category] + 1
            channelsWithCategory = channelsWithCategory + 1
        end if
    end for
    
    print "M3UChannelScreen.brs - [extractAndBuildCategories] Channels with category: " + channelsWithCategory.ToStr() + " / " + m.channels.Count().ToStr()
    
    ' Convert to sorted array
    m.categories = []
    for each category in categoryMap
        m.categories.Push(category)
    end for
    
    ' Sort categories alphabetically (simple bubble sort)
    if m.categories.Count() > 1
        for i = 0 to m.categories.Count() - 2
            for j = 0 to m.categories.Count() - 2 - i
                if m.categories[j] > m.categories[j + 1]
                    temp = m.categories[j]
                    m.categories[j] = m.categories[j + 1]
                    m.categories[j + 1] = temp
                end if
            end for
        end for
    end if
    
    print "M3UChannelScreen.brs - [extractAndBuildCategories] Found " + m.categories.Count().ToStr() + " unique categories"
    if m.categories.Count() > 0
        print "M3UChannelScreen.brs - [extractAndBuildCategories] First 10 categories: " + FormatJson(m.categories)
    end if
    
    ' Build category LabelList (add "All" as first item)
    if m.categoryLabelList = invalid
        print "M3UChannelScreen.brs - [extractAndBuildCategories] ERROR: categoryLabelList is invalid!"
        return
    end if
    
    if m.categories.Count() > 0
        print "M3UChannelScreen.brs - [extractAndBuildCategories] Building category content..."
        categoryContent = CreateObject("roSGNode", "ContentNode")
        
        ' Add "All" category first with total count
        allItem = categoryContent.CreateChild("ContentNode")
        allText = "All (" + m.channels.Count().ToStr() + ")"
        ' Add padding spaces for better visual centering (LabelList doesn't support center alignment)
        allItem.title = "    " + allText
        allItem.id = "all"
        print "M3UChannelScreen.brs - [extractAndBuildCategories] Added 'All' category with count: " + m.channels.Count().ToStr()
        
        ' Add each category with channel count
        categoryCount = 0
        for each category in m.categories
            catItem = categoryContent.CreateChild("ContentNode")
            channelCount = m.categoryCounts[category]
            categoryText = category + " (" + channelCount.ToStr() + ")"
            ' Add padding spaces for better visual centering
            catItem.title = "    " + categoryText
            catItem.id = category
            categoryCount = categoryCount + 1
            if categoryCount <= 5
                print "M3UChannelScreen.brs - [extractAndBuildCategories] Added category: " + category + " with " + channelCount.ToStr() + " channels"
            end if
        end for
        
        print "M3UChannelScreen.brs - [extractAndBuildCategories] Total category items created: " + (categoryCount + 1).ToStr()
        
        m.categoryLabelList.content = categoryContent
        m.categoryLabelList.visible = true
        m.selectedCategory = "all"  ' Default to showing all channels
        
        ' Show category container
        if m.categoryListContainer <> invalid
            m.categoryListContainer.visible = true
        end if
        
        ' Set initial selection to "All"
        m.categoryLabelList.jumpToItem = 0
        
        ' Set grid to 4 columns with category sidebar
        if m.channelGrid <> invalid
            m.channelGrid.numColumns = 4
            print "M3UChannelScreen.brs - [extractAndBuildCategories] Grid set to 4 columns (with categories)"
        end if
        if m.searchResultsGrid <> invalid
            m.searchResultsGrid.numColumns = 4
        end if
        
        ' Position grid to the right of category sidebar
        if m.channelGridContainer <> invalid
            m.channelGridContainer.translation = [360, 200]
            print "M3UChannelScreen.brs - [extractAndBuildCategories] Grid positioned with category sidebar offset"
        end if
        
        print "M3UChannelScreen.brs - [extractAndBuildCategories] Category filter UI populated and visible"
        print "M3UChannelScreen.brs - [extractAndBuildCategories] LabelList content child count: " + m.categoryLabelList.content.getChildCount().ToStr()
        print "M3UChannelScreen.brs - [extractAndBuildCategories] LabelList visible: " + m.categoryLabelList.visible.ToStr()
    else
        print "M3UChannelScreen.brs - [extractAndBuildCategories] No categories found - hiding category list"
        m.categoryLabelList.content = CreateObject("roSGNode", "ContentNode")
        m.categoryLabelList.visible = false
        
        ' Hide category container
        if m.categoryListContainer <> invalid
            m.categoryListContainer.visible = false
        end if
        
        ' Set grid to 5 columns without category sidebar (full width)
        if m.channelGrid <> invalid
            m.channelGrid.numColumns = 5
            print "M3UChannelScreen.brs - [extractAndBuildCategories] Grid set to 5 columns (no categories)"
        end if
        if m.searchResultsGrid <> invalid
            m.searchResultsGrid.numColumns = 5
        end if
        
        ' Position grid to the left (no category sidebar)
        if m.channelGridContainer <> invalid
            m.channelGridContainer.translation = [40, 200]
            print "M3UChannelScreen.brs - [extractAndBuildCategories] Grid positioned at full width (no categories)"
        end if
    end if
    print "M3UChannelScreen.brs - [extractAndBuildCategories] =========================================="
end sub

sub buildChannelGrid()
    print "M3UChannelScreen.brs - [buildChannelGrid] Building channel grid..."
    print "M3UChannelScreen.brs - [buildChannelGrid] Selected category: " + m.selectedCategory
    
    ' Filter channels by category
    m.displayChannels = []
    if m.selectedCategory = "all"
        ' Show all channels
        m.displayChannels = m.channels
        print "M3UChannelScreen.brs - [buildChannelGrid] Showing all " + m.channels.Count().ToStr() + " channels"
    else
        ' Filter by selected category
        for each channel in m.channels
            if channel.category <> invalid and channel.category = m.selectedCategory
                m.displayChannels.Push(channel)
            end if
        end for
        print "M3UChannelScreen.brs - [buildChannelGrid] Filtered to " + m.displayChannels.Count().ToStr() + " channels in category: " + m.selectedCategory
    end if
    
    m.totalChannels = m.displayChannels.Count()
    m.currentPage = 0
    m.loadedChannels = 0
    
    ' Create content node for MarkupGrid (flat list, no rows)
    if m.channelGrid.content = invalid
        contentNode = CreateObject("roSGNode", "ContentNode")
        m.channelGrid.content = contentNode
    end if
    
    ' Load first page
    loadChannelPage()
    
    ' Hide loading indicator
    if m.loadingGroup <> invalid
        m.loadingGroup.visible = false
    end if
    
    ' Show grid
    m.channelGrid.visible = true
    
    ' Set focus on category list first (if visible), otherwise on grid
    if m.categoryLabelList <> invalid and m.categoryLabelList.visible = true
        m.categoryLabelList.setFocus(true)
        print "M3UChannelScreen.brs - [buildChannelGrid] Set focus on category list"
    else
        m.channelGrid.setFocus(true)
        print "M3UChannelScreen.brs - [buildChannelGrid] Set focus on channel grid"
    end if
    
    ' Show and update channel counter and selected index
    updateChannelCounter()
    updateSelectedIndex()
    
    ' Show options hint group (search prompt)
    if m.optionsHintGroup <> invalid
        m.optionsHintGroup.visible = true
    end if
    
    ' Bottom navigation hints are always visible (no need to toggle)
    
    ' Show category container if categories exist
    if m.categoryListContainer <> invalid and m.categoryLabelList <> invalid
        if m.categoryLabelList.content <> invalid and m.categoryLabelList.content.getChildCount() > 0
            m.categoryListContainer.visible = true
        end if
    end if
    
    print "M3UChannelScreen.brs - [buildChannelGrid] Initial grid built with " + m.loadedChannels.ToStr() + " channels"
end sub

sub loadChannelPage()
    print "M3UChannelScreen.brs - [loadChannelPage] Loading page " + m.currentPage.ToStr()
    
    contentNode = m.channelGrid.content
    if contentNode = invalid then return
    
    startIndex = m.currentPage * m.channelsPerPage
    endIndex = startIndex + m.channelsPerPage - 1
    if endIndex >= m.totalChannels then endIndex = m.totalChannels - 1
    
    print "M3UChannelScreen.brs - [loadChannelPage] Loading channels " + startIndex.ToStr() + " to " + endIndex.ToStr()
    
    channelCount = 0
    channelsWithLogo = 0
    channelsWithoutLogo = 0
    
    for i = startIndex to endIndex
        if i >= m.displayChannels.Count() then exit for
        
        channel = m.displayChannels[i]
        if channel = invalid then continue for
        
        itemNode = contentNode.createChild("ContentNode")
        if itemNode = invalid then continue for
        
        ' Set title with fallback
        channelTitle = "Channel " + (i + 1).ToStr()
        if channel.name <> invalid and channel.name <> ""
            channelTitle = channel.name
        end if
        itemNode.title = channelTitle
        
        ' Set description
        if channel.channelNumber <> invalid and channel.channelNumber <> ""
            itemNode.description = "Ch " + channel.channelNumber
        else
            itemNode.description = ""
        end if
        
        ' Set logo/poster with detailed logging for first 5 items
        hasLogo = false
        if channel.logo <> invalid and channel.logo <> ""
            itemNode.hdPosterUrl = channel.logo
            hasLogo = true
            channelsWithLogo = channelsWithLogo + 1
            
            ' Detailed logging for first 5 items
            if channelCount < 5
                print "M3UChannelScreen.brs - [loadChannelPage] Channel " + i.ToStr() + " LOGO ASSIGNED:"
                print "    Title: " + channelTitle
                print "    Logo URL: " + channel.logo
                print "    Logo Length: " + Len(channel.logo).ToStr()
            end if
        else
            ' Use placeholder image for channels without logo
            itemNode.hdPosterUrl = "pkg:/images/png/poster_not_found_350x245.png"
            channelsWithoutLogo = channelsWithoutLogo + 1
            
            ' Log missing logo for first 5 items
            if channelCount < 5
                print "M3UChannelScreen.brs - [loadChannelPage] Channel " + i.ToStr() + " NO LOGO (using placeholder):"
                print "    Title: " + channelTitle
                print "    Logo field: " + Type(channel.logo)
            end if
        end if
        
        ' Set category
        if channel.category <> invalid and channel.category <> ""
            itemNode.addFields({ category: channel.category })
        end if
        
        ' Store stream URL
        if channel.url <> invalid and channel.url <> ""
            itemNode.addFields({ streamUrl: channel.url })
        end if
        
        channelCount = channelCount + 1
        m.loadedChannels = m.loadedChannels + 1
    end for
    
    print "M3UChannelScreen.brs - [loadChannelPage] Logo statistics for this page:"
    print "    Channels WITH logo: " + channelsWithLogo.ToStr()
    print "    Channels WITHOUT logo: " + channelsWithoutLogo.ToStr()
    print "    Percentage with logo: " + (channelsWithLogo * 100 / channelCount).ToStr() + "%"
    
    m.currentPage = m.currentPage + 1
    
    ' Update channel counter
    updateChannelCounter()
    
    print "M3UChannelScreen.brs - [loadChannelPage] Loaded " + channelCount.ToStr() + " channels. Total loaded: " + m.loadedChannels.ToStr()
end sub

sub updateChannelCounter()
    if m.channelCountLabel = invalid then return
    
    counterText = ""
    statsText = ""
    
    if m.isSearchMode
        ' Show search results count
        if m.searchQuery <> ""
            totalMatches = m.filteredChannels.Count()
            displayedCount = 0
            if m.activeGrid <> invalid and m.activeGrid.content <> invalid
                displayedCount = m.activeGrid.content.getChildCount()
            end if
            
            if displayedCount < totalMatches
                counterText = "Showing " + displayedCount.ToStr() + " of " + totalMatches.ToStr() + " results"
                statsText = displayedCount.ToStr() + " Results"
            else
                counterText = totalMatches.ToStr() + " results for '" + m.searchQuery + "'"
                statsText = totalMatches.ToStr() + " Results"
            end if
        else
            counterText = m.loadedChannels.ToStr() + " Channels"
            statsText = m.loadedChannels.ToStr() + " Channels"
        end if
    else if m.totalChannels > 0
        ' Show normal channel count
        if m.loadedChannels < m.totalChannels
            counterText = "Loading... " + m.loadedChannels.ToStr() + " of " + m.totalChannels.ToStr()
        else
            counterText = "All " + m.loadedChannels.ToStr() + " channels loaded"
        end if
        statsText = m.totalChannels.ToStr() + " Channels"
    else
        counterText = "Loading..."
        statsText = "0 Channels"
    end if
    
    m.channelCountLabel.text = counterText
    
    ' Update stats card label
    if m.statsChannelCount <> invalid
        m.statsChannelCount.text = statsText
    end if
end sub

sub updateSelectedIndex()
    if m.selectedIndexLabel = invalid then return
    
    activeGrid = m.activeGrid
    if activeGrid = invalid then return
    
    focusedIndex = activeGrid.itemFocused
    totalItems = 0
    
    if m.isSearchMode
        totalItems = m.filteredChannels.Count()
    else
        totalItems = m.loadedChannels
    end if
    
    if focusedIndex >= 0 and totalItems > 0
        ' Display 1-based index (user-friendly)
        indexText = "Item " + (focusedIndex + 1).ToStr() + " of " + totalItems.ToStr() + " selected"
        m.selectedIndexLabel.text = indexText
        m.selectedIndexLabel.visible = true
    else
        m.selectedIndexLabel.visible = false
    end if
end sub

sub showSearchKeyboard()
    print "M3UChannelScreen.brs - [showSearchKeyboard] Showing search keyboard"

    ' Create keyboard dialog programmatically (like in account_screen)
    m.searchKeyboard = CreateObject("roSGNode", "KeyboardDialog")
    m.searchKeyboard.title = "Search Channels"
    m.searchKeyboard.text = ""
    m.searchKeyboard.buttons = ["Search", "Cancel"]
    m.searchKeyboard.observeField("buttonSelected", "onSearchKeyboardButton")
    m.searchKeyboard.observeField("wasClosed", "onSearchKeyboardClosed")
    
    ' Show the dialog
    m.top.GetScene().dialog = m.searchKeyboard
end sub

sub onSearchKeyboardButton()
    if m.searchKeyboard = invalid then return
    
    buttonIndex = m.searchKeyboard.buttonSelected
    print "M3UChannelScreen.brs - [onSearchKeyboardButton] Button selected: " + buttonIndex.ToStr()
    
    if buttonIndex = 0
        ' Search button
        searchText = m.searchKeyboard.text
        if searchText <> invalid and searchText <> ""
            m.searchQuery = searchText.Trim()
            print "M3UChannelScreen.brs - [onSearchKeyboardButton] Search query: '" + m.searchQuery + "'"
            
            if m.searchQuery <> ""
                m.searchKeyboard.close = true
                enterSearchMode()
                performSearch()
            else
                m.searchKeyboard.keyboard.textEditBox.hintText = "Please enter search text"
            end if
        else
            m.searchKeyboard.keyboard.textEditBox.hintText = "Please enter search text"
        end if
    else if buttonIndex = 1
        ' Cancel button
        print "M3UChannelScreen.brs - [onSearchKeyboardButton] Search cancelled"
        m.searchKeyboard.close = true
        
        ' Return focus to active grid
        if m.activeGrid <> invalid
            m.activeGrid.setFocus(true)
        end if
    end if
end sub

sub onSearchKeyboardClosed()
    print "M3UChannelScreen.brs - [onSearchKeyboardClosed] Keyboard dialog closed"
    
    ' Return focus to active grid (search results grid if in search mode)
    if m.isSearchMode and m.searchResultsGrid <> invalid and m.searchResultsGrid.visible = true
        print "M3UChannelScreen.brs - [onSearchKeyboardClosed] Setting focus on search results grid"
        m.searchResultsGrid.setFocus(true)
    else if m.activeGrid <> invalid
        print "M3UChannelScreen.brs - [onSearchKeyboardClosed] Setting focus on active grid"
        m.activeGrid.setFocus(true)
    end if
end sub

sub onSearchKeyboardText()
    ' This fires as user types - we can show live preview if needed
    if m.searchKeyboard <> invalid
        currentText = m.searchKeyboard.text
        if currentText <> invalid
            print "M3UChannelScreen.brs - [onSearchKeyboardText] Current text: '" + currentText + "'"
        end if
    end if
end sub

sub enterSearchMode()
    print "M3UChannelScreen.brs - [enterSearchMode] Entering search mode"
    
    m.isSearchMode = true
    m.activeGrid = m.searchResultsGrid
    
    ' Hide category list container when in search mode
    if m.categoryListContainer <> invalid
        m.categoryListContainer.visible = false
        print "M3UChannelScreen.brs - [enterSearchMode] Category list container hidden"
    end if
    if m.categoryLabelList <> invalid
        m.categoryLabelList.visible = false
    end if
    
    ' Hide options hint group, show search status bar
    if m.optionsHintGroup <> invalid
        m.optionsHintGroup.visible = false
    end if
    if m.searchStatusBar <> invalid
        m.searchStatusBar.visible = true
    end if
    
    ' Move grid to full width when no categories (search mode)
    if m.channelGridContainer <> invalid
        m.channelGridContainer.translation = [40, 200]
    end if
    
    ' Update search display
    updateSearchDisplay()
end sub

sub exitSearchMode()
    print "M3UChannelScreen.brs - [exitSearchMode] Exiting search mode"
    
    m.isSearchMode = false
    m.searchQuery = ""
    m.filteredChannels = []
    
    ' Show category list container again if categories exist
    if m.categoryLabelList <> invalid and m.categoryLabelList.content <> invalid and m.categoryLabelList.content.getChildCount() > 0
        if m.categoryListContainer <> invalid
            m.categoryListContainer.visible = true
        end if
        m.categoryLabelList.visible = true
        print "M3UChannelScreen.brs - [exitSearchMode] Category list restored"
        
        ' Restore grid position with categories
        if m.channelGridContainer <> invalid
            m.channelGridContainer.translation = [280, 200]
        end if
    end if
    
    ' Show options hint group, hide search status bar
    if m.optionsHintGroup <> invalid
        m.optionsHintGroup.visible = true
    end if
    if m.searchStatusBar <> invalid
        m.searchStatusBar.visible = false
    end if
    
    ' Switch back to main grid
    if m.searchResultsGrid <> invalid
        m.searchResultsGrid.visible = false
    end if
    if m.channelGrid <> invalid
        m.channelGrid.visible = true
        m.channelGrid.setFocus(true)
        m.activeGrid = m.channelGrid
    end if
    
    ' Update displays
    updateChannelCounter()
    updateSelectedIndex()
end sub

sub updateSearchDisplay()
    if m.searchQueryText <> invalid and m.searchQuery <> invalid
        m.searchQueryText.text = m.searchQuery
    end if
end sub

sub performSearch()
    print "M3UChannelScreen.brs - [performSearch] =========================================="
    print "M3UChannelScreen.brs - [performSearch] Searching for: '" + m.searchQuery + "'"
    print "M3UChannelScreen.brs - [performSearch] Total channels available: " + m.channels.Count().ToStr()
    print "M3UChannelScreen.brs - [performSearch] Previously loaded channels: " + m.loadedChannels.ToStr()

    if m.searchQuery = ""
        ' Empty search - show all channels (not just loaded ones)
        m.filteredChannels = []
        for i = 0 to m.channels.Count() - 1
            if m.channels[i] <> invalid
                m.filteredChannels.Push(m.channels[i])
            end if
        end for
        print "M3UChannelScreen.brs - [performSearch] Empty query - showing all " + m.filteredChannels.Count().ToStr() + " channels"
    else
        ' Filter channels by search query - search through ALL channels, not just loaded
        m.filteredChannels = []
        searchLower = LCase(m.searchQuery)

        print "M3UChannelScreen.brs - [performSearch] Searching through ALL " + m.channels.Count().ToStr() + " channels"
        
        for i = 0 to m.channels.Count() - 1
            if i >= m.channels.Count() then exit for

            channel = m.channels[i]
            if channel <> invalid
                ' Search in channel name and category
                matchFound = false

                if channel.name <> invalid and channel.name <> ""
                    if LCase(channel.name).Instr(searchLower) >= 0
                        matchFound = true
                    end if
                end if

                if not matchFound and channel.category <> invalid and channel.category <> ""
                    if LCase(channel.category).Instr(searchLower) >= 0
                        matchFound = true
                    end if
                end if

                if matchFound
                    m.filteredChannels.Push(channel)
                end if
            end if
        end for
        
        print "M3UChannelScreen.brs - [performSearch] Found " + m.filteredChannels.Count().ToStr() + " matching channels out of " + m.channels.Count().ToStr() + " total"
    end if

    ' Build search results grid
    buildSearchResults()

    print "M3UChannelScreen.brs - [performSearch] Search complete - displaying " + m.filteredChannels.Count().ToStr() + " results"
    print "M3UChannelScreen.brs - [performSearch] =========================================="
end sub

sub buildSearchResults()
    if m.searchResultsGrid = invalid then return
    
    ' Limit search results to 100 (same as initial channel load)
    maxSearchResults = 100
    totalMatches = m.filteredChannels.Count()
    
    if totalMatches > maxSearchResults
        print "M3UChannelScreen.brs - [buildSearchResults] Limiting results: " + totalMatches.ToStr() + " matches, showing first " + maxSearchResults.ToStr()
    end if
    
    ' Create content node for search results
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    channelCount = 0
    for each channel in m.filteredChannels
        if channel = invalid then continue for
        
        ' Stop after reaching max results
        if channelCount >= maxSearchResults then exit for
        
        itemNode = contentNode.createChild("ContentNode")
        if itemNode = invalid then continue for
        
        ' Set title with fallback
        channelTitle = "Channel " + (channelCount + 1).ToStr()
        if channel.name <> invalid and channel.name <> ""
            channelTitle = channel.name
        end if
        itemNode.title = channelTitle
        
        ' Set description
        if channel.channelNumber <> invalid and channel.channelNumber <> ""
            itemNode.description = "Ch " + channel.channelNumber
        else
            itemNode.description = ""
        end if
        
        ' Set logo/poster
        if channel.logo <> invalid and channel.logo <> ""
            itemNode.hdPosterUrl = channel.logo
        else
            ' Use placeholder image for channels without logo
            itemNode.hdPosterUrl = "pkg:/images/png/poster_not_found_350x245.png"
        end if
        
        ' Set category
        if channel.category <> invalid and channel.category <> ""
            itemNode.addFields({ category: channel.category })
        end if
        
        ' Store stream URL
        if channel.url <> invalid and channel.url <> ""
            itemNode.addFields({ streamUrl: channel.url })
        end if
        
        channelCount = channelCount + 1
    end for
    
    ' Switch to search results grid
    m.searchResultsGrid.content = contentNode
    m.channelGrid.visible = false
    m.searchResultsGrid.visible = true
    m.activeGrid = m.searchResultsGrid
    
    ' Jump to first item and set focus
    if contentNode.getChildCount() > 0
        m.searchResultsGrid.jumpToItem = 0
    end if
    m.searchResultsGrid.setFocus(true)
    
    ' Update displays
    updateChannelCounter()
    updateSelectedIndex()
    
    print "M3UChannelScreen.brs - [buildSearchResults] Built search grid with " + channelCount.ToStr() + " items (out of " + totalMatches.ToStr() + " total matches)"
    print "M3UChannelScreen.brs - [buildSearchResults] Focus set on search results grid"
end sub

sub onSearchResultSelected()
    print "M3UChannelScreen.brs - [onSearchResultSelected] Search result selected"
    
    ' IMPORTANT: Stop preview player before starting full-screen video
    ' Roku doesn't support multiple video instances
    stopPreviewPlayer()
    if m.previewPlayerContainer <> invalid
        m.previewPlayerContainer.visible = false
    end if
    m.currentPreviewUrl = ""
    
    navigateToPlayVideo()
end sub

sub onSearchResultFocused()
    if m.searchResultsGrid = invalid then return
    
    focusedIndex = m.searchResultsGrid.itemFocused
    
    ' Update selected index display
    updateSelectedIndex()
    
    ' Preview player disabled for now
    ' updatePreviewPlayer(focusedIndex)
end sub

sub onChannelFocused()
    if m.channelGrid = invalid then return
    
    focusedIndex = m.channelGrid.itemFocused
    
    ' Update selected index display
    updateSelectedIndex()
    
    ' Preview player disabled for now
    ' updatePreviewPlayer(focusedIndex)
    
    ' Auto-load more channels when user gets close to the end
    ' Load more when focusing on one of the last 10 items
    triggerIndex = m.loadedChannels - 10
    if triggerIndex < 0 then triggerIndex = 0
    
    if focusedIndex >= triggerIndex and m.loadedChannels < m.totalChannels
        print "M3UChannelScreen.brs - [onChannelFocused] Auto-loading more channels (focused index: " + focusedIndex.ToStr() + ", trigger: " + triggerIndex.ToStr() + ")"
        
        ' Show loading indicator briefly
        if m.loadingGroup <> invalid
            loadingLabel = m.loadingGroup.findNode("loadingLabel")
            if loadingLabel <> invalid
                loadingLabel.text = "Loading more channels..."
            end if
            m.loadingGroup.visible = true
        end if
        
        ' Load next page
        loadChannelPage()
        
        ' Hide loading indicator after a short delay
        if m.loadingGroup <> invalid
            m.loadingGroup.visible = false
        end if
    end if
end sub

sub updatePreviewPlayer(focusedIndex as Integer)
    ' Get the focused channel from active grid
    activeGrid = m.activeGrid
    if activeGrid = invalid or activeGrid.content = invalid then return
    
    ' Get number of columns dynamically (4 with categories, 5 without)
    numColumns = 4 ' Default
    if activeGrid.numColumns <> invalid
        numColumns = activeGrid.numColumns
    end if
    
    ' Calculate row and column from focused index
    row = int(focusedIndex / numColumns)
    column = focusedIndex mod numColumns
    
    print "=========================================="
    print "M3UChannelScreen.brs - [updatePreviewPlayer] Focused: index=" + focusedIndex.ToStr() + ", row=" + row.ToStr() + ", column=" + column.ToStr() + ", numColumns=" + numColumns.ToStr()
    
    ' Log all relevant grid properties to understand scroll behavior
    print "M3UChannelScreen.brs - [updatePreviewPlayer] Grid properties:"
    if activeGrid.translation <> invalid
        print "  - translation: [" + activeGrid.translation[0].ToStr() + ", " + activeGrid.translation[1].ToStr() + "]"
    end if
    if activeGrid.itemFocused <> invalid
        print "  - itemFocused: " + activeGrid.itemFocused.ToStr()
    end if
    if activeGrid.boundingRect <> invalid
        bounds = activeGrid.boundingRect()
        if bounds <> invalid
            print "  - boundingRect: x=" + bounds.x.ToStr() + ", y=" + bounds.y.ToStr() + ", w=" + bounds.width.ToStr() + ", h=" + bounds.height.ToStr()
        end if
    end if
    print "=========================================="
    
    focusedItem = activeGrid.content.getChild(focusedIndex)
    if focusedItem = invalid then return
    
    ' Get stream URL
    streamUrl = ""
    if focusedItem.streamUrl <> invalid
        streamUrl = focusedItem.streamUrl
    end if
    
    ' Calculate visual row based on floatingFocus behavior
    ' For numRows=3, floatingFocus keeps the focused item centered at row 1 once scrolling begins
    ' The key is determining WHEN scrolling begins
    ' Let's try different calculation based on total items
    totalItems = activeGrid.content.getChildCount()
    totalRows = int((totalItems + 3) / 4) ' Ceiling division for 4 columns
    
    print "M3UChannelScreen.brs - [updatePreviewPlayer] Total items: " + totalItems.ToStr() + ", Total rows: " + totalRows.ToStr()
    
    ' Detect scroll direction
    scrollDirection = "none"
    if m.lastFocusedRow >= 0
        if row > m.lastFocusedRow
            scrollDirection = "down"
        else if row < m.lastFocusedRow
            scrollDirection = "up"
        end if
    end if
    
    print "M3UChannelScreen.brs - [updatePreviewPlayer] Scroll direction: " + scrollDirection + " (prev row: " + m.lastFocusedRow.ToStr() + ")"
    
    ' Calculate visual row for floatingFocus with numRows=3
    ' floatingFocus behavior is direction-dependent:
    ' 
    ' SCROLLING DOWN:
    ' - Row 0: Visual 0 (top)
    ' - Row 1: Visual 1 (middle)
    ' - Row 2+: Visual 2 (bottom) - focus reaches bottom and stays there as grid scrolls
    '
    ' SCROLLING UP:
    ' - Focus moves UP through visible positions as you navigate
    ' - Grid only scrolls when focus would go off top of screen
    ' - So: row 5→4 means focus moves from visual 2 to visual 1
    '       row 4→3 means focus moves from visual 1 to visual 0
    '       row 3→2 means grid scrolls, focus stays at visual 0 or moves to visual 2
    '
    visualRow = row
    
    if scrollDirection = "down"
        ' Scrolling DOWN: focus reaches bottom and stays there
        if row >= 2
            visualRow = 2
        end if
    else if scrollDirection = "up"
        ' Scrolling UP: focus moves up through visible positions
        ' Based on user feedback:
        ' Row 0: top (visual 0)
        ' Row 1: top (visual 0) - when scrolling up from row 2, shows at top
        ' Row 2+: middle (visual 1) - grid is still scrolled, focus at middle
        if row <= 1
            visualRow = 0 ' Top position for rows 0 and 1 when scrolling up
        else if row >= 2
            visualRow = 1 ' Middle position for rows 2+ when scrolling up
        end if
    else
        ' Initial/unknown direction - use natural positions
        if row > 2
            visualRow = 2 ' Default to bottom for deep rows
        end if
    end if
    
    print "M3UChannelScreen.brs - [updatePreviewPlayer] Row " + row.ToStr() + " → Visual " + visualRow.ToStr() + " (direction: " + scrollDirection + ")"
    
    ' Store current row for next iteration
    m.lastFocusedRow = row
    
    ' Calculate position based on visual row
    ' Grid: itemSize=[370, 268], itemSpacing=[18, 18]
    ' Preview only covers the poster area (210px), not the title section (58px)
    itemWidth = 370
    itemHeight = 268
    posterHeight = 210
    spacingX = 18
    spacingY = 18
    
    posX = column * (itemWidth + spacingX)
    posY = visualRow * (itemHeight + spacingY)
    
    ' Position preview player over focused item
    if m.previewPlayerContainer <> invalid
        m.previewPlayerContainer.translation = [posX, posY]
        print "M3UChannelScreen.brs - [updatePreviewPlayer] CALCULATED POSITION:"
        print "  - Visual row: " + visualRow.ToStr() + " (from actual row " + row.ToStr() + ")"
        print "  - X: " + posX.ToStr() + " (column " + column.ToStr() + " * " + (itemWidth + spacingX).ToStr() + ")"
        print "  - Y: " + posY.ToStr() + " (visual row " + visualRow.ToStr() + " * " + (itemHeight + spacingY).ToStr() + ")"
        print "  >>> PREVIEW AT: [" + posX.ToStr() + ", " + posY.ToStr() + "]"
        print "  >>> PLEASE REPORT: Is preview overlaying the focused item correctly? (yes/no)"
    end if
    
    ' Update preview channel name
    channelTitle = "Unknown Channel"
    if focusedItem.title <> invalid and focusedItem.title <> ""
        channelTitle = focusedItem.title
    end if
    if m.previewChannelName <> invalid
        m.previewChannelName.text = channelTitle
    end if
    
    if streamUrl <> "" and streamUrl <> m.currentPreviewUrl
        print "M3UChannelScreen.brs - [updatePreviewPlayer] Loading preview for: " + channelTitle
        print "M3UChannelScreen.brs - [updatePreviewPlayer] Stream URL: " + streamUrl
        
        ' Clear error flag for new stream
        m.previewHasError = false
        
        ' Show loading status
        if m.previewStatusGroup <> invalid and m.previewStatusLabel <> invalid
            m.previewStatusLabel.text = "Loading Stream..."
            m.previewStatusGroup.visible = true
        end if
        
        ' Load stream into preview player
        loadPreviewStream(streamUrl)
        m.currentPreviewUrl = streamUrl
    end if
    
    ' Show preview container
    if m.previewPlayerContainer <> invalid and m.previewPlayerContainer.visible = false
        m.previewPlayerContainer.visible = true
        print "M3UChannelScreen.brs - [updatePreviewPlayer] Preview player shown"
    end if
end sub

sub loadPreviewStream(streamUrl as String)
    if m.previewPlayer = invalid then return
    
    ' Stop any current playback
    m.previewPlayer.control = "stop"
    
    ' Create content node
    previewContent = CreateObject("roSGNode", "ContentNode")
    previewContent.url = streamUrl
    previewContent.streamFormat = detectStreamFormat(streamUrl)
    previewContent.live = true
    
    ' Video playback properties for preview
    previewContent.IgnoreStreamErrors = true
    previewContent.StreamStickyHttpRedirects = [true]
    previewContent.MinBandwidth = 100000
    previewContent.MaxBandwidth = 2000000  ' Lower bandwidth for preview
    
    ' Set video properties
    m.previewPlayer.content = previewContent
    m.previewPlayer.control = "play"
    
    print "M3UChannelScreen.brs - [loadPreviewStream] Playing stream: " + streamUrl + " (format: " + previewContent.streamFormat + ")"
end sub

sub stopPreviewPlayer()
    if m.previewPlayer <> invalid
        m.previewPlayer.control = "stop"
        m.previewPlayer.content = invalid
    end if
    
    if m.previewStatusGroup <> invalid
        m.previewStatusGroup.visible = false
    end if
    
    ' Clear error flag when stopping
    m.previewHasError = false
end sub

sub onPreviewPlayerState()
    if m.previewPlayer = invalid then return
    
    playerState = m.previewPlayer.state
    print "M3UChannelScreen.brs - [onPreviewPlayerState] Preview player state: " + playerState + ", hasError: " + m.previewHasError.ToStr()
    
    if playerState = "playing"
        ' Successfully playing - clear error flag and hide status
        m.previewHasError = false
        if m.previewStatusGroup <> invalid
            m.previewStatusGroup.visible = false
        end if
    else if playerState = "buffering"
        ' Only show buffering if we haven't already encountered an error
        if not m.previewHasError
            if m.previewStatusGroup <> invalid and m.previewStatusLabel <> invalid
                m.previewStatusLabel.text = "Loading Stream..."
                m.previewStatusGroup.visible = true
            end if
        else
            ' Already had error, don't override the error message
            print "M3UChannelScreen.brs - [onPreviewPlayerState] Ignoring buffering state - stream already errored"
        end if
    else if playerState = "error"
        print "M3UChannelScreen.brs - [onPreviewPlayerState] Preview player ERROR - stream failed"
        ' Set error flag and show error message
        m.previewHasError = true
        if m.previewStatusGroup <> invalid and m.previewStatusLabel <> invalid
            m.previewStatusLabel.text = "Stream Error"
            m.previewStatusGroup.visible = true
        end if
    else if playerState = "finished" or playerState = "stopped"
        ' Hide status when stopped (but don't clear error flag yet)
        if m.previewStatusGroup <> invalid
            m.previewStatusGroup.visible = false
        end if
    end if
end sub

sub onCategorySelected()
    print "M3UChannelScreen.brs - [onCategorySelected] Category selected"
    
    if m.categoryLabelList = invalid or m.categoryLabelList.content = invalid then return
    
    selectedIndex = m.categoryLabelList.itemSelected
    if selectedIndex < 0 then return
    
    selectedItem = m.categoryLabelList.content.getChild(selectedIndex)
    if selectedItem = invalid then return
    
    m.selectedCategory = selectedItem.id
    categoryTitle = selectedItem.title
    print "M3UChannelScreen.brs - [onCategorySelected] Selected category: " + m.selectedCategory + " (" + categoryTitle + ")"
    
    ' Set flag for pending category change
    m.pendingCategoryChange = true
    
    ' Stop preview player when changing category
    stopPreviewPlayer()
    if m.previewPlayerContainer <> invalid
        m.previewPlayerContainer.visible = false
    end if
    m.currentPreviewUrl = ""
    
    ' Fade out animation
    if m.gridFadeOut <> invalid
        m.gridFadeOut.control = "start"
    else
        ' No animation available, rebuild immediately
        rebuildGridForCategory()
    end if
end sub

sub onFadeOutComplete()
    if m.gridFadeOut = invalid then return
    
    ' Check if fade out animation completed
    if m.gridFadeOut.state = "stopped" and m.pendingCategoryChange = true
        print "M3UChannelScreen.brs - [onFadeOutComplete] Fade out complete, rebuilding grid"
        m.pendingCategoryChange = false
        rebuildGridForCategory()
    end if
end sub

sub rebuildGridForCategory()
    print "M3UChannelScreen.brs - [rebuildGridForCategory] Rebuilding grid for category: " + m.selectedCategory
    
    ' Rebuild the channel grid with filtered channels
    ' Clear existing content
    if m.channelGrid.content <> invalid
        m.channelGrid.content.removeChildrenIndex(m.channelGrid.content.getChildCount(), 0)
    end if
    
    ' Rebuild with filtered channels
    buildChannelGrid()
    
    ' Reset focus to first item (index 0)
    if m.channelGrid <> invalid and m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
        m.channelGrid.jumpToItem = 0
        print "M3UChannelScreen.brs - [rebuildGridForCategory] Reset grid focus to item 0"
    end if
    
    ' Update UI
    updateChannelCounter()
    updateSelectedIndex()
    
    ' Fade in animation
    if m.gridFadeIn <> invalid
        m.gridFadeIn.control = "start"
    end if
end sub

sub onChannelSelected()
    print "M3UChannelScreen.brs - [onChannelSelected] Channel selected"
    
    ' IMPORTANT: Stop preview player before starting full-screen video
    ' Roku doesn't support multiple video instances
    stopPreviewPlayer()
    if m.previewPlayerContainer <> invalid
        m.previewPlayerContainer.visible = false
    end if
    m.currentPreviewUrl = ""
    
    navigateToPlayVideo()
end sub

sub navigateToPlayVideo()
    print "M3UChannelScreen.brs - [navigateToPlayVideo] =========================================="
    
    ' Get the selected channel from the active grid
    activeGrid = m.activeGrid
    if activeGrid = invalid
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: No active grid"
        return
    end if

    selectedIndex = activeGrid.itemFocused
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Selected index: " + selectedIndex.ToStr()
    
    ' Store focused index for restoration when returning from video
    m.lastFocusedIndex = selectedIndex
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Stored focus index: " + m.lastFocusedIndex.ToStr()

    if activeGrid.content = invalid
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: No content in active grid"
        return
    end if

    ' Get the channel node
    channelNode = activeGrid.content.getChild(selectedIndex)

    if channelNode = invalid
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: Channel node not found"
        return
    end if

    print "M3UChannelScreen.brs - [navigateToPlayVideo] Playing channel: " + channelNode.title

    ' Get the stream URL from custom field
    streamUrl = ""
    if channelNode.streamUrl <> invalid and channelNode.streamUrl <> ""
        streamUrl = channelNode.streamUrl
    end if

    if streamUrl = ""
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: No stream URL found"
        return
    end if

    ' Check if this URL is an M3U playlist endpoint (should be parsed, not played)
    streamUrlLower = LCase(streamUrl)
    isM3UPlaylist = false
    
    ' Check for common M3U playlist patterns
    if (Instr(1, streamUrlLower, "type=m3u") > 0 or Instr(1, streamUrlLower, ".m3u") > 0 or Instr(1, streamUrlLower, "output=ts") > 0 or Instr(1, streamUrlLower, "get.php") > 0) then
        isM3UPlaylist = true
    end if
    
    if isM3UPlaylist
        print "M3UChannelScreen.brs - [navigateToPlayVideo] =========================================="
        print "M3UChannelScreen.brs - [navigateToPlayVideo] Detected M3U playlist URL!"
        print "M3UChannelScreen.brs - [navigateToPlayVideo] URL: " + streamUrl
        print "M3UChannelScreen.brs - [navigateToPlayVideo] This should load a channel list, not play directly"
        print "M3UChannelScreen.brs - [navigateToPlayVideo] Loading M3U playlist..."
        print "M3UChannelScreen.brs - [navigateToPlayVideo] =========================================="
        
        ' Load this M3U playlist (it will replace current screen content)
        m.top.m3uUrl = streamUrl
        return
    end if

    ' Get description
    channelDescription = ""
    if channelNode.description <> invalid and channelNode.description <> ""
        channelDescription = channelNode.description
    end if

    ' Get thumbnail
    channelThumbnail = ""
    if channelNode.hdPosterUrl <> invalid and channelNode.hdPosterUrl <> ""
        channelThumbnail = channelNode.hdPosterUrl
    end if

    ' Create video data for home scene video player
    videoData = {
        contentUrl: streamUrl,
        title: channelNode.title,
        description: channelDescription,
        thumbnail: channelThumbnail,
        isLive: true
    }

    print "M3UChannelScreen.brs - [navigateToPlayVideo] Sending video play request to home scene"
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Title: " + channelNode.title
    print "M3UChannelScreen.brs - [navigateToPlayVideo] URL: " + streamUrl

    ' Trigger video play request to parent (home scene)
    m.top.videoPlayRequested = videoData
    print "M3UChannelScreen.brs - [navigateToPlayVideo] =========================================="
end sub

sub showError(errorMsg as String)
    print "M3UChannelScreen.brs - [showError] Showing error: " + errorMsg

    ' Hide loading indicator
    if m.loadingGroup <> invalid
        m.loadingGroup.visible = false
    end if

    ' Hide grid
    if m.channelGrid <> invalid
        m.channelGrid.visible = false
    end if

    ' Show error in loading label
    loadingLabel = m.top.findNode("loadingLabel")
    if loadingLabel <> invalid
        loadingLabel.text = "Error: " + errorMsg
        if m.loadingGroup <> invalid
            m.loadingGroup.visible = true
        end if
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    print "M3UChannelScreen.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr()

    if press
        if key = "back"
            ' If in search mode, exit search first
            if m.isSearchMode
                exitSearchMode()
                return true
            end if

            print "M3UChannelScreen.brs - [onKeyEvent] BACK pressed, resetting and hiding M3U screen"

            ' Stop any playing video first
            parentScene = m.top.getScene()
            if parentScene <> invalid
                videoPlayer = parentScene.findNode("videoPlayer")
                if videoPlayer <> invalid and videoPlayer.visible = true
                    print "M3UChannelScreen.brs - [onKeyEvent] Stopping video player"
                    videoPlayer.control = "stop"
                    videoPlayer.visible = false
                end if
            end if

            ' Reset the M3U screen completely
            resetScreen()

            ' Hide this screen
            m.top.visible = false

            ' Return focus to Personal content screen
            if parentScene <> invalid
                ' Find the Personal content screen
                dynamicScreensContainer = parentScene.findNode("dynamicScreensContainer")
                if dynamicScreensContainer <> invalid
                    for i = 0 to dynamicScreensContainer.getChildCount() - 1
                        screen = dynamicScreensContainer.getChild(i)
                        if screen <> invalid and screen.hasField("contentTypeId") and screen.contentTypeId = 16
                            print "M3UChannelScreen.brs - [onKeyEvent] Found Personal screen, making visible and restoring focus"
                            screen.visible = true
                            
                            ' Trigger focus restoration to last selected item
                            if screen.hasField("restoreFocusRequested")
                                screen.restoreFocusRequested = true
                                print "M3UChannelScreen.brs - [onKeyEvent] Triggered restoreFocusRequested on Personal screen"
                            else
                                screen.setFocus(true)
                                print "M3UChannelScreen.brs - [onKeyEvent] Set focus on Personal screen (no restoreFocusRequested field)"
                            end if
                            exit for
                        end if
                    end for
                end if
            end if

            return true
        else if key = "options"
            ' Show search keyboard dialog
            showSearchKeyboard()
            return true
        else if key = "left" or key = "right"
            ' Handle navigation between category list and channel grid
            if m.categoryLabelList <> invalid and m.categoryLabelList.visible = true
                if key = "right"
                    ' If focus is on category list, move to grid
                    if m.categoryLabelList.hasFocus()
                        if m.activeGrid <> invalid and m.activeGrid.visible = true
                            m.activeGrid.setFocus(true)
                            return true
                        end if
                    end if
                else if key = "left"
                    ' If focus is on grid first column and categories are visible, move to category list
                    if m.activeGrid <> invalid and m.activeGrid.hasFocus()
                        ' Only handle left navigation if category list is visible
                        if m.categoryLabelList <> invalid and m.categoryLabelList.visible = true
                            focusedIndex = m.activeGrid.itemFocused
                            ' Get number of columns dynamically
                            numColumns = 4
                            if m.activeGrid.numColumns <> invalid
                                numColumns = m.activeGrid.numColumns
                            end if
                            ' Check if in first column
                            if focusedIndex mod numColumns = 0
                                m.categoryLabelList.setFocus(true)
                                return true
                            end if
                        end if
                    end if
                end if
            end if
        end if
    end if
    
    return false
end function

sub updateClockDisplay()
    ' Get current local time and format as HH:MM
    dateTime = CreateObject("roDateTime")
    dateTime.ToLocalTime()
    
    hours = dateTime.GetHours()
    minutes = dateTime.GetMinutes()
    
    ' Format with leading zeros
    hoursStr = hours.ToStr()
    if hours < 10 then hoursStr = "0" + hoursStr
    
    minutesStr = minutes.ToStr()
    if minutes < 10 then minutesStr = "0" + minutesStr
    
    timeStr = hoursStr + ":" + minutesStr
    
    if m.screenTimeLabel <> invalid
        m.screenTimeLabel.text = timeStr
    end if
end sub

sub resetScreen()
    print "M3UChannelScreen.brs - [resetScreen] =========================================="
    print "M3UChannelScreen.brs - [resetScreen] Resetting M3U Channel Screen"
    
    ' Clear all channel data
    m.allChannels = []
    m.displayedChannels = []
    m.currentPage = 0
    m.totalChannels = 0
    
    ' Clear search state
    m.isSearchMode = false
    m.searchQuery = ""
    m.filteredChannels = []
    
    ' Clear categories
    m.categories = []
    m.categoryCounts = {}
    m.selectedCategory = ""
    if m.categoryLabelList <> invalid
        m.categoryLabelList.content = CreateObject("roSGNode", "ContentNode")
        m.categoryLabelList.visible = false
        print "M3UChannelScreen.brs - [resetScreen] Category list cleared and hidden"
    end if
    
    ' Clear grid content
    if m.channelGrid <> invalid
        m.channelGrid.content = CreateObject("roSGNode", "ContentNode")
        print "M3UChannelScreen.brs - [resetScreen] Channel grid content cleared"
    end if
    
    if m.searchGrid <> invalid
        m.searchGrid.content = CreateObject("roSGNode", "ContentNode")
        m.searchGrid.visible = false
        print "M3UChannelScreen.brs - [resetScreen] Search grid content cleared and hidden"
    end if
    
    ' Reset UI labels
    if m.channelCountLabel <> invalid
        m.channelCountLabel.text = ""
    end if
    
    if m.selectedIndexLabel <> invalid
        m.selectedIndexLabel.text = ""
    end if
    
    if m.optionsHintGroup <> invalid
        m.optionsHintGroup.visible = true
    end if
    
    if m.searchStatusBar <> invalid
        m.searchStatusBar.visible = false
    end if
    
    ' Reset M3U URL
    m.top.m3uUrl = ""
    
    ' Stop clock timer if running
    if m.clockTimer <> invalid
        m.clockTimer.control = "stop"
    end if
    
    ' Cancel any pending API task
    if m.m3uLoaderTask <> invalid
        m.m3uLoaderTask.control = "stop"
        m.m3uLoaderTask.unobserveField("m3uContent")
        m.m3uLoaderTask.unobserveField("errorMessage")
        m.m3uLoaderTask = invalid
    end if
    
    print "M3UChannelScreen.brs - [resetScreen] Screen reset complete"
    print "M3UChannelScreen.brs - [resetScreen] =========================================="
end sub

function detectStreamFormat(url as string) as string
    ' Detect stream format from URL extension
    if url = invalid or url = "" then return "hls"

    urlLower = LCase(url)

    ' Check for IPTV-style URLs with numeric path segments (e.g., /123456)
    lastSlashPos = 0
    for i = Len(urlLower) to 1 step -1
        if Mid(urlLower, i, 1) = "/"
            lastSlashPos = i
            exit for
        end if
    end for

    if lastSlashPos > 0
        lastSegment = Mid(url, lastSlashPos + 1)
        isNumeric = true
        for i = 1 to Len(lastSegment)
            char = Mid(lastSegment, i, 1)
            if char < "0" or char > "9"
                isNumeric = false
                exit for
            end if
        end for
        if isNumeric and Len(lastSegment) > 0 then return "ts"
    end if

    if Instr(1, urlLower, ".ts") > 0 then return "ts"
    if Instr(1, urlLower, ".m3u8") > 0 then return "hls"
    if Instr(1, urlLower, ".mp4") > 0 then return "mp4"
    
    return "hls" ' Default to HLS
end function

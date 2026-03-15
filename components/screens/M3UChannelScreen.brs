sub init()
    print "M3UChannelScreen.brs - [init] *** INIT START ***"
    
    m.top.focusable = true
    m.channelGrid = m.top.findNode("channelGrid")
    m.searchResultsGrid = m.top.findNode("searchResultsGrid")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.channelCountLabel = m.top.findNode("channelCountLabel")
    m.selectedIndexLabel = m.top.findNode("selectedIndexLabel")
    m.searchPromptLabel = m.top.findNode("searchPromptLabel")
    m.searchStatusGroup = m.top.findNode("searchStatusGroup")
    m.searchQueryText = m.top.findNode("searchQueryText")
    m.searchClearHint = m.top.findNode("searchClearHint")
    
    ' Search state
    m.isSearchMode = false
    m.searchQuery = ""
    m.filteredChannels = []
    m.activeGrid = m.channelGrid
    m.searchKeyboard = invalid
    
    ' Header elements
    m.screenHeaderGroup = m.top.findNode("screenHeaderGroup")
    m.screenTabName = m.top.findNode("screenTabName")
    m.screenDotSeparator = m.top.findNode("screenDotSeparator")
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
        
        ' If grid has content, focus on it
        if m.channelGrid <> invalid and m.channelGrid.content <> invalid and m.channelGrid.content.getChildCount() > 0
            print "M3UChannelScreen.brs - [onVisibilityChanged] Grid has content, setting focus on grid"
            m.channelGrid.setFocus(true)
        else
            print "M3UChannelScreen.brs - [onVisibilityChanged] Grid empty, setting focus on screen"
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
    end if
end sub

sub onM3uUrlChanged()
    print "M3UChannelScreen.brs - [onM3uUrlChanged] M3U URL changed: " + m.top.m3uUrl
    print "M3UChannelScreen.brs - [onM3uUrlChanged] Screen visible: " + m.top.visible.ToStr()
    
    if m.top.m3uUrl <> "" and m.top.m3uUrl <> invalid
        loadM3UPlaylist()
    end if
end sub

sub loadM3UPlaylist()
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Starting to load M3U playlist"
    print "M3UChannelScreen.brs - [loadM3UPlaylist] URL: " + m.top.m3uUrl
    
    ' Show loading indicator, hide grid
    if m.loadingGroup <> invalid
        m.loadingGroup.visible = true
    end if
    
    if m.channelGrid <> invalid
        m.channelGrid.visible = false
    end if
    
    ' Create M3U Loader Task
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Creating M3ULoaderApi Task..."
    m.m3uLoader = CreateObject("roSGNode", "M3ULoaderApi")
    
    if m.m3uLoader = invalid
        print "M3UChannelScreen.brs - [loadM3UPlaylist] ERROR: Failed to create M3ULoaderApi Task!"
        return
    end if
    
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Setting up observers..."
    m.m3uLoader.observeField("responseData", "onM3ULoaded")
    m.m3uLoader.observeField("errorMessage", "onM3UError")
    
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Setting m3uUrl: " + m.top.m3uUrl
    m.m3uLoader.m3uUrl = m.top.m3uUrl
    
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Starting Task with control = RUN..."
    m.m3uLoader.control = "RUN"
    
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Task started, waiting for response..."
end sub

sub onM3ULoaded()
    print "M3UChannelScreen.brs - [onM3ULoaded] M3U data loaded successfully"
    
    responseData = m.m3uLoader.responseData
    if responseData <> invalid and responseData <> ""
        print "M3UChannelScreen.brs - [onM3ULoaded] Response length: " + Len(responseData).ToStr()
        parseM3UContent(responseData)
    else
        print "M3UChannelScreen.brs - [onM3ULoaded] ERROR: Empty response"
        showError("Empty M3U response")
    end if
end sub

sub onM3UError()
    print "M3UChannelScreen.brs - [onM3UError] M3U loading failed"
    
    errorMsg = m.m3uLoader.errorMessage
    if errorMsg <> invalid and errorMsg <> ""
        print "M3UChannelScreen.brs - [onM3UError] Error: " + errorMsg
        showError(errorMsg)
    else
        showError("Failed to load M3U playlist")
    end if
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
    print "M3UChannelScreen.brs - [parseM3UContent] Starting to parse M3U content"
    
    m.channels = []
    lines = content.Split(Chr(10)) ' Split by newline
    
    currentChannel = invalid
    channelCount = 0
    
    for i = 0 to lines.Count() - 1
        line = lines[i].Trim()
        
        ' Skip empty lines and comments (except EXTINF)
        if line = "" or (line.Left(1) = "#" and line.Left(7) <> "#EXTINF")
            continue for
        end if
        
        ' Parse EXTINF line
        if line.Left(7) = "#EXTINF"
            currentChannel = {}
            
            ' Extract channel info from EXTINF line
            ' Format: #EXTINF:-1 channel-id="..." tvg-id="..." tvg-chno="..." tvg-name="..." tvg-logo="..." group-title="...",Channel Name
            
            ' Extract tvg-name (channel name)
            nameStart = line.Instr("tvg-name=" + Chr(34))
            if nameStart > -1
                nameStart = nameStart + 10 ' Skip 'tvg-name="'
                nameEnd = line.Instr(nameStart, Chr(34))
                if nameEnd > -1
                    currentChannel.name = line.Mid(nameStart, nameEnd - nameStart)
                end if
            end if
            
            ' Extract tvg-logo (channel logo)
            logoStart = line.Instr("tvg-logo=" + Chr(34))
            if logoStart > -1
                logoStart = logoStart + 10 ' Skip 'tvg-logo="'
                logoEnd = line.Instr(logoStart, Chr(34))
                if logoEnd > -1
                    currentChannel.logo = line.Mid(logoStart, logoEnd - logoStart)
                end if
            end if
            
            ' Extract tvg-chno (channel number)
            chnoStart = line.Instr("tvg-chno=" + Chr(34))
            if chnoStart > -1
                chnoStart = chnoStart + 10 ' Skip 'tvg-chno="'
                chnoEnd = line.Instr(chnoStart, Chr(34))
                if chnoEnd > -1
                    currentChannel.channelNumber = line.Mid(chnoStart, chnoEnd - chnoStart)
                end if
            end if
            
            ' Extract group-title (category)
            groupStart = line.Instr("group-title=" + Chr(34))
            if groupStart > -1
                groupStart = groupStart + 13 ' Skip 'group-title="'
                groupEnd = line.Instr(groupStart, Chr(34))
                if groupEnd > -1
                    currentChannel.category = line.Mid(groupStart, groupEnd - groupStart)
                end if
            end if
            
            ' If tvg-name wasn't found, try to get name from the end of the line
            if currentChannel.name = invalid or currentChannel.name = ""
                commaPos = line.InStr(",")
                if commaPos > -1 and commaPos < Len(line) - 1
                    currentChannel.name = line.Mid(commaPos + 1).Trim()
                end if
            end if
            
        ' Parse URL line (stream URL)
        else if currentChannel <> invalid and line.Left(4) = "http"
            currentChannel.url = line
            
            ' Add channel to list
            if currentChannel.name <> invalid and currentChannel.name <> ""
                m.channels.Push(currentChannel)
                channelCount = channelCount + 1
                
                ' Log every 50 channels
                if channelCount mod 50 = 0
                    print "M3UChannelScreen.brs - [parseM3UContent] Parsed " + channelCount.ToStr() + " channels so far..."
                end if
            end if
            
            currentChannel = invalid
        end if
    end for
    
    print "M3UChannelScreen.brs - [parseM3UContent] Parsing complete. Total channels: " + m.channels.Count().ToStr()

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

        buildChannelGrid()
    else
        showError("No channels found in playlist")
    end if
end sub

sub buildChannelGrid()
    print "M3UChannelScreen.brs - [buildChannelGrid] Building initial channel grid with " + m.channels.Count().ToStr() + " total channels"
    
    m.totalChannels = m.channels.Count()
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
    
    ' Show grid and set focus
    m.channelGrid.visible = true
    m.channelGrid.setFocus(true)
    
    ' Show and update channel counter and selected index
    updateChannelCounter()
    updateSelectedIndex()
    
    ' Show search prompt
    if m.searchPromptLabel <> invalid
        m.searchPromptLabel.visible = true
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
        if i >= m.channels.Count() then exit for
        
        channel = m.channels[i]
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
            channelsWithoutLogo = channelsWithoutLogo + 1
            
            ' Log missing logo for first 5 items
            if channelCount < 5
                print "M3UChannelScreen.brs - [loadChannelPage] Channel " + i.ToStr() + " NO LOGO:"
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
    
    if m.isSearchMode
        ' Show search results count
        if m.searchQuery <> ""
            counterText = m.filteredChannels.Count().ToStr() + " results for '" + m.searchQuery + "'"
        else
            counterText = m.loadedChannels.ToStr() + " channels (search mode)"
        end if
        m.channelCountLabel.text = counterText
        m.channelCountLabel.visible = true
    else if m.totalChannels > 0
        ' Show normal channel count
        counterText = m.loadedChannels.ToStr() + " of " + m.totalChannels.ToStr() + " channels loaded"
        m.channelCountLabel.text = counterText
        m.channelCountLabel.visible = true
    else
        m.channelCountLabel.visible = false
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
    
    ' Return focus to active grid
    if m.activeGrid <> invalid
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
    
    ' Hide search prompt, show search status
    if m.searchPromptLabel <> invalid
        m.searchPromptLabel.visible = false
    end if
    if m.searchStatusGroup <> invalid
        m.searchStatusGroup.visible = true
    end if
    
    ' Update search display
    updateSearchDisplay()
end sub

sub exitSearchMode()
    print "M3UChannelScreen.brs - [exitSearchMode] Exiting search mode"
    
    m.isSearchMode = false
    m.searchQuery = ""
    m.filteredChannels = []
    
    ' Show search prompt, hide search status
    if m.searchPromptLabel <> invalid
        m.searchPromptLabel.visible = true
    end if
    if m.searchStatusGroup <> invalid
        m.searchStatusGroup.visible = false
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
    print "M3UChannelScreen.brs - [performSearch] Searching for: '" + m.searchQuery + "'"
    
    if m.searchQuery = ""
        ' Empty search - show all loaded channels
        m.filteredChannels = []
        for i = 0 to m.loadedChannels - 1
            if i < m.channels.Count()
                m.filteredChannels.Push(m.channels[i])
            end if
        end for
    else
        ' Filter channels by search query
        m.filteredChannels = []
        searchLower = LCase(m.searchQuery)
        
        for i = 0 to m.loadedChannels - 1
            if i >= m.channels.Count() then exit for
            
            channel = m.channels[i]
            if channel <> invalid
                ' Search in channel name and category
                matchFound = false
                
                if channel.name <> invalid and channel.name <> ""
                    if LCase(channel.name).Instr(searchLower) > 0
                        matchFound = true
                    end if
                end if
                
                if not matchFound and channel.category <> invalid and channel.category <> ""
                    if LCase(channel.category).Instr(searchLower) > 0
                        matchFound = true
                    end if
                end if
                
                if matchFound
                    m.filteredChannels.Push(channel)
                end if
            end if
        end for
    end if
    
    ' Build search results grid
    buildSearchResults()
    
    print "M3UChannelScreen.brs - [performSearch] Found " + m.filteredChannels.Count().ToStr() + " matching channels"
end sub

sub buildSearchResults()
    if m.searchResultsGrid = invalid then return
    
    ' Create content node for search results
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    channelCount = 0
    for each channel in m.filteredChannels
        if channel = invalid then continue for
        
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
    m.searchResultsGrid.setFocus(true)
    m.activeGrid = m.searchResultsGrid
    
    ' Update displays
    updateChannelCounter()
    updateSelectedIndex()
end sub

sub onSearchResultSelected()
    print "M3UChannelScreen.brs - [onSearchResultSelected] Search result selected"
    navigateToPlayVideo()
end sub

sub onSearchResultFocused()
    if m.searchResultsGrid = invalid then return
    updateSelectedIndex()
end sub

sub onChannelFocused()
    if m.channelGrid = invalid then return
    
    focusedIndex = m.channelGrid.itemFocused
    
    ' Update selected index display
    updateSelectedIndex()
    
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

sub onChannelSelected()
    print "M3UChannelScreen.brs - [onChannelSelected] Channel selected"
    navigateToPlayVideo()
end sub

sub navigateToPlayVideo()
    ' Get the video player screen
    videoDVRScreen = m.global.findNode("videoDVRScreen")
    
    if videoDVRScreen = invalid
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: videoDVRScreen not found"
        return
    end if
    
    ' Get the selected channel from the active grid
    activeGrid = m.activeGrid
    if activeGrid = invalid
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: No active grid"
        return
    end if
    
    selectedIndex = activeGrid.itemFocused
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Selected index: " + selectedIndex.ToStr()
    
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
    if channelNode.streamUrl <> invalid
        streamUrl = channelNode.streamUrl
    end if
    
    if streamUrl = ""
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: No stream URL found"
        return
    end if
    
    ' Create content node for video player
    progNodeToPlay = CreateObject("roSGNode", "ContentNode")
    progNodeToPlay.url = streamUrl
    progNodeToPlay.title = channelNode.title
    
    ' Set description
    if channelNode.description <> invalid
        progNodeToPlay.description = channelNode.description
    else
        progNodeToPlay.description = ""
    end if
    
    ' Set poster (channel logo)
    if channelNode.hdPosterUrl <> invalid and channelNode.hdPosterUrl <> ""
        progNodeToPlay.hdposterurl = channelNode.hdPosterUrl
    end if
    
    ' Add additional fields
    progNodeToPlay.addFields({
        isCC: "false",
        isHD: "true",
        channelTitle: "M3U Channel",
        streamFormat: "hls"
    })
    
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Setting content on videoDVRScreen"
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Stream URL: " + streamUrl
    
    ' Navigate to video player
    videoDVRScreen.navigatedFrom = "M3UChannels"
    videoDVRScreen.content = progNodeToPlay
    videoDVRScreen.setFocus(true)
    videoDVRScreen.visible = true
    m.top.visible = false
    
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Navigation complete"
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
            
            print "M3UChannelScreen.brs - [onKeyEvent] BACK pressed, hiding M3U screen"
            
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
                            print "M3UChannelScreen.brs - [onKeyEvent] Found Personal screen, making visible and setting focus"
                            screen.visible = true
                            screen.setFocus(true)
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

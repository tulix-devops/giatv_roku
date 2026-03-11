sub init()
    print "M3UChannelScreen.brs - [init] *** INIT START ***"
    
    m.top.focusable = true
    m.channelGrid = m.top.findNode("channelGrid")
    m.loadingGroup = m.top.findNode("loadingGroup")
    
    ' Header elements
    m.screenHeaderGroup = m.top.findNode("screenHeaderGroup")
    m.screenTabName = m.top.findNode("screenTabName")
    m.screenDotSeparator = m.top.findNode("screenDotSeparator")
    m.screenTimeLabel = m.top.findNode("screenTimeLabel")
    m.clockTimer = m.top.findNode("clockTimer")
    
    ' Observe visibility changes to manage focus
    m.top.observeField("visible", "onVisibilityChanged")
    
    ' Observe channel selection
    if m.channelGrid <> invalid
        m.channelGrid.observeField("itemSelected", "onChannelSelected")
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
    
    ' Print first 5 channels for debugging
    if m.channels.Count() > 0
        print "M3UChannelScreen.brs - [parseM3UContent] ========== FIRST 5 CHANNELS =========="
        maxPrint = 5
        if m.channels.Count() < maxPrint then maxPrint = m.channels.Count()
        
        for i = 0 to maxPrint - 1
            ch = m.channels[i]
            print "M3UChannelScreen.brs - [parseM3UContent] Channel " + i.ToStr() + ":"
            print "  name: " + ch.name
            if ch.channelNumber <> invalid then print "  number: " + ch.channelNumber
            if ch.category <> invalid then print "  category: " + ch.category
            if ch.logo <> invalid then print "  logo: " + ch.logo
            if ch.url <> invalid then print "  url: " + Left(ch.url, 60)
        end for
        print "M3UChannelScreen.brs - [parseM3UContent] =========================================="
        
        buildChannelGrid()
    else
        showError("No channels found in playlist")
    end if
end sub

sub buildChannelGrid()
    print "M3UChannelScreen.brs - [buildChannelGrid] Building channel grid with " + m.channels.Count().ToStr() + " channels"
    
    ' Create content node for MarkupGrid (flat list, no rows)
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    ' Add all channels as direct children (MarkupGrid handles the grid layout)
    channelCount = 0
    for each channel in m.channels
        itemNode = contentNode.createChild("ContentNode")
        
        ' Set title (required)
        if channel.name <> invalid and channel.name <> ""
            itemNode.title = channel.name
        else
            itemNode.title = "Channel " + channelCount.ToStr()
        end if
        
        ' Set description with channel number
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
        
        ' Store the stream URL
        if channel.url <> invalid and channel.url <> ""
            itemNode.addFields({ streamUrl: channel.url })
        end if
        
        channelCount = channelCount + 1
        
        ' Limit to first 100 channels for performance
        if channelCount >= 100
            print "M3UChannelScreen.brs - [buildChannelGrid] Limiting to first 100 channels for performance"
            exit for
        end if
    end for
    
    print "M3UChannelScreen.brs - [buildChannelGrid] Added " + channelCount.ToStr() + " channels to grid"
    
    ' Hide loading indicator
    if m.loadingGroup <> invalid
        m.loadingGroup.visible = false
    end if
    
    ' Set content and show grid
    m.channelGrid.content = contentNode
    m.channelGrid.visible = true
    m.channelGrid.setFocus(true)
    
    print "M3UChannelScreen.brs - [buildChannelGrid] Grid built and displayed with " + contentNode.getChildCount().ToStr() + " items"
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
    
    ' Get the selected channel from the grid (MarkupGrid uses flat index)
    selectedIndex = m.channelGrid.itemFocused
    print "M3UChannelScreen.brs - [navigateToPlayVideo] Selected index: " + selectedIndex.ToStr()
    
    if m.channelGrid.content = invalid
        print "M3UChannelScreen.brs - [navigateToPlayVideo] ERROR: No content in grid"
        return
    end if
    
    ' Get the channel node
    channelNode = m.channelGrid.content.getChild(selectedIndex)
    
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

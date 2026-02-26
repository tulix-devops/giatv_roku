sub init()
    print "TVGuideScreen.brs - [init] Initializing TV Guide Screen"
    
    m.background = m.top.findNode("background")
    m.headerTitle = m.top.findNode("headerTitle")
    m.headerTime = m.top.findNode("headerTime")
    m.headerLogo = m.top.findNode("headerLogo")
    m.headerDivider = m.top.findNode("headerDivider")
    
    m.daySelector = m.top.findNode("daySelector")
    m.timeGrid = m.top.findNode("timeGrid")
    
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.noContentLabel = m.top.findNode("noContentLabel")
    
    ' Channel logo and program details
    m.channelLogoImage = m.top.findNode("channelLogoImage")
    m.channelLogoName = m.top.findNode("channelLogoName")
    m.currentTimestamp = m.top.findNode("currentTimestamp")
    m.programTitle = m.top.findNode("programTitle")
    m.programTime = m.top.findNode("programTime")
    m.programDescription = m.top.findNode("programDescription")
    
    ' Video player
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.videoPlayerStatus = m.top.findNode("videoPlayerStatus")
    
    ' Observe video player state
    if m.videoPlayer <> invalid
        m.videoPlayer.observeField("state", "onVideoStateChanged")
    end if
    
    ' Store channels and programs data
    m.channelsData = []
    m.dataLoaded = false

    ' Day selector state: 4 options [-3,-2,-1,0], Today is index 3 (last item)
    m.selectedDayIndex = 3
    m.dayOffset = 0
    
    ' API task reference
    m.tvGuideApiTask = invalid
    
    ' Track which area has focus
    m.focusArea = "timegrid" ' "days" | "timegrid"
    m.lastFocusAreaBeforeDays = "timegrid"
    
    ' Set up TimeGrid observers
    if m.timeGrid <> invalid
        m.timeGrid.observeField("programSelected", "onProgramSelected")
        m.timeGrid.observeField("programFocused", "onProgramFocused")
        m.timeGrid.observeField("channelFocused", "onChannelFocused")
    end if
    
    if m.daySelector <> invalid
        m.daySelector.observeField("itemFocused", "onDayFocused")
    end if
    
    ' Update header time
    updateHeaderTime()

    ' Build day selector UI (independent of API)
    buildDaySelector()
    
    ' Create time update timer
    m.timeTimer = CreateObject("roSGNode", "Timer")
    m.timeTimer.repeat = true
    m.timeTimer.duration = 60 ' Update every minute
    m.timeTimer.observeField("fire", "onTimeUpdate")
    m.timeTimer.control = "start"
    
    print "TVGuideScreen.brs - [init] Initialization complete"
end sub

sub buildDaySelector()
    if m.daySelector = invalid
        return
    end if

    content = CreateObject("roSGNode", "ContentNode")

    ' 4 days: Today and previous 3 days
    offsets = [-3, -2, -1, 0]
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    nowSeconds = now.AsSeconds()

    for i = 0 to offsets.Count() - 1
        offset = offsets[i]
        n = CreateObject("roSGNode", "ContentNode")
        n.addFields({ dayOffset: offset })

        if offset = -1
            n.title = "Yesterday"
        else if offset = 0
            n.title = "Today"
        else
            ' Format past days as "Tue, 27 Jan"
            d = CreateObject("roDateTime")
            d.FromSeconds(nowSeconds + (offset * 86400))
            d.ToLocalTime()

            ' Example input: "Tue, Jan 27 2026" -> "Tue, 27 Jan"
            dateStr = d.AsDateString("short-month-short-weekday")
            parts = dateStr.Split(" ")
            weekday = Left(parts[0], 3)
            if parts.Count() >= 3
                month = parts[1]
                day = parts[2]
                n.title = weekday + ", " + day + " " + month
            else
                n.title = dateStr
            end if
        end if

        content.appendChild(n)
    end for

    m.daySelector.content = content
    m.daySelector.itemFocused = m.selectedDayIndex
end sub

sub onDayFocused()
    if m.daySelector = invalid then return
    idx = m.daySelector.itemFocused
    if idx = invalid then return
    idx = Int(idx)

    ' Keep "Today" default as the 4th item (index 3)
    m.selectedDayIndex = idx
    offsets = [-3, -2, -1, 0, 1]
    if idx >= 0 and idx < offsets.Count()
        m.dayOffset = offsets[idx]
    else
        m.dayOffset = 0
    end if

    ' Reset timeline window when day changes
    m.timelineStartTotalMinutes = 0
    m.timelineStartHour = 0
    m.timelineStartMinute = 0

    ' Force reload (API may honor ?date=YYYY-MM-DD)
    loadTVGuideForSelectedDay()
end sub

sub loadTVGuideForSelectedDay()
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] ========== STARTING API CALL =========="
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] Day offset (UI): " + m.dayOffset.ToStr()

    showLoading()

    ' Calculate which day to request from API
    ' API uses local date, but we need EST date
    ' If it's 1 AM local on Feb 25, but 4 PM EST on Feb 24, we need to request Feb 24
    dateTimeUTC = CreateObject("roDateTime")
    dateTimeLocal = CreateObject("roDateTime")
    dateTimeLocal.ToLocalTime()
    
    ' Calculate EST date
    currentMonth = dateTimeUTC.GetMonth()
    americanOffsetFromUTC = -18000 ' EST (UTC-5)
    if currentMonth >= 3 and currentMonth <= 10
        americanOffsetFromUTC = -14400 ' EDT (UTC-4)
    end if
    
    currentSecondsEST = dateTimeUTC.AsSeconds() + americanOffsetFromUTC
    dateTimeEST = CreateObject("roDateTime")
    dateTimeEST.FromSeconds(currentSecondsEST)
    
    ' Get day of month for both
    localDay = dateTimeLocal.GetDayOfMonth()
    estDay = dateTimeEST.GetDayOfMonth()
    
    ' Calculate day difference (EST day - local day)
    dayDifference = estDay - localDay
    
    ' Adjust API dayOffset to request EST's day
    apiDayOffset = m.dayOffset + dayDifference
    
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] Local date: " + dateTimeLocal.GetMonth().ToStr() + "/" + localDay.ToStr()
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] EST date: " + dateTimeEST.GetMonth().ToStr() + "/" + estDay.ToStr()
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] Day difference: " + dayDifference.ToStr()
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] API dayOffset (adjusted): " + apiDayOffset.ToStr()

    m.tvGuideApiTask = CreateObject("roSGNode", "TVGuideApi")
    if m.tvGuideApiTask = invalid
        print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] ERROR: Failed to create TVGuideApi task"
        hideLoading()
        return
    end if

    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] ✓ TVGuideApi task created"
    m.tvGuideApiTask.observeField("responseData", "onTVGuideDataReceived")
    m.tvGuideApiTask.observeField("errorMessage", "onTVGuideError")
    m.tvGuideApiTask.dayOffset = apiDayOffset
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] ✓ Starting API task..."
    m.tvGuideApiTask.control = "run"
    print "TVGuideScreen.brs - [loadTVGuideForSelectedDay] ✓ API task started"
end sub

' Called by home_scene when this screen is shown
function loadContentForType() as boolean
    print "TVGuideScreen.brs - [loadContentForType] ========== FUNCTION CALLED BY HOME_SCENE =========="
    print "TVGuideScreen.brs - [loadContentForType] m.dataLoaded: " + m.dataLoaded.ToStr()
    if m.channelsData <> invalid
        print "TVGuideScreen.brs - [loadContentForType] m.channelsData count: " + m.channelsData.Count().ToStr()
    else
        print "TVGuideScreen.brs - [loadContentForType] m.channelsData is invalid"
    end if
    
    ' Don't reload if already loaded (for the currently selected day)
    if m.dataLoaded = true and m.channelsData.Count() > 0
        print "TVGuideScreen.brs - [loadContentForType] Data already loaded, skipping API call"
        return true
    end if
    
    print "TVGuideScreen.brs - [loadContentForType] Need to load data, calling loadTVGuideForSelectedDay()"
    loadTVGuideForSelectedDay()
    
    print "TVGuideScreen.brs - [loadContentForType] ✓ API task initiated"
    return true
end function

sub onTVGuideDataReceived()
    print "TVGuideScreen.brs - [onTVGuideDataReceived] ========== DATA RECEIVED =========="
    
    if m.tvGuideApiTask = invalid
        print "TVGuideScreen.brs - [onTVGuideDataReceived] ERROR: API task is invalid"
        hideLoading()
        return
    end if
    
    responseData = m.tvGuideApiTask.responseData
    if responseData = invalid or responseData = ""
        print "TVGuideScreen.brs - [onTVGuideDataReceived] ERROR: Empty response"
        m.noContentLabel.visible = true
        hideLoading()
        return
    end if
    
    print "TVGuideScreen.brs - [onTVGuideDataReceived] Response data length: " + Len(responseData).ToStr() + " chars"
    print "TVGuideScreen.brs - [onTVGuideDataReceived] Response preview: " + Left(responseData, 200)
    
    ' Parse JSON response
    parsedData = ParseJson(responseData)
    if parsedData = invalid
        print "TVGuideScreen.brs - [onTVGuideDataReceived] ERROR: Failed to parse JSON"
        m.noContentLabel.visible = true
        hideLoading()
        return
    end if
    
    print "TVGuideScreen.brs - [onTVGuideDataReceived] ✓ Parsed data successfully"
    print "TVGuideScreen.brs - [onTVGuideDataReceived] Data type: " + Type(parsedData)
    if Type(parsedData) = "roArray"
        print "TVGuideScreen.brs - [onTVGuideDataReceived] Array length: " + parsedData.Count().ToStr()
    else if Type(parsedData) = "roAssociativeArray"
        print "TVGuideScreen.brs - [onTVGuideDataReceived] Keys: " + FormatJson(parsedData.Keys())
    end if
    
    ' TV Guide API returns direct array of channels
    m.dataLoaded = true
    print "TVGuideScreen.brs - [onTVGuideDataReceived] ========== CALLING loadTVGuideData() =========="
    loadTVGuideData(parsedData)
end sub

sub onTVGuideError()
    print "TVGuideScreen.brs - [onTVGuideError] Error loading TV Guide"
    
    if m.tvGuideApiTask <> invalid and m.tvGuideApiTask.errorMessage <> invalid
        print "TVGuideScreen.brs - [onTVGuideError] Error message: " + m.tvGuideApiTask.errorMessage
    end if
    
    m.noContentLabel.visible = true
    hideLoading()
end sub

sub onContentTypeIdChanged()
    print "TVGuideScreen.brs - [onContentTypeIdChanged] ========== CONTENT TYPE ID CHANGED =========="
    print "TVGuideScreen.brs - [onContentTypeIdChanged] New contentTypeId: " + m.top.contentTypeId.ToStr()
    
    ' TV Guide has contentTypeId = 17
    if m.top.contentTypeId = 17
        print "TVGuideScreen.brs - [onContentTypeIdChanged] TV Guide detected (ID 17), loading content"
        loadContentForType()
    else
        print "TVGuideScreen.brs - [onContentTypeIdChanged] Not TV Guide ID, contentTypeId: " + m.top.contentTypeId.ToStr()
    end if
end sub

sub onVisibleChanged()
    if m.top.visible = true
        print "TVGuideScreen.brs - [onVisibleChanged] Screen became visible"
        updateHeaderTime()
        m.focusArea = "timegrid"
        ' DO NOT auto-focus TimeGrid - let user navigate from navigation bar with RIGHT key
        print "TVGuideScreen.brs - [onVisibleChanged] TimeGrid ready, waiting for user to press RIGHT from navigation"
        
        ' If returning from video player and TimeGrid has focus, resume preview playback
        if m.timeGrid <> invalid and m.timeGrid.hasFocus()
            channelIndex = m.timeGrid.channelFocused
            programIndex = m.timeGrid.programFocused
            if channelIndex <> invalid and programIndex <> invalid and programIndex >= 0
                print "TVGuideScreen.brs - [onVisibleChanged] Resuming preview for focused program"
                updateFocusedItemDetails(channelIndex, programIndex)
            end if
        end if
    else
        ' Stop video when screen is hidden
        if m.videoPlayer <> invalid
            m.videoPlayer.control = "stop"
            print "TVGuideScreen.brs - [onVisibleChanged] Stopped preview video player"
        end if
    end if
end sub

sub onExplicitFocusRequested()
    ' Called when user presses RIGHT from navigation bar
    if m.top.explicitContentFocusRequested = true
        print "TVGuideScreen.brs - [onExplicitFocusRequested] User pressed RIGHT from navigation, focusing TimeGrid"
        if m.timeGrid <> invalid
            m.timeGrid.setFocus(true)
            m.focusArea = "timegrid"
        end if
        ' Reset the flag
        m.top.explicitContentFocusRequested = false
    end if
end sub

sub onChannelFocused()
    if m.timeGrid = invalid then return
    
    channelIndex = m.timeGrid.channelFocused
    programIndex = m.timeGrid.programFocused
    
    if channelIndex <> invalid and programIndex <> invalid
        print "TVGuideScreen.brs - [onChannelFocused] Channel: " + channelIndex.ToStr() + ", Program: " + programIndex.ToStr()
        updateFocusedItemDetails(channelIndex, programIndex)
    end if
end sub

sub onProgramFocused()
    if m.timeGrid = invalid then return
    
    channelIndex = m.timeGrid.channelFocused
    programIndex = m.timeGrid.programFocused
    
    ' Handle invalid program index (e.g., -1 when no program at that time)
    if channelIndex = invalid or programIndex = invalid or programIndex < 0
        print "TVGuideScreen.brs - [onProgramFocused] Invalid program index: " + programIndex.ToStr()
        ' Stop video and show message
        if m.videoPlayer <> invalid
            m.videoPlayer.control = "stop"
        end if
        if m.videoPlayerStatus <> invalid
            m.videoPlayerStatus.text = "No program at this time"
            m.videoPlayerStatus.visible = true
        end if
        return
    end if
    
    if channelIndex <> invalid and programIndex <> invalid
        print "TVGuideScreen.brs - [onProgramFocused] Channel: " + channelIndex.ToStr() + ", Program: " + programIndex.ToStr()
        updateFocusedItemDetails(channelIndex, programIndex)
    end if
end sub

sub updateFocusedItemDetails(channelIndex as Integer, programIndex as Integer)
    ' Update channel logo and program details
    content = m.timeGrid.content
    if content = invalid then return
    
    channelNode = content.GetChild(channelIndex)
    if channelNode = invalid then return
    
    program = channelNode.GetChild(programIndex)
    if program = invalid then return
    
    ' Get original channel data from m.channelsData for stream URL
    originalChannel = invalid
    originalProgram = invalid
    if m.channelsData <> invalid and channelIndex >= 0 and channelIndex < m.channelsData.Count()
        originalChannel = m.channelsData[channelIndex]
        ' Also get the original program data which may have a stream URL
        if originalChannel.shows <> invalid and programIndex >= 0 and programIndex < originalChannel.shows.Count()
            originalProgram = originalChannel.shows[programIndex]
        end if
    end if
    
    ' Update channel logo
    if m.channelLogoImage <> invalid
        ' Get channel logo URL
        logoUrl = ""
        if channelNode.HDSMALLICONURL <> invalid and channelNode.HDSMALLICONURL <> ""
            logoUrl = channelNode.HDSMALLICONURL
        else if channelNode.HDPOSTERURL <> invalid and channelNode.HDPOSTERURL <> ""
            logoUrl = channelNode.HDPOSTERURL
        else if channelNode.hdPosterUrl <> invalid and channelNode.hdPosterUrl <> ""
            logoUrl = channelNode.hdPosterUrl
        else if channelNode.SDPosterUrl <> invalid and channelNode.SDPosterUrl <> ""
            logoUrl = channelNode.SDPosterUrl
        end if
        
        m.channelLogoImage.uri = logoUrl
        
        ' Set channel name as fallback
        if m.channelLogoName <> invalid
            if channelNode.title <> invalid and channelNode.title <> ""
                m.channelLogoName.text = channelNode.title
            else
                m.channelLogoName.text = ""
            end if
            
            ' Show name if no logo
            if logoUrl = ""
                m.channelLogoName.visible = true
            else
                m.channelLogoName.visible = false
            end if
        end if
    end if
    
    ' Update program title
    if m.programTitle <> invalid
        if program.title <> invalid and program.title <> ""
            m.programTitle.text = program.title
        else
            m.programTitle.text = "No Title"
        end if
    end if
    
    ' Update program time (start - end)
    if m.programTime <> invalid
        ' Get playStart and playDuration
        playStartTime = program.PLAYSTART
        playDurationTime = program.PLAYDURATION
        if playStartTime = invalid then playStartTime = program.playStart
        if playDurationTime = invalid then playDurationTime = program.playDuration
        
        if playStartTime <> invalid and playDurationTime <> invalid
            ' Format start time
            startDateTime = CreateObject("roDateTime")
            startDateTime.FromSeconds(playStartTime)
            startDateTime.ToLocalTime()
            startHour = startDateTime.GetHours()
            startMin = startDateTime.GetMinutes()
            startAMPM = "AM"
            if startHour >= 12
                startAMPM = "PM"
                if startHour > 12 then startHour = startHour - 12
            end if
            if startHour = 0 then startHour = 12
            
            ' Format end time
            endDateTime = CreateObject("roDateTime")
            endDateTime.FromSeconds(playStartTime + playDurationTime)
            endDateTime.ToLocalTime()
            endHour = endDateTime.GetHours()
            endMin = endDateTime.GetMinutes()
            endAMPM = "AM"
            if endHour >= 12
                endAMPM = "PM"
                if endHour > 12 then endHour = endHour - 12
            end if
            if endHour = 0 then endHour = 12
            
            ' Format: "10:30 AM - 12:00 PM"
            timeText = startHour.ToStr() + ":"
            if startMin < 10 then timeText = timeText + "0"
            timeText = timeText + startMin.ToStr() + " " + startAMPM + " - "
            timeText = timeText + endHour.ToStr() + ":"
            if endMin < 10 then timeText = timeText + "0"
            timeText = timeText + endMin.ToStr() + " " + endAMPM
            
            m.programTime.text = timeText
        else
            m.programTime.text = ""
        end if
    end if
    
    ' Update program description
    if m.programDescription <> invalid
        if program.description <> invalid and program.description <> ""
            m.programDescription.text = program.description
        else
            m.programDescription.text = "No description available"
        end if
    end if
    
    ' Log program status
    playStartTime = program.PLAYSTART
    playDurationTime = program.PLAYDURATION
    if playStartTime = invalid then playStartTime = program.playStart
    if playDurationTime = invalid then playDurationTime = program.playDuration
    
    diff = m.timeGrid.leftEdgeTargetTime - playStartTime
    
    bIsInPast = diff > 0 and (diff - playDurationTime) > 0
    bIsInFuture = (diff + m.timeGrid.duration) < 0
    
    if bIsInPast then
        print "TVGuideScreen.brs - [updateFocusedItemDetails] Program is in the past"
    else if bIsInFuture then
        print "TVGuideScreen.brs - [updateFocusedItemDetails] Program is in the future"
    else
        print "TVGuideScreen.brs - [updateFocusedItemDetails] Program: " + program.title
    end if
    
    ' Play video preview on focus (use original channel and program data with stream URLs)
    if originalChannel <> invalid
        playChannelPreview(originalChannel, originalProgram)
    else
        print "TVGuideScreen.brs - [updateFocusedItemDetails] WARNING: Original channel data not found"
    end if
end sub

sub playChannelPreview(channel as object, program as object)
    ' Play channel video in preview player when focused
    if m.videoPlayer = invalid
        print "TVGuideScreen.brs - [playChannelPreview] ERROR: Video player not initialized"
        return
    end if
    
    ' Safely get channel title and program title
    channelTitle = "Unknown Channel"
    if channel.title <> invalid and channel.title <> ""
        channelTitle = channel.title
    else if channel.name <> invalid and channel.name <> ""
        channelTitle = channel.name
    end if
    
    programTitle = ""
    if program <> invalid
        if program.name <> invalid and program.name <> ""
            programTitle = program.name
        else if program.title <> invalid and program.title <> ""
            programTitle = program.title
        end if
    end if
    
    print "TVGuideScreen.brs - [playChannelPreview] Attempting to play: " + channelTitle
    if programTitle <> ""
        print "TVGuideScreen.brs - [playChannelPreview] Program: " + programTitle
    else
        print "TVGuideScreen.brs - [playChannelPreview] Program: (no name)"
    end if
    
    ' Get stream URL - check multiple sources
    ' PRIORITY: Check program URL first (individual shows may have specific streams)
    streamUrl = ""
    
    ' 1. Try program's URL field (shows often have their own stream URLs)
    if program <> invalid and program.url <> invalid and program.url <> ""
        streamUrl = program.url
        print "TVGuideScreen.brs - [playChannelPreview] Found program.url: " + streamUrl
    end if
    
    ' 2. Try channel stream_url field
    if streamUrl = "" and channel.stream_url <> invalid and channel.stream_url <> ""
        streamUrl = channel.stream_url
        print "TVGuideScreen.brs - [playChannelPreview] Found channel.stream_url: " + streamUrl
    end if
    
    ' 3. Try channel sources object
    if streamUrl = "" and channel.sources <> invalid
        if channel.sources.primary <> invalid and channel.sources.primary <> ""
            streamUrl = channel.sources.primary
            print "TVGuideScreen.brs - [playChannelPreview] Found channel.sources.primary: " + streamUrl
        else if channel.sources.hls <> invalid and channel.sources.hls <> ""
            streamUrl = channel.sources.hls
            print "TVGuideScreen.brs - [playChannelPreview] Found channel.sources.hls: " + streamUrl
        end if
    end if
    
    ' 4. Fallback to channel http field (often empty in TV Guide API)
    if streamUrl = "" and channel.http <> invalid and channel.http <> ""
        streamUrl = channel.http
        print "TVGuideScreen.brs - [playChannelPreview] Found channel.http: " + streamUrl
    end if
    
    ' 5. Try channel url field
    if streamUrl = "" and channel.url <> invalid and channel.url <> ""
        streamUrl = channel.url
        print "TVGuideScreen.brs - [playChannelPreview] Found channel.url: " + streamUrl
    end if
    
    if streamUrl = ""
        print "TVGuideScreen.brs - [playChannelPreview] No stream URL for channel: " + channelTitle + " (ID: " + channel.id.ToStr() + ")"
        ' Show informative message - stream not available in TV Guide data
        if m.videoPlayerStatus <> invalid
            m.videoPlayerStatus.text = channelTitle + Chr(10) + Chr(10) + "Stream preview not available" + Chr(10) + "Select to watch full screen"
            m.videoPlayerStatus.visible = true
        end if
        ' Stop any current playback
        m.videoPlayer.control = "stop"
        return
    end if
    
    print "TVGuideScreen.brs - [playChannelPreview] Loading preview: " + channelTitle + " - " + streamUrl
    
    ' Create content node for video
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = streamUrl
    videoContent.title = channelTitle
    videoContent.streamFormat = "hls"
    
    ' Set content and play
    m.videoPlayer.content = videoContent
    m.videoPlayer.control = "play"
    
    ' Show loading message (will be hidden when playing)
    if m.videoPlayerStatus <> invalid
        m.videoPlayerStatus.text = "Loading..."
        m.videoPlayerStatus.visible = true
    end if
end sub

sub onProgramSelected()
    print "TVGuideScreen.brs - [onProgramSelected] Program selected - opening full-screen player"
    if m.timeGrid = invalid then return
    
    ' Stop the preview video player before opening full-screen player
    if m.videoPlayer <> invalid
        m.videoPlayer.control = "stop"
        print "TVGuideScreen.brs - [onProgramSelected] Stopped preview video player"
    end if
    
    ' TimeGrid uses channelSelected and programSelected fields (not arrays)
    channelIndex = m.timeGrid.channelSelected
    programIndex = m.timeGrid.programSelected
    
    if channelIndex <> invalid and programIndex <> invalid
        print "TVGuideScreen.brs - [onProgramSelected] Channel: " + channelIndex.ToStr() + ", Program: " + programIndex.ToStr()
        
        ' Get the channel and program data from TimeGrid content
        content = m.timeGrid.content
        if content <> invalid
            channelNode = content.GetChild(channelIndex)
            if channelNode <> invalid
                program = channelNode.GetChild(programIndex)
                if program <> invalid
                    ' Get original channel data for stream URL
                    originalChannel = invalid
                    originalProgram = invalid
                    if m.channelsData <> invalid and channelIndex >= 0 and channelIndex < m.channelsData.Count()
                        originalChannel = m.channelsData[channelIndex]
                        if originalChannel.shows <> invalid and programIndex >= 0 and programIndex < originalChannel.shows.Count()
                            originalProgram = originalChannel.shows[programIndex]
                        end if
                    end if
                    
                    ' Get stream URL
                    streamUrl = ""
                    
                    ' Priority 1: Program's individual stream URL
                    if originalProgram <> invalid and originalProgram.url <> invalid and originalProgram.url <> ""
                        streamUrl = originalProgram.url
                        print "TVGuideScreen.brs - [onProgramSelected] Using program stream URL"
                    end if
                    
                    ' Priority 2: Channel stream URL
                    if streamUrl = "" and originalChannel <> invalid
                        if originalChannel.stream_url <> invalid and originalChannel.stream_url <> ""
                            streamUrl = originalChannel.stream_url
                            print "TVGuideScreen.brs - [onProgramSelected] Using channel.stream_url"
                        else if originalChannel.sources <> invalid
                            if originalChannel.sources.primary <> invalid and originalChannel.sources.primary <> ""
                                streamUrl = originalChannel.sources.primary
                                print "TVGuideScreen.brs - [onProgramSelected] Using channel.sources.primary"
                            else if originalChannel.sources.hls <> invalid and originalChannel.sources.hls <> ""
                                streamUrl = originalChannel.sources.hls
                                print "TVGuideScreen.brs - [onProgramSelected] Using channel.sources.hls"
                            end if
                        else if originalChannel.http <> invalid and originalChannel.http <> ""
                            streamUrl = originalChannel.http
                            print "TVGuideScreen.brs - [onProgramSelected] Using channel.http"
                        else if originalChannel.url <> invalid and originalChannel.url <> ""
                            streamUrl = originalChannel.url
                            print "TVGuideScreen.brs - [onProgramSelected] Using channel.url"
                        end if
                    end if
                    
                    if streamUrl = "" or streamUrl = invalid
                        print "TVGuideScreen.brs - [onProgramSelected] ERROR: No stream URL available for this program/channel"
                        return
                    end if
                    
                    ' Get program and channel info for display
                    programTitle = "Live TV"
                    if program.title <> invalid and program.title <> ""
                        programTitle = program.title
                    end if
                    
                    channelTitle = "Unknown Channel"
                    if channelNode.title <> invalid and channelNode.title <> ""
                        channelTitle = channelNode.title
                    end if
                    
                    programDescription = ""
                    if program.description <> invalid and program.description <> ""
                        programDescription = program.description
                    end if
                    
                    ' Get channel logo for thumbnail
                    thumbnailUrl = ""
                    if channelNode.HDSMALLICONURL <> invalid and channelNode.HDSMALLICONURL <> ""
                        thumbnailUrl = channelNode.HDSMALLICONURL
                    else if channelNode.HDPOSTERURL <> invalid and channelNode.HDPOSTERURL <> ""
                        thumbnailUrl = channelNode.HDPOSTERURL
                    end if
                    
                    ' Create video play request data matching the pattern from dynamic_content_screen
                    videoData = {
                        contentUrl: streamUrl,
                        title: programTitle + " - " + channelTitle,
                        description: programDescription,
                        thumbnail: thumbnailUrl,
                        isLive: true
                    }
                    
                    print "TVGuideScreen.brs - [onProgramSelected] Triggering video playback:"
                    print "TVGuideScreen.brs - [onProgramSelected]   Title: " + videoData.title
                    print "TVGuideScreen.brs - [onProgramSelected]   URL: " + streamUrl
                    
                    ' Trigger video play request to parent (home scene)
                    m.top.videoPlayRequested = videoData
                    print "TVGuideScreen.brs - [onProgramSelected] Video play request sent to parent"
                end if
            end if
        end if
    end if
end sub

sub onVideoStateChanged()
    ' Handle video player state changes
    if m.videoPlayer = invalid then return
    
    state = m.videoPlayer.state
    print "TVGuideScreen.brs - [onVideoStateChanged] Video state: " + state
    
    if m.videoPlayerStatus = invalid then return
    
    if state = "playing"
        m.videoPlayerStatus.visible = false
    else if state = "buffering"
        m.videoPlayerStatus.text = "Loading..."
        m.videoPlayerStatus.visible = true
    else if state = "paused"
        m.videoPlayerStatus.text = "Paused"
        m.videoPlayerStatus.visible = true
    else if state = "stopped"
        m.videoPlayerStatus.text = "Select a program to watch"
        m.videoPlayerStatus.visible = true
    else if state = "error"
        m.videoPlayerStatus.text = "Error loading stream"
        m.videoPlayerStatus.visible = true
    else if state = "finished"
        m.videoPlayerStatus.text = "Stream ended"
        m.videoPlayerStatus.visible = true
    end if
end sub

sub returnFocusToNavigation()
    ' Return focus to the navigation bar (TV Guide icon)
    print "TVGuideScreen.brs - [returnFocusToNavigation] Returning focus to navigation bar"
    
    ' Stop video player when navigating back
    if m.videoPlayer <> invalid
        m.videoPlayer.control = "stop"
        print "TVGuideScreen.brs - [returnFocusToNavigation] Stopped video player"
    end if
    
    ' Walk up the parent chain to find the home scene
    parentScene = m.top.getParent()
    maxDepth = 10
    depth = 0
    
    while parentScene <> invalid and depth < maxDepth
        depth = depth + 1
        
        ' Check if this is the home scene (has dynamic_navigation_bar)
        navBar = parentScene.findNode("dynamic_navigation_bar")
        if navBar <> invalid
            print "TVGuideScreen.brs - [returnFocusToNavigation] Found navigation bar at depth " + depth.ToStr()
            
            ' Set navigation bar state and focus
            navBar.navHasFocus = true
            navBar.setFocus(true)
            
            ' Force focus update to ensure proper visual state
            navBar.callFunc("focusUpdated")
            
            ' If navigation bar still doesn't have focus, force it
            if not navBar.hasFocus()
                print "TVGuideScreen.brs - [returnFocusToNavigation] Navigation bar still no focus, calling forceFocus"
                navBar.callFunc("forceFocus")
            end if
            
            print "TVGuideScreen.brs - [returnFocusToNavigation] Focus returned to navigation bar successfully"
            return
        end if
        parentScene = parentScene.getParent()
    end while
    
    print "TVGuideScreen.brs - [returnFocusToNavigation] ERROR: Could not find navigation bar"
end sub

sub ensureChannelWindowForIndex(channelIndex as integer)
    if channelIndex < 0 then return
    if m.visibleChannelRows = invalid then m.visibleChannelRows = 4

    changed = false
    if channelIndex < m.channelWindowStart
        m.channelWindowStart = channelIndex
        changed = true
    else if channelIndex >= (m.channelWindowStart + m.visibleChannelRows)
        m.channelWindowStart = channelIndex - m.visibleChannelRows + 1
        if m.channelWindowStart < 0 then m.channelWindowStart = 0
        changed = true
    end if

    if changed
        buildProgramGrid()
    end if
end sub

sub updateHeaderTime()
    ' Display current time in local timezone
    dateTimeLocal = CreateObject("roDateTime")
    dateTimeLocal.ToLocalTime()
    
    hours = dateTimeLocal.GetHours()
    minutes = dateTimeLocal.GetMinutes()
    
    ' 12-hour format with AM/PM
    ampm = "AM"
    displayHours = hours
    if hours >= 12
        ampm = "PM"
        if hours > 12 then displayHours = hours - 12
    end if
    if displayHours = 0 then displayHours = 12
    
    minutesStr = minutes.ToStr()
    if minutes < 10 then minutesStr = "0" + minutesStr
    
    ' Update current timestamp in program details area
    if m.currentTimestamp <> invalid
        timestampText = displayHours.ToStr() + ":" + minutesStr + " " + ampm
        m.currentTimestamp.text = "Current Time: " + timestampText
    end if
end sub

sub onTimeUpdate()
    updateHeaderTime()
    updateCurrentTimeIndicator()
end sub

sub showLoading()
    if m.loadingGroup <> invalid
        m.loadingGroup.visible = true
    end if
end sub

sub hideLoading()
    if m.loadingGroup <> invalid
        m.loadingGroup.visible = false
    end if
end sub

sub loadTVGuideData(tvGuideData as object)
    print "TVGuideScreen.brs - [loadTVGuideData] ========== LOADING TV GUIDE DATA =========="
    
    if tvGuideData = invalid
        print "TVGuideScreen.brs - [loadTVGuideData] ERROR: Data is invalid"
        m.noContentLabel.visible = true
        hideLoading()
        return
    end if
    
    print "TVGuideScreen.brs - [loadTVGuideData] Data type: " + Type(tvGuideData)
    if Type(tvGuideData) = "roArray"
        print "TVGuideScreen.brs - [loadTVGuideData] Array count: " + tvGuideData.Count().ToStr()
    end if
    
    if tvGuideData.Count() = 0
        print "TVGuideScreen.brs - [loadTVGuideData] ERROR: Data count is 0"
        m.noContentLabel.visible = true
        hideLoading()
        return
    end if
    
    ' Check if data is in the converted format (with category and contents)
    ' or direct array of channels
    if tvGuideData.Count() = 1 and tvGuideData[0].contents <> invalid
        ' Converted format - extract channels from contents
        m.channelsData = tvGuideData[0].contents
        print "TVGuideScreen.brs - [loadTVGuideData] ✓ Extracted " + m.channelsData.Count().ToStr() + " channels from converted format"
    else
        ' Direct array format
        m.channelsData = tvGuideData
        print "TVGuideScreen.brs - [loadTVGuideData] ✓ Using direct array with " + m.channelsData.Count().ToStr() + " channels"
    end if
    
    print "TVGuideScreen.brs - [loadTVGuideData] m.channelsData count: " + m.channelsData.Count().ToStr()
    if m.channelsData.Count() > 0
        ' Log first channel (Gusto TV)
        firstChannel = m.channelsData[0]
        channelName = "Unknown"
        if firstChannel.title <> invalid then channelName = firstChannel.title
        if firstChannel.name <> invalid then channelName = firstChannel.name
        print "TVGuideScreen.brs - [loadTVGuideData] ========== FIRST CHANNEL: " + channelName + " =========="
        print "TVGuideScreen.brs - [loadTVGuideData] Channel keys: " + FormatJson(firstChannel.Keys())
        
        if firstChannel.shows <> invalid and firstChannel.shows.Count() > 0
            print "TVGuideScreen.brs - [loadTVGuideData] Total shows: " + firstChannel.shows.Count().ToStr()
            print "TVGuideScreen.brs - [loadTVGuideData] First 10 shows:"
            for i = 0 to 9
                if i < firstChannel.shows.Count()
                    show = firstChannel.shows[i]
                    
                    showName = "NO_NAME"
                    if show.name <> invalid then showName = show.name
                    if show.title <> invalid then showName = show.title
                    
                    showStart = "NO_START"
                    if show.start <> invalid then showStart = show.start
                    
                    showEnd = "NO_END"
                    if show.end <> invalid then showEnd = show.end
                    
                    showTZ = "NO_TZ"
                    if show.timezone <> invalid then showTZ = show.timezone
                    
                    print "TVGuideScreen.brs - [loadTVGuideData]   " + i.ToStr() + ": [" + showName + "] " + showStart + " - " + showEnd + " (TZ: " + showTZ + ")"
                end if
            end for
        else
            print "TVGuideScreen.brs - [loadTVGuideData] ERROR: No shows data!"
        end if
        print "TVGuideScreen.brs - [loadTVGuideData] ================================"
    end if
    
    ' Build TimeGrid content
    print "TVGuideScreen.brs - [loadTVGuideData] ========== CALLING buildTimeGridContent() =========="
    buildTimeGridContent()
    
    hideLoading()
    
    ' DO NOT auto-focus TimeGrid - let user navigate from navigation bar with RIGHT key
    print "TVGuideScreen.brs - [loadTVGuideData] ✓ Data loaded, TimeGrid ready"
end sub

sub buildTimeGridContent()
    print "TVGuideScreen.brs - [buildTimeGridContent] ========== BUILDING TIMEGRID CONTENT =========="
    
    if m.timeGrid = invalid
        print "TVGuideScreen.brs - [buildTimeGridContent] ERROR: TimeGrid not found"
        return
    end if
    
    print "TVGuideScreen.brs - [buildTimeGridContent] ✓ TimeGrid exists"
    
    if m.channelsData = invalid
        print "TVGuideScreen.brs - [buildTimeGridContent] ERROR: m.channelsData is invalid"
        return
    end if
    
    print "TVGuideScreen.brs - [buildTimeGridContent] ✓ m.channelsData exists, count: " + m.channelsData.Count().ToStr()
    
    if m.channelsData.Count() = 0
        print "TVGuideScreen.brs - [buildTimeGridContent] ERROR: No channels data (count=0)"
        return
    end if
    
    ' Get current date/time
    ' API returns times in EST (e.g., "00:00" = midnight EST, "16:15" = 4:15 PM EST)
    ' Goal: Display these EST times directly on TimeGrid (show "00:00" as 12:00 AM, "16:15" as 4:15 PM)
    ' TimeGrid interprets timestamps in LOCAL timezone, so we need to create "fake" timestamps
    ' that display the EST wall-clock time when interpreted as local time
    
    dateTimeUTC = CreateObject("roDateTime")
    dateTimeLocal = CreateObject("roDateTime")
    dateTimeLocal.ToLocalTime()
    
    currentSecondsUTC = dateTimeUTC.AsSeconds()
    currentSecondsLocal = dateTimeLocal.AsSeconds()
    localOffsetFromUTC = currentSecondsLocal - currentSecondsUTC
    
    ' Calculate EST offset
    currentMonth = dateTimeUTC.GetMonth()
    americanOffsetFromUTC = -18000 ' EST (UTC-5)
    if currentMonth >= 3 and currentMonth <= 10
        americanOffsetFromUTC = -14400 ' EDT (UTC-4)
    end if
    
    ' Calculate timezone offset from EST to local
    ' If local is UTC+4 and EST is UTC-5, offset is +9 hours (32400 seconds)
    timezoneOffsetESTtoLocal = localOffsetFromUTC - americanOffsetFromUTC
    
    ' Get local time info
    currentHourLocal = dateTimeLocal.GetHours()
    currentMinuteLocal = dateTimeLocal.GetMinutes()
    currentSecondLocal = dateTimeLocal.GetSeconds()
    secondsSinceMidnightLocal = (currentHourLocal * 3600) + (currentMinuteLocal * 60) + currentSecondLocal
    
    ' Calculate EST midnight as UTC timestamp
    ' Step 1: Get current UTC time
    ' Step 2: Convert to EST
    currentSecondsEST = currentSecondsUTC + americanOffsetFromUTC
    dateTimeEST = CreateObject("roDateTime")
    dateTimeEST.FromSeconds(currentSecondsEST)
    
    currentHourEST = dateTimeEST.GetHours()
    currentMinuteEST = dateTimeEST.GetMinutes()
    secondsSinceMidnightEST = (currentHourEST * 3600) + (currentMinuteEST * 60)
    
    ' Step 3: Get EST midnight (still as a timestamp with EST offset)
    midnightSecondsEST = currentSecondsEST - secondsSinceMidnightEST
    
    ' Step 4: Convert EST midnight back to UTC
    midnightESTasUTC = midnightSecondsEST - americanOffsetFromUTC
    
    ' Step 5: Use UTC timestamp directly - TimeGrid will display in local time automatically
    ' Don't add localOffsetFromUTC here, as roDateTime.ToLocalTime() does that internally
    startOfDaySeconds = midnightESTasUTC
    
    print "TVGuideScreen.brs - [buildTimeGridContent] ========== TIMEZONE DEBUG =========="
    print "TVGuideScreen.brs - [buildTimeGridContent] Current local time: " + currentHourLocal.ToStr() + ":" + currentMinuteLocal.ToStr()
    print "TVGuideScreen.brs - [buildTimeGridContent] Current EST time: " + currentHourEST.ToStr() + ":" + currentMinuteEST.ToStr()
    print "TVGuideScreen.brs - [buildTimeGridContent] EST midnight (with offset): " + midnightSecondsEST.ToStr()
    print "TVGuideScreen.brs - [buildTimeGridContent] EST midnight as UTC: " + midnightESTasUTC.ToStr()
    print "TVGuideScreen.brs - [buildTimeGridContent] Converted to local timestamp: " + startOfDaySeconds.ToStr()
    
    ' Verify what this displays as
    debugMidnight = CreateObject("roDateTime")
    debugMidnight.FromSeconds(startOfDaySeconds)
    debugMidnight.ToLocalTime()
    print "TVGuideScreen.brs - [buildTimeGridContent] >>> EST midnight will display as: " + debugMidnight.GetHours().ToStr() + ":" + debugMidnight.GetMinutes().ToStr() + " local (should be ~9:00 AM)"
    print "TVGuideScreen.brs - [buildTimeGridContent] ================================"
    
    ' Adjust for day offset
    dayAdjustment = m.dayOffset * 86400
    startOfDaySeconds = startOfDaySeconds + dayAdjustment
    
    m.timeGrid.contentStartTime = startOfDaySeconds
    
    ' Set duration to visible window (2.5 hours = 9000 seconds)
    m.timeGrid.duration = 9000
    
    ' Set maxDays to 4 (4 days of scrollable content: yesterday, today, tomorrow, +1 more day)
    m.timeGrid.maxDays = 4
    
    ' Calculate leftEdgeTargetTime (but set it AFTER content is set)
    targetTime = startOfDaySeconds
    if m.dayOffset = 0 then
        ' For today, show current local time (rounded to 30-min)
        targetTime = currentSecondsLocal - (currentSecondsLocal mod 1800)
        
        print "TVGuideScreen.brs - [buildTimeGridContent] ========== TIME DEBUG (TODAY) =========="
        print "TVGuideScreen.brs - [buildTimeGridContent] Current local time: " + currentHourLocal.ToStr() + ":" + currentMinuteLocal.ToStr()
        print "TVGuideScreen.brs - [buildTimeGridContent] Target time (rounded): " + targetTime.ToStr()
        
        verifyDisplay = CreateObject("roDateTime")
        verifyDisplay.FromSeconds(targetTime)
        verifyDisplay.ToLocalTime()
        print "TVGuideScreen.brs - [buildTimeGridContent] >>> TimeGrid will show: " + verifyDisplay.GetHours().ToStr() + ":" + verifyDisplay.GetMinutes().ToStr()
        print "TVGuideScreen.brs - [buildTimeGridContent] ================================"
    else
        targetTime = startOfDaySeconds
    end if
    
    ' Create root content node
    timeGridContent = CreateObject("roSGNode", "ContentNode")
    
    ' Add each channel as a child node
    for each channel in m.channelsData
        channelNode = CreateObject("roSGNode", "ContentNode")
        
        ' Get channel info
        channelTitle = "Unknown Channel"
        if channel.title <> invalid and channel.title <> ""
            channelTitle = channel.title
        else if channel.name <> invalid and channel.name <> ""
            channelTitle = channel.name
        end if
        
        channelNode.title = channelTitle
        
        ' Add channel logo - TimeGrid uses HDSMALLICONURL first, then HDPOSTERURL
        logoSet = false
        if channel.logo <> invalid and channel.logo <> ""
            channelNode.HDSMALLICONURL = channel.logo
            channelNode.HDPOSTERURL = channel.logo
            channelNode.hdPosterUrl = channel.logo
            print "TVGuideScreen.brs - [buildTimeGridContent] Channel '" + channelTitle + "' logo: " + channel.logo
            logoSet = true
        else if channel.icon <> invalid and channel.icon <> ""
            channelNode.HDSMALLICONURL = channel.icon
            channelNode.HDPOSTERURL = channel.icon
            channelNode.hdPosterUrl = channel.icon
            print "TVGuideScreen.brs - [buildTimeGridContent] Channel '" + channelTitle + "' icon: " + channel.icon
            logoSet = true
        end if
        
        if not logoSet
            print "TVGuideScreen.brs - [buildTimeGridContent] WARNING: Channel '" + channelTitle + "' has no logo/icon"
        end if
        
        ' Add stream URL for playback
        if channel.stream_url <> invalid and channel.stream_url <> ""
            channelNode.url = channel.stream_url
        else if channel.url <> invalid and channel.url <> ""
            channelNode.url = channel.url
        end if
        
        ' Add programs for this channel
        if channel.shows <> invalid and channel.shows.Count() > 0
            for each show in channel.shows
                programNode = CreateObject("roSGNode", "ContentNode")
                
                ' Program title
                if show.name <> invalid
                    programNode.title = show.name
                else
                    programNode.title = "Program"
                end if
                
                ' Program description
                if show.longdescription <> invalid
                    programNode.description = show.longdescription
                else if show.description <> invalid
                    programNode.description = show.description
                end if
                
                ' Parse start and end times
                if show.start <> invalid and show.end <> invalid
                    ' Debug: Log first few program times to verify API timezone
                    if channelNode.getChildCount() < 3
                        print "TVGuideScreen.brs - [buildTimeGridContent] Program: " + show.name + " | Start: " + show.start + " | End: " + show.end
                    end if
                    
                    ' Parse "HH:MM" format
                    startParts = show.start.Split(":")
                    endParts = show.end.Split(":")
                    
                    if startParts.Count() >= 2 and endParts.Count() >= 2
                        startHour = Val(startParts[0])
                        startMin = Val(startParts[1])
                        endHour = Val(endParts[0])
                        endMin = Val(endParts[1])
                        
                        ' Calculate seconds from midnight for start time (EST)
                        startSecondsFromMidnightEST = (startHour * 3600) + (startMin * 60)
                        
                        ' Calculate seconds from midnight for end time (EST)
                        endSecondsFromMidnightEST = (endHour * 3600) + (endMin * 60)
                        
                        ' Handle programs spanning midnight
                        if endSecondsFromMidnightEST <= startSecondsFromMidnightEST
                            endSecondsFromMidnightEST = endSecondsFromMidnightEST + 86400
                        end if
                        
                        ' Calculate duration first
                        programDurationSeconds = endSecondsFromMidnightEST - startSecondsFromMidnightEST
                        
                        ' Set PLAYSTART and PLAYDURATION
                        ' startOfDaySeconds is EST midnight as UTC timestamp
                        ' Just add the EST seconds directly - TimeGrid will display in local time automatically
                        programNode.PLAYSTART = startOfDaySeconds + startSecondsFromMidnightEST
                        programNode.PLAYDURATION = programDurationSeconds
                        programNode.playStart = startOfDaySeconds + startSecondsFromMidnightEST
                        programNode.playDuration = programDurationSeconds
                        
                        ' Debug: Log calculated timestamp for first few programs
                        if channelNode.getChildCount() < 5
                            print "TVGuideScreen.brs - [buildTimeGridContent]   API time: " + show.start + " EST"
                            print "TVGuideScreen.brs - [buildTimeGridContent]   Seconds from midnight EST: " + startSecondsFromMidnightEST.ToStr()
                            print "TVGuideScreen.brs - [buildTimeGridContent]   PLAYSTART timestamp: " + programNode.PLAYSTART.ToStr()
                            
                            debugProgramTime = CreateObject("roDateTime")
                            debugProgramTime.FromSeconds(programNode.PLAYSTART)
                            debugProgramTime.ToLocalTime()
                            print "TVGuideScreen.brs - [buildTimeGridContent]   >>> Will display at: " + debugProgramTime.GetHours().ToStr() + ":" + debugProgramTime.GetMinutes().ToStr() + " local"
                        end if
                        
                        ' Store display times
                        programNode.addFields({
                            startTime: show.start,
                            endTime: show.end
                        })
                    end if
                end if
                
                channelNode.appendChild(programNode)
            end for
        end if
        
        timeGridContent.appendChild(channelNode)
    end for
    
    ' Set content on TimeGrid
    m.timeGrid.content = timeGridContent
    
    print "TVGuideScreen.brs - [buildTimeGridContent] Added " + timeGridContent.getChildCount().ToStr() + " channels to TimeGrid"
    
    ' NOW set leftEdgeTargetTime AFTER content is set (SGDEX best practice)
    m.timeGrid.leftEdgeTargetTime = targetTime
    print "TVGuideScreen.brs - [buildTimeGridContent] Set leftEdgeTargetTime to: " + targetTime.ToStr()
    
    ' Debug: Show what time this timestamp represents
    debugTime = CreateObject("roDateTime")
    debugTime.FromSeconds(targetTime)
    print "TVGuideScreen.brs - [buildTimeGridContent] leftEdgeTargetTime as date: " + debugTime.ToISOString()
    print "TVGuideScreen.brs - [buildTimeGridContent] leftEdgeTargetTime hour: " + debugTime.GetHours().ToStr() + ":" + debugTime.GetMinutes().ToStr()
    
    ' Also log contentStartTime
    debugStart = CreateObject("roDateTime")
    debugStart.FromSeconds(m.timeGrid.contentStartTime)
    print "TVGuideScreen.brs - [buildTimeGridContent] contentStartTime as date: " + debugStart.ToISOString()
    print "TVGuideScreen.brs - [buildTimeGridContent] contentStartTime hour: " + debugStart.GetHours().ToStr() + ":" + debugStart.GetMinutes().ToStr()
    
    ' Auto-focus to current program for "Today"
    if m.dayOffset = 0
        autoFocusToCurrentProgram()
    end if
end sub

sub autoFocusToCurrentProgram()
    ' Focus on current time program when viewing "Today"
    if m.timeGrid = invalid or m.timeGrid.content = invalid then return
    
    content = m.timeGrid.content
    if content.getChildCount() = 0 then return
    
    channel = content.getChild(0)
    if channel = invalid or channel.getChildCount() = 0 then return
    
    ' Get current time as UTC timestamp (to match PLAYSTART which is in UTC)
    dateTimeUTC = CreateObject("roDateTime")
    currentTimeUTC = dateTimeUTC.AsSeconds()
    
    isNowProgramAvailable = false
    nowProgramIndex = 0
    
    ' Find program at current time - use uppercase PLAYSTART and PLAYDURATION
    for i = 0 to channel.getChildCount() - 1
        program = channel.getChild(i)
        programStart = program.PLAYSTART
        programDuration = program.PLAYDURATION
        if programStart = invalid then programStart = program.playStart
        if programDuration = invalid then programDuration = program.playDuration
        
        if programStart <= currentTimeUTC and (programStart + programDuration) >= currentTimeUTC
            isNowProgramAvailable = true
            nowProgramIndex = i
            exit for
        end if
    end for
    
    if isNowProgramAvailable
        print "TVGuideScreen.brs - [autoFocusToCurrentProgram] Focusing on current program at index: " + nowProgramIndex.ToStr()
        m.timeGrid.jumpToChannel = 0
        m.timeGrid.jumpToProgram = nowProgramIndex
    else
        print "TVGuideScreen.brs - [autoFocusToCurrentProgram] No current program found, focusing on first program"
        m.timeGrid.jumpToChannel = 0
        m.timeGrid.jumpToProgram = 0
        print "TVGuideScreen.brs - [autoFocusToCurrentProgram] Keeping TimeGrid at current time"
    end if
end sub

sub buildChannelList()
    print "TVGuideScreen.brs - [buildChannelList] Building channel list with logos"
    
    if m.channelsData = invalid or m.channelsData.Count() = 0
        print "TVGuideScreen.brs - [buildChannelList] No channels data"
        return
    end if
    
    ' Create content node for channel list
    channelContent = CreateObject("roSGNode", "ContentNode")
    
    for each channel in m.channelsData
        channelNode = CreateObject("roSGNode", "ContentNode")
        
        ' Get channel name - full name, not truncated
        channelName = "Unknown Channel"
        if channel.title <> invalid and channel.title <> ""
            channelName = channel.title
        else if channel.name <> invalid and channel.name <> ""
            channelName = channel.name
        end if
        
        channelNode.title = channelName
        
        ' Get channel logo
        logoUrl = ""
        if channel.images <> invalid
            if channel.images.poster <> invalid and channel.images.poster <> ""
                logoUrl = channel.images.poster
            else if channel.images.thumbnail <> invalid and channel.images.thumbnail <> ""
                logoUrl = channel.images.thumbnail
            end if
        else if channel.icon <> invalid and channel.icon <> ""
            ' Direct icon field (from raw API data)
            if Left(channel.icon, 4) = "http"
                logoUrl = channel.icon
            else
                logoUrl = "https://giatv.dineo.uk" + channel.icon
            end if
        end if
        
        if logoUrl <> ""
            channelNode.hdPosterUrl = logoUrl
            channelNode.SDPosterUrl = logoUrl
        end if
        
        ' Store channel data for later use
        if channel.id <> invalid
            channelNode.addFields({ channelId: channel.id })
        end if
        
        channelContent.appendChild(channelNode)
        print "TVGuideScreen.brs - [buildChannelList] Added channel: " + channelName + " with logo: " + logoUrl
    end for
    
    m.channelList.content = channelContent
    print "TVGuideScreen.brs - [buildChannelList] Added " + channelContent.getChildCount().ToStr() + " channels"
end sub

sub buildTimelineHeader()
    print "TVGuideScreen.brs - [buildTimelineHeader] Building timeline header"
    
    ' Use stored timeline start position
    startHour = m.timelineStartHour
    startMinute = m.timelineStartMinute
    
    ' If not yet initialized, calculate from current American Eastern Time
    if m.timelineStartTotalMinutes = 0
        ' Get current time in American Eastern Time
        dateTimeUTC = CreateObject("roDateTime")
        currentMonth = dateTimeUTC.GetMonth()
        
        ' Calculate American offset (EST or EDT)
        americanOffset = -18000 ' EST (UTC-5)
        if currentMonth >= 3 and currentMonth <= 10
            americanOffset = -14400 ' EDT (UTC-4)
        end if
        
        ' Convert to American time
        currentSecondsUTC = dateTimeUTC.AsSeconds()
        currentSecondsAmerican = currentSecondsUTC + americanOffset
        
        dateTimeAmerican = CreateObject("roDateTime")
        dateTimeAmerican.FromSeconds(currentSecondsAmerican)
        
        currentHour = dateTimeAmerican.GetHours()
        currentMinute = dateTimeAmerican.GetMinutes()
        
        ' Round to nearest 30 minutes
        if currentMinute < 30
            startMinute = 0
        else
            startMinute = 30
        end if
        startHour = currentHour
        
        m.timelineStartHour = startHour
        m.timelineStartMinute = startMinute
        m.timelineStartTotalMinutes = startHour * 60 + startMinute
        
        print "TVGuideScreen.brs - [buildTimelineHeader] Initialized timeline to American time: " + startHour.ToStr() + ":" + startMinute.ToStr()
    end if
    
    ' Remove existing time labels (keep the background rectangle)
    while m.timelineGroup.getChildCount() > 1
        m.timelineGroup.removeChildIndex(1)
    end while
    
    ' Time slot width: 1560px / 5 slots = 312px per slot
    slotWidth = 312
    m.timeSlotWidth = slotWidth
    m.pixelsPerMinute = slotWidth / 30
    
    for i = 0 to 4
        slotHour = startHour + Int((startMinute + (i * 30)) / 60)
        slotMinute = (startMinute + (i * 30)) mod 60
        
        ' Handle day overflow
        if slotHour >= 24 then slotHour = slotHour - 24
        
        ' Format time string in 12-hour American format (h:MM AM/PM)
        displayHour = slotHour
        ampm = "AM"
        if slotHour >= 12
            ampm = "PM"
            if slotHour > 12 then displayHour = slotHour - 12
        end if
        if displayHour = 0 then displayHour = 12
        
        minuteStr = slotMinute.ToStr()
        if slotMinute < 10 then minuteStr = "0" + minuteStr
        
        timeStr = displayHour.ToStr() + ":" + minuteStr + " " + ampm
        
        ' Create label: 18px font, #B0B8C4 color
        timeLabel = CreateObject("roSGNode", "Label")
        timeLabel.text = timeStr
        timeLabel.font = "font:SmallSystemFont"
        timeLabel.color = "#B0B8C4"
        timeLabel.width = slotWidth
        timeLabel.height = 60
        timeLabel.horizAlign = "center"
        timeLabel.vertAlign = "center"
        timeLabel.translation = [i * slotWidth, 0]
        
        m.timelineGroup.appendChild(timeLabel)
        
        ' Add vertical separator line: #2E5A8A (TV Guide design)
        if i > 0
            separator = CreateObject("roSGNode", "Rectangle")
            separator.width = 1
            separator.height = 60
            separator.color = "#2E5A8A"
            separator.translation = [i * slotWidth, 0]
            m.timelineGroup.appendChild(separator)
        end if
    end for
    
    print "TVGuideScreen.brs - [buildTimelineHeader] Created 5 time slots starting at " + startHour.ToStr() + ":" + startMinute.ToStr()
end sub

sub buildProgramGrid()
    print "TVGuideScreen.brs - [buildProgramGrid] Building variable-width program blocks"
    
    if m.programGridGroup = invalid then return
    if m.channelsData = invalid or m.channelsData.Count() = 0
        print "TVGuideScreen.brs - [buildProgramGrid] No channels data"
        return
    end if
    
    ' Use stored timeline position or calculate if not set
    if m.timelineStartTotalMinutes = 0
        ' Get current time in American Eastern Time
        dateTimeUTC = CreateObject("roDateTime")
        currentMonth = dateTimeUTC.GetMonth()
        
        ' Calculate American offset (EST or EDT)
        americanOffset = -18000 ' EST (UTC-5)
        if currentMonth >= 3 and currentMonth <= 10
            americanOffset = -14400 ' EDT (UTC-4)
        end if
        
        ' Convert to American time
        currentSecondsUTC = dateTimeUTC.AsSeconds()
        currentSecondsAmerican = currentSecondsUTC + americanOffset
        
        dateTimeAmerican = CreateObject("roDateTime")
        dateTimeAmerican.FromSeconds(currentSecondsAmerican)
        
        currentHour = dateTimeAmerican.GetHours()
        currentMinute = dateTimeAmerican.GetMinutes()
        
        if currentMinute < 30
            m.timelineStartMinute = 0
        else
            m.timelineStartMinute = 30
        end if
        m.timelineStartHour = currentHour
        m.timelineStartTotalMinutes = m.timelineStartHour * 60 + m.timelineStartMinute
        
        print "TVGuideScreen.brs - [buildProgramGrid] Initialized timeline to American time: " + m.timelineStartHour.ToStr() + ":" + m.timelineStartMinute.ToStr()
    end if
    
    ' Clear existing blocks
    while m.programGridGroup.getChildCount() > 0
        m.programGridGroup.removeChildIndex(0)
    end while
    
    m.programBlocksByChannel = []
    m.programRowGroups = []
    
    windowStart = m.timelineStartTotalMinutes
    windowEnd = windowStart + 150
    ' Load programs for extended window (300 minutes) to allow smoother navigation
    extendedWindowMinutes = 300
    programAreaWidth = m.timeSlotWidth * 5
    
    startChannel = m.channelWindowStart
    endChannelExclusive = startChannel + m.visibleChannelRows
    if endChannelExclusive > m.channelsData.Count()
        endChannelExclusive = m.channelsData.Count()
    end if
    
    visibleRow = 0
    for channelIdx = startChannel to endChannelExclusive - 1
        channel = m.channelsData[channelIdx]
        shows = channel.shows
        if shows = invalid then shows = []
        
        rowY = visibleRow * (m.rowHeight + m.rowSpacing)
        
        ' Create row container Group
        rowGroup = CreateObject("roSGNode", "Group")
        rowGroup.translation = [0, rowY]
        rowGroup.vertFocusAnimationStyle = "fixedFocus"
        m.programGridGroup.appendChild(rowGroup)
        m.programRowGroups.Push(rowGroup)
        
        ' Load programs for extended window (not just visible 150 min)
        relevantShows = getShowsInTimeWindow(shows, windowStart, extendedWindowMinutes)
        
        channelPrograms = []
        
        if relevantShows.Count() = 0
            ' Full-row "no info" block
            blockInfo = createProgramBlock("No Program Info", "", "", windowStart, windowEnd, 0, channelIdx, channel)
            rowGroup.appendChild(blockInfo.node)
            channelPrograms.Push(blockInfo)
        else
            for each show in relevantShows
                s = show.startMinutes
                e = show.endMinutes
                ' Don't clamp to visible window - create blocks for extended window
                if e > s
                    blockInfo = createProgramBlock(show.name, show.startTime, show.endTime, s, e, 0, channelIdx, channel)
                    ' Only add to scene graph if visible
                    if s < windowEnd
                        rowGroup.appendChild(blockInfo.node)
                    end if
                    channelPrograms.Push(blockInfo)
                end if
            end for
        end if
        
        m.programBlocksByChannel.Push(channelPrograms)
        visibleRow = visibleRow + 1
    end for
    
    ' Set initial focus on first program of first channel
    ' updateProgramFocus()
    
    print "TVGuideScreen.brs - [buildProgramGrid] Created " + m.programBlocksByChannel.Count().ToStr() + " channel rows with variable-width blocks"
end sub

function createProgramBlock(title as string, startTime as string, endTime as string, startMinutes as integer, endMinutes as integer, rowY as integer, channelIdx as integer, channel as object) as object
    windowStart = m.timelineStartTotalMinutes
    
    ' Calculate position relative to visible window
    xPos = (startMinutes - windowStart) * m.pixelsPerMinute
    blockWidth = (endMinutes - startMinutes) * m.pixelsPerMinute
    
    ' Clamp xPos to ensure blocks don't go into negative space (overlapping channels)
    if xPos < 0
        ' Adjust width if program starts before visible window
        blockWidth = blockWidth + xPos
        xPos = 0
        ' Ensure width is still positive after adjustment
        if blockWidth < 10 then blockWidth = 10
    end if
    
    ' Minimum width for very short programs
    if blockWidth < 60 then blockWidth = 60
    
    block = CreateObject("roSGNode", "Group")
    block.translation = [xPos, rowY]
    
    bg = CreateObject("roSGNode", "Rectangle")
    bg.width = Int(blockWidth) - 4
    bg.height = m.rowHeight - 4
    bg.color = "#1F3B5C"
    bg.translation = [2, 2]
    block.appendChild(bg)
    
    ' Add divider at bottom
    divider = CreateObject("roSGNode", "Rectangle")
    divider.width = Int(blockWidth)
    divider.height = 1
    divider.color = "#2E5A8A"
    divider.opacity = 0.22
    divider.translation = [0, m.rowHeight - 1]
    block.appendChild(divider)
    
    titleLabel = CreateObject("roSGNode", "Label")
    titleLabel.text = title
    titleLabel.translation = [18, 20]
    titleLabel.width = Int(blockWidth) - 36
    titleLabel.height = 30
    titleLabel.font = "font:SmallBoldSystemFont"
    titleLabel.color = "#FFFFFF"
    titleLabel.maxLines = 1
    block.appendChild(titleLabel)
    
    timeLabel = CreateObject("roSGNode", "Label")
    timeText = ""
    ' Convert times to American 12-hour format
    if startTime <> ""
        timeText = convertTo12HourFormat(startTime)
    end if
    if endTime <> ""
        if timeText <> "" then timeText = timeText + " – "
        timeText = timeText + convertTo12HourFormat(endTime)
    end if
    timeLabel.text = timeText
    timeLabel.translation = [18, 56]
    timeLabel.width = Int(blockWidth) - 36
    timeLabel.height = 22
    timeLabel.font = "font:TinySystemFont"
    timeLabel.color = "#B0B8C4"
    timeLabel.maxLines = 1
    block.appendChild(timeLabel)
    
    ' Get channel info for playback
    channelTitle = ""
    if channel.title <> invalid
        channelTitle = channel.title
    else if channel.name <> invalid
        channelTitle = channel.name
    end if
    
    return {
        node: block,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        channelIdx: channelIdx,
        channelTitle: channelTitle,
        title: title
    }
end function

function getShowsInTimeWindow(shows as object, startMinutes as integer, windowMinutes as integer) as object
    relevantShows = []
    endMinutes = startMinutes + windowMinutes
    
    if shows = invalid or shows.Count() = 0
        return relevantShows
    end if
    
    for each show in shows
        if show.start <> invalid
            ' Parse show start time
            startParts = show.start.Split(":")
            if startParts.Count() >= 2
                showStartHour = Val(startParts[0])
                showStartMinute = Val(startParts[1])
                showStartTotal = showStartHour * 60 + showStartMinute
                
                ' Parse show end time
                showEndTotal = showStartTotal + 60 ' Default 1 hour
                if show.end <> invalid
                    endParts = show.end.Split(":")
                    if endParts.Count() >= 2
                        showEndHour = Val(endParts[0])
                        showEndMinute = Val(endParts[1])
                        showEndTotal = showEndHour * 60 + showEndMinute
                        ' Handle shows spanning midnight
                        if showEndTotal < showStartTotal
                            showEndTotal = showEndTotal + 1440
                        end if
                    end if
                else if show.duration <> invalid
                    ' Use duration if end time not available
                    durationVal = 60
                    if Type(show.duration) = "roString" or Type(show.duration) = "String"
                        durationVal = Val(show.duration)
                    else
                        durationVal = show.duration
                    end if
                    showEndTotal = showStartTotal + durationVal
                end if
                
                ' Check if show overlaps with our window
                if showEndTotal > startMinutes and showStartTotal < endMinutes
                    ' Add show with calculated times
                    showInfo = {
                        name: show.name,
                        startMinutes: showStartTotal,
                        endMinutes: showEndTotal,
                        startTime: show.start,
                        endTime: show.end,
                        description: show.longdescription
                    }
                    relevantShows.Push(showInfo)
                end if
            end if
        end if
    end for
    
    return relevantShows
end function


sub updateCurrentTimeIndicator()
    ' Calculate position of current time indicator using American Eastern Time
    dateTimeUTC = CreateObject("roDateTime")
    currentMonth = dateTimeUTC.GetMonth()
    
    ' Calculate American offset (EST or EDT)
    americanOffset = -18000 ' EST (UTC-5)
    if currentMonth >= 3 and currentMonth <= 10
        americanOffset = -14400 ' EDT (UTC-4)
    end if
    
    ' Convert to American time
    currentSecondsUTC = dateTimeUTC.AsSeconds()
    currentSecondsAmerican = currentSecondsUTC + americanOffset
    
    dateTimeAmerican = CreateObject("roDateTime")
    dateTimeAmerican.FromSeconds(currentSecondsAmerican)
    
    currentHour = dateTimeAmerican.GetHours()
    currentMinute = dateTimeAmerican.GetMinutes()
    currentTotalMinutes = currentHour * 60 + currentMinute
    
    ' Only show current time indicator for Today
    if m.dayOffset <> invalid and m.dayOffset <> 0
        m.currentTimeIndicator.visible = false
        return
    end if

    ' Calculate offset from timeline start (if set)
    if m.timelineStartTotalMinutes <> invalid and m.timelineStartTotalMinutes > 0
        minuteOffset = currentTotalMinutes - m.timelineStartTotalMinutes
        
        ' Only show indicator if within visible range (150 minutes = 2.5 hours)
        if minuteOffset >= 0 and minuteOffset <= 150
            pixelOffset = minuteOffset * m.pixelsPerMinute
            ' Position: grid starts at x=360, indicator starts at y=201 (below timeline)
            m.currentTimeIndicator.translation = [360 + pixelOffset, 201]
            m.currentTimeIndicator.visible = true
        else
            m.currentTimeIndicator.visible = false
        end if
    else
 
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "TVGuideScreen.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr() + ", FocusArea: " + m.focusArea
    
    if not press then return false
    
    if key = "up"
        if m.focusArea = "days"
            return false
        end if
        
        if m.focusArea = "timegrid" and m.daySelector <> invalid
            ' Check if at top of TimeGrid - go to day selector
            ' TimeGrid will handle this automatically, we just check if we should intercept
            ' For now, let TimeGrid handle up navigation
            return false
        end if
        
        return false
    else if key = "down"
        if m.focusArea = "days"
            m.focusArea = m.lastFocusAreaBeforeDays
            if m.timeGrid <> invalid
                m.timeGrid.setFocus(true)
            end if
            return true
        end if
        
        return false
    else if key = "back"
        if m.focusArea = "days"
            m.focusArea = m.lastFocusAreaBeforeDays
            if m.timeGrid <> invalid
                m.timeGrid.setFocus(true)
            end if
            return true
        else if m.focusArea = "timegrid"
            ' Return focus to navigation bar
            print "TVGuideScreen.brs - [onKeyEvent] BACK pressed from TimeGrid - returning focus to navigation"
            returnFocusToNavigation()
            return true
        end if
        ' Let parent handle back navigation (return to home)
        return false
    else if key = "OK"
        ' TimeGrid will trigger programSelected event
        return false
    end if
    
    return false
end function

sub checkAndScrollTimelineForFocusedProgram()
    ' Auto-scroll timeline if focused program is outside visible window
    if m.focusedProgramBlock = invalid then return
    
    progStart = m.focusedProgramBlock.startMinutes
    progEnd = m.focusedProgramBlock.endMinutes
    windowStart = m.timelineStartTotalMinutes
    windowEnd = windowStart + 150
    
    ' If program starts past 75% of visible window, scroll forward
    scrollThreshold = windowStart + 100 ' scroll when past 100 minutes (2/3 of window)
    if progStart >= scrollThreshold
        ' Scroll forward by 60 minutes (2 time slots)
        newStart = windowStart + 60
        if newStart > 1290 then newStart = 1290
        scrollToTime(newStart)
    else if progEnd <= windowStart
        ' If program ends before visible window, scroll back
        newStart = windowStart - 60
        if newStart < 0 then newStart = 0
        scrollToTime(newStart)
    end if
end sub

sub scrollToTime(targetMinutes as integer)
    ' Clamp within day
    if targetMinutes < 0 then targetMinutes = 0
    if targetMinutes > 1290 then targetMinutes = 1290 ' 1440 - 150
    
    ' Round to 30-minute boundary
    targetMinutes = Int(targetMinutes / 30) * 30
    
    m.timelineStartTotalMinutes = targetMinutes
    m.timelineStartHour = Int(targetMinutes / 60) mod 24
    m.timelineStartMinute = targetMinutes mod 60
    
    ' Reset program index to first program after timeline scroll
    m.focusedProgramIndex = 0
    
    buildTimelineHeader()
    buildProgramGrid()
    updateCurrentTimeIndicator()
end sub

sub scrollTimeline(direction as integer)
    ' direction: 1 = forward (later), -1 = backward (earlier)
    ' Each scroll moves by 30 minutes
    scrollAmount = 30 * direction
    
    ' Calculate new timeline start
    newStartMinutes = m.timelineStartTotalMinutes + scrollAmount
    
    ' Clamp within a single day window (24h coverage, 5 visible 30-min slots = 150 minutes)
    minStartMinutes = 0
    maxStartMinutes = 1440 - 150
    if newStartMinutes < minStartMinutes
        newStartMinutes = minStartMinutes
    end if
    if newStartMinutes > maxStartMinutes
        newStartMinutes = maxStartMinutes
    end if
    
    ' Update timeline start
    m.timelineStartTotalMinutes = newStartMinutes
    m.timelineStartHour = Int(newStartMinutes / 60) mod 24
    m.timelineStartMinute = newStartMinutes mod 60
    
    print "TVGuideScreen.brs - [scrollTimeline] New timeline start: " + m.timelineStartHour.ToStr() + ":" + m.timelineStartMinute.ToStr()
    
    ' Rebuild the timeline and program grid
    buildTimelineHeader()
    buildProgramGrid()
    updateCurrentTimeIndicator()
end sub

'' Obsolete - now handled by onProgramSelected()

sub playChannel(channel as object)
    ' Safely get channel title
    channelTitle = "Unknown Channel"
    if channel.title <> invalid and channel.title <> ""
        channelTitle = channel.title
    else if channel.name <> invalid and channel.name <> ""
        channelTitle = channel.name
    end if
    
    print "TVGuideScreen.brs - [playChannel] Playing channel: " + channelTitle
    
    ' Get stream URL - check multiple sources
    streamUrl = ""
    
    ' First try sources object
    if channel.sources <> invalid
        if channel.sources.primary <> invalid and channel.sources.primary <> ""
            streamUrl = channel.sources.primary
        else if channel.sources.hls <> invalid and channel.sources.hls <> ""
            streamUrl = channel.sources.hls
        end if
    end if
    
    ' Fallback to direct http field (raw API format)
    if streamUrl = "" and channel.http <> invalid and channel.http <> ""
        streamUrl = channel.http
    end if
    
    if streamUrl = ""
        print "TVGuideScreen.brs - [playChannel] No stream URL available for this channel"
        return
    end if
    
    print "TVGuideScreen.brs - [playChannel] Stream URL: " + streamUrl
    
    ' Play in the preview video player
    if m.videoPlayer <> invalid
        ' Create content node for video
        videoContent = CreateObject("roSGNode", "ContentNode")
        videoContent.url = streamUrl
        videoContent.title = channelTitle
        videoContent.streamFormat = "hls"
        
        ' Set content and play
        m.videoPlayer.content = videoContent
        m.videoPlayer.control = "play"
        
        ' Hide status message
        if m.videoPlayerStatus <> invalid
            m.videoPlayerStatus.visible = false
        end if
        
        print "TVGuideScreen.brs - [playChannel] Started playback in preview player"
    else
        print "TVGuideScreen.brs - [playChannel] Video player not available"
    end if
    
    ' Also notify parent to play video in full screen (optional)
    ' Uncomment if you want both preview and full screen option
    ' m.top.getScene().callFunc("playVideo", {
    '     url: streamUrl,
    '     title: channelTitle,
    '     contentType: "live"
    ' })
end sub

function convertTo12HourFormat(time24 as string) as string
    ' Convert 24-hour format (HH:MM) to 12-hour American format (h:MM AM/PM)
    if time24 = invalid or time24 = ""
        return ""
    end if
    
    parts = time24.Split(":")
    if parts.Count() < 2
        return time24 ' Return as-is if not in expected format
    end if
    
    hour = Val(parts[0])
    minute = Val(parts[1])
    
    ' Convert to 12-hour format
    ampm = "AM"
    displayHour = hour
    if hour >= 12
        ampm = "PM"
        if hour > 12 then displayHour = hour - 12
    end if
    if displayHour = 0 then displayHour = 12
    
    ' Format minutes with leading zero
    minuteStr = minute.ToStr()
    if minute < 10 then minuteStr = "0" + minuteStr
    
    return displayHour.ToStr() + ":" + minuteStr + " " + ampm
end function

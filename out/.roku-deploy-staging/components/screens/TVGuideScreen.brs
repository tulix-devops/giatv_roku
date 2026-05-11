sub init()
    ' ==================== TV GUIDE VERSION CONTROL ====================
    ' Set to true to use new Channel Browser layout (V2)
    ' Set to false to use original TimeGrid layout (V1)
    m.useTVGuideV2 = true
    ' ==================================================================
    
    m.background = m.top.findNode("background")
    m.headerTitle = m.top.findNode("headerTitle")
    m.headerTime = m.top.findNode("headerTime")
    m.headerLogo = m.top.findNode("headerLogo")
    m.headerDivider = m.top.findNode("headerDivider")

    ' New header elements (matching dynamic_content_screen)
    m.screenHeaderGroup = m.top.findNode("screenHeaderGroup")
    m.screenTabName = m.top.findNode("screenTabName")
    m.screenTimeLabel = m.top.findNode("screenTimeLabel")
    m.screenBrandIcon = m.top.findNode("screenBrandIcon")

    m.daySelector = m.top.findNode("daySelector")
    m.timeGrid = m.top.findNode("timeGrid")

    m.loadingGroup = m.top.findNode("loadingGroup")
    m.v2LoadingGroup = m.top.findNode("v2LoadingGroup")
    m.noContentLabel = m.top.findNode("noContentLabel")

    ' Channel logo and program details
    m.channelLogoImage = m.top.findNode("channelLogoImage")
    m.channelLogoName = m.top.findNode("channelLogoName")
    m.currentTimestamp = m.top.findNode("currentTimestamp")
    m.programTitle = m.top.findNode("programTitle")
    m.programTime = m.top.findNode("programTime")
    m.programDescription = m.top.findNode("programDescription")
    
    ' Set up clock timer for header
    m.clockTimer = CreateObject("roSGNode", "Timer")
    m.clockTimer.duration = 60
    m.clockTimer.repeat = true
    m.clockTimer.observeField("fire", "updateClockDisplay")
    
    ' Update clock immediately and start timer
    updateClockDisplay()
    m.clockTimer.control = "start"
    
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
    
    ' Get animation references
    m.timeGridMoveDownAnimation = m.top.findNode("timeGridMoveDownAnimation")
    m.timeGridMoveUpAnimation = m.top.findNode("timeGridMoveUpAnimation")
    m.programDetailsFadeInAnimation = m.top.findNode("programDetailsFadeInAnimation")
    m.programDetailsFadeOutAnimation = m.top.findNode("programDetailsFadeOutAnimation")
    m.videoPlayerFadeInAnimation = m.top.findNode("videoPlayerFadeInAnimation")
    m.videoPlayerFadeOutAnimation = m.top.findNode("videoPlayerFadeOutAnimation")
    m.channelLogoFadeInAnimation = m.top.findNode("channelLogoFadeInAnimation")
    m.channelLogoFadeOutAnimation = m.top.findNode("channelLogoFadeOutAnimation")
    m.programDetailsGroup = m.top.findNode("programDetailsGroup")
    m.videoPlayerGroup = m.top.findNode("videoPlayerGroup")
    m.channelLogoGroup = m.top.findNode("channelLogoGroup")
    m.backHintGroup = m.top.findNode("backHintGroup")
    
    ' Track animation state
    m.isDetailViewOpen = false
    m.isClosingDetailView = false
    m.timeGridHasBeenFocused = false
    
    ' Track currently playing program for full screen detection
    m.currentPlayingChannelIndex = -1
    m.currentPlayingProgramIndex = -1
    
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
    
    ' ==================== TV GUIDE V2 INITIALIZATION ====================
    if m.useTVGuideV2 = true
        initTVGuideV2()
    end if
    ' ====================================================================
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
    showLoading()

    dateTimeUTC = CreateObject("roDateTime")
    dateTimeLocal = CreateObject("roDateTime")
    dateTimeLocal.ToLocalTime()
    
    currentMonth = dateTimeUTC.GetMonth()
    americanOffsetFromUTC = -18000
    if currentMonth >= 3 and currentMonth <= 10
        americanOffsetFromUTC = -14400
    end if
    
    currentSecondsEST = dateTimeUTC.AsSeconds() + americanOffsetFromUTC
    dateTimeEST = CreateObject("roDateTime")
    dateTimeEST.FromSeconds(currentSecondsEST)
    
    localDay = dateTimeLocal.GetDayOfMonth()
    estDay = dateTimeEST.GetDayOfMonth()
    dayDifference = estDay - localDay
    apiDayOffset = m.dayOffset + dayDifference

    m.tvGuideApiTask = CreateObject("roSGNode", "TVGuideApi")
    if m.tvGuideApiTask = invalid
        print "TVGuideScreen.brs - ERROR: Failed to create TVGuideApi task"
        hideLoading()
        return
    end if

    m.tvGuideApiTask.observeField("responseData", "onTVGuideDataReceived")
    m.tvGuideApiTask.observeField("errorMessage", "onTVGuideError")
    m.tvGuideApiTask.dayOffset = apiDayOffset
    m.tvGuideApiTask.control = "run"
end sub

' Called by home_scene when this screen is shown
function loadContentForType() as boolean
    if m.dataLoaded = true and m.channelsData <> invalid and m.channelsData.Count() > 0
        return true
    end if
    
    loadTVGuideForSelectedDay()
    return true
end function

sub onTVGuideDataReceived()
    if m.tvGuideApiTask = invalid
        hideLoading()
        return
    end if
    
    responseData = m.tvGuideApiTask.responseData
    if responseData = invalid or responseData = ""
        if m.noContentLabel <> invalid then
            m.noContentLabel.visible = true
        end if
        hideLoading()
        return
    end if
    
    parsedData = ParseJson(responseData)
    if parsedData = invalid
        print "TVGuideScreen.brs - ERROR: Failed to parse JSON"
        if m.noContentLabel <> invalid then
            m.noContentLabel.visible = true
        end if
        hideLoading()
        return
    end if
    
    m.dataLoaded = true
    loadTVGuideData(parsedData)
end sub

sub onTVGuideError()
    print "TVGuideScreen.brs - ERROR: " + m.tvGuideApiTask.errorMessage
    if m.noContentLabel <> invalid then
        m.noContentLabel.visible = true
    end if
    hideLoading()
end sub

sub onContentTypeIdChanged()
    if m.top.contentTypeId = 17
        loadContentForType()
    end if
end sub

sub onVisibleChanged()
    if m.top.visible = true
        updateHeaderTime()
        m.focusArea = "timegrid"
        
        if m.timeGrid <> invalid and m.timeGrid.hasFocus()
            channelIndex = m.timeGrid.channelFocused
            programIndex = m.timeGrid.programFocused
            if channelIndex <> invalid and programIndex <> invalid and programIndex >= 0
                updateFocusedItemDetails(channelIndex, programIndex, false)
            end if
        end if
    else
        if m.videoPlayer <> invalid
            m.videoPlayer.control = "stop"
        end if
    end if
end sub

sub onExplicitFocusRequested()
    print "TVGuideScreen.brs - [onExplicitFocusRequested] Explicit focus requested"
    if m.top.explicitContentFocusRequested > 0
        ' V2 handling
        if m.useTVGuideV2 = true
            ' Restore focus to the area that had it before (programs or channels)
            if m.v2FocusArea = "programs" and m.v2ProgramRow <> invalid
                m.v2ProgramRow.setFocus(true)
                print "TVGuideScreen.brs - [onExplicitFocusRequested] V2 Program row focused (restored)"
            else if m.v2ChannelList <> invalid
                m.v2ChannelList.setFocus(true)
                m.v2FocusArea = "channels"
                print "TVGuideScreen.brs - [onExplicitFocusRequested] V2 Channel list focused"
            end if
            m.top.explicitContentFocusRequested = 0
            return
        end if
        
        ' V1 handling (original)
        if m.timeGrid <> invalid
            m.timeGridHasBeenFocused = true
            m.focusArea = "timegrid"
            m.timeGrid.setFocus(true)
            print "TVGuideScreen.brs - [onExplicitFocusRequested] TimeGrid focused"

            if m.isDetailViewOpen = false and m.isClosingDetailView = false
                print "TVGuideScreen.brs - [onExplicitFocusRequested] Triggering layout transition"
                triggerLayoutTransition()
            end if
        end if
        m.top.explicitContentFocusRequested = 0
    end if
end sub

sub onChannelFocused()
    if m.timeGrid = invalid then return
    
    channelIndex = m.timeGrid.channelFocused
    programIndex = m.timeGrid.programFocused
    
    if channelIndex <> invalid and programIndex <> invalid
        if m.isDetailViewOpen = true
            ' On channel focus change, update details only (not video player)
            updateFocusedItemDetails(channelIndex, programIndex, false)
        end if
    end if
end sub

sub onProgramFocused()
    if m.timeGrid = invalid then return

    channelIndex = m.timeGrid.channelFocused
    programIndex = m.timeGrid.programFocused

    print "TVGuideScreen.brs - [onProgramFocused] =========================================="
    print "TVGuideScreen.brs - [onProgramFocused] Channel: " + channelIndex.ToStr() + ", Program: " + programIndex.ToStr()
    print "TVGuideScreen.brs - [onProgramFocused] isDetailViewOpen: " + m.isDetailViewOpen.ToStr()

    if channelIndex = invalid or programIndex = invalid or programIndex < 0
        print "TVGuideScreen.brs - [onProgramFocused] Invalid indices"
        return
    end if

    ' Update details (title/description) when program focus changes and detail view is open
    ' DO NOT update video player on focus - only on SELECT
    if m.isDetailViewOpen = true
        print "TVGuideScreen.brs - [onProgramFocused] Detail view open, updating details (focus only, no video change)"
        updateFocusedItemDetails(channelIndex, programIndex, false)
    end if
end sub

sub triggerLayoutTransition()
    print "TVGuideScreen.brs - [triggerLayoutTransition] Opening detail view"
    m.isDetailViewOpen = true
    
    ' Manually adjust TimeGrid numRows for detail view (height animated)
    if m.timeGrid <> invalid
        m.timeGrid.numRows = 5
        print "TVGuideScreen.brs - [triggerLayoutTransition] TimeGrid set to 5 rows"
    end if
    
    if m.timeGridMoveDownAnimation <> invalid
        m.timeGridMoveDownAnimation.control = "start"
    end if
    
    ' Make program details visible and start fade-in animation
    if m.programDetailsGroup <> invalid
        m.programDetailsGroup.visible = true
        if m.programDetailsFadeInAnimation <> invalid
            m.programDetailsFadeInAnimation.control = "start"
        else
            m.programDetailsGroup.opacity = 1.0
        end if
    end if
    
    ' Make video player visible and start fade-in animation
    if m.videoPlayerGroup <> invalid
        m.videoPlayerGroup.visible = true
        if m.videoPlayerFadeInAnimation <> invalid
            m.videoPlayerFadeInAnimation.control = "start"
        else
            m.videoPlayerGroup.opacity = 1.0
        end if
    end if
    
    ' Make channel logo visible and start fade-in animation
    if m.channelLogoGroup <> invalid
        m.channelLogoGroup.visible = true
        if m.channelLogoFadeInAnimation <> invalid
            m.channelLogoFadeInAnimation.control = "start"
        else
            m.channelLogoGroup.opacity = 1.0
        end if
    end if
    
    ' Make back hint visible with fade-in
    if m.backHintGroup <> invalid
        m.backHintGroup.visible = true
        m.backHintGroup.opacity = 1.0
    end if
    
    ' Wait a moment for TimeGrid focus to stabilize, then update details
    m.detailUpdateTimer = CreateObject("roSGNode", "Timer")
    m.detailUpdateTimer.duration = 0.15
    m.detailUpdateTimer.repeat = false
    m.detailUpdateTimer.observeField("fire", "onInitialDetailUpdate")
    m.detailUpdateTimer.control = "start"
end sub

sub onInitialDetailUpdate()
    print "TVGuideScreen.brs - [onInitialDetailUpdate] Updating details after layout transition"
    if m.timeGrid <> invalid
        channelIndex = m.timeGrid.channelFocused
        programIndex = m.timeGrid.programFocused
        print "TVGuideScreen.brs - [onInitialDetailUpdate] Channel: " + channelIndex.ToStr() + ", Program: " + programIndex.ToStr()
        if channelIndex <> invalid and programIndex <> invalid and programIndex >= 0
            ' Initial detail update: show details but don't start video yet (wait for SELECT)
            updateFocusedItemDetails(channelIndex, programIndex, false)
        end if
    end if
end sub

sub closeDetailView()
    print "TVGuideScreen.brs - [closeDetailView] Closing detail view"
    m.isClosingDetailView = true
    m.isDetailViewOpen = false
    
    ' Reset currently playing program tracking
    m.currentPlayingChannelIndex = -1
    m.currentPlayingProgramIndex = -1
    print "TVGuideScreen.brs - [closeDetailView] Reset playing program tracking"
    
    if m.videoPlayer <> invalid
        m.videoPlayer.control = "stop"
    end if
    
    ' Manually restore TimeGrid numRows (height animated)
    if m.timeGrid <> invalid
        m.timeGrid.numRows = 12
        print "TVGuideScreen.brs - [closeDetailView] TimeGrid restored to 12 rows"
    end if
    
    if m.programDetailsFadeOutAnimation <> invalid
        m.programDetailsFadeOutAnimation.control = "start"
    end if
    
    if m.videoPlayerFadeOutAnimation <> invalid
        m.videoPlayerFadeOutAnimation.control = "start"
    end if
    
    if m.channelLogoFadeOutAnimation <> invalid
        m.channelLogoFadeOutAnimation.control = "start"
    end if
    
    ' Hide back hint group
    if m.backHintGroup <> invalid
        m.backHintGroup.visible = false
        m.backHintGroup.opacity = 0.0
    end if
    
    if m.timeGridMoveUpAnimation <> invalid
        m.timeGridMoveUpAnimation.control = "start"
    end if
    
    if m.timeGrid <> invalid
        m.timeGrid.setFocus(true)
    end if
    
    m.closeAnimationTimer = CreateObject("roSGNode", "Timer")
    m.closeAnimationTimer.duration = 0.5
    m.closeAnimationTimer.repeat = false
    m.closeAnimationTimer.observeField("fire", "onCloseAnimationComplete")
    m.closeAnimationTimer.control = "start"
end sub

sub onCloseAnimationComplete()
    if m.programDetailsGroup <> invalid
        m.programDetailsGroup.visible = false
        m.programDetailsGroup.opacity = 0.0
    end if

    if m.videoPlayerGroup <> invalid
        m.videoPlayerGroup.visible = false
        m.videoPlayerGroup.opacity = 0.0
    end if

    if m.channelLogoGroup <> invalid
        m.channelLogoGroup.visible = false
        m.channelLogoGroup.opacity = 0.0
    end if
    
    if m.backHintGroup <> invalid
        m.backHintGroup.visible = false
        m.backHintGroup.opacity = 0.0
    end if
    
    if m.backHintGroup <> invalid
        m.backHintGroup.visible = false
        m.backHintGroup.opacity = 0.0
    end if
    
    m.isClosingDetailView = false
end sub

sub updateFocusedItemDetails(channelIndex as Integer, programIndex as Integer, updateVideoPlayer as Boolean)
    print "TVGuideScreen.brs - [updateFocusedItemDetails] ========== UPDATING DETAILS =========="
    print "TVGuideScreen.brs - [updateFocusedItemDetails] Channel index: " + channelIndex.ToStr()
    print "TVGuideScreen.brs - [updateFocusedItemDetails] Program index: " + programIndex.ToStr()
    print "TVGuideScreen.brs - [updateFocusedItemDetails] Update video player: " + updateVideoPlayer.ToStr()
    
    ' Update channel logo and program details
    content = m.timeGrid.content
    if content = invalid
        print "TVGuideScreen.brs - [updateFocusedItemDetails] ERROR: TimeGrid content is invalid"
        return
    end if

    channelNode = content.GetChild(channelIndex)
    if channelNode = invalid
        print "TVGuideScreen.brs - [updateFocusedItemDetails] ERROR: Channel node is invalid at index " + channelIndex.ToStr()
        return
    end if
    
    print "TVGuideScreen.brs - [updateFocusedItemDetails] Channel title: " + channelNode.title
    print "TVGuideScreen.brs - [updateFocusedItemDetails] Channel has " + channelNode.getChildCount().ToStr() + " programs"

    program = channelNode.GetChild(programIndex)
    if program = invalid
        print "TVGuideScreen.brs - [updateFocusedItemDetails] ERROR: Program is invalid at index " + programIndex.ToStr()
        return
    end if
    
    print "TVGuideScreen.brs - [updateFocusedItemDetails] Program title: " + program.title

    ' Get original channel data from m.channelsData for stream URL
    originalChannel = invalid
    originalProgram = invalid
    if m.channelsData <> invalid and channelIndex >= 0 and channelIndex < m.channelsData.Count()
        originalChannel = m.channelsData[channelIndex]
        ' Also get the original program data which may have a stream URL
        if originalChannel.shows <> invalid and programIndex >= 0 and programIndex < originalChannel.shows.Count()
            originalProgram = originalChannel.shows[programIndex]
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Found original program data"
        else
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Original program data not found"
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
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Set programTitle.text to: " + program.title
        else
            m.programTitle.text = "No Title"
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Set programTitle.text to: No Title"
        end if
    else
        print "TVGuideScreen.brs - [updateFocusedItemDetails] ERROR: m.programTitle is invalid"
    end if
    
    ' Update program time (start - end)
    if m.programTime <> invalid
        ' Get playStart and playDuration
        playStartTime = program.PLAYSTART
        playDurationTime = program.PLAYDURATION
        if playStartTime = invalid then playStartTime = program.playStart
        if playDurationTime = invalid then playDurationTime = program.playDuration
        
        print "TVGuideScreen.brs - [updateFocusedItemDetails] playStartTime: " + playStartTime.ToStr()
        print "TVGuideScreen.brs - [updateFocusedItemDetails] playDurationTime: " + playDurationTime.ToStr()
        
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
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Set programTime.text to: " + timeText
        else
            m.programTime.text = ""
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Set programTime.text to empty (invalid times)"
        end if
    else
        print "TVGuideScreen.brs - [updateFocusedItemDetails] ERROR: m.programTime is invalid"
    end if
    
    ' Update program description
    if m.programDescription <> invalid
        if program.description <> invalid and program.description <> ""
            m.programDescription.text = program.description
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Set programDescription.text (length: " + Len(program.description).ToStr() + ")"
        else
            m.programDescription.text = "No description available"
            print "TVGuideScreen.brs - [updateFocusedItemDetails] Set programDescription.text to: No description available"
        end if
    else
        print "TVGuideScreen.brs - [updateFocusedItemDetails] ERROR: m.programDescription is invalid"
    end if
    
    ' Only update video player if explicitly requested (on SELECT, not on FOCUS)
    if updateVideoPlayer = true and originalChannel <> invalid
        print "TVGuideScreen.brs - [updateFocusedItemDetails] Updating video player preview"
        playChannelPreview(originalChannel, originalProgram)
        
        ' Store currently playing program for full screen detection
        m.currentPlayingChannelIndex = channelIndex
        m.currentPlayingProgramIndex = programIndex
        print "TVGuideScreen.brs - [updateFocusedItemDetails] Stored playing program: [" + channelIndex.ToStr() + ", " + programIndex.ToStr() + "]"
    else
        print "TVGuideScreen.brs - [updateFocusedItemDetails] Skipping video player update (focus only)"
    end if
end sub

sub playChannelPreview(channel as object, program as object)
    if m.videoPlayer = invalid then return
    
    channelTitle = "Unknown Channel"
    if channel.title <> invalid and channel.title <> ""
        channelTitle = channel.title
    else if channel.name <> invalid and channel.name <> ""
        channelTitle = channel.name
    end if
    
    streamUrl = ""
    
    if program <> invalid and program.url <> invalid and program.url <> ""
        streamUrl = program.url
    end if
    
    if streamUrl = "" and channel.stream_url <> invalid and channel.stream_url <> ""
        streamUrl = channel.stream_url
    end if
    
    if streamUrl = "" and channel.sources <> invalid
        if channel.sources.primary <> invalid and channel.sources.primary <> ""
            streamUrl = channel.sources.primary
        else if channel.sources.hls <> invalid and channel.sources.hls <> ""
            streamUrl = channel.sources.hls
        end if
    end if
    
    if streamUrl = "" and channel.http <> invalid and channel.http <> ""
        streamUrl = channel.http
    end if
    
    if streamUrl = "" and channel.url <> invalid and channel.url <> ""
        streamUrl = channel.url
    end if
    
    if streamUrl = ""
        if m.videoPlayerStatus <> invalid
            m.videoPlayerStatus.text = channelTitle + Chr(10) + Chr(10) + "Stream preview not available" + Chr(10) + "Select to watch full screen"
            m.videoPlayerStatus.visible = true
        end if
        m.videoPlayer.control = "stop"
        return
    end if
    
    ' Parse URL for credentials
    urlParts = parseUrlCredentials(streamUrl)
    finalUrl = streamUrl
    if urlParts.hasCredentials
        finalUrl = urlParts.cleanUrl
    end if
    
    ' Detect stream format
    detectedFormat = detectStreamFormat(finalUrl)
    
    ' For MPEG-TS with credentials, attach roHttpAgent
    if m.videoPlayer <> invalid and detectedFormat = "ts" and urlParts.hasCredentials
        agent = CreateObject("roHttpAgent")
        agent.AddHeader("Authorization", "Basic " + urlParts.basicAuth)
        m.videoPlayer.SetHttpAgent(agent)
    end if

    ' Create content node for video
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = finalUrl
    videoContent.title = channelTitle

    ' Set stream format (both variants)
    if detectedFormat <> "" then
        videoContent.streamformat = detectedFormat
        videoContent.StreamFormat = detectedFormat
    end if

    ' Disable transcoding for TV Guide streams
    videoContent.live = true
    videoContent.Live = true
    
    ' MPEG-TS specific
    if detectedFormat = "ts"
        videoContent.StreamStickyHttpRedirects = [true]
        if urlParts.hasCredentials
            videoContent.HttpHeaders = ["Authorization:Basic " + urlParts.basicAuth]
        end if
    end if

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
    if m.timeGrid = invalid then return
    
    print "TVGuideScreen.brs - [onProgramSelected] =========================================="
    print "TVGuideScreen.brs - [onProgramSelected] Program selected with OK button"
    
    channelIndex = m.timeGrid.channelSelected
    programIndex = m.timeGrid.programSelected
    
    print "TVGuideScreen.brs - [onProgramSelected] Selected: [" + channelIndex.ToStr() + ", " + programIndex.ToStr() + "]"
    print "TVGuideScreen.brs - [onProgramSelected] Currently playing: [" + m.currentPlayingChannelIndex.ToStr() + ", " + m.currentPlayingProgramIndex.ToStr() + "]"
    
    if channelIndex = invalid or programIndex = invalid
        print "TVGuideScreen.brs - [onProgramSelected] Invalid selection indices"
        return
    end if
    
    ' Check if user selected the SAME program that's already playing in small player
    isSameProgram = (channelIndex = m.currentPlayingChannelIndex and programIndex = m.currentPlayingProgramIndex)
    
    if isSameProgram
        print "TVGuideScreen.brs - [onProgramSelected] *** SAME PROGRAM - Opening full screen video player ***"
        
        ' Get program data for full screen playback
        content = m.timeGrid.content
        if content <> invalid
            channelNode = content.GetChild(channelIndex)
            if channelNode <> invalid
                program = channelNode.GetChild(programIndex)
                if program <> invalid
                    originalChannel = invalid
                    originalProgram = invalid
                    if m.channelsData <> invalid and channelIndex >= 0 and channelIndex < m.channelsData.Count()
                        originalChannel = m.channelsData[channelIndex]
                        if originalChannel.shows <> invalid and programIndex >= 0 and programIndex < originalChannel.shows.Count()
                            originalProgram = originalChannel.shows[programIndex]
                        end if
                    end if
                    
                    streamUrl = ""
                    
                    if originalProgram <> invalid and originalProgram.url <> invalid and originalProgram.url <> ""
                        streamUrl = originalProgram.url
                    end if
                    
                    if streamUrl = "" and originalChannel <> invalid
                        if originalChannel.stream_url <> invalid and originalChannel.stream_url <> ""
                            streamUrl = originalChannel.stream_url
                        else if originalChannel.sources <> invalid
                            if originalChannel.sources.primary <> invalid and originalChannel.sources.primary <> ""
                                streamUrl = originalChannel.sources.primary
                            else if originalChannel.sources.hls <> invalid and originalChannel.sources.hls <> ""
                                streamUrl = originalChannel.sources.hls
                            end if
                        else if originalChannel.http <> invalid and originalChannel.http <> ""
                            streamUrl = originalChannel.http
                        else if originalChannel.url <> invalid and originalChannel.url <> ""
                            streamUrl = originalChannel.url
                        end if
                    end if
                    
                    if streamUrl <> "" and streamUrl <> invalid
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
                        
                        thumbnailUrl = ""
                        if channelNode.HDSMALLICONURL <> invalid and channelNode.HDSMALLICONURL <> ""
                            thumbnailUrl = channelNode.HDSMALLICONURL
                        else if channelNode.HDPOSTERURL <> invalid and channelNode.HDPOSTERURL <> ""
                            thumbnailUrl = channelNode.HDPOSTERURL
                        end if
                        
                        videoData = {
                            contentUrl: streamUrl,
                            title: programTitle + " - " + channelTitle,
                            description: programDescription,
                            thumbnail: thumbnailUrl,
                            isLive: true
                        }
                        
                        print "TVGuideScreen.brs - [onProgramSelected] Opening full screen video player"
                        m.top.videoPlayRequested = videoData
                    end if
                end if
            end if
        end if
    else
        print "TVGuideScreen.brs - [onProgramSelected] *** DIFFERENT PROGRAM - Updating small video player only ***"
        
        ' Update small video player to the newly selected program
        if channelIndex <> invalid and programIndex <> invalid
            ' Update details AND video player (updateVideoPlayer = true)
            updateFocusedItemDetails(channelIndex, programIndex, true)
        end if
    end if
    
    print "TVGuideScreen.brs - [onProgramSelected] =========================================="
end sub

sub onVideoStateChanged()
    if m.videoPlayer = invalid then return
    
    state = m.videoPlayer.state
    
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
    print "TVGuideScreen.brs - [returnFocusToNavigation] Returning to navigation"
    m.timeGridHasBeenFocused = false
    m.isDetailViewOpen = false
    m.isClosingDetailView = false

    if m.videoPlayer <> invalid
        m.videoPlayer.control = "stop"
    end if

    ' Reset TimeGrid to initial state with header visible (12 rows at y=175)
    if m.timeGrid <> invalid
        m.timeGrid.translation = [0, 175]
        m.timeGrid.height = 905
        m.timeGrid.numRows = 12
        print "TVGuideScreen.brs - [returnFocusToNavigation] TimeGrid reset to 12 rows at [0, 175]"
    end if
    
    ' Ensure header is visible
    if m.screenHeaderGroup <> invalid
        m.screenHeaderGroup.visible = true
        print "TVGuideScreen.brs - [returnFocusToNavigation] Header made visible"
    end if

    if m.programDetailsGroup <> invalid
        m.programDetailsGroup.visible = false
        m.programDetailsGroup.opacity = 0.0
    end if
    if m.videoPlayerGroup <> invalid
        m.videoPlayerGroup.visible = false
        m.videoPlayerGroup.opacity = 0.0
    end if
    if m.channelLogoGroup <> invalid
        m.channelLogoGroup.visible = false
        m.channelLogoGroup.opacity = 0.0
    end if
    
    parentScene = m.top.getParent()
    maxDepth = 10
    depth = 0
    
    while parentScene <> invalid and depth < maxDepth
        depth = depth + 1
        
        navBar = parentScene.findNode("dynamic_navigation_bar")
        if navBar <> invalid
            navBar.navHasFocus = true
            navBar.setFocus(true)
            navBar.callFunc("focusUpdated")
            
            if not navBar.hasFocus()
                navBar.callFunc("forceFocus")
            end if
            return
        end if
        parentScene = parentScene.getParent()
    end while
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
    if m.useTVGuideV2 = true
        if m.v2LoadingGroup <> invalid
            m.v2LoadingGroup.visible = true
        end if
    else
        if m.loadingGroup <> invalid
            m.loadingGroup.visible = true
        end if
    end if
end sub

sub hideLoading()
    if m.useTVGuideV2 = true
        if m.v2LoadingGroup <> invalid
            m.v2LoadingGroup.visible = false
        end if
    else
        if m.loadingGroup <> invalid
            m.loadingGroup.visible = false
        end if
    end if
end sub

sub loadTVGuideData(tvGuideData as object)
    ' Route to appropriate version
    if m.useTVGuideV2 = true
        loadTVGuideDataV2(tvGuideData)
        return
    end if
    
    ' V1 Logic (original)
    if tvGuideData = invalid
        if m.noContentLabel <> invalid then
            m.noContentLabel.visible = true
        end if
        hideLoading()
        return
    end if
    
    if Type(tvGuideData) <> "roArray" or tvGuideData.Count() = 0
        if m.noContentLabel <> invalid then
            m.noContentLabel.visible = true
        end if
        hideLoading()
        return
    end if
    
    if tvGuideData.Count() = 1 and tvGuideData[0] <> invalid and tvGuideData[0].contents <> invalid
        m.channelsData = tvGuideData[0].contents
    else
        m.channelsData = tvGuideData
    end if
    
    buildTimeGridContent()
    hideLoading()
end sub

sub buildTimeGridContent()
    if m.timeGrid = invalid then return
    if m.channelsData = invalid then return
    if m.channelsData.Count() = 0 then return
    
    dateTimeUTC = CreateObject("roDateTime")
    dateTimeLocal = CreateObject("roDateTime")
    dateTimeLocal.ToLocalTime()
    
    currentSecondsUTC = dateTimeUTC.AsSeconds()
    currentSecondsLocal = dateTimeLocal.AsSeconds()
    localOffsetFromUTC = currentSecondsLocal - currentSecondsUTC
    
    currentMonth = dateTimeUTC.GetMonth()
    americanOffsetFromUTC = -18000
    if currentMonth >= 3 and currentMonth <= 10
        americanOffsetFromUTC = -14400
    end if
    
    timezoneOffsetESTtoLocal = localOffsetFromUTC - americanOffsetFromUTC
    
    currentHourLocal = dateTimeLocal.GetHours()
    currentMinuteLocal = dateTimeLocal.GetMinutes()
    currentSecondLocal = dateTimeLocal.GetSeconds()
    secondsSinceMidnightLocal = (currentHourLocal * 3600) + (currentMinuteLocal * 60) + currentSecondLocal
    
    currentSecondsEST = currentSecondsUTC + americanOffsetFromUTC
    dateTimeEST = CreateObject("roDateTime")
    dateTimeEST.FromSeconds(currentSecondsEST)
    
    currentHourEST = dateTimeEST.GetHours()
    currentMinuteEST = dateTimeEST.GetMinutes()
    secondsSinceMidnightEST = (currentHourEST * 3600) + (currentMinuteEST * 60)
    
    midnightSecondsEST = currentSecondsEST - secondsSinceMidnightEST
    midnightESTasUTC = midnightSecondsEST - americanOffsetFromUTC
    startOfDaySeconds = midnightESTasUTC
    
    dayAdjustment = m.dayOffset * 86400
    startOfDaySeconds = startOfDaySeconds + dayAdjustment
    
    m.timeGrid.contentStartTime = startOfDaySeconds
    m.timeGrid.duration = 9000
    m.timeGrid.maxDays = 1
    
    targetTime = startOfDaySeconds
    if m.dayOffset = 0 then
        targetTime = currentSecondsLocal - (currentSecondsLocal mod 1800)
    else
        targetTime = startOfDaySeconds
    end if
    
    timeGridContent = CreateObject("roSGNode", "ContentNode")
    
    for each channel in m.channelsData
        channelNode = CreateObject("roSGNode", "ContentNode")
        
        channelTitle = "Unknown Channel"
        if channel.title <> invalid and channel.title <> ""
            channelTitle = channel.title
        else if channel.name <> invalid and channel.name <> ""
            channelTitle = channel.name
        end if
        
        channelNode.title = channelTitle
        
        if channel.logo <> invalid and channel.logo <> ""
            channelNode.HDSMALLICONURL = channel.logo
            channelNode.HDPOSTERURL = channel.logo
            channelNode.hdPosterUrl = channel.logo
        else if channel.icon <> invalid and channel.icon <> ""
            channelNode.HDSMALLICONURL = channel.icon
            channelNode.HDPOSTERURL = channel.icon
            channelNode.hdPosterUrl = channel.icon
        end if
        
        if channel.stream_url <> invalid and channel.stream_url <> ""
            channelNode.url = channel.stream_url
        else if channel.url <> invalid and channel.url <> ""
            channelNode.url = channel.url
        end if
        
        if channel.shows <> invalid and channel.shows.Count() > 0
            for each show in channel.shows
                programNode = CreateObject("roSGNode", "ContentNode")
                
                if show.name <> invalid
                    programNode.title = show.name
                else
                    programNode.title = "Program"
                end if
                
                if show.longdescription <> invalid
                    programNode.description = show.longdescription
                else if show.description <> invalid
                    programNode.description = show.description
                end if
                
                if show.start <> invalid and show.end <> invalid
                    startParts = show.start.Split(":")
                    endParts = show.end.Split(":")
                    
                    if startParts.Count() >= 2 and endParts.Count() >= 2
                        startHour = Val(startParts[0])
                        startMin = Val(startParts[1])
                        endHour = Val(endParts[0])
                        endMin = Val(endParts[1])
                        
                        startSecondsFromMidnightEST = (startHour * 3600) + (startMin * 60)
                        endSecondsFromMidnightEST = (endHour * 3600) + (endMin * 60)
                        
                        if endSecondsFromMidnightEST <= startSecondsFromMidnightEST
                            endSecondsFromMidnightEST = endSecondsFromMidnightEST + 86400
                        end if
                        
                        programDurationSeconds = endSecondsFromMidnightEST - startSecondsFromMidnightEST
                        
                        programNode.PLAYSTART = startOfDaySeconds + startSecondsFromMidnightEST
                        programNode.PLAYDURATION = programDurationSeconds
                        programNode.playStart = startOfDaySeconds + startSecondsFromMidnightEST
                        programNode.playDuration = programDurationSeconds
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
    
    m.timeGrid.content = timeGridContent
    m.timeGrid.leftEdgeTargetTime = targetTime
    
    if m.dayOffset = 0
        autoFocusToCurrentProgram()
    end if
end sub

sub autoFocusToCurrentProgram()
    if m.timeGrid = invalid or m.timeGrid.content = invalid then return
    
    content = m.timeGrid.content
    if content.getChildCount() = 0 then return
    
    channel = content.getChild(0)
    if channel = invalid or channel.getChildCount() = 0 then return
    
    dateTimeUTC = CreateObject("roDateTime")
    currentTimeUTC = dateTimeUTC.AsSeconds()
    
    isNowProgramAvailable = false
    nowProgramIndex = 0
    
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
        m.timeGrid.jumpToChannel = 0
        m.timeGrid.jumpToProgram = nowProgramIndex
    else
        m.timeGrid.jumpToChannel = 0
        m.timeGrid.jumpToProgram = 0
    end if
end sub

sub buildChannelList()
    if m.channelsData = invalid or m.channelsData.Count() = 0 then return
    
    channelContent = CreateObject("roSGNode", "ContentNode")
    
    for each channel in m.channelsData
        channelNode = CreateObject("roSGNode", "ContentNode")
        
        channelName = "Unknown Channel"
        if channel.title <> invalid and channel.title <> ""
            channelName = channel.title
        else if channel.name <> invalid and channel.name <> ""
            channelName = channel.name
        end if
        
        channelNode.title = channelName
        
        logoUrl = ""
        if channel.images <> invalid
            if channel.images.poster <> invalid and channel.images.poster <> ""
                logoUrl = channel.images.poster
            else if channel.images.thumbnail <> invalid and channel.images.thumbnail <> ""
                logoUrl = channel.images.thumbnail
            end if
        else if channel.icon <> invalid and channel.icon <> ""
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
        
        if channel.id <> invalid
            channelNode.addFields({ channelId: channel.id })
        end if
        
        channelContent.appendChild(channelNode)
    end for
    
    m.channelList.content = channelContent
end sub

sub buildTimelineHeader()
    startHour = m.timelineStartHour
    startMinute = m.timelineStartMinute
    
    if m.timelineStartTotalMinutes = 0
        dateTimeUTC = CreateObject("roDateTime")
        currentMonth = dateTimeUTC.GetMonth()
        
        americanOffset = -18000
        if currentMonth >= 3 and currentMonth <= 10
            americanOffset = -14400
        end if
        
        currentSecondsUTC = dateTimeUTC.AsSeconds()
        currentSecondsAmerican = currentSecondsUTC + americanOffset
        
        dateTimeAmerican = CreateObject("roDateTime")
        dateTimeAmerican.FromSeconds(currentSecondsAmerican)
        
        currentHour = dateTimeAmerican.GetHours()
        currentMinute = dateTimeAmerican.GetMinutes()
        
        if currentMinute < 30
            startMinute = 0
        else
            startMinute = 30
        end if
        startHour = currentHour
        
        m.timelineStartHour = startHour
        m.timelineStartMinute = startMinute
        m.timelineStartTotalMinutes = startHour * 60 + startMinute
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
end sub

sub buildProgramGrid()
    if m.programGridGroup = invalid then return
    if m.channelsData = invalid or m.channelsData.Count() = 0 then return
    
    if m.timelineStartTotalMinutes = 0
        dateTimeUTC = CreateObject("roDateTime")
        currentMonth = dateTimeUTC.GetMonth()
        
        americanOffset = -18000
        if currentMonth >= 3 and currentMonth <= 10
            americanOffset = -14400
        end if
        
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
    ' Route to V2 if enabled
    if m.useTVGuideV2 = true
        return onKeyEventV2(key, press)
    end if
    
    ' V1 Logic (original)
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
            ' Back from TimeGrid ALWAYS returns to navigation (one press)
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
    
    streamUrl = ""
    
    if channel.sources <> invalid
        if channel.sources.primary <> invalid and channel.sources.primary <> ""
            streamUrl = channel.sources.primary
        else if channel.sources.hls <> invalid and channel.sources.hls <> ""
            streamUrl = channel.sources.hls
        end if
    end if
    
    if streamUrl = "" and channel.http <> invalid and channel.http <> ""
        streamUrl = channel.http
    end if
    
    if streamUrl = "" then return
    
    if m.videoPlayer <> invalid
        ' Parse URL for credentials
        urlParts = parseUrlCredentials(streamUrl)
        finalUrl = streamUrl
        if urlParts.hasCredentials
            finalUrl = urlParts.cleanUrl
        end if
        
        ' Detect stream format
        detectedFormat = detectStreamFormat(finalUrl)
        
        ' For MPEG-TS with credentials, attach roHttpAgent
        if detectedFormat = "ts" and urlParts.hasCredentials
            agent = CreateObject("roHttpAgent")
            agent.AddHeader("Authorization", "Basic " + urlParts.basicAuth)
            m.videoPlayer.SetHttpAgent(agent)
        end if
        
        videoContent = CreateObject("roSGNode", "ContentNode")
        videoContent.url = finalUrl
        videoContent.title = channelTitle

        ' Set stream format (both variants)
        if detectedFormat <> "" then
            videoContent.streamformat = detectedFormat
            videoContent.StreamFormat = detectedFormat
        end if

        ' Disable transcoding for TV Guide streams
        videoContent.live = true
        videoContent.Live = true
        
        ' MPEG-TS specific
        if detectedFormat = "ts"
            videoContent.StreamStickyHttpRedirects = [true]
            if urlParts.hasCredentials
                videoContent.HttpHeaders = ["Authorization:Basic " + urlParts.basicAuth]
            end if
        end if

        m.videoPlayer.content = videoContent
        m.videoPlayer.control = "play"
        
        if m.videoPlayerStatus <> invalid
            m.videoPlayerStatus.visible = false
        end if
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
    
    ' Update the header time label
    if m.screenTimeLabel <> invalid
        m.screenTimeLabel.text = timeStr
    end if
end sub

' ############################################################################
' ######################### TV GUIDE V2 IMPLEMENTATION #######################
' ############################################################################

sub initTVGuideV2()
    print "TVGuideScreen.brs - [initTVGuideV2] *** Initializing TV Guide V2 (Channel Browser) ***"
    
    ' Hide TimeGrid and related V1 components
    if m.timeGrid <> invalid
        m.timeGrid.visible = false
    end if
    if m.daySelector <> invalid
        m.daySelector.visible = false
    end if
    if m.channelLogoGroup <> invalid
        m.channelLogoGroup.visible = false
    end if
    if m.programDetailsGroup <> invalid
        m.programDetailsGroup.visible = false
    end if
    if m.backHintGroup <> invalid
        m.backHintGroup.visible = false
    end if
    
    ' Get V2 UI components
    m.v2ChannelList = m.top.findNode("v2ChannelList")
    m.v2ProgramRow = m.top.findNode("v2ProgramRow")
    m.v2VideoPreview = m.top.findNode("v2VideoPreview")
    m.v2VideoPlayer = m.top.findNode("v2VideoPlayer")
    m.v2VideoStatus = m.top.findNode("v2VideoStatus")
    m.v2ProgramTimeLabel = m.top.findNode("v2ProgramTimeLabel")
    m.v2NavigationHint = m.top.findNode("v2NavigationHint")
    
    ' Set up observers for V2 components
    if m.v2ChannelList <> invalid
        m.v2ChannelList.observeField("itemFocused", "onV2ChannelFocused")
        m.v2ChannelList.observeField("itemSelected", "onV2ChannelSelected")
    end if
    
    if m.v2ProgramRow <> invalid
        m.v2ProgramRow.observeField("rowItemFocused", "onV2ProgramFocused")
        m.v2ProgramRow.observeField("rowItemSelected", "onV2ProgramSelected")
    end if
    
    if m.v2VideoPlayer <> invalid
        m.v2VideoPlayer.observeField("state", "onV2VideoStateChanged")
    end if
    
    ' V2 focus state tracking
    m.v2FocusArea = "channels" ' "channels" or "programs"
    m.v2CurrentChannelIndex = 0
    m.v2CurrentProgramIndex = 0
    m.v2CurrentlyPlayingChannelIndex = -1
    m.v2CurrentlyPlayingProgramIndex = -1
    
    print "TVGuideScreen.brs - [initTVGuideV2] V2 initialization complete"
end sub

sub loadTVGuideDataV2(tvGuideData as object)
    print "TVGuideScreen.brs - [loadTVGuideDataV2] Loading data for V2"

    if tvGuideData = invalid or Type(tvGuideData) <> "roArray" or tvGuideData.Count() = 0
        print "TVGuideScreen.brs - [loadTVGuideDataV2] No data available"
        if m.noContentLabel <> invalid then
            m.noContentLabel.visible = true
        end if
        hideLoading()
        return
    end if

    ' Extract channels data (same as V1)
    if tvGuideData.Count() = 1 and tvGuideData[0] <> invalid and tvGuideData[0].contents <> invalid
        m.channelsData = tvGuideData[0].contents
    else
        m.channelsData = tvGuideData
    end if

    print "TVGuideScreen.brs - [loadTVGuideDataV2] Channels loaded: " + m.channelsData.Count().ToStr()

    ' Build V2 UI
    buildV2ChannelList()
    
    ' Load first channel's programs immediately
    if m.channelsData.Count() > 0
        print "TVGuideScreen.brs - [loadTVGuideDataV2] Loading first channel's programs"
        buildV2ProgramRow(0)
        m.v2CurrentChannelIndex = 0
    end if
    
    hideLoading()

    ' DON'T set initial focus here - let navigation handle it
    ' Initial focus should only happen when explicitly requested
    m.v2FocusArea = "channels"
end sub

sub buildV2ChannelList()
    if m.v2ChannelList = invalid or m.channelsData = invalid or m.channelsData.Count() = 0
        print "TVGuideScreen.brs - [buildV2ChannelList] ERROR: Missing components or data"
        return
    end if
    
    print "TVGuideScreen.brs - [buildV2ChannelList] Building channel list with " + m.channelsData.Count().ToStr() + " channels"
    
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    for channelIdx = 0 to m.channelsData.Count() - 1
        channel = m.channelsData[channelIdx]
        if channel = invalid then continue for
        
        channelNode = CreateObject("roSGNode", "ContentNode")
        
        ' Get channel title
        channelTitle = "Unknown Channel"
        if channel.title <> invalid and channel.title <> ""
            channelTitle = channel.title
        else if channel.name <> invalid and channel.name <> ""
            channelTitle = channel.name
        end if
        channelNode.title = channelTitle

        ' Get channel logo
        logoUrl = ""
        if channel.logo <> invalid and channel.logo <> ""
            logoUrl = channel.logo
        else if channel.icon <> invalid and channel.icon <> ""
            if Left(channel.icon, 4) = "http"
                logoUrl = channel.icon
            else
                logoUrl = "https://giatv.dineo.uk" + channel.icon
            end if
        else if channel.images <> invalid
            if channel.images.poster <> invalid and channel.images.poster <> ""
                logoUrl = channel.images.poster
            else if channel.images.thumbnail <> invalid and channel.images.thumbnail <> ""
                logoUrl = channel.images.thumbnail
            end if
        end if

        if logoUrl <> ""
            channelNode.HDPosterUrl = logoUrl
            channelNode.hdPosterUrl = logoUrl
        end if

        ' Store channel index for later reference
        channelNode.addFields({ channelDataIndex: channelIdx })

        ' Debug first 3 channels
        if channelIdx < 3
            print "TVGuideScreen.brs - [buildV2ChannelList] Channel " + channelIdx.ToStr() + ":"
            print "  Title: " + channelTitle
            print "  Logo: " + logoUrl
            print "  channelNode.title: " + channelNode.title
        end if

        contentNode.appendChild(channelNode)
    end for
    
    m.v2ChannelList.content = contentNode
    
    print "TVGuideScreen.brs - [buildV2ChannelList] Channel list built successfully"
end sub

sub onV2ChannelFocused()
    if m.v2ChannelList = invalid then return

    focusedIndex = m.v2ChannelList.itemFocused
    if focusedIndex = invalid or focusedIndex < 0 then return

    m.v2CurrentChannelIndex = focusedIndex
    
    ' Ensure focus area is set to channels
    m.v2FocusArea = "channels"

    print "TVGuideScreen.brs - [onV2ChannelFocused] Channel focused: " + focusedIndex.ToStr() + ", Focus area: " + m.v2FocusArea

    ' Build program row for this channel
    buildV2ProgramRow(focusedIndex)
end sub

sub onV2ChannelSelected()
    ' Channel selected - move focus to program row
    print "TVGuideScreen.brs - [onV2ChannelSelected] Channel selected, moving to programs"
    ' This will be handled by onKeyEvent when RIGHT is pressed
end sub

sub buildV2ProgramRow(channelIndex as integer)
    if m.v2ProgramRow = invalid or m.channelsData = invalid then return
    if channelIndex < 0 or channelIndex >= m.channelsData.Count() then return
    
    channel = m.channelsData[channelIndex]
    if channel = invalid then return
    
    print "TVGuideScreen.brs - [buildV2ProgramRow] Building program row for channel " + channelIndex.ToStr()
    
    ' Get shows for this channel
    shows = channel.shows
    if shows = invalid or shows.Count() = 0
        print "TVGuideScreen.brs - [buildV2ProgramRow] No programs available for this channel"
        ' Show empty state - still needs row structure for RowList
        contentNode = CreateObject("roSGNode", "ContentNode")
        rowNode = contentNode.createChild("ContentNode")
        emptyNode = rowNode.createChild("ContentNode")
        emptyNode.title = "No Program Information"
        emptyNode.description = ""
        m.v2ProgramRow.content = contentNode
        print "TVGuideScreen.brs - [buildV2ProgramRow] Set empty program row"
        return
    end if
    
    ' Get current time to find "now"
    dateTimeUTC = CreateObject("roDateTime")
    dateTimeLocal = CreateObject("roDateTime")
    dateTimeLocal.ToLocalTime()
    
    currentSecondsUTC = dateTimeUTC.AsSeconds()
    currentSecondsLocal = dateTimeLocal.AsSeconds()
    
    ' Build program list for RowList (needs a row with items)
    contentNode = CreateObject("roSGNode", "ContentNode")
    rowNode = contentNode.createChild("ContentNode")
    
    currentProgramIndex = -1
    programCount = 0
    
    for i = 0 to shows.Count() - 1
        show = shows[i]
        if show = invalid then continue for
        
        programNode = rowNode.createChild("ContentNode")
        
        ' Program title
        programTitle = "Program"
        if show.name <> invalid and show.name <> ""
            programTitle = show.name
        end if
        programNode.title = programTitle
        
        ' Program description
        programDesc = ""
        if show.longdescription <> invalid and show.longdescription <> ""
            programDesc = show.longdescription
        else if show.description <> invalid and show.description <> ""
            programDesc = show.description
        end if
        programNode.description = programDesc
        
        ' Program time information
        if show.start <> invalid and show.end <> invalid
            programNode.addFields({
                startTime: show.start,
                endTime: show.end
            })
            
            ' Check if this is the current program
            startParts = show.start.Split(":")
            endParts = show.end.Split(":")
            
            if startParts.Count() >= 2 and endParts.Count() >= 2
                startHour = Val(startParts[0])
                startMin = Val(startParts[1])
                endHour = Val(endParts[0])
                endMin = Val(endParts[1])
                
                ' Calculate program time in seconds (simplified - assumes same day)
                currentHour = dateTimeLocal.GetHours()
                currentMin = dateTimeLocal.GetMinutes()
                currentTotalMin = currentHour * 60 + currentMin
                programStartMin = startHour * 60 + startMin
                programEndMin = endHour * 60 + endMin
                
                ' Handle midnight crossover
                if programEndMin < programStartMin
                    programEndMin = programEndMin + 1440
                end if
                
                ' Check if current time is within this program
                if currentTotalMin >= programStartMin and currentTotalMin < programEndMin
                    currentProgramIndex = programCount
                    print "TVGuideScreen.brs - [buildV2ProgramRow] Found current program at index " + programCount.ToStr()
                end if
            end if
        end if
        
        ' Store original show index
        programNode.addFields({ originalShowIndex: i })
        
        programCount = programCount + 1
    end for
    
    m.v2ProgramRow.content = contentNode
    
    print "TVGuideScreen.brs - [buildV2ProgramRow] RowList content set, program count: " + programCount.ToStr()
    
    ' Jump to current program if found (RowList uses rowItemFocused for column position)
    if currentProgramIndex >= 0
        m.v2ProgramRow.jumpToRowItem = [0, currentProgramIndex]
        m.v2CurrentProgramIndex = currentProgramIndex
        print "TVGuideScreen.brs - [buildV2ProgramRow] Jumped to current program at index " + currentProgramIndex.ToStr()
    else
        m.v2ProgramRow.jumpToRowItem = [0, 0]
        m.v2CurrentProgramIndex = 0
        print "TVGuideScreen.brs - [buildV2ProgramRow] Starting at first program"
    end if
    
    ' Update program time display
    updateV2ProgramTimeDisplay()
    
    print "TVGuideScreen.brs - [buildV2ProgramRow] Program row built successfully with " + programCount.ToStr() + " programs"
end sub

sub onV2ProgramFocused()
    if m.v2ProgramRow = invalid then return
    
    ' RowList uses rowItemFocused which returns [row, item]
    focusedItem = m.v2ProgramRow.rowItemFocused
    if focusedItem = invalid or focusedItem.Count() < 2 then return
    
    focusedIndex = focusedItem[1] ' Column index (item within row)
    if focusedIndex < 0 then return
    
    m.v2CurrentProgramIndex = focusedIndex
    
    ' Ensure focus area is set to programs
    m.v2FocusArea = "programs"
    
    print "TVGuideScreen.brs - [onV2ProgramFocused] Program focused: " + focusedIndex.ToStr() + ", Focus area: " + m.v2FocusArea
    
    ' Update program time display
    updateV2ProgramTimeDisplay()
end sub

sub onV2ProgramSelected()
    if m.v2ProgramRow = invalid or m.channelsData = invalid then return
    
    ' RowList uses rowItemSelected which returns [row, item]
    selectedItem = m.v2ProgramRow.rowItemSelected
    if selectedItem = invalid or selectedItem.Count() < 2 then return
    
    programIndex = selectedItem[1] ' Column index (item within row)
    channelIndex = m.v2CurrentChannelIndex
    
    print "TVGuideScreen.brs - [onV2ProgramSelected] =========================================="
    print "TVGuideScreen.brs - [onV2ProgramSelected] Program selected: Channel " + channelIndex.ToStr() + ", Program " + programIndex.ToStr()
    print "TVGuideScreen.brs - [onV2ProgramSelected] Currently playing: Channel " + m.v2CurrentlyPlayingChannelIndex.ToStr() + ", Program " + m.v2CurrentlyPlayingProgramIndex.ToStr()
    
    if programIndex = invalid or programIndex < 0 then return
    if channelIndex < 0 or channelIndex >= m.channelsData.Count() then return
    
    ' Check if this is the same program already playing
    isSameProgram = (channelIndex = m.v2CurrentlyPlayingChannelIndex and programIndex = m.v2CurrentlyPlayingProgramIndex)
    
    if isSameProgram
        print "TVGuideScreen.brs - [onV2ProgramSelected] *** SAME PROGRAM - Opening full screen ***"
        playV2ProgramFullScreen(channelIndex, programIndex)
    else
        print "TVGuideScreen.brs - [onV2ProgramSelected] *** DIFFERENT PROGRAM - Playing in preview ***"
        playV2ProgramPreview(channelIndex, programIndex)
        m.v2CurrentlyPlayingChannelIndex = channelIndex
        m.v2CurrentlyPlayingProgramIndex = programIndex
    end if
    
    print "TVGuideScreen.brs - [onV2ProgramSelected] =========================================="
end sub

function parseUrlCredentials(url as string) as object
    ' Extract credentials from URL like http://user:pass@host:port/path
    result = {
        originalUrl: url
        cleanUrl: url
        username: ""
        password: ""
        hasCredentials: false
        basicAuth: ""
    }
    
    if url = invalid or url = "" then return result
    
    schemePos = Instr(1, url, "://")
    atPos = Instr(1, url, "@")
    
    if schemePos > 0 and atPos > schemePos + 3
        afterSchemePos = schemePos + 3
        afterScheme = Mid(url, afterSchemePos)
        slashPos = Instr(1, afterScheme, "/")
        
        atIsInAuthority = true
        if slashPos > 0
            slashAbs = afterSchemePos + slashPos - 1
            if slashAbs < atPos then atIsInAuthority = false
        end if
        
        if atIsInAuthority
            userInfo = Mid(url, afterSchemePos, atPos - afterSchemePos)
            colonPos = Instr(1, userInfo, ":")
            if colonPos > 0
                result.username = Left(userInfo, colonPos - 1)
                result.password = Mid(userInfo, colonPos + 1)
                result.cleanUrl = Left(url, afterSchemePos - 1) + Mid(url, atPos + 1)
                result.hasCredentials = true
                
                ' Create Base64 Basic Auth
                bytes = CreateObject("roByteArray")
                bytes.FromAsciiString(result.username + ":" + result.password)
                result.basicAuth = bytes.ToBase64String()
                
                print "TVGuideScreen.brs - [parseUrlCredentials] Extracted credentials"
            end if
        end if
    end if
    
    return result
end function

function detectStreamFormat(url as string) as string
    ' Detect stream format from URL extension
    ' Supports: HLS (.m3u8), MPEG-TS (.ts), MP4 (.mp4), and others
    
    if url = invalid or url = "" then
        print "TVGuideScreen.brs - [detectStreamFormat] Invalid URL, defaulting to hls"
        return "hls"
    end if
    
    ' Convert to lowercase for case-insensitive comparison
    urlLower = LCase(url)
    
    ' Check for IPTV-style URLs with numeric path segments (e.g., /stream/channelid/123456)
    ' These should be treated as MPEG-TS even without .ts extension
    lastSlashPos = 0
    for i = Len(urlLower) to 1 step -1
        if Mid(urlLower, i, 1) = "/"
            lastSlashPos = i
            exit for
        end if
    end for
    
    if lastSlashPos > 0
        lastSegment = Mid(url, lastSlashPos + 1)
        ' Check if last segment is numeric (IPTV channel ID pattern)
        isNumeric = true
        for i = 1 to Len(lastSegment)
            char = Mid(lastSegment, i, 1)
            if char < "0" or char > "9"
                isNumeric = false
                exit for
            end if
        end for
        
        if isNumeric and Len(lastSegment) > 0
            print "TVGuideScreen.brs - [detectStreamFormat] Detected IPTV numeric channel URL - using 'ts' format"
            return "ts"
        end if
    end if
    
    ' Check for .ts extension (MPEG-TS streams)
    ' Note: Many IPTV providers use .ts URLs - use 'ts' format explicitly
    if Instr(1, urlLower, ".ts") > 0
        ' Check if this looks like an HLS segment (has m3u8 in path or chunklist/segment pattern)
        if Instr(1, urlLower, "m3u8") > 0 or Instr(1, urlLower, "chunklist") > 0 or Instr(1, urlLower, "segment") > 0
            print "TVGuideScreen.brs - [detectStreamFormat] Detected HLS stream with .ts segments"
            return "hls"
        ' For all other .ts files (including IPTV), use explicit 'ts' format
        else
            print "TVGuideScreen.brs - [detectStreamFormat] Detected MPEG-TS stream (.ts) - using 'ts' format"
            return "ts"
        end if
    end if
    
    ' Check for .m3u8 (HLS)
    if Instr(1, urlLower, ".m3u8") > 0
        print "TVGuideScreen.brs - [detectStreamFormat] Detected HLS stream (.m3u8)"
        return "hls"
    end if
    
    ' Check for .mp4
    if Instr(1, urlLower, ".mp4") > 0
        print "TVGuideScreen.brs - [detectStreamFormat] Detected MP4 stream (.mp4)"
        return "mp4"
    end if
    
    ' Check for .mkv
    if Instr(1, urlLower, ".mkv") > 0
        print "TVGuideScreen.brs - [detectStreamFormat] Detected MKV stream (.mkv)"
        return "mkv"
    end if
    
    ' Check for DASH manifest
    if Instr(1, urlLower, ".mpd") > 0
        print "TVGuideScreen.brs - [detectStreamFormat] Detected DASH stream (.mpd)"
        return "dash"
    end if
    
    ' Check for ISM (Smooth Streaming)
    if Instr(1, urlLower, ".ism") > 0 or Instr(1, urlLower, "/manifest") > 0
        print "TVGuideScreen.brs - [detectStreamFormat] Detected Smooth Streaming (.ism)"
        return "ism"
    end if
    
    ' Default to HLS if no match
    print "TVGuideScreen.brs - [detectStreamFormat] No specific format detected, defaulting to hls for URL: " + url
    return "hls"
end function

sub playV2ProgramPreview(channelIndex as integer, programIndex as integer)
    if m.v2VideoPlayer = invalid or m.channelsData = invalid then return
    if channelIndex < 0 or channelIndex >= m.channelsData.Count() then return

    channel = m.channelsData[channelIndex]
    if channel = invalid then return

    print "TVGuideScreen.brs - [playV2ProgramPreview] Playing preview for channel " + channelIndex.ToStr()

    ' Get stream URL
    streamUrl = getChannelStreamUrl(channel, programIndex)

    if streamUrl = "" or streamUrl = invalid
        print "TVGuideScreen.brs - [playV2ProgramPreview] ERROR: No stream URL available"
        if m.v2VideoStatus <> invalid
            m.v2VideoStatus.text = "Stream not available"
            m.v2VideoStatus.visible = true
        end if
        return
    end if

    ' Get channel title
    channelTitle = "Live TV"
    if channel.title <> invalid and channel.title <> ""
        channelTitle = channel.title
    else if channel.name <> invalid and channel.name <> ""
        channelTitle = channel.name
    end if

    ' Parse URL for credentials
    urlParts = parseUrlCredentials(streamUrl)
    finalUrl = streamUrl
    if urlParts.hasCredentials
        finalUrl = urlParts.cleanUrl
        print "TVGuideScreen.brs - [playV2ProgramPreview] Using clean URL with Basic Auth"
    end if
    
    ' Detect stream format
    detectedFormat = detectStreamFormat(finalUrl)
    
    ' For MPEG-TS with credentials, attach roHttpAgent BEFORE creating content
    if m.v2VideoPlayer <> invalid and detectedFormat = "ts" and urlParts.hasCredentials
        agent = CreateObject("roHttpAgent")
        authHeader = "Basic " + urlParts.basicAuth
        agent.AddHeader("Authorization", authHeader)
        m.v2VideoPlayer.SetHttpAgent(agent)
        print "TVGuideScreen.brs - [playV2ProgramPreview] Attached roHttpAgent with Basic Auth"
    end if

    ' Create video content
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = finalUrl
    videoContent.title = channelTitle
    
    ' Set stream format (both variants for compatibility)
    if detectedFormat <> "" then
        videoContent.streamformat = detectedFormat
        videoContent.StreamFormat = detectedFormat
    end if
    
    ' Disable transcoding for TV Guide streams (all are live)
    videoContent.live = true
    videoContent.Live = true
    
    ' MPEG-TS specific properties
    if detectedFormat = "ts"
        videoContent.StreamStickyHttpRedirects = [true]
        ' Be lenient with malformed metadata in MPEG-TS streams
        videoContent.IgnoreStreamErrors = true
        ' Additional properties for error tolerance
        videoContent.MinBandwidth = 0
        videoContent.MaxBandwidth = 0
        if urlParts.hasCredentials
            videoContent.HttpHeaders = ["Authorization:Basic " + urlParts.basicAuth]
        end if
        print "TVGuideScreen.brs - [playV2ProgramPreview] MPEG-TS config: IgnoreStreamErrors=true, StreamStickyHttpRedirects=[true]"
    end if

    ' Play video
    m.v2VideoPlayer.content = videoContent
    m.v2VideoPlayer.control = "play"

    if m.v2VideoStatus <> invalid
        m.v2VideoStatus.text = "Loading..."
        m.v2VideoStatus.visible = true
    end if
    
    print "TVGuideScreen.brs - [playV2ProgramPreview] Preview started: " + streamUrl
end sub

sub playV2ProgramFullScreen(channelIndex as integer, programIndex as integer)
    if m.channelsData = invalid then return
    if channelIndex < 0 or channelIndex >= m.channelsData.Count() then return
    
    channel = m.channelsData[channelIndex]
    if channel = invalid then return
    
    print "TVGuideScreen.brs - [playV2ProgramFullScreen] Opening full screen for channel " + channelIndex.ToStr()
    
    ' Stop the small preview video player first (Roku only supports one video instance)
    if m.v2VideoPlayer <> invalid
        m.v2VideoPlayer.control = "stop"
        print "TVGuideScreen.brs - [playV2ProgramFullScreen] Stopped preview video player"
    end if
    
    ' Get stream URL
    streamUrl = getChannelStreamUrl(channel, programIndex)
    
    if streamUrl = "" or streamUrl = invalid
        print "TVGuideScreen.brs - [playV2ProgramFullScreen] ERROR: No stream URL available"
        return
    end if
    
    ' Get channel and program details
    channelTitle = "Live TV"
    if channel.title <> invalid and channel.title <> ""
        channelTitle = channel.title
    else if channel.name <> invalid and channel.name <> ""
        channelTitle = channel.name
    end if
    
    programTitle = ""
    programDescription = ""
    thumbnailUrl = ""
    
    if channel.shows <> invalid and programIndex >= 0 and programIndex < channel.shows.Count()
        program = channel.shows[programIndex]
        if program <> invalid
            if program.name <> invalid and program.name <> ""
                programTitle = program.name
            end if
            if program.longdescription <> invalid and program.longdescription <> ""
                programDescription = program.longdescription
            else if program.description <> invalid and program.description <> ""
                programDescription = program.description
            end if
        end if
    end if
    
    ' Get channel logo for thumbnail
    if channel.logo <> invalid and channel.logo <> ""
        thumbnailUrl = channel.logo
    else if channel.icon <> invalid and channel.icon <> ""
        if Left(channel.icon, 4) = "http"
            thumbnailUrl = channel.icon
        else
            thumbnailUrl = "https://giatv.dineo.uk" + channel.icon
        end if
    end if
    
    ' Create video data for full screen player
    videoData = {
        contentUrl: streamUrl,
        title: programTitle + " - " + channelTitle,
        description: programDescription,
        thumbnail: thumbnailUrl,
        isLive: true
    }
    
    print "TVGuideScreen.brs - [playV2ProgramFullScreen] Requesting full screen video playback"
    m.top.videoPlayRequested = videoData
end sub

function getChannelStreamUrl(channel as object, programIndex as integer) as string
    streamUrl = ""
    
    ' Try to get stream URL from program first
    if channel.shows <> invalid and programIndex >= 0 and programIndex < channel.shows.Count()
        program = channel.shows[programIndex]
        if program <> invalid and program.url <> invalid and program.url <> ""
            streamUrl = program.url
            return streamUrl
        end if
    end if
    
    ' Fall back to channel stream URL
    if channel.stream_url <> invalid and channel.stream_url <> ""
        streamUrl = channel.stream_url
    else if channel.sources <> invalid
        if channel.sources.primary <> invalid and channel.sources.primary <> ""
            streamUrl = channel.sources.primary
        else if channel.sources.hls <> invalid and channel.sources.hls <> ""
            streamUrl = channel.sources.hls
        end if
    else if channel.http <> invalid and channel.http <> ""
        streamUrl = channel.http
    else if channel.url <> invalid and channel.url <> ""
        streamUrl = channel.url
    end if
    
    return streamUrl
end function

sub onV2VideoStateChanged()
    if m.v2VideoPlayer = invalid or m.v2VideoStatus = invalid then return
    
    state = m.v2VideoPlayer.state
    
    if state = "playing"
        m.v2VideoStatus.visible = false
    else if state = "buffering"
        m.v2VideoStatus.text = "Loading..."
        m.v2VideoStatus.visible = true
    else if state = "error"
        m.v2VideoStatus.text = "Error loading stream"
        m.v2VideoStatus.visible = true
    else if state = "stopped"
        m.v2VideoStatus.text = "Select a program to watch"
        m.v2VideoStatus.visible = true
    end if
end sub

sub updateV2ProgramTimeDisplay()
    if m.v2ProgramRow = invalid or m.v2ProgramTimeLabel = invalid then return
    
    content = m.v2ProgramRow.content
    if content = invalid or content.getChildCount() = 0 then return
    
    ' Get the first row (we only have one row)
    rowNode = content.getChild(0)
    if rowNode = invalid then return
    
    focusedIndex = m.v2CurrentProgramIndex
    if focusedIndex < 0 or focusedIndex >= rowNode.getChildCount() then return
    
    programNode = rowNode.getChild(focusedIndex)
    if programNode = invalid then return
    
    ' Get program times
    startTime = programNode.startTime
    endTime = programNode.endTime
    
    if startTime <> invalid and endTime <> invalid
        ' Format times
        startTimeFormatted = convertTo12HourFormat(startTime)
        endTimeFormatted = convertTo12HourFormat(endTime)
        
        timeText = startTimeFormatted + " - " + endTimeFormatted
        m.v2ProgramTimeLabel.text = timeText
    else
        m.v2ProgramTimeLabel.text = ""
    end if
end sub

sub onKeyEventV2(key as string, press as boolean) as boolean
    if not press then return false
    
    print "TVGuideScreen.brs - [onKeyEventV2] Key: " + key + ", Focus area: " + m.v2FocusArea
    
    if key = "right"
        if m.v2FocusArea = "channels"
            ' Move from channel list to program row
            if m.v2ProgramRow <> invalid and m.v2ProgramRow.content <> invalid
                print "TVGuideScreen.brs - [onKeyEventV2] Moving focus from channels to programs"
                m.v2FocusArea = "programs"
                m.v2ProgramRow.setFocus(true)
                return true
            end if
        end if
        return false
    else if key = "left" or key = "back"
        if m.v2FocusArea = "programs"
            ' Move from program row back to channel list
            print "TVGuideScreen.brs - [onKeyEventV2] Moving focus from programs to channels"
            m.v2FocusArea = "channels"
            if m.v2ChannelList <> invalid
                m.v2ChannelList.setFocus(true)
            end if
            return true
        else if m.v2FocusArea = "channels"
            ' Return to navigation
            print "TVGuideScreen.brs - [onKeyEventV2] Returning to navigation from channels"
            returnFocusToNavigation()
            return true
        end if
    else if key = "up" or key = "down"
        ' Let the focused list handle up/down
        return false
    else if key = "OK"
        ' Let the list components handle OK
        return false
    end if
    
    return false
end sub

sub init()
    print "DVRItemComponent.brs - [init] Initializing modern DVR item component"
    
    ' Get references to UI elements
    m.itemposter = m.top.findNode("poster")
    m.contentOverlay = m.top.findNode("contentOverlay")
    m.overlayBackground = m.top.findNode("overlayBackground")
    m.liveIndicator = m.top.findNode("liveIndicator")  ' Now a Poster with live image
    m.recordingIndicator = m.top.findNode("recordingIndicator")
    m.recordingLabel = m.top.findNode("recordingLabel")
    m.premiumIndicator = m.top.findNode("premiumIndicator")
    m.premiumLabel = m.top.findNode("premiumLabel")
    m.channelTitle = m.top.findNode("channelTitle")
    m.timeSlot = m.top.findNode("timeSlot")
    m.duration = m.top.findNode("duration")
    m.playButtonGroup = m.top.findNode("playButtonGroup")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.focusBorder = m.top.findNode("focusBorder")
    m.cardBackground = m.top.findNode("cardBackground")
    m.statusContainer = m.top.findNode("statusContainer")
    
    ' Set up poster loading observer
    m.itemposter.observeField("loadStatus", "onPosterLoadStatusChanged")
    
    ' Set up focus observer
    m.top.observeField("focusedChild", "onFocusChanged")
    
    ' Initialize as focusable
    m.top.focusable = true
    
    ' Set initial state
    showLoadingState()
end sub

sub OnContentSet()
    print "DVRItemComponent.brs - [OnContentSet] Setting up modern DVR content"
    
    content = m.top.itemContent
    if content = invalid
        print "DVRItemComponent.brs - [OnContentSet] ERROR: No content provided"
        showErrorState("No content available")
        return
    end if
    
    ' Validate essential content fields
    if content.title = invalid or content.title = ""
        print "DVRItemComponent.brs - [OnContentSet] WARNING: Content has no title"
        content.title = "Unknown Channel"
    end if
    
    print "DVRItemComponent.brs - [OnContentSet] Content type: " + Type(content)
    
    contentTitle = "No title"
    if content.title <> invalid and content.title <> ""
        contentTitle = content.title
    end if
    print "DVRItemComponent.brs - [OnContentSet] Content title: " + contentTitle
    
    contentUrl = "No URL"
    if content.url <> invalid and content.url <> ""
        contentUrl = content.url
    end if
    print "DVRItemComponent.brs - [OnContentSet] Content URL: " + contentUrl
    
    contentDvrUrl = "No DVR URL"
    if content.dvr_url <> invalid and content.dvr_url <> ""
        contentDvrUrl = content.dvr_url
    end if
    print "DVRItemComponent.brs - [OnContentSet] Content DVR URL: " + contentDvrUrl
    
    ' Set channel/show title with enhanced formatting
    if content.title <> invalid and content.title <> ""
        ' Enhance title with channel info if available
        channelTitle = content.title
        
        ' Use real channel ID for channel number
        if content.id <> invalid
            channelNum = content.id  ' Use real channel ID (1544, 1292, etc.)
            channelPrefix = "CH " + channelNum.ToStr() + " • "
            channelTitle = channelPrefix + channelTitle
        end if
        
        m.channelTitle.text = channelTitle
        print "DVRItemComponent.brs - [OnContentSet] Enhanced channel title: " + channelTitle
    else if content.shortDescriptionLine1 <> invalid and content.shortDescriptionLine1 <> ""
        m.channelTitle.text = content.shortDescriptionLine1
    else
        m.channelTitle.text = "CH 01 • Live Channel"
    end if
    
    ' Set time slot information - only show if real data is available
    timeInfo = ""
    hasRealTimeData = false
    
    ' Check for real time data first
    if content.startsAt <> invalid and content.startsAt <> ""
        ' Use real start time if available
        timeInfo = "Today • " + content.startsAt
        if content.endsAt <> invalid and content.endsAt <> ""
            timeInfo = timeInfo + " - " + content.endsAt
        end if
        hasRealTimeData = true
        print "DVRItemComponent.brs - [OnContentSet] Using real time data: " + timeInfo
    else if content.releaseDate <> invalid and content.releaseDate <> ""
        ' Try to parse and format the date/time
        timeInfo = "Today • " + content.releaseDate
        hasRealTimeData = true
        print "DVRItemComponent.brs - [OnContentSet] Using release date: " + timeInfo
    else if content.shortDescriptionLine2 <> invalid and content.shortDescriptionLine2 <> "" and Len(content.shortDescriptionLine2) < 50
        ' Only use secondary description if it's short and likely to be time info (not a full description)
        if Instr(1, LCase(content.shortDescriptionLine2), "today") > 0 or Instr(1, content.shortDescriptionLine2, ":") > 0 or Instr(1, LCase(content.shortDescriptionLine2), "live") > 0
            timeInfo = content.shortDescriptionLine2
            hasRealTimeData = true
            print "DVRItemComponent.brs - [OnContentSet] Using description time info: " + timeInfo
        else
            print "DVRItemComponent.brs - [OnContentSet] Description too long or not time-related, skipping: " + Left(content.shortDescriptionLine2, 50) + "..."
        end if
    else
        ' No real time data available - hide the time slot completely
        timeInfo = ""
        hasRealTimeData = false
        print "DVRItemComponent.brs - [OnContentSet] No real time data available - hiding time slot"
    end if
    
    ' Set text and visibility based on real data availability
    m.timeSlot.text = timeInfo
    m.timeSlot.visible = hasRealTimeData
    
    ' Dynamically adjust layout based on available content
    ' Always keep poster at TRUE 16:9 (396x223)
    m.itemposter.height = 223
    m.contentOverlay.translation = [2, 225]
    
    if hasRealTimeData
        print "DVRItemComponent.brs - [OnContentSet] Time slot visible: " + timeInfo
        ' Full layout with time info - show both title and time
        m.overlayBackground.height = 73
        m.channelTitle.translation = [12, 10]
        m.channelTitle.height = 26
        m.statusContainer.translation = [332, 8]  ' Align 30px icon with 26px title at y=10
    else
        print "DVRItemComponent.brs - [OnContentSet] Time slot hidden - compact layout"
        ' Compact layout - center title vertically in overlay (no time slot)
        m.overlayBackground.height = 73
        m.channelTitle.translation = [12, 26]
        m.channelTitle.height = 26
        m.statusContainer.translation = [332, 24]  ' Align 30px icon with centered title
    end if
    
    ' Set duration and metadata - hide for live content since we have LIVE indicator badge
    durationText = ""
    showDuration = true
    
    if content.length <> invalid and content.length > 0
        minutes = content.length / 60
        durationText = minutes.ToStr() + "m"
    else if content.live = true
        ' Live content - don't show redundant "LIVE" text, we have the badge already
        ' Only show useful metadata if available (language, studio)
        if content.details <> invalid
            if content.details.language <> invalid and content.details.language <> ""
                durationText = content.details.language  ' "English", "Georgian"
            else if content.details.studio <> invalid and content.details.studio <> ""
                durationText = content.details.studio  ' "Studio 218"
            else
                ' No useful metadata and it's live - hide duration row entirely
                showDuration = false
            end if
        else
            ' No details and it's live - hide duration row entirely
            showDuration = false
        end if
    else
        ' Non-live content without length - show studio/language if available
        if content.details <> invalid
            if content.details.language <> invalid and content.details.language <> ""
                durationText = content.details.language
            else if content.details.studio <> invalid and content.details.studio <> ""
                durationText = content.details.studio
            else
                showDuration = false
            end if
        else
            showDuration = false
        end if
    end if
    
    m.duration.text = durationText
    m.duration.visible = showDuration
    
    ' Set poster image
    posterUrl = ""
    if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
        posterUrl = content.hdPosterUrl
        print "DVRItemComponent.brs - [OnContentSet] Using hdPosterUrl: " + posterUrl
    else if content.hdGridPosterUrl <> invalid and content.hdGridPosterUrl <> ""
        posterUrl = content.hdGridPosterUrl
        print "DVRItemComponent.brs - [OnContentSet] Using hdGridPosterUrl: " + posterUrl
    else if content.hdBackgroundImageUrl <> invalid and content.hdBackgroundImageUrl <> ""
        posterUrl = content.hdBackgroundImageUrl
        print "DVRItemComponent.brs - [OnContentSet] Using hdBackgroundImageUrl: " + posterUrl
    else if content.thumbnail <> invalid and content.thumbnail <> ""
        posterUrl = content.thumbnail
        print "DVRItemComponent.brs - [OnContentSet] Using thumbnail: " + posterUrl
    else
        print "DVRItemComponent.brs - [OnContentSet] No poster URL found, using default"
        posterUrl = "pkg:/images/png/poster_not_found_350x245.png"
    end if
    
    print "DVRItemComponent.brs - [OnContentSet] Setting poster URI to: " + posterUrl
    m.itemposter.uri = posterUrl
    
    ' Determine content status and show appropriate indicators
    setupContentIndicators(content)
    
    ' Check for DVR availability
    setupDVRIndicator(content)
    
    ' Show content overlay
    m.contentOverlay.visible = true
    
    print "DVRItemComponent.brs - [OnContentSet] Modern DVR content setup complete"
end sub

sub showErrorState(errorMessage as string)
    print "DVRItemComponent.brs - [showErrorState] Showing error: " + errorMessage
    
    ' Hide loading state
    hideLoadingState()
    
    ' Show error in title
    m.channelTitle.text = "Error: " + errorMessage
    m.channelTitle.color = "#ff6b6b"  ' Red color for error
    
    ' Hide other elements
    m.timeSlot.visible = false
    m.duration.visible = false
    m.liveIndicator.visible = false
    
    print "DVRItemComponent.brs - [showErrorState] Error state displayed"
end sub

sub setupDVRIndicator(content)
    ' Check if this channel has DVR content available
    hasDVR = false
    if content.dvr_url <> invalid and content.dvr_url <> ""
        hasDVR = true
        print "DVRItemComponent.brs - [setupDVRIndicator] DVR content available: " + content.dvr_url
        
        ' Store DVR URL for later use
        m.top.dvrUrl = content.dvr_url
        
        ' Show DVR indicator (we can use the recording indicator for this)
        m.recordingIndicator.visible = true
        m.recordingLabel.visible = true
        m.recordingLabel.text = "DVR"
        m.recordingIndicator.color = "#4FC3F7"  ' Light blue for DVR
        print "DVRItemComponent.brs - [setupDVRIndicator] DVR indicator shown for: " + content.title
    else
        print "DVRItemComponent.brs - [setupDVRIndicator] No DVR content available for: " + content.title
        m.top.dvrUrl = ""
    end if
end sub

sub setupContentIndicators(content)
    ' Reset all indicators
    m.liveIndicator.visible = false
    m.recordingIndicator.visible = false
    m.recordingLabel.visible = false
    m.premiumIndicator.visible = false
    m.premiumLabel.visible = false
    
    ' Use real live field from content
    isLive = false
    if content.live <> invalid and content.live = true
        isLive = true
        m.liveIndicator.visible = true
        print "DVRItemComponent.brs - [setupContentIndicators] Real LIVE content detected: " + content.title
    end if
    
    ' Check for recording status (simulate for demo)
    ' In real implementation, this would come from content metadata
    isRecording = false
    if content.title <> invalid
        ' Demo: Mark certain shows as recording
        if Instr(1, LCase(content.title), "news") > 0 or Instr(1, LCase(content.title), "sports") > 0
            isRecording = true
        end if
    end if
    
    if isRecording
        m.recordingIndicator.visible = true
        m.recordingLabel.visible = true
        print "DVRItemComponent.brs - [setupContentIndicators] Recording content detected"
    end if
    
    ' Check for premium/HD content
    isPremium = false
    if content.quality <> invalid and LCase(content.quality) = "hd"
        isPremium = true
    else if content.title <> invalid
        ' Demo: Mark certain channels as premium/HD
        if Instr(1, LCase(content.title), "hbo") > 0 or Instr(1, LCase(content.title), "premium") > 0
            isPremium = true
        end if
    end if
    
    if isPremium
        m.premiumIndicator.visible = true
        m.premiumLabel.visible = true
        print "DVRItemComponent.brs - [setupContentIndicators] Premium/HD content detected"
    end if
end sub

sub onPosterLoadStatusChanged()
    loadStatus = m.itemposter.loadStatus
    print "DVRItemComponent.brs - [onPosterLoadStatusChanged] Load status: " + loadStatus
    
    if loadStatus = "ready"
        hideLoadingState()
    else if loadStatus = "loading"
        showLoadingState()
    else if loadStatus = "failed"
        hideLoadingState()
        ' Set fallback image
        m.itemposter.uri = "pkg:/images/png/poster_not_found_350x245.png"
    end if
end sub

sub showLoadingState()
    print "DVRItemComponent.brs - [showLoadingState] Showing loading state"
    m.loadingGroup.visible = true
end sub

sub hideLoadingState()
    print "DVRItemComponent.brs - [hideLoadingState] Hiding loading state"
    m.loadingGroup.visible = false
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    ' Let the RowList handle all key events for proper item selection
    ' The DVR detection and navigation will be handled in the parent screen's onItemSelected
    return false
end function

sub onFocusChanged()
    if m.top.hasFocus()
        print "DVRItemComponent.brs - [onFocusChanged] DVR item gained focus - showing 2px 9-patch focus bitmap"
        
        ' Show custom 2px 9-patch focus bitmap border
        m.focusBorder.visible = true
        
        ' Show play button overlay
        m.playButtonGroup.visible = true
        
        ' Enhance card background for focus
        m.cardBackground.color = "#252b3a"  ' Slightly lighter on focus
        
        print "DVRItemComponent.brs - [onFocusChanged] 2px 9-patch focus bitmap effects applied"
    else
        print "DVRItemComponent.brs - [onFocusChanged] DVR item lost focus - hiding focus state"
        
        ' Hide 2px 9-patch focus bitmap border
        m.focusBorder.visible = false
        
        ' Hide play button
        m.playButtonGroup.visible = false
        
        ' Reset card background
        m.cardBackground.color = "#1a1f2e"  ' Original dark color
        
        print "DVRItemComponent.brs - [onFocusChanged] 2px 9-patch focus bitmap effects removed"
    end if
end sub
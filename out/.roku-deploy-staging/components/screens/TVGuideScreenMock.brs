sub init()
    print "TVGuideScreenMock.brs - [init] Initializing MOCK TV Guide Screen"
    
    m.timeGrid = m.top.findNode("timeGrid")
    m.channelLogoImage = m.top.findNode("channelLogoImage")
    m.channelLogoName = m.top.findNode("channelLogoName")
    m.programTitle = m.top.findNode("programTitle")
    m.programTime = m.top.findNode("programTime")
    m.programDescription = m.top.findNode("programDescription")
    m.videoPlayerStatus = m.top.findNode("videoPlayerStatus")
    
    ' Set up TimeGrid event observers
    m.timeGrid.observeField("programFocused", "onProgramFocused")
    m.timeGrid.observeField("channelFocused", "onChannelFocused")
    m.timeGrid.observeField("programSelected", "onProgramSelected")
    
    ' Load mock data immediately
    loadMockData()
end sub

sub loadMockData()
    print "TVGuideScreenMock.brs - [loadMockData] Creating mock EPG data"
    
    ' Get current time for realistic timestamps
    dateTime = CreateObject("roDateTime")
    dateTime.ToLocalTime()
    currentSeconds = dateTime.AsSeconds()
    currentHour = dateTime.GetHours()
    currentMinute = dateTime.GetMinutes()
    currentSecond = dateTime.GetSeconds()
    
    ' Calculate midnight of today
    secondsSinceMidnight = (currentHour * 3600) + (currentMinute * 60) + currentSecond
    midnightSeconds = currentSeconds - secondsSinceMidnight
    
    ' Configure TimeGrid
    m.timeGrid.contentStartTime = midnightSeconds
    m.timeGrid.duration = 9000 ' 2.5 hours visible
    m.timeGrid.maxDays = 1
    
    ' Start at current time rounded to 30-min
    currentTimeRounded = currentSeconds - (currentSeconds mod 1800)
    m.timeGrid.leftEdgeTargetTime = currentTimeRounded
    
    ' Create mock channels
    mockChannels = [
        {
            name: "HBO",
            logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/HBO_logo.svg/320px-HBO_logo.svg.png"
        },
        {
            name: "ESPN",
            logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/ESPN_wordmark.svg/320px-ESPN_wordmark.svg.png"
        },
        {
            name: "CNN",
            logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/CNN.svg/320px-CNN.svg.png"
        },
        {
            name: "Discovery",
            logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Discovery_Channel_logo.svg/320px-Discovery_Channel_logo.svg.png"
        },
        {
            name: "National Geographic",
            logo: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/13/National_Geographic_Channel.svg/320px-National_Geographic_Channel.svg.png"
        }
    ]
    
    ' Create mock programs with varying durations (including very short ones)
    mockProgramTemplates = [
        {title: "Morning News", duration: 3600, description: "Latest news and weather updates"},
        {title: "Sports Highlights", duration: 1800, description: "Best moments from last night's games"},
        {title: "Quick Break", duration: 300, description: "5-minute commercial break"}, ' 5 min - tests narrow programs
        {title: "Ad Spot", duration: 60, description: "1-minute advertisement"}, ' 1 min - tests very narrow programs
        {title: "Movie: Action Hero", duration: 7200, description: "An epic action adventure film"},
        {title: "Documentary", duration: 5400, description: "Exploring the depths of the ocean"},
        {title: "Sitcom", duration: 1800, description: "Comedy series about a quirky family"},
        {title: "News Update", duration: 600, description: "10-minute news bulletin"}, ' 10 min
        {title: "Weather", duration: 180, description: "3-minute weather forecast"}, ' 3 min - tests narrow programs
        {title: "Talk Show", duration: 3600, description: "Celebrity interviews and entertainment"},
        {title: "Reality Show", duration: 2700, description: "Competition reality series"},
        {title: "Cooking Show", duration: 1800, description: "Chef prepares gourmet meals"}
    ]
    
    ' Build TimeGrid content
    timeGridContent = CreateObject("roSGNode", "ContentNode")
    
    for channelIdx = 0 to mockChannels.Count() - 1
        channel = mockChannels[channelIdx]
        
        ' Create channel node
        channelNode = CreateObject("roSGNode", "ContentNode")
        channelNode.title = channel.name
        channelNode.HDSMALLICONURL = channel.logo
        channelNode.HDPOSTERURL = channel.logo
        channelNode.hdPosterUrl = channel.logo
        
        ' Create programs for this channel (24 hours)
        currentProgramTime = midnightSeconds
        endOfDay = midnightSeconds + 86400 ' 24 hours
        
        programIndex = 0
        while currentProgramTime < endOfDay
            ' Pick a random program template
            templateIdx = programIndex mod mockProgramTemplates.Count()
            template = mockProgramTemplates[templateIdx]
            
            ' Create program node
            programNode = CreateObject("roSGNode", "ContentNode")
            programNode.title = template.title
            programNode.description = template.description
            programNode.PLAYSTART = currentProgramTime
            programNode.PLAYDURATION = template.duration
            programNode.playStart = currentProgramTime
            programNode.playDuration = template.duration
            
            ' Add formatted times for display
            startDateTime = CreateObject("roDateTime")
            startDateTime.FromSeconds(currentProgramTime)
            startDateTime.ToLocalTime()
            startHour = startDateTime.GetHours()
            startMin = startDateTime.GetMinutes()
            
            endDateTime = CreateObject("roDateTime")
            endDateTime.FromSeconds(currentProgramTime + template.duration)
            endDateTime.ToLocalTime()
            endHour = endDateTime.GetHours()
            endMin = endDateTime.GetMinutes()
            
            ' Format times as HH:MM
            startTime = formatTime(startHour, startMin)
            endTime = formatTime(endHour, endMin)
            
            programNode.addFields({
                startTime: startTime,
                endTime: endTime
            })
            
            ' Add to channel
            channelNode.appendChild(programNode)
            
            ' Move to next program
            currentProgramTime = currentProgramTime + template.duration
            programIndex = programIndex + 1
        end while
        
        ' Add channel to grid
        timeGridContent.appendChild(channelNode)
        
        print "TVGuideScreenMock.brs - [loadMockData] Created channel: " + channel.name + " with " + channelNode.getChildCount().ToStr() + " programs"
    end for
    
    ' Set content on TimeGrid
    m.timeGrid.content = timeGridContent
    
    print "TVGuideScreenMock.brs - [loadMockData] MOCK data loaded - " + timeGridContent.getChildCount().ToStr() + " channels"
    
    ' Set initial channel/program details
    if timeGridContent.getChildCount() > 0
        firstChannel = timeGridContent.getChild(0)
        if firstChannel.getChildCount() > 0
            m.channelLogoName.text = firstChannel.title
            firstProgram = firstChannel.getChild(0)
            m.programTitle.text = firstProgram.title
            m.programDescription.text = firstProgram.description
            if firstProgram.hasField("startTime") and firstProgram.hasField("endTime")
                m.programTime.text = firstProgram.startTime + " - " + firstProgram.endTime
            end if
        end if
    end if
end sub

function formatTime(hour as integer, minute as integer) as string
    ' Format as HH:MM
    hourStr = hour.ToStr()
    if hour < 10 then hourStr = "0" + hourStr
    
    minStr = minute.ToStr()
    if minute < 10 then minStr = "0" + minStr
    
    return hourStr + ":" + minStr
end function

sub onProgramFocused()
    programIndex = m.timeGrid.programFocused
    channelIndex = m.timeGrid.channelFocused
    
    print "TVGuideScreenMock.brs - [onProgramFocused] Channel: " + channelIndex.ToStr() + ", Program: " + programIndex.ToStr()
    
    if programIndex < 0
        ' No program at this time
        m.programTitle.text = "No Program"
        m.programTime.text = ""
        m.programDescription.text = "No program scheduled at this time"
        m.videoPlayerStatus.text = "[MOCK] No Preview Available"
        return
    end if
    
    updateFocusedItemDetails(channelIndex, programIndex)
end sub

sub onChannelFocused()
    channelIndex = m.timeGrid.channelFocused
    print "TVGuideScreenMock.brs - [onChannelFocused] Channel: " + channelIndex.ToStr()
end sub

sub onProgramSelected()
    programIndex = m.timeGrid.programSelected
    channelIndex = m.timeGrid.channelSelected
    print "TVGuideScreenMock.brs - [onProgramSelected] Selected - Channel: " + channelIndex.ToStr() + ", Program: " + programIndex.ToStr()
end sub

sub updateFocusedItemDetails(channelIndex as Integer, programIndex as Integer)
    content = m.timeGrid.content
    if content = invalid then return
    
    channelNode = content.GetChild(channelIndex)
    if channelNode = invalid then return
    
    program = channelNode.GetChild(programIndex)
    if program = invalid then return
    
    ' Update channel logo
    m.channelLogoName.text = channelNode.title
    logoUrl = ""
    if channelNode.HDSMALLICONURL <> invalid and channelNode.HDSMALLICONURL <> ""
        logoUrl = channelNode.HDSMALLICONURL
        m.channelLogoImage.uri = logoUrl
        m.channelLogoName.visible = false
    else
        m.channelLogoImage.uri = ""
        m.channelLogoName.visible = true
    end if
    
    ' Update program details
    m.programTitle.text = program.title
    m.programDescription.text = program.description
    
    ' Update time display
    if program.hasField("startTime") and program.hasField("endTime")
        m.programTime.text = program.startTime + " - " + program.endTime
    else
        m.programTime.text = ""
    end if
    
    ' Update video status
    m.videoPlayerStatus.text = "[MOCK] Preview: " + program.title
    
    print "TVGuideScreenMock.brs - [updateFocusedItemDetails] Updated to: " + program.title
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    
    if key = "back"
        print "TVGuideScreenMock.brs - [onKeyEvent] Back pressed"
        return false ' Let parent handle
    end if
    
    return false ' Let TimeGrid handle navigation
end function

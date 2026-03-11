' EPG Program Item for TimeGrid (dynamic sizing based on duration)

sub init()
    m.itemBackground = m.top.findNode("itemBackground")
    m.programTitle = m.top.findNode("programTitle")
    m.timeRange = m.top.findNode("timeRange")
    
    ' Padding for content
    m.horizontalPadding = 12
    m.verticalPadding = 10
end sub

sub onContentSet()
    content = m.top.content
    
    if content = invalid
        m.programTitle.text = ""
        m.timeRange.text = ""
        return
    end if
    
    ' Set program title
    if content.title <> invalid and content.title <> ""
        m.programTitle.text = content.title
    else
        m.programTitle.text = "Program"
    end if
    
    ' Set time range - check for custom fields
    startTime = ""
    endTime = ""
    
    ' Try to get startTime from custom field
    startTimeField = content.getField("startTime")
    if startTimeField <> invalid and startTimeField <> ""
        startTime = startTimeField
    end if
    
    ' Try to get endTime from custom field
    endTimeField = content.getField("endTime")
    if endTimeField <> invalid and endTimeField <> ""
        endTime = endTimeField
    end if
    
    ' Format: "10:00 – 11:30"
    if startTime <> "" and endTime <> ""
        m.timeRange.text = startTime + " – " + endTime
    else if startTime <> ""
        m.timeRange.text = startTime
    else
        m.timeRange.text = ""
    end if
end sub

sub onLayoutChanged()
    ' TimeGrid sets width and height dynamically based on program duration
    originalWidth = m.top.width
    itemHeight = m.top.height
    
    ' Always hide time range for narrow items (< 100px)
    showTimeRange = (originalWidth >= 100)
    
    ' Enforce minimum rendering width for visibility
    ' Background/labels will overflow the Group if needed, making narrow programs visible
    renderWidth = originalWidth
    minWidth = 60  ' Minimum visual width (background will be at least this wide)
    if renderWidth < minWidth then renderWidth = minWidth
    
    ' Update background size (may overflow Group bounds for very short programs)
    if m.itemBackground <> invalid
        m.itemBackground.width = renderWidth
        m.itemBackground.height = itemHeight
    end if
    
    ' Calculate content area (with padding)
    contentWidth = renderWidth - (m.horizontalPadding * 2)
    if contentWidth < 20 then contentWidth = 20 ' Minimum text width
    
    ' Update label sizes - ALWAYS show title (no minimum width requirement)
    if m.programTitle <> invalid
        m.programTitle.width = contentWidth
        m.programTitle.visible = true  ' Always visible
        
        ' Use progressively smaller fonts for narrower items
        if originalWidth < 40
            ' Extremely narrow: use smallest font and vertical center
            m.programTitle.font = "font:VerySmallSystemFont"
            m.programTitle.wrap = false
            m.programTitle.vertAlign = "center"
            m.programTitle.translation = [m.horizontalPadding, (itemHeight - 15) / 2]
        else if originalWidth < 80
            ' Narrow: very small font
            m.programTitle.font = "font:VerySmallSystemFont"
            m.programTitle.wrap = false
            m.programTitle.vertAlign = "center"
            m.programTitle.translation = [m.horizontalPadding, 18]
        else
            ' Normal: small font
            m.programTitle.font = "font:SmallSystemFont"
            m.programTitle.wrap = false
            m.programTitle.vertAlign = "center"
            m.programTitle.translation = [m.horizontalPadding, 18]
        end if
    end if
    
    if m.timeRange <> invalid
        m.timeRange.width = contentWidth
        m.timeRange.visible = showTimeRange
    end if
    
    ' Debug log for very narrow items
    if originalWidth < 50
        print "EPGProgramItem - Narrow item: origWidth=" + originalWidth.ToStr() + ", renderWidth=" + renderWidth.ToStr()
    end if
end sub

sub onFocusPercentChanged()
    focusPercent = m.top.focusPercent
    
    ' Focused: #3498DB (bright blue) | Unfocused: #1F3B5C (dark blue-gray)
    if focusPercent > 0.5
        ' Focused state
        m.itemBackground.color = "#3498DB"
        m.programTitle.color = "#FFFFFF"
        m.timeRange.color = "#FFFFFF"
    else
        ' Unfocused state
        m.itemBackground.color = "#1F3B5C"
        m.programTitle.color = "#FFFFFF"
        m.timeRange.color = "#B0B8C4"
    end if
end sub

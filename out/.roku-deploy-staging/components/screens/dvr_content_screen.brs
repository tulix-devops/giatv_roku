sub init()
    print "DVRContentScreen.brs - [init] Initializing DVR content screen"
    
    ' Get references to UI elements
    m.dvrRowList = m.top.findNode("dvrRowList")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.noDVRContentGroup = m.top.findNode("noDVRContentGroup")
    m.channelTitleLabel = m.top.findNode("channelTitleLabel")
    m.backButton = m.top.findNode("backButton")
    
    ' Set up RowList event handlers
    m.dvrRowList.observeField("itemSelected", "onItemSelected")
    m.dvrRowList.observeField("itemFocused", "onItemFocused")
    
    ' Set up back button
    m.backButton.observeField("buttonSelected", "onBackButtonPressed")
    
    ' Focus handling
    m.top.observeField("focusedChild", "onFocusChanged")
    
    ' Initialize as focusable
    m.top.focusable = true
    
    ' Set initial state
    showLoadingState()
    
    print "DVRContentScreen.brs - [init] DVR content screen initialized"
end sub

sub loadDVRContent()
    print "DVRContentScreen.brs - [loadDVRContent] Loading DVR content from URL: " + m.top.dvrUrl
    
    if m.top.dvrUrl = invalid or m.top.dvrUrl = ""
        print "DVRContentScreen.brs - [loadDVRContent] No DVR URL provided"
        showNoDVRContent()
        return
    end if
    
    ' Update channel title if provided
    if m.top.channelTitle <> invalid and m.top.channelTitle <> ""
        m.channelTitleLabel.text = m.top.channelTitle + " - DVR Content"
    else
        m.channelTitleLabel.text = "DVR Content"
    end if
    
    showLoadingState()
    
    ' TODO: Implement actual DVR content loading from m.top.dvrUrl
    ' For now, simulate loading with a timer
    simulateDVRLoading()
end sub

sub simulateDVRLoading()
    print "DVRContentScreen.brs - [simulateDVRLoading] Simulating DVR content loading..."
    
    ' Create a timer to simulate loading
    loadingTimer = CreateObject("roSGNode", "Timer")
    loadingTimer.duration = 2.0  ' 2 seconds
    loadingTimer.repeat = false
    loadingTimer.observeField("fire", "onLoadingComplete")
    loadingTimer.control = "start"
    m.loadingTimer = loadingTimer
end sub

sub onLoadingComplete()
    print "DVRContentScreen.brs - [onLoadingComplete] DVR loading simulation complete"
    
    ' For demo purposes, create some sample DVR content
    createSampleDVRContent()
end sub

sub createSampleDVRContent()
    print "DVRContentScreen.brs - [createSampleDVRContent] Creating sample DVR content"
    
    hideLoadingState()
    
    ' Create sample DVR content structure
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    ' Create a row for recorded programs
    recordedRow = CreateObject("roSGNode", "ContentNode")
    recordedRow.title = "Recorded Programs"
    
    ' Add sample recorded items
    sampleRecordings = [
        {
            title: "Evening News - Jan 20",
            description: "Daily news broadcast",
            duration: "1800",  ' 30 minutes
            recordedDate: "2024-01-20",
            thumbnail: "pkg:/images/png/no-poster-found.png"
        },
        {
            title: "Morning Show - Jan 20", 
            description: "Morning talk show",
            duration: "3600",  ' 60 minutes
            recordedDate: "2024-01-20",
            thumbnail: "pkg:/images/png/no-poster-found.png"
        },
        {
            title: "Documentary Special",
            description: "Nature documentary",
            duration: "5400",  ' 90 minutes
            recordedDate: "2024-01-19",
            thumbnail: "pkg:/images/png/no-poster-found.png"
        }
    ]
    
    for each recording in sampleRecordings
        itemNode = CreateObject("roSGNode", "ContentNode")
        itemNode.title = recording.title
        itemNode.description = recording.description
        itemNode.length = Val(recording.duration)
        itemNode.releaseDate = recording.recordedDate
        itemNode.hdPosterUrl = recording.thumbnail
        itemNode.thumbnail = recording.thumbnail
        
        ' Mark as recorded content
        itemNode.live = false
        itemNode.dvr_url = ""  ' No nested DVR
        
        recordedRow.appendChild(itemNode)
        print "DVRContentScreen.brs - [createSampleDVRContent] Added DVR item: " + recording.title
    end for
    
    contentNode.appendChild(recordedRow)
    
    ' Set content to RowList
    m.dvrRowList.content = contentNode
    m.dvrRowList.visible = true
    
    print "DVRContentScreen.brs - [createSampleDVRContent] DVR content loaded with " + recordedRow.getChildCount().ToStr() + " items"
    
    ' Set focus to the content
    setInitialFocus()
end sub

sub showLoadingState()
    print "DVRContentScreen.brs - [showLoadingState] Showing loading state"
    m.top.isLoading = true
    m.loadingGroup.visible = true
    m.dvrRowList.visible = false
    m.noDVRContentGroup.visible = false
end sub

sub hideLoadingState()
    print "DVRContentScreen.brs - [hideLoadingState] Hiding loading state"
    m.top.isLoading = false
    m.loadingGroup.visible = false
end sub

sub showNoDVRContent()
    print "DVRContentScreen.brs - [showNoDVRContent] Showing no DVR content message"
    hideLoadingState()
    m.dvrRowList.visible = false
    m.noDVRContentGroup.visible = true
    
    ' Set focus to back button
    m.backButton.setFocus(true)
end sub

sub setInitialFocus()
    print "DVRContentScreen.brs - [setInitialFocus] Setting initial focus"
    
    if m.dvrRowList.visible = true and m.dvrRowList.content <> invalid
        print "DVRContentScreen.brs - [setInitialFocus] Setting focus on DVR content"
        m.dvrRowList.setFocus(true)
    else
        print "DVRContentScreen.brs - [setInitialFocus] Setting focus on back button"
        m.backButton.setFocus(true)
    end if
end sub

sub onFocusChanged()
    print "DVRContentScreen.brs - [onFocusChanged] Focus changed, hasFocus: " + m.top.hasFocus().ToStr()
    
    if m.top.hasFocus()
        print "DVRContentScreen.brs - [onFocusChanged] DVR screen gained focus"
        setInitialFocus()
    else
        print "DVRContentScreen.brs - [onFocusChanged] DVR screen lost focus"
    end if
end sub

sub onItemSelected()
    print "DVRContentScreen.brs - [onItemSelected] DVR item selected"
    
    ' Get selected item
    selectedItem = m.dvrRowList.content.getChild(m.dvrRowList.rowItemSelected[0]).getChild(m.dvrRowList.rowItemSelected[1])
    
    if selectedItem <> invalid
        print "DVRContentScreen.brs - [onItemSelected] Selected DVR item: " + selectedItem.title
        ' TODO: Play the selected DVR content
    end if
end sub

sub onItemFocused()
    print "DVRContentScreen.brs - [onItemFocused] DVR item focus changed"
end sub

sub onBackButtonPressed()
    print "DVRContentScreen.brs - [onBackButtonPressed] Back button pressed"
    ' TODO: Navigate back to previous screen
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press
        if key = "back" or key = "left"
            print "DVRContentScreen.brs - [onKeyEvent] Back key pressed"
            ' TODO: Navigate back to previous screen
            return true
        else if key = "right"
            ' Enter DVR content from back button
            if m.backButton.hasFocus() and m.dvrRowList.visible = true
                print "DVRContentScreen.brs - [onKeyEvent] Moving focus from back button to DVR content"
                m.dvrRowList.setFocus(true)
                return true
            end if
        end if
    end if
    
    return false
end function
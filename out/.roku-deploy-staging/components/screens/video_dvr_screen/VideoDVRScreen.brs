' =============================================================================
' init - Initializes the Details screen, sets all observers and configures buttons for Details screen
' =============================================================================

function init()

    print "DetailsScreen.brs - [init]"

    m.buttons = m.top.findNode("Buttons")
    m.videoPlayer = m.top.findNode("VideoPlayer")
    m.poster = m.top.findNode("Poster")
    m.description = m.top.findNode("Description")
    m.detailsOverhang = m.top.findNode("detailsOverhang")
    m.overhangBackground = m.top.findNode("overhangBackground")
    ' m.overhangBackground.height = m.global.overhangHeight
    m.overhangBackground.height = 140
    m.backgroundPanelSet = m.top.findNode("backgroundPanelSet")
    m.hudRectangle = m.top.findNode("HUDRectangle")
    m.backgroundPanel = m.top.findNode("backgroundPanel")
    m.fadeInBackgroundGroup = m.top.findNode("fadeInBackgroundGroup")
    m.fadeOutBackgroundGroup = m.top.findNode("fadeOutBackgroundGroup")


    m.overhangBackground.color = "#f16667"
    m.hudRectangle.color = "#f16667"

    ' m.top.observeField("visible", "onVisibleChange")

    ' m.videoPlayer.enableUI = false
    ' m.videoPlayer.enableTrickPlay = false
    m.videoPlayer.disableScreenSaver = true

    ' m.videoPlayer.enableUI = false
    ' m.videoPlayer.enableTrickPlay = false
    m.videoPlayer.globalCaptionMode = m.global.enablecc '''''''"On"
    device = CreateObject("roDeviceInfo")
    cninfo = device.GetConnectionInfo()
    hvideo = CreateObject("roHttpAgent")
    hvideoheaders = {
        "Device": device.GetChannelClientId(),
        "MacID": device.GetChannelClientId(),
        "Cinfo": cninfo.ip,
        "DeviceProf": device.GetModelDisplayName() + "(" + device.GetModel() + ";" + device.GetVersion() + ";Roku;roku)",
        "Version": "C4.9.9_S0 caglar",
        "x-roku-reserved-dev-id": "",
        "session-id": "",
    }
    hvideo.SetHeaders(hvideoheaders)

    print "VideoPlayerDVRScreenView.brs - [SetCurrentTimeHrsMins()] Client IP " device.GetIPAddrs()
    m.videoPlayer.setHttpAgent(hvideo)


    m.dialogErrStream = CreateObject("roSGNode", "BackDialog")
    m.dialogErrStream.title = "Stream Error"
    m.dialogErrStream.message = "Streaming is not available!"
    m.dialogErrStream.buttons = ["OK"]
    m.dialogErrStream.ObserveField("buttonSelected", "On_dialogErrStream_buttonSelected")

end function

sub On_dialogErrStream_buttonSelected()
    print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Called"
    print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] navigatedFrom: " + m.top.navigatedFrom
    
    MainSceneNode = m.top.getScene()
    MainSceneNode.dialog.close = true
    
    ' Stop video player first
    m.videoPlayer.control = "stop"
    m.top.visible = false
    
    ' Navigate back to the source screen after error dialog is closed
    if m.top.navigatedFrom = "M3UChannels"
        print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Returning to M3U Channels screen"
        
        m3uScreen = m.global.findNode("m3uChannelScreen")
        if m3uScreen <> invalid
            print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Found m3uChannelScreen"
            m3uScreen.visible = true
            
            ' Get the channel grid and restore focus
            channelGrid = m3uScreen.findNode("channelGrid")
            if channelGrid <> invalid
                print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Setting focus on channel grid"
                channelGrid.setFocus(true)
            else
                print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] channelGrid not found, setting focus on screen"
                m3uScreen.setFocus(true)
            end if
            
            print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Focus returned to M3U screen"
        else
            print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] ERROR: m3uChannelScreen not found"
        end if
    else if m.top.navigatedFrom = "Seasons"
        print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Returning to Season screen"
        
        seasonScreen = m.global.findNode("SeasonScreen")
        if seasonScreen <> invalid
            seasonScreen.visible = true
            seasonScreen.setFocus(true)
        end if
    else if m.top.navigatedFrom = "VOD"
        m.global.findNode("vod_screen").setFocus(true)
        m.global.findNode("vod_screen").visible = true
        m.global.findNode("navigation_bar").visible = true
    else if m.top.navigatedFrom = "LIVE"
        m.global.findNode("live_screen").setFocus(true)
        m.global.findNode("live_screen").visible = true
        m.global.findNode("navigation_bar").visible = true
    end if
    
    print "VideoDVRScreen.brs - [On_dialogErrStream_buttonSelected()] Exiting"
end sub

' =============================================================================
' onVisibleChange
' =============================================================================

sub onVisibleChange()

    ' If entering Details screen, set the focus to the first button


    if m.top.visible then

        print "DetailsScreen.brs - [onVisibleChange] Set up DetailsScreen"

        ' Focus first button

        m.buttons.jumpToItem = 0
        m.buttons.setFocus(true)

        ' Set the color of the button (focused)

        m.buttons.focusBitmapBlendColor = m.global.keyColorTint

        ' Set the color of the Overhang and the H.U.D. area at the bottom to the global keyColor

        ' m.overhangBackground.color = m.global.keyColor
        ' m.hudRectangle.color = m.global.keyColor

        ' Start the animation of the background images

        ' m.fadeInBackgroundGroup.control = "start"
        ' m.backgroundPanel.visible = true

        if m.global.deeplinked = "1"

            showPlayer()

            '	m.global.deeplinked="0"

        end if

        ' Else exiting DetailsScreen

    else

        print "DetailsScreen.brs - [onVisibleChange] Tear down DetailsScreen"

        ' Begin to fade out the DetailsScreen

        ' m.fadeOutBackgroundGroup.control = "start"

        ' Stop the animation of the background images

        ' m.backgroundPanel.visible = false

        ' Make sure the Video component is not playing a video and is not visible

        m.videoPlayer.visible = false
        m.videoPlayer.control = "stop"

    end if

end sub

' =============================================================================
' onKeyEvent - Called when a key on the remote is pressed
' =============================================================================

function onKeyEvent(key as string, isPressed as boolean) as boolean

    print "DetailsScreen.brs - [onKeyEvent] key = "; key; ", isPressed = "; isPressed
    
    ' Debug: Check management state immediately
    if key = "back" and isPressed = true then
        print "VideoDVRScreen.brs - [onKeyEvent] *** BACK BUTTON DEBUG ***"
        print "VideoDVRScreen.brs - [onKeyEvent] managedByHomeScene: " + m.top.managedByHomeScene.ToStr()
        print "VideoDVRScreen.brs - [onKeyEvent] buttons.visible: " + m.buttons.visible.ToStr()
    end if

    isKeyEventHandled = false

    ' There doesn't seem to be a way to disable the "Options" in the Overhang in "HeroScene",
    ' so if the options button is pressed, set the flag that the key has been handled so that
    ' it doesn't propagate to "HeroScene"

    if key = "options" then

        isKeyEventHandled = true

        ' If the buttons are hidden (because the user navigated to the "DataPanel" screen), and if the
        ' "left" or "back" button was pressed, then the user is returning to the "Details" screen.

    else if m.buttons.visible = false and (key = "left" or key = "back") then
        ' Check if this is managed by home scene first
        if m.top.managedByHomeScene = true and key = "back" then
            print "VideoDVRScreen.brs - [onKeyEvent] Back button intercepted (buttons hidden) - managed by home scene"
            print "VideoDVRScreen.brs - [onKeyEvent] managedByHomeScene: " + m.top.managedByHomeScene.ToStr()
            print "VideoDVRScreen.brs - [onKeyEvent] sourceScreenIndex: " + m.top.sourceScreenIndex.ToStr()
            print "VideoDVRScreen.brs - [onKeyEvent] *** TRIGGERING HOME SCENE BACK BUTTON ***"
            m.top.backButtonPressed = true
            return true
        else
            ' Original button visibility logic
            m.buttons.visible = true

            ' When backgroundPanel gains focus, the backgroundPanel will slide into view, but
            ' the buttons must then have focus restored so that they are usable (it seem that there
            ' must be a delay before changing the focus to the buttons to ensure that the slide
            ' transition to backgroundPanel actually takes place)

            ' m.backgroundPanel.setFocus(true)
            sleep(1000)
            m.buttons.setFocus(true)

            ' Stop the background animation in the dataPanel (removed - dataPanel not defined)
            ' m.dataPanel.animationControl = "stop"

            isKeyEventHandled = true
        end if

    else if isPressed = true and key = "back" then
        ' Debug: Check management state
        print "VideoDVRScreen.brs - [onKeyEvent] Back button pressed"
        print "VideoDVRScreen.brs - [onKeyEvent] managedByHomeScene: " + m.top.managedByHomeScene.ToStr()
        print "VideoDVRScreen.brs - [onKeyEvent] sourceScreenIndex: " + m.top.sourceScreenIndex.ToStr()
        navigatedFromValue = "invalid"
        if m.top.navigatedFrom <> invalid and m.top.navigatedFrom <> ""
            navigatedFromValue = m.top.navigatedFrom
        end if
        print "VideoDVRScreen.brs - [onKeyEvent] navigatedFrom: " + navigatedFromValue
        
        ' Check if this video player is managed by the home scene
        if m.top.managedByHomeScene = true then
            print "VideoDVRScreen.brs - [onKeyEvent] *** MANAGED BY HOME SCENE - TRIGGERING FIELD ***"
            m.top.backButtonPressed = true
            return true
        else if m.top.navigatedFrom = "VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("vod_screen").setFocus(true)
            m.global.findNode("vod_screen").visible = true
            m.global.findNode("navigation_bar").visible = true
            return true
        else if m.top.navigatedFrom = "LIVE" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("live_screen").setFocus(true)
            m.global.findNode("live_screen").visible = true
            m.global.findNode("navigation_bar").visible = true
            return true
        else if m.top.navigatedFrom = "HOME" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("home_screen").visible = true
            m.global.findNode("home_screen").setFocus(true)
            m.global.findNode("navigation_bar").visible = true
            return true
        else if m.top.navigatedFrom = "Search" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("search_screen").setFocus(true)
            m.global.findNode("navigation_bar").visible = true
            m.global.findNode("search_screen").visible = true
            return true
        else if m.top.navigatedFrom = "TVSHOW" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("saved_screen").setFocus(true)
            m.global.findNode("saved_screen").visible = true
            m.global.findNode("navigation_bar").visible = true
            return true
        else if m.top.navigatedFrom = "DVR" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("DVRListingScreen").setFocus(true)
            m.global.findNode("DVRListingScreen").visible = true
            return true
        else if m.top.navigatedFrom = "Seasons" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("SeasonScreen").setFocus(true)
            m.global.findNode("SeasonScreen").visible = true
            return true
        else if m.top.navigatedFrom = "M3UChannels" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m3uScreen = m.global.findNode("m3uChannelScreen")
            if m3uScreen <> invalid
                m3uScreen.setFocus(true)
                m3uScreen.visible = true
            else
                print "VideoDVRScreen.brs - [onKeyEvent] ERROR: m3uChannelScreen not found"
            end if
            return true
        end if

    end if

    return isKeyEventHandled

end function

'=============================================================================
' onItemSelected - Button press handler
'=============================================================================
sub onItemSelected()

    print "DetailsScreen.brs - [onItemSelected] button = " m.top.itemSelected

    itm = m.buttons.content.getChild(m.top.itemSelected) ''''(m.top.itemSelected)

    print "DetailsScreen.brs - [onItemSelected] button = " itm

    ' Play button
    if itm.id = "1" then
        ' m.backgroundPanel.visible = false
        m.videoPlayer.visible = true
        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
        m.videoPlayer.observeField("state", "onVideoPlayerStateChange")

    else if itm.id = "2" then

        ' m.backgroundPanel.visible = false
        m.videoPlayer.visible = true
        m.videoPlayer.setFocus(true)
        m.videoPlayer.control = "play"
        if (m.top.seekPosition > 0)
            m.videoPlayer.seek = m.top.seekPosition
        end if
        m.videoPlayer.observeField("state", "onVideoPlayerStateChange")

    else if itm.id = "3" then


    else if itm.id = "4" then


    end if

end sub



sub showLoadingDialog(textToShow as string)

    print "DetailsScreen.brs - [showLoadingDialog()] Called"
    progressdialog = createObject("roSGNode", "ProgressDialog")
    progressdialog.title = textToShow

    MainSceneNode = m.top.getScene()
    MainSceneNode.dialog = progressdialog


    print "DetailsScreen.brs - [showLoadingDialog()] Exiting"
end sub





' =============================================================================
' onVideoVisibleChange - Set focus to buttons and stop video if returning to Details from Playback
' =============================================================================

sub onVideoVisibleChange()

    print "DetailsScreen.brs - [onVideoVisibleChange]"

    if m.videoPlayer.visible = false and m.top.visible = true

        ' Make sure the buttons have the focus

        m.buttons.setFocus(true)

        ' Make sure the Video component is not playing a video

        m.videoPlayer.control = "stop"

        ' Re-start the background image animation

        ' m.backgroundPanel.visible = true

    end if

end sub

' =============================================================================
' onVideoPlayerStateChange - Event handler for Video player message
' =============================================================================

sub onVideoPlayerStateChange()

    print "DetailsScreen.brs - [onVideoPlayerStateChange] " m.videoPlayer.state
    

    print "VideoDVRScreen.brs  - [onVideoPlayerStateChange] " m.videoPlayer.content
    if m.videoPlayer.state = "error" then
        print m.videoPlayer.errorMsg
        print "Here is Error message"
        m.videoPlayer.visible = false
        MainSceneNode = m.top.getScene()
        MainSceneNode.dialog = m.dialogErrStream

    else if m.videoPlayer.state = "playing"

        ' Playback complete handling

    else if m.videoPlayer.state = "finished"

        m.videoPlayer.visible = false
        if m.top.navigatedFrom = "VOD" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("vod_screen").setFocus(true)
            m.global.findNode("vod_screen").visible = true
            m.global.findNode("navigation_bar").visible = true

        else if m.top.navigatedFrom = "LIVE" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("live_screen").setFocus(true)
            m.global.findNode("live_screen").visible = true
            m.global.findNode("navigation_bar").visible = true

        else if m.top.navigatedFrom = "HOME" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("home_screen").visible = true
            m.global.findNode("home_screen").setFocus(true)
            m.global.findNode("navigation_bar").visible = true

        else if m.top.navigatedFrom = "Search" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("search_screen").setFocus(true)
            m.global.findNode("navigation_bar").visible = true
            m.global.findNode("search_screen").visible = true

        else if m.top.navigatedFrom = "TVSHOW" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("saved_screen").setFocus(true)
            m.global.findNode("saved_screen").visible = true
            m.global.findNode("navigation_bar").visible = true

        else if m.top.navigatedFrom = "DVR" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("DVRListingScreen").setFocus(true)
            m.global.findNode("DVRListingScreen").visible = true

        else if m.top.navigatedFrom = "Seasons" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m.global.findNode("SeasonScreen").setFocus(true)
            m.global.findNode("SeasonScreen").visible = true

        else if m.top.navigatedFrom = "M3UChannels" then
            m.top.visible = false
            m.videoPlayer.control = "stop"
            m3uScreen = m.global.findNode("m3uChannelScreen")
            if m3uScreen <> invalid
                m3uScreen.setFocus(true)
                m3uScreen.visible = true
            else
                print "VideoDVRScreen.brs - [onVideoPlayerStateChange] ERROR: m3uChannelScreen not found"
            end if

        end if


        ' if m.top.content.isdvr = "1"
        '     epid = m.top.content.id
        '     sec = CreateObject("roRegistrySection", "positions")
        '     sec.Write(epid, Str(0))
        '     sec.Flush()

        '     if m.buttons.content.getChildCount() > 1 then
        '         m.buttons.content.removeChildIndex(1)
        '     end if

        ' end if

    else if m.videoPlayer.state = "stopped"

        epid = m.top.content.id
        print "Episode: ";epid;" Position: ";m.videoPlayer.position


        if m.top.content.isdvr = "1"

            oldposf = m.videoPlayer.position
            print "Writing episode position for "; epid;" ";oldposf;" ";m.videoPlayer.position
            sec = CreateObject("roRegistrySection", "positions")
            sec.Write(epid, Str(oldposf))
            sec.Flush()

            if oldposf > 30
                minutes = oldposf \ 60
                seconds = oldposf mod 60
                ttl = "  Resume ("
                if minutes > 60 then
                    hh = minutes \ 60
                    minutes = minutes \ 60
                    ttl = ttl + hh.toStr() + "h "
                end if

                if minutes > 0 then
                    ttl = ttl + minutes.toStr() + "m "
                end if

                if seconds > 0 then
                    ttl = ttl + seconds.toStr() + "s"
                end if

                ttl = ttl + ")  "
                contentNode = createObject("roSGNode", "ContentNode")

                if m.buttons.content.getChildCount() > 1 then
                    m.buttons.content.removeChildIndex(1)
                    print "m.videoPlayer.position"
                end if

                contentNode.title = ttl
                contentNode.id = 2
                m.buttons.content.appendChild(contentNode)
                m.top.seekPosition = oldposf
            end if
        end if
    end if

end sub


' =============================================================================
' onContentChange
' =============================================================================

sub onContentChange()

    print "DetailsScreen.brs - [onContentChange]"

    ' Set the Overhang title to the name of the selected media (if available)
    if m.top.content.channel <> invalid and Len(m.top.content.channel) > 0 then
        m.detailsOverhang.title = m.top.content.channel
    else if m.top.content.title <> invalid and Len(m.top.content.title) > 0 then
        m.detailsOverhang.title = m.top.content.title
    else
        m.detailsOverhang = "Exploration"
    end if

    epid = m.top.content.id
    registry = getRegistry()
    if m.top.content.isdvr <> invalid and m.top.content.isdvr = "1" then
        print "Reading position for episode ";epid
        sec = CreateObject("roRegistrySection", "positions")
        if (sec.Exists(epid))
            oldpos = sec.Read(epid)
        else
            oldpos = "0"
        end if
        oldposf = Val(oldpos)
    else
        oldposf = 0
    end if

    ' Initialize the Description component that present information about the selected media item
    m.description.content = m.top.content
    m.description.Description.width = "1120"

    ' Assign the selected media content to the Video component
    m.videoPlayer.content = m.top.content
    if m.top.content.isdvr = "0"
        m.videoPlayer.enableTrickPlay = false
    else
        m.videoPlayer.enableTrickPlay = true
    end if

    print "Episode: ";epid;" Position: ";m.videoPlayer.position

    ' Initialize the Poster images with the URI of the the content's background image

    if m.top.content.isdvr <> invalid and m.top.content.isdvr = "1" then
        m.poster.uri = m.top.content.hdposterurl
        m.backgroundPanel.imageURL = m.top.content.hdposterurl
        ' m.backgroundPanel.visible = true
    else
        showPlayer()
    end if
end sub

' =============================================================================
' contentList2SimpleNode - Helper function convert AA to Node
' =============================================================================

function contentList2SimpleNode(contentList as object, nodeType = "ContentNode" as string) as object

    print "DetailsScreen.brs - [contentList2SimpleNode]"

    result = createObject("roSGNode", nodeType)

    if result <> invalid

        for each itemAA in contentList
            item = createObject("roSGNode", nodeType)
            item.setFields(itemAA)
            result.appendChild(item)
        end for

    end if

    return result

end function


sub showPlayer()

    print "DetailsScreen.brs - [showPlayer] "

    ' m.backgroundPanel.visible = false

    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"

    m.videoPlayer.TrickPlayBar.filledBarBlendColor = "#f16667"


    print m.videoPlayer.bufferingBar
    print "here is a Buffering Bar"

    m.videoPlayer.observeField("state", "onVideoPlayerStateChange")


end sub











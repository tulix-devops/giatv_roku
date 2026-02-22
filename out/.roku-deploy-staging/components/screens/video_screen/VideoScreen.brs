function Init()

    m.top.isResetSuccessful = false
    m.focusedBtnColor = "0xbfd3d9AA"
    m.unFocusedBtnColor = "0xbfd3d930"
    m.focusedLabelBtnColor = "0xFFFFFF"
    m.unFocusedLabelBtnColor = "0x848484"
    m.focusedFieldColor = "0x848484FF"
    m.unFocusedFieldColor = "0x63636366"

    m.maxControlsOnScreen = 3
    m.selectedControlIndex = 0
    m.selectedButtonIndex = 0

    m.isPlayBtn = false
    m.bIsPlaybackStarted = false
    m.bIsShowingPlaybar = true
    m.timerSincePlaybarVisible = 0

    m.currentTime = CreateObject("roDateTime") ' roDateTime is initialized
    m.currentTime.ToLocalTime()

    m.seekCounter = 0
    m.isSeekReqInitiated = false
    m.isSeekForward = false
    m.seekToPosition = -1
    m.seekIncrementDefault = 20
    m.seekIncrementSecs = 20
    m.currProgStartTime = 0
    m.containerPlayBar = m.top.findNode("containerPlayBar")



    m.programPoster = m.top.findNode("programPoster")
    m.labelProgramTitle = m.top.findNode("labelProgramTitle")
    m.labelChannelProgInfo = m.top.findNode("labelChannelProgInfo")
    m.labelProgramDescription = m.top.findNode("labelProgramDescription")
    m.playerTimeBar = m.top.findNode("playerTimeBar")

    m.containerPlayBarStats = m.top.findNode("containerPlayBarStats")

    m.iconRewind = m.top.findNode("iconRewind")
    m.iconForward = m.top.findNode("iconForward")
    m.iconPlayPause = m.top.findNode("iconPlayPause")
    m.labelCurrPlayTime = m.top.findNode("labelCurrPlayTime")
    m.labelTotalDuration = m.top.findNode("labelTotalDuration")

    m.iconIsHD = m.top.findNode("isHdIcon")
    m.iconIsCC = m.top.findNode("isCCIcon")

    m.iconIsHD.visible = false
    m.iconIsCC.visible = false
    m.containerPlayBarStats.visible = true


    m.iconPlayPause.uri = "pkg:/images/play-icon.png"
    m.labelCurrPlayTime.text = "00:00"
    m.playerTimeBar.duration = 1
    m.playerTimeBar.position = 0

    m.spinner = m.top.FindNode("spinner")

    m.videoDVRPlayer = m.top.findNode("videoDVRPlayer")
    m.videoDVRPlayer.enableUI = false
    m.videoDVRPlayer.enableTrickPlay = false
    m.videoDVRPlayer.disableScreenSaver = true
    m.videoDVRPlayer.globalCaptionMode = m.global.enablecc '''''''"On"

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
    }
    hvideo.SetHeaders(hvideoheaders)
    m.videoDVRPlayer.setHttpAgent(hvideo)

    ' m.timerCurrTimeSetter = m.top.findNode("timerCurrentTime")
    ' m.timerCurrTimeSetter.control = "start"
    ' m.timerCurrTimeSetter.ObserveField("fire", "on1SecTimerEventFired")

    m.pauseButton = m.top.findNode("pauseButton")
    ' m.videoPlayer.enableUI = false


    setRewindIconState()
    setForwardIconState()
    ' SetCurrentTimeHrsMins()

    focusUnFocusControls()

end function

sub unFocusAllControls()

    ' m.btnReset.color = m.unFocusedBtnColor
    ' m.labelBtnReset.font="font:MediumSystemFont"
    ' m.btnCancel.color = m.unFocusedBtnColor
    ' m.labelBtnCancel.font="font:MediumSystemFont"

    ' m.boxInputFieldEmail.color=m.unFocusedFieldColor
    ' m.labelInputEmailField.font="font:MediumSystemFont"

end sub

sub focusUnFocusControls()

    unFocusAllControls()

    if m.selectedControlIndex = 0 then
        ' m.boxInputFieldEmail.color=m.focusedFieldColor
        ' m.labelInputEmailField.font="font:MediumBoldSystemFont"
    else if m.selectedControlIndex = 1 then
        ' m.btnCancel.color = m.focusedBtnColor
        ' m.labelBtnCancel.font="font:MediumBoldSystemFont"
    else if m.selectedControlIndex = 2 then
        ' m.btnReset.color = m.focusedBtnColor
        ' m.labelBtnReset.font="font:MediumBoldSystemFont"
    end if

end sub

sub keyControlOKForControlsHandler()

    if m.bIsShowingPlaybar = false then

    else
        if m.selectedControlIndex = 0 then
            print "VideoPlayerDVRScreenView.brs - [keyControlOKForControlsHandler()] Email TXT Field "
        else if m.selectedControlIndex = 1 then
            print "VideoPlayerDVRScreenView.brs - [keyControlOKForControlsHandler()] Cancel Button "
        else if m.selectedControlIndex = 2 then
            print "VideoPlayerDVRScreenView.brs - [keyControlOKForControlsHandler()] Submit Button "
        end if
    end if
    togglePlayBarVisibility()
end sub


sub setUnsetBufferStatus()
    ' print "VideoPlayerDVRScreenView.brs - [setUnsetBufferStatus()] Called "
    if m.videoDVRPlayer.state = "buffering" then
        ShowSpinner(true)
    else
        ShowSpinner(false)
    end if
end sub

sub onProgramContentChanged()
    print "VideoPlayerDVRScreenView.brs - [onProgramContentChanged()] Called "
    onContentSet()
end sub

' sub checkPlayerPlaybackFinished()
'     ' print "VideoPlayerDVRScreenView.brs - [checkPlayerPlaybackFinished()] Called "
'     if m.videoDVRPlayer.state = "finished" OR m.videoDVRPlayer.state = "stopped" OR m.videoDVRPlayer.state = "error" then
'         print "VideoPlayerDVRScreenView.brs - [checkPlayerPlaybackFinished()] Playback Stopped with  " m.videoDVRPlayer.state
'         ' Exit Player
'         exitPlayer()
'     end if
' end sub

sub checkPlayerPlaybackFinished()
    ' print "VideoPlayerDVRScreenView.brs - [checkPlayerPlaybackFinished()] Called "
    if m.videoDVRPlayer.state = "finished" or m.videoDVRPlayer.state = "stopped" or m.videoDVRPlayer.state = "error" then
        print "VideoPlayerDVRScreenView.brs - [checkPlayerPlaybackFinished()] Playback Stopped with  " m.videoDVRPlayer.state
        if m.videoDVRPlayer.errorCode < 0 then
            print "VideoPlayerDVRScreenView.brs - [checkPlayerPlaybackFinished()] We have an Error showing Offline "
            showErrorProgramOfflineDialog()
        else
            exitPlayer()
        end if
    end if
end sub


sub checkAutoHidePlaybar()
    ' print "VideoPlayerDVRScreenView.brs - [checkPlayerPlaybackFinished()] Called "
    if m.isSeekReqInitiated = false and m.bIsShowingPlaybar = true and m.videoDVRPlayer.state = "playing" then
        ' print "VideoPlayerDVRScreenView.brs - [checkPlayerPlaybackFinished()] Playback Stopped with  " m.videoDVRPlayer.state
        m.timerSincePlaybarVisible = m.timerSincePlaybarVisible + 1
        if m.timerSincePlaybarVisible > 7 then
            togglePlayBarVisibility()
        end if
    end if
end sub

sub updatePlayerPlaybackPosition()
    ' print "VideoPlayerDVRScreenView.brs - [updatePlayerPlaybackPosition()] Called "
    if m.videoDVRPlayer.state = "playing" or m.videoDVRPlayer.state = "paused" or m.videoDVRPlayer.state = "buffering" then
        ' print "VideoPlayerDVRScreenView.brs - [updatePlayerPlaybackPosition()] Playback position  " m.videoDVRPlayer.position
        m.labelCurrPlayTime.text = getPlaybackMinAndSecsFromTime(m.videoDVRPlayer.position)
        m.playerTimeBar.position = m.videoDVRPlayer.position
    end if
end sub

sub on1SecTimerEventFired()
    ' print "VideoPlayerDVRScreenView.brs - [on1SecTimerEventFired()] Called "
    setUnsetBufferStatus()
    updatePlayerPlaybackPosition()
    checkAutoHidePlaybar()
    checkPlayerPlaybackFinished()
    if m.isSeekReqInitiated = true then
        playMaxDuration = m.seekIncrementSecs
        if m.top.contentProgram <> invalid then
            playMaxDuration = m.top.contentProgram.PLAYDURATION
        end if
        if m.isSeekForward = true
            m.seekToPosition = m.seekToPosition + m.seekIncrementSecs
        else
            m.seekToPosition = m.seekToPosition - m.seekIncrementSecs
        end if
        if m.seekToPosition < 0
            m.seekToPosition = 0
        else if m.seekToPosition >= playMaxDuration
            m.seekToPosition = m.seekToPosition - m.seekIncrementSecs
        end if
        print "VideoPlayerDVRScreenView.brs - [on1SecTimerEventFired()] m.seekToPosition " m.seekToPosition
        m.playerTimeBar.seekPosition = m.seekToPosition
    end if

end sub

function getPlaybackMinAndSecsFromTime(positionTime)

    strTimeMinSecs = "00:00:00"
    ' print "VideoPlayerDVRScreenView.brs - [getPlaybackMinAndSecsFromTime()] Called " positionTime
    strHrsPrefix = ""
    strMinsPrefix = ""
    strSecsPrefix = ""

    secs = positionTime mod 60
    timeToMins = Int(positionTime / 60)
    mins = timeToMins mod 60
    hrs = Int(positionTime / 3600)

    if secs < 10 then
        strSecsPrefix = "0"
    end if
    if mins < 10 then
        strMinsPrefix = "0"
    end if
    if hrs < 10 then
        strHrsPrefix = "0"
    end if

    ' print "VideoPlayerDVRScreenView.brs - [SetCurrentTimeHrsMins()] secs " secs
    strTimeMinSecs = strHrsPrefix + hrs.toStr() + ":" + strMinsPrefix + mins.toStr() + ":" + strSecsPrefix + secs.toStr()
    ' print "VideoPlayerDVRScreenView.brs - [SetCurrentTimeHrsMins()] strTimeMinSecs " strTimeMinSecs

    return strTimeMinSecs

end function

function GetProgramDateAndTimeRange(timeSecs as integer, duration as integer)
    print "VideoPlayerDVRScreenView.brs - [GetProgramDateAndTimeRange()] Called with timeSecs " timeSecs " duration " duration

    dateTimeObj = CreateObject("roDateTime")
    dateTimeObj.FromSeconds(timeSecs)

    dateTimeObj.ToLocalTime()
    datePartOrig = dateTimeObj.AsDateString("short-month-short-weekday")
    totalCharsDatePart = Len(datePartOrig)
    strDatePart = Left(datePartOrig, totalCharsDatePart - 6)
    strDayPart = Left(strDatePart, 3)
    strDayMonth = Right(strDatePart, (Len(strDatePart) - 3))
    print "VideoPlayerDVRScreenView.brs - [GetProgramDateAndTimeRange()] datePartOrig " datePartOrig


    ' strStartRange = hoursModed.toStr() + ":" + strMinsPrefix + mins.toStr() + strAmPm
    strStartRange = getTimeFromDateObjectWithSeconds(dateTimeObj, timeSecs)
    strEndRange = getTimeFromDateObjectWithSeconds(dateTimeObj, (timeSecs + duration))

    dateTimeObj.ToLocalTime()

    strDateTimeRange = strDayPart + "," + strDayMonth + " | " + strStartRange + " - " + strEndRange

    return strDateTimeRange
end function

function getTimeFromDateObjectWithSeconds(dateTimeObj as object, timeSecs as integer)
    dateTimeObj.FromSeconds(timeSecs)

    strAmPm = " am"
    strMinsPrefix = ""

    dateTimeObj.ToLocalTime()

    mins = dateTimeObj.GetMinutes()
    hours = dateTimeObj.GetHours()
    hoursModed = hours mod 12

    if hours >= 12 then
        strAmPm = " pm"
    end if
    if mins < 10 then
        strMinsPrefix = "0"
    end if

    if hoursModed = 0
        hoursModed = 12
    end if
    ' print "VideoPlayerDVRScreenView.brs - [getTimeFromDateObjectWithSeconds()] mins " mins
    ' print "VideoPlayerDVRScreenView.brs - [getTimeFromDateObjectWithSeconds()] hours " hours
    ' print "VideoPlayerDVRScreenView.brs - [getTimeFromDateObjectWithSeconds()] hoursModed " hoursModed


    strTimeStamp = hoursModed.toStr() + ":" + strMinsPrefix + mins.toStr() + strAmPm

    return strTimeStamp
end function

sub playLiveVideo(progContent as object)
    print "Do we get to The Play Video"
    print "VideoPlayerDVRScreenView.brs - [playLiveVideo()] Called progContent " progContent
    if progContent.url = ""
        print "VideoPlayerDVRScreenView.brs - [playLiveVideo()] Exiting from Top as empty progContent.url " progContent.url
        return
    end if

    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.url = progContent.url
    videoContent.id = progContent.id
    videoContent.starttime = ""
    videoContent.PLAYDURATION = progContent.PLAYDURATION
    videoContent.title = progContent.title
    videoContent.streamformat = "hls"
    videoContent.subtitleConfig = {
        trackName: "eia608/1"
    }

    m.timerCurrTimeSetter = m.top.findNode("timerCurrentTime")
    m.timerCurrTimeSetter.control = "start"
    m.timerCurrTimeSetter.ObserveField("fire", "on1SecTimerEventFired")

    print "VideoPlayerDVRScreenView.brs - [playLiveVideo()] Not Currently Playing any so Starting videoContent.url " videoContent.url
    m.videoDVRPlayer.content = videoContent
    m.videoDVRPlayer.control = "play"

    print "are We Getting here whenever Player is called ? "
    m.iconPlayPause.uri = "pkg:/images/pause-icon.png"
    m.isPlayBtn = true

end sub


sub onContentSet()

    print "VideoPlayerDVRScreenView.brs - [onContentSet()] Called "
    print "VideoPlayerDVRScreenView.brs - [onContentSet()] contentProgram " m.top.contentProgram

    m.iconIsHD.visible = false
    m.iconIsCC.visible = false
    m.playerTimeBar.position = 0
    m.playerTimeBar.duration = 0
    m.labelProgramTitle.text = ""
    m.labelProgramDescription.text = ""
    m.labelProgramDescription.text = ""
    ' m.currProgStartTime = 0
    m.programPoster.uri = ""
    m.programPoster.visible = true
    ' m.containerProgramVidStats.visible = false
    if m.videoDVRPlayer.state = "playing" or m.videoDVRPlayer.state = "paused" or m.videoDVRPlayer.state = "buffering"
        m.videoDVRPlayer.control = "stop"
    end if
    preparePlayerForChannel()
end sub

sub preparePlayerForChannel()
    if m.top.contentProgram <> invalid
        print "VideoPlayerDVRScreenView.brs - [onContentSet()] m.top.contentProgram " m.top.contentProgram
        m.programPoster.uri = m.top.contentProgram.hdposterurl
        m.labelProgramTitle.text = m.top.contentProgram.title
        m.labelProgramDescription.text = m.top.contentProgram.description
        m.labelChannelProgInfo.text = m.top.contentProgram.channelTitle
        '  + " | " + GetProgramDateAndTimeRange(m.top.contentProgram.PLAYSTART, m.top.contentProgram.PLAYDURATION)

        if m.top.contentProgram.isCC = "true" then
            m.iconIsCC.visible = true
        else
            m.iconIsCC.visible = false
        end if

        if m.top.contentProgram.isHD = "true" then
            m.iconIsHD.visible = true
        else
            m.iconIsHD.visible = false
        end if
        print m.top.contentProgram
        print "Check contentProgram we are getting here"
        m.playerTimeBar.duration = m.top.contentProgram.PLAYDURATION
        m.labelTotalDuration.text = getPlaybackMinAndSecsFromTime(m.top.contentProgram.PLAYDURATION)
        playLiveVideo(m.top.contentProgram)
        ' m.bIsShowingPlaybar = true
        ' m.containerPlayBar.visible = true
    end if

end sub

sub exitPlayer()
    print "VideoPlayerDVRScreenView.brs - [exitPlayer()] Called Closing LiveVideoPlayerScreen"
    if m.videoDVRPlayer.state = "playing" or m.videoDVRPlayer.state = "paused" or m.videoDVRPlayer.state = "buffering"
        m.videoDVRPlayer.control = "stop"
    end if
    m.timerCurrTimeSetter.control = "paused"
    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.url = ""
    m.videoDVRPlayer.content = videoContent
    m.videoDVRPlayer.control = "stop"
    m.bIsShowingPlaybar = false
    ' m.top.contentURL = ""

    m.maxControlsOnScreen = 3
    m.selectedControlIndex = 0
    m.selectedButtonIndex = 0
    m.isPlayBtn = false
    m.bIsPlaybackStarted = false
    m.bIsShowingPlaybar = true
    m.timerSincePlaybarVisible = 0
    m.seekCounter = 0
    m.isSeekReqInitiated = false
    m.isSeekForward = false
    m.seekToPosition = -1
    m.seekIncrementDefault = 20
    m.seekIncrementSecs = 20
    m.currProgStartTime = 0
    m.iconIsHD.visible = false
    m.iconIsCC.visible = false
    m.containerPlayBarStats.visible = true
    ' m.labelCurrPlayTime.text = "00:00"
    m.playerTimeBar.duration = 1
    m.playerTimeBar.position = 0

    m.top.visible = false
    m.global.findNode("navigation_bar").visible = true
    if m.top.navigatedFrom = "VOD" then
        m.global.findNode("vod_screen").setFocus(true)
        m.global.findNode("vod_screen").visible = true

    else if m.top.navigatedFrom = "LIVE" then
        m.global.findNode("live_screen").setFocus(true)

        m.global.findNode("live_screen").visible = true

    else if m.top.navigatedFrom = "HOME" then
        m.global.findNode("home_screen").setFocus(true)
        m.global.findNode("home_screen").visible = true

    else if m.top.navigatedFrom = "Search" then
        m.global.findNode("search_screen").setFocus(true)
        m.global.findNode("search_screen").visible = true

    end if
    
    

end sub

sub seekRewindPlayer(increment as integer)
    print "VideoPlayerDVRScreenView.brs - [seekRewindPlayer()] Called "
    if m.videoDVRPlayer.state = "playing" or m.videoDVRPlayer.state = "paused" or m.videoDVRPlayer.state = "buffering"
        m.videoDVRPlayer.seek = m.videoDVRPlayer.position - increment
    end if
end sub

sub seekRewindRequested()
    print "VideoPlayerDVRScreenView.brs - [seekRewindRequested()] Called "
    m.isSeekForward = false
    m.isSeekReqInitiated = true
end sub

sub seekForwardRequested()
    print "VideoPlayerDVRScreenView.brs - [seekForwardRequested()] Called "
    m.isSeekForward = true
    m.isSeekReqInitiated = true
end sub

sub seekForwardPlayer(increment as integer)
    print "VideoPlayerDVRScreenView.brs - [seekForwardPlayer()] Called "
    if m.videoDVRPlayer.state = "playing" or m.videoDVRPlayer.state = "paused" or m.videoDVRPlayer.state = "buffering"
        m.videoDVRPlayer.seek = m.videoDVRPlayer.position + increment
    end if
end sub

sub pausePlayer()
    print "VideoPlayerDVRScreenView.brs - [pausePlayer()] Called "
    if m.videoDVRPlayer.state = "playing" or m.videoDVRPlayer.state = "buffering"
        m.videoDVRPlayer.control = "pause"
        m.iconPlayPause.uri = "pkg:/images/play-icon.png"
    end if
end sub

sub resumePlayer()
    print "VideoPlayerDVRScreenView.brs - [resumePlayer()] Called "
    if m.isSeekReqInitiated = true then
        ' if m.isSeekForward = true then
        ' else
        ' end if
        m.videoDVRPlayer.seek = m.seekToPosition
        m.seekCounter = 0
        setRewindIconState()
        setForwardIconState()
    end if
    m.isSeekReqInitiated = false
    m.playerTimeBar.seekPosition = 0
    if m.videoDVRPlayer.state = "playing" or m.videoDVRPlayer.state = "paused" or m.videoDVRPlayer.state = "buffering"
        m.videoDVRPlayer.control = "resume"
        m.iconPlayPause.uri = "pkg:/images/pause-icon.png"
    end if
end sub

' Overridden Key event handler for button focus processing
function onKeyEvent(key as string, bPressed as boolean) as boolean
    result = false
    print "VideoPlayerDVRScreenView.brs - [onKeyEvent()] Called " key " bPressed " bPressed
    ' if bPressed AND (key = "left" OR key = "right" OR key = "up" OR key = "down") then
    if bPressed and (key = "back") then
        print "VideoPlayerDVRScreenView.brs - [onKeyEvent()] Closing LiveVideoPlayerScreen"
        result = false
        exitPlayer()
        return true
    else if bPressed and (key = "options") then
    else if bPressed and (key = "OK") then
        print bPressed
        print key
        print "Ok has Been Clicked"
        ' refreshLastUserInteractionWithPlayBar()
        if m.isSeekReqInitiated = true then
            m.isPlayBtn = (not m.isPlayBtn)
            if m.isPlayBtn = true then
                resumePlayer()
            else
                pausePlayer()
            end if
        else
            keyControlOKForControlsHandler()
        end if
        result = true
    else if bPressed and ((key = "fastforward") or (key = "right"))then
        forceShowPlayBar()
        refreshLastUserInteractionWithPlayBar()
        if m.isSeekForward = true then
            m.seekCounter = m.seekCounter + 1
            if m.seekCounter > 3
                m.seekCounter = 3
            end if
        else
            m.seekCounter = m.seekCounter - 1
            if m.seekCounter <= 0
                m.seekCounter = 1
            end if
        end if
        if m.isSeekReqInitiated = false then
            m.isSeekForward = true
            m.isSeekReqInitiated = true
            m.seekIncrementSecs = m.seekIncrementDefault
            m.seekToPosition = m.playerTimeBar.position
            m.isPlayBtn = false
            pausePlayer()
        else
            m.seekIncrementSecs = (m.seekIncrementDefault * m.seekCounter)
            if m.seekIncrementSecs = 0 then
                m.seekIncrementSecs = m.seekIncrementDefault
            end if
        end if

        if m.isSeekForward = true then
            setForwardIconState()
        else
            setRewindIconState()
        end if
        result = true
        ' m.selectedControlIndex += 1

        ' if m.selectedControlIndex >= m.maxControlsOnScreen then
        '     m.selectedControlIndex = m.maxControlsOnScreen - 1
        ' end if
        ' focusUnFocusControls()
    else if bPressed and ((key = "rewind") or (key = "left"))then
        forceShowPlayBar()
        refreshLastUserInteractionWithPlayBar()
        if m.isSeekForward = false then
            m.seekCounter = m.seekCounter + 1
            if m.seekCounter > 3
                m.seekCounter = 3
            end if
        else
            m.seekCounter = m.seekCounter - 1
            if m.seekCounter <= 0
                m.seekCounter = 1
            end if
        end if

        if m.isSeekReqInitiated = false then
            m.isSeekForward = false
            m.isSeekReqInitiated = true
            m.seekIncrementSecs = m.seekIncrementDefault
            m.seekToPosition = m.playerTimeBar.position
            m.isPlayBtn = false
            pausePlayer()
        else
            ' m.seekIncrementSecs += m.seekIncrementDefault
            m.seekIncrementSecs = (m.seekIncrementDefault * m.seekCounter)
            if m.seekIncrementSecs = 0 then
                m.seekIncrementSecs = m.seekIncrementDefault
            end if
        end if

        if m.isSeekForward = true then
            setForwardIconState()
        else
            setRewindIconState()
        end if

        result = true
    else if bPressed and (key = "play") then
        forceShowPlayBar()
        refreshLastUserInteractionWithPlayBar()
        m.isPlayBtn = (not m.isPlayBtn)
        if m.isPlayBtn = true then
            resumePlayer()
        else
            pausePlayer()
        end if
    else
        result = false
    end if
    return result
end function


sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub

sub forceShowPlayBar()
    m.bIsShowingPlaybar = true
    m.containerPlayBar.visible = true
    m.timerSincePlaybarVisible = 0
end sub

sub togglePlayBarVisibility()

    m.bIsShowingPlaybar = (not m.bIsShowingPlaybar)
    if m.bIsShowingPlaybar = true
        m.containerPlayBar.visible = true
        m.timerSincePlaybarVisible = 0
    else
        m.containerPlayBar.visible = false
    end if
end sub

sub refreshLastUserInteractionWithPlayBar()

    if m.bIsShowingPlaybar = true
        m.timerSincePlaybarVisible = 0
    end if
end sub

sub setRewindIconState()

    if m.seekCounter = 0 then
        m.iconRewind.uri = "pkg:/images/r-1x-def.png"
    else if m.seekCounter = 1 then
        m.iconRewind.uri = "pkg:/images/r-1x.png"
    else if m.seekCounter = 2 then
        m.iconRewind.uri = "pkg:/images/r-2x.png"
    else if m.seekCounter = 3 then
        m.iconRewind.uri = "pkg:/images/r-3x.png"
    end if
end sub

sub setForwardIconState()

    if m.seekCounter = 0 then
        m.iconForward.uri = "pkg:/images/ff-1x-def.png"
    else if m.seekCounter = 1 then
        m.iconForward.uri = "pkg:/images/ff-1x.png"
    else if m.seekCounter = 2 then
        m.iconForward.uri = "pkg:/images/ff-2x.png"
    else if m.seekCounter = 3 then
        m.iconForward.uri = "pkg:/images/ff-3x.png"
    end if
end sub

sub showErrorProgramOfflineDialog()
    print "VideoPlayerDVRScreenView.brs - [showErrorProgramOfflineDialog()]"
    ShowSpinner(false)
    m.dialogInfo = CreateObject("roSGNode", "BackDialog")
    m.dialogInfo.title = "Playback Failed!"
    m.dialogInfo.buttons = ["Close"]
    m.dialogInfo.ObserveField("buttonSelected", "onDialogChannelOfflineClosed")
    m.dialogInfo.message = "Program " + m.top.contentProgram.title + " is Offline"
    m.top.GetScene().dialog = m.dialogInfo
end sub

sub onDialogChannelOfflineClosed()
    TopDialogClose()
    exitPlayer()
end sub

sub ShowSpinner(show)
    m.spinner.visible = show
    if show
        m.spinner.control = "start"
    else
        m.spinner.control = "stop"
    end if
end sub

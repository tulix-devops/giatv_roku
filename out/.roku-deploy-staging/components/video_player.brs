sub init()
    ' m.top.observeField("contentURL", "onContentURLChanged")
    ' m.videoPlayer = m.top.findNode("videoPlayer")
    ' print m.videPlayer "So VideoPlayer Doesnt Exist"
    ' m.pauseButton = m.top.findNode("pauseButton")

    ' m.pauseButton.setFocus(true) ' Set initial focus to the pause button
    ' m.videoPlayer.observeField("state", "onVideoStateChange")
    ' m.videoPlayer.control = "play" ' Start playing immediately

    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.url = "https://bozztv.com/dvrfl05/gin-armeniaeu1/tracks-v1a1/mono.m3u8"
    videoContent.streamFormat = "hls" ' Specify the stream format, if known
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.videoPlayer.content = videoContent
    ' m.videoPlayer.control = "play"
    m.pauseButton = m.top.findNode("pauseButton")
    m.fullscreenButton = m.top.findNode("fullscreenButton")
    m.videoPlayer.enableUI = false
    ' m.pauseButton.observeField("buttonSelected", "onPauseButtonSelected")
    m.fullscreenButton.observeField("buttonSelected", "onFullscreenButtonSelected")

end sub


sub onPauseButtonSelected()
    if m.videoPlayer.state = "play"
        m.videoPlayer.control = "pause"
    else
        m.videoPlayer.control = "play"
    end if
end sub

sub onFullscreenButtonSelected()
    if m.videoPlayer.fullScreen = false
        m.videoPlayer.fullScreen = true
    else
        m.videoPlayer.fullScreen = false
    end if
end sub

sub onContentURLChanged()
    url = m.top.contentURL
    if url <> invalid and url <> ""
        content = createObject("roSGNode", "ContentNode")
        content.url = url
        m.videoPlayer.content = content
    end if
end sub

sub onVideoStateChange()
    if m.videoPlayer.state = "playing"
        m.pauseButton.text = "Pause"
    else
        m.pauseButton.text = "Play"
    end if
end sub

' Handle remote key presses
function onKeyEvent(key as string, press as boolean) as boolean
    if key = "OK" and press
        if m.videoPlayer.state = "playing"
            m.videoPlayer.control = "pause"
        else
            m.videoPlayer.control = "play"
        end if
        return true
    else if key = "up" then
        return true
    else if key = "down" then

        return true
    else if key = "right" then
        m.videoPlayer = m.top.findNode("videoPlayer")
        ' InitScreenStack()
        ' ShowScreen(m.videoPlayer)
    end if
    return false
end function


sub InitScreenStack()
    m.screenStack = []
end sub

sub ShowScreen(node as Object)
    ' prev = m.screenStack.Peek() ' take current screen from screen stack but don't delete it
    ' if prev <> invalid
    '     prev.visible = false ' hide current screen if it exist
    ' end if
    m.top.AppendChild(node) ' add new screen to scene
    ' show new screen
    node.visible = true
    node.SetFocus(true)
    m.screenStack.Push(node) ' add new screen to the screen stack
end sub

sub CloseScreen(node as Object)
    if node = invalid OR (m.screenStack.Peek() <> invalid AND m.screenStack.Peek().IsSameNode(node))
        last = m.screenStack.Pop() ' remove screen from screenStack
        last.visible = false ' hide screen
        m.top.RemoveChild(last) ' remove screen from scene

        ' take previous screen and make it visible
        prev = m.screenStack.Peek()
        if prev <> invalid
            prev.visible = true
            prev.SetFocus(true)
        end if
    end if
end sub
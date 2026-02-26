sub init()
    print "M3UChannelScreen.brs - [init] Initializing M3U Channel Screen"
    
    m.top = m.top
    m.channelGrid = m.top.findNode("channelGrid")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.errorGroup = m.top.findNode("errorGroup")
    m.errorMessage = m.top.findNode("errorMessage")
    m.headerTitle = m.top.findNode("headerTitle")
    
    ' Store parsed channels
    m.channels = []
    m.channelCache = invalid
    
    ' Set up grid observers
    m.channelGrid.observeField("itemSelected", "onChannelSelected")
    
    print "M3UChannelScreen.brs - [init] Initialization complete"
end sub

sub onM3uUrlChanged()
    print "M3UChannelScreen.brs - [onM3uUrlChanged] M3U URL changed: " + m.top.m3uUrl
    
    if m.top.m3uUrl <> "" and m.top.m3uUrl <> invalid
        loadM3UPlaylist()
    end if
end sub

sub loadM3UPlaylist()
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Starting to load M3U playlist"
    print "M3UChannelScreen.brs - [loadM3UPlaylist] URL: " + m.top.m3uUrl
    
    ' Show loading state
    m.loadingGroup.visible = true
    m.channelGrid.visible = false
    m.errorGroup.visible = false
    
    ' Create URL transfer object
    m.urlTransfer = CreateObject("roUrlTransfer")
    m.urlTransfer.SetUrl(m.top.m3uUrl)
    m.urlTransfer.EnablePeerVerification(false)
    m.urlTransfer.EnableHostVerification(false)
    m.urlTransfer.RetainBodyOnError(true)
    m.urlTransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    
    ' Set port for async request
    m.port = CreateObject("roMessagePort")
    m.urlTransfer.SetPort(m.port)
    
    print "M3UChannelScreen.brs - [loadM3UPlaylist] Initiating async GET request"
    
    ' Start async request
    if m.urlTransfer.AsyncGetToString()
        print "M3UChannelScreen.brs - [loadM3UPlaylist] Async request started successfully"
        ' Create timer to poll for response
        m.responseTimer = CreateObject("roSGNode", "Timer")
        m.responseTimer.duration = 0.1
        m.responseTimer.repeat = true
        m.responseTimer.observeField("fire", "checkM3UResponse")
        m.responseTimer.control = "start"
    else
        print "M3UChannelScreen.brs - [loadM3UPlaylist] ERROR: Failed to start async request"
        showError("Failed to start download")
    end if
end sub

sub checkM3UResponse()
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
    
    if m.channels.Count() > 0
        buildChannelGrid()
    else
        showError("No channels found in playlist")
    end if
end sub

sub buildChannelGrid()
    print "M3UChannelScreen.brs - [buildChannelGrid] Building channel grid with " + m.channels.Count().ToStr() + " channels"
    
    ' Hide loading
    m.loadingGroup.visible = false
    
    ' Create content node for grid
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    ' Add channels to grid (we'll display them in a single scrollable row for now)
    rowNode = contentNode.createChild("ContentNode")
    rowNode.title = "All Channels (" + m.channels.Count().ToStr() + ")"
    
    for each channel in m.channels
        itemNode = rowNode.createChild("ContentNode")
        itemNode.title = channel.name
        
        if channel.channelNumber <> invalid
            itemNode.description = "Ch " + channel.channelNumber
        else
            itemNode.description = ""
        end if
        
        if channel.category <> invalid
            itemNode.shortDescriptionLine2 = channel.category
        end if
        
        if channel.logo <> invalid and channel.logo <> ""
            itemNode.HDPosterUrl = channel.logo
            itemNode.FHDPosterUrl = channel.logo
        else
            ' Use placeholder - just use background for now
            itemNode.HDPosterUrl = "pkg:/images/background.png"
        end if
        
        ' Store the stream URL in a custom field
        itemNode.streamUrl = channel.url
    end for
    
    ' Set content and show grid
    m.channelGrid.content = contentNode
    m.channelGrid.visible = true
    m.channelGrid.setFocus(true)
    
    print "M3UChannelScreen.brs - [buildChannelGrid] Grid built and displayed"
end sub

sub onChannelSelected()
    selectedItem = m.channelGrid.itemFocused
    print "M3UChannelScreen.brs - [onChannelSelected] Channel selected at index: [" + selectedItem[0].ToStr() + ", " + selectedItem[1].ToStr() + "]"
    
    ' Get the selected channel
    content = m.channelGrid.content
    if content <> invalid
        rowContent = content.getChild(selectedItem[0])
        if rowContent <> invalid
            channelNode = rowContent.getChild(selectedItem[1])
            if channelNode <> invalid
                print "M3UChannelScreen.brs - [onChannelSelected] Selected channel: " + channelNode.title
                print "M3UChannelScreen.brs - [onChannelSelected] Stream URL: " + channelNode.streamUrl
                
                ' TODO: Play the channel stream
                ' For now, just log it
                playChannel(channelNode)
            end if
        end if
    end if
end sub

sub playChannel(channelNode as Object)
    print "M3UChannelScreen.brs - [playChannel] Playing channel: " + channelNode.title
    
    ' Create video player content
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.title = channelNode.title
    videoContent.streamFormat = "hls"
    videoContent.url = channelNode.streamUrl
    
    ' Get the video player from home scene
    parentScene = m.top.getScene()
    if parentScene <> invalid
        videoPlayer = parentScene.findNode("videoPlayer")
        if videoPlayer <> invalid
            print "M3UChannelScreen.brs - [playChannel] Setting video content and starting playback"
            videoPlayer.content = videoContent
            videoPlayer.visible = true
            videoPlayer.control = "play"
            videoPlayer.setFocus(true)
        else
            print "M3UChannelScreen.brs - [playChannel] ERROR: Video player not found"
        end if
    end if
end sub

sub showError(errorMsg as String)
    print "M3UChannelScreen.brs - [showError] Showing error: " + errorMsg
    
    m.loadingGroup.visible = false
    m.channelGrid.visible = false
    m.errorGroup.visible = true
    m.errorMessage.text = errorMsg
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

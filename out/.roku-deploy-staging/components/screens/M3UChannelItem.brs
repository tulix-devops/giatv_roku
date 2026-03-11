sub init()
    m.background = m.top.findNode("background")
    m.channelPoster = m.top.findNode("channelPoster")
    m.bottomTitle = m.top.findNode("bottomTitle")
    m.focusIndicator = m.top.findNode("focusIndicator")
end sub

sub onContentChanged()
    content = m.top.itemContent
    
    print "M3UChannelItem - onContentChanged called"
    
    if content = invalid
        print "M3UChannelItem - content is invalid"
        return
    end if
    
    ' Get channel name/title
    channelTitle = "Unknown Channel"
    if content.title <> invalid and content.title <> ""
        channelTitle = content.title
        print "M3UChannelItem - Title: " + channelTitle
    else if content.name <> invalid and content.name <> ""
        channelTitle = content.name
        print "M3UChannelItem - Name: " + channelTitle
    end if
    
    ' Set title below card (only place we show title)
    if m.bottomTitle <> invalid
        m.bottomTitle.text = channelTitle
    end if
    
    ' Set poster/logo (try multiple fields)
    posterUrl = ""
    if content.HDPosterUrl <> invalid and content.HDPosterUrl <> ""
        posterUrl = content.HDPosterUrl
    else if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
        posterUrl = content.hdPosterUrl
    else if content.FHDPosterUrl <> invalid and content.FHDPosterUrl <> ""
        posterUrl = content.FHDPosterUrl
    else if content.posterUrl <> invalid and content.posterUrl <> ""
        posterUrl = content.posterUrl
    else if content.thumbnail <> invalid and content.thumbnail <> ""
        posterUrl = content.thumbnail
    else if content.logo <> invalid and content.logo <> ""
        posterUrl = content.logo
    end if
    
    if posterUrl <> ""
        m.channelPoster.uri = posterUrl
        print "M3UChannelItem - Poster set: " + posterUrl
    else
        print "M3UChannelItem - No poster found, using placeholder"
    end if
end sub

sub onFocusPercentChanged()
    focusPercent = m.top.focusPercent
    
    ' Animate focus indicator
    if focusPercent > 0.5
        m.focusIndicator.opacity = 0.3
        if m.bottomTitle <> invalid
            m.bottomTitle.color = "0xFFFFFFFF"
        end if
    else
        m.focusIndicator.opacity = 0.0
        if m.bottomTitle <> invalid
            m.bottomTitle.color = "0xCCCCCCFF"
        end if
    end if
end sub

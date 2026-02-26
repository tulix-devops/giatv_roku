sub init()
    m.top = m.top
    m.background = m.top.findNode("background")
    m.channelPoster = m.top.findNode("channelPoster")
    m.channelName = m.top.findNode("channelName")
    m.channelInfo = m.top.findNode("channelInfo")
    m.focusIndicator = m.top.findNode("focusIndicator")
end sub

sub onContentChanged()
    content = m.top.itemContent
    
    if content <> invalid
        ' Set channel name
        if content.title <> invalid
            m.channelName.text = content.title
        end if
        
        ' Set channel info (number or category)
        infoText = ""
        if content.description <> invalid and content.description <> ""
            infoText = content.description
        end if
        if content.shortDescriptionLine2 <> invalid and content.shortDescriptionLine2 <> ""
            if infoText <> ""
                infoText = infoText + " • " + content.shortDescriptionLine2
            else
                infoText = content.shortDescriptionLine2
            end if
        end if
        m.channelInfo.text = infoText
        
        ' Set poster
        if content.HDPosterUrl <> invalid and content.HDPosterUrl <> ""
            m.channelPoster.uri = content.HDPosterUrl
        else if content.FHDPosterUrl <> invalid and content.FHDPosterUrl <> ""
            m.channelPoster.uri = content.FHDPosterUrl
        end if
    end if
end sub

sub onFocusPercentChanged()
    focusPercent = m.top.focusPercent
    
    ' Animate focus indicator
    if focusPercent > 0
        m.focusIndicator.opacity = 0.3 * focusPercent
        
        ' Scale up slightly when focused
        scale = 1.0 + (0.05 * focusPercent)
        m.top.scale = [scale, scale]
    else
        m.focusIndicator.opacity = 0.0
        m.top.scale = [1.0, 1.0]
    end if
end sub

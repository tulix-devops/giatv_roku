sub init()
    m.background = m.top.findNode("itemBg")
    m.logo = m.top.findNode("channelLogo")
    m.nameLabel = m.top.findNode("channelName")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then return
    
    ' Always set and show the channel name
    if content.title <> invalid and content.title <> ""
        m.nameLabel.text = content.title
        m.nameLabel.visible = true
    else
        m.nameLabel.text = "Channel"
        m.nameLabel.visible = true
    end if
    
    ' Set channel logo (show if available)
    logoUrl = ""
    if content.HDPosterUrl <> invalid and content.HDPosterUrl <> ""
        logoUrl = content.HDPosterUrl
    else if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
        logoUrl = content.hdPosterUrl
    end if
    
    if logoUrl <> ""
        m.logo.uri = logoUrl
        m.logo.visible = true
    else
        m.logo.visible = false
    end if
end sub

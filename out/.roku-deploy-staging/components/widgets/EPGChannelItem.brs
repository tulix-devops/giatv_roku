' Simplified EPG Channel Item (based on SGDEX TimeGridChannelItemComponent pattern)
' Uses our API data but follows TimeGrid best practices

sub init()
    m.title = m.top.findNode("title")
    m.poster = m.top.findNode("poster")
    
    ' Setup margins for proper spacing
    m.horizontalMargin = 20
    m.verticalMargin = 10
    m.title.translation = [m.horizontalMargin, m.verticalMargin]
    m.poster.translation = [m.horizontalMargin, m.verticalMargin]
end sub

sub onContentSet()
    content = m.top.content
    if content = invalid then return
    
    ' Set title (hidden, but available as fallback)
    if content.title <> invalid and content.title <> ""
        m.title.text = content.title
    else
        m.title.text = ""
    end if
    
    ' Get poster URL - try multiple fields (from our API data)
    posterUrl = ""
    if content.HDSMALLICONURL <> invalid and content.HDSMALLICONURL <> ""
        posterUrl = content.HDSMALLICONURL
    else if content.HDPOSTERURL <> invalid and content.HDPOSTERURL <> ""
        posterUrl = content.HDPOSTERURL
    else if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
        posterUrl = content.hdPosterUrl
    else if content.SDPosterUrl <> invalid and content.SDPosterUrl <> ""
        posterUrl = content.SDPosterUrl
    end if
    
    print "EPGChannelItem - Channel: " + m.title.text + ", Logo: " + posterUrl
    
    ' Set poster URI
    m.poster.uri = posterUrl
    
    ' Always keep title hidden (logo-only display as requested)
    m.title.visible = false
end sub

sub onLayoutChanged()
    ' TimeGrid sets width and height dynamically
    ' Calculate rendering area with margins
    renderingWidth = m.top.width - (m.horizontalMargin * 2)
    renderingHeight = m.top.height - (m.verticalMargin * 2)
    
    ' Apply to poster
    m.poster.width = renderingWidth
    m.poster.height = renderingHeight
    m.poster.loadWidth = renderingWidth
    m.poster.loadHeight = renderingHeight
    
    ' Apply to title (hidden fallback)
    m.title.width = renderingWidth
    m.title.height = renderingHeight
end sub

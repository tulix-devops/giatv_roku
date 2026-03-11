sub init()
    m.cardBackground = m.top.findNode("cardBackground")
    m.logoImage = m.top.findNode("logoImage")
    m.textBackground = m.top.findNode("textBackground")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.bottomTitle = m.top.findNode("bottomTitle")
    m.focusBorder = m.top.findNode("focusBorder")
    m.itemContainer = m.top.findNode("itemContainer")
    
    print "M3UPlaylistCard - init() called"
end sub

sub OnContentSet()
    content = m.top.itemContent
    
    print "==================== M3UPlaylistCard - OnContentSet ===================="
    
    if content = invalid
        print "M3UPlaylistCard - ERROR: content is INVALID"
        return
    end if
    
    ' Get title
    titleText = "M3U Playlist"
    if content.title <> invalid and content.title <> ""
        titleText = content.title
        print "M3UPlaylistCard - Got title from content.title: " + titleText
    else if content.name <> invalid and content.name <> ""
        titleText = content.name
        print "M3UPlaylistCard - Got title from content.name: " + titleText
    else
        print "M3UPlaylistCard - Using default title"
    end if
    
    ' Set title in both places
    m.titleLabel.text = titleText
    m.bottomTitle.text = titleText
    print "M3UPlaylistCard - Title set to: " + titleText
    
    ' Get description
    descText = "Press OK to open"
    if content.description <> invalid and content.description <> ""
        descText = content.description
        print "M3UPlaylistCard - Got description from content.description: " + descText
    else if content.shortDescriptionLine2 <> invalid and content.shortDescriptionLine2 <> ""
        descText = content.shortDescriptionLine2
        print "M3UPlaylistCard - Got description from content.shortDescriptionLine2: " + descText
    else
        print "M3UPlaylistCard - Using default description"
    end if
    
    ' Set description
    m.descriptionLabel.text = descText
    print "M3UPlaylistCard - Description set to: " + descText
    
    ' Get logo URL
    logoUrl = "pkg:/images/png/gia-tv-logo.png"
    if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
        logoUrl = content.hdPosterUrl
        print "M3UPlaylistCard - Got logo from content.hdPosterUrl: " + logoUrl
    else if content.posterUrl <> invalid and content.posterUrl <> ""
        logoUrl = content.posterUrl
        print "M3UPlaylistCard - Got logo from content.posterUrl: " + logoUrl
    else if content.thumbnail <> invalid and content.thumbnail <> ""
        logoUrl = content.thumbnail
        print "M3UPlaylistCard - Got logo from content.thumbnail: " + logoUrl
    else
        print "M3UPlaylistCard - Using default logo"
    end if
    
    ' Set logo
    m.logoImage.uri = logoUrl
    print "M3UPlaylistCard - Logo set to: " + logoUrl
    
    print "==================== M3UPlaylistCard - Setup Complete ===================="
end sub

sub showFocus()
    focusPercent = m.top.focusPercent
    
    print "M3UPlaylistCard - showFocus: " + focusPercent.ToStr()
    
    if focusPercent > 0.5
        ' Focused state
        m.focusBorder.color = "0x00A8E1FF"
        m.focusBorder.opacity = 1.0
        m.cardBackground.color = "0x3A5F8EFF"
        m.bottomTitle.color = "0xFFFFFFFF"
        m.top.scale = [1.05, 1.05]
    else
        ' Unfocused state
        m.focusBorder.color = "0x00000000"
        m.focusBorder.opacity = 0.0
        m.cardBackground.color = "0x2A3F5EFF"
        m.bottomTitle.color = "0xCCCCCCFF"
        m.top.scale = [1.0, 1.0]
    end if
end sub

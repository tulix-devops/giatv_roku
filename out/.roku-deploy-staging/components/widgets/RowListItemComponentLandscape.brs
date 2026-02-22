sub init()
    ' Main elements
    m.itemposter = m.top.findNode("poster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.infoPanel = m.top.findNode("infoPanel")
    m.glassBackground = m.top.findNode("glassBackground")
    m.glassReflection = m.top.findNode("glassReflection")
    
    ' Visual effects
    m.actionButton = m.top.findNode("actionButton")
    m.cornerBadge = m.top.findNode("cornerBadge")
    m.badgeText = m.top.findNode("badgeText")
    
    ' Animations
    m.focusInAnimation = m.top.findNode("focusInAnimation")
    m.focusOutAnimation = m.top.findNode("focusOutAnimation")
end sub

sub OnContentSet() ' invoked when item metadata retrieved
    content = m.top.itemContent
    content.observeField("keyPressed", "onKeyPressed")
    
    if content <> invalid
        ' Set poster image directly
        if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
            m.itemposter.uri = content.hdPosterUrl
            print "RowListItemComponentLandscape: Setting image URI to: " + content.hdPosterUrl
        else
            print "RowListItemComponentLandscape: No image URL provided for: " + content.title
        end if
        
        ' Always ensure poster is visible
        m.itemposter.visible = true
        print "RowListItemComponentLandscape: Poster visible set to: " + m.itemposter.visible.ToStr()
        
        ' Set content information
        setContentInfo(content)
        
        ' Set up focus handling with animations
        content.observeField("rowItemFocus", "onFocusChanged")
    end if
end sub


sub setContentInfo(content)
    ' Set title with enhanced styling
    if content.data <> invalid and content.data.title <> invalid
        title = content.data.title
        if len(title) > 25
            title = left(title, 22) + "..."
        end if
        m.titleLabel.text = title
    else if content.title <> invalid
        title = content.title
        if len(title) > 25
            title = left(title, 22) + "..."
        end if
        m.titleLabel.text = title
    else
        m.titleLabel.text = ""
    end if
    
    ' Set badge based on content type
    if content.isDVRItem <> invalid and content.isDVRItem = true
        ' DVR item - show "DVR" badge
        m.badgeText.text = "DVR"
        m.cornerBadge.findNode("badgeBackground").color = "0xFF6B6B"  ' Red color for DVR
    else if content.isLiveParent <> invalid and content.isLiveParent = true
        ' Live item - show "LIVE" badge
        m.badgeText.text = "LIVE"
        m.cornerBadge.findNode("badgeBackground").color = "0x4A90E2"  ' Blue color for LIVE
    else
        ' Default TV Show badge
        m.badgeText.text = "SERIES"
        m.cornerBadge.findNode("badgeBackground").color = "0x4A90E2"
    end if
end sub

sub onFocusChanged()
    content = m.top.itemContent
    if content <> invalid
        if content.rowItemFocus = true
            ' Start focus in animation
            m.focusInAnimation.control = "start"
        else
            ' Start focus out animation
            m.focusOutAnimation.control = "start"
        end if
    end if
end sub

sub onKeyPressed()
    ' Handle key press events if needed
end sub
